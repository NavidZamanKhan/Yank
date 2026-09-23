import 'dart:async';
import 'dart:convert';

import 'package:yank/features/library/models/yank_item.dart';
import 'package:yank/features/library/repositories/demo_fixtures.dart';
import 'package:yank/features/library/repositories/library_repository.dart';
import 'package:yank/features/library/repositories/metadata_store.dart';

class DemoLibraryRepository implements LibraryRepository {
  DemoLibraryRepository._(this._store, this._items);
  static const storageKey = 'yank.demo.library.v1';
  final MetadataStore _store;
  List<YankItem> _items;
  final _changes = StreamController<List<YankItem>>.broadcast(sync: true);
  Future<void> _pending = Future.value();

  static Future<DemoLibraryRepository> open(
    MetadataStore store, {
    bool seedIfEmpty = true,
  }) async {
    final saved = await store.read(storageKey);
    final items = saved == null
        ? (seedIfEmpty ? DemoFixtures.build() : const <YankItem>[])
        : (jsonDecode(saved) as List)
              .map(
                (value) =>
                    YankItem.fromJson(Map<String, dynamic>.from(value as Map)),
              )
              .where(
                (item) =>
                    seedIfEmpty || !DemoFixtures.demoIds.contains(item.id),
              )
              .toList();
    final repository = DemoLibraryRepository._(store, List.unmodifiable(items));
    if (saved == null) {
      await repository._commit(items);
    }
    return repository;
  }

  @override
  List<YankItem> get items => _items;
  @override
  Stream<List<YankItem>> get changes => _changes.stream;

  Future<void> _commit(List<YankItem> next) async {
    // Persistence completes before publishing. A failed write never masquerades
    // as a successful capture. This adapter is for small demo metadata only.
    await _store.write(
      storageKey,
      jsonEncode(next.map((i) => i.toJson()).toList()),
    );
    _items = List.unmodifiable(next);
    _changes.add(_items);
  }

  @override
  Future<void> put(YankItem item) =>
      _transaction(() => [..._items.where((old) => old.id != item.id), item]);
  @override
  Future<void> clearYank() => _transaction(
    () => _items.map((item) => item.copyWith(yankedAt: null)).toList(),
  );
  @override
  Future<void> reset() => _transaction(() => const <YankItem>[]);
  Future<void> _transaction(List<YankItem> Function() update) {
    // Capture and Library have separate Blocs. Serialize at their shared storage
    // boundary as well so simultaneous capture/toggle operations cannot lose data.
    final operation = _pending.then((_) => _commit(update()));
    _pending = operation.then<void>(
      (_) {},
      onError: (Object _, StackTrace _) {},
    );
    return operation;
  }

  @override
  Future<void> close() async {
    await _pending;
    await _changes.close();
  }
}
