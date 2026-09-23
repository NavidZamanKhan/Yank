import 'package:flutter_test/flutter_test.dart';
import 'package:yank/features/library/bloc/library_bloc.dart';
import 'package:yank/features/library/models/yank_item.dart';
import 'package:yank/features/library/repositories/demo_library_repository.dart';
import 'package:yank/features/library/repositories/metadata_store.dart';

void main() {
  test(
    'rapid double toggle preserves the original state and timeline',
    () async {
      final repository = await DemoLibraryRepository.open(
        MemoryMetadataStore(),
      );
      final bloc = LibraryBloc(repository);
      final original = bloc.state.visible.map((i) => i.id).toList();
      final complete = bloc.stream.firstWhere(
        (state) => state.notice?.serial == 2,
      );
      bloc
        ..add(const ItemYankToggled('poster'))
        ..add(const ItemYankToggled('poster'));
      await complete;
      expect(bloc.state.item('poster')!.isYanked, isFalse);
      expect(bloc.state.visible.map((i) => i.id), original);
      await bloc.close();
      await repository.close();
    },
  );
  test('cancelled download cannot later become available', () async {
    final repository = await DemoLibraryRepository.open(MemoryMetadataStore());
    final bloc = LibraryBloc(
      repository,
      initialState: LibraryState(
        items: repository.items,
        local: const {'checklist': LocalAvailability.cloud},
      ),
    );
    final started = bloc.stream.firstWhere(
      (s) => s.availability('checklist') == LocalAvailability.downloading,
    );
    bloc.add(const DownloadRequested('checklist'));
    await started;
    final cancelled = bloc.stream.firstWhere(
      (s) => s.availability('checklist') == LocalAvailability.cloud,
    );
    bloc.add(const DownloadCancelled('checklist'));
    await cancelled;
    bloc.add(const DownloadFinished('checklist'));
    await Future<void>.delayed(Duration.zero);
    expect(bloc.state.availability('checklist'), LocalAvailability.cloud);
    await bloc.close();
    await repository.close();
  });

  test('NoticePosted emits a notice in LibraryState', () async {
    final repository = await DemoLibraryRepository.open(MemoryMetadataStore());
    final bloc = LibraryBloc(repository);
    final noticeFuture = bloc.stream.firstWhere(
      (state) => state.notice?.message == 'Yanked. It is in your library.',
    );
    bloc.add(const NoticePosted('Yanked. It is in your library.'));
    final stateWithNotice = await noticeFuture;
    expect(stateWithNotice.notice?.message, 'Yanked. It is in your library.');
    expect(stateWithNotice.notice?.serial, isNotNull);
    await bloc.close();
    await repository.close();
  });
}
