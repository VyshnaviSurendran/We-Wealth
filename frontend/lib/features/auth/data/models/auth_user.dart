/// Mirrors the backend's `UserRead` schema exactly
/// (`backend/src/schemas/user.py`) — do not add fields that aren't there.
class AuthUser {
  const AuthUser({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.isActive,
  });

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      phone: json['phone'] as String?,
      isActive: json['is_active'] as bool,
    );
  }

  final String id;
  final String name;
  final String email;
  final String? phone;
  final bool isActive;
}
