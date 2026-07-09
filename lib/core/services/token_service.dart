import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../constants/app_constants.dart';

class TokenService {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  // ─── Token ────────────────────────────────────────────────────
  static Future<void> saveToken(String token) =>
      _storage.write(key: AppConstants.tokenKey, value: token);

  static Future<String?> getToken() =>
      _storage.read(key: AppConstants.tokenKey);

  static Future<void> deleteToken() =>
      _storage.delete(key: AppConstants.tokenKey);

  // ─── Session ──────────────────────────────────────────────────
  static Future<void> saveSession({
    required String token,
    required String role,
    required String accountType,
    required String email,
    required String name,
    String? profileImage,
  }) async {
    await Future.wait([
      _storage.write(key: AppConstants.tokenKey, value: token),
      _storage.write(key: AppConstants.userRoleKey, value: role),
      _storage.write(key: AppConstants.accountTypeKey, value: accountType),
      _storage.write(key: AppConstants.userEmailKey, value: email),
      _storage.write(key: AppConstants.userNameKey, value: name),
      _storage.write(key: AppConstants.profileImageKey, value: profileImage ?? ''),
    ]);
  }

  static Future<Map<String, String?>> getSession() async {
    final results = await Future.wait([
      _storage.read(key: AppConstants.tokenKey),
      _storage.read(key: AppConstants.userRoleKey),
      _storage.read(key: AppConstants.accountTypeKey),
      _storage.read(key: AppConstants.userEmailKey),
      _storage.read(key: AppConstants.userNameKey),
      _storage.read(key: AppConstants.profileImageKey),
    ]);
    return {
      AppConstants.tokenKey: results[0],
      AppConstants.userRoleKey: results[1],
      AppConstants.accountTypeKey: results[2],
      AppConstants.userEmailKey: results[3],
      AppConstants.userNameKey: results[4],
      AppConstants.profileImageKey: results[5],
    };
  }

  static Future<void> clearAll() => _storage.deleteAll();

  static Future<bool> hasToken() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }
}