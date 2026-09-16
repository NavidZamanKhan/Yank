import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/yank_theme.dart';
import '../bloc/auth_bloc.dart';

class AuthEmailForm extends StatefulWidget {
  const AuthEmailForm({super.key, required this.state});
  final AuthState state;
  @override
  State<AuthEmailForm> createState() => _AuthEmailFormState();
}

class _AuthEmailFormState extends State<AuthEmailForm> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _obscure = true;

  @override
  void didUpdateWidget(covariant AuthEmailForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.state.mode != widget.state.mode) {
      _password.clear();
      _obscure = true;
    }
  }

  @override
  void dispose() {
    _email.dispose();
    _password.clear();
    _password.dispose();
    super.dispose();
  }

  void _submit() {
    if (widget.state.busy) {
      return;
    }
    FocusScope.of(context).unfocus();
    context.read<AuthBloc>().add(
      AuthEmailSubmitted(_email.text, _password.text),
    );
  }

  void _changed(String _) {
    if (widget.state.emailError != null ||
        widget.state.passwordError != null ||
        widget.state.message != null) {
      context.read<AuthBloc>().add(const AuthErrorsCleared());
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    return AutofillGroup(
      // This is a demo. Do not invite the OS to save a sample password.
      onDisposeAction: AutofillContextAction.cancel,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            key: const ValueKey('auth-email'),
            controller: _email,
            enabled: !state.busy,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.email],
            autocorrect: false,
            maxLength: 254,
            onChanged: _changed,
            decoration: InputDecoration(
              labelText: 'Email address',
              hintText: 'you@example.com',
              counterText: '',
              errorText: state.emailError,
              errorMaxLines: 2,
              floatingLabelBehavior: FloatingLabelBehavior.always,
              fillColor: context.colors.surface,
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: context.colors.line),
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            key: const ValueKey('auth-password'),
            controller: _password,
            enabled: !state.busy,
            obscureText: _obscure,
            autocorrect: false,
            enableSuggestions: false,
            textInputAction: TextInputAction.done,
            maxLength: 128,
            onChanged: _changed,
            onSubmitted: (_) => _submit(),
            decoration: InputDecoration(
              labelText: 'Password',
              hintText: 'At least 8 characters',
              counterText: '',
              errorText: state.passwordError,
              errorMaxLines: 2,
              floatingLabelBehavior: FloatingLabelBehavior.always,
              fillColor: context.colors.surface,
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: context.colors.line),
              ),
              suffixIcon: IconButton(
                tooltip: _obscure ? 'Show password' : 'Hide password',
                onPressed: state.busy
                    ? null
                    : () => setState(() => _obscure = !_obscure),
                icon: Icon(
                  _obscure ? LucideIcons.eye : LucideIcons.eyeOff,
                  size: 18,
                  color: context.colors.muted,
                ),
              ),
            ),
          ),
          if (!state.isSignUp)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: state.busy
                    ? null
                    : () => showDialog<void>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Trying the login flow?'),
                          content: const Text(
                            'This is a local demo. Any sample password with 8 or more characters works. No password is stored and no reset email is sent.',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Got it'),
                            ),
                          ],
                        ),
                      ),
                child: const Text(
                  'Forgot password?',
                  style: TextStyle(fontSize: 12),
                ),
              ),
            ),
          SizedBox(height: state.isSignUp ? 20 : 6),
          FilledButton(
            key: const ValueKey('auth-email-submit'),
            onPressed: state.busy ? null : _submit,
            style: FilledButton.styleFrom(minimumSize: const Size(48, 52)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (state.activity == AuthActivity.email) ...[
                  const SizedBox.square(
                    dimension: 17,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  const SizedBox(width: 10),
                ],
                Flexible(
                  child: Text(
                    state.activity == AuthActivity.email
                        ? 'Opening your space...'
                        : state.isSignUp
                        ? 'Create account'
                        : 'Log in',
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
      ),
    );
  }
}
