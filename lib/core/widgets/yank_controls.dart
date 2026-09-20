import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

enum YankButtonVariant {
  primary,
  secondary,
  subtle,
}

class YankButton extends StatelessWidget {
  const YankButton({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    this.variant = YankButtonVariant.primary,
    this.loading = false,
    this.fullWidth = false,
    this.height = 48,
    this.padding,
  });

  const YankButton.secondary({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    this.loading = false,
    this.fullWidth = false,
    this.height = 48,
    this.padding,
  }) : variant = YankButtonVariant.secondary;

  const YankButton.subtle({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    this.loading = false,
    this.fullWidth = false,
    this.height = 38,
    this.padding,
  }) : variant = YankButtonVariant.subtle;

  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final YankButtonVariant variant;
  final bool loading;
  final bool fullWidth;
  final double height;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !loading;

    final (Color background, Color foreground, BorderSide? border) =
        switch (variant) {
      YankButtonVariant.primary => (
          enabled
              ? context.colors.iris
              : context.colors.muted.withValues(alpha: 0.35),
          Theme.of(context).brightness == Brightness.dark
              ? context.colors.canvas
              : Colors.white,
          null,
        ),
      YankButtonVariant.secondary => (
          context.colors.surface,
          enabled ? context.colors.ink : context.colors.muted,
          BorderSide(color: context.colors.line, width: 1.2),
        ),
      YankButtonVariant.subtle => (
          Colors.transparent,
          enabled ? context.colors.iris : context.colors.muted,
          null,
        ),
    };

    final content = Row(
      mainAxisSize: fullWidth ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (loading) ...[
          SizedBox.square(
            dimension: 17,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(foreground),
            ),
          ),
          const SizedBox(width: 9),
          Flexible(
            child: Text(
              'Saving...',
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: foreground,
              ),
            ),
          ),
        ] else ...[
          if (icon != null) ...[
            Icon(icon, size: 17, color: foreground),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: foreground,
              ),
            ),
          ),
        ],
      ],
    );

    final buttonBox = AnimatedContainer(
      duration: YankMotion.quick,
      height: height,
      padding: padding ??
          (variant == YankButtonVariant.subtle
              ? const EdgeInsets.symmetric(horizontal: 10, vertical: 6)
              : const EdgeInsets.symmetric(horizontal: 16)),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(13),
        border: border != null ? Border.fromBorderSide(border) : null,
        boxShadow: variant == YankButtonVariant.primary && enabled
            ? [
                BoxShadow(
                  color: context.colors.iris.withValues(alpha: 0.22),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ]
            : null,
      ),
      alignment: Alignment.center,
      child: content,
    );

    return Semantics(
      button: true,
      enabled: enabled,
      child: PressScale(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: enabled
              ? () {
                  HapticFeedback.lightImpact();
                  onPressed?.call();
                }
              : null,
          child: fullWidth
              ? SizedBox(width: double.infinity, child: buttonBox)
              : buttonBox,
        ),
      ),
    );
  }
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
        PressScale(
          child: IconButton(
            onPressed: onClose ?? () => Navigator.pop(context),
            tooltip: 'Close',
            icon: const Icon(LucideIcons.x),
          ),
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
