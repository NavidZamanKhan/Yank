import 'package:flutter_test/flutter_test.dart';

import 'package:yank/features/capture/bloc/capture_bloc.dart';
import 'package:yank/features/library/models/yank_item.dart';
import 'package:yank/features/library/repositories/demo_library_repository.dart';
import 'package:yank/features/library/repositories/metadata_store.dart';

void main() {
  group('CaptureBloc functional captures', () {
    late MemoryMetadataStore store;
    late DemoLibraryRepository repository;

    setUp(() async {
      store = MemoryMetadataStore();
      repository = await DemoLibraryRepository.open(store);
    });

    tearDown(() async {
      await repository.close();
    });

    test('captures real photo with file path and custom title', () async {
      final bloc = CaptureBloc(repository);

      bloc.add(const CaptureKindChanged(ItemKind.photo));
      bloc.add(
        const CaptureFileSelected(
          filePath: '/mock/path/vacation.jpg',
          fileName: 'vacation.jpg',
          fileSize: 2048576,
        ),
      );
      bloc.add(const CaptureTitleChanged('Sunset at the beach'));
      bloc.add(const CaptureSubmitted());

      await expectLater(
        bloc.stream,
        emitsThrough(
          predicate<CaptureState>((state) => state.saved == true),
        ),
      );

      final saved = repository.items.firstWhere(
        (i) => i.title == 'Sunset at the beach',
      );
      expect(saved.kind, ItemKind.photo);
      expect(saved.artwork, '/mock/path/vacation.jpg');
      expect(saved.sizeBytes, 2048576);

      await bloc.close();
    });

    test('requires photo selection before submitting photo item', () async {
      final bloc = CaptureBloc(repository);

      bloc.add(const CaptureKindChanged(ItemKind.photo));
      bloc.add(const CaptureSubmitted());

      await expectLater(
        bloc.stream,
        emitsThrough(
          predicate<CaptureState>(
            (state) => state.error != null && state.saved == false,
          ),
        ),
      );

      await bloc.close();
    });

    test('captures real audio file with custom track title', () async {
      final bloc = CaptureBloc(repository);

      bloc.add(const CaptureKindChanged(ItemKind.audio));
      bloc.add(
        const CaptureFileSelected(
          filePath: '/mock/path/voice_note.m4a',
          fileName: 'voice_note.m4a',
          fileSize: 524288,
        ),
      );
      bloc.add(const CaptureTitleChanged('Idea Recording'));
      bloc.add(const CaptureSubmitted());

      await expectLater(
        bloc.stream,
        emitsThrough(
          predicate<CaptureState>((state) => state.saved == true),
        ),
      );

      final saved = repository.items.firstWhere(
        (i) => i.title == 'Idea Recording',
      );
      expect(saved.kind, ItemKind.audio);
      expect(saved.audioAsset, '/mock/path/voice_note.m4a');
      expect(saved.sizeBytes, 524288);

      await bloc.close();
    });

    test('captures real file/document with filename default', () async {
      final bloc = CaptureBloc(repository);

      bloc.add(const CaptureKindChanged(ItemKind.file));
      bloc.add(
        const CaptureFileSelected(
          filePath: '/mock/path/budget.xlsx',
          fileName: 'budget.xlsx',
          fileSize: 1048576,
        ),
      );
      bloc.add(const CaptureSubmitted());

      await expectLater(
        bloc.stream,
        emitsThrough(
          predicate<CaptureState>((state) => state.saved == true),
        ),
      );

      final saved = repository.items.firstWhere(
        (i) => i.title == 'budget.xlsx',
      );
      expect(saved.kind, ItemKind.file);
      expect(saved.url, '/mock/path/budget.xlsx');
      expect(saved.sizeBytes, 1048576);

      await bloc.close();
    });
  });
}
