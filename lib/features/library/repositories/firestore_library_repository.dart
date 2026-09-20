import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/yank_item.dart';
import 'demo_fixtures.dart';
import 'library_repository.dart';

class FirestoreLibraryRepository implements LibraryRepository {
  FirestoreLibraryRepository({
    required this.userId,
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  final String userId;
  final FirebaseFirestore _firestore;

  List<YankItem> _items = const [];
  final _changes = StreamController<List<YankItem>>.broadcast(sync: true);
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _subscription;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('users').doc(userId).collection('items');

  static Future<FirestoreLibraryRepository> open({
    required String userId,
    FirebaseFirestore? firestore,
    bool seedIfEmpty = true,
  }) async {
    final repository = FirestoreLibraryRepository(
      userId: userId,
      firestore: firestore,
    );
    await repository._init(seedIfEmpty: seedIfEmpty);
    return repository;
  }

  Future<void> _init({bool seedIfEmpty = true}) async {
    final completer = Completer<void>();

    _subscription = _collection.snapshots().listen(
      (snapshot) {
        final loaded = snapshot.docs.map((doc) {
          return YankItem.fromMap(doc.data(), id: doc.id);
        }).toList();

        _items = List.unmodifiable(loaded);
        _changes.add(_items);

        if (!completer.isCompleted) {
          completer.complete();
        }
      },
      onError: (Object error, StackTrace stack) {
        debugPrint('FirestoreLibraryRepository snapshot error: $error');
        if (!completer.isCompleted) {
          completer.completeError(error, stack);
        }
      },
    );

    try {
      await completer.future.timeout(const Duration(seconds: 4));
    } catch (error) {
      await close();
      throw StateError('Firestore connection failed: $error');
    }

    if (_items.isEmpty && seedIfEmpty) {
      try {
        await _seedDemoFixtures();
      } catch (e) {
        await close();
        throw StateError('Firestore seeding failed: $e');
      }
    }
  }

  Future<void> _seedDemoFixtures() async {
    final fixtures = DemoFixtures.build();
    for (var i = 0; i < fixtures.length; i += 400) {
      final chunk = fixtures.skip(i).take(400);
      final batch = _firestore.batch();
      for (final item in chunk) {
        batch.set(_collection.doc(item.id), item.toJson());
      }
      await batch.commit();
    }
  }

  @override
  List<YankItem> get items => _items;

  @override
  Stream<List<YankItem>> get changes => _changes.stream;

  @override
  Future<void> put(YankItem item) async {
    await _collection.doc(item.id).set(item.toJson(), SetOptions(merge: true));
  }

  @override
  Future<void> clearYank() async {
    final yanked = _items.where((i) => i.isYanked).toList();
    if (yanked.isEmpty) return;

    for (var i = 0; i < yanked.length; i += 400) {
      final chunk = yanked.skip(i).take(400);
      final batch = _firestore.batch();
      for (final item in chunk) {
        batch.update(_collection.doc(item.id), {'yankedAt': null});
      }
      await batch.commit();
    }
  }

  @override
  Future<void> reset() async {
    final existing = await _collection.get();
    for (var i = 0; i < existing.docs.length; i += 400) {
      final chunk = existing.docs.skip(i).take(400);
      final batch = _firestore.batch();
      for (final doc in chunk) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    }
    await _seedDemoFixtures();
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    _subscription = null;
    await _changes.close();
  }
}
