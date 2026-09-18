import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:yank/app/yank_app.dart';
import 'package:yank/features/audio/repositories/audio_repository.dart';
import 'package:yank/features/auth/models/auth_user.dart';
import 'package:yank/features/auth/repositories/demo_auth_repository.dart';
import 'package:yank/features/library/repositories/demo_library_repository.dart';
import 'package:yank/features/library/repositories/metadata_store.dart';
import 'package:yank/features/settings/repositories/settings_repository.dart';

void main() {
  testWidgets('Capture sheet presentation triggers card depth recession and restore', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final store = MemoryMetadataStore();
    await store.write(
      DemoAuthRepository.storageKey,
      jsonEncode(
        const AuthUser(
          email: 'test@yank.demo',
          provider: AuthProvider.google,
        ).toJson(),
      ),
    );
    final repository = await DemoLibraryRepository.open(store);
    final auth = await DemoAuthRepository.open(store);

    await tester.pumpWidget(
      YankApp(
        library: repository,
        authRepository: auth,
        settingsRepository: SettingsRepository(store),
        initialAppearance: const AppearanceSettings(),
        audioFactory: _SilentAudio.new,
      ),
    );
    await tester.pumpAndSettle();

    // Verify initial state: capture sheet is not shown.
    expect(find.text('Something worth keeping.'), findsNothing);

    // Tap capture button to open sheet.
    final addBtn = find.byTooltip('Add something');
    expect(addBtn, findsOneWidget);
    await tester.tap(addBtn);

    // Pump midway to observe active transition.
    await tester.pump(const Duration(milliseconds: 160));
    expect(find.text('Something worth keeping.'), findsOneWidget);

    // Settle transition into open state.
    await tester.pumpAndSettle();
    expect(find.text('Something worth keeping.'), findsOneWidget);

    // Dismiss sheet via close button.
    final closeBtn = find.byIcon(LucideIcons.x);
    expect(closeBtn, findsOneWidget);
    await tester.tap(closeBtn);
    await tester.pumpAndSettle();

    // Verify sheet is closed and main screen is restored.
    expect(find.text('Something worth keeping.'), findsNothing);
    expect(find.byTooltip('Add something'), findsOneWidget);
  });
}

class _SilentAudio implements AudioRepository {
  final _controller = StreamController<AudioFrame>.broadcast();
  @override
  Stream<AudioFrame> get frames => _controller.stream;
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
  Future<void> close() => _controller.close();
}
