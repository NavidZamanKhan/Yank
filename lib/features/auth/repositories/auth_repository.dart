import '../models/auth_user.dart';

/// Replace the demo implementation with a real identity provider later.
abstract interface class AuthRepository {
  AuthUser? get currentUser;
  Future<AuthUser> continueWithGoogle();
  Future<AuthUser> signInWithEmail(String email, String password);
  Future<AuthUser> createAccount(String email, String password);
  Future<void> sendSignUpOtp(String email);
  Future<AuthUser> verifySignUpOtp({
    required String email,
    required String password,
    required String otp,
  });
  Future<void> signOut();
}
