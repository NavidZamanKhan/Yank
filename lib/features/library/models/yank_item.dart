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
    Object? yankedAt = _unchanged,
    bool? archived,
    bool? deleted,
  }) => YankItem(
    id: id,
    kind: kind,
    title: title ?? this.title,
    createdAt: createdAt,
    body: body ?? this.body,
    url: url,
    artwork: artwork,
    audioAsset: audioAsset,
    durationSeconds: durationSeconds,
    sizeBytes: sizeBytes,
    yankedAt: identical(yankedAt, _unchanged)
        ? this.yankedAt
        : yankedAt as DateTime?,
    archived: archived ?? this.archived,
    deleted: deleted ?? this.deleted,
  );

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
  factory YankItem.fromJson(Map<String, dynamic> json) => YankItem(
    id: json['id'] as String,
    kind: ItemKind.values.byName(json['kind'] as String),
    title: json['title'] as String,
    createdAt: DateTime.parse(json['createdAt'] as String),
    body: json['body'] as String? ?? '',
    url: json['url'] as String?,
    artwork: json['artwork'] as String?,
    audioAsset: json['audioAsset'] as String?,
    durationSeconds: json['durationSeconds'] as int? ?? 0,
    sizeBytes: json['sizeBytes'] as int? ?? 0,
    yankedAt: json['yankedAt'] == null
        ? null
        : DateTime.parse(json['yankedAt'] as String),
    archived: json['archived'] as bool? ?? false,
    deleted: json['deleted'] as bool? ?? false,
  );
}
