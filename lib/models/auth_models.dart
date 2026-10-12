// MARK: - Auth & User Data Models
class UserProfile {
  final String id;
  final String email;
  final String? name;
  final String? role;

  UserProfile({
    required this.id,
    required this.email,
    this.name,
    this.role,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
        id: json['id'] as String,
        email: json['email'] as String,
        name: json['name'] as String?,
        role: json['role'] as String?,
      );
}

class AuthResponse {
  final String accessToken;
  final String refreshToken;
  final UserProfile user;
  final String? language;

  AuthResponse({
    required this.accessToken,
    required this.refreshToken,
    required this.user,
    this.language,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    final tokens = json['tokens'] as Map<String, dynamic>;
    return AuthResponse(
      accessToken: tokens['accessToken'] as String,
      refreshToken: tokens['refreshToken'] as String,
      user: UserProfile.fromJson(json['user'] as Map<String, dynamic>),
      language: (json['onboarding'] is Map)
          ? (json['onboarding'] as Map)['language'] as String?
          : null,
    );
  }
}
