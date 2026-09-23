// Domain data stays independent of Flutter, plugins, and device availability.
const _unchanged = Object();

enum ItemKind { link, photo, audio, file, text }

enum LibrarySection { library, yank, archive }

enum LocalAvailability { available, cloud, downloading }

extension ItemKindLabel on ItemKind {
  String get label => switch (this) {
    ItemKind.link => 'Links',
    ItemKind.photo => 'Photos',
    ItemKind.audio => 'Audio',
    ItemKind.file => 'Files',
    ItemKind.text => 'Text',
  };
}

class YankItem {
  const YankItem({
    required this.id,
    required this.kind,
    required this.title,
    required this.createdAt,
    this.body = '',
    this.url,
    this.artwork,
    this.audioAsset,
    this.durationSeconds = 0,
    this.sizeBytes = 0,
    this.yankedAt,
    this.archived = false,
    this.deleted = false,
  });
  final String id;
  final ItemKind kind;
  final String title;
  final DateTime createdAt;
  final String body;
  final String? url;
  final String? artwork;
  final String? audioAsset;
  final int durationSeconds;
  final int sizeBytes;
  final DateTime? yankedAt;
  final bool archived;
  final bool deleted;
  bool get isYanked => yankedAt != null;
  String get displayTitle {
    final withoutPrefix = title
        .replaceFirst(RegExp(r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}_'), '')
        .replaceFirst(RegExp(r'^[0-9a-fA-F]{32}_'), '')
        .replaceFirst(RegExp(r'^[0-9a-fA-F]{8}_'), '')
        .replaceFirst(RegExp(r'^share-\d+-\d+-'), '');
    var cleaned = withoutPrefix.isNotEmpty ? withoutPrefix : title;

    if (kind == ItemKind.link) {
      cleaned = _cleanLinkTitle(cleaned);
    }

    return cleaned.isNotEmpty ? cleaned : title;
  }

  String _cleanLinkTitle(String raw) {
    var text = raw.trim();

    // 1. If title is a raw URL, display clean path or domain
    if (text.startsWith('http://') || text.startsWith('https://')) {
      final uri = Uri.tryParse(text);
      if (uri != null && uri.host.isNotEmpty) {
        final path = uri.path.replaceAll(RegExp(r'^/|/$'), '');
        if (path.isNotEmpty && !path.contains(RegExp(r'^(index|default)\.'))) {
          text = path;
        } else {
          text = uri.host.replaceFirst(RegExp(r'^www\.'), '');
        }
      }
    }

    // 2. Strip brand prefixes and suffixes
    final brandNames = <String>{
      if (source.isNotEmpty && source != kind.label) source,
      if (domain.isNotEmpty) domain,
      if (domain.contains('.')) domain.split('.').first,
      'GitHub',
      'YouTube',
      'Instagram',
      'Facebook',
      'Reddit',
      'Twitter',
      'Medium',
      'Substack',
      'The Verge',
      'Wikipedia',
      'LinkedIn',
      'Flutter',
    };

    for (final brand in brandNames) {
      if (brand.length < 2) continue;
      final escaped = RegExp.escape(brand);
      // Strip prefix: Brand - Title or Brand: Title
      final prefixPattern = RegExp(
        '^$escaped\\s*[-:\\u2013\\u2014|•·]\\s*',
        caseSensitive: false,
      );
      text = text.replaceFirst(prefixPattern, '');

      // Strip suffix: Title - Brand or Title | Brand or Title - on Brand
      final suffixPattern = RegExp(
        '\\s*[-:\\u2013\\u2014|•·]\\s*(?:on\\s+)?$escaped\$',
        caseSensitive: false,
      );
      text = text.replaceFirst(suffixPattern, '');
    }

    // Strip author suffix: " | by Author Name"
    final authorPattern = RegExp(
      '\\s*[-:\\u2013\\u2014|•·]\\s*by\\s+[^|:\\u2013\\u2014•·-]+\$',
      caseSensitive: false,
    );
    text = text.replaceFirst(authorPattern, '');

    // 3. Colon separation: Title: Subtitle / Description
    // e.g. "NavidZamanKhan/Yank: Cross-device universal capture inbox..."
    if (text.contains(': ')) {
      final parts = text.split(': ');
      if (parts.length >= 2) {
        final prefix = parts[0].trim();
        final suffix = parts.sublist(1).join(': ').trim();

        final isRepo = RegExp(r'^[\w.-]+/[\w.-]+$').hasMatch(prefix);

        bool suffixRepeatsBody = false;
        if (body.isNotEmpty) {
          final b = body.trim().toLowerCase();
          final s = suffix.toLowerCase();
          final checkLen = s.length < 15 ? s.length : 15;
          final sample = s.substring(0, checkLen);
          final bCheckLen = b.length < 15 ? b.length : 15;
          final bSample = b.substring(0, bCheckLen);
          suffixRepeatsBody = b.contains(sample) || s.contains(bSample);
        }

        if (isRepo ||
            suffixRepeatsBody ||
            (source == 'GitHub' && parts.length == 2) ||
            (prefix.length <= 40 && suffix.length > 35 && suffix.contains(' '))) {
          if (prefix.isNotEmpty) {
            text = prefix;
          }
        }
      }
    }

    // 4. Strip any leading/trailing separator punctuation left over
    text = text
        .replaceAll(
          RegExp('^[\\s\\-:|\u2013\u2014•·]+|[\\s\\-:|\u2013\u2014•·]+\$'),
          '',
        )
        .trim();

    return text.isNotEmpty ? text : raw;
  }
  String get domain => url == null
      ? ''
      : (Uri.tryParse(url!)?.host ?? '').replaceFirst(RegExp(r'^www\.'), '');
  String get source => switch (domain) {
    'github.com' => 'GitHub',
    'youtube.com' || 'youtu.be' => 'YouTube',
    'instagram.com' => 'Instagram',
    'facebook.com' || 'fb.com' => 'Facebook',
    'reddit.com' => 'Reddit',
    'docs.flutter.dev' || 'flutter.dev' => 'Flutter',
    '' => kind.label,
    _ => domain,
  };

  YankItem copyWith({
    String? title,
    String? body,
    String? url,
    String? artwork,
    String? audioAsset,
    int? durationSeconds,
    int? sizeBytes,
    Object? yankedAt = _unchanged,
    bool? archived,
    bool? deleted,
  }) => YankItem(
    id: id,
    kind: kind,
    title: title ?? this.title,
    createdAt: createdAt,
    body: body ?? this.body,
    url: url ?? this.url,
    artwork: artwork ?? this.artwork,
    audioAsset: audioAsset ?? this.audioAsset,
    durationSeconds: durationSeconds ?? this.durationSeconds,
    sizeBytes: sizeBytes ?? this.sizeBytes,
    yankedAt: identical(yankedAt, _unchanged)
        ? this.yankedAt
        : yankedAt as DateTime?,
    archived: archived ?? this.archived,
    deleted: deleted ?? this.deleted,
  );

  static DateTime _parseDateTime(dynamic value) {
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
    try {
      final dynamic dyn = value;
      final dt = dyn.toDate();
      if (dt is DateTime) return dt;
    } catch (_) {}
    return DateTime.now();
  }

  static DateTime? _parseNullableDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    try {
      final dynamic dyn = value;
      final dt = dyn.toDate();
      if (dt is DateTime) return dt;
    } catch (_) {}
    return null;
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'kind': kind.name,
    'title': title,
    'createdAt': createdAt.toIso8601String(),
    'body': body,
    'url': url,
    'artwork': artwork,
    'audioAsset': audioAsset,
    'durationSeconds': durationSeconds,
    'sizeBytes': sizeBytes,
    'yankedAt': yankedAt?.toIso8601String(),
    'archived': archived,
    'deleted': deleted,
  };

  factory YankItem.fromMap(Map<String, dynamic> json, {String? id}) => YankItem(
    id: id ?? (json['id'] as String? ?? ''),
    kind: ItemKind.values.where((k) => k.name == json['kind']).firstOrNull ??
        ItemKind.link,
    title: json['title'] as String? ?? '',
    createdAt: _parseDateTime(json['createdAt']),
    body: json['body'] as String? ?? '',
    url: json['url'] as String?,
    artwork: json['artwork'] as String?,
    audioAsset: json['audioAsset'] as String?,
    durationSeconds: json['durationSeconds'] as int? ?? 0,
    sizeBytes: json['sizeBytes'] as int? ?? 0,
    yankedAt: _parseNullableDateTime(json['yankedAt']),
    archived: json['archived'] as bool? ?? false,
    deleted: json['deleted'] as bool? ?? false,
  );

  factory YankItem.fromJson(Map<String, dynamic> json) =>
      YankItem.fromMap(json);
}
