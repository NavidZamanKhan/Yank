import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yank/app/yank_app.dart';
import 'package:yank/features/audio/repositories/audio_repository.dart';
import 'package:yank/features/auth/repositories/demo_auth_repository.dart';
import 'package:yank/features/library/repositories/demo_library_repository.dart';
import 'package:yank/features/library/repositories/metadata_store.dart';
import 'package:yank/features/settings/repositories/settings_repository.dart';

void main() {
  for (final width in [320.0, 390.0, 1440.0]) {
    testWidgets('Google, email reveal, login switch and logout at $width', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final store = MemoryMetadataStore();
      final library = await DemoLibraryRepository.open(store);
      final auth = await DemoAuthRepository.open(store);
      await tester.pumpWidget(
        YankApp(
          library: library,
          authRepository: auth,
          settingsRepository: SettingsRepository(store),
          initialAppearance: const AppearanceSettings(),
          audioFactory: _SilentAudio.new,
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('auth-google')), findsOneWidget);
      expect(find.byKey(const ValueKey('auth-email')), findsNothing);
      await tester.tap(find.byKey(const ValueKey('auth-email-reveal')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('auth-email')), findsOneWidget);
      final submit = find.byKey(const ValueKey('auth-email-submit'));
      await tester.ensureVisible(submit);
      await tester.tap(submit);
      await tester.pumpAndSettle();
      expect(find.text('Enter your email address.'), findsOneWidget);
      final switchMode = find.byKey(const ValueKey('auth-mode-switch'));
      await tester.ensureVisible(switchMode);
      await tester.tap(switchMode);
      await tester.pumpAndSettle();
      expect(find.text('Forgot password?'), findsOneWidget);
      final google = find.byKey(const ValueKey('auth-google'));
      await tester.ensureVisible(google);
      await tester.tap(google);
      await tester.pumpAndSettle();
      expect(find.text('Flutter animation guide'), findsOneWidget);
      if (width >= 900) {
        await tester.tap(find.text('Settings'));
      } else {
        await tester.tap(find.byTooltip('Settings'));
      }
      await tester.pumpAndSettle();
      final logout = find.byKey(const ValueKey('settings-logout'));
      await tester.ensureVisible(logout);
      await tester.tap(logout);
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('auth-google')), findsOneWidget);
      expect(find.text('Make yourself at home.'), findsNothing);
      expect(auth.currentUser, isNull);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    });
  }
}

class _SilentAudio implements AudioRepository {
  final _frames = StreamController<AudioFrame>.broadcast();
  @override
  Stream<AudioFrame> get frames => _frames.stream;
  @override
  Future<void> play(String id, String asset) async {}
  @override
  Future<void> pause() async {}
  @override
  Future<void> resume() async {}
  @override
  Future<void> seek(Duration position) async {}
  @override
  Future<void> stop() async {}
  @override
  Future<void> close() => _frames.close();
}
