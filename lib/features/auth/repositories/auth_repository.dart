import '../models/auth_user.dart';

abstract interface class AuthRepository {
  bool get isDemo;
  bool get requiresOtpVerification;
  AuthUser? get currentUser;
  Future<AuthUser> continueWithGoogle();
  Future<AuthUser> signInWithEmail(String email, String password);
  Future<AuthUser> createAccount(String email, String password);
  Future<void> sendPasswordReset(String email);
  Future<void> sendSignInLinkToEmail(String email);
  Future<AuthUser> signInWithEmailLink({
    required String email,
    required String emailLink,
  });
  Future<void> sendSignUpOtp(String email);
  Future<AuthUser> verifySignUpOtp({
    required String email,
    required String password,
    required String otp,
  });
  Future<void> signOut();
}
