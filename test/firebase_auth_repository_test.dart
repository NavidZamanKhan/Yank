import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:yank/features/auth/models/auth_failure.dart';
import 'package:yank/features/auth/repositories/firebase_auth_repository.dart';

void main() {
  group('FirebaseAuthRepository input validation', () {
    test('signInWithEmail rejects invalid email before network call', () async {
      final repository = FirebaseAuthRepository();
      expect(
        () => repository.signInWithEmail('notanemail', 'password123'),
        throwsA(
          isA<AuthFailure>().having(
            (e) => e.message,
            'message',
            'That email address does not look quite right.',
          ),
        ),
      );
    });

    test('signInWithEmail rejects short password before network call', () async {
      final repository = FirebaseAuthRepository();
      expect(
        () => repository.signInWithEmail('valid@example.com', 'short'),
        throwsA(
          isA<AuthFailure>().having(
            (e) => e.message,
            'message',
            'Use at least 8 characters.',
          ),
        ),
      );
    });

    test('createAccount rejects invalid email before network call', () async {
      final repository = FirebaseAuthRepository();
      expect(
        () => repository.createAccount('invalid-email', 'password123'),
        throwsA(
          isA<AuthFailure>().having(
            (e) => e.message,
            'message',
            'That email address does not look quite right.',
          ),
        ),
      );
    });

    test('verifySignUpOtp rejects non-6-digit OTP code', () async {
      final repository = FirebaseAuthRepository();
      expect(
        () => repository.verifySignUpOtp(
          email: 'valid@example.com',
          password: 'password123',
          otp: '12',
        ),
        throwsA(
          isA<AuthFailure>().having(
            (e) => e.message,
            'message',
            'Enter a valid 6-digit code.',
          ),
        ),
      );
    });

    test('continueWithGoogle handles user cancellation', () async {
      final repository = FirebaseAuthRepository(
        googleSignIn: _FakeGoogleSignIn(),
      );
      expect(
        () => repository.continueWithGoogle(),
        throwsA(
          isA<AuthFailure>().having(
            (e) => e.message,
            'message',
            'Google sign-in was cancelled.',
          ),
        ),
      );
    });
  });
}

class _FakeGoogleSignIn extends Fake implements GoogleSignIn {
  @override
  Future<GoogleSignInAccount?> signIn() async => null;
}
