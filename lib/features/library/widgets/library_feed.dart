import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

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
    this.onSearch,
  });

  final LibraryState state;
  final bool wide;
  final ValueChanged<YankItem> onOpen, onPreview;
  final VoidCallback onClear, onCapture, onBrowse;
  final VoidCallback? onSearch;

  @override
  State<LibraryFeed> createState() => _LibraryFeedState();
}

class _LibraryFeedState extends State<LibraryFeed> {
  late LibrarySection _lastSection;
  ItemKind? _lastKind;
  bool _isForward = true;
  bool _isPullingFromTop = false;
  bool _searchTriggered = false;
  final ScrollController _scrollController = ScrollController();

  bool _onScrollNotification(ScrollNotification notification) {
    if (widget.onSearch == null) return false;

    if (notification.metrics.axis != Axis.vertical) return false;

    final hasDrag = switch (notification) {
      ScrollStartNotification s => s.dragDetails != null,
      ScrollUpdateNotification u => u.dragDetails != null,
      OverscrollNotification o => o.dragDetails != null,
      _ => false,
    };

    if (notification is ScrollStartNotification) {
      // Only initiate pull-to-search when the user begins dragging while
      // the scrollable list is resting at the top boundary.
      if (hasDrag &&
          notification.metrics.extentBefore <= 0.0 &&
          notification.metrics.pixels <= 0.0) {
        _isPullingFromTop = true;
        _searchTriggered = false;
      } else {
        _isPullingFromTop = false;
      }
    } else if (notification is ScrollUpdateNotification) {
      if (notification.metrics.pixels > 0.0) {
        _isPullingFromTop = false;
      }
      if (_isPullingFromTop && hasDrag) {
        // On BouncingScrollPhysics, pulling down past top makes pixels negative.
        if (notification.metrics.pixels <= -12.0 && !_searchTriggered) {
          _searchTriggered = true;
          widget.onSearch!();
        }
      }
      // If drag ended and scroll returned to normal range, clear the pulling flag
      if (!hasDrag && notification.metrics.pixels >= 0.0) {
        _isPullingFromTop = false;
      }
    } else if (notification is OverscrollNotification) {
      // On ClampingScrollPhysics, overscroll captures the pull distance
      if (_isPullingFromTop && hasDrag) {
        if (notification.overscroll < -4.0 && !_searchTriggered) {
          _searchTriggered = true;
          widget.onSearch!();
        }
      }
    } else if (notification is ScrollEndNotification) {
      _isPullingFromTop = false;
      _searchTriggered = false;
    } else if (notification is UserScrollNotification) {
      if (notification.direction == ScrollDirection.idle) {
        _isPullingFromTop = false;
      }
    }
    return false;
  }


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
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
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
        const Duration(milliseconds: 400),
      ),
      reverseDuration: YankMotion.duration(
        context,
        const Duration(milliseconds: 400),
      ),
      switchInCurve: Curves.easeInOutCubic,
      switchOutCurve: Curves.easeInOutCubic,
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
                ? const Offset(1.0, 0.0)
                : const Offset(-1.0, 0.0))
            : (isCurrent
                ? const Offset(-1.0, 0.0)
                : const Offset(1.0, 0.0));

        final reduced = MediaQuery.disableAnimationsOf(context);

        final slideTransition = SlideTransition(
          position: Tween<Offset>(
            begin: beginOffset,
            end: Offset.zero,
          ).animate(animation),
          child: AnimatedBuilder(
            animation: animation,
            builder: (context, child) {
              final stretch = reduced
                  ? 0.0
                  : math.sin(animation.value * math.pi) * 0.05;
              return Transform(
                alignment: Alignment.center,
                transform: Matrix4.diagonal3Values(1.0 + stretch, 1.0, 1.0),
                child: child,
              );
            },
            child: child,
          ),
        );

        if (isCurrent) {
          return slideTransition;
        }

        return FadeTransition(
          opacity: animation,
          child: slideTransition,
        );
      },
      child: KeyedSubtree(
        key: currentKey,
        child: NotificationListener<ScrollNotification>(
          onNotification: _onScrollNotification,
          child: content,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
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
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
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
