import '../../model/social_platform_model.dart';
import '../constants/app_constants.dart';
import '../network/api_service.dart';

class SocialService {
  final ApiService _api;

  SocialService([ApiService? api]) : _api = api ?? ApiService();

  Future<String> fetchAuthorizationUrl(
      String platform, {
        String? clientId,
        String? key,
      }) async {
    final body = await _api.get(
      '${AppConstants.socialAuth}/$platform',
      queryParams: _extraParams(clientId: clientId, key: key),
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
    String? clientId,
    String? key,
  }) async {
    final body = await _api.post(
      AppConstants.socialConnect,
      body: {
        'platform': platform,
        'code': code,
        'state': state,
        'codeVerifier': codeVerifier,
        if (clientId != null) 'clientId': clientId,
        if (key != null) 'key': key,
      },
    );

    if (body['success'] == true) return;

    throw SocialApiException(
      body['msg']?.toString() ?? 'Unable to connect social account',
    );
  }

  Future<void> disconnectSocialPlatform(
      String accountId, {
        String? clientId,
        String? key,
      }) async {
    final body = await _api.post(
      '${AppConstants.socialDisconnect}/$accountId',
      body: {
        if (clientId != null) 'clientId': clientId,
        if (key != null) 'key': key,
      },
    );

    if (body['success'] == true) return;

    throw SocialApiException(
      body['message']?.toString() ?? 'Unable to disconnect social account',
    );
  }

  Future<List<SocialPlatformModel>> fetchConnectedAccounts({
    String? clientId,
  }) async {
    final body = await _api.get(
      AppConstants.socialAccount,
      queryParams: clientId != null ? {'clientId': clientId} : null,
    );

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

  /// Fetches the SMM clients list (`/api/smm/clients`) and returns each
  /// client together with its platform-connection list, straight from the
  /// API — no local hardcoded platform data is used.
  Future<List<SmmClientModel>> fetchClients() async {
    final body = await _api.get(AppConstants.smmClients);

    final data = body['data'];
    final raw = (data is Map ? data['clients'] : null) ??
        body['clients'] ??
        (data is List ? data : null) ??
        <dynamic>[];

    final list = raw is List ? raw : <dynamic>[];
    return list
        .whereType<Object>()
        .map((e) => SmmClientModel.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Map<String, dynamic>? _extraParams({String? clientId, String? key}) {
    if (clientId == null && key == null) return null;
    return {
      if (clientId != null) 'clientId': clientId,
      if (key != null) 'key': key,
    };
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

/// A client returned by `/api/smm/clients`, along with the platforms shown
/// on its "Connect Accounts" card and the `key` needed to continue the
/// connect/disconnect flow for that client.
class SmmClientModel {
  final String id;
  final String name;
  final String? email;
  final String? key;
  final List<SocialPlatformModel> platforms;

  const SmmClientModel({
    required this.id,
    required this.name,
    this.email,
    this.key,
    required this.platforms,
  });

  factory SmmClientModel.fromJson(Map<String, dynamic> json) {
    final id = (json['_id'] ?? json['id'] ?? json['clientId'] ?? '').toString();
    final name = (json['name'] ?? json['fullName'] ?? json['full_name'] ?? json['username'] ?? 'Unknown').toString();
    final email = json['email']?.toString();
    final key = (json['key'] ?? json['apiKey'] ?? json['clientKey'] ?? json['accessKey'])?.toString();

    final rawPlatforms = json['platforms'] ??
        json['socialAccounts'] ??
        json['accounts'] ??
        json['channels'] ??
        json['connectedAccounts'] ??
        <dynamic>[];

    final list = rawPlatforms is List ? rawPlatforms : <dynamic>[];

    // The platform list shown for this client comes straight from the API
    // response — nothing hardcoded/static here.
    final platforms = list
        .whereType<Object>()
        .map((raw) => raw is Map
        ? SocialPlatformModel.fromConnectedAccountJson(Map<String, dynamic>.from(raw))
        : null)
        .whereType<SocialPlatformModel>()
        .toList();

    return SmmClientModel(id: id, name: name, email: email, key: key, platforms: platforms);
  }
}

class SocialApiException implements Exception {
  final String message;
  SocialApiException(this.message);

  @override
  String toString() => message;
}