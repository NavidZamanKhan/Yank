import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:yank/features/library/models/yank_item.dart';
import 'package:yank/features/library/repositories/library_repository.dart';
import 'package:yank/features/library/bloc/library_event.dart';
import 'package:yank/features/library/bloc/library_state.dart';
export 'library_event.dart';
export 'library_state.dart';

class LibraryBloc extends Bloc<LibraryEvent, LibraryState> {
  LibraryBloc(this.repository, {LibraryState? initialState})
      : super(initialState ?? LibraryState(items: repository.items)) {
    // One sequential event lane preserves ordering across different mutations,
    // including rapid double taps. Downloads use cancellable completion events
    // so a transfer never blocks searching, filtering, or navigation.
    on<LibraryEvent>(
      _handle,
      transformer: (events, mapper) => events.asyncExpand(mapper),
    );
    _subscription = repository.changes.listen(
      (items) => add(LibraryChanged(items)),
    );
  }
  final LibraryRepository repository;
  late final StreamSubscription<List<YankItem>> _subscription;
  final Map<String, Timer> _downloads = {};
  int _noticeSerial = 0;
  LibraryNotice _notice(String message, {YankItem? undo}) =>
      LibraryNotice(++_noticeSerial, message, undo: undo);

  Future<void> _handle(LibraryEvent event, Emitter<LibraryState> emit) async {
    try {
      switch (event) {
        case LibraryChanged():
          // A queued snapshot may predate a second rapid mutation. Read the
          // current repository snapshot instead of briefly replaying old data.
          final items = repository.items;
          final sourceStillExists = items.any(
            (i) => !i.deleted && !i.archived && i.source == state.source,
          );
          emit(
            state.copyWith(
              items: items,
              source: sourceStillExists ? state.source : null,
            ),
          );
        case SectionChanged(:final section):
          emit(
            state.copyWith(
              section: section,
              kind: null,
              source: null,
              selectedId: null,
            ),
          );
        case KindChanged(:final kind):
          emit(state.copyWith(kind: kind, source: null));
        case SourceChanged(:final source):
          emit(state.copyWith(source: source));
        case QueryChanged(:final query):
          emit(state.copyWith(query: query));
        case PreviewSelected(:final id):
          emit(state.copyWith(selectedId: id));
        case NoticePosted(:final message, :final undo):
          emit(state.copyWith(notice: _notice(message, undo: undo)));
        case ItemYankToggled(:final id):
          final item = _current(id);
          if (item == null) {
            return;
          }
          await repository.put(
            item.copyWith(
              yankedAt: item.isYanked ? null : DateTime.now(),
              archived: item.isYanked ? item.archived : false,
            ),
          );
          emit(
            state.copyWith(
              items: repository.items,
              notice: _notice(
                item.isYanked
                    ? 'Removed from Yank. Still in your library.'
                    : 'Kept close in Yank.',
              ),
            ),
          );
        case ItemArchiveToggled(:final id):
          final item = _current(id);
          if (item == null) {
            return;
          }
          final nextArchived = !item.archived;
          final updated = item.copyWith(
            archived: nextArchived,
            archivedAt: nextArchived ? DateTime.now() : null,
            yankedAt: nextArchived ? null : item.yankedAt,
          );
          await repository.put(updated);
          emit(
            state.copyWith(
              items: repository.items,
              selectedId: null,
              notice: _notice(
                item.archived
                    ? 'Back in your library.'
                    : 'Archived. Deletes automatically after 30 days.',
                undo: item,
              ),
            ),
          );
        case ItemDeleted(:final id):
          final item = _current(id);
          if (item == null) {
            return;
          }
          _downloads.remove(id)?.cancel();
          await repository.delete(id);
          emit(
            state.copyWith(
              items: repository.items,
              selectedId: null,
              notice: _notice('Item deleted.', undo: item),
            ),
          );
        case ItemRestored(:final item):
          await repository.put(item);
          emit(
            state.copyWith(
              items: repository.items,
              notice: _notice('Restored.'),
            ),
          );
        case YankCleared():
          await repository.clearYank();
          emit(
            state.copyWith(
              items: repository.items,
              notice: _notice('Yank cleared. Your library is unchanged.'),
            ),
          );
        case DemoReset():
          for (final timer in _downloads.values) {
            timer.cancel();
          }
          _downloads.clear();
          await repository.reset();
          emit(
            LibraryState(
              items: repository.items,
              notice: _notice('A fresh start. Sample library restored.'),
            ),
          );
        case OfflineToggled(:final offline):
          if (offline) {
            for (final timer in _downloads.values) {
              timer.cancel();
            }
            _downloads.clear();
          }
          emit(
            state.copyWith(
              offline: offline,
              local: Map.unmodifiable({
                for (final entry in state.local.entries)
                  entry.key:
                      offline && entry.value == LocalAvailability.downloading
                      ? LocalAvailability.cloud
                      : entry.value,
              }),
            ),
          );
        case DownloadRequested(:final id):
          if (_current(id) == null ||
              state.availability(id) != LocalAvailability.cloud) {
            return;
          }
          if (state.offline) {
            emit(
              state.copyWith(notice: _notice('Connect to download this item.')),
            );
            return;
          }
          _setLocal(emit, id, LocalAvailability.downloading);
          _downloads[id] = Timer(const Duration(milliseconds: 1400), () {
            if (!isClosed) {
              add(DownloadFinished(id));
            }
          });
        case DownloadFinished(:final id):
          if (_downloads.remove(id) == null || _current(id) == null) {
            return;
          }
          _setLocal(emit, id, LocalAvailability.available);
        case DownloadCancelled(:final id):
          _downloads.remove(id)?.cancel();
          _setLocal(emit, id, LocalAvailability.cloud);
        case LocalCopyRemoved(:final id):
          _downloads.remove(id)?.cancel();
          _setLocal(emit, id, LocalAvailability.cloud);
      }
    } catch (_) {
      emit(
        state.copyWith(
          notice: _notice('That change could not be saved. Please try again.'),
        ),
      );
    }
  }

  YankItem? _current(String id) {
    for (final item in repository.items) {
      if (item.id == id && !item.deleted) {
        return item;
      }
    }
    return null;
  }

  void _setLocal(
    Emitter<LibraryState> emit,
    String id,
    LocalAvailability value,
  ) => emit(
    state.copyWith(local: Map.unmodifiable({...state.local, id: value})),
  );
  @override
  Future<void> close() async {
    await _subscription.cancel();
    for (final timer in _downloads.values) {
      timer.cancel();
    }
    return super.close();
  }
}
