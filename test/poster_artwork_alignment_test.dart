import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:yank/features/library/widgets/poster_artwork.dart';

void main() {
  group('PosterArtwork alignment and fallback tests', () {
    testWidgets('defaults to Alignment.topCenter for network images', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PosterArtwork(
              variant: 'https://example.com/photo.jpg',
            ),
          ),
        ),
      );

      final imageFinder = find.byType(Image);
      expect(imageFinder, findsOneWidget);
      final image = tester.widget<Image>(imageFinder);
      expect(image.alignment, equals(Alignment.topCenter));
      expect(image.fit, equals(BoxFit.cover));
    });

    testWidgets('honors custom alignment when specified', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PosterArtwork(
              variant: 'https://example.com/photo.jpg',
              alignment: Alignment.center,
              fit: BoxFit.contain,
            ),
          ),
        ),
      );

      final imageFinder = find.byType(Image);
      expect(imageFinder, findsOneWidget);
      final image = tester.widget<Image>(imageFinder);
      expect(image.alignment, equals(Alignment.center));
      expect(image.fit, equals(BoxFit.contain));
    });

    testWidgets('renders placeholder icon instead of slow down poster for missing real photo', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PosterArtwork(
              variant: '/data/user/0/com.example.yank/app_flutter/captures/screenshot.jpg',
            ),
          ),
        ),
      );

      // Must show LucideIcons.image placeholder, NOT slow down poster
      expect(find.byIcon(LucideIcons.image), findsOneWidget);
      expect(find.textContaining('slow down'), findsNothing);
    });

    testWidgets('renders sample vector poster only when variant is explicit poster name', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PosterArtwork(
              variant: 'slow',
            ),
          ),
        ),
      );

      expect(
        find.descendant(
          of: find.byType(PosterArtwork),
          matching: find.byType(CustomPaint),
        ),
        findsOneWidget,
      );
      expect(find.byIcon(LucideIcons.image), findsNothing);
    });

    testWidgets('falls back to remoteUrl when local file path is not on current device', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PosterArtwork(
              variant: '/data/user/0/com.example.yank/captures/other_device.jpg',
              remoteUrl: 'https://example.com/cloud_sync.jpg',
            ),
          ),
        ),
      );

      final imageFinder = find.byType(Image);
      expect(imageFinder, findsOneWidget);
      final image = tester.widget<Image>(imageFinder);
      expect(image.alignment, equals(Alignment.topCenter));
      expect((image.image as NetworkImage).url, equals('https://example.com/cloud_sync.jpg'));
    });
  });
}
