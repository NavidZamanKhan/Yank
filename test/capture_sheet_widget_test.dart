import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:yank/core/theme/yank_theme.dart';
import 'package:yank/features/capture/bloc/capture_bloc.dart';
import 'package:yank/features/capture/views/capture_sheet.dart';
import 'package:yank/features/library/repositories/demo_library_repository.dart';
import 'package:yank/features/library/repositories/library_repository.dart';
import 'package:yank/features/library/repositories/metadata_store.dart';

void main() {
  group('CaptureSheet widget tests', () {
    late MemoryMetadataStore store;
    late DemoLibraryRepository repository;

    setUp(() async {
      store = MemoryMetadataStore();
      repository = await DemoLibraryRepository.open(store);
    });

    tearDown(() async {
      await repository.close();
    });

    Widget createTestWidget() {
      return MaterialApp(
        theme: YankTheme.build(Brightness.light),
        home: Scaffold(
          body: RepositoryProvider<LibraryRepository>.value(
            value: repository,
            child: Builder(
              builder: (context) => Center(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<bool>(
                        builder: (_) => BlocProvider(
                          create: (_) => CaptureBloc(repository),
                          child: const Scaffold(
                            body: SingleChildScrollView(
                              child: CaptureSheet(),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                  child: const Text('Open Sheet'),
                ),
              ),
            ),
          ),
        ),
      );
    }

    testWidgets('switches between all capture kinds and shows corresponding UI and buttons', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open Sheet'));
      await tester.pumpAndSettle();

      // Default kind is Link
      expect(find.text('Paste a link...'), findsOneWidget);
      expect(find.text('Paste from clipboard'), findsOneWidget);

      // Switch to Text
      await tester.tap(find.text('Text'));
      await tester.pumpAndSettle();
      expect(find.text('A thought, a quote, a tiny plan...'), findsOneWidget);
      expect(find.text('Paste from clipboard'), findsOneWidget);

      // Switch to Image (Photo)
      await tester.tap(find.text('Image'));
      await tester.pumpAndSettle();
      expect(find.text('Add an image to your library'), findsOneWidget);
      expect(find.text('Photos'), findsOneWidget);
      expect(find.text('Camera'), findsOneWidget);

      // Switch to Audio
      await tester.tap(find.text('Audio'));
      await tester.pumpAndSettle();
      expect(find.text('Choose an audio track or voice note'), findsOneWidget);
      expect(find.text('Browse audio files'), findsOneWidget);
      expect(find.byIcon(LucideIcons.fileAudio), findsOneWidget);

      // Switch to File
      await tester.tap(find.text('File'));
      await tester.pumpAndSettle();
      expect(find.text('Choose a document or file'), findsOneWidget);
      expect(find.text('Browse files'), findsOneWidget);
      expect(find.byIcon(LucideIcons.fileUp), findsOneWidget);

      // Verify Add to library button is present
      expect(find.text('Add to library'), findsOneWidget);
    });
  });
}
