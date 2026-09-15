import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/motion/yank_motion.dart';
import '../../../core/theme/yank_theme.dart';
import '../../../core/utils/formatters.dart';
import '../bloc/library_bloc.dart';
import '../models/yank_item.dart';
import 'yank_item_card.dart';

class LibraryFeed extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final items = state.visible;
    if (items.isEmpty) {
      return _EmptyLibrary(
        state: state,
        onClear: onClear,
        onCapture: onCapture,
        onBrowse: onBrowse,
      );
    }
    final entries = <Object>[];
    String? previous;
    for (final item in items) {
      final label = dayLabel(
        state.section == LibrarySection.yank ? item.yankedAt! : item.createdAt,
      );
      if (state.query.isEmpty && label != previous) {
        entries.add(label);
        previous = label;
      }
      entries.add(item);
    }
    final filterKey =
        '${state.section.name}-${state.kind?.name}-${state.source}';
    return AnimatedSwitcher(
      duration: YankMotion.duration(context, YankMotion.quick),
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      child: ListView.builder(
        key: PageStorageKey(filterKey),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: EdgeInsets.fromLTRB(wide ? 24 : 15, 12, wide ? 24 : 15, 24),
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
              onOpen: () => onOpen(item),
              onPreview: () => onPreview(item),
            ),
          );
        },
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
