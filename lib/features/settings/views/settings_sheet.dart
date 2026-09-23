import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:yank/core/motion/yank_motion.dart';
import 'package:yank/core/theme/yank_theme.dart';
import 'package:yank/core/widgets/yank_controls.dart';
import 'package:yank/features/auth/widgets/logout_tile.dart';
import 'package:yank/features/library/bloc/library_bloc.dart';
import 'package:yank/features/library/models/yank_item.dart';
import 'package:yank/features/settings/bloc/settings_bloc.dart';

Future<void> showSettingsSheet(
  BuildContext context, {
  AnimationController? animationController,
}) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      constraints: const BoxConstraints(maxWidth: 620),
      transitionAnimationController: animationController,
      sheetAnimationStyle: const AnimationStyle(
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInOutCubic,
      ),
      builder: (context) => const SettingsSheet(),
    );

class SettingsSheet extends StatelessWidget {
  const SettingsSheet({super.key});
  @override
  Widget build(
    BuildContext context,
  ) => BlocBuilder<SettingsBloc, SettingsState>(
    builder: (context, settings) => SafeArea(
      top: false,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const SheetHeading(
              title: 'Make yourself at home.',
              subtitle: 'A few things, just how you like them.',
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 0, 22, 26),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _Label('Appearance'),
                  Row(
                    children: ThemeMode.values.map((mode) {
                      final selected = settings.appearance.themeMode == mode;
                      return Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(
                            right: mode == ThemeMode.values.last ? 0 : 8,
                          ),
                          child: Semantics(
                            button: true,
                            selected: selected,
                            child: PressScale(
                              child: GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTap: () {
                                  HapticFeedback.lightImpact();
                                  context
                                      .read<SettingsBloc>()
                                      .add(ThemeChanged(mode));
                                },
                                child: AnimatedContainer(
                                  duration: YankMotion.quick,
                                  curve: Curves.easeOutCubic,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 13,
                                    horizontal: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: selected
                                        ? context.colors.tint
                                        : context.colors.surface,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: selected
                                          ? context.colors.iris.withValues(alpha: 0.35)
                                          : context.colors.line,
                                      width: 1,
                                    ),
                                  ),
                                  child: Column(
                                    children: [
                                      Icon(
                                        switch (mode) {
                                          ThemeMode.system =>
                                            LucideIcons.monitor,
                                          ThemeMode.light => LucideIcons.sun,
                                          ThemeMode.dark => LucideIcons.moon,
                                        },
                                        size: 19,
                                        color: selected
                                            ? context.colors.iris
                                            : context.colors.muted,
                                      ),
                                      const SizedBox(height: 7),
                                      Text(
                                        switch (mode) {
                                          ThemeMode.system => 'System',
                                          ThemeMode.light => 'Light',
                                          ThemeMode.dark => 'Dark',
                                        },
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: selected
                                              ? FontWeight.w600
                                              : FontWeight.normal,
                                          color: selected
                                              ? context.colors.iris
                                              : context.colors.muted,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    title: const Text(
                      'Reduce motion',
                      style: TextStyle(fontSize: 14),
                    ),
                    subtitle: const Text(
                      'Keep transitions quiet.',
                      style: TextStyle(fontSize: 12),
                    ),
                    value: settings.appearance.reduceMotion,
                    onChanged: (value) => context.read<SettingsBloc>().add(
                      ReduceMotionChanged(value),
                    ),
                  ),
                  const SizedBox(height: 15),
                  const _Label('Your library'),
                  _SettingsRow(
                    icon: LucideIcons.archive,
                    title: 'Archive',
                    subtitle: 'Out of the way. Still yours.',
                    onTap: () {
                      context.read<LibraryBloc>().add(
                        const SectionChanged(LibrarySection.archive),
                      );
                      Navigator.pop(context);
                    },
                  ),
                  _SettingsRow(
                    icon: LucideIcons.arrowDownLeft,
                    title: 'Clear Yank',
                    subtitle: 'Keep everything in your library.',
                    onTap: () async {
                      if (await confirmAction(
                            context,
                            title: 'Clear your working set?',
                            message: 'All items will stay in your library. Only their membership in Yank will be removed.',
                            action: 'Clear Yank',
                          ) &&
                          context.mounted) {
                        context.read<LibraryBloc>().add(const YankCleared());
                      }
                    },
                  ),
                  const SizedBox(height: 22),
                  const LogoutTile(),
                  const SizedBox(height: 20),
                  Text(
                    'Yank',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: context.colors.ink,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Universal cross-device capture for links, photos, audio, files, and text.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: context.colors.muted,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _Label extends StatelessWidget {
  const _Label(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Text(text, style: Theme.of(context).textTheme.titleMedium),
  );
}

class _SettingsRow extends StatelessWidget {
  const _SettingsRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });
  final IconData icon;
  final String title, subtitle;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: EdgeInsets.zero,
    leading: Icon(icon, size: 20, color: context.colors.iris),
    title: Text(title, style: const TextStyle(fontSize: 14)),
    subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
    trailing: Icon(
      LucideIcons.chevronRight,
      size: 16,
      color: context.colors.muted,
    ),
    onTap: onTap,
  );
}
