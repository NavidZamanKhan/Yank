import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/yank_theme.dart';
import '../../../core/widgets/yank_controls.dart';
import '../../audio/bloc/audio_bloc.dart';
import '../../auth/widgets/logout_tile.dart';
import '../../library/bloc/library_bloc.dart';
import '../../library/models/yank_item.dart';
import '../bloc/settings_bloc.dart';

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
                    children: ThemeMode.values
                        .map(
                          (mode) => Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(right: 6),
                              child: OutlinedButton(
                                onPressed: () => context
                                    .read<SettingsBloc>()
                                    .add(ThemeChanged(mode)),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 13,
                                    horizontal: 4,
                                  ),
                                  foregroundColor:
                                      settings.appearance.themeMode == mode
                                      ? context.colors.iris
                                      : context.colors.muted,
                                  backgroundColor:
                                      settings.appearance.themeMode == mode
                                      ? context.colors.tint
                                      : context.colors.surface,
                                  side: BorderSide(
                                    color: settings.appearance.themeMode == mode
                                        ? context.colors.tint
                                        : context.colors.line,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    Icon(switch (mode) {
                                      ThemeMode.system => LucideIcons.monitor,
                                      ThemeMode.light => LucideIcons.sun,
                                      ThemeMode.dark => LucideIcons.moon,
                                    }, size: 19),
                                    const SizedBox(height: 7),
                                    Text(switch (mode) {
                                      ThemeMode.system => 'System',
                                      ThemeMode.light => 'Light',
                                      ThemeMode.dark => 'Dark',
                                    }, style: const TextStyle(fontSize: 12)),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        )
                        .toList(),
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
                  const SizedBox(height: 19),
                  const _Label('Demo controls'),
                  BlocBuilder<LibraryBloc, LibraryState>(
                    buildWhen: (a, b) => a.offline != b.offline,
                    builder: (context, library) => SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      title: const Text(
                        'Offline preview',
                        style: TextStyle(fontSize: 14),
                      ),
                      subtitle: const Text(
                        'Try local capture and unavailable downloads.',
                        style: TextStyle(fontSize: 12),
                      ),
                      value: library.offline,
                      onChanged: (value) => context.read<LibraryBloc>().add(
                        OfflineToggled(value),
                      ),
                    ),
                  ),
                  _SettingsRow(
                    icon: LucideIcons.rotateCcw,
                    title: 'Reset sample library',
                    subtitle: 'Restore the original demo content.',
                    onTap: () async {
                      final reset = await confirmAction(
                        context,
                        title: 'Start fresh?',
                        message: 'This removes items you added to this local demo and restores the original samples.',
                        action: 'Reset demo',
                      );
                      if (!context.mounted || !reset) {
                        return;
                      }
                      context.read<AudioBloc>().add(const AudioStopped());
                      context.read<LibraryBloc>().add(const DemoReset());
                      Navigator.pop(context);
                    },
                  ),
                  const SizedBox(height: 22),
                  const LogoutTile(),
                  const SizedBox(height: 14),
                  Text(
                    'Yank / Interface prototype',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Sample content lives on this device. Cloud availability is simulated; no account is connected.',
                    style: Theme.of(context).textTheme.bodySmall,
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
