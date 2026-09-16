enum AuthProvider { google, email }

/// Display/session metadata only. Never includes a password or OAuth token.
class AuthUser {
  const AuthUser({
    required this.email,
    required this.provider,
    this.uid,
  });
  final String email;
  final AuthProvider provider;
  final String? uid;

  String get id => uid ?? '${provider.name}:$email';

  Map<String, dynamic> toJson() => {
    'email': email,
    'provider': provider.name,
    if (uid != null) 'uid': uid,
  };

  factory AuthUser.fromJson(Map<String, dynamic> json) => AuthUser(
    email: json['email'] as String,
    provider: AuthProvider.values.byName(json['provider'] as String),
    uid: json['uid'] as String?,
  );
}
