import 'package:flutter/material.dart';
import '../errors/api_response.dart';
import '../errors/app_exceptions.dart';
import '../network/dio_client.dart';
import '../services/token_service.dart';
import '../constants/app_constants.dart';
import '../../features/auth/repositories/auth_repository.dart';
import '../../features/auth/models/auth_models.dart';

enum UserRole { admin, graphicDesigner, smm, client }
enum AccountType { admin, user }

extension UserRoleExt on UserRole {
  String get apiValue {
    switch (this) {
      case UserRole.graphicDesigner:
        return 'Graphic Designer';
      case UserRole.smm:
        return 'SMM';
      case UserRole.client:
        return 'Client';
      case UserRole.admin:
        return 'Admin';
    }
  }
}

UserRole? userRoleFromString(String? value) {
  switch (value?.toLowerCase()) {
    case 'admin': return UserRole.admin;
    case 'graphicdesigner': return UserRole.graphicDesigner;
    case 'smm': return UserRole.smm;
    case 'client': return UserRole.client;
    default: return null;
  }
}

class AuthProvider extends ChangeNotifier {
  final AuthRepository _repository;

  AuthProvider({AuthRepository? repository})
      : _repository = repository ?? AuthRepository();

  // ─── State ───────────────────────────────────────
  UserRole? _userRole;
  AccountType? _accountType;
  bool _isLoggedIn = false;
  String _userName = '';
  String _userEmail = '';
  String? _profileImageUrl;

  ApiResponse<AuthResponse> _adminLoginState = ApiResponse.idle();
  ApiResponse<AuthResponse> _userLoginState = ApiResponse.idle();

  // ─── Getters ─────────────────────────────────────
  UserRole? get userRole => _userRole;
  AccountType? get accountType => _accountType;
  bool get isLoggedIn => _isLoggedIn;
  String get userName => _userName;
  String get userEmail => _userEmail;
  String? get profileImageUrl => _profileImageUrl;
  ApiResponse<AuthResponse> get adminLoginState => _adminLoginState;
  ApiResponse<AuthResponse> get userLoginState => _userLoginState;
  bool get isAdminLoading => _adminLoginState.isLoading;
  bool get isUserLoading => _userLoginState.isLoading;

  void setAccountType(AccountType type) { _accountType = type; notifyListeners(); }
  void setUserRole(UserRole role) { _userRole = role; notifyListeners(); }

  // ─── Admin Login ──────────────────────────────────
  Future<bool> loginAdmin(String email, String password) async {
    _adminLoginState = ApiResponse.loading();
    notifyListeners();
    try {
      final response = await _repository.adminLogin(email: email.trim(), password: password);
      if (response.token == null || response.token!.isEmpty) {
        throw ServerException('Token not received from server');
      }

      await TokenService.saveSession(
        token: response.token ?? '',
        role: UserRole.admin.apiValue,
        accountType: AccountType.admin.name,
        email: email.trim(),
        name: response.user?.name ?? 'Admin',
        profileImage: response.user?.profileImage,
      );
      DioClient.reset();
      _isLoggedIn = true;
      _accountType = AccountType.admin;
      _userRole = UserRole.admin;
      _userEmail = email.trim();
      _userName = response.user?.name ?? 'Admin';
      _profileImageUrl = response.user?.profileImage;
      _adminLoginState = ApiResponse.success(response, message: response.message ?? 'Login successful');
      notifyListeners();
      return true;
    } on AppException catch (e) {
      _adminLoginState = ApiResponse.error(e.message, statusCode: e.statusCode);
      notifyListeners();
      return false;
    } catch (e) {
      _adminLoginState = ApiResponse.error('An unexpected error occurred. Please try again.');
      notifyListeners();
      return false;
    }
  }

