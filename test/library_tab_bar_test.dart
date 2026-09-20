import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yank/core/theme/yank_theme.dart';
import 'package:yank/features/library/bloc/library_state.dart';
import 'package:yank/features/library/models/yank_item.dart';
import 'package:yank/features/library/widgets/library_header.dart';

void main() {
  Widget buildHeader({
    required LibraryState state,
    ValueChanged<ItemKind?>? onKind,
    bool disableAnimations = false,
  }) {
    return MaterialApp(
      theme: YankTheme.build(Brightness.light),
      home: MediaQuery(
        data: MediaQueryData(
          size: const Size(400, 800),
          disableAnimations: disableAnimations,
        ),
        child: Scaffold(
          body: LibraryHeader(
            state: state,
            controller: TextEditingController(),
            focusNode: FocusNode(),
            wide: false,
            onQuery: (_) {},
            onKind: onKind ?? (_) {},
            onSource: (_) {},
            onSettings: () {},
            onBack: () {},
            onClearYank: () {},
          ),
        ),
      ),
    );
  }

  testWidgets(
      'category tab indicator starts centered under initial selected tab',
      (tester) async {
    final state = const LibraryState(
      items: [],
      kind: null,
    );

    await tester.pumpWidget(buildHeader(state: state));
    await tester.pumpAndSettle();

    final indicatorFinder = find.byKey(const ValueKey('type_tab_indicator'));
    expect(indicatorFinder, findsOneWidget);

    final indicatorRect = tester.getRect(indicatorFinder);
    expect(indicatorRect.width, equals(20.0));
    expect(indicatorRect.height, equals(3.0));

    final allTextFinder = find.text('All');
    final allTextRect = tester.getRect(allTextFinder);

    // Indicator center should align closely with the 'All' tab center
    expect((indicatorRect.center.dx - allTextRect.center.dx).abs(), lessThan(1.0));
  });

  testWidgets(
      'switching category tab smoothly slides indicator horizontally with dynamic stretch and elastic settlement',
      (tester) async {
    ItemKind? selectedKind;
    late StateSetter setWidgetState;
    var state = const LibraryState(items: [], kind: null);

    await tester.pumpWidget(
      StatefulBuilder(
        builder: (context, setState) {
          setWidgetState = setState;
          return buildHeader(
            state: state,
            onKind: (kind) {
              selectedKind = kind;
            },
          );
        },
      ),
    );
    await tester.pumpAndSettle();

    final indicatorFinder = find.byKey(const ValueKey('type_tab_indicator'));
    final initialRect = tester.getRect(indicatorFinder);
    expect(initialRect.width, equals(20.0));

    // Tap Photos tab
    final photosFinder = find.text('Photos');
    await tester.tap(photosFinder);
    expect(selectedKind, equals(ItemKind.photo));

    // Update state to trigger animation
    setWidgetState(() {
      state = state.copyWith(kind: ItemKind.photo);
    });
    await tester.pump();
    // Advance halfway through the 320ms animation (160ms)
    await tester.pump(const Duration(milliseconds: 160));

    final midRect = tester.getRect(indicatorFinder);
    // Mid-animation shows dynamic stretch
    expect(midRect.width, greaterThan(20.0));
    // Due to Curves.easeOutBack, midRect has reached and elastically overshot the destination
    expect(midRect.center.dx, greaterThan(initialRect.center.dx));

    // Complete the animation
    await tester.pumpAndSettle();

    final finalRect = tester.getRect(indicatorFinder);
    final photosTextRect = tester.getRect(photosFinder);

    // After settling, indicator width returns precisely to resting 20.0
    expect(finalRect.width, equals(20.0));
    // Indicator center aligns with Photos tab after elastic recoil
    expect((finalRect.center.dx - photosTextRect.center.dx).abs(), lessThan(1.0));
  });

  testWidgets(
      'switching category tab in reverse slides back smoothly',
      (tester) async {
    late StateSetter setWidgetState;
    var state = const LibraryState(items: [], kind: ItemKind.photo);

    await tester.pumpWidget(
      StatefulBuilder(
        builder: (context, setState) {
          setWidgetState = setState;
          return buildHeader(state: state);
        },
      ),
    );
    await tester.pumpAndSettle();

    final indicatorFinder = find.byKey(const ValueKey('type_tab_indicator'));
    final initialRect = tester.getRect(indicatorFinder);

    // Switch back to All
    setWidgetState(() {
      state = state.copyWith(kind: null);
    });
    await tester.pump();

    // Halfway through reverse slide
    await tester.pump(const Duration(milliseconds: 160));
    final midRect = tester.getRect(indicatorFinder);

    expect(midRect.center.dx, lessThan(initialRect.center.dx));
    expect(midRect.width, greaterThan(20.0));

    // Settle
    await tester.pumpAndSettle();
    final settledRect = tester.getRect(indicatorFinder);
    final allTextRect = tester.getRect(find.text('All'));

    expect(settledRect.width, equals(20.0));
    expect((settledRect.center.dx - allTextRect.center.dx).abs(), lessThan(1.0));
  });

  testWidgets(
      'rapidly interrupting tab change deflects indicator without teleporting',
      (tester) async {
    late StateSetter setWidgetState;
    var state = const LibraryState(items: [], kind: null);

    await tester.pumpWidget(
      StatefulBuilder(
        builder: (context, setState) {
          setWidgetState = setState;
          return buildHeader(state: state);
        },
      ),
    );
    await tester.pumpAndSettle();

    final indicatorFinder = find.byKey(const ValueKey('type_tab_indicator'));

    // Start animating toward Audio (index 3)
    setWidgetState(() {
      state = state.copyWith(kind: ItemKind.audio);
    });
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    final interruptedPos = tester.getRect(indicatorFinder).center.dx;

    // Immediately interrupt toward Links (index 1)
    setWidgetState(() {
      state = state.copyWith(kind: ItemKind.link);
    });
    await tester.pump();

    final newStartPos = tester.getRect(indicatorFinder).center.dx;
    // New animation must take off from current position without jump
    expect((newStartPos - interruptedPos).abs(), lessThan(1.0));

    await tester.pumpAndSettle();
    final finalRect = tester.getRect(indicatorFinder);
    final linkTextRect = tester.getRect(find.text('Links'));
    expect((finalRect.center.dx - linkTextRect.center.dx).abs(), lessThan(1.0));
  });

  testWidgets(
      'reduced motion places indicator immediately at target without stretch',
      (tester) async {
    late StateSetter setWidgetState;
    var state = const LibraryState(items: [], kind: null);

    await tester.pumpWidget(
      StatefulBuilder(
        builder: (context, setState) {
          setWidgetState = setState;
          return buildHeader(
            state: state,
            disableAnimations: true,
          );
        },
      ),
    );
    await tester.pumpAndSettle();

    final indicatorFinder = find.byKey(const ValueKey('type_tab_indicator'));

    setWidgetState(() {
      state = state.copyWith(kind: ItemKind.file);
    });
    await tester.pump();

    final fileTextRect = tester.getRect(find.text('Files'));
    final rect = tester.getRect(indicatorFinder);

    expect(rect.width, equals(20.0));
    expect((rect.center.dx - fileTextRect.center.dx).abs(), lessThan(1.0));
  });
}
