import 'dart:async';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';

import 'package:yank/features/capture/services/share_receiver_service.dart';
import 'package:yank/features/library/bloc/library_bloc.dart';
import 'package:yank/features/library/models/yank_item.dart';
import 'package:yank/features/library/repositories/demo_library_repository.dart';
import 'package:yank/features/library/repositories/metadata_store.dart';

void main() {
  group('ShareReceiverService classification', () {
    test('classifies web URL as ItemKind.link with clean host title', () {
      final item = ShareReceiverService.classifyAndBuildItem(
        file: SharedMediaFile(
          path: 'https://www.nytimes.com/interactive/2026/technology.html',
          type: SharedMediaType.url,
        ),
        id: 'test-link',
        createdAt: DateTime(2026, 9, 22),
      );

      expect(item.kind, ItemKind.link);
      expect(item.title, 'nytimes.com');
      expect(item.url, 'https://www.nytimes.com/interactive/2026/technology.html');
    });

    test('classifies text URL without schema as ItemKind.link', () {
      final item = ShareReceiverService.classifyAndBuildItem(
        file: SharedMediaFile(
          path: 'github.com/flutter/flutter',
          type: SharedMediaType.text,
        ),
        id: 'test-link-noschema',
        createdAt: DateTime(2026, 9, 22),
      );

      expect(item.kind, ItemKind.link);
      expect(item.title, 'github.com');
      expect(item.url, 'https://github.com/flutter/flutter');
    });

    test('classifies plain multiline note as ItemKind.text with first line title', () {
      final item = ShareReceiverService.classifyAndBuildItem(
        file: SharedMediaFile(
          path: 'Ideas for next project\n1. Universal capture\n2. Real-time sync',
          type: SharedMediaType.text,
        ),
        id: 'test-text',
        createdAt: DateTime(2026, 9, 22),
      );

      expect(item.kind, ItemKind.text);
      expect(item.title, 'Ideas for next project');
      expect(item.body, 'Ideas for next project\n1. Universal capture\n2. Real-time sync');
    });

    test('classifies image file path as ItemKind.photo with filename title', () {
      final item = ShareReceiverService.classifyAndBuildItem(
        file: SharedMediaFile(
          path: '/storage/emulated/0/DCIM/Camera/IMG_20260922.jpg',
          type: SharedMediaType.image,
          mimeType: 'image/jpeg',
        ),
        id: 'test-photo',
        createdAt: DateTime(2026, 9, 22),
      );

      expect(item.kind, ItemKind.photo);
      expect(item.title, 'IMG_20260922.jpg');
      expect(item.artwork, '/storage/emulated/0/DCIM/Camera/IMG_20260922.jpg');
    });

    test('classifies audio file as ItemKind.audio with filename title', () {
      final item = ShareReceiverService.classifyAndBuildItem(
        file: SharedMediaFile(
          path: '/storage/emulated/0/Music/voice_memo.m4a',
          type: SharedMediaType.file,
          mimeType: 'audio/mp4',
        ),
        id: 'test-audio',
        createdAt: DateTime(2026, 9, 22),
      );

      expect(item.kind, ItemKind.audio);
      expect(item.title, 'voice_memo.m4a');
      expect(item.audioAsset, '/storage/emulated/0/Music/voice_memo.m4a');
    });

    test('classifies generic document as ItemKind.file', () {
      final item = ShareReceiverService.classifyAndBuildItem(
        file: SharedMediaFile(
          path: '/storage/emulated/0/Download/quarterly_report.pdf',
          type: SharedMediaType.file,
          mimeType: 'application/pdf',
        ),
        id: 'test-doc',
        createdAt: DateTime(2026, 9, 22),
      );

      expect(item.kind, ItemKind.file);
      expect(item.title, 'quarterly_report.pdf');
      expect(item.url, '/storage/emulated/0/Download/quarterly_report.pdf');
    });
  });

  group('ShareReceiverService ingestion stream and cold start', () {
    late DemoLibraryRepository repo;
    late LibraryBloc bloc;
    late StreamController<List<SharedMediaFile>> streamController;

    setUp(() async {
      repo = await DemoLibraryRepository.open(MemoryMetadataStore());
      bloc = LibraryBloc(repo);
      streamController = StreamController<List<SharedMediaFile>>.broadcast();
    });

    tearDown(() async {
      await streamController.close();
      await bloc.close();
      await repo.close();
    });

    test('ingests stream shared link and posts notice on LibraryBloc', () async {
      ReceiveSharingIntent.setMockValues(
        initialMedia: [],
        mediaStream: streamController.stream,
      );

      final service = ShareReceiverService(
        repository: repo,
        libraryBloc: bloc,
      );
      service.initialize();

      final initialCount = repo.items.length;

      final noticeFuture = bloc.stream.firstWhere((s) => s.notice != null);
      streamController.add([
        SharedMediaFile(
          path: 'https://dart.dev/guides',
          type: SharedMediaType.url,
        ),
      ]);

      await noticeFuture;

      expect(repo.items.length, initialCount + 1);
      final captured = repo.items.firstWhere((i) => i.url == 'https://dart.dev/guides');
      expect(captured.kind, ItemKind.link);
      expect(captured.title, 'dart.dev');

      // Verify notification on bloc
      expect(bloc.state.notice?.message, contains('Captured to Yank: dart.dev'));

      service.dispose();
    });

    test('ingests multiple shared files in single batch with count indicator in notice', () async {
      ReceiveSharingIntent.setMockValues(
        initialMedia: [
          SharedMediaFile(
            path: '/tmp/photo1.png',
            type: SharedMediaType.image,
            mimeType: 'image/png',
          ),
          SharedMediaFile(
            path: '/tmp/photo2.png',
            type: SharedMediaType.image,
            mimeType: 'image/png',
          ),
        ],
        mediaStream: streamController.stream,
      );

      final noticeFuture = bloc.stream.firstWhere((s) => s.notice != null);
      final service = ShareReceiverService(
        repository: repo,
        libraryBloc: bloc,
      );
      service.initialize();

      await noticeFuture;

      expect(repo.items.any((i) => i.artwork == '/tmp/photo1.png'), isTrue);
      expect(repo.items.any((i) => i.artwork == '/tmp/photo2.png'), isTrue);

      expect(bloc.state.notice?.message, contains('photo1.png (+1 more)'));

      service.dispose();
    });

    test('persistFileLocally streams content directly to disk without loading into RAM', () async {
      final tempDir = Directory.systemTemp.createTempSync('yank_test_');
      final sourceFile = File('${tempDir.path}/shared_photo.jpg');
      await sourceFile.writeAsString('fake image bytes for test');

      final targetDir = Directory('${tempDir.path}/captures');
      final persistedPath = await ShareReceiverService.persistFileLocally(
        sourcePath: sourceFile.path,
        itemId: 'item-123',
        targetDirectory: targetDir,
      );

      expect(File(persistedPath).existsSync(), isTrue);
      expect(persistedPath, contains('item-123-shared_photo.jpg'));
      expect(await File(persistedPath).readAsString(), 'fake image bytes for test');

      tempDir.deleteSync(recursive: true);
    });

    test('classifyAndBuildItemAsync creates permanent file copy and populates sizeBytes', () async {
      final tempDir = Directory.systemTemp.createTempSync('yank_test_');
      final sourceFile = File('${tempDir.path}/recording.m4a');
      await sourceFile.writeAsString('audio recording payload');

      final targetDir = Directory('${tempDir.path}/captures');
      final item = await ShareReceiverService.classifyAndBuildItemAsync(
        file: SharedMediaFile(
          path: sourceFile.path,
          type: SharedMediaType.file,
          mimeType: 'audio/mp4',
        ),
        id: 'test-async-audio',
        createdAt: DateTime(2026, 9, 22),
        targetDirectory: targetDir,
      );

      expect(item.kind, ItemKind.audio);
      expect(item.audioAsset, isNotNull);
      expect(item.audioAsset, isNot(equals(sourceFile.path)));
      expect(File(item.audioAsset!).existsSync(), isTrue);
      expect(item.sizeBytes, 'audio recording payload'.length);

      tempDir.deleteSync(recursive: true);
    });

    test('extractCleanTitle removes UUID prefixes and formats UUID-only filenames as fallback', () {
      expect(
        ShareReceiverService.extractCleanTitle(
          '/path/to/a1b2c3d4_my_vacation.jpg',
          fallback: 'Photo',
        ),
        'my_vacation.jpg',
      );

      expect(
        ShareReceiverService.extractCleanTitle(
          '/path/to/3D618713-2442-493A-A6C5-3F701F8FD160.png',
          fallback: 'Photo',
        ),
        'Photo',
      );

      expect(
        ShareReceiverService.extractCleanTitle(
          '/path/to/notes.pdf',
          fallback: 'Document',
        ),
        'notes.pdf',
      );
    });

    test('persistFileLocally cleans up temporary file if inside AppGroup container', () async {
      final tempDir = Directory.systemTemp.createTempSync('yank_group.com.example.yank_test_');
      final sourceFile = File('${tempDir.path}/shared_appgroup_photo.jpg');
      await sourceFile.writeAsString('bytes in appgroup container');

      final targetDir = Directory('${tempDir.path}/captures');
      final persistedPath = await ShareReceiverService.persistFileLocally(
        sourcePath: sourceFile.path,
        itemId: 'item-ag-1',
        targetDirectory: targetDir,
      );

      expect(File(persistedPath).existsSync(), isTrue);
      // Source file in group container must be cleaned up to prevent disk bloat
      expect(sourceFile.existsSync(), isFalse);

      tempDir.deleteSync(recursive: true);
    });

    test('ingests pending shares when app resumes from background (didChangeAppLifecycleState)', () async {
      ReceiveSharingIntent.setMockValues(
        initialMedia: [],
        mediaStream: streamController.stream,
      );

      final service = ShareReceiverService(
        repository: repo,
        libraryBloc: bloc,
      );
      service.initialize();
      await Future<void>.delayed(const Duration(milliseconds: 50));

      final initialCount = repo.items.length;

      // Simulate user sharing a photo in background while Yank is in background
      ReceiveSharingIntent.setMockValues(
        initialMedia: [
          SharedMediaFile(
            path: 'https://github.com',
            type: SharedMediaType.url,
          ),
        ],
        mediaStream: streamController.stream,
      );

      final noticeFuture = bloc.stream.firstWhere((s) => s.notice != null);

      // Simulate app resuming to foreground
      service.didChangeAppLifecycleState(AppLifecycleState.resumed);

      await noticeFuture;

      expect(repo.items.length, initialCount + 1);
      final captured = repo.items.firstWhere((i) => i.url == 'https://github.com');
      expect(captured.kind, ItemKind.link);
      expect(captured.title, 'github.com');
      expect(bloc.state.notice?.message, contains('Captured to Yank: github.com'));

      service.dispose();
    });

    test('parseSharedMediaJson parses App Group JSON payload accurately', () {
      const sampleJson = '''
      [
        {
          "path": "/private/var/mobile/Containers/Shared/AppGroup/UUID/photo.jpg",
          "mimeType": "image/jpeg",
          "thumbnail": null,
          "duration": null,
          "message": "Vacation picture",
          "type": "image"
        },
        {
          "path": "https://yank.app",
          "mimeType": "text/plain",
          "thumbnail": null,
          "duration": null,
          "message": null,
          "type": "url"
        }
      ]
      ''';

      final files = ShareReceiverService.parseSharedMediaJson(sampleJson);
      expect(files.length, 2);
      expect(files[0].path, contains('photo.jpg'));
      expect(files[0].type, SharedMediaType.image);
      expect(files[0].mimeType, 'image/jpeg');
      expect(files[0].message, 'Vacation picture');

      expect(files[1].path, 'https://yank.app');
      expect(files[1].type, SharedMediaType.url);
    });

    test('parseSharedMediaJson handles empty and malformed json gracefully', () {
      expect(ShareReceiverService.parseSharedMediaJson(''), isEmpty);
      expect(ShareReceiverService.parseSharedMediaJson('{not a valid json array}'), isEmpty);
    });
  });
}
