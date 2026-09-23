import 'package:equatable/equatable.dart';

import 'package:yank/features/library/models/library_projection.dart';
import 'package:yank/features/library/models/yank_item.dart';

const _unchanged = Object();

class LibraryNotice extends Equatable {
  const LibraryNotice(this.serial, this.message, {this.undo});
  final int serial;
  final String message;
  final YankItem? undo;
  @override
  List<Object?> get props => [serial, message, undo];
}

class LibraryState extends Equatable {
  const LibraryState({
    required this.items,
    this.section = LibrarySection.library,
    this.kind,
    this.source,
    this.query = '',
    this.selectedId,
    this.local = const {},
    this.offline = false,
    this.notice,
  });
  final List<YankItem> items;
  final LibrarySection section;
  final ItemKind? kind;
  final String? source;
  final String query;
  final String? selectedId;
  final Map<String, LocalAvailability> local;
  final bool offline;
  final LibraryNotice? notice;
  List<YankItem> get visible => LibraryProjection.select(
    items,
    section: section,
    kind: kind,
    source: source,
    query: query,
  );
  List<String> get sources => LibraryProjection.sources(items, section);
  int get yankCount =>
      items.where((i) => i.isYanked && !i.archived && !i.deleted).length;
  LocalAvailability availability(String id) =>
      local[id] ?? LocalAvailability.available;
  YankItem? item(String id) {
    for (final item in items) {
      if (item.id == id && !item.deleted) {
        return item;
      }
    }
    return null;
  }

  LibraryState copyWith({
    List<YankItem>? items,
    LibrarySection? section,
    Object? kind = _unchanged,
    Object? source = _unchanged,
    String? query,
    Object? selectedId = _unchanged,
    Map<String, LocalAvailability>? local,
    bool? offline,
    LibraryNotice? notice,
  }) => LibraryState(
    items: items ?? this.items,
    section: section ?? this.section,
    kind: identical(kind, _unchanged) ? this.kind : kind as ItemKind?,
    source: identical(source, _unchanged) ? this.source : source as String?,
    query: query ?? this.query,
    selectedId: identical(selectedId, _unchanged)
        ? this.selectedId
        : selectedId as String?,
    local: local ?? this.local,
    offline: offline ?? this.offline,
    notice: notice ?? this.notice,
  );
  @override
  List<Object?> get props => [
    items,
    section,
    kind,
    source,
    query,
    selectedId,
    local,
    offline,
    notice,
  ];
}
