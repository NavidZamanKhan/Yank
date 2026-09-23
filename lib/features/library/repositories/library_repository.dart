import 'package:yank/features/library/models/yank_item.dart';

abstract interface class LibraryRepository {
  List<YankItem> get items;
  Stream<List<YankItem>> get changes;
  Future<void> put(YankItem item);
  Future<void> delete(String id);
  Future<void> clearYank();
  Future<void> reset();
  Future<void> close();
}
