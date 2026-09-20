import 'package:flutter_test/flutter_test.dart';
import 'package:yank/features/library/models/yank_item.dart';

class _FakeFirestoreTimestamp {
  const _FakeFirestoreTimestamp(this.date);
  final DateTime date;
  DateTime toDate() => date;
}

void main() {
  group('YankItem Firestore mapping & parsing', () {
    test('parses ISO8601 strings and roundtrips through toJson', () {
      final now = DateTime.utc(2026, 9, 20, 14, 30, 0);
      final item = YankItem(
        id: 'test-1',
        kind: ItemKind.link,
        title: 'Flutter Dev',
        createdAt: now,
        url: 'https://flutter.dev',
        yankedAt: now,
      );

      final json = item.toJson();
      final parsed = YankItem.fromMap(json);

      expect(parsed.id, 'test-1');
      expect(parsed.kind, ItemKind.link);
      expect(parsed.title, 'Flutter Dev');
      expect(parsed.createdAt, now);
      expect(parsed.url, 'https://flutter.dev');
      expect(parsed.yankedAt, now);
      expect(parsed.isYanked, isTrue);
    });

    test('parses Firestore Timestamp objects via toDate duck-typing', () {
      final time = DateTime.utc(2026, 9, 20, 10, 0, 0);
      final fakeTimestamp = _FakeFirestoreTimestamp(time);

      final map = {
        'id': 'doc-123',
        'kind': 'photo',
        'title': 'Sample Photo',
        'createdAt': fakeTimestamp,
        'yankedAt': fakeTimestamp,
      };

      final parsed = YankItem.fromMap(map);
      expect(parsed.createdAt, time);
      expect(parsed.yankedAt, time);
      expect(parsed.kind, ItemKind.photo);
    });

    test('overrides id when provided in fromMap', () {
      final map = {
        'kind': 'text',
        'title': 'Document with external ID',
        'createdAt': '2026-09-20T12:00:00.000Z',
      };

      final parsed = YankItem.fromMap(map, id: 'external-firestore-id');
      expect(parsed.id, 'external-firestore-id');
      expect(parsed.kind, ItemKind.text);
      expect(parsed.title, 'Document with external ID');
    });

    test('falls back gracefully on unknown kind or missing fields', () {
      final map = {
        'id': 'fallback-id',
        'kind': 'unknown_type_from_future',
      };

      final parsed = YankItem.fromMap(map);
      expect(parsed.id, 'fallback-id');
      expect(parsed.kind, ItemKind.link);
      expect(parsed.title, '');
      expect(parsed.createdAt, isNotNull);
      expect(parsed.body, '');
      expect(parsed.yankedAt, isNull);
      expect(parsed.archived, isFalse);
      expect(parsed.deleted, isFalse);
    });
  });
}
