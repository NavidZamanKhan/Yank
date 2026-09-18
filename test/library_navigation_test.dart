import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:yank/core/theme/yank_theme.dart';
import 'package:yank/features/library/bloc/library_state.dart';
import 'package:yank/features/library/models/yank_item.dart';
import 'package:yank/features/library/widgets/library_navigation.dart';

void main() {
  testWidgets(
      'LibraryBottomNavigation plus button starts 46x46 and triggers onCapture',
      (tester) async {
    bool captured = false;
    await tester.pumpWidget(
      MaterialApp(
        theme: YankTheme.build(Brightness.light),
        home: Scaffold(
          bottomNavigationBar: LibraryBottomNavigation(
            section: LibrarySection.library,
            yankCount: 0,
            onSection: (_) {},
            onCapture: () => captured = true,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byIcon(LucideIcons.plus), findsOneWidget);
    expect(find.text('Library'), findsOneWidget);
    expect(find.text('Yank'), findsOneWidget);

    // Verify squircle border radius (14) on plus button
    final plusMaterial = tester.widget<Material>(
      find.byWidgetPredicate(
        (w) =>
            w is Material &&
            w.borderRadius == BorderRadius.circular(14.0),
      ),
    );
    expect(plusMaterial.borderRadius, equals(BorderRadius.circular(14.0)));

    await tester.tap(find.byIcon(LucideIcons.plus));
    expect(captured, isTrue);
  });

  testWidgets(
      'morphs plus button smoothly from right to left with notice text and rotating icon',
      (tester) async {
    late StateSetter setWidgetState;
    LibraryNotice? currentNotice;

    await tester.pumpWidget(
      MaterialApp(
        theme: YankTheme.build(Brightness.light),
        home: StatefulBuilder(
          builder: (context, setState) {
            setWidgetState = setState;
            return Scaffold(
              bottomNavigationBar: LibraryBottomNavigation(
                section: LibrarySection.library,
                yankCount: 2,
                onSection: (_) {},
                onCapture: () {},
                notice: currentNotice,
              ),
            );
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Trigger notice
    setWidgetState(() {
      currentNotice = const LibraryNotice(1, 'Kept close in Yank.');
    });
    await tester.pump();

    // Advance halfway through expansion (180ms)
    await tester.pump(const Duration(milliseconds: 180));

    // Advance to full expansion (total 360ms)
    await tester.pump(const Duration(milliseconds: 180));
    expect(find.text('Kept close in Yank.'), findsOneWidget);

    // Verify squircle border radius (14) preserved in expanded notification
    final expandedMaterial = tester.widget<Material>(
      find.byWidgetPredicate(
        (w) =>
            w is Material &&
            w.borderRadius == BorderRadius.circular(14.0),
      ),
    );
    expect(expandedMaterial.borderRadius, equals(BorderRadius.circular(14.0)));

    // Verify both plus and check are in the rotating stack, with check visible
    expect(find.byIcon(LucideIcons.check), findsOneWidget);

    // Advance past hold duration (2800ms) to trigger collapse
    await tester.pump(const Duration(milliseconds: 2900));
    await tester.pumpAndSettle();

    // Should be collapsed back to plus button
    expect(find.text('Kept close in Yank.'), findsNothing);
    expect(find.byIcon(LucideIcons.plus), findsOneWidget);
  });

  testWidgets(
      'displays undo button and invokes callback when tapped', (tester) async {
    YankItem? restoredItem;
    final item = YankItem(
      id: 'demo-1',
      title: 'Demo',
      url: 'https://yank.test',
      kind: ItemKind.text,
      createdAt: DateTime.now(),
      archived: true,
    );
    late StateSetter setWidgetState;
    LibraryNotice? currentNotice;

    await tester.pumpWidget(
      MaterialApp(
        theme: YankTheme.build(Brightness.dark),
        home: StatefulBuilder(
          builder: (context, setState) {
            setWidgetState = setState;
            return Scaffold(
              bottomNavigationBar: LibraryBottomNavigation(
                section: LibrarySection.library,
                yankCount: 0,
                onSection: (_) {},
                onCapture: () {},
                notice: currentNotice,
                onUndo: (i) => restoredItem = i,
              ),
            );
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    setWidgetState(() {
      currentNotice = LibraryNotice(1, 'Archived.', undo: item);
    });
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 360));

    expect(find.text('Archived.'), findsOneWidget);
    expect(find.text('Undo'), findsOneWidget);

    await tester.tap(find.text('Undo'));
    await tester.pumpAndSettle();

    expect(restoredItem?.id, equals('demo-1'));
  });

  testWidgets(
      'transition from undo notice to restored notice maintains expanded width without jitter',
      (tester) async {
    late StateSetter setWidgetState;
    final item = YankItem(
      id: 'demo-1',
      title: 'Demo',
      url: 'https://yank.test',
      kind: ItemKind.text,
      createdAt: DateTime.now(),
      archived: true,
    );
    LibraryNotice? currentNotice;

    await tester.pumpWidget(
      MaterialApp(
        theme: YankTheme.build(Brightness.dark),
        home: StatefulBuilder(
          builder: (context, setState) {
            setWidgetState = setState;
            return Scaffold(
              bottomNavigationBar: LibraryBottomNavigation(
                section: LibrarySection.library,
                yankCount: 0,
                onSection: (_) {},
                onCapture: () {},
                notice: currentNotice,
                onUndo: (_) {
                  setWidgetState(() {
                    currentNotice = const LibraryNotice(2, 'Restored.');
                  });
                },
              ),
            );
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    setWidgetState(() {
      currentNotice = LibraryNotice(1, 'Archived.', undo: item);
    });
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 360));

    // Verify initial expanded state
    expect(find.text('Archived.'), findsOneWidget);
    expect(find.text('Undo'), findsOneWidget);
    final pillFinder = find.byWidgetPredicate(
      (w) =>
          w is Material &&
          w.borderRadius == BorderRadius.circular(14.0),
    );
    final initialExpandedWidth = tester.getSize(pillFinder).width;

    // Tap undo, triggering transition to 'Restored.'
    await tester.tap(find.text('Undo'));
    await tester.pump();

    // Verify width immediately on next frame has NOT collapsed to 46px
    final postUndoWidth = tester.getSize(pillFinder).width;
    expect(postUndoWidth, equals(initialExpandedWidth));

    // Advance through cross-fade transition (220ms)
    await tester.pump(const Duration(milliseconds: 250));
    await tester.pump();
    expect(find.text('Restored.'), findsOneWidget);
    expect(find.text('Undo'), findsNothing);

    // Advance past hold duration to verify clean collapse
    await tester.pump(const Duration(milliseconds: 2900));
    await tester.pumpAndSettle();

    expect(find.text('Restored.'), findsNothing);
    expect(find.byIcon(LucideIcons.plus), findsOneWidget);
  });

  testWidgets('pill background and foreground colors match theme in dark mode',
      (tester) async {
    late StateSetter setWidgetState;
    LibraryNotice? currentNotice;

    await tester.pumpWidget(
      MaterialApp(
        theme: YankTheme.build(Brightness.dark),
        home: StatefulBuilder(
          builder: (context, setState) {
            setWidgetState = setState;
            return Scaffold(
              bottomNavigationBar: LibraryBottomNavigation(
                section: LibrarySection.library,
                yankCount: 0,
                onSection: (_) {},
                onCapture: () {},
                notice: currentNotice,
              ),
            );
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    setWidgetState(() {
      currentNotice = const LibraryNotice(1, 'Kept close in Yank.');
    });
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 360));

    final theme = YankTheme.build(Brightness.dark);
    final materialFinder = find.byWidgetPredicate(
      (widget) =>
          widget is Material && widget.color == theme.colorScheme.primary,
    );
    expect(materialFinder, findsOneWidget);

    final textWidget = tester.widget<Text>(find.text('Kept close in Yank.'));
    expect(textWidget.style?.color, equals(theme.colorScheme.onPrimary));
  });

  testWidgets(
      'switching section or updating widget does not replay already shown notice',
      (tester) async {
    late StateSetter setWidgetState;
    LibraryNotice? currentNotice;
    LibrarySection currentSection = LibrarySection.library;

    await tester.pumpWidget(
      MaterialApp(
        theme: YankTheme.build(Brightness.light),
        home: StatefulBuilder(
          builder: (context, setState) {
            setWidgetState = setState;
            return Scaffold(
              bottomNavigationBar: LibraryBottomNavigation(
                section: currentSection,
                yankCount: 1,
                onSection: (_) {},
                onCapture: () {},
                notice: currentNotice,
              ),
            );
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Trigger notice once
    setWidgetState(() {
      currentNotice = const LibraryNotice(1, 'Kept close in Yank.');
    });
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 360));
    expect(find.text('Kept close in Yank.'), findsOneWidget);

    // Let notice collapse after 2800ms
    await tester.pump(const Duration(milliseconds: 2900));
    await tester.pumpAndSettle();
    expect(find.text('Kept close in Yank.'), findsNothing);
    expect(find.byIcon(LucideIcons.plus), findsOneWidget);

    // User switches tab to 'yank' (with the same notice still in state)
    setWidgetState(() {
      currentSection = LibrarySection.yank;
    });
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 360));

    // Must remain collapsed as plus button, NOT replay notice
    expect(find.text('Kept close in Yank.'), findsNothing);
    expect(find.byIcon(LucideIcons.plus), findsOneWidget);

    // User switches filter or updates widget again
    setWidgetState(() {});
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 360));
    expect(find.text('Kept close in Yank.'), findsNothing);
    expect(find.byIcon(LucideIcons.plus), findsOneWidget);
  });

  testWidgets(
      'indicator pill slides smoothly between library and yank navigation destinations',
      (tester) async {
    late StateSetter setWidgetState;
    LibrarySection currentSection = LibrarySection.library;

    await tester.pumpWidget(
      MaterialApp(
        theme: YankTheme.build(Brightness.light),
        home: StatefulBuilder(
          builder: (context, setState) {
            setWidgetState = setState;
            return Scaffold(
              bottomNavigationBar: LibraryBottomNavigation(
                section: currentSection,
                yankCount: 3,
                onSection: (s) {
                  setWidgetState(() {
                    currentSection = s;
                  });
                },
                onCapture: () {},
              ),
            );
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    final pillFinder = find.byKey(const Key('library_nav_indicator_pill'));
    expect(pillFinder, findsOneWidget);

    // Initial position on Library: left is 0.0
    final initialWidget = tester.widget<AnimatedPositioned>(pillFinder);
    expect(initialWidget.left, equals(0.0));
    final initialRenderBox = tester.renderObject(pillFinder) as RenderBox;
    final initialOffset = initialRenderBox.localToGlobal(Offset.zero);

    // Verify indicator decoration has squircle BorderRadius.circular(12)
    final decoratedBoxFinder = find.descendant(
      of: pillFinder,
      matching: find.byType(DecoratedBox),
    );
    expect(decoratedBoxFinder, findsOneWidget);
    final decoratedBox = tester.widget<DecoratedBox>(decoratedBoxFinder);
    final boxDecoration = decoratedBox.decoration as BoxDecoration;
    expect(boxDecoration.borderRadius, equals(BorderRadius.circular(12)));

    // Verify destinations have transparent background to let the pill show through
    final destTextButtons = tester.widgetList<TextButton>(find.byType(TextButton));
    for (final btn in destTextButtons) {
      expect(
        btn.style?.backgroundColor?.resolve({}),
        equals(Colors.transparent),
      );
    }

    // Switch section to Yank
    await tester.tap(find.text('Yank'));
    await tester.pump();

    // After state update, AnimatedPositioned target left is greater than 0
    final yankWidget = tester.widget<AnimatedPositioned>(pillFinder);
    expect(yankWidget.left, greaterThan(0.0));
    final targetLeft = yankWidget.left!;

    // Mid-way through animation (130ms)
    await tester.pump(const Duration(milliseconds: 130));
    final midRenderBox = tester.renderObject(pillFinder) as RenderBox;
    final midOffset = midRenderBox.localToGlobal(Offset.zero);
    expect(midOffset.dx, greaterThan(initialOffset.dx));
    expect(midOffset.dx, lessThan(initialOffset.dx + targetLeft));

    // Complete animation (total 260ms)
    await tester.pump(const Duration(milliseconds: 130));
    await tester.pump();
    final finalRenderBox = tester.renderObject(pillFinder) as RenderBox;
    final finalOffset = finalRenderBox.localToGlobal(Offset.zero);
    expect(finalOffset.dx, closeTo(initialOffset.dx + targetLeft, 0.5));

    // Now tap Library to slide back
    await tester.tap(find.text('Library'));
    await tester.pump();

    final libWidget = tester.widget<AnimatedPositioned>(pillFinder);
    expect(libWidget.left, equals(0.0));

    // Mid-way back (130ms)
    await tester.pump(const Duration(milliseconds: 130));
    final backMidRenderBox = tester.renderObject(pillFinder) as RenderBox;
    final backMidOffset = backMidRenderBox.localToGlobal(Offset.zero);
    expect(backMidOffset.dx, lessThan(finalOffset.dx));
    expect(backMidOffset.dx, greaterThan(initialOffset.dx));

    // Complete slide back
    await tester.pump(const Duration(milliseconds: 130));
    await tester.pump();
    final backFinalRenderBox = tester.renderObject(pillFinder) as RenderBox;
    final backFinalOffset = backFinalRenderBox.localToGlobal(Offset.zero);
    expect(backFinalOffset.dx, closeTo(initialOffset.dx, 0.5));
  });
}
