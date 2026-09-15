import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yank/app/yank_app.dart';
import 'package:yank/features/audio/repositories/audio_repository.dart';
import 'package:yank/features/library/repositories/demo_library_repository.dart';
import 'package:yank/features/library/repositories/metadata_store.dart';
import 'package:yank/features/settings/repositories/settings_repository.dart';

void main() {
  for (final width in [320.0, 390.0, 1440.0]) {
    testWidgets('library and search fit at width $width', (tester) async {
      tester.view.physicalSize = Size(width, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final store = MemoryMetadataStore();
      final repository = await DemoLibraryRepository.open(store);
      await tester.pumpWidget(
        YankApp(
          library: repository,
          settingsRepository: SettingsRepository(store),
          initialAppearance: const AppearanceSettings(),
          audioFactory: _SilentAudio.new,
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.enterText(find.byType(TextField).first, 'first rough');
      await tester.pumpAndSettle();
      expect(find.text('The first rough idea'), findsOneWidget);
      expect(find.text('Flutter animation guide'), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    });
  }
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
