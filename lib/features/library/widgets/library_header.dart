import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:yank/core/motion/yank_motion.dart';
import 'package:yank/core/theme/yank_theme.dart';
import 'package:yank/core/widgets/yank_controls.dart';
import 'package:yank/features/library/bloc/library_bloc.dart';
import 'package:yank/features/library/models/yank_item.dart';

class LibraryHeader extends StatelessWidget {
  const LibraryHeader({
    super.key,
    required this.state,
    required this.controller,
    required this.focusNode,
    required this.wide,
    required this.onQuery,
    required this.onKind,
    required this.onSource,
    required this.onSettings,
    required this.onBack,
    required this.onClearYank,
    this.onSearch,
  });
  final LibraryState state;
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool wide;
  final ValueChanged<String> onQuery;
  final ValueChanged<ItemKind?> onKind;
  final ValueChanged<String?> onSource;
  final VoidCallback onSettings, onBack, onClearYank;
  final VoidCallback? onSearch;
  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.fromLTRB(
      wide ? 26 : 19,
      wide ? 24 : 9,
      wide ? 26 : 19,
      0,
    ),
    child: _HeaderDragDetector(
      onSearch: onSearch,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (state.section == LibrarySection.archive && !wide)
                IconButton(
                  onPressed: onBack,
                  tooltip: 'Back to library',
                  icon: const Icon(LucideIcons.arrowLeft),
                ),
              if (!wide && state.section != LibrarySection.archive)
                const YankWordmark()
              else
                Text(switch (state.section) {
                  LibrarySection.library => 'Library',
                  LibrarySection.yank => 'Kept close.',
                  LibrarySection.archive => 'Archive',
                }, style: Theme.of(context).textTheme.titleLarge),
              const Spacer(),
              if (state.section == LibrarySection.yank && state.yankCount > 0)
                TextButton(
                  onPressed: onClearYank,
                  child: const Text('Clear', style: TextStyle(fontSize: 12)),
                ),
              if (!wide)
                IconButton(
                  onPressed: onSettings,
                  tooltip: 'Settings',
                  icon: Icon(
                    LucideIcons.settings2,
                    color: context.colors.muted,
                    size: 19,
                  ),
                ),
            ],
          ),
          SizedBox(height: wide ? 23 : 11),
          ListenableBuilder(
            listenable: focusNode,
            builder: (context, _) {
              final isFocused = focusNode.hasFocus;
              return AnimatedScale(
                scale: isFocused ? 1.015 : 1.0,
                duration: YankMotion.duration(
                  context,
                  const Duration(milliseconds: 200),
                ),
                curve: Curves.easeOutCubic,
                child: AnimatedContainer(
                  duration: YankMotion.duration(
                    context,
                    const Duration(milliseconds: 200),
                  ),
                  curve: Curves.easeOutCubic,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: isFocused
                        ? [
                            BoxShadow(
                              color:
                                  context.colors.iris.withValues(alpha: 0.18),
                              blurRadius: 16,
                              spreadRadius: 2,
                            ),
                          ]
                        : const [],
                  ),
                  child: TextField(
                    controller: controller,
                    focusNode: focusNode,
                    onChanged: onQuery,
                    style: const TextStyle(fontSize: 14),
                    textInputAction: TextInputAction.search,
                    decoration: InputDecoration(
                      hintText: isFocused ? 'Type to search...' : 'Find anything',
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 12,
                      ),
                      prefixIcon: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        child: Icon(
                          LucideIcons.search,
                          key: ValueKey(isFocused),
                          size: 17,
                          color: isFocused
                              ? context.colors.iris
                              : context.colors.muted,
                        ),
                      ),
                      suffixIcon: state.query.isEmpty
                          ? null
                          : IconButton(
                              onPressed: () {
                                controller.clear();
                                onQuery('');
                              },
                              tooltip: 'Clear search',
                              icon: const Icon(LucideIcons.x, size: 16),
                            ),
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 9),
        Row(
          children:
              <ItemKind?>[
                    null,
                    ItemKind.link,
                    ItemKind.photo,
                    ItemKind.audio,
                    ItemKind.file,
                  ]
                  .map(
                    (kind) => Expanded(
                      child: _TypeTab(
                        label: kind?.label ?? 'All',
                        selected: state.kind == kind,
                        onTap: () => onKind(kind),
                      ),
                    ),
                  )
                  .toList(),
        ),
        if (state.kind == ItemKind.link && state.sources.isNotEmpty)
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _SourceChip(
                  text: 'All sources',
                  selected: state.source == null,
                  onTap: () => onSource(null),
                ),
                ...state.sources.map(
                  (source) => _SourceChip(
                    text: source,
                    selected: source == state.source,
                    onTap: () => onSource(source),
                  ),
                ),
              ],
            ),
          ),
        if (state.offline)
          Padding(
            padding: const EdgeInsets.only(top: 9, bottom: 2),
            child: Row(
              children: [
                Icon(
                  LucideIcons.wifiOff,
                  size: 14,
                  color: context.colors.muted,
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    'Offline. Your saved items are still here.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class _TypeTab extends StatelessWidget {
  const _TypeTab({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Semantics(
    selected: selected,
    child: TextButton(
      onPressed: onTap,
      style: TextButton.styleFrom(
        minimumSize: const Size(44, 44),
        padding: EdgeInsets.zero,
        foregroundColor: selected ? context.colors.iris : context.colors.muted,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
          const SizedBox(height: 7),
          Container(
            width: 20,
            height: 3,
            decoration: BoxDecoration(
              color: selected ? context.colors.iris : Colors.transparent,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      ),
    ),
  );
}

class _SourceChip extends StatelessWidget {
  const _SourceChip({
    required this.text,
    required this.selected,
    required this.onTap,
  });
  final String text;
  final bool selected;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(right: 7, top: 3, bottom: 3),
    child: TextButton(
      onPressed: onTap,
      style: TextButton.styleFrom(
        backgroundColor: selected ? context.colors.tint : Colors.transparent,
        foregroundColor: selected ? context.colors.iris : context.colors.muted,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
      ),
      child: Text(text, style: const TextStyle(fontSize: 12)),
    ),
  );
}

class _HeaderDragDetector extends StatefulWidget {
  const _HeaderDragDetector({required this.onSearch, required this.child});
  final VoidCallback? onSearch;
  final Widget child;

  @override
  State<_HeaderDragDetector> createState() => _HeaderDragDetectorState();
}

class _HeaderDragDetectorState extends State<_HeaderDragDetector> {
  double _distance = 0.0;
  bool _triggered = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onVerticalDragStart: (_) {
        _distance = 0.0;
        _triggered = false;
      },
      onVerticalDragUpdate: (details) {
        _distance += details.primaryDelta ?? 0.0;
        if (_distance > 20.0 && !_triggered) {
          _triggered = true;
          widget.onSearch?.call();
        }
      },
      onVerticalDragEnd: (details) {
        if (!_triggered && (details.primaryVelocity ?? 0.0) > 100.0) {
          _triggered = true;
          widget.onSearch?.call();
        }
        _distance = 0.0;
        _triggered = false;
      },
      onVerticalDragCancel: () {
        _distance = 0.0;
        _triggered = false;
      },
      child: widget.child,
    );
  }
}
