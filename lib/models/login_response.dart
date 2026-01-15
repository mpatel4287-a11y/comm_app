// lib/models/login_response.dart

class LoginResponse {
  final bool success;
  final String message;
  final bool isAdmin;
  final String? role;

  LoginResponse({
    required this.success,
    required this.message,
    required this.isAdmin,
    this.role,
  });
}
