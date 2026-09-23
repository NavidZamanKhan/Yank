import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:yank/core/utils/local_path_resolver.dart';
import 'package:yank/features/capture/services/binary_sync_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('yank_sync_test_');
    LocalPathResolver.setDirectories(
      documentsDirectory: Directory('${tempDir.path}/docs'),
      temporaryDirectory: Directory('${tempDir.path}/tmp'),
    );
  });

  tearDown(() async {
    LocalPathResolver.reset();
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('BinarySyncService chunking and assembly tests', () {
    test('verifies chunk calculation logic for large binaries', () {
      const totalBytes = 1200 * 1024; // 1.2 MB
      final expectedChunks = (totalBytes / BinarySyncService.chunkSize).ceil();
      expect(expectedChunks, equals(3));
    });

    test('reassembles byte chunks into exact identical binary file on disk', () async {
      final docsDir = Directory('${tempDir.path}/docs/captures');
      await docsDir.create(recursive: true);

      // Create test payload of 800 KB with predictable byte pattern
      const sampleSize = 800 * 1024;
      final originalBytes = Uint8List(sampleSize);
      for (var i = 0; i < sampleSize; i++) {
        originalBytes[i] = i % 256;
      }

      // Simulate chunking
      final chunks = <Uint8List>[];
      for (var i = 0; i < sampleSize; i += BinarySyncService.chunkSize) {
        final end = (i + BinarySyncService.chunkSize < sampleSize)
            ? i + BinarySyncService.chunkSize
            : sampleSize;
        chunks.add(Uint8List.sublistView(originalBytes, i, end));
      }

      expect(chunks.length, equals(2));

      // Simulate download assembly directly to disk
      final destFile = File('${docsDir.path}/assembled_image.jpg');
      final writer = destFile.openSync(mode: FileMode.write);
      for (final chunk in chunks) {
        writer.writeFromSync(chunk);
      }
      writer.closeSync();

      expect(destFile.existsSync(), isTrue);
      expect(destFile.lengthSync(), equals(sampleSize));

      final readBack = await destFile.readAsBytes();
      expect(readBack, equals(originalBytes));
    });
  });
}
