import 'dart:async';

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

      // Emit incoming share while app is running
      streamController.add([
        SharedMediaFile(
          path: 'https://dart.dev/guides',
          type: SharedMediaType.url,
        ),
      ]);

      // Allow async processing
      await Future<void>.delayed(const Duration(milliseconds: 50));

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

      final service = ShareReceiverService(
        repository: repo,
        libraryBloc: bloc,
      );
      service.initialize();

      // Allow cold-start async getInitialMedia to process
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(repo.items.any((i) => i.artwork == '/tmp/photo1.png'), isTrue);
      expect(repo.items.any((i) => i.artwork == '/tmp/photo2.png'), isTrue);

      expect(bloc.state.notice?.message, contains('photo1.png (+1 more)'));

      service.dispose();
    });
  });
}
