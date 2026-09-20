import 'package:equatable/equatable.dart';

import 'package:yank/features/library/models/yank_item.dart';

sealed class LibraryEvent extends Equatable {
  const LibraryEvent();
  @override
  List<Object?> get props => [];
}

final class LibraryChanged extends LibraryEvent {
  const LibraryChanged(this.items);
  final List<YankItem> items;
  @override
  List<Object?> get props => [items];
}

final class SectionChanged extends LibraryEvent {
  const SectionChanged(this.section);
  final LibrarySection section;
  @override
  List<Object?> get props => [section];
}

final class KindChanged extends LibraryEvent {
  const KindChanged(this.kind);
  final ItemKind? kind;
  @override
  List<Object?> get props => [kind];
}

final class SourceChanged extends LibraryEvent {
  const SourceChanged(this.source);
  final String? source;
  @override
  List<Object?> get props => [source];
}

final class QueryChanged extends LibraryEvent {
  const QueryChanged(this.query);
  final String query;
  @override
  List<Object?> get props => [query];
}

final class ItemYankToggled extends LibraryEvent {
  const ItemYankToggled(this.id);
  final String id;
  @override
  List<Object?> get props => [id];
}

final class ItemArchiveToggled extends LibraryEvent {
  const ItemArchiveToggled(this.id);
  final String id;
  @override
  List<Object?> get props => [id];
}

final class ItemDeleted extends LibraryEvent {
  const ItemDeleted(this.id);
  final String id;
  @override
  List<Object?> get props => [id];
}

final class ItemRestored extends LibraryEvent {
  const ItemRestored(this.item);
  final YankItem item;
  @override
  List<Object?> get props => [item];
}

final class YankCleared extends LibraryEvent {
  const YankCleared();
}

final class DemoReset extends LibraryEvent {
  const DemoReset();
}

final class PreviewSelected extends LibraryEvent {
  const PreviewSelected(this.id);
  final String? id;
  @override
  List<Object?> get props => [id];
}

final class OfflineToggled extends LibraryEvent {
  const OfflineToggled(this.offline);
  final bool offline;
  @override
  List<Object?> get props => [offline];
}

final class DownloadRequested extends LibraryEvent {
  const DownloadRequested(this.id);
  final String id;
  @override
  List<Object?> get props => [id];
}

final class DownloadFinished extends LibraryEvent {
  const DownloadFinished(this.id);
  final String id;
  @override
  List<Object?> get props => [id];
}

final class DownloadCancelled extends LibraryEvent {
  const DownloadCancelled(this.id);
  final String id;
  @override
  List<Object?> get props => [id];
}

final class LocalCopyRemoved extends LibraryEvent {
  const LocalCopyRemoved(this.id);
  final String id;
  @override
  List<Object?> get props => [id];
}
