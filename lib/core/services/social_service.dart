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
      // `source: app` tells the backend this request came from the mobile
      // app (not the website), so /auth/callback knows to redirect to the
      // smmapp://oauth-callback deep link instead of the normal website
      // callback page.
      queryParams: _extraParams(clientId: clientId, key: key, source: 'app'),
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
    final body = await _api.delete(
      '${AppConstants.socialDisconnect}/$accountId',
      // body: {
      //   if (clientId != null) 'clientId': clientId,
      //   if (key != null) 'key': key,
      // },
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
    final clients = list
        .whereType<Object>()
        .map((e) => SmmClientModel.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();

    // `/api/smm/clients` only gives back platform *names* (no connection
    // status), so on its own every platform looks "not connected" and the
    // Disconnect action never appears — even right after a successful
    // connect. To fix that, pull the real connection state per client from
    // `/api/smm/account` and merge it into that client's platform list.
    await Future.wait(clients.map((client) async {
      try {
        final connectedAccounts = await fetchConnectedAccounts(clientId: client.id);
        client.mergeConnectedAccounts(connectedAccounts);
      } catch (_) {
        // Don't let one client's enrichment failure break the whole list —
        // that client's platforms simply stay at their current state.
      }
    }));

    return clients;
  }

  Map<String, dynamic>? _extraParams({String? clientId, String? key, String? source}) {
    if (clientId == null && key == null && source == null) return null;
    return {
      if (clientId != null) 'clientId': clientId,
      if (key != null) 'key': key,
      if (source != null) 'source': source,
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
    //
    // Two shapes are supported, since /api/smm/clients returns platforms as
    // plain strings (e.g. ["YouTube", "Instagram", "Facebook"]) while other
    // endpoints (e.g. /api/smm/account) return connection objects
    // (e.g. [{"platform": "youtube", "connected": true, ...}]).
    final platforms = list
        .whereType<Object>()
        .map((raw) {
      if (raw is Map) {
        return SocialPlatformModel.fromConnectedAccountJson(Map<String, dynamic>.from(raw));
      }
      if (raw is String && raw.trim().isNotEmpty) {
        return SocialPlatformModel.fromPlatformName(raw.trim());
      }
      return null;
    })
        .whereType<SocialPlatformModel>()
        .toList();

    return SmmClientModel(id: id, name: name, email: email, key: key, platforms: platforms);
  }

  /// Overlays real connection data (from `/api/smm/account`) onto this
  /// client's platform list (which, when it came from `/api/smm/clients`,
  /// may only be bare platform names with `connected: false`). Matching is
  /// done by platform key (e.g. "instagram"), and each match replaces the
  /// placeholder entry with the fully connected one (accountId,
  /// connectedAs, connected: true, etc.) so the UI shows the correct
  /// "Connected" state and the Disconnect action.
  void mergeConnectedAccounts(List<SocialPlatformModel> connectedAccounts) {
    if (connectedAccounts.isEmpty) return;

    final byPlatform = <String, SocialPlatformModel>{
      for (final account in connectedAccounts) account.platform: account,
    };

    for (var i = 0; i < platforms.length; i++) {
      final match = byPlatform[platforms[i].platform];
      if (match != null) {
        platforms[i] = match;
      }
    }
  }
}

class SocialApiException implements Exception {
  final String message;
  SocialApiException(this.message);

  @override
  String toString() => message;
}