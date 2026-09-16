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
  const AuthEmailSubmitted(
    this.email,
    this.password, {
    this.confirmPassword,
  });
  final String email, password;
  final String? confirmPassword;
  // Credentials are deliberately excluded from string output and Equatable
  // props; no event logger should print either value.
  @override
  String toString() => 'AuthEmailSubmitted(credentials: redacted)';
}

final class AuthOtpSubmitted extends AuthEvent {
  const AuthOtpSubmitted(this.otp);
  final String otp;
  @override
  String toString() => 'AuthOtpSubmitted(otp: redacted)';
}

final class AuthOtpResendRequested extends AuthEvent {
  const AuthOtpResendRequested();
}

final class AuthOtpBackRequested extends AuthEvent {
  const AuthOtpBackRequested();
}

final class AuthOtpCooldownTicked extends AuthEvent {
  const AuthOtpCooldownTicked(this.secondsRemaining);
  final int secondsRemaining;
}

final class AuthPasswordResetRequested extends AuthEvent {
  const AuthPasswordResetRequested(this.email);
  final String email;
}

final class AuthEmailLinkRequested extends AuthEvent {
  const AuthEmailLinkRequested(this.email);
  final String email;
}

final class AuthEmailLinkVerified extends AuthEvent {
  const AuthEmailLinkVerified({
    required this.email,
    required this.emailLink,
  });
  final String email;
  final String emailLink;
}

final class AuthLogoutRequested extends AuthEvent {
  const AuthLogoutRequested();
}
