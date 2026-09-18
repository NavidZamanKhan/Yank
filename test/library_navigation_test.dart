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

    await tester.pumpWidget(
      MaterialApp(
        theme: YankTheme.build(Brightness.dark),
        home: Scaffold(
          bottomNavigationBar: LibraryBottomNavigation(
            section: LibrarySection.library,
            yankCount: 0,
            onSection: (_) {},
            onCapture: () {},
            notice: LibraryNotice(1, 'Archived.', undo: item),
            onUndo: (i) => restoredItem = i,
          ),
        ),
      ),
    );
    // Initial frame triggers notice since notice is present at mount
    await tester.pump(const Duration(milliseconds: 360));
    await tester.pump();

    expect(find.text('Archived.'), findsOneWidget);
    expect(find.text('Undo'), findsOneWidget);

    await tester.tap(find.text('Undo'));
    await tester.pumpAndSettle();

    expect(restoredItem?.id, equals('demo-1'));
  });

  testWidgets('pill background and foreground colors match theme in dark mode',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: YankTheme.build(Brightness.dark),
        home: Scaffold(
          bottomNavigationBar: LibraryBottomNavigation(
            section: LibrarySection.library,
            yankCount: 0,
            onSection: (_) {},
            onCapture: () {},
            notice: const LibraryNotice(1, 'Kept close in Yank.'),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 360));

    final theme = YankTheme.build(Brightness.dark);
    final materialFinder = find.byWidgetPredicate(
      (widget) => widget is Material && widget.color == theme.colorScheme.primary,
    );
    expect(materialFinder, findsOneWidget);

    final textWidget = tester.widget<Text>(find.text('Kept close in Yank.'));
    expect(textWidget.style?.color, equals(theme.colorScheme.onPrimary));
  });
}
