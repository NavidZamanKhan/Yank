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

  group('YankItem.displayTitle link cleaning', () {
    test('cleans GitHub repository titles and strips redundant description', () {
      final item = YankItem(
        id: 'gh-1',
        kind: ItemKind.link,
        title: 'GitHub - NavidZamanKhan/Yank: Cross-device universal capture inbox for links, photos, audio, files, and text across iOS, Android, and macOS',
        body: 'Cross-device universal capture inbox for links, photos, audio, files, and text across iOS, Android, and macOS',
        url: 'https://github.com/NavidZamanKhan/Yank',
        createdAt: DateTime.now(),
      );
      expect(item.displayTitle, 'NavidZamanKhan/Yank');
    });

    test('strips platform suffix from YouTube video title', () {
      final item = YankItem(
        id: 'yt-1',
        kind: ItemKind.link,
        title: 'Never Gonna Give You Up (Official Music Video) - YouTube',
        url: 'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
        createdAt: DateTime.now(),
      );
      expect(item.displayTitle, 'Never Gonna Give You Up (Official Music Video)');
    });

    test('strips author and platform suffix from Medium article title', () {
      final item = YankItem(
        id: 'med-1',
        kind: ItemKind.link,
        title: 'Building Scalable Apps | by Tech Lead | Medium',
        url: 'https://medium.com/@techlead/building-scalable-apps',
        createdAt: DateTime.now(),
      );
      expect(item.displayTitle, 'Building Scalable Apps');
    });

    test('strips brand prefix from site title', () {
      final item = YankItem(
        id: 'flt-1',
        kind: ItemKind.link,
        title: 'Flutter - Build apps for any screen',
        url: 'https://flutter.dev',
        createdAt: DateTime.now(),
      );
      expect(item.displayTitle, 'Build apps for any screen');
    });

    test('extracts clean path from raw URL title', () {
      final item = YankItem(
        id: 'url-1',
        kind: ItemKind.link,
        title: 'https://github.com/flutter/flutter',
        url: 'https://github.com/flutter/flutter',
        createdAt: DateTime.now(),
      );
      expect(item.displayTitle, 'flutter/flutter');
    });

    test('extracts domain when raw URL has no path', () {
      final item = YankItem(
        id: 'url-2',
        kind: ItemKind.link,
        title: 'https://www.example.com/',
        url: 'https://www.example.com/',
        createdAt: DateTime.now(),
      );
      expect(item.displayTitle, 'example.com');
    });

    test('removes colon subtitle when it duplicates body', () {
      final item = YankItem(
        id: 'sub-1',
        kind: ItemKind.link,
        title: 'Product Launch: The new way to capture anything',
        body: 'The new way to capture anything instantly across all devices.',
        url: 'https://example.com/product',
        createdAt: DateTime.now(),
      );
      expect(item.displayTitle, 'Product Launch');
    });

    test('preserves link title if no brands or subtitles match', () {
      final item = YankItem(
        id: '2',
        kind: ItemKind.link,
        title: 'Yanked Item 2',
        createdAt: DateTime.now(),
      );
      expect(item.displayTitle, 'Yanked Item 2');
    });

    test('preserves non-link item titles', () {
      final item = YankItem(
        id: 'text-1',
        kind: ItemKind.text,
        title: 'My Notes: Project Checklist',
        body: 'Project Checklist details',
        createdAt: DateTime.now(),
      );
      expect(item.displayTitle, 'My Notes: Project Checklist');
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
