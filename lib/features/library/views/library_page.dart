import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:yank/core/theme/yank_theme.dart';
import 'package:yank/core/widgets/yank_controls.dart';
import 'package:yank/core/widgets/yank_feedback.dart';
import 'package:yank/features/audio/bloc/audio_bloc.dart';
import 'package:yank/features/audio/widgets/audio_controls.dart';
import 'package:yank/features/capture/views/capture_sheet.dart';
import 'package:yank/features/preview/views/item_preview.dart';
import 'package:yank/features/settings/bloc/settings_bloc.dart';
import 'package:yank/features/settings/views/settings_sheet.dart';
import 'package:yank/features/library/bloc/library_bloc.dart';
import 'package:yank/features/library/models/yank_item.dart';
import 'package:yank/features/library/widgets/item_actions.dart';
import 'package:yank/features/library/widgets/library_feed.dart';
import 'package:yank/features/library/widgets/library_header.dart';
import 'package:yank/features/library/widgets/library_navigation.dart';

class LibraryPage extends StatefulWidget {
  const LibraryPage({super.key});
  @override
  State<LibraryPage> createState() => _LibraryPageState();
}

class _LibraryPageState extends State<LibraryPage>
    with SingleTickerProviderStateMixin {
  final _search = TextEditingController();
  final _searchFocus = FocusNode();
  bool _captureOpen = false;
  late final AnimationController _sheetAnimation = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 400),
    reverseDuration: const Duration(milliseconds: 360),
  );
  LibraryBloc get _bloc => context.read<LibraryBloc>();

  @override
  void dispose() {
    _search.dispose();
    _searchFocus.dispose();
    _sheetAnimation.dispose();
    super.dispose();
  }

  Future<void> _waitForSheetClose() async {
    if (!_sheetAnimation.isAnimating) {
      return;
    }
    final completer = Completer<void>();
    void listener(AnimationStatus status) {
      if (status == AnimationStatus.dismissed) {
        _sheetAnimation.removeStatusListener(listener);
        if (!completer.isCompleted) {
          completer.complete();
        }
      }
    }

    _sheetAnimation.addStatusListener(listener);
    if (_sheetAnimation.status == AnimationStatus.dismissed) {
      _sheetAnimation.removeStatusListener(listener);
      if (!completer.isCompleted) {
        completer.complete();
      }
    }
    try {
      await completer.future;
    } finally {
      _sheetAnimation.removeStatusListener(listener);
    }
  }

  Future<void> _capture() async {
    if (_captureOpen || _sheetAnimation.isAnimating) {
      return;
    }
    _captureOpen = true;
    _searchFocus.unfocus();
    final saved = await showCaptureSheet(
      context,
      animationController: _sheetAnimation,
    );
    await _waitForSheetClose();
    _captureOpen = false;
    if (!mounted || saved != true) {
      return;
    }
    _clear();
    _bloc.add(const SectionChanged(LibrarySection.library));
    _bloc.add(const NoticePosted('Yanked. It is in your library.'));
  }

  void _clear() {
    _search.clear();
    _bloc
      ..add(const QueryChanged(''))
      ..add(const KindChanged(null));
  }

  void _triggerSearch() {
    if (!_searchFocus.hasFocus) {
      HapticFeedback.lightImpact();
      _searchFocus.requestFocus();
    }
  }

  Future<void> _preview(YankItem item, bool widePreview) async {
    if (_sheetAnimation.isAnimating) {
      return;
    }
    _searchFocus.unfocus();
    if (_bloc.state.availability(item.id) == LocalAvailability.cloud) {
      _bloc.add(DownloadRequested(item.id));
    }
    if (widePreview) {
      _bloc.add(PreviewSelected(item.id));
    } else {
      await showItemPreview(
        context,
        item.id,
        animationController: _sheetAnimation,
      );
      await _waitForSheetClose();
    }
  }

  Future<void> _showSettings() async {
    if (_sheetAnimation.isAnimating) {
      return;
    }
    await showSettingsSheet(
      context,
      animationController: _sheetAnimation,
    );
    await _waitForSheetClose();
  }

  Future<void> _open(YankItem item, bool widePreview) async {
    if (item.kind == ItemKind.link) {
      await openOriginal(context, item);
    } else {
      await _preview(item, widePreview);
    }
  }

  Future<void> _clearYank() async {
    if (await confirmAction(
          context,
          title: 'Clear your working set?',
          message: 'Your items will stay in the library.',
          action: 'Clear Yank',
        ) &&
        mounted) {
      _bloc.add(const YankCleared());
    }
  }

  @override
  Widget build(BuildContext context) => MultiBlocListener(
    listeners: [
      BlocListener<LibraryBloc, LibraryState>(
        listenWhen: (old, next) =>
            old.query != next.query && next.query.isEmpty,
        listener: (_, _) => _search.clear(),
      ),
      BlocListener<LibraryBloc, LibraryState>(
        listener: (context, state) {
          final playing = context.read<AudioBloc>().state.item;
          if (playing != null &&
              (state.item(playing.id) == null ||
                  state.availability(playing.id) !=
                      LocalAvailability.available)) {
            context.read<AudioBloc>().add(const AudioStopped());
          }
        },
      ),
      BlocListener<LibraryBloc, LibraryState>(
        listenWhen: (old, next) => old.notice != next.notice,
        listener: (context, state) {
          final notice = state.notice;
          if (notice == null) {
            return;
          }
          final wide = MediaQuery.sizeOf(context).width >= 900;
          if (wide) {
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(
                SnackBar(
                  content: Text(notice.message),
                  action: notice.undo == null
                      ? null
                      : SnackBarAction(
                          label: 'Undo',
                          onPressed: () => _bloc.add(ItemRestored(notice.undo!)),
                        ),
                ),
              );
          }
        },
      ),
      BlocListener<AudioBloc, AudioState>(
        listenWhen: (a, b) => a.errorSerial != b.errorSerial && b.error != null,
        listener: (context, state) => showMessage(context, state.error!),
      ),
      BlocListener<SettingsBloc, SettingsState>(
        listenWhen: (a, b) => a.errorSerial != b.errorSerial && b.error != null,
        listener: (context, state) => showMessage(context, state.error!),
      ),
    ],
    child: CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.keyF, meta: true):
            _searchFocus.requestFocus,
        const SingleActivator(LogicalKeyboardKey.keyF, control: true):
            _searchFocus.requestFocus,
        const SingleActivator(LogicalKeyboardKey.keyN, meta: true): _capture,
        const SingleActivator(LogicalKeyboardKey.keyN, control: true): _capture,
        const SingleActivator(LogicalKeyboardKey.digit1, meta: true): () =>
            _bloc.add(const SectionChanged(LibrarySection.library)),
        const SingleActivator(LogicalKeyboardKey.digit2, meta: true): () =>
            _bloc.add(const SectionChanged(LibrarySection.yank)),
        const SingleActivator(LogicalKeyboardKey.escape): () {
          _searchFocus.unfocus();
          _bloc.add(const PreviewSelected(null));
          _clear();
        },
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? Colors.black
            : const Color(0xFFDDD9D2),
        body: AnimatedBuilder(
          animation: _sheetAnimation,
          builder: (context, child) {
            final reduced = MediaQuery.disableAnimationsOf(context);
            final isWide = MediaQuery.sizeOf(context).width >= 900;
            final isDark = Theme.of(context).brightness == Brightness.dark;
            final curve = _sheetAnimation.status == AnimationStatus.reverse
                ? Curves.easeInOutCubic
                : Curves.easeOutCubic;
            final t = (reduced || isWide)
                ? 0.0
                : curve.transform(
                    _sheetAnimation.value.clamp(0.0, 1.0),
                  );

            final scale = 1.0 - (0.075 * t);
            final translateY = 55.0 * t;
            final radius = 34.0 * t;
            final dimAlpha = (isDark ? 0.22 : 0.04) * t;

            return AnnotatedRegion<SystemUiOverlayStyle>(
              value: (isDark
                      ? SystemUiOverlayStyle.light
                      : SystemUiOverlayStyle.dark)
                  .copyWith(
                    statusBarColor: Colors.transparent,
                    systemNavigationBarColor: Colors.transparent,
                  ),
              child: Transform.translate(
                offset: Offset(0, translateY),
                child: Transform.scale(
                  scale: scale,
                  alignment: Alignment.topCenter,
                  child: Container(
                    decoration: BoxDecoration(
                      color: context.colors.canvas,
                      borderRadius: BorderRadius.circular(radius),
                      boxShadow: t > 0
                          ? [
                              BoxShadow(
                                color: Colors.black.withValues(
                                  alpha: (isDark ? 0.45 : 0.10) * t,
                                ),
                                blurRadius: (isDark ? 28.0 : 20.0) * t,
                                offset: Offset(0, (isDark ? 8.0 : 5.0) * t),
                              ),
                            ]
                          : null,
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        child!,
                        if (dimAlpha > 0)
                          Positioned.fill(
                            child: IgnorePointer(
                              child: ColoredBox(
                                color: Colors.black.withValues(
                                  alpha: dimAlpha,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: () {
              if (_searchFocus.hasFocus) {
                _searchFocus.unfocus();
              }
            },
            child: SafeArea(
              bottom: false,
              child: LayoutBuilder(
              builder: (context, constraints) {
                final wide = constraints.maxWidth >= 900;
                final widePreview = constraints.maxWidth >= 1180;
                return BlocBuilder<LibraryBloc, LibraryState>(
                  builder: (context, state) {
                    final selected = state.selectedId == null
                        ? null
                        : state.item(state.selectedId!);
                    final content = Column(
                      children: [
                        LibraryHeader(
                          state: state,
                          controller: _search,
                          focusNode: _searchFocus,
                          wide: wide,
                          onQuery: (query) => _bloc.add(QueryChanged(query)),
                          onKind: (kind) => _bloc.add(KindChanged(kind)),
                          onSource: (source) =>
                              _bloc.add(SourceChanged(source)),
                          onSettings: _showSettings,
                          onBack: () => _bloc.add(
                            const SectionChanged(LibrarySection.library),
                          ),
                          onClearYank: _clearYank,
                          onSearch: _triggerSearch,
                        ),
                        Expanded(
                          child: LibraryFeed(
                            state: state,
                            wide: wide,
                            onOpen: (item) => _open(item, widePreview),
                            onPreview: (item) => _preview(item, widePreview),
                            onClear: _clear,
                            onCapture: _capture,
                            onBrowse: () => _bloc.add(
                              const SectionChanged(LibrarySection.library),
                            ),
                            onSearch: _triggerSearch,
                          ),
                        ),
                        const MiniPlayer(),
                        if (!wide)
                          LibraryBottomNavigation(
                            section: state.section,
                            yankCount: state.yankCount,
                            onSection: (section) =>
                                _bloc.add(SectionChanged(section)),
                            onCapture: _capture,
                            notice: state.notice,
                            onUndo: (item) => _bloc.add(ItemRestored(item)),
                          ),
                      ],
                    );
                    if (!wide) {
                      return content;
                    }
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        LibrarySidebar(
                          section: state.section,
                          yankCount: state.yankCount,
                          onSection: (section) =>
                              _bloc.add(SectionChanged(section)),
                          onCapture: _capture,
                          onSettings: _showSettings,
                        ),
                        Expanded(
                          child: Center(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 670),
                              child: content,
                            ),
                          ),
                        ),
                        if (widePreview && selected != null)
                          Container(
                            width: 370,
                            decoration: BoxDecoration(
                              color: context.colors.canvas,
                              border: Border(
                                left: BorderSide(color: context.colors.line),
                              ),
                            ),
                            child: ItemPreview(
                              id: selected.id,
                              onClose: () =>
                                  _bloc.add(const PreviewSelected(null)),
                            ),
                          ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
        ),
      ),
    ),
  ),
);
}
