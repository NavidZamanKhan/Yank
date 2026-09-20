import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:yank/core/motion/yank_motion.dart';
import 'package:yank/core/theme/yank_theme.dart';

class YankWordmark extends StatelessWidget {
  const YankWordmark({super.key, this.size = 32});
  final double size;
  @override
  Widget build(BuildContext context) => Text(
    'yank',
    semanticsLabel: 'Yank',
    style: TextStyle(
      fontSize: size,
      height: 1,
      fontWeight: FontWeight.w800,
      letterSpacing: -1.8,
      color: context.colors.ink,
    ),
  );
}

class YankToggle extends StatelessWidget {
  const YankToggle({
    super.key,
    required this.selected,
    required this.onPressed,
    required this.title,
  });
  final bool selected;
  final VoidCallback onPressed;
  final String title;
  @override
  Widget build(BuildContext context) => Semantics(
    toggled: selected,
    child: PressScale(
      child: IconButton(
        tooltip: '${selected ? 'Unyank' : 'Yank'} $title',
        onPressed: onPressed,
        style: IconButton.styleFrom(
          backgroundColor: selected ? context.colors.tint : Colors.transparent,
          foregroundColor: context.colors.iris,
        ),
        icon: const Icon(LucideIcons.arrowDownLeft, size: 18),
      ),
    ),
  );
}

class SheetHeading extends StatelessWidget {
  const SheetHeading({
    super.key,
    required this.title,
    this.subtitle,
    this.onClose,
  });
  final String title;
  final String? subtitle;
  final VoidCallback? onClose;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(22, 18, 12, 14),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleLarge),
              if (subtitle != null) ...[
                const SizedBox(height: 5),
                Text(subtitle!, style: Theme.of(context).textTheme.bodySmall),
              ],
            ],
          ),
        ),
        IconButton(
          onPressed: onClose ?? () => Navigator.pop(context),
          tooltip: 'Close',
          icon: const Icon(LucideIcons.x),
        ),
      ],
    ),
  );
}

Future<bool> confirmAction(
  BuildContext context, {
  required String title,
  required String message,
  required String action,
}) async =>
    await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(action),
          ),
        ],
      ),
    ) ??
    false;
