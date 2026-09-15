import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../repositories/settings_repository.dart';
export '../repositories/settings_repository.dart';

sealed class SettingsEvent extends Equatable {
  const SettingsEvent();
}

final class ThemeChanged extends SettingsEvent {
  const ThemeChanged(this.mode);
  final ThemeMode mode;
  @override
  List<Object?> get props => [mode];
}

final class ReduceMotionChanged extends SettingsEvent {
  const ReduceMotionChanged(this.reduce);
  final bool reduce;
  @override
  List<Object?> get props => [reduce];
}

class SettingsState extends Equatable {
  const SettingsState(this.appearance, {this.error, this.errorSerial = 0});
  final AppearanceSettings appearance;
  final String? error;
  final int errorSerial;
  @override
  List<Object?> get props => [appearance, error, errorSerial];
}

class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  SettingsBloc(this.repository, AppearanceSettings initial)
    : super(SettingsState(initial)) {
    on<SettingsEvent>((event, emit) async {
      final next = switch (event) {
        ThemeChanged(:final mode) => state.appearance.copyWith(themeMode: mode),
        ReduceMotionChanged(:final reduce) => state.appearance.copyWith(
          reduceMotion: reduce,
        ),
      };
      try {
        await repository.save(next);
        emit(SettingsState(next));
      } catch (_) {
        emit(
          SettingsState(
            state.appearance,
            error: 'Appearance could not be saved. Please try again.',
            errorSerial: state.errorSerial + 1,
          ),
        );
      }
    }, transformer: (events, mapper) => events.asyncExpand(mapper));
  }
  final SettingsRepository repository;
}
