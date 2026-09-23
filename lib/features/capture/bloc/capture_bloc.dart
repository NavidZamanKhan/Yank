import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:yank/features/capture/services/url_metadata_service.dart';
import 'package:yank/features/library/models/library_projection.dart';
import 'package:yank/features/library/models/yank_item.dart';
import 'package:yank/features/library/repositories/library_repository.dart';

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

final class CaptureTitleChanged extends CaptureEvent {
  const CaptureTitleChanged(this.title);
  final String title;
  @override
  List<Object?> get props => [title];
}

final class CaptureFileSelected extends CaptureEvent {
  const CaptureFileSelected({
    required this.filePath,
    required this.fileName,
    required this.fileSize,
  });
  final String filePath;
  final String fileName;
  final int fileSize;
  @override
  List<Object?> get props => [filePath, fileName, fileSize];
}

final class CaptureFileCleared extends CaptureEvent {
  const CaptureFileCleared();
}

final class CaptureSubmitted extends CaptureEvent {
  const CaptureSubmitted();
}

class CaptureState extends Equatable {
  const CaptureState({
    this.kind = ItemKind.link,
    this.value = '',
    this.title = '',
    this.filePath,
    this.fileName,
    this.fileSize = 0,
    this.saving = false,
    this.saved = false,
    this.error,
  });

  final ItemKind kind;
  final String value;
  final String title;
  final String? filePath;
  final String? fileName;
  final int fileSize;
  final bool saving;
  final bool saved;
  final String? error;

  CaptureState copyWith({
    ItemKind? kind,
    String? value,
    String? title,
    String? filePath,
    String? fileName,
    int? fileSize,
    bool? saving,
    bool? saved,
    String? error,
    bool clearFile = false,
    bool clearError = false,
  }) =>
      CaptureState(
        kind: kind ?? this.kind,
        value: value ?? this.value,
        title: title ?? this.title,
        filePath: clearFile ? null : (filePath ?? this.filePath),
        fileName: clearFile ? null : (fileName ?? this.fileName),
        fileSize: clearFile ? 0 : (fileSize ?? this.fileSize),
        saving: saving ?? this.saving,
        saved: saved ?? this.saved,
        error: clearError ? null : (error ?? this.error),
      );

  @override
  List<Object?> get props => [
        kind,
        value,
        title,
        filePath,
        fileName,
        fileSize,
        saving,
        saved,
        error,
      ];
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
        emit(
          CaptureState(
            kind: kind,
            value: '',
            title: '',
          ),
        );

      case CaptureValueChanged(:final value):
        emit(state.copyWith(value: value, clearError: true));

      case CaptureTitleChanged(:final title):
        emit(state.copyWith(title: title, clearError: true));

      case CaptureFileSelected(
          :final filePath,
          :final fileName,
          :final fileSize,
        ):
        emit(
          state.copyWith(
            filePath: filePath,
            fileName: fileName,
            fileSize: fileSize,
            clearError: true,
          ),
        );

      case CaptureFileCleared():
        emit(state.copyWith(clearFile: true, clearError: true));

      case CaptureSubmitted():
        final kind = state.kind;
        final value = state.value.trim();
        final userTitle = state.title.trim();
        final now = DateTime.now();

        if (kind == ItemKind.link) {
          final url = LibraryProjection.normalizeLink(value);
          if (url == null) {
            emit(
              state.copyWith(
                error: 'Add a valid web address, like github.com/flutter.',
              ),
            );
            return;
          }

          emit(state.copyWith(saving: true, clearError: true));

          final derivedTitle = userTitle.isNotEmpty
              ? userTitle
              : Uri.parse(url).host.replaceFirst('www.', '');

          final item = YankItem(
            id: 'capture-${now.microsecondsSinceEpoch}',
            kind: ItemKind.link,
            title: derivedTitle,
            createdAt: now,
            url: url,
            body: userTitle.isNotEmpty ? value : '',
          );

          await _save(item, emit);
          unawaited(UrlMetadataService.enrichItem(repository, item));
          return;
        }

        if (kind == ItemKind.text) {
          if (value.isEmpty) {
            emit(
              state.copyWith(
                error: 'Write something worth keeping.',
              ),
            );
            return;
          }

          emit(state.copyWith(saving: true, clearError: true));

          final firstLine = value.split('\n').first;
          final derivedTitle = userTitle.isNotEmpty
              ? userTitle
              : firstLine.substring(0, firstLine.length.clamp(0, 90));

          final item = YankItem(
            id: 'capture-${now.microsecondsSinceEpoch}',
            kind: ItemKind.text,
            title: derivedTitle,
            createdAt: now,
            body: value,
          );

          await _save(item, emit);
          return;
        }

        if (kind == ItemKind.photo) {
          if (state.filePath == null) {
            emit(
              state.copyWith(
                error: 'Please choose or take a photo first.',
              ),
            );
            return;
          }

          emit(state.copyWith(saving: true, clearError: true));

          final derivedTitle = userTitle.isNotEmpty
              ? userTitle
              : (state.fileName?.isNotEmpty == true
                  ? state.fileName!
                  : 'Photo');

          final item = YankItem(
            id: 'capture-${now.microsecondsSinceEpoch}',
            kind: ItemKind.photo,
            title: derivedTitle,
            createdAt: now,
            body: value,
            artwork: state.filePath,
            sizeBytes: state.fileSize,
          );

          await _save(item, emit);
          return;
        }

        if (kind == ItemKind.audio) {
          if (state.filePath == null) {
            emit(
              state.copyWith(
                error: 'Please select an audio file first.',
              ),
            );
            return;
          }

          emit(state.copyWith(saving: true, clearError: true));

          final derivedTitle = userTitle.isNotEmpty
              ? userTitle
              : (state.fileName?.isNotEmpty == true
                  ? state.fileName!
                  : 'Audio Track');

          final item = YankItem(
            id: 'capture-${now.microsecondsSinceEpoch}',
            kind: ItemKind.audio,
            title: derivedTitle,
            createdAt: now,
            body: value,
            audioAsset: state.filePath,
            sizeBytes: state.fileSize,
          );

          await _save(item, emit);
          return;
        }

        if (kind == ItemKind.file) {
          if (state.filePath == null) {
            emit(
              state.copyWith(
                error: 'Please choose a document or file first.',
              ),
            );
            return;
          }

          emit(state.copyWith(saving: true, clearError: true));

          final derivedTitle = userTitle.isNotEmpty
              ? userTitle
              : (state.fileName?.isNotEmpty == true
                  ? state.fileName!
                  : 'Document');

          final item = YankItem(
            id: 'capture-${now.microsecondsSinceEpoch}',
            kind: ItemKind.file,
            title: derivedTitle,
            createdAt: now,
            url: state.filePath,
            body: value.isNotEmpty
                ? value
                : (state.fileName ?? ''),
            sizeBytes: state.fileSize,
          );

          await _save(item, emit);
          return;
        }
    }
  }

  Future<void> _save(YankItem item, Emitter<CaptureState> emit) async {
    try {
      await repository.put(item);
      emit(state.copyWith(saved: true, saving: false));
    } catch (e) {
      emit(
        state.copyWith(
          saving: false,
          error: 'Could not save this item: $e',
        ),
      );
    }
  }
}
