import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:yank/core/theme/yank_theme.dart';
import 'package:yank/features/auth/bloc/auth_bloc.dart';

class LogoutTile extends StatelessWidget {
  const LogoutTile({super.key});
  @override
  Widget build(BuildContext context) => BlocBuilder<AuthBloc, AuthState>(
    builder: (context, state) => ListTile(
      key: const ValueKey('settings-logout'),
      contentPadding: EdgeInsets.zero,
      leading: Icon(LucideIcons.logOut, size: 20, color: context.colors.iris),
      title: Text(
        state.activity == AuthActivity.loggingOut
            ? 'Logging out...'
            : 'Log out',
        style: const TextStyle(fontSize: 14),
      ),
      subtitle: Text(
        'Return to the welcome screen.',
        style: Theme.of(context).textTheme.bodySmall,
      ),
      trailing: state.activity == AuthActivity.loggingOut
          ? const SizedBox.square(
              dimension: 16,
              child: CircularProgressIndicator(strokeWidth: 1.5),
            )
          : Icon(
              LucideIcons.chevronRight,
              size: 16,
              color: context.colors.muted,
            ),
      onTap: state.busy
          ? null
          : () => context.read<AuthBloc>().add(const AuthLogoutRequested()),
    ),
  );
}
