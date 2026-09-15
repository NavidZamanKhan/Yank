import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/motion/yank_motion.dart';
import '../../../core/theme/yank_theme.dart';
import '../../../core/widgets/yank_controls.dart';
import '../models/yank_item.dart';

class LibraryBottomNavigation extends StatelessWidget {
  const LibraryBottomNavigation({
    super.key,
    required this.section,
    required this.yankCount,
    required this.onSection,
    required this.onCapture,
  });
  final LibrarySection section;
  final int yankCount;
  final ValueChanged<LibrarySection> onSection;
  final VoidCallback onCapture;
  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: context.colors.canvas,
      border: Border(top: BorderSide(color: context.colors.line)),
    ),
    child: SafeArea(
      top: false,
      minimum: const EdgeInsets.fromLTRB(16, 10, 16, 11),
      child: Row(
        children: [
          Expanded(
            child: _Destination(
              label: 'Library',
              icon: LucideIcons.layers,
              selected: section == LibrarySection.library,
              onPressed: () => onSection(LibrarySection.library),
            ),
          ),
          const SizedBox(width: 7),
          Expanded(
            child: _Destination(
              label: 'Yank',
              icon: LucideIcons.arrowDownLeft,
              selected: section == LibrarySection.yank,
              count: yankCount,
              onPressed: () => onSection(LibrarySection.yank),
            ),
          ),
          const SizedBox(width: 12),
          PressScale(
            child: Tooltip(
              message: 'Add something',
              child: SizedBox.square(
                dimension: 46,
                child: FilledButton(
                  onPressed: onCapture,
                  style: FilledButton.styleFrom(padding: EdgeInsets.zero),
                  child: const Icon(LucideIcons.plus, size: 21),
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class _Destination extends StatelessWidget {
  const _Destination({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onPressed,
    this.count,
  });
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onPressed;
  final int? count;
  @override
  Widget build(BuildContext context) => Semantics(
    selected: selected,
    child: TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        minimumSize: const Size(44, 46),
        padding: const EdgeInsets.symmetric(horizontal: 10),
        backgroundColor: selected ? context.colors.tint : Colors.transparent,
        foregroundColor: selected ? context.colors.iris : context.colors.muted,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 18),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
          if (count != null && count! > 0) ...[
            const SizedBox(width: 7),
            Text(
              '$count',
              style: TextStyle(fontSize: 11, color: context.colors.muted),
            ),
          ],
        ],
      ),
    ),
  );
}

class LibrarySidebar extends StatelessWidget {
  const LibrarySidebar({
    super.key,
    required this.section,
    required this.yankCount,
    required this.onSection,
    required this.onCapture,
    required this.onSettings,
  });
  final LibrarySection section;
  final int yankCount;
  final ValueChanged<LibrarySection> onSection;
  final VoidCallback onCapture, onSettings;
  @override
  Widget build(BuildContext context) => Container(
    width: 216,
    decoration: BoxDecoration(
      border: Border(right: BorderSide(color: context.colors.line)),
    ),
    padding: const EdgeInsets.fromLTRB(20, 34, 20, 20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const YankWordmark(size: 36),
        const SizedBox(height: 34),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: onCapture,
            icon: const Icon(LucideIcons.plus, size: 18),
            label: const Text('Add something'),
          ),
        ),
        const SizedBox(height: 28),
        _Destination(
          label: 'Library',
          icon: LucideIcons.layers,
          selected: section == LibrarySection.library,
          onPressed: () => onSection(LibrarySection.library),
        ),
        const SizedBox(height: 7),
        _Destination(
          label: 'Yank',
          icon: LucideIcons.arrowDownLeft,
          selected: section == LibrarySection.yank,
          count: yankCount,
          onPressed: () => onSection(LibrarySection.yank),
        ),
        const SizedBox(height: 7),
        _Destination(
          label: 'Archive',
          icon: LucideIcons.archive,
          selected: section == LibrarySection.archive,
          onPressed: () => onSection(LibrarySection.archive),
        ),
        const Spacer(),
        Text(
          'See it. Yank it.\nFind it anywhere.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(height: 1.7),
        ),
        const SizedBox(height: 20),
        TextButton.icon(
          onPressed: onSettings,
          style: TextButton.styleFrom(foregroundColor: context.colors.muted),
          icon: const Icon(LucideIcons.settings2, size: 18),
          label: const Text('Settings'),
        ),
      ],
    ),
  );
}
