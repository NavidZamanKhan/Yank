import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:yank/core/utils/local_path_resolver.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempRoot;
  late Directory mockDocs;
  late Directory mockTemp;
  late Directory mockCaptures;

  setUp(() {
    tempRoot = Directory.systemTemp.createTempSync('yank_path_resolver_test_');
    mockDocs = Directory('${tempRoot.path}/Application/NEW-UUID/Documents')..createSync(recursive: true);
    mockTemp = Directory('${tempRoot.path}/Application/NEW-UUID/tmp')..createSync(recursive: true);
    mockCaptures = Directory('${mockDocs.path}/captures')..createSync(recursive: true);

    LocalPathResolver.setDirectories(
      documentsDirectory: mockDocs,
      temporaryDirectory: mockTemp,
    );
  });

  tearDown(() {
    LocalPathResolver.reset();
    try {
      if (tempRoot.existsSync()) {
        tempRoot.deleteSync(recursive: true);
      }
    } catch (_) {}
  });

  group('LocalPathResolver', () {
    test('returns null for null or empty paths', () {
      expect(LocalPathResolver.resolveFile(null), isNull);
      expect(LocalPathResolver.resolveFile(''), isNull);
      expect(LocalPathResolver.resolveFile('   '), isNull);
      expect(LocalPathResolver.resolve(null), isNull);
      expect(LocalPathResolver.resolve(''), isNull);
    });

    test('returns direct file if it already exists', () {
      final file = File('${tempRoot.path}/direct.txt')..writeAsStringSync('hello');
      final resolved = LocalPathResolver.resolveFile(file.path);
      expect(resolved, isNotNull);
      expect(resolved!.path, equals(file.path));
      expect(resolved.existsSync(), isTrue);
    });

    test('resolves file when iOS application container UUID has changed', () {
      final realFile = File('${mockCaptures.path}/share-123_IMG_0001.JPG')
        ..writeAsStringSync('image_bytes');

      const stalePath =
          '/var/mobile/Containers/Data/Application/OLD-UUID-1111/Documents/captures/share-123_IMG_0001.JPG';

      final resolved = LocalPathResolver.resolveFile(stalePath);
      expect(resolved, isNotNull);
      expect(resolved!.path, equals(realFile.path));
      expect(resolved.existsSync(), isTrue);
    });

    test('resolves image picker file when tmp path moved', () {
      final realTmpFile = File('${mockTemp.path}/image_picker_abc.jpg')
        ..writeAsStringSync('tmp_bytes');

      const staleTmpPath =
          '/var/mobile/Containers/Data/Application/OLD-UUID-2222/tmp/image_picker_abc.jpg';

      final resolved = LocalPathResolver.resolveFile(staleTmpPath);
      expect(resolved, isNotNull);
      expect(resolved!.path, equals(realTmpFile.path));
      expect(resolved.existsSync(), isTrue);
    });

    test('resolves Android app_flutter captures path', () {
      final realFile = File('${mockCaptures.path}/photo.jpg')
        ..writeAsStringSync('android_photo');

      const androidOldPath =
          '/data/user/0/com.example.yank/app_flutter/captures/photo.jpg';

      final resolved = LocalPathResolver.resolveFile(androidOldPath);
      expect(resolved, isNotNull);
      expect(resolved!.path, equals(realFile.path));
    });

    test('resolves by basename lookup in captures directory', () {
      final realFile = File('${mockCaptures.path}/document.pdf')
        ..writeAsStringSync('pdf_bytes');

      const foreignPath = '/some/unrelated/path/to/document.pdf';

      final resolved = LocalPathResolver.resolveFile(foreignPath);
      expect(resolved, isNotNull);
      expect(resolved!.path, equals(realFile.path));
    });

    test('resolves relative path against documents directory', () {
      final realFile = File('${mockCaptures.path}/sample.png')
        ..writeAsStringSync('png_data');

      final resolved = LocalPathResolver.resolveFile('captures/sample.png');
      expect(resolved, isNotNull);
      expect(resolved!.path, equals(realFile.path));
    });

    test('resolveOrOriginal returns original path when unresolvable', () {
      const nonExistent = '/non/existent/file.xyz';
      expect(
        LocalPathResolver.resolveOrOriginal(nonExistent),
        equals(nonExistent),
      );
    });
  });
}
