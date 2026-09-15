import 'package:flutter_test/flutter_test.dart';
import 'package:yank/features/library/models/yank_item.dart';
import 'package:yank/features/library/repositories/demo_library_repository.dart';
import 'package:yank/features/library/repositories/metadata_store.dart';

void main() {
  test(
    'concurrent capture and an existing-item update both survive restart',
    () async {
      final store = MemoryMetadataStore();
      final repository = await DemoLibraryRepository.open(store);
      final before = repository.items.first;
      final captured = YankItem(
        id: 'new',
        kind: ItemKind.text,
        title: 'New thought',
        createdAt: DateTime.now(),
        body: 'Keep it.',
      );
      await Future.wait([
        repository.put(captured),
        repository.put(before.copyWith(archived: true)),
      ]);
      await repository.close();
      final reopened = await DemoLibraryRepository.open(store);
      expect(reopened.items.any((i) => i.id == 'new'), isTrue);
      expect(
        reopened.items.singleWhere((i) => i.id == before.id).archived,
        isTrue,
      );
      await reopened.close();
    },
  );
  test('a failed write does not publish a pretend saved item', () async {
    final store = _FailingStore();
    final repository = await DemoLibraryRepository.open(store);
    final before = repository.items;
    store.fail = true;
    await expectLater(
      repository.put(before.first.copyWith(title: 'Unsaved')),
      throwsStateError,
    );
    expect(repository.items, same(before));
    store.fail = false;
    await repository.put(before.first.copyWith(title: 'Saved'));
    expect(repository.items.any((i) => i.title == 'Saved'), isTrue);
    await repository.close();
  });
}

class _FailingStore extends MemoryMetadataStore {
  bool fail = false;
  @override
  Future<void> write(String key, String value) async {
    if (fail) {
      throw StateError('write failed');
    }
    await super.write(key, value);
  }
}
