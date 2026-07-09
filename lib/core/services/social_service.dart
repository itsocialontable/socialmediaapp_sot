import '../../model/social_platform_model.dart';
import '../constants/app_constants.dart';
import '../network/api_service.dart';

class SocialService {
  final ApiService _api;

  SocialService([ApiService? api]) : _api = api ?? ApiService();

  Future<String> fetchAuthorizationUrl(String platform) async {
    final body = await _api.get(
      '${AppConstants.socialAuth}/$platform',
    );

    if (body['success'] == true && body['url'] is String) {
      return body['url'] as String;
    }

    throw SocialApiException(
      body['msg']?.toString() ?? 'Failed to load OAuth URL',
    );
  }

  Future<void> connectSocialPlatform({
    required String platform,
    required String code,
    required String state,
    required String codeVerifier,
  }) async {
    final body = await _api.post(
      AppConstants.socialConnect,
      body: {
        'platform': platform,
        'code': code,
        'state': state,
        'codeVerifier': codeVerifier,
      },
    );

    if (body['success'] == true) return;

    throw SocialApiException(
      body['msg']?.toString() ?? 'Unable to connect social account',
    );
  }

  Future<void> disconnectSocialPlatform(String accountId) async {
    final body = await _api.post(
      '${AppConstants.socialDisconnect}/$accountId',
      body: {},
    );

    if (body['success'] == true) return;

    throw SocialApiException(
      body['message']?.toString() ?? 'Unable to disconnect social account',
    );
  }

  Future<List<SocialPlatformModel>> fetchConnectedAccounts() async {
    final body = await _api.get(AppConstants.socialAccount);

    final rawAccounts = _extractList(body);
    return rawAccounts
        .map((dynamic raw) {
      if (raw is Map<String, dynamic>) {
        return SocialPlatformModel.fromConnectedAccountJson(raw);
      }
      return SocialPlatformModel.fromConnectedAccountJson(
        Map<String, dynamic>.from(raw as Map),
      );
    })
        .where((account) => account.platform.isNotEmpty)
        .toList();
  }

  List<dynamic> _extractList(dynamic body) {
    if (body is List) return body;

    if (body is Map<String, dynamic>) {
      if (body['data'] is List) return body['data'] as List<dynamic>;
      if (body['accounts'] is List) return body['accounts'] as List<dynamic>;
    }

    return <dynamic>[];
  }
}

class SocialApiException implements Exception {
  final String message;
  SocialApiException(this.message);

  @override
  String toString() => message;
}