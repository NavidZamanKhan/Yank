import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:yank/features/library/models/yank_item.dart';
import 'package:yank/features/library/repositories/library_repository.dart';

class UrlMetadata {
  const UrlMetadata({
    required this.url,
    this.title,
    this.description,
    this.imageUrl,
    this.siteName,
  });

  final String url;
  final String? title;
  final String? description;
  final String? imageUrl;
  final String? siteName;

  bool get hasContent =>
      (title != null && title!.isNotEmpty) ||
      (description != null && description!.isNotEmpty) ||
      (imageUrl != null && imageUrl!.isNotEmpty);
}

class UrlMetadataService {
  static const String _defaultUserAgent =
      'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) '
      'AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36';

  static String decodeHtmlEntities(String text) {
    if (text.isEmpty) return text;
    var result = text
        .replaceAll('&amp;', '&')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll('&apos;', "'")
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&#x2F;', '/');

    // Decode decimal numeric entities &#123;
    result = result.replaceAllMapped(RegExp(r'&#(\d+);'), (match) {
      try {
        final code = int.parse(match.group(1)!);
        return String.fromCharCode(code);
      } catch (_) {
        return match.group(0)!;
      }
    });

    // Decode hex numeric entities &#x1F44D;
    result = result.replaceAllMapped(RegExp(r'&#x([0-9a-fA-F]+);'), (match) {
      try {
        final code = int.parse(match.group(1)!, radix: 16);
        return String.fromCharCode(code);
      } catch (_) {
        return match.group(0)!;
      }
    });

    return result.trim().replaceAll(RegExp(r'\s+'), ' ');
  }

  static String? _getMetaContent(String html, List<String> targets) {
    for (final target in targets) {
      final escaped = RegExp.escape(target);

      // Pattern 1: property="og:..." content="..."
      final pattern1 = RegExp(
        '<meta\\s+[^>]*?(?:property|name)=["\']$escaped["\'][^>]*?content=["\'](.*?)["\']',
        caseSensitive: false,
        dotAll: true,
      );
      final m1 = pattern1.firstMatch(html);
      if (m1 != null && m1.group(1) != null && m1.group(1)!.trim().isNotEmpty) {
        return decodeHtmlEntities(m1.group(1)!);
      }

      // Pattern 2: content="..." property="og:..."
      final pattern2 = RegExp(
        '<meta\\s+[^>]*?content=["\'](.*?)["\'][^>]*?(?:property|name)=["\']$escaped["\']',
        caseSensitive: false,
        dotAll: true,
      );
      final m2 = pattern2.firstMatch(html);
      if (m2 != null && m2.group(1) != null && m2.group(1)!.trim().isNotEmpty) {
        return decodeHtmlEntities(m2.group(1)!);
      }
    }
    return null;
  }

  static UrlMetadata parseHtml(String html, Uri baseUri) {
    // 1. Title extraction priority: og:title -> twitter:title -> <title>
    var title = _getMetaContent(html, ['og:title', 'twitter:title']);
    if (title == null || title.isEmpty) {
      final titleTagMatch = RegExp(
        r'<title[^>]*>(.*?)</title>',
        caseSensitive: false,
        dotAll: true,
      ).firstMatch(html);
      if (titleTagMatch != null && titleTagMatch.group(1) != null) {
        final rawTitle = decodeHtmlEntities(titleTagMatch.group(1)!);
        if (rawTitle.isNotEmpty) {
          title = rawTitle;
        }
      }
    }

    // 2. Description extraction priority: og:description -> twitter:description -> description
    final description = _getMetaContent(
      html,
      ['og:description', 'twitter:description', 'description'],
    );

    // 3. Image extraction priority: og:image -> twitter:image -> twitter:image:src
    var imageUrl = _getMetaContent(
      html,
      ['og:image', 'twitter:image', 'twitter:image:src'],
    );

    if (imageUrl != null && imageUrl.isNotEmpty) {
      try {
        final resolved = baseUri.resolve(imageUrl);
        if (resolved.scheme == 'http' || resolved.scheme == 'https') {
          imageUrl = resolved.toString();
        }
      } catch (_) {}
    }

    // 4. Site name
    final siteName = _getMetaContent(html, ['og:site_name']);

    return UrlMetadata(
      url: baseUri.toString(),
      title: title != null && title.isNotEmpty ? title : null,
      description:
          description != null && description.isNotEmpty ? description : null,
      imageUrl: imageUrl != null && imageUrl.isNotEmpty ? imageUrl : null,
      siteName: siteName != null && siteName.isNotEmpty ? siteName : null,
    );
  }

