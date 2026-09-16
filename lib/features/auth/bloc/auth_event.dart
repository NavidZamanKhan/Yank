enum AuthMode { signUp, logIn }

sealed class AuthEvent {
  const AuthEvent();
}

final class AuthModeChanged extends AuthEvent {
  const AuthModeChanged(this.mode);
  final AuthMode mode;
}

final class AuthEmailRevealed extends AuthEvent {
  const AuthEmailRevealed();
}

final class AuthErrorsCleared extends AuthEvent {
  const AuthErrorsCleared();
}

final class AuthGoogleRequested extends AuthEvent {
  const AuthGoogleRequested();
}

final class AuthEmailSubmitted extends AuthEvent {
  const AuthEmailSubmitted(this.email, this.password);
  final String email, password;
  // Credentials are deliberately excluded from string output and Equatable
  // props; no event logger should print either value.
  @override
  String toString() => 'AuthEmailSubmitted(credentials: redacted)';
}

final class AuthLogoutRequested extends AuthEvent {
  const AuthLogoutRequested();
}
