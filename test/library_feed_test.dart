import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yank/core/theme/yank_theme.dart';
import 'package:yank/features/library/bloc/library_state.dart';
import 'package:yank/features/library/models/yank_item.dart';
import 'package:yank/features/library/widgets/library_feed.dart';

void main() {
  testWidgets(
      'LibraryFeed swaps pages horizontally with full-length slide when switching sections',
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

    // Mid-way through horizontal transition (200ms of 400ms)
    await tester.pump(const Duration(milliseconds: 200));

    final slideTransitions = tester.widgetList<SlideTransition>(
      find.byType(SlideTransition),
    ).toList();
    expect(slideTransitions.length, greaterThanOrEqualTo(2));

    // In forward horizontal swap:
    // Incoming slides in from right (dx > 0.0)
    // Outgoing exits towards left (dx < 0.0)
    final incomingSlide = slideTransitions.firstWhere(
      (s) => s.position.value.dx > 0.0,
    );
    final outgoingSlide = slideTransitions.firstWhere(
      (s) => s.position.value.dx < 0.0,
    );
    expect(incomingSlide.position.value.dy, equals(0.0));
    expect(outgoingSlide.position.value.dy, equals(0.0));

    // Complete forward horizontal slide
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pumpAndSettle();

    expect(find.text('Yanked Item 2'), findsOneWidget);
    expect(find.text('Library Item 1'), findsNothing);

    // Switch section backward from Yank to Library
    setWidgetState(() {
      state = state.copyWith(section: LibrarySection.library);
    });
    await tester.pump();

    // Mid-way through backward horizontal transition (200ms)
    await tester.pump(const Duration(milliseconds: 200));

    final backSlides = tester.widgetList<SlideTransition>(
      find.byType(SlideTransition),
    ).toList();
    expect(backSlides.length, greaterThanOrEqualTo(2));

    // In backward horizontal swap:
    // Incoming slides in from left (dx < 0.0)
    // Outgoing exits towards right (dx > 0.0)
    final backIncomingSlide = backSlides.firstWhere(
      (s) => s.position.value.dx < 0.0,
    );
    final backOutgoingSlide = backSlides.firstWhere(
      (s) => s.position.value.dx > 0.0,
    );
    expect(backIncomingSlide.position.value.dy, equals(0.0));
    expect(backOutgoingSlide.position.value.dy, equals(0.0));

    // Complete backward slide
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pumpAndSettle();

    expect(find.text('Library Item 1'), findsOneWidget);
    expect(find.text('Yanked Item 2'), findsOneWidget);
  });

  testWidgets(
      'LibraryFeed swaps pages horizontally when selecting category filter and returning to All',
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
    await tester.pump(const Duration(milliseconds: 200));

    final forwardSlides = tester.widgetList<SlideTransition>(
      find.byType(SlideTransition),
    ).toList();
    expect(forwardSlides.length, greaterThanOrEqualTo(2));
    expect(forwardSlides.any((s) => s.position.value.dx > 0.0), isTrue);
    expect(forwardSlides.any((s) => s.position.value.dx < 0.0), isTrue);

    await tester.pump(const Duration(milliseconds: 200));
    await tester.pumpAndSettle();

    expect(find.text('Sunset Photo'), findsOneWidget);
    expect(find.text('Text Note'), findsNothing);

    // Switch kind backward to All (index 0 < 2)
    setWidgetState(() {
      state = state.copyWith(kind: null);
    });
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    final backwardSlides = tester.widgetList<SlideTransition>(
      find.byType(SlideTransition),
    ).toList();
    expect(backwardSlides.length, greaterThanOrEqualTo(2));
    expect(backwardSlides.any((s) => s.position.value.dx < 0.0), isTrue);
    expect(backwardSlides.any((s) => s.position.value.dx > 0.0), isTrue);

    await tester.pump(const Duration(milliseconds: 200));
    await tester.pumpAndSettle();

    expect(find.text('Sunset Photo'), findsOneWidget);
    expect(find.text('Text Note'), findsOneWidget);
  });

  testWidgets(
      'LibraryFeed applies elastic transit stretch during horizontal page swap',
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

    // Switch section forward to Yank
    setWidgetState(() {
      state = state.copyWith(section: LibrarySection.yank);
    });
    await tester.pump();

    // Mid-way through transition (200ms of 400ms)
    await tester.pump(const Duration(milliseconds: 200));

    final transforms = tester.widgetList<Transform>(
      find.byType(Transform),
    ).toList();
    final stretched = transforms.where(
      (t) => t.transform.storage[0] > 1.01,
    );
    expect(stretched.isNotEmpty, isTrue);

    // Complete transition
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pumpAndSettle();

    expect(find.text('Beta Link'), findsOneWidget);
    expect(find.text('Alpha Note'), findsNothing);
  });
}
