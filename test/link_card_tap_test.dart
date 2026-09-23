import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yank/app/yank_app.dart';
import 'package:yank/core/widgets/yank_controls.dart';
import 'package:yank/features/audio/repositories/audio_repository.dart';
import 'package:yank/features/auth/models/auth_user.dart';
import 'package:yank/features/auth/repositories/demo_auth_repository.dart';
import 'package:yank/features/library/models/yank_item.dart';
import 'package:yank/features/library/repositories/demo_library_repository.dart';
import 'package:yank/features/library/repositories/metadata_store.dart';
import 'package:yank/features/library/widgets/poster_artwork.dart';
import 'package:yank/features/preview/views/item_preview.dart';
import 'package:yank/features/settings/repositories/settings_repository.dart';

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

void main() {
  testWidgets('Tapping a link card expands preview sheet instead of immediately leaving app', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

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

    final linkItem = YankItem(
      id: 'test-link-1',
      kind: ItemKind.link,
      title: 'Flutter - Build apps for any screen',
      body: 'Flutter transforms the frontend development process.',
      createdAt: DateTime.now(),
      url: 'https://flutter.dev',
      artwork: 'scenic',
    );
    await repository.put(linkItem);

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

    // Verify link card is displayed with banner artwork and clean title (without redundant brand prefix)
    expect(find.text('Build apps for any screen'), findsWidgets);
    expect(find.byType(PosterArtwork), findsWidgets);

    // Tap on the link card
    final cardFinder = find.text('Build apps for any screen').first;
    await tester.tap(cardFinder);
    await tester.pumpAndSettle();

    // Verify ItemPreview bottom sheet expanded
    expect(find.byType(ItemPreview), findsOneWidget);

    // Verify "Open original" button and domain badge are inside the preview sheet
    expect(find.widgetWithText(YankButton, 'Open original'), findsOneWidget);
    expect(find.text('flutter.dev'), findsWidgets);
    expect(find.text('Flutter transforms the frontend development process.'), findsWidgets);

    await repository.close();
  });
}
