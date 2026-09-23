import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import 'package:yank/core/utils/local_path_resolver.dart';
import 'package:yank/features/library/models/yank_item.dart';

/// Service responsible for streaming binary payloads (photos, audio, files)
/// between devices under Yank's $0 infrastructure budget.
///
/// Uses Firestore chunked binary streams (up to 500 KB per chunk) to operate
/// within the 100% free Spark tier without requiring credit cards or Cloud Storage billing.
class BinarySyncService {
  BinarySyncService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  static const int chunkSize = 512 * 1024; // 512 KB per chunk (well under 1 MB limit)

  CollectionReference<Map<String, dynamic>> _itemChunks(String userId, String itemId) =>
      _firestore
          .collection('users')
          .doc(userId)
          .collection('items')
          .doc(itemId)
          .collection('chunks');

  /// Uploads a locally persisted binary file to Firestore chunked storage.
  Future<bool> uploadBinary({
    required String userId,
    required YankItem item,
    File? file,
  }) async {
    final targetFile = file ??
        LocalPathResolver.resolveFile(item.artwork ?? item.audioAsset ?? item.url);
    if (targetFile == null || !targetFile.existsSync()) {
      return false;
    }

    try {
      final totalBytes = await targetFile.length();
      if (totalBytes == 0) return false;

      final originalName = targetFile.path.split(Platform.pathSeparator).last;
      final totalChunks = (totalBytes / chunkSize).ceil();
      final chunksCol = _itemChunks(userId, item.id);

      final reader = targetFile.openSync(mode: FileMode.read);
      try {
        for (var index = 0; index < totalChunks; index++) {
          final buffer = Uint8List(chunkSize);
          final bytesRead = reader.readIntoSync(buffer);
          final slice = bytesRead == chunkSize
              ? buffer
              : Uint8List.sublistView(buffer, 0, bytesRead);

          await chunksCol.doc('$index').set({
            'index': index,
            'totalChunks': totalChunks,
            'fileName': originalName,
            'sizeBytes': totalBytes,
            'data': Blob(slice),
            'uploadedAt': FieldValue.serverTimestamp(),
          });
        }
      } finally {
        reader.closeSync();
      }

      // Mark the parent item as having cloud binary available
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('items')
          .doc(item.id)
          .set({
        'hasCloudBinary': true,
        'cloudFileName': originalName,
      }, SetOptions(merge: true));

      return true;
    } catch (e) {
      debugPrint('BinarySyncService uploadBinary error: $e');
      return false;
    }
  }

  /// Downloads a binary payload from remote URL or Firestore chunks directly to local disk.
  Future<File?> downloadBinary({
    required String userId,
    required YankItem item,
  }) async {
    // 1. If remote HTTP URL exists, stream directly from network to disk
    if (item.url != null &&
        (item.url!.startsWith('http://') || item.url!.startsWith('https://'))) {
      return _downloadFromHttp(item.url!, item.id);
    }

    // 2. Fetch chunks from Firestore
    try {
      final chunksCol = _itemChunks(userId, item.id);
      final snapshot = await chunksCol.orderBy('index').get();
      if (snapshot.docs.isEmpty) {
        return null;
      }

      final docs = snapshot.docs;
      final firstData = docs.first.data();
      final fileName = firstData['fileName'] as String? ?? '${item.id}.bin';

      final docsDir = LocalPathResolver.documentsDirectory ??
          await getApplicationDocumentsDirectory();
      final capturesDir = Directory('${docsDir.path}/captures');
      if (!capturesDir.existsSync()) {
        await capturesDir.create(recursive: true);
      }

      final destFile = File('${capturesDir.path}/$fileName');
      final writer = destFile.openSync(mode: FileMode.write);

      try {
        for (final doc in docs) {
          final chunkBlob = doc.data()['data'] as Blob?;
          if (chunkBlob != null) {
            writer.writeFromSync(chunkBlob.bytes);
          }
        }
      } finally {
        writer.closeSync();
      }

      return destFile;
    } catch (e) {
      debugPrint('BinarySyncService downloadBinary error: $e');
      return null;
    }
  }

  /// Checks if remote binary chunks exist for this item.
  Future<bool> hasRemoteBinary({
    required String userId,
    required String itemId,
  }) async {
    try {
      final snapshot = await _itemChunks(userId, itemId).limit(1).get();
      return snapshot.docs.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  /// Automatically scans items and uploads any that exist locally on this device
  /// but have not yet been synchronized to cloud storage.
  Future<void> syncPendingUploads({
    required String userId,
    required List<YankItem> items,
  }) async {
    for (final item in items) {
      if (item.deleted || item.kind == ItemKind.text || item.kind == ItemKind.link) {
        continue;
      }

      final localPath = item.artwork ?? item.audioAsset ?? item.url;
      final file = LocalPathResolver.resolveFile(localPath);
      if (file == null || !file.existsSync()) {
        continue;
      }

      // Check if already uploaded
      final hasCloud = await hasRemoteBinary(userId: userId, itemId: item.id);
      if (!hasCloud) {
        await uploadBinary(userId: userId, item: item, file: file);
      }
    }
  }

  Future<File?> _downloadFromHttp(String url, String itemId) async {
    try {
      final uri = Uri.parse(url);
      final client = HttpClient();
      final request = await client.getUrl(uri);
      final response = await request.close();

      if (response.statusCode != 200) {
        return null;
      }

      final docsDir = LocalPathResolver.documentsDirectory ??
          await getApplicationDocumentsDirectory();
      final capturesDir = Directory('${docsDir.path}/captures');
      if (!capturesDir.existsSync()) {
        await capturesDir.create(recursive: true);
      }

      final ext = uri.pathSegments.isNotEmpty && uri.pathSegments.last.contains('.')
          ? '.${uri.pathSegments.last.split('.').last}'
          : '.jpg';
      final destFile = File('${capturesDir.path}/$itemId-download$ext');

      final sink = destFile.openWrite();
      await response.pipe(sink);
      return destFile;
    } catch (e) {
      debugPrint('BinarySyncService _downloadFromHttp error: $e');
      return null;
    }
  }
}
