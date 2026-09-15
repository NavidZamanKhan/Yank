import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../library/models/yank_item.dart';
import '../repositories/audio_repository.dart';

sealed class AudioEvent extends Equatable {
  const AudioEvent();
  @override
  List<Object?> get props => [];
}

final class AudioTapped extends AudioEvent {
  const AudioTapped(this.item);
  final YankItem item;
  @override
  List<Object?> get props => [item];
}

final class AudioSeeked extends AudioEvent {
  const AudioSeeked(this.position);
  final Duration position;
  @override
  List<Object?> get props => [position];
}

final class AudioStopped extends AudioEvent {
  const AudioStopped();
}

final class _AudioFrameArrived extends AudioEvent {
  const _AudioFrameArrived(this.frame);
  final AudioFrame frame;
  @override
  List<Object?> get props => [frame];
}

final class _AudioFailed extends AudioEvent {
  const _AudioFailed();
}

class AudioState extends Equatable {
  const AudioState({
    this.item,
    this.position = Duration.zero,
    this.duration = Duration.zero,
    this.playing = false,
    this.loading = false,
    this.error,
    this.errorSerial = 0,
  });
  final YankItem? item;
  final Duration position, duration;
  final bool playing, loading;
  final String? error;
  final int errorSerial;
  AudioState copyWith({
    Duration? position,
    Duration? duration,
    bool? playing,
    bool? loading,
  }) => AudioState(
    item: item,
    position: position ?? this.position,
    duration: duration ?? this.duration,
    playing: playing ?? this.playing,
    loading: loading ?? this.loading,
    errorSerial: errorSerial,
  );
  @override
  List<Object?> get props => [
    item,
    position,
    duration,
    playing,
    loading,
    error,
    errorSerial,
  ];
}

class AudioBloc extends Bloc<AudioEvent, AudioState> {
  AudioBloc(this.repository) : super(const AudioState()) {
    on<AudioEvent>(
      _handle,
      transformer: (events, mapper) => events.asyncExpand(mapper),
    );
    _subscription = repository.frames.listen(
      (frame) => add(_AudioFrameArrived(frame)),
      onError: (Object _) {
        if (!isClosed) {
          add(const _AudioFailed());
        }
      },
    );
  }
  final AudioRepository repository;
  late final StreamSubscription<AudioFrame> _subscription;
  Future<void> _handle(AudioEvent event, Emitter<AudioState> emit) async {
    try {
      switch (event) {
        case AudioTapped(:final item):
          if (item.audioAsset == null) {
            return;
          }
          if (state.item?.id == item.id) {
            if (state.playing) {
              await repository.pause();
              emit(state.copyWith(playing: false));
            } else {
              if (state.position == Duration.zero) {
                await repository.play(item.id, item.audioAsset!);
              } else {
                await repository.resume();
              }
              emit(state.copyWith(playing: true));
            }
          } else {
            emit(
              AudioState(
                item: item,
                loading: true,
                duration: Duration(seconds: item.durationSeconds),
                errorSerial: state.errorSerial,
              ),
            );
            await repository.play(item.id, item.audioAsset!);
            emit(state.copyWith(loading: false, playing: true));
          }
        case AudioSeeked(:final position):
          if (state.item == null) {
            return;
          }
          await repository.seek(position);
          emit(state.copyWith(position: position));
        case AudioStopped():
          await repository.stop();
          emit(AudioState(errorSerial: state.errorSerial));
        case _AudioFrameArrived(:final frame):
          if (frame.id != state.item?.id) {
            return;
          }
          emit(
            state.copyWith(
              position: frame.completed ? Duration.zero : frame.position,
              duration: frame.duration > Duration.zero
                  ? frame.duration
                  : state.duration,
              playing: frame.playing,
              loading: false,
            ),
          );
        case _AudioFailed():
          await repository.stop();
          emit(
            AudioState(
              error: 'This audio could not be played. Please try again.',
              errorSerial: state.errorSerial + 1,
            ),
          );
      }
    } catch (_) {
      emit(
        AudioState(
          error: 'This audio could not be played. Please try again.',
          errorSerial: state.errorSerial + 1,
        ),
      );
    }
  }

  @override
  Future<void> close() async {
    await _subscription.cancel();
    await repository.close();
    return super.close();
  }
}
