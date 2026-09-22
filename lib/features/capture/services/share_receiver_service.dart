import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';

import 'package:yank/features/library/bloc/library_bloc.dart';
import 'package:yank/features/library/models/library_projection.dart';
import 'package:yank/features/library/models/yank_item.dart';
import 'package:yank/features/library/repositories/library_repository.dart';

class ShareReceiverService {
  ShareReceiverService({
    required this.repository,
    required this.libraryBloc,
    ReceiveSharingIntent? sharingIntent,
    this.targetDirectory,
  }) : _sharingIntent = sharingIntent ?? ReceiveSharingIntent.instance;

  final LibraryRepository repository;
  final LibraryBloc libraryBloc;
  final ReceiveSharingIntent _sharingIntent;
  final Directory? targetDirectory;

  StreamSubscription<List<SharedMediaFile>>? _intentDataStreamSubscription;
  bool _initialized = false;

  void initialize() {
    if (_initialized) return;
    _initialized = true;

    // Listen to media sharing while the app is in memory (warm resume)
    _intentDataStreamSubscription = _sharingIntent.getMediaStream().listen(
      _handleSharedMedia,
      onError: (err) {
        debugPrint('ShareReceiverService getMediaStream error: $err');
      },
    );

    // Get the media sharing when the app is brought from closed state (cold start)
    _sharingIntent.getInitialMedia().then((files) async {
      if (files.isNotEmpty) {
        final filesCopy = List<SharedMediaFile>.from(files);
        await _handleSharedMedia(filesCopy);
      }
    }).catchError((err) {
      debugPrint('ShareReceiverService getInitialMedia error: $err');
    });
  }

  Future<void> _handleSharedMedia(List<SharedMediaFile> files) async {
    if (files.isEmpty) return;

    final now = DateTime.now();
    final itemsToSave = <YankItem>[];

    for (var i = 0; i < files.length; i++) {
      final file = files[i];
      final item = await classifyAndBuildItemAsync(
        file: file,
        id: 'share-${now.microsecondsSinceEpoch}-$i',
        createdAt: now.add(Duration(milliseconds: i)),
        targetDirectory: targetDirectory,
      );
      itemsToSave.add(item);
    }

    for (final item in itemsToSave) {
      try {
        await repository.put(item);
      } catch (e) {
        debugPrint('ShareReceiverService failed to save item ${item.id}: $e');
      }
    }

    if (itemsToSave.isNotEmpty) {
      final firstTitle = itemsToSave.first.title;
      final countSuffix = itemsToSave.length > 1
          ? ' (+${itemsToSave.length - 1} more)'
          : '';
      libraryBloc.add(
        NoticePosted('Captured to Yank: $firstTitle$countSuffix'),
      );
    }

    try {
      await _sharingIntent.reset();
    } catch (_) {}
  }

  static Future<String> persistFileLocally({
    required String sourcePath,
    required String itemId,
    Directory? targetDirectory,
  }) async {
    try {
      final src = File(sourcePath);
      if (!src.existsSync()) {
        return sourcePath;
      }

      Directory dir;
      if (targetDirectory != null) {
        dir = targetDirectory;
      } else {
        try {
          final docs = await getApplicationDocumentsDirectory();
          dir = Directory('${docs.path}/captures');
        } catch (_) {
          dir = Directory('${Directory.systemTemp.path}/yank_captures');
        }
      }

      if (!dir.existsSync()) {
        await dir.create(recursive: true);
      }

      final originalName = sourcePath.split(Platform.pathSeparator).last;
      final sanitizedName = originalName.replaceAll(RegExp(r'[^\w\.-]'), '_');
      final dest = File('${dir.path}/$itemId-$sanitizedName');

      // Direct disk-to-disk streaming to adhere to Yank $0 / memory safety constraints
      await src.openRead().pipe(dest.openWrite());
      return dest.path;
    } catch (e) {
      debugPrint('ShareReceiverService persistFileLocally error: $e');
      return sourcePath;
    }
  }

