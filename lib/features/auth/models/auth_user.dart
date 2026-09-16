enum AuthProvider { google, email }

/// Display/session metadata only. Never includes a password or OAuth token.
class AuthUser {
  const AuthUser({required this.email, required this.provider});
  final String email;
  final AuthProvider provider;
  String get id => '${provider.name}:$email';
  Map<String, dynamic> toJson() => {'email': email, 'provider': provider.name};
  factory AuthUser.fromJson(Map<String, dynamic> json) => AuthUser(
    email: json['email'] as String,
    provider: AuthProvider.values.byName(json['provider'] as String),
  );
}
