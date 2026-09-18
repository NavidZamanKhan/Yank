import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/motion/yank_motion.dart';
import '../../../core/theme/yank_theme.dart';
import '../../../core/widgets/yank_controls.dart';
import '../bloc/library_state.dart';
import '../models/yank_item.dart';

class LibraryBottomNavigation extends StatefulWidget {
  const LibraryBottomNavigation({
    super.key,
    required this.section,
    required this.yankCount,
    required this.onSection,
    required this.onCapture,
    this.notice,
    this.onUndo,
  });

  final LibrarySection section;
  final int yankCount;
  final ValueChanged<LibrarySection> onSection;
  final VoidCallback onCapture;
  final LibraryNotice? notice;
  final ValueChanged<YankItem>? onUndo;

  @override
  State<LibraryBottomNavigation> createState() =>
      _LibraryBottomNavigationState();
}

class _LibraryBottomNavigationState extends State<LibraryBottomNavigation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _expandController;
  late final Animation<double> _expandAnimation;
  late final Animation<double> _contentOpacity;
  Timer? _dismissTimer;
  LibraryNotice? _currentNotice;
  int? _lastNoticeSerial;

  @override
  void initState() {
    super.initState();
    _expandController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 360),
      reverseDuration: const Duration(milliseconds: 280),
    );
    _expandAnimation = CurvedAnimation(
      parent: _expandController,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInOutCubic,
    );
    _contentOpacity = CurvedAnimation(
      parent: _expandController,
      curve: const Interval(0.38, 1.0, curve: Curves.easeOut),
      reverseCurve: const Interval(0.55, 1.0, curve: Curves.easeIn),
    );

    if (widget.notice != null) {
      _showNotice(widget.notice!);
    }
  }

  @override
  void didUpdateWidget(covariant LibraryBottomNavigation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.notice != null &&
        (widget.notice!.serial != _lastNoticeSerial ||
            (!_expandController.isAnimating &&
                _expandController.value == 0.0))) {
      _showNotice(widget.notice!);
    }
  }

  void _showNotice(LibraryNotice notice) {
    _lastNoticeSerial = notice.serial;
    _currentNotice = notice;
    _dismissTimer?.cancel();
    HapticFeedback.lightImpact();
    _expandController.forward(from: 0.0);
    _dismissTimer = Timer(const Duration(milliseconds: 2800), () {
      if (mounted) {
        _collapse();
      }
    });
  }

  void _collapse() {
    _dismissTimer?.cancel();
    if (_expandController.value > 0.0) {
      _expandController.reverse();
    }
  }

  void _onUndo() {
    final item = _currentNotice?.undo;
    _collapse();
    if (item != null) {
      widget.onUndo?.call(item);
    }
  }

  @override
  void dispose() {
    _dismissTimer?.cancel();
    _expandController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    final onPrimaryColor = theme.colorScheme.onPrimary;

    return Container(
      decoration: BoxDecoration(
        color: context.colors.canvas,
        border: Border(top: BorderSide(color: context.colors.line)),
      ),
      child: SafeArea(
        top: false,
        minimum: const EdgeInsets.fromLTRB(16, 10, 16, 11),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final totalWidth = constraints.maxWidth;
            const buttonHeight = 46.0;
            const collapsedWidth = 46.0;
            const squircleRadius = 14.0;

            return AnimatedBuilder(
              animation: _expandAnimation,
              builder: (context, child) {
                final animValue = _expandAnimation.value;
                final isExpanded = animValue > 0.0;
                final currentWidth =
                    collapsedWidth + (totalWidth - collapsedWidth) * animValue;

                return SizedBox(
                  height: buttonHeight,
                  child: Stack(
                    alignment: Alignment.centerRight,
                    clipBehavior: Clip.none,
                    children: [
                      // Navigation row underneath, fading gently during expansion
                      Opacity(
                        opacity: (1.0 - animValue * 1.5).clamp(0.0, 1.0),
                        child: IgnorePointer(
                          ignoring: isExpanded,
                          child: Row(
                            children: [
                              Expanded(
                                child: _Destination(
                                  label: 'Library',
                                  icon: LucideIcons.layers,
                                  selected:
                                      widget.section == LibrarySection.library,
                                  onPressed: () => widget.onSection(
                                    LibrarySection.library,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 7),
                              Expanded(
                                child: _Destination(
                                  label: 'Yank',
                                  icon: LucideIcons.arrowDownLeft,
                                  selected:
                                      widget.section == LibrarySection.yank,
                                  count: widget.yankCount,
                                  onPressed: () => widget.onSection(
                                    LibrarySection.yank,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              const SizedBox.square(dimension: collapsedWidth),
                            ],
                          ),
                        ),
                      ),

                      // Morphing Action / Notification Pill expanding from right to left
                      Align(
                        alignment: Alignment.centerRight,
                        child: SizedBox(
                          width: currentWidth,
                          height: buttonHeight,
                          child: PressScale(
                            child: Tooltip(
                              message: isExpanded ? '' : 'Add something',
                              child: Material(
                                color: primaryColor,
                                clipBehavior: Clip.antiAlias,
                                borderRadius:
                                    BorderRadius.circular(squircleRadius),
                                elevation: isExpanded ? 2.0 : 0.0,
                                shadowColor:
                                    primaryColor.withValues(alpha: 0.3),
                                child: InkWell(
                                  onTap: () {
                                    if (isExpanded) {
                                      _collapse();
                                    } else {
                                      widget.onCapture();
                                    }
                                  },
                                  borderRadius:
                                      BorderRadius.circular(squircleRadius),
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      // Plus icon rotating and traveling leftwards to blend in
                                      Positioned(
                                        left: (collapsedWidth - 21) / 2,
                                        child: Transform.rotate(
                                          angle: animValue * (math.pi / 2),
                                          child: SizedBox.square(
                                            dimension: 21,
                                            child: Stack(
                                              alignment: Alignment.center,
                                              children: [
                                                if (animValue < 0.8)
                                                  Opacity(
                                                    opacity:
                                                        (1.0 - animValue * 1.6)
                                                            .clamp(0.0, 1.0),
                                                    child: Icon(
                                                      LucideIcons.plus,
                                                      size: 21,
                                                      color: onPrimaryColor,
                                                    ),
                                                  ),
                                                if (animValue > 0.2)
                                                  Opacity(
                                                    opacity:
                                                        ((animValue - 0.25) *
                                                                1.5)
                                                            .clamp(0.0, 1.0),
                                                    child: Icon(
                                                      LucideIcons.check,
                                                      size: 19,
                                                      color: onPrimaryColor,
                                                    ),
                                                  ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),

                                      // Notification message text
                                      if (isExpanded)
                                        Positioned(
                                          left: 40,
                                          right: _currentNotice?.undo != null
                                              ? 78
                                              : 14,
                                          child: FadeTransition(
                                            opacity: _contentOpacity,
                                            child: Text(
                                              _currentNotice?.message ?? '',
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w600,
                                                color: onPrimaryColor,
                                                letterSpacing: -0.1,
                                              ),
                                            ),
                                          ),
                                        ),

                                      // Optional Undo action
                                      if (isExpanded &&
                                          _currentNotice?.undo != null)
                                        Positioned(
                                          right: 8,
                                          child: FadeTransition(
                                            opacity: _contentOpacity,
                                            child: TextButton(
                                              onPressed: _onUndo,
                                              style: TextButton.styleFrom(
                                                visualDensity:
                                                    VisualDensity.compact,
                                                backgroundColor: onPrimaryColor
                                                    .withValues(alpha: 0.18),
                                                foregroundColor: onPrimaryColor,
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                  horizontal: 11,
                                                  vertical: 6,
                                                ),
                                                minimumSize: const Size(0, 30),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(10),
                                                ),
                                              ),
                                              child: const Text(
                                                'Undo',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
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