  static Future<UrlMetadata?> extract(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null || (uri.scheme != 'http' && uri.scheme != 'https')) {
      return null;
    }

    HttpClient? client;
    try {
      client = HttpClient()
        ..connectionTimeout = const Duration(seconds: 5)
        ..idleTimeout = const Duration(seconds: 3);

      final request = await client.getUrl(uri).timeout(const Duration(seconds: 6));
      request.headers.set(HttpHeaders.userAgentHeader, _defaultUserAgent);
      request.headers.set(
        HttpHeaders.acceptHeader,
        'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
      );
      request.followRedirects = true;
      request.maxRedirects = 5;

      final response = await request.close().timeout(const Duration(seconds: 6));
      if (response.statusCode != HttpStatus.ok) {
        return null;
      }

      final contentType = response.headers.contentType;
      if (contentType != null &&
          contentType.mimeType != 'text/html' &&
          contentType.mimeType != 'application/xhtml+xml') {
        return null;
      }

      final buffer = StringBuffer();
      const maxReadChars = 80000;

      await for (final chunk in response.transform(utf8.decoder)) {
        buffer.write(chunk);
        if (buffer.length >= maxReadChars ||
            buffer.toString().contains('</head>')) {
          break;
        }
      }

      return parseHtml(buffer.toString(), uri);
    } catch (e) {
      debugPrint('UrlMetadataService.extract error for $url: $e');
      return null;
    } finally {
      client?.close(force: true);
    }
  }

  static Future<void> enrichItem(LibraryRepository repository, YankItem item) async {
    if (item.kind != ItemKind.link || item.url == null || item.url!.isEmpty) {
      return;
    }

    try {
      final metadata = await extract(item.url!);
      if (metadata == null || !metadata.hasContent) {
        return;
      }

      // Check current item in repository to make sure it was not deleted
      final current = repository.items.where((i) => i.id == item.id).firstOrNull;
      if (current == null || current.deleted) {
        return;
      }

      // Determine updated title
      var updatedTitle = current.title;
      final host = Uri.tryParse(current.url ?? '')?.host.replaceFirst('www.', '') ?? '';
      final isGenericTitle = current.title == host ||
          current.title == current.url ||
          current.title == 'Link' ||
          current.title.isEmpty;

      if (isGenericTitle && metadata.title != null && metadata.title!.isNotEmpty) {
        updatedTitle = metadata.title!;
      }

      // Determine updated body/description
      var updatedBody = current.body;
      final isBodyEmptyOrUrl = current.body.isEmpty || current.body == current.url;
      if (isBodyEmptyOrUrl && metadata.description != null && metadata.description!.isNotEmpty) {
        updatedBody = metadata.description!;
      }

      // Determine updated artwork (preview image)
      var updatedArtwork = current.artwork;
      if ((updatedArtwork == null || updatedArtwork.isEmpty) &&
          metadata.imageUrl != null &&
          metadata.imageUrl!.isNotEmpty) {
        updatedArtwork = metadata.imageUrl!;
      }

      if (updatedTitle != current.title ||
          updatedBody != current.body ||
          updatedArtwork != current.artwork) {
        final enriched = current.copyWith(
          title: updatedTitle,
          body: updatedBody,
          artwork: updatedArtwork,
        );
        await repository.put(enriched);
      }
    } catch (e) {
      debugPrint('UrlMetadataService.enrichItem error: $e');
    }
  }
}
