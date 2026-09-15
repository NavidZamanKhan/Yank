import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yank/core/theme/yank_theme.dart';
import 'package:yank/features/library/bloc/library_bloc.dart';
import 'package:yank/features/library/models/yank_item.dart';
import 'package:yank/features/library/repositories/demo_fixtures.dart';
import 'package:yank/features/library/repositories/demo_library_repository.dart';
import 'package:yank/features/library/repositories/metadata_store.dart';
import 'package:yank/features/library/widgets/yank_item_card.dart';

void main() {
  testWidgets('swiping right clamps travel to soft border and triggers yank',
      (tester) async {
    final store = MemoryMetadataStore();
    final repository = await DemoLibraryRepository.open(store);
    final bloc = LibraryBloc(repository);
    addTearDown(bloc.close);

    final item = DemoFixtures.build().first;

    await tester.pumpWidget(
      MaterialApp(
        theme: YankTheme.build(Brightness.light),
        home: Scaffold(
          body: BlocProvider.value(
            value: bloc,
            child: YankItemCard(
              item: item,
              availability: LocalAvailability.available,
              onOpen: () {},
              onPreview: () {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Find the item card material
    final cardFinder = find.byType(Material).last;
    final initialTopLeft = tester.getTopLeft(cardFinder);

    // Perform a horizontal drag of 200 pixels to the right in increments
    final gesture = await tester.startGesture(tester.getCenter(cardFinder));
    for (int i = 0; i < 10; i++) {
      await gesture.moveBy(const Offset(20, 0));
      await tester.pump(const Duration(milliseconds: 16));
    }

    // Verify the card did NOT travel 200px across the screen, but is clamped to at most 80px
    final draggedTopLeft = tester.getTopLeft(cardFinder);
    final travel = draggedTopLeft.dx - initialTopLeft.dx;
    expect(travel, lessThanOrEqualTo(80.5));
    expect(travel, greaterThanOrEqualTo(56.0));

    // Release gesture
    await gesture.up();
    await tester.pumpAndSettle();

    // Verify card sprang back to center (offset 0)
    final finalTopLeft = tester.getTopLeft(cardFinder);
    expect((finalTopLeft.dx - initialTopLeft.dx).abs(), lessThan(1.0));
  });

  testWidgets('swiping left clamps travel to soft border and triggers archive',
      (tester) async {
    final store = MemoryMetadataStore();
    final repository = await DemoLibraryRepository.open(store);
    final bloc = LibraryBloc(repository);
    addTearDown(bloc.close);

    final item = DemoFixtures.build().first;

    await tester.pumpWidget(
      MaterialApp(
        theme: YankTheme.build(Brightness.light),
        home: Scaffold(
          body: BlocProvider.value(
            value: bloc,
            child: YankItemCard(
              item: item,
              availability: LocalAvailability.available,
              onOpen: () {},
              onPreview: () {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final cardFinder = find.byType(Material).last;
    final initialTopLeft = tester.getTopLeft(cardFinder);

    // Drag 200 pixels to the left in increments
    final gesture = await tester.startGesture(tester.getCenter(cardFinder));
    for (int i = 0; i < 10; i++) {
      await gesture.moveBy(const Offset(-20, 0));
      await tester.pump(const Duration(milliseconds: 16));
    }

    // Travel should be clamped to at most -80px
    final draggedTopLeft = tester.getTopLeft(cardFinder);
    final travel = draggedTopLeft.dx - initialTopLeft.dx;
    expect(travel, greaterThanOrEqualTo(-80.5));
    expect(travel, lessThanOrEqualTo(-56.0));

    await gesture.up();
    await tester.pumpAndSettle();

    // Verify the item has been archived in the bloc state
    expect(bloc.state.item(item.id)?.archived, isTrue);

    // Verify the card slot collapsed its height to 0
    final size = tester.getSize(find.byType(SizeTransition).last);
    expect(size.height, equals(0.0));
  });
}
