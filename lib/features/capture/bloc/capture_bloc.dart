import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../library/models/library_projection.dart';
import '../../library/models/yank_item.dart';
import '../../library/repositories/demo_fixtures.dart';
import '../../library/repositories/library_repository.dart';

sealed class CaptureEvent extends Equatable {
  const CaptureEvent();
  @override
  List<Object?> get props => [];
}

final class CaptureKindChanged extends CaptureEvent {
  const CaptureKindChanged(this.kind);
  final ItemKind kind;
  @override
  List<Object?> get props => [kind];
}

final class CaptureValueChanged extends CaptureEvent {
  const CaptureValueChanged(this.value);
  final String value;
  @override
  List<Object?> get props => [value];
}

final class CaptureSubmitted extends CaptureEvent {
  const CaptureSubmitted();
}

class CaptureState extends Equatable {
  const CaptureState({
    this.kind = ItemKind.link,
    this.value = '',
    this.saving = false,
    this.saved = false,
    this.error,
  });
  final ItemKind kind;
  final String value;
  final bool saving, saved;
  final String? error;
  @override
  List<Object?> get props => [kind, value, saving, saved, error];
}

class CaptureBloc extends Bloc<CaptureEvent, CaptureState> {
  CaptureBloc(this.repository) : super(const CaptureState()) {
    on<CaptureEvent>(
      _handle,
      transformer: (events, mapper) => events.asyncExpand(mapper),
    );
  }
  final LibraryRepository repository;
  Future<void> _handle(CaptureEvent event, Emitter<CaptureState> emit) async {
    if (state.saved) {
      return;
    }
    switch (event) {
      case CaptureKindChanged(:final kind):
        emit(CaptureState(kind: kind));
      case CaptureValueChanged(:final value):
        emit(CaptureState(kind: state.kind, value: value));
      case CaptureSubmitted():
        final kind = state.kind;
        final value = state.value.trim();
        final url = kind == ItemKind.link
            ? LibraryProjection.normalizeLink(value)
            : null;
        if (kind == ItemKind.link && url == null) {
          emit(
            CaptureState(
              kind: kind,
              value: value,
              error: 'Add a valid web address, like github.com/flutter.',
            ),
          );
          return;
        }
        if (kind == ItemKind.text && value.isEmpty) {
          emit(
            CaptureState(
              kind: kind,
              value: value,
              error: 'Write something worth keeping.',
            ),
          );
          return;
        }
        emit(CaptureState(kind: kind, value: value, saving: true));
        final now = DateTime.now();
        final title = switch (kind) {
          ItemKind.link => Uri.parse(url!).host.replaceFirst('www.', ''),
          ItemKind.text =>
            value
                .split('\n')
                .first
                .substring(0, value.split('\n').first.length.clamp(0, 90)),
          ItemKind.photo => 'Take the scenic route',
          ItemKind.audio => 'An idea for the weekend',
          ItemKind.file => 'Yank product brief.pdf',
        };
        final item = YankItem(
          id: 'capture-${now.microsecondsSinceEpoch}',
          kind: kind,
          title: title,
          createdAt: now,
          url: url,
          body: kind == ItemKind.text
              ? value
              : kind == ItemKind.file
              ? DemoFixtures.brief
              : '',
          artwork: kind == ItemKind.photo ? 'scenic' : null,
          audioAsset: kind == ItemKind.audio ? 'audio/weekend.wav' : null,
          durationSeconds: kind == ItemKind.audio ? 24 : 0,
          sizeBytes: switch (kind) {
            ItemKind.photo => 640000,
            ItemKind.audio => 768044,
            ItemKind.file => 1800000,
            _ => 0,
          },
        );
        try {
          await repository.put(item);
          emit(CaptureState(kind: kind, saved: true));
        } catch (_) {
          emit(
            CaptureState(
              kind: kind,
              value: value,
              error: 'Could not save this item. Please try again.',
            ),
          );
        }
    }
  }
}
