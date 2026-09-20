import 'package:yank/features/library/models/yank_item.dart';

abstract final class LibraryProjection {
  static List<YankItem> select(
    Iterable<YankItem> items, {
    LibrarySection section = LibrarySection.library,
    ItemKind? kind,
    String? source,
    String query = '',
  }) {
    final terms = query
        .toLowerCase()
        .trim()
        .split(RegExp(r'\s+'))
        .where((s) => s.isNotEmpty);
    final result = items.where((item) {
      if (item.deleted) {
        return false;
      }
      final inSection = switch (section) {
        LibrarySection.library => query.trim().isNotEmpty || !item.archived,
        LibrarySection.yank => item.isYanked && !item.archived,
        LibrarySection.archive => item.archived,
      };
      if (!inSection || (kind != null && kind != item.kind)) {
        return false;
      }
      if (source != null && item.source != source) {
        return false;
      }
      final searchable =
          '${item.title} ${item.body} ${item.url ?? ''} ${item.source} ${item.kind.label}'
              .toLowerCase();
      return terms.every(searchable.contains);
    }).toList();
    result.sort((a, b) {
      final aTime = section == LibrarySection.yank ? a.yankedAt! : a.createdAt;
      final bTime = section == LibrarySection.yank ? b.yankedAt! : b.createdAt;
      final order = bTime.compareTo(aTime);
      return order == 0 ? a.id.compareTo(b.id) : order;
    });
    return List.unmodifiable(result);
  }

  static List<String> sources(
    Iterable<YankItem> items,
    LibrarySection section,
  ) {
    final result = select(
      items,
      section: section,
      kind: ItemKind.link,
    ).map((i) => i.source).toSet().toList()..sort();
    return result;
  }

  static String? normalizeLink(String input) {
    final raw = input.trim();
    if (raw.isEmpty || RegExp(r'\s').hasMatch(raw)) {
      return null;
    }
    final uri = Uri.tryParse(raw.contains('://') ? raw : 'https://$raw');
    if (uri == null ||
        !{'https', 'http'}.contains(uri.scheme) ||
        !uri.host.contains('.') ||
        uri.userInfo.isNotEmpty) {
      return null;
    }
    return uri.toString();
  }
}
