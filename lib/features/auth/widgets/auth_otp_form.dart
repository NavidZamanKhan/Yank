import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:yank/core/theme/yank_theme.dart';
import 'package:yank/features/auth/bloc/auth_bloc.dart';

class AuthOtpForm extends StatefulWidget {
  const AuthOtpForm({super.key, required this.state});
  final AuthState state;

  @override
  State<AuthOtpForm> createState() => _AuthOtpFormState();
}

class _AuthOtpFormState extends State<AuthOtpForm> {
  final _otpController = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    // Auto focus the OTP input once presented.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _focusNode.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _otpController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _submit() {
    if (widget.state.busy) {
      return;
    }
    FocusScope.of(context).unfocus();
    context.read<AuthBloc>().add(AuthOtpSubmitted(_otpController.text));
  }

  void _onChanged(String value) {
    if (widget.state.otpError != null) {
      context.read<AuthBloc>().add(const AuthErrorsCleared());
    }
    if (value.trim().length == 6) {
      _submit();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final email = state.pendingEmail ?? '';
    final code = _otpController.text;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: context.colors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: context.colors.line),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    LucideIcons.shieldCheck,
                    size: 18,
                    color: context.colors.iris,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Verification code',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: context.colors.ink,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text.rich(
                TextSpan(
                  children: [
                    const TextSpan(text: 'We sent a 6-digit code to '),
                    TextSpan(
                      text: email,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: context.colors.ink,
                      ),
                    ),
                    const TextSpan(text: '. Enter it below to finish creating your space.'),
                  ],
                ),
                style: TextStyle(
                  fontSize: 12,
                  height: 1.45,
                  color: context.colors.muted,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        // Stack a transparent TextField on top of custom styled 6-digit boxes.
        Stack(
          alignment: Alignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(6, (index) {
                final char = index < code.length ? code[index] : '';
                final isCurrent = index == code.length && _focusNode.hasFocus;
                return Container(
                  width: 38,
                  height: 48,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: context.colors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: state.otpError != null
                          ? Theme.of(context).colorScheme.error
                          : isCurrent
                          ? context.colors.iris
                          : char.isNotEmpty
                          ? context.colors.iris.withValues(alpha: .5)
                          : context.colors.line,
                      width: isCurrent ? 1.5 : 1.0,
                    ),
                  ),
                  child: Text(
                    char,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: context.colors.ink,
                    ),
                  ),
                );
              }),
            ),
            Opacity(
              opacity: 0.0,
              child: TextField(
                key: const ValueKey('auth-otp-input'),
                controller: _otpController,
                focusNode: _focusNode,
                enabled: !state.busy,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.done,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(6),
                ],
                onChanged: (val) {
                  setState(() {});
                  _onChanged(val);
                },
                onSubmitted: (_) => _submit(),
              ),
            ),
          ],
        ),
        if (state.otpError != null) ...[
          const SizedBox(height: 10),
          Text(
            state.otpError!,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Theme.of(context).colorScheme.error,
              fontSize: 12,
            ),
          ),
        ],
        const SizedBox(height: 16),
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 12,
          runSpacing: 4,
          children: [
            TextButton(
              key: const ValueKey('auth-otp-back'),
              onPressed: state.busy
                  ? null
                  : () {
                      FocusScope.of(context).unfocus();
                      context.read<AuthBloc>().add(const AuthOtpBackRequested());
                    },
              style: TextButton.styleFrom(
                foregroundColor: context.colors.muted,
                padding: EdgeInsets.zero,
                minimumSize: const Size(48, 36),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(LucideIcons.arrowLeft, size: 14),
                  SizedBox(width: 5),
                  Text('Edit email', style: TextStyle(fontSize: 12)),
                ],
              ),
            ),
            TextButton(
              key: const ValueKey('auth-otp-resend'),
              onPressed: state.busy || state.otpCooldownRemaining > 0
                  ? null
                  : () => context
                      .read<AuthBloc>()
                      .add(const AuthOtpResendRequested()),
              style: TextButton.styleFrom(
                foregroundColor: context.colors.iris,
                padding: EdgeInsets.zero,
                minimumSize: const Size(48, 36),
              ),
              child: Text(
                state.otpCooldownRemaining > 0
                    ? 'Resend code in ${state.otpCooldownRemaining}s'
                    : 'Resend code',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: state.otpCooldownRemaining > 0
                      ? context.colors.muted
                      : context.colors.iris,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        FilledButton(
          key: const ValueKey('auth-otp-submit'),
          onPressed: state.busy ? null : _submit,
          style: FilledButton.styleFrom(minimumSize: const Size(48, 52)),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (state.activity == AuthActivity.otp) ...[
                const SizedBox.square(
                  dimension: 17,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                const SizedBox(width: 10),
              ],
              Flexible(
                child: Text(
                  state.activity == AuthActivity.otp
                      ? 'Verifying code...'
                      : 'Verify and create account',
                  textAlign: TextAlign.center,
                ),
              ),
              if (!state.busy) ...[
                const SizedBox(width: 9),
                const Icon(LucideIcons.arrowRight, size: 17),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
