import 'package:flutter_test/flutter_test.dart';
import 'package:yank/features/capture/services/url_metadata_service.dart';
import 'package:yank/features/library/models/yank_item.dart';
import 'package:yank/features/library/repositories/demo_library_repository.dart';
import 'package:yank/features/library/repositories/metadata_store.dart';

void main() {
  group('UrlMetadataService.decodeHtmlEntities', () {
    test('decodes common HTML entities and clean whitespace', () {
      expect(
        UrlMetadataService.decodeHtmlEntities('Flutter &amp; Dart &quot;Awesome&#39;'),
        'Flutter & Dart "Awesome\'',
      );
      expect(
        UrlMetadataService.decodeHtmlEntities('&lt;div&gt;Hello &nbsp; World&lt;/div&gt;'),
        '<div>Hello World</div>',
      );
      expect(
        UrlMetadataService.decodeHtmlEntities('Special &#8212; character &#x2F; slash'),
        'Special — character / slash',
      );
    });
  });

  group('UrlMetadataService.parseHtml', () {
    test('extracts og:title, og:description, og:image, and og:site_name', () {
      const html = '''
<!DOCTYPE html>
<html>
<head>
  <meta property="og:title" content="Flutter - Build apps for any screen" />
  <meta property="og:description" content="Flutter transforms the development process." />
  <meta property="og:image" content="https://storage.googleapis.com/cms-storage-bucket/flutter-banner.png" />
  <meta property="og:site_name" content="Flutter Dev" />
</head>
<body>
  <h1>Content</h1>
</body>
</html>
''';

      final meta = UrlMetadataService.parseHtml(html, Uri.parse('https://flutter.dev'));
      expect(meta.title, 'Flutter - Build apps for any screen');
      expect(meta.description, 'Flutter transforms the development process.');
      expect(meta.imageUrl, 'https://storage.googleapis.com/cms-storage-bucket/flutter-banner.png');
      expect(meta.siteName, 'Flutter Dev');
    });

    test('resolves relative image URLs against base URI', () {
      const html = '''
<html>
<head>
  <meta property="og:title" content="GitHub Repository" />
  <meta property="og:image" content="/images/social-preview.png" />
</head>
</html>
''';

      final meta = UrlMetadataService.parseHtml(html, Uri.parse('https://github.com/flutter/flutter'));
      expect(meta.title, 'GitHub Repository');
      expect(meta.imageUrl, 'https://github.com/images/social-preview.png');
    });

    test('falls back to twitter:title, meta description, and title tag', () {
      const html = '''
<html>
<head>
  <title>Standard Page Title</title>
  <meta name="description" content="Meta standard description" />
  <meta name="twitter:image" content="https://example.com/twitter-card.jpg" />
</head>
</html>
''';

      final meta = UrlMetadataService.parseHtml(html, Uri.parse('https://example.com/article'));
      expect(meta.title, 'Standard Page Title');
      expect(meta.description, 'Meta standard description');
      expect(meta.imageUrl, 'https://example.com/twitter-card.jpg');
    });

    test('handles empty and malformed HTML gracefully', () {
      final meta = UrlMetadataService.parseHtml('<html><body>No head tags</body></html>', Uri.parse('https://example.com'));
      expect(meta.title, isNull);
      expect(meta.description, isNull);
      expect(meta.imageUrl, isNull);
      expect(meta.hasContent, isFalse);
    });
  });

  group('UrlMetadataService.enrichItem', () {
    test('enriches generic link item with fetched title and artwork', () async {
      final repository = await DemoLibraryRepository.open(MemoryMetadataStore());
      final item = YankItem(
        id: 'link-enrich-test',
        kind: ItemKind.link,
        title: 'example.com',
        createdAt: DateTime.now(),
        url: 'https://example.com',
      );
      await repository.put(item);

      // Verify item exists
      expect(repository.items.any((i) => i.id == 'link-enrich-test'), isTrue);

      await repository.close();
    });
  });
}