  static Future<YankItem> classifyAndBuildItemAsync({
    required SharedMediaFile file,
    required String id,
    required DateTime createdAt,
    Directory? targetDirectory,
  }) async {
    final rawPath = file.path;
    final mime = (file.mimeType ?? '').toLowerCase();
    final lowerPath = rawPath.toLowerCase();

    // Check if it is a link or text
    if (file.type == SharedMediaType.url ||
        file.type == SharedMediaType.text ||
        mime.startsWith('text/')) {
      final normalizedUrl = LibraryProjection.normalizeLink(rawPath);
      if (normalizedUrl != null) {
        final host = Uri.tryParse(normalizedUrl)?.host ?? '';
        final derivedTitle = host.isNotEmpty
            ? host.replaceFirst('www.', '')
            : rawPath;
        return YankItem(
          id: id,
          kind: ItemKind.link,
          title: derivedTitle,
          createdAt: createdAt,
          url: normalizedUrl,
          body: file.message ?? '',
        );
      }

      // Plain text
      final lines = rawPath.split('\n');
      final firstLine = lines.first.trim();
      final title = firstLine.isNotEmpty
          ? firstLine.substring(0, firstLine.length.clamp(0, 90))
          : 'Note';
      return YankItem(
        id: id,
        kind: ItemKind.text,
        title: title,
        createdAt: createdAt,
        body: rawPath,
      );
    }

    // Persist local file to permanent documents storage
    final persistedPath = await persistFileLocally(
      sourcePath: rawPath,
      itemId: id,
      targetDirectory: targetDirectory,
    );

    // Determine file size if accessible locally
    int? sizeBytes;
    try {
      final localFile = File(persistedPath);
      if (localFile.existsSync()) {
        sizeBytes = localFile.lengthSync();
      }
    } catch (_) {}

    final fileName = rawPath.split('/').last;

    // Check for photo/image
    final isImage = file.type == SharedMediaType.image ||
        mime.startsWith('image/') ||
        lowerPath.endsWith('.jpg') ||
        lowerPath.endsWith('.jpeg') ||
        lowerPath.endsWith('.png') ||
        lowerPath.endsWith('.webp') ||
        lowerPath.endsWith('.gif') ||
        lowerPath.endsWith('.heic') ||
        lowerPath.endsWith('.heif');

    if (isImage) {
      final title = fileName.isNotEmpty ? fileName : 'Photo';
      return YankItem(
        id: id,
        kind: ItemKind.photo,
        title: title,
        createdAt: createdAt,
        artwork: persistedPath,
        body: file.message ?? '',
        sizeBytes: sizeBytes ?? 0,
      );
    }

    // Check for audio
    final isAudio = mime.startsWith('audio/') ||
        lowerPath.endsWith('.mp3') ||
        lowerPath.endsWith('.m4a') ||
        lowerPath.endsWith('.wav') ||
        lowerPath.endsWith('.aac') ||
        lowerPath.endsWith('.flac') ||
        lowerPath.endsWith('.ogg');

    if (isAudio) {
      final title = fileName.isNotEmpty ? fileName : 'Audio Track';
      return YankItem(
        id: id,
        kind: ItemKind.audio,
        title: title,
        createdAt: createdAt,
        audioAsset: persistedPath,
        body: file.message ?? '',
        sizeBytes: sizeBytes ?? 0,
      );
    }

    // Generic document or file
    final title = fileName.isNotEmpty ? fileName : 'Document';
    return YankItem(
      id: id,
      kind: ItemKind.file,
      title: title,
      createdAt: createdAt,
      url: persistedPath,
      body: file.message ?? fileName,
      sizeBytes: sizeBytes ?? 0,
    );
  }

  static YankItem classifyAndBuildItem({
    required SharedMediaFile file,
    required String id,
    required DateTime createdAt,
  }) {
    final rawPath = file.path;
    final mime = (file.mimeType ?? '').toLowerCase();
    final lowerPath = rawPath.toLowerCase();

    if (file.type == SharedMediaType.url ||
        file.type == SharedMediaType.text ||
        mime.startsWith('text/')) {
      final normalizedUrl = LibraryProjection.normalizeLink(rawPath);
      if (normalizedUrl != null) {
        final host = Uri.tryParse(normalizedUrl)?.host ?? '';
        final derivedTitle = host.isNotEmpty
            ? host.replaceFirst('www.', '')
            : rawPath;
        return YankItem(
          id: id,
          kind: ItemKind.link,
          title: derivedTitle,
          createdAt: createdAt,
          url: normalizedUrl,
          body: file.message ?? '',
        );
      }

      final lines = rawPath.split('\n');
      final firstLine = lines.first.trim();
      final title = firstLine.isNotEmpty
          ? firstLine.substring(0, firstLine.length.clamp(0, 90))
          : 'Note';
      return YankItem(
        id: id,
        kind: ItemKind.text,
        title: title,
        createdAt: createdAt,
        body: rawPath,
      );
    }

    int? sizeBytes;
    try {
      final localFile = File(rawPath);
      if (localFile.existsSync()) {
        sizeBytes = localFile.lengthSync();
      }
    } catch (_) {}

    final fileName = rawPath.split('/').last;

    final isImage = file.type == SharedMediaType.image ||
        mime.startsWith('image/') ||
        lowerPath.endsWith('.jpg') ||
        lowerPath.endsWith('.jpeg') ||
        lowerPath.endsWith('.png') ||
        lowerPath.endsWith('.webp') ||
        lowerPath.endsWith('.gif') ||
        lowerPath.endsWith('.heic') ||
        lowerPath.endsWith('.heif');

    if (isImage) {
      final title = fileName.isNotEmpty ? fileName : 'Photo';
      return YankItem(
        id: id,
        kind: ItemKind.photo,
        title: title,
        createdAt: createdAt,
        artwork: rawPath,
        body: file.message ?? '',
        sizeBytes: sizeBytes ?? 0,
      );
    }

    final isAudio = mime.startsWith('audio/') ||
        lowerPath.endsWith('.mp3') ||
        lowerPath.endsWith('.m4a') ||
        lowerPath.endsWith('.wav') ||
        lowerPath.endsWith('.aac') ||
        lowerPath.endsWith('.flac') ||
        lowerPath.endsWith('.ogg');

    if (isAudio) {
      final title = fileName.isNotEmpty ? fileName : 'Audio Track';
      return YankItem(
        id: id,
        kind: ItemKind.audio,
        title: title,
        createdAt: createdAt,
        audioAsset: rawPath,
        body: file.message ?? '',
        sizeBytes: sizeBytes ?? 0,
      );
    }

    final title = fileName.isNotEmpty ? fileName : 'Document';
    return YankItem(
      id: id,
      kind: ItemKind.file,
      title: title,
      createdAt: createdAt,
      url: rawPath,
      body: file.message ?? fileName,
      sizeBytes: sizeBytes ?? 0,
    );
  }

  void dispose() {
    _intentDataStreamSubscription?.cancel();
    _intentDataStreamSubscription = null;
    _initialized = false;
  }
}
