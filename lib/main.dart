import 'dart:convert';

import 'package:flutter/material.dart';

import 'app/yank_app.dart';
import 'core/theme/yank_theme.dart';
import 'features/library/repositories/demo_fixtures.dart';
import 'features/library/repositories/demo_library_repository.dart';
import 'features/library/repositories/preferences_metadata_store.dart';
import 'features/settings/repositories/settings_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _start();
}

Future<void> _start({bool reset = false}) async {
  final store = PreferencesMetadataStore();
  try {
    if (reset) {
      await store.write(
        DemoLibraryRepository.storageKey,
        jsonEncode(DemoFixtures.build().map((item) => item.toJson()).toList()),
      );
      await store.write(
        SettingsRepository.key,
        jsonEncode({'theme': 'light', 'reduceMotion': false}),
      );
    }
    final settingsRepository = SettingsRepository(store);
    final appearance = await settingsRepository.load();
    final library = await DemoLibraryRepository.open(store);
    runApp(
      YankApp(
        library: library,
        settingsRepository: settingsRepository,
        initialAppearance: appearance,
      ),
    );
  } catch (error, stack) {
    debugPrint('Yank demo initialization failed: $error\n$stack');
    runApp(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: YankTheme.build(Brightness.light),
        home: Scaffold(
          body: SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Let’s try that again.',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Yank could not open the local demo data.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 22),
                    FilledButton(
                      onPressed: _start,
                      child: const Text('Try again'),
                    ),
                    TextButton(
                      onPressed: () async {
                        final approved = await showDialog<bool>(
                          context: _startupNavigator.currentContext!,
                          builder: (context) => AlertDialog(
                            title: const Text('Reset local demo data?'),
                            content: const Text(
                              'This removes your local additions and restores the sample library.',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(context, true),
                                child: const Text('Reset'),
                              ),
                            ],
                          ),
                        );
                        if (approved == true) {
                          await _start(reset: true);
                        }
                      },
                      child: const Text('Reset demo data'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        navigatorKey: _startupNavigator,
      ),
    );
  }
}

final _startupNavigator = GlobalKey<NavigatorState>();
