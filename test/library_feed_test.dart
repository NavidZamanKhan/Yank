import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yank/core/theme/yank_theme.dart';
import 'package:yank/features/library/bloc/library_state.dart';
import 'package:yank/features/library/models/yank_item.dart';
import 'package:yank/features/library/widgets/library_feed.dart';

void main() {
  testWidgets(
      'LibraryFeed slides forward from right when switching to Yank and backward from left when returning to Library',
      (tester) async {
    final items = [
      YankItem(
        id: 'item-1',
        kind: ItemKind.text,
        title: 'Library Item 1',
        createdAt: DateTime(2026, 9, 18),
      ),
    ];
    final yankItems = [
      YankItem(
        id: 'item-2',
        kind: ItemKind.link,
        title: 'Yanked Item 2',
        createdAt: DateTime(2026, 9, 18),
        yankedAt: DateTime(2026, 9, 18),
      ),
    ];

    late StateSetter setWidgetState;
    var state = LibraryState(
      items: [...items, ...yankItems],
      section: LibrarySection.library,
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: YankTheme.build(Brightness.light),
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) {
              setWidgetState = setState;
              return LibraryFeed(
                state: state,
                wide: false,
                onOpen: (_) {},
                onPreview: (_) {},
                onClear: () {},
                onCapture: () {},
                onBrowse: () {},
              );
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Library Item 1'), findsOneWidget);
    expect(find.text('Yanked Item 2'), findsOneWidget);

    // Switch section forward from Library to Yank
    setWidgetState(() {
      state = state.copyWith(section: LibrarySection.yank);
    });
    await tester.pump();

    // Mid-way through forward slide transition (140ms)
    await tester.pump(const Duration(milliseconds: 140));

    // Both incoming and outgoing items exist during transition
    final slideTransitions = tester.widgetList<SlideTransition>(
      find.byType(SlideTransition),
    );
    expect(slideTransitions.length, greaterThanOrEqualTo(2));

    // Complete forward slide
    await tester.pump(const Duration(milliseconds: 160));
    await tester.pumpAndSettle();

    expect(find.text('Yanked Item 2'), findsOneWidget);
    expect(find.text('Library Item 1'), findsNothing);

    // Switch section backward from Yank to Library
    setWidgetState(() {
      state = state.copyWith(section: LibrarySection.library);
    });
    await tester.pump();

    // Mid-way through backward slide transition (140ms)
    await tester.pump(const Duration(milliseconds: 140));

    // Complete backward slide
    await tester.pump(const Duration(milliseconds: 160));
    await tester.pumpAndSettle();

    expect(find.text('Library Item 1'), findsOneWidget);
    expect(find.text('Yanked Item 2'), findsOneWidget);
  });

  testWidgets(
      'LibraryFeed slides forward when selecting category filter and backward when returning to All',
      (tester) async {
    final items = [
      YankItem(
        id: 'item-text',
        kind: ItemKind.text,
        title: 'Text Note',
        createdAt: DateTime(2026, 9, 18),
      ),
      YankItem(
        id: 'item-photo',
        kind: ItemKind.photo,
        title: 'Sunset Photo',
        createdAt: DateTime(2026, 9, 18),
      ),
    ];

    late StateSetter setWidgetState;
    var state = LibraryState(
      items: items,
      section: LibrarySection.library,
      kind: null,
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: YankTheme.build(Brightness.light),
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) {
              setWidgetState = setState;
              return LibraryFeed(
                state: state,
                wide: false,
                onOpen: (_) {},
                onPreview: (_) {},
                onClear: () {},
                onCapture: () {},
                onBrowse: () {},
              );
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Text Note'), findsOneWidget);
    expect(find.text('Sunset Photo'), findsOneWidget);

    // Switch kind forward to Photo (index 2 > 0)
    setWidgetState(() {
      state = state.copyWith(kind: ItemKind.photo);
    });
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 140));

    final slideTransitions = tester.widgetList<SlideTransition>(
      find.byType(SlideTransition),
    );
    expect(slideTransitions.length, greaterThanOrEqualTo(2));

    await tester.pump(const Duration(milliseconds: 160));
    await tester.pumpAndSettle();

    expect(find.text('Sunset Photo'), findsOneWidget);
    expect(find.text('Text Note'), findsNothing);

    // Switch kind backward to All (index 0 < 2)
    setWidgetState(() {
      state = state.copyWith(kind: null);
    });
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 140));
    await tester.pump(const Duration(milliseconds: 160));
    await tester.pumpAndSettle();

    expect(find.text('Sunset Photo'), findsOneWidget);
    expect(find.text('Text Note'), findsOneWidget);
  });

  testWidgets(
      'LibraryFeed delays incoming content fade-in until slide is underway',
      (tester) async {
    final items = [
      YankItem(
        id: 'item-1',
        kind: ItemKind.text,
        title: 'Alpha Note',
        createdAt: DateTime(2026, 9, 18),
      ),
      YankItem(
        id: 'item-2',
        kind: ItemKind.link,
        title: 'Beta Link',
        createdAt: DateTime(2026, 9, 18),
        yankedAt: DateTime(2026, 9, 18),
      ),
    ];

    late StateSetter setWidgetState;
    var state = LibraryState(
      items: items,
      section: LibrarySection.library,
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: YankTheme.build(Brightness.light),
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) {
              setWidgetState = setState;
              return LibraryFeed(
                state: state,
                wide: false,
                onOpen: (_) {},
                onPreview: (_) {},
                onClear: () {},
                onCapture: () {},
                onBrowse: () {},
              );
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Alpha Note'), findsOneWidget);

    // Switch section forward from Library to Yank
    setWidgetState(() {
      state = state.copyWith(section: LibrarySection.yank);
    });
    await tester.pump();

    // At 50ms (t ~ 0.11 < 0.24 threshold of incoming fade interval):
    // Slide is underway but incoming child fade has not started yet (opacity == 0.0)
    await tester.pump(const Duration(milliseconds: 50));

    final earlyFades = tester.widgetList<FadeTransition>(
      find.byType(FadeTransition),
    );
    expect(earlyFades.any((f) => f.opacity.value == 0.0), isTrue);

    // At 220ms (t = 0.50 > 0.24 threshold):
    // Incoming child has smoothly faded into visible range
    await tester.pump(const Duration(milliseconds: 170));

    final midFades = tester.widgetList<FadeTransition>(
      find.byType(FadeTransition),
    );
    expect(
      midFades.any((f) => f.opacity.value > 0.0 && f.opacity.value < 1.0),
      isTrue,
    );

    // Settle to completion
    await tester.pump(const Duration(milliseconds: 250));
    await tester.pumpAndSettle();

    expect(find.text('Beta Link'), findsOneWidget);
    expect(find.text('Alpha Note'), findsNothing);
  });
}

