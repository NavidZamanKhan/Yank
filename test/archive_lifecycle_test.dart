import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:yank/features/library/bloc/library_bloc.dart';
import 'package:yank/features/library/models/yank_item.dart';
import 'package:yank/features/library/repositories/demo_library_repository.dart';
import 'package:yank/features/library/repositories/metadata_store.dart';

void main() {
  group('YankItem archive and deletion model', () {
    test('archivedAt serializes and deserializes properly', () {
      final now = DateTime.now();
      final item = YankItem(
        id: 'archived-item',
        kind: ItemKind.text,
        title: 'Archived note',
        createdAt: now.subtract(const Duration(days: 10)),
        archived: true,
        archivedAt: now.subtract(const Duration(days: 5)),
      );

      final map = item.toJson();
      final restored = YankItem.fromMap(map);

      expect(restored.archived, isTrue);
      expect(restored.archivedAt, isNotNull);
      expect(
        restored.archivedAt!.millisecondsSinceEpoch,
        equals(item.archivedAt!.millisecondsSinceEpoch),
      );
    });

    test('isExpiredArchive calculation for 30 day threshold', () {
      final now = DateTime.now();
      final fresh = YankItem(
        id: 'fresh',
        kind: ItemKind.text,
        title: 'Fresh note',
        createdAt: now,
        archived: true,
        archivedAt: now,
      );
      expect(fresh.isExpiredArchive, isFalse);
      expect(fresh.daysUntilArchiveDeletion, 30);

      final mid = YankItem(
        id: 'mid',
        kind: ItemKind.text,
        title: 'Mid note',
        createdAt: now.subtract(const Duration(days: 20)),
        archived: true,
        archivedAt: now.subtract(const Duration(days: 15)),
      );
      expect(mid.isExpiredArchive, isFalse);
      expect(mid.daysUntilArchiveDeletion, 15);

      final expired = YankItem(
        id: 'expired',
        kind: ItemKind.text,
        title: 'Expired note',
        createdAt: now.subtract(const Duration(days: 35)),
        archived: true,
        archivedAt: now.subtract(const Duration(days: 31)),
      );
      expect(expired.isExpiredArchive, isTrue);
      expect(expired.daysUntilArchiveDeletion, 0);

      final unarchived = YankItem(
        id: 'unarchived',
        kind: ItemKind.text,
        title: 'Unarchived note',
        createdAt: now.subtract(const Duration(days: 40)),
        archived: false,
      );
      expect(unarchived.isExpiredArchive, isFalse);
    });
  });

  group('LibraryRepository permanent delete and auto-purge', () {
    test('delete physically removes item from repository and store', () async {
      final store = MemoryMetadataStore();
      final repository = await DemoLibraryRepository.open(store);
      final initialCount = repository.items.length;
      final targetId = repository.items.first.id;

      await repository.delete(targetId);

      expect(repository.items.length, initialCount - 1);
      expect(repository.items.any((i) => i.id == targetId), isFalse);

      await repository.close();

      // Verify that after reopening, the deleted item remains gone
      final reopened = await DemoLibraryRepository.open(store);
      expect(reopened.items.any((i) => i.id == targetId), isFalse);
      await reopened.close();
    });

    test('opening repository auto-purges items archived over 30 days', () async {
      final store = MemoryMetadataStore();
      final expiredItem = YankItem(
        id: 'expired-35-days',
        kind: ItemKind.text,
        title: 'Ancient archived note',
        createdAt: DateTime.now().subtract(const Duration(days: 40)),
        archived: true,
        archivedAt: DateTime.now().subtract(const Duration(days: 35)),
      );

      await store.write(
        DemoLibraryRepository.storageKey,
        jsonEncode([expiredItem.toJson()]),
      );

      final repository = await DemoLibraryRepository.open(store);
      expect(repository.items.any((i) => i.id == 'expired-35-days'), isFalse);

      await repository.close();

      final rawSaved = await store.read(DemoLibraryRepository.storageKey);
      expect(rawSaved, isNotNull);
      final List<dynamic> decoded = jsonDecode(rawSaved!) as List<dynamic>;
      expect(decoded.any((m) => (m as Map<String, dynamic>)['id'] == 'expired-35-days'), isFalse);
    });
  });

  group('LibraryBloc archive lifecycle and permanent deletion', () {
    test('ItemArchiveToggled stamps archivedAt on archive and clears on restore', () async {
      final repository = await DemoLibraryRepository.open(MemoryMetadataStore());
      final bloc = LibraryBloc(repository);
      final item = repository.items.first;

      // Toggle archive ON
      final archivedFuture = bloc.stream.firstWhere(
        (s) => s.item(item.id)?.archived == true,
      );
      bloc.add(ItemArchiveToggled(item.id));
      final archivedState = await archivedFuture;
      final archivedItem = archivedState.item(item.id)!;
      expect(archivedItem.archived, isTrue);
      expect(archivedItem.archivedAt, isNotNull);

      // Toggle archive OFF
      final unarchivedFuture = bloc.stream.firstWhere(
        (s) => s.item(item.id)?.archived == false,
      );
      bloc.add(ItemArchiveToggled(item.id));
      final unarchivedState = await unarchivedFuture;
      final unarchivedItem = unarchivedState.item(item.id)!;
      expect(unarchivedItem.archived, isFalse);
      expect(unarchivedItem.archivedAt, isNull);

      await bloc.close();
      await repository.close();
    });

    test('ItemDeleted removes item and ItemRestored restores it', () async {
      final repository = await DemoLibraryRepository.open(MemoryMetadataStore());
      final bloc = LibraryBloc(repository);
      final item = repository.items.first;

      final deletedFuture = bloc.stream.firstWhere(
        (s) => s.item(item.id) == null,
      );
      bloc.add(ItemDeleted(item.id));
      await deletedFuture;

      expect(bloc.state.item(item.id), isNull);
      expect(repository.items.any((i) => i.id == item.id), isFalse);

      // Restore item
      final restoredFuture = bloc.stream.firstWhere(
        (s) => s.item(item.id) != null,
      );
      bloc.add(ItemRestored(item));
      await restoredFuture;

      expect(bloc.state.item(item.id), isNotNull);
      expect(repository.items.any((i) => i.id == item.id), isTrue);

      await bloc.close();
      await repository.close();
    });
  });
}
