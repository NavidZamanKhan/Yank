import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:yank/core/theme/yank_theme.dart';
import 'package:yank/features/audio/repositories/audio_repository.dart';
import 'package:yank/features/auth/bloc/auth_bloc.dart';
import 'package:yank/features/auth/repositories/auth_repository.dart';
import 'package:yank/features/auth/views/auth_gate.dart';
import 'package:yank/features/library/repositories/library_repository.dart';
import 'package:yank/features/settings/bloc/settings_bloc.dart';

class YankApp extends StatelessWidget {
  const YankApp({
    super.key,
    required this.library,
    required this.authRepository,
    required this.settingsRepository,
    required this.initialAppearance,
    this.audioFactory,
  });
  final LibraryRepository library;
  final AuthRepository authRepository;
  final SettingsRepository settingsRepository;
  final AppearanceSettings initialAppearance;
  final AudioRepository Function()? audioFactory;
  @override
  Widget build(BuildContext context) => RepositoryProvider<LibraryRepository>(
    create: (_) => library,
    dispose: (repository) => unawaited(repository.close()),
    child: MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => AuthBloc(authRepository)),
        BlocProvider(
          create: (_) => SettingsBloc(settingsRepository, initialAppearance),
        ),
      ],
      child: BlocBuilder<SettingsBloc, SettingsState>(
        buildWhen: (a, b) => a.appearance != b.appearance,
        builder: (context, state) => MaterialApp(
          title: 'Yank',
          debugShowCheckedModeBanner: false,
          theme: YankTheme.build(Brightness.light),
          darkTheme: YankTheme.build(Brightness.dark),
          themeMode: state.appearance.themeMode,
          themeAnimationDuration: state.appearance.reduceMotion
              ? Duration.zero
              : const Duration(milliseconds: 220),
          scrollBehavior: const MaterialScrollBehavior().copyWith(
            dragDevices: {
              PointerDeviceKind.touch,
              PointerDeviceKind.mouse,
              PointerDeviceKind.trackpad,
              PointerDeviceKind.stylus,
            },
          ),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              disableAnimations:
                  state.appearance.reduceMotion ||
                  MediaQuery.disableAnimationsOf(context),
            ),
            child: child!,
          ),
          home: AuthGate(audioFactory: audioFactory),
        ),
      ),
    ),
  );
}
