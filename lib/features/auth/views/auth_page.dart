import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:yank/core/motion/yank_motion.dart';
import 'package:yank/core/theme/yank_theme.dart';
import 'package:yank/core/widgets/yank_controls.dart';
import 'package:yank/features/auth/bloc/auth_bloc.dart';
import 'package:yank/features/auth/widgets/auth_card_stack.dart';
import 'package:yank/features/auth/widgets/auth_email_form.dart';
import 'package:yank/features/auth/widgets/auth_otp_form.dart';
import 'package:yank/features/auth/widgets/google_auth_button.dart';

class AuthPage extends StatelessWidget {
  const AuthPage({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: BlocBuilder<AuthBloc, AuthState>(
        // Keep the last auth frame stable while the session gate fades it out.
        buildWhen: (old, next) => next.user == null,
        builder: (context, state) => LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 900;
            return Column(
              children: [
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    wide ? 40 : 26,
                    12,
                    wide ? 32 : 18,
                    0,
                  ),
                  child: Row(
                    children: [
                      const YankWordmark(size: 31),
                      const Spacer(),
                      IconButton(
                        tooltip: 'About this demo',
                        onPressed: () => _showDemoInfo(context),
                        icon: Icon(
                          LucideIcons.info,
                          size: 18,
                          color: context.colors.muted,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, viewport) {
                      final compact = viewport.maxHeight < 650;
                      return SingleChildScrollView(
                        keyboardDismissBehavior:
                            ScrollViewKeyboardDismissBehavior.onDrag,
                        padding: EdgeInsets.symmetric(
                          horizontal: wide ? 48 : 26,
                          vertical: 22,
                        ),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minHeight: (viewport.maxHeight - 44).clamp(
                              0.0,
                              double.infinity,
                            ),
                          ),
                          child: Center(
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                maxWidth: wide ? 1000 : 420,
                              ),
                              child: wide
                                  ? Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        Expanded(
                                          child: _Introduction(
                                            state: state,
                                            wide: true,
                                            compact: false,
                                          ),
                                        ),
                                        const SizedBox(width: 82),
                                        Expanded(
                                          child: ConstrainedBox(
                                            constraints: const BoxConstraints(
                                              maxWidth: 380,
                                            ),
                                            child: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  state.isVerifyingOtp
                                                      ? 'Verify your email.'
                                                      : state.isSignUp
                                                      ? 'Make yourself at home.'
                                                      : 'Your space is waiting.',
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .titleLarge,
                                                ),
                                                const SizedBox(height: 8),
                                                Text(
                                                  state.isVerifyingOtp
                                                      ? 'Almost there. One quick step.'
                                                      : state.isSignUp
                                                      ? 'A good place to start.'
                                                      : 'Pick up where you left off.',
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .bodySmall,
                                                ),
                                                const SizedBox(height: 28),
                                                _AuthActions(state: state),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    )
                                  : Column(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        _Introduction(
                                          state: state,
                                          wide: false,
                                          compact: compact,
                                        ),
                                        SizedBox(height: compact ? 24 : 30),
                                        _AuthActions(state: state),
                                      ],
                                    ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    ),
  );
}

class _Introduction extends StatelessWidget {
  const _Introduction({
    required this.state,
    required this.wide,
    required this.compact,
  });
  final AuthState state;
  final bool wide, compact;
  @override
  Widget build(BuildContext context) {
    final showArtwork =
        wide || (!state.emailExpanded && !state.isVerifyingOtp);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Expanding email makes room for the keyboard by folding the illustration
        // away. AnimatedSize interpolates layout; the form remains scrollable.
        AnimatedSize(
          duration: YankMotion.duration(context, YankMotion.panel),
          curve: Curves.easeOutCubic,
          alignment: Alignment.topCenter,
          child: showArtwork
              ? Padding(
                  padding: EdgeInsets.only(bottom: wide ? 32 : 23),
                  child: AuthCardStack(
                    height: wide
                        ? 260
                        : compact
                        ? 133
                        : 183,
                  ),
                )
              : const SizedBox(width: double.infinity),
        ),
        Semantics(
          header: true,
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: state.isVerifyingOtp
                      ? 'Almost\n'
                      : state.isSignUp
                      ? 'Everything worth\n'
                      : 'Good to have\n',
                ),
                TextSpan(
                  text: state.isVerifyingOtp
                      ? 'there.'
                      : state.isSignUp
                      ? 'keeping.'
                      : 'you back.',
                  style: TextStyle(color: context.colors.iris),
                ),
              ],
            ),
            style: TextStyle(
              fontSize: wide
                  ? 45
                  : (state.emailExpanded || state.isVerifyingOtp)
                  ? 31
                  : 35,
              height: 1.08,
              fontWeight: FontWeight.w600,
              letterSpacing: -1.3,
              color: context.colors.ink,
            ),
          ),
        ),
        const SizedBox(height: 14),
        Text(
          state.isVerifyingOtp
              ? 'Check your inbox for your 6-digit code to complete sign up.'
              : state.isSignUp
              ? 'Links, ideas, little discoveries.\nA place to keep them close.'
              : 'All those things you meant to come back to.\nRight where you left them.',
          style: TextStyle(
            fontSize: wide ? 15 : 13,
            height: 1.6,
            color: context.colors.muted,
          ),
        ),
        if (wide) ...[
          const SizedBox(height: 30),
          Row(
            children: [
              Icon(
                LucideIcons.arrowDownLeft,
                size: 16,
                color: context.colors.iris,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  'See it. Yank it. Find it anywhere.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _AuthActions extends StatelessWidget {
  const _AuthActions({required this.state});
  final AuthState state;

  @override
  Widget build(BuildContext context) {
    if (state.isVerifyingOtp) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AuthOtpForm(state: state),
          if (state.message != null)
            Padding(
              padding: const EdgeInsets.only(top: 14),
              child: Semantics(
                liveRegion: true,
                child: Text(
                  state.message!,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          const SizedBox(height: 20),
          Text(
            context.read<AuthBloc>().repository.isDemo
                ? 'Demo mode · enter any 6 digits to verify'
                : 'Enter the 6-digit code sent to your email',
            textAlign: TextAlign.center,
            style:
                Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 10),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GoogleAuthButton(
          key: const ValueKey('auth-google'),
          onPressed: state.busy
              ? null
              : () {
                  FocusScope.of(context).unfocus();
                  context.read<AuthBloc>().add(const AuthGoogleRequested());
                },
          loading: state.activity == AuthActivity.google,
        ),
        AnimatedSize(
          duration: YankMotion.duration(context, YankMotion.panel),
          curve: Curves.easeOutCubic,
          alignment: Alignment.topCenter,
          child: state.emailExpanded
              ? Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 21),
                      child: Row(
                        children: [
                          Expanded(child: Divider(color: context.colors.line)),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 13),
                            child: Text(
                              'or use email',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ),
                          Expanded(child: Divider(color: context.colors.line)),
                        ],
                      ),
                    ),
                    AuthEmailForm(state: state),
                  ],
                )
              : Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: TextButton(
                    key: const ValueKey('auth-email-reveal'),
                    onPressed: state.busy
                        ? null
                        : () => context.read<AuthBloc>().add(
                            const AuthEmailRevealed(),
                          ),
                    style: TextButton.styleFrom(
                      foregroundColor: context.colors.muted,
                      minimumSize: const Size(48, 46),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(LucideIcons.mail, size: 16),
                        const SizedBox(width: 9),
                        const Flexible(
                          child: Text(
                            'Continue with email',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
        ),
        if (state.message != null)
          Padding(
            padding: const EdgeInsets.only(top: 14),
            child: Semantics(
              liveRegion: true,
              child: Text(
                state.message!,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        Padding(
          padding: const EdgeInsets.only(top: 17),
          child: Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            alignment: WrapAlignment.center,
            children: [
              Text(
                state.isSignUp
                    ? 'Already have a space here?'
                    : 'New around here?',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              TextButton(
                key: const ValueKey('auth-mode-switch'),
                onPressed: state.busy
                    ? null
                    : () {
                        FocusScope.of(context).unfocus();
                        context.read<AuthBloc>().add(
                          AuthModeChanged(
                            state.isSignUp ? AuthMode.logIn : AuthMode.signUp,
                          ),
                        );
                      },
                child: Text(
                  state.isSignUp ? 'Log in' : 'Sign up',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),

      ],
    );
  }
}

void _showDemoInfo(BuildContext context) {
  final isDemo = context.read<AuthBloc>().repository.isDemo;
  showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(
        isDemo ? 'A little look inside Yank.' : 'Firebase Authentication',
      ),
      content: Text(
        isDemo
            ? 'Google opens a sample session. Email signup and login accept any valid email and a sample password of 8 or more characters. Passwords are never saved.\n\nThis is a local interface prototype. No Google account is connected and no email is sent.'
            : 'Authentication is securely managed by Firebase Authentication with Google Sign-In and Email Authentication. User sessions and credentials are encrypted and managed by Google Identity services.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Got it'),
        ),
      ],
    ),
  );
}
