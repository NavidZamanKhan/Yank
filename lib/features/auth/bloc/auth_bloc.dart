import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../models/auth_failure.dart';
import '../models/auth_input.dart';
import '../repositories/auth_repository.dart';
import 'auth_event.dart';
import 'auth_state.dart';
export 'auth_event.dart';
export 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc(this.repository) : super(AuthState(user: repository.currentUser)) {
    on<AuthEvent>(
      _handle,
      transformer: (events, mapper) => events.asyncExpand(mapper),
    );
  }
  final AuthRepository repository;
  Timer? _cooldownTimer;

  void _startCooldown([int seconds = 30]) {
    _cooldownTimer?.cancel();
    var remaining = seconds;
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      remaining--;
      if (isClosed) {
        timer.cancel();
        return;
      }
      add(AuthOtpCooldownTicked(remaining));
      if (remaining <= 0) {
        timer.cancel();
      }
    });
  }

  void _cancelTimer() {
    _cooldownTimer?.cancel();
    _cooldownTimer = null;
  }

  @override
  Future<void> close() {
    _cancelTimer();
    return super.close();
  }

  Future<void> _handle(AuthEvent event, Emitter<AuthState> emit) async {
    // A second queued tap cannot sign in again after the first one succeeded.
    if (state.user != null && event is! AuthLogoutRequested) {
      return;
    }
    try {
      switch (event) {
        case AuthModeChanged(:final mode):
          _cancelTimer();
          emit(
            state.copyWith(
              mode: mode,
              isVerifyingOtp: false,
              clearErrors: true,
            ),
          );
        case AuthEmailRevealed():
          emit(state.copyWith(emailExpanded: true));
        case AuthErrorsCleared():
          emit(state.copyWith(clearErrors: true));
        case AuthGoogleRequested():
          emit(state.copyWith(activity: AuthActivity.google));
          final user = await repository.continueWithGoogle();
          if (!emit.isDone) {
            emit(AuthState(user: user, mode: state.mode));
          }
        case AuthEmailSubmitted(
          :final email,
          :final password,
          :final confirmPassword,
        ):
          final emailError = AuthInput.emailError(email);
          final passwordError = AuthInput.passwordError(password);
          final confirmPasswordError = state.isSignUp
              ? AuthInput.confirmPasswordError(password, confirmPassword ?? '')
              : null;

          if (emailError != null ||
              passwordError != null ||
              confirmPasswordError != null) {
            emit(
              state.copyWith(
                emailError: emailError,
                passwordError: passwordError,
                confirmPasswordError: confirmPasswordError,
                emailExpanded: true,
              ),
            );
            return;
          }

          emit(state.copyWith(activity: AuthActivity.email, clearErrors: true));

          if (state.isSignUp) {
            if (repository.requiresOtpVerification) {
              await repository.sendSignUpOtp(email);
              if (!emit.isDone) {
                emit(
                  state.copyWith(
                    activity: AuthActivity.idle,
                    isVerifyingOtp: true,
                    pendingEmail: email,
                    pendingPassword: password,
                    otpCooldownRemaining: 30,
                    clearErrors: true,
                  ),
                );
                _startCooldown(30);
              }
            } else {
              final user = await repository.createAccount(email, password);
              if (!emit.isDone) {
                emit(AuthState(user: user, mode: state.mode));
              }
            }
          } else {
            final user = await repository.signInWithEmail(email, password);
            if (!emit.isDone) {
              emit(AuthState(user: user, mode: state.mode));
            }
          }
        case AuthOtpCooldownTicked(:final secondsRemaining):
          emit(state.copyWith(otpCooldownRemaining: secondsRemaining));
        case AuthOtpResendRequested():
          if (state.otpCooldownRemaining > 0 || state.pendingEmail == null) {
            return;
          }
          emit(state.copyWith(activity: AuthActivity.otp, clearErrors: true));
          await repository.sendSignUpOtp(state.pendingEmail!);
          if (!emit.isDone) {
            emit(
              state.copyWith(
                activity: AuthActivity.idle,
                otpCooldownRemaining: 30,
                message: 'Verification code resent to ${state.pendingEmail}.',
                noticeSerial: state.noticeSerial + 1,
              ),
            );
            _startCooldown(30);
          }
        case AuthOtpBackRequested():
          _cancelTimer();
          emit(state.copyWith(isVerifyingOtp: false, clearErrors: true));
        case AuthOtpSubmitted(:final otp):
          final otpError = AuthInput.otpError(otp);
          if (otpError != null) {
            emit(state.copyWith(otpError: otpError));
            return;
          }
          emit(state.copyWith(activity: AuthActivity.otp, clearErrors: true));
          final user = await repository.verifySignUpOtp(
            email: state.pendingEmail ?? '',
            password: state.pendingPassword ?? '',
            otp: otp,
          );
          _cancelTimer();
          if (!emit.isDone) {
            emit(AuthState(user: user, mode: state.mode));
          }
        case AuthPasswordResetRequested(:final email):
          final emailError = AuthInput.emailError(email);
          if (emailError != null) {
            emit(state.copyWith(emailError: emailError));
            return;
          }
          emit(state.copyWith(activity: AuthActivity.email, clearErrors: true));
          await repository.sendPasswordReset(email);
          if (!emit.isDone) {
            emit(
              state.copyWith(
                activity: AuthActivity.idle,
                message: 'Password reset link sent to $email. Check your inbox.',
                noticeSerial: state.noticeSerial + 1,
              ),
            );
          }
        case AuthEmailLinkRequested(:final email):
          final emailError = AuthInput.emailError(email);
          if (emailError != null) {
            emit(state.copyWith(emailError: emailError));
            return;
          }
          emit(state.copyWith(activity: AuthActivity.email, clearErrors: true));
          await repository.sendSignInLinkToEmail(email);
          if (!emit.isDone) {
            emit(
              state.copyWith(
                activity: AuthActivity.idle,
                message:
                    'Sign-in link sent to $email. Open the link in your email to sign in.',
                noticeSerial: state.noticeSerial + 1,
              ),
            );
          }
        case AuthEmailLinkVerified(:final email, :final emailLink):
          emit(state.copyWith(activity: AuthActivity.email, clearErrors: true));
          final user = await repository.signInWithEmailLink(
            email: email,
            emailLink: emailLink,
          );
          if (!emit.isDone) {
            emit(AuthState(user: user, mode: state.mode));
          }
        case AuthLogoutRequested():
          if (state.user == null) {
            return;
          }
          emit(state.copyWith(activity: AuthActivity.loggingOut));
          await repository.signOut();
          if (!emit.isDone) {
            emit(const AuthState(mode: AuthMode.logIn));
          }
      }
    } on AuthFailure catch (e) {
      if (emit.isDone) {
        return;
      }
      emit(
        state.copyWith(
          activity: AuthActivity.idle,
          message: e.message,
          noticeSerial: state.noticeSerial + 1,
        ),
      );
    } catch (_) {
      if (emit.isDone) {
        return;
      }
      emit(
        state.copyWith(
          activity: AuthActivity.idle,
          message: state.user == null
              ? 'Could not complete authentication. Please try again.'
              : 'Could not log out. Please try again.',
          noticeSerial: state.noticeSerial + 1,
        ),
      );
    }
  }
}
