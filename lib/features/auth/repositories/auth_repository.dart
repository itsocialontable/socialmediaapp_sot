import '../../../core/constants/app_constants.dart';
import '../../../core/network/api_service.dart';
import '../models/auth_models.dart';



class AuthRepository {
  final ApiService _apiService;

  AuthRepository({ApiService? apiService})
      : _apiService = apiService ?? ApiService();

  /// Admin login — POST /api/admin/login
  Future<AuthResponse> adminLogin({
    required String email,
    required String password,
  }) async {
    final request = AdminLoginRequest(email: email, password: password);
    final response = await _apiService.post(
      AppConstants.adminLogin,
      body: request.toJson(),
    );
    return AuthResponse.fromJson(response);
  }

  /// User login — POST /api/user/login
  Future<AuthResponse> userLogin({
    required String email,
    required String password,
    required String role,
  }) async {
    final request = UserLoginRequest(
      email: email,
      password: password,
      role: role,
    );
    final response = await _apiService.post(
      AppConstants.userLogin,
      body: request.toJson(),
    );
    return AuthResponse.fromJson(response);
  }
}
