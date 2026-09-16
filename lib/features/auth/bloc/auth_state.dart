import 'package:equatable/equatable.dart';

import '../models/auth_user.dart';
import 'auth_event.dart';

enum AuthActivity { idle, google, email, loggingOut }

class AuthState extends Equatable {
  const AuthState({
    this.user,
    this.mode = AuthMode.signUp,
    this.emailExpanded = false,
    this.activity = AuthActivity.idle,
    this.emailError,
    this.passwordError,
    this.message,
    this.noticeSerial = 0,
  });
  final AuthUser? user;
  final AuthMode mode;
  final bool emailExpanded;
  final AuthActivity activity;
  final String? emailError, passwordError, message;
  final int noticeSerial;
  bool get busy => activity != AuthActivity.idle;
  bool get isSignUp => mode == AuthMode.signUp;
  AuthState copyWith({
    AuthMode? mode,
    bool? emailExpanded,
    AuthActivity? activity,
    String? emailError,
    String? passwordError,
    String? message,
    int? noticeSerial,
  }) => AuthState(
    user: user,
    mode: mode ?? this.mode,
    emailExpanded: emailExpanded ?? this.emailExpanded,
    activity: activity ?? this.activity,
    emailError: emailError,
    passwordError: passwordError,
    message: message,
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
    message,
    noticeSerial,
  ];
}
