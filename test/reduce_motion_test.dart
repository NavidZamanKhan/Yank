import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yank/core/motion/yank_motion.dart';

void main() {
  group('iOS Reduce Motion compliance tests', () {
    testWidgets('PressScale dims opacity instead of scaling when reduce motion is active', (
      tester,
    ) async {
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: Center(
              child: PressScale(
                child: Container(
                  width: 100,
                  height: 100,
                  color: Colors.blue,
                ),
              ),
            ),
          ),
        ),
      );

      // Initially full opacity and scale 1
      final animatedScaleFinder = find.byType(AnimatedScale);
      expect(animatedScaleFinder, findsOneWidget);
      final initialScale = tester.widget<AnimatedScale>(animatedScaleFinder);
      expect(initialScale.scale, equals(1.0));

      final animatedOpacityFinder = find.byType(AnimatedOpacity);
      expect(animatedOpacityFinder, findsOneWidget);
      final initialOpacity = tester.widget<AnimatedOpacity>(animatedOpacityFinder);
      expect(initialOpacity.opacity, equals(1.0));

      // Press down
      final gesture = await tester.startGesture(tester.getCenter(find.byType(PressScale)));
      await tester.pump();

      // Verify scale remains 1.0 (no bouncy spring compression)
      final downScale = tester.widget<AnimatedScale>(animatedScaleFinder);
      expect(downScale.scale, equals(1.0));

      // Verify opacity dips to 0.72 (soft iOS touch feedback)
      final downOpacity = tester.widget<AnimatedOpacity>(animatedOpacityFinder);
      expect(downOpacity.opacity, equals(0.72));

      // Release press
      await gesture.up();
      await tester.pump(const Duration(milliseconds: 100));

      final releasedOpacity = tester.widget<AnimatedOpacity>(animatedOpacityFinder);
      expect(releasedOpacity.opacity, equals(1.0));
    });

    testWidgets('PressScale scales physically when reduce motion is false', (
      tester,
    ) async {
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(disableAnimations: false),
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: Center(
              child: PressScale(
                child: Container(
                  width: 100,
                  height: 100,
                  color: Colors.blue,
                ),
              ),
            ),
          ),
        ),
      );

      final animatedScaleFinder = find.byType(AnimatedScale);
      final animatedOpacityFinder = find.byType(AnimatedOpacity);

      // Press down
      final gesture = await tester.startGesture(tester.getCenter(find.byType(PressScale)));
      await tester.pump();

      // Scale compresses to 0.965
      final downScale = tester.widget<AnimatedScale>(animatedScaleFinder);
      expect(downScale.scale, equals(0.965));

      // Opacity stays 1.0 (no dimming when normal motion is on)
      final downOpacity = tester.widget<AnimatedOpacity>(animatedOpacityFinder);
      expect(downOpacity.opacity, equals(1.0));

      await gesture.up();
      await tester.pump(const Duration(milliseconds: 300));
    });
  });
}
