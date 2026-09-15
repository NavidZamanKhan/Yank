import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../core/theme/yank_theme.dart';
import '../features/audio/bloc/audio_bloc.dart';
import '../features/audio/repositories/audio_repository.dart';
import '../features/library/bloc/library_bloc.dart';
import '../features/library/repositories/library_repository.dart';
import '../features/library/views/library_page.dart';
import '../features/settings/bloc/settings_bloc.dart';

class YankApp extends StatelessWidget {
  const YankApp({
    super.key,
    required this.library,
    required this.settingsRepository,
    required this.initialAppearance,
    this.audioFactory,
  });
  final LibraryRepository library;
  final SettingsRepository settingsRepository;
  final AppearanceSettings initialAppearance;
  final AudioRepository Function()? audioFactory;
  @override
  Widget build(BuildContext context) => RepositoryProvider<LibraryRepository>(
    create: (_) => library,
    dispose: (repository) => unawaited(repository.close()),
    child: MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => LibraryBloc(library)),
        BlocProvider(
          create: (_) => SettingsBloc(settingsRepository, initialAppearance),
        ),
        BlocProvider(
          create: (_) =>
              AudioBloc(audioFactory?.call() ?? AssetAudioRepository()),
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
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              disableAnimations:
                  state.appearance.reduceMotion ||
                  MediaQuery.disableAnimationsOf(context),
            ),
            child: child!,
          ),
          home: const LibraryPage(),
        ),
      ),
    ),
  );
}
