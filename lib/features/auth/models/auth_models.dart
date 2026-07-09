// ─── Admin Login Request ──────────────────────────────────────────────────────
class AdminLoginRequest {
  final String email;
  final String password;

  const AdminLoginRequest({
    required this.email,
    required this.password,
  });

  Map<String, dynamic> toJson() => {
        'email': email,
        'password': password,
      };
}

// ─── User Login Request ───────────────────────────────────────────────────────
class UserLoginRequest {
  final String email;
  final String password;
  final String role;

  const UserLoginRequest({
    required this.email,
    required this.password,
    required this.role,
  });

  Map<String, dynamic> toJson() => {
        'email': email,
        'password': password,
        'role': role,
      };
}

// ─── Auth Response ────────────────────────────────────────────────────────────
class AuthResponse {
  final String? token;
  final String? message;
  final UserData? user;

  const AuthResponse({
    this.token,
    this.message,
    this.user,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    // Handle various token key patterns from API
    final token = json['token'] ??
        json['access_token'] ??
        json['accessToken'] ??
        json['data']?['token'] ??
        json['data']?['access_token'];

    final message = json['message'] ?? json['msg'];

    UserData? user;
    final userData = json['user'] ?? json['data']?['user'] ?? json['data'];
    if (userData is Map<String, dynamic>) {
      user = UserData.fromJson(userData);
    }

    return AuthResponse(
      token: token?.toString(),
      message: message?.toString(),
      user: user,
    );
  }
}

// ─── User Data ────────────────────────────────────────────────────────────────
class UserData {
  final String? id;
  final String? name;
  final String? email;
  final String? role;
  final String? profileImage;

  const UserData({
    this.id,
    this.name,
    this.email,
    this.role,
    this.profileImage,
  });

  factory UserData.fromJson(Map<String, dynamic> json) {
    return UserData(
      id: json['id']?.toString() ?? json['_id']?.toString(),
      name: json['name']?.toString() ?? json['username']?.toString(),
      email: json['email']?.toString(),
      role: json['role']?.toString(),
      profileImage: json['profileImage']?.toString(),
    );
  }
}
