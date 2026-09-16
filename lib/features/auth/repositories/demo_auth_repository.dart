import 'dart:convert';

import '../../library/repositories/metadata_store.dart';
import '../models/auth_input.dart';
import '../models/auth_user.dart';
import 'auth_repository.dart';

/// A local navigation/session demo, explicitly not an authentication system.
/// Any valid email and 8–128 character sample password work in both modes.
/// Passwords are validated and discarded. Only email/provider are persisted.
class DemoAuthRepository implements AuthRepository {
  DemoAuthRepository._(this._store, this._currentUser);
  static const storageKey = 'yank.demo.session.v1';
  final MetadataStore _store;
  AuthUser? _currentUser;
  Future<void> _pending = Future.value();

  static Future<DemoAuthRepository> open(MetadataStore store) async {
    final saved = await store.read(storageKey);
    final decoded = saved == null ? null : jsonDecode(saved);
    final user = decoded == null
        ? null
        : AuthUser.fromJson(Map<String, dynamic>.from(decoded as Map));
    return DemoAuthRepository._(store, user);
  }

  @override
  AuthUser? get currentUser => _currentUser;

  Future<void> _commit(AuthUser? user) {
    final operation = _pending.then((_) async {
      await _store.write(storageKey, jsonEncode(user?.toJson()));
      _currentUser = user;
    });
    _pending = operation.then<void>(
      (_) {},
      onError: (Object _, StackTrace _) {},
    );
    return operation;
  }

  @override
  Future<AuthUser> continueWithGoogle() async {
    const user = AuthUser(
      email: 'you@yank.demo',
      provider: AuthProvider.google,
    );
    await _commit(user);
    return user;
  }

  Future<AuthUser> _emailSession(String email, String password) async {
    if (AuthInput.emailError(email) != null ||
        AuthInput.passwordError(password) != null) {
      // Never include the rejected credentials in an exception or log.
      throw const FormatException('Invalid demo credentials.');
    }
    final user = AuthUser(
      email: AuthInput.normalizeEmail(email),
      provider: AuthProvider.email,
    );
    await _commit(user);
    return user;
  }

  @override
  Future<AuthUser> signInWithEmail(String email, String password) =>
      _emailSession(email, password);
  @override
  Future<AuthUser> createAccount(String email, String password) =>
      _emailSession(email, password);
  @override
  Future<void> sendSignUpOtp(String email) async {
    if (AuthInput.emailError(email) != null) {
      throw const FormatException('Invalid email address for OTP.');
    }
    // Simulate short network delay in demo mode.
    await Future<void>.delayed(const Duration(milliseconds: 250));
  }

  @override
  Future<AuthUser> verifySignUpOtp({
    required String email,
    required String password,
    required String otp,
  }) async {
    if (AuthInput.otpError(otp) != null) {
      throw const FormatException('Invalid verification code.');
    }
    return _emailSession(email, password);
  }

  @override
  Future<void> signOut() => _commit(null);
}
