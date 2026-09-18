import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yank/core/theme/yank_theme.dart';
import 'package:yank/features/library/bloc/library_state.dart';
import 'package:yank/features/library/models/yank_item.dart';
import 'package:yank/features/library/widgets/library_feed.dart';
import 'package:yank/features/library/widgets/library_header.dart';

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

  testWidgets(
      'LibraryFeed triggers onSearch callback when user swipes down at top of feed',
      (tester) async {
    var searchTriggered = false;
    final items = [
      YankItem(
        id: 'item-1',
        kind: ItemKind.text,
        title: 'Alpha Note',
        createdAt: DateTime(2026, 9, 18),
      ),
    ];
    final state = LibraryState(
      items: items,
      section: LibrarySection.library,
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: YankTheme.build(Brightness.light),
        home: Scaffold(
          body: LibraryFeed(
            state: state,
            wide: false,
            onOpen: (_) {},
            onPreview: (_) {},
            onClear: () {},
            onCapture: () {},
            onBrowse: () {},
            onSearch: () => searchTriggered = true,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(searchTriggered, isFalse);

    // Swipe down on the feed
    await tester.drag(find.byType(ListView), const Offset(0.0, 80.0));
    await tester.pump();

    expect(searchTriggered, isTrue);
  });

  testWidgets(
      'LibraryFeed triggers onSearch callback when user swipes down on empty library',
      (tester) async {
    var searchTriggered = false;
    final state = LibraryState(
      items: const [],
      section: LibrarySection.library,
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: YankTheme.build(Brightness.light),
        home: Scaffold(
          body: LibraryFeed(
            state: state,
            wide: false,
            onOpen: (_) {},
            onPreview: (_) {},
            onClear: () {},
            onCapture: () {},
            onBrowse: () {},
            onSearch: () => searchTriggered = true,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(searchTriggered, isFalse);

    // Swipe down on empty state SingleChildScrollView
    await tester.drag(find.byType(SingleChildScrollView), const Offset(0.0, 80.0));
    await tester.pump();

    expect(searchTriggered, isTrue);
  });

  testWidgets(
      'LibraryHeader highlights with glow and triggers onSearch when swiped down',
      (tester) async {
    var searchTriggered = false;
    final controller = TextEditingController();
    final focusNode = FocusNode();
    addTearDown(controller.dispose);
    addTearDown(focusNode.dispose);

    await tester.pumpWidget(
      MaterialApp(
        theme: YankTheme.build(Brightness.light),
        home: Scaffold(
          body: LibraryHeader(
            state: const LibraryState(items: []),
            controller: controller,
            focusNode: focusNode,
            wide: false,
            onQuery: (_) {},
            onKind: (_) {},
            onSource: (_) {},
            onSettings: () {},
            onBack: () {},
            onClearYank: () {},
            onSearch: () {
              searchTriggered = true;
              focusNode.requestFocus();
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(focusNode.hasFocus, isFalse);

    // Swipe down across LibraryHeader
    await tester.fling(find.byType(LibraryHeader), const Offset(0.0, 300.0), 1000.0);
    await tester.pumpAndSettle();

    expect(searchTriggered, isTrue);
    expect(focusNode.hasFocus, isTrue);
  });

  testWidgets(
      'LibraryFeed does not trigger onSearch when scrolling up fast and bouncing at the top',
      (tester) async {
    var searchTriggered = false;
    final items = List.generate(
      20,
      (i) => YankItem(
        id: 'item-$i',
        kind: ItemKind.text,
        title: 'Item $i',
        createdAt: DateTime(2026, 9, 18),
      ),
    );
    final state = LibraryState(items: items);

    await tester.pumpWidget(
      MaterialApp(
        theme: YankTheme.build(Brightness.light),
        home: Scaffold(
          body: LibraryFeed(
            state: state,
            wide: false,
            onOpen: (_) {},
            onPreview: (_) {},
            onClear: () {},
            onCapture: () {},
            onBrowse: () {},
            onSearch: () => searchTriggered = true,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Scroll down into the feed
    await tester.drag(find.byType(ListView), const Offset(0.0, -400.0));
    await tester.pumpAndSettle();

    expect(searchTriggered, isFalse);

    // Fast fling up toward the top with high velocity so it hits top and bounces
    await tester.fling(find.byType(ListView), const Offset(0.0, 500.0), 3000.0);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pumpAndSettle();

    // Must NOT have triggered search
    expect(searchTriggered, isFalse);

    // Now intentionally drag down while resting at the top
    await tester.drag(find.byType(ListView), const Offset(0.0, 50.0));
    await tester.pump();

    // MUST trigger search when pulling down from the top
    expect(searchTriggered, isTrue);
  });

  testWidgets(
      'LibraryFeed does not trigger onSearch during continuous drag starting from down in list',
      (tester) async {
    var searchTriggered = false;
    final items = List.generate(
      20,
      (i) => YankItem(
        id: 'item-$i',
        kind: ItemKind.text,
        title: 'Item $i',
        createdAt: DateTime(2026, 9, 18),
      ),
    );
    final state = LibraryState(items: items);

    await tester.pumpWidget(
      MaterialApp(
        theme: YankTheme.build(Brightness.light),
        home: Scaffold(
          body: LibraryFeed(
            state: state,
            wide: false,
            onOpen: (_) {},
            onPreview: (_) {},
            onClear: () {},
            onCapture: () {},
            onBrowse: () {},
            onSearch: () => searchTriggered = true,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Scroll down to offset ~300
    await tester.drag(find.byType(ListView), const Offset(0.0, -300.0));
    await tester.pumpAndSettle();
    expect(searchTriggered, isFalse);

    // Drag 500px down in one gesture so it passes 0 into overscroll
    await tester.drag(find.byType(ListView), const Offset(0.0, 500.0));
    await tester.pump();

    // Because the drag started while extentBefore > 0, it must NOT trigger search
    expect(searchTriggered, isFalse);
  });

  testWidgets(
      'LibraryFeed triggers onSearch when trackpad pan down is performed at top',
      (tester) async {
    var searchTriggered = false;
    final items = List.generate(
      5,
      (i) => YankItem(
        id: 'item-$i',
        kind: ItemKind.text,
        title: 'Item $i',
        createdAt: DateTime(2026, 9, 18),
      ),
    );
    final state = LibraryState(items: items);

    await tester.pumpWidget(
      MaterialApp(
        theme: YankTheme.build(Brightness.light),
        home: Scaffold(
          body: LibraryFeed(
            state: state,
            wide: false,
            onOpen: (_) {},
            onPreview: (_) {},
            onClear: () {},
            onCapture: () {},
            onBrowse: () {},
            onSearch: () => searchTriggered = true,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(searchTriggered, isFalse);

    final location = tester.getCenter(find.byType(ListView));
    final gesture = await tester.createGesture(kind: PointerDeviceKind.trackpad);
    await gesture.panZoomStart(location);
    await gesture.panZoomUpdate(location, pan: const Offset(0.0, 40.0));
    await tester.pump();

    expect(searchTriggered, isTrue);

    await gesture.panZoomEnd();
    await tester.pumpAndSettle();
  });

  testWidgets(
      'LibraryFeed triggers onSearch when pointer scroll down occurs at top and not when scrolled',
      (tester) async {
    var searchTriggered = false;
    final items = List.generate(
      20,
      (i) => YankItem(
        id: 'item-$i',
        kind: ItemKind.text,
        title: 'Item $i',
        createdAt: DateTime(2026, 9, 18),
      ),
    );
    final state = LibraryState(items: items);

    await tester.pumpWidget(
      MaterialApp(
        theme: YankTheme.build(Brightness.light),
        home: Scaffold(
          body: LibraryFeed(
            state: state,
            wide: false,
            onOpen: (_) {},
            onPreview: (_) {},
            onClear: () {},
            onCapture: () {},
            onBrowse: () {},
            onSearch: () => searchTriggered = true,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(searchTriggered, isFalse);

    final location = tester.getCenter(find.byType(ListView));

    // Scrolling down at top (negative scrollDelta.dy) triggers search
    await tester.sendEventToBinding(
      PointerScrollEvent(
        position: location,
        scrollDelta: const Offset(0.0, -20.0),
      ),
    );
    await tester.pump();
    expect(searchTriggered, isTrue);

    // Reset and scroll down into the list
    searchTriggered = false;
    await tester.drag(find.byType(ListView), const Offset(0.0, -300.0));
    await tester.pumpAndSettle();

    // Scrolling when not at top should not trigger search
    await tester.sendEventToBinding(
      PointerScrollEvent(
        position: location,
        scrollDelta: const Offset(0.0, -20.0),
      ),
    );
    await tester.pump();
    expect(searchTriggered, isFalse);

    // Allow debounce timer to settle
    await tester.pump(const Duration(milliseconds: 400));
  });

  testWidgets(
      'LibraryFeed retains search focus throughout pull gesture and unfocuses on content scroll',
      (tester) async {
    final focusNode = FocusNode();
    final controller = TextEditingController();
    addTearDown(focusNode.dispose);
    addTearDown(controller.dispose);

    final items = List.generate(
      20,
      (i) => YankItem(
        id: 'item-$i',
        kind: ItemKind.text,
        title: 'Item $i',
        createdAt: DateTime(2026, 9, 18),
      ),
    );
    final state = LibraryState(items: items);

    await tester.pumpWidget(
      MaterialApp(
        theme: YankTheme.build(Brightness.light),
        home: Scaffold(
          body: Column(
            children: [
              TextField(controller: controller, focusNode: focusNode),
              Expanded(
                child: LibraryFeed(
                  state: state,
                  wide: false,
                  onOpen: (_) {},
                  onPreview: (_) {},
                  onClear: () {},
                  onCapture: () {},
                  onBrowse: () {},
                  onSearch: () => focusNode.requestFocus(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(focusNode.hasFocus, isFalse);

    // Pull down slowly like a real finger across multiple frames
    final center = tester.getCenter(find.byType(ListView));
    final gesture = await tester.startGesture(center, kind: PointerDeviceKind.touch);

    for (var i = 0; i < 12; i++) {
      await gesture.moveBy(const Offset(0.0, 5.0));
      await tester.pump(const Duration(milliseconds: 16));
    }

    // Must have gained focus and retained focus mid-pull
    expect(focusNode.hasFocus, isTrue);

    // Release finger and settle
    await gesture.up();
    await tester.pumpAndSettle();

    // Must remain focused after release
    expect(focusNode.hasFocus, isTrue);

    // Now drag down into content (scroll list down)
    final scrollGesture = await tester.startGesture(center, kind: PointerDeviceKind.touch);
    for (var i = 0; i < 8; i++) {
      await scrollGesture.moveBy(const Offset(0.0, -15.0));
      await tester.pump(const Duration(milliseconds: 16));
    }
    await scrollGesture.up();
    await tester.pumpAndSettle();

    // Scrolling down into content must have dismissed focus
    expect(focusNode.hasFocus, isFalse);
  });
}

