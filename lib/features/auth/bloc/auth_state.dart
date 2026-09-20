import 'package:equatable/equatable.dart';

import 'package:yank/features/auth/models/auth_user.dart';
import 'package:yank/features/auth/bloc/auth_event.dart';

enum AuthActivity { idle, google, email, otp, loggingOut }

class AuthState extends Equatable {
  const AuthState({
    this.user,
    this.mode = AuthMode.signUp,
    this.emailExpanded = false,
    this.activity = AuthActivity.idle,
    this.emailError,
    this.passwordError,
    this.confirmPasswordError,
    this.otpError,
    this.isVerifyingOtp = false,
    this.pendingEmail,
    this.pendingPassword,
    this.otpCooldownRemaining = 0,
    this.message,
    this.noticeSerial = 0,
  });
  final AuthUser? user;
  final AuthMode mode;
  final bool emailExpanded;
  final AuthActivity activity;
  final String? emailError;
  final String? passwordError;
  final String? confirmPasswordError;
  final String? otpError;
  final bool isVerifyingOtp;
  final String? pendingEmail;
  final String? pendingPassword;
  final int otpCooldownRemaining;
  final String? message;
  final int noticeSerial;

  bool get busy => activity != AuthActivity.idle;
  bool get isSignUp => mode == AuthMode.signUp;

  AuthState copyWith({
    AuthMode? mode,
    bool? emailExpanded,
    AuthActivity? activity,
    String? emailError,
    String? passwordError,
    String? confirmPasswordError,
    String? otpError,
    bool? isVerifyingOtp,
    String? pendingEmail,
    String? pendingPassword,
    int? otpCooldownRemaining,
    String? message,
    int? noticeSerial,
    bool clearErrors = false,
  }) => AuthState(
    user: user,
    mode: mode ?? this.mode,
    emailExpanded: emailExpanded ?? this.emailExpanded,
    activity: activity ?? this.activity,
    emailError: clearErrors ? null : (emailError ?? this.emailError),
    passwordError: clearErrors ? null : (passwordError ?? this.passwordError),
    confirmPasswordError: clearErrors
        ? null
        : (confirmPasswordError ?? this.confirmPasswordError),
    otpError: clearErrors ? null : (otpError ?? this.otpError),
    isVerifyingOtp: isVerifyingOtp ?? this.isVerifyingOtp,
    pendingEmail: pendingEmail ?? this.pendingEmail,
    pendingPassword: pendingPassword ?? this.pendingPassword,
    otpCooldownRemaining: otpCooldownRemaining ?? this.otpCooldownRemaining,
    message: clearErrors ? null : (message ?? this.message),
    noticeSerial: noticeSerial ?? this.noticeSerial,
  );

  @override
  List<Object?> get props => [
    user?.id,
    mode,
    emailExpanded,
    activity,
    emailError,
    passwordError,
    confirmPasswordError,
    otpError,
    isVerifyingOtp,
    pendingEmail,
    pendingPassword,
    otpCooldownRemaining,
    message,
    noticeSerial,
  ];
}
