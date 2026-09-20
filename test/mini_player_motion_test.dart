import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yank/core/theme/yank_theme.dart';
import 'package:yank/features/audio/bloc/audio_bloc.dart';
import 'package:yank/features/audio/repositories/audio_repository.dart';
import 'package:yank/features/audio/widgets/audio_controls.dart';
import 'package:yank/features/library/models/yank_item.dart';

class _FakeAudioRepository implements AudioRepository {
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
  final testItem = YankItem(
    id: 'audio-1',
    kind: ItemKind.audio,
    title: 'An idea for the weekend',
    createdAt: DateTime(2026, 9, 20),
    durationSeconds: 120,
    audioAsset: 'assets/audio/test.mp3',
  );

  testWidgets(
    'MiniPlayer animates in smoothly with size and fade, and animates out on stop',
    (tester) async {
      final repository = _FakeAudioRepository();
      final audioBloc = AudioBloc(repository);
      addTearDown(() {
        audioBloc.close();
        repository.close();
      });

      await tester.pumpWidget(
        MaterialApp(
          theme: YankTheme.build(Brightness.light),
          home: Scaffold(
            body: BlocProvider.value(
              value: audioBloc,
              child: const Column(
                children: [
                  Expanded(child: SizedBox()),
                  MiniPlayer(),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Initially, no audio is active: height should be zero
      expect(find.text('An idea for the weekend'), findsNothing);
      final initialBox = tester.renderObject<RenderBox>(find.byType(MiniPlayer));
      expect(initialBox.size.height, equals(0.0));

      // Play audio: triggers smooth entrance
      final playingState = audioBloc.stream.firstWhere((s) => s.item != null);
      audioBloc.add(AudioTapped(testItem));
      await playingState;
      await tester.pump();

      // Mid-way through entrance animation (140ms of 280ms)
      await tester.pump(const Duration(milliseconds: 140));

      // Widget should be partially expanded
      final midBox = tester.renderObject<RenderBox>(find.byType(MiniPlayer));
      expect(midBox.size.height, greaterThan(0.0));

      // Check that opacity and heightFactor are progressing
      final alignWidget = tester.widget<Align>(
        find.descendant(
          of: find.byType(MiniPlayer),
          matching: find.byType(Align),
        ).first,
      );
      expect(alignWidget.heightFactor, greaterThan(0.2));
      expect(alignWidget.heightFactor, lessThan(0.95));

      // Complete entrance animation (settle)
      await tester.pump(const Duration(milliseconds: 150));
      await tester.pumpAndSettle();

      // Fully expanded and visible
      expect(find.text('An idea for the weekend'), findsOneWidget);
      final textTopLeft = tester.getTopLeft(find.text('An idea for the weekend'));
      expect(textTopLeft.dx, equals(16.0));
      final fullBox = tester.renderObject<RenderBox>(find.byType(MiniPlayer));
      final fullHeight = fullBox.size.height;
      expect(fullHeight, greaterThanOrEqualTo(40.0));

      // Stop audio: triggers smooth exit
      final stoppedState = audioBloc.stream.firstWhere((s) => s.item == null);
      audioBloc.add(const AudioStopped());
      await stoppedState;
      await tester.pump();

      // Mid-way through exit animation (120ms of 240ms)
      await tester.pump(const Duration(milliseconds: 120));

      // Title should still be rendered during exit transition
      expect(find.text('An idea for the weekend'), findsOneWidget);
      final exitMidBox = tester.renderObject<RenderBox>(find.byType(MiniPlayer));
      expect(exitMidBox.size.height, lessThan(fullHeight));
      expect(exitMidBox.size.height, greaterThan(0.0));

      // Complete exit animation
      await tester.pump(const Duration(milliseconds: 150));
      await tester.pumpAndSettle();

      // Fully closed
      expect(find.text('An idea for the weekend'), findsNothing);
      final closedBox = tester.renderObject<RenderBox>(find.byType(MiniPlayer));
      expect(closedBox.size.height, equals(0.0));
    },
  );

  testWidgets(
    'MiniPlayer respects reduced motion with immediate transition',
    (tester) async {
      final repository = _FakeAudioRepository();
      final audioBloc = AudioBloc(repository);
      addTearDown(() {
        audioBloc.close();
        repository.close();
      });

      await tester.pumpWidget(
        MaterialApp(
          theme: YankTheme.build(Brightness.light),
          home: MediaQuery(
            data: const MediaQueryData(disableAnimations: true),
            child: Scaffold(
              body: BlocProvider.value(
                value: audioBloc,
                child: const Column(
                  children: [
                    Expanded(child: SizedBox()),
                    MiniPlayer(),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('An idea for the weekend'), findsNothing);

      // Play audio: with reduced motion, it appears immediately without delay
      final playingState = audioBloc.stream.firstWhere((s) => s.item != null);
      audioBloc.add(AudioTapped(testItem));
      await playingState;
      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.text('An idea for the weekend'), findsOneWidget);
      final box = tester.renderObject<RenderBox>(find.byType(MiniPlayer));
      expect(box.size.height, greaterThanOrEqualTo(40.0));

      // Stop audio: with reduced motion, it closes immediately
      final stoppedState = audioBloc.stream.firstWhere((s) => s.item == null);
      audioBloc.add(const AudioStopped());
      await stoppedState;
      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.text('An idea for the weekend'), findsNothing);
      final closedBox = tester.renderObject<RenderBox>(find.byType(MiniPlayer));
      expect(closedBox.size.height, equals(0.0));
    },
  );
}
