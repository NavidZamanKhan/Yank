import 'package:flutter_bloc/flutter_bloc.dart';

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

  Future<void> _handle(AuthEvent event, Emitter<AuthState> emit) async {
    // A second queued tap cannot sign in again after the first one succeeded.
    if (state.user != null && event is! AuthLogoutRequested) {
      return;
    }
    try {
      switch (event) {
        case AuthModeChanged(:final mode):
          emit(state.copyWith(mode: mode));
        case AuthEmailRevealed():
          emit(state.copyWith(emailExpanded: true));
        case AuthErrorsCleared():
          emit(state.copyWith());
        case AuthGoogleRequested():
          emit(state.copyWith(activity: AuthActivity.google));
          final user = await repository.continueWithGoogle();
          if (!emit.isDone) {
            emit(AuthState(user: user, mode: state.mode));
          }
        case AuthEmailSubmitted(:final email, :final password):
          final emailError = AuthInput.emailError(email);
          final passwordError = AuthInput.passwordError(password);
          if (emailError != null || passwordError != null) {
            emit(
              state.copyWith(
                emailError: emailError,
                passwordError: passwordError,
                emailExpanded: true,
              ),
            );
            return;
          }
          emit(state.copyWith(activity: AuthActivity.email));
          final user = state.isSignUp
              ? await repository.createAccount(email, password)
              : await repository.signInWithEmail(email, password);
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
    } catch (_) {
      if (emit.isDone) {
        return;
      }
      emit(
        state.copyWith(
          activity: AuthActivity.idle,
          message: state.user == null
              ? 'Could not save this demo session. Please try again.'
              : 'Could not log out. Please try again.',
          noticeSerial: state.noticeSerial + 1,
        ),
      );
    }
  }
}
