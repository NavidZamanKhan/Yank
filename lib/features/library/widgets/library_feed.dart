import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/motion/yank_motion.dart';
import '../../../core/theme/yank_theme.dart';
import '../../../core/utils/formatters.dart';
import '../bloc/library_bloc.dart';
import '../models/yank_item.dart';
import 'yank_item_card.dart';

class LibraryFeed extends StatefulWidget {
  const LibraryFeed({
    super.key,
    required this.state,
    required this.wide,
    required this.onOpen,
    required this.onPreview,
    required this.onClear,
    required this.onCapture,
    required this.onBrowse,
  });

  final LibraryState state;
  final bool wide;
  final ValueChanged<YankItem> onOpen, onPreview;
  final VoidCallback onClear, onCapture, onBrowse;

  @override
  State<LibraryFeed> createState() => _LibraryFeedState();
}

class _LibraryFeedState extends State<LibraryFeed> {
  late LibrarySection _lastSection;
  ItemKind? _lastKind;
  bool _isForward = true;

  @override
  void initState() {
    super.initState();
    _lastSection = widget.state.section;
    _lastKind = widget.state.kind;
  }

  @override
  void didUpdateWidget(covariant LibraryFeed oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.state.section != _lastSection) {
      _isForward = widget.state.section.index >= _lastSection.index;
      _lastSection = widget.state.section;
      _lastKind = widget.state.kind;
    } else if (widget.state.kind != _lastKind) {
      _isForward = _kindIndex(widget.state.kind) >= _kindIndex(_lastKind);
      _lastKind = widget.state.kind;
    }
  }

  static int _kindIndex(ItemKind? kind) => switch (kind) {
    null => 0,
    ItemKind.link => 1,
    ItemKind.photo => 2,
    ItemKind.audio => 3,
    ItemKind.file => 4,
    ItemKind.text => 5,
  };

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final items = state.visible;
    final filterKey =
        '${state.section.name}-${state.kind?.name}-${state.source}-${state.query}';
    final currentKey = ValueKey(filterKey);

    final Widget content;
    if (items.isEmpty) {
      content = _EmptyLibrary(
        state: state,
        onClear: widget.onClear,
        onCapture: widget.onCapture,
        onBrowse: widget.onBrowse,
      );
    } else {
      final entries = <Object>[];
      String? previous;
      for (final item in items) {
        final label = dayLabel(
          state.section == LibrarySection.yank
              ? item.yankedAt!
              : item.createdAt,
        );
        if (state.query.isEmpty && label != previous) {
          entries.add(label);
          previous = label;
        }
        entries.add(item);
      }
      content = ListView.builder(
        key: PageStorageKey(filterKey),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: EdgeInsets.fromLTRB(
          widget.wide ? 24 : 15,
          12,
          widget.wide ? 24 : 15,
          24,
        ),
        itemCount: entries.length,
        itemBuilder: (context, index) {
          final entry = entries[index];
          if (entry is String) {
            return Padding(
              padding: EdgeInsets.fromLTRB(4, index == 0 ? 4 : 22, 4, 12),
              child: Text(
                entry,
                style: Theme.of(context).textTheme.bodySmall
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
            );
          }
          final item = entry as YankItem;
          return Padding(
            key: ValueKey(item.id),
            padding: const EdgeInsets.only(bottom: 14),
            child: YankItemCard(
              item: item,
              availability: state.availability(item.id),
              onOpen: () => widget.onOpen(item),
              onPreview: () => widget.onPreview(item),
            ),
          );
        },
      );
    }

    return AnimatedSwitcher(
      duration: YankMotion.duration(
        context,
        const Duration(milliseconds: 440),
      ),
      reverseDuration: YankMotion.duration(
        context,
        const Duration(milliseconds: 380),
      ),
      switchInCurve: Curves.linear,
      switchOutCurve: Curves.linear,
      layoutBuilder: (currentChild, previousChildren) => ClipRect(
        child: Stack(
          fit: StackFit.expand,
          children: [
            ...previousChildren,
            ?currentChild,
          ],
        ),
      ),
      transitionBuilder: (child, animation) {
        final isCurrent = child.key == currentKey;
        final beginOffset = _isForward
            ? (isCurrent
                ? const Offset(0.28, 0.0)
                : const Offset(-0.28, 0.0))
            : (isCurrent
                ? const Offset(-0.28, 0.0)
                : const Offset(0.28, 0.0));

        final slideCurve = isCurrent ? Curves.easeOutCubic : Curves.easeInCubic;
        final fadeInterval = isCurrent
            ? const Interval(0.24, 1.0, curve: Curves.easeOut)
            : const Interval(0.0, 0.60, curve: Curves.easeIn);

        return FadeTransition(
          opacity: CurvedAnimation(
            parent: animation,
            curve: fadeInterval,
          ),
          child: SlideTransition(
            position: Tween<Offset>(
              begin: beginOffset,
              end: Offset.zero,
            ).animate(
              CurvedAnimation(
                parent: animation,
                curve: slideCurve,
              ),
            ),
            child: child,
          ),
        );
      },
      child: KeyedSubtree(
        key: currentKey,
        child: content,
      ),
    );
  }
}

class _EmptyLibrary extends StatelessWidget {
  const _EmptyLibrary({
    required this.state,
    required this.onClear,
    required this.onCapture,
    required this.onBrowse,
  });
  final LibraryState state;
  final VoidCallback onClear, onCapture, onBrowse;
  @override
  Widget build(BuildContext context) {
    final searching =
        state.query.isNotEmpty || state.kind != null || state.source != null;
    final title = searching
        ? 'Nothing here just yet.'
        : switch (state.section) {
            LibrarySection.library => 'A little room for anything.',
            LibrarySection.yank => 'Keep something close.',
            LibrarySection.archive => 'Nothing tucked away.',
          };
    final description = searching
        ? 'Try a different word or clear the filters.'
        : switch (state.section) {
            LibrarySection.library =>
              'Add a link, an image, a sound, or a thought.',
            LibrarySection.yank =>
              'Tap the pull arrow on an item you are using right now.',
            LibrarySection.archive =>
              'Archived items will appear here and in search.',
          };
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: context.colors.tint,
                borderRadius: BorderRadius.circular(22),
              ),
              child: Icon(
                searching ? LucideIcons.search : LucideIcons.arrowDownLeft,
                color: context.colors.iris,
                size: 29,
              ),
            ),
            const SizedBox(height: 22),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 9),
            Text(
              description,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 20),
            TextButton(
              onPressed: searching
                  ? onClear
                  : state.section == LibrarySection.library
                  ? onCapture
                  : onBrowse,
              child: Text(
                searching
                    ? 'Clear search and filters'
                    : state.section == LibrarySection.library
                    ? 'Add something'
                    : 'Browse your library',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
