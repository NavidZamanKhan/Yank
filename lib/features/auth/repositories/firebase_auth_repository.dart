import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:google_sign_in/google_sign_in.dart';

import '../models/auth_failure.dart';
import '../models/auth_input.dart';
import '../models/auth_user.dart';
import 'auth_repository.dart';

class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuthRepository({
    fb.FirebaseAuth? auth,
    GoogleSignIn? googleSignIn,
  })  : _authOverride = auth,
        _googleSignInOverride = googleSignIn;

  final fb.FirebaseAuth? _authOverride;
  final GoogleSignIn? _googleSignInOverride;

  fb.FirebaseAuth get _auth => _authOverride ?? fb.FirebaseAuth.instance;
  GoogleSignIn get _googleSignIn => _googleSignInOverride ?? GoogleSignIn();

  @override
  AuthUser? get currentUser {
    final user = _auth.currentUser;
    if (user == null || user.email == null) {
      return null;
    }
    final isGoogle = user.providerData.any(
      (p) => p.providerId == 'google.com',
    );
    return AuthUser(
      email: user.email!,
      provider: isGoogle ? AuthProvider.google : AuthProvider.email,
      uid: user.uid,
    );
  }

  @override
  Future<AuthUser> continueWithGoogle() async {
    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        throw const AuthFailure('Google sign-in was cancelled.');
      }
      final googleAuth = await googleUser.authentication;
      final credential = fb.GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      final userCredential = await _auth.signInWithCredential(credential);
      final user = userCredential.user;
      if (user == null || user.email == null) {
        throw const AuthFailure('Failed to retrieve user from Google sign-in.');
      }
      return AuthUser(
        email: user.email!,
        provider: AuthProvider.google,
        uid: user.uid,
      );
    } on fb.FirebaseAuthException catch (e) {
      throw _mapFirebaseAuthException(e);
    } catch (e) {
      if (e is AuthFailure) rethrow;
      throw AuthFailure('Google sign-in error: $e');
    }
  }

  @override
  Future<AuthUser> signInWithEmail(String email, String password) async {
    final emailError = AuthInput.emailError(email);
    final passwordError = AuthInput.passwordError(password);
    if (emailError != null || passwordError != null) {
      throw AuthFailure(emailError ?? passwordError!);
    }

    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: AuthInput.normalizeEmail(email),
        password: password,
      );
      final user = credential.user;
      if (user == null || user.email == null) {
        throw const AuthFailure('Failed to retrieve user session.');
      }
      return AuthUser(
        email: user.email!,
        provider: AuthProvider.email,
        uid: user.uid,
      );
    } on fb.FirebaseAuthException catch (e) {
      throw _mapFirebaseAuthException(e);
    }
  }

  @override
  Future<AuthUser> createAccount(String email, String password) async {
    final emailError = AuthInput.emailError(email);
    final passwordError = AuthInput.passwordError(password);
    if (emailError != null || passwordError != null) {
      throw AuthFailure(emailError ?? passwordError!);
    }

    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: AuthInput.normalizeEmail(email),
        password: password,
      );
      final user = credential.user;
      if (user == null || user.email == null) {
        throw const AuthFailure('Failed to create user session.');
      }
      return AuthUser(
        email: user.email!,
        provider: AuthProvider.email,
        uid: user.uid,
      );
    } on fb.FirebaseAuthException catch (e) {
      throw _mapFirebaseAuthException(e);
    }
  }

  @override
  Future<void> sendSignUpOtp(String email) async {
    final emailError = AuthInput.emailError(email);
    if (emailError != null) {
      throw AuthFailure(emailError);
    }
    // Simulate short network delay for OTP dispatch.
    await Future<void>.delayed(const Duration(milliseconds: 300));
  }

  @override
  Future<AuthUser> verifySignUpOtp({
    required String email,
    required String password,
    required String otp,
  }) async {
    final otpError = AuthInput.otpError(otp);
    if (otpError != null) {
      throw AuthFailure(otpError);
    }
    // Create the real account in Firebase upon OTP verification.
    return createAccount(email, password);
  }

  @override
  Future<void> signOut() async {
    try {
      await Future.wait([
        _auth.signOut(),
        _googleSignIn.signOut(),
      ]);
    } on fb.FirebaseAuthException catch (e) {
      throw _mapFirebaseAuthException(e);
    } catch (_) {
      // Ignore Google sign-out failures if already signed out
    }
  }

  static AuthFailure _mapFirebaseAuthException(fb.FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return const AuthFailure(
          'No account found with this email. Please check your email or sign up.',
        );
      case 'wrong-password':
      case 'invalid-credential':
        return const AuthFailure(
          'Incorrect email or password. Please try again.',
        );
      case 'email-already-in-use':
        return const AuthFailure(
          'This email is already in use. Please log in instead.',
        );
      case 'weak-password':
        return const AuthFailure(
          'Password is too weak. Please use a stronger password.',
        );
      case 'invalid-email':
        return const AuthFailure('That email address is not valid.');
      case 'user-disabled':
        return const AuthFailure('This account has been disabled.');
      case 'too-many-requests':
        return const AuthFailure(
          'Too many failed attempts. Please try again later.',
        );
      case 'network-request-failed':
        return const AuthFailure(
          'Network error. Please check your internet connection.',
        );
      case 'operation-not-allowed':
        return const AuthFailure(
          'Email/password sign-in is not enabled in the Firebase Console.',
        );
      default:
        return AuthFailure(e.message ?? 'Authentication failed.');
    }
  }
}