  // ─── User Login ───────────────────────────────────
  Future<bool> loginUser(String email, String password, UserRole role) async {
    _userLoginState = ApiResponse.loading();
    notifyListeners();
    try {
      final response = await _repository.userLogin(
        email: email.trim(),
        password: password,
        role: role.apiValue,
      );
      if (response.token == null || response.token!.isEmpty) {
        throw ServerException('Token not received from server');
      }
      await TokenService.saveSession(
        token: response.token ?? '',
        role: role.apiValue,
        accountType: AccountType.user.name,
        email: email.trim(),
        name: response.user?.name ?? _defaultName(role),
        profileImage: response.user?.profileImage,
      );
      DioClient.reset();
      _isLoggedIn = true;
      _accountType = AccountType.user;
      _userRole = role;
      _userEmail = email.trim();
      _userName = response.user?.name ?? _defaultName(role);
      _profileImageUrl = response.user?.profileImage;
      _userLoginState = ApiResponse.success(response, message: response.message ?? 'Login successful');
      notifyListeners();
      return true;
    } on AppException catch (e) {
      _userLoginState = ApiResponse.error(e.message, statusCode: e.statusCode);
      notifyListeners();
      return false;
    } catch (e) {
      _userLoginState = ApiResponse.error('An unexpected error occurred. Please try again.');
      notifyListeners();
      return false;
    }
  }

  // ─── Restore session ──────────────────────────────
  Future<bool> tryRestoreSession() async {
    final session = await TokenService.getSession();
    final token = session[AppConstants.tokenKey];
    if (token == null || token.isEmpty) return false;
    _userRole = userRoleFromString(session['user_role']);
    _accountType = session['account_type'] == 'admin' ? AccountType.admin : AccountType.user;
    _userEmail = session['user_email'] ?? '';
    _userName = session['user_name'] ?? '';
    final img = session[AppConstants.profileImageKey] ?? '';
    _profileImageUrl = img.isNotEmpty ? img : null;
    _isLoggedIn = true;
    notifyListeners();
    return true;
  }

  // ─── Logout ───────────────────────────────────────
  Future<void> logout() async {
    await TokenService.clearAll();
    DioClient.reset();
    _isLoggedIn = false;
    _userRole = null;
    _accountType = null;
    _userName = '';
    _userEmail = '';
    _profileImageUrl = null;
    _adminLoginState = ApiResponse.idle();
    _userLoginState = ApiResponse.idle();
    notifyListeners();
  }

  void resetAdminLoginState() { _adminLoginState = ApiResponse.idle(); notifyListeners(); }
  void resetUserLoginState() { _userLoginState = ApiResponse.idle(); notifyListeners(); }

  // ─── Update user info locally ─────────────────────────
  Future<void> updateUserInfo({String? name, String? email, String? profileImage}) async {
    if (name != null) _userName = name;
    if (email != null) _userEmail = email;
    if (profileImage != null) _profileImageUrl = profileImage.isNotEmpty ? profileImage : null;
    final session = await TokenService.getSession();
    await TokenService.saveSession(
      token: session[AppConstants.tokenKey] ?? '',
      role: session['user_role'] ?? '',
      accountType: session['account_type'] ?? '',
      email: email ?? _userEmail,
      name: name ?? _userName,
      profileImage: profileImage ?? _profileImageUrl,
    );
    notifyListeners();
  }

  // ─── Update profile image URL ─────────────────────────
  Future<void> setProfileImageUrl(String? url) async {
    _profileImageUrl = (url != null && url.isNotEmpty) ? url : null;
    final session = await TokenService.getSession();
    await TokenService.saveSession(
      token: session[AppConstants.tokenKey] ?? '',
      role: session['user_role'] ?? '',
      accountType: session['account_type'] ?? '',
      email: _userEmail,
      name: _userName,
      profileImage: url,
    );
    notifyListeners();
  }

  String get dashboardRoute {
    switch (_userRole) {
      case UserRole.admin: return '/dashboard/admin';
      case UserRole.graphicDesigner: return '/dashboard/designer';
      case UserRole.smm: return '/dashboard/smm';
      case UserRole.client: return '/dashboard/client';
      default: return '/welcome';
    }
  }

  String _defaultName(UserRole role) {
    switch (role) {
      case UserRole.graphicDesigner: return 'Designer';
      case UserRole.smm: return 'SMM Manager';
      case UserRole.client: return 'Client';
      default: return 'User';
    }
  }
}