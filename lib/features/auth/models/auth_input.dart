/// The deliberately small input contract for the UI prototype. This is not a
/// password policy or a substitute for authentication at a real server.
abstract final class AuthInput {
  static String normalizeEmail(String email) => email.trim().toLowerCase();
  static String? emailError(String email) {
    final value = normalizeEmail(email);
    if (value.isEmpty) {
      return 'Enter your email address.';
    }
    if (value.length > 254 ||
        !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value)) {
      return 'That email address does not look quite right.';
    }
    return null;
  }

  static String? passwordError(String password) {
    if (password.isEmpty) {
      return 'Enter a sample password.';
    }
    if (password.trim().isEmpty || password.length < 8) {
      return 'Use at least 8 characters.';
    }
    if (password.length > 128) {
      return 'Keep it under 129 characters.';
    }
    return null;
  }

  static String? confirmPasswordError(String password, String confirmPassword) {
    if (confirmPassword.isEmpty) {
      return 'Confirm your password.';
    }
    if (password != confirmPassword) {
      return 'Passwords do not match.';
    }
    return null;
  }

  static String? otpError(String otp) {
    final clean = otp.trim();
    if (clean.isEmpty) {
      return 'Enter the 6-digit code.';
    }
    if (clean.length != 6 || !RegExp(r'^\d{6}$').hasMatch(clean)) {
      return 'Enter a valid 6-digit code.';
    }
    return null;
  }
}
