import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../services/oauth_deep_link_service.dart';
import '../services/social_service.dart';

class SocialProvider extends ChangeNotifier {
  final SocialService _service;

  SocialProvider([SocialService? service]) : _service = service ?? SocialService();

  // ── Clients (driven entirely by /api/smm/clients — no local dummy data) ──
  List<SmmClientModel> _clients = [];
  bool _isLoading = false;
  String? _errorMessage;
  String? _codeVerifier;
  final Map<String, bool> _actionLoading = {};

  List<SmmClientModel> get clients => List.unmodifiable(_clients);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  bool isPlatformLoading(String clientId, String platform) =>
      _actionLoading['$clientId:$platform'] == true;

  Future<void> loadClients() async {
    _setLoading(true);
    _errorMessage = null;

    try {
      _clients = await _service.fetchClients();
    } catch (error) {
      _errorMessage = error.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<String?> prepareAuthUrl({
    required String clientId,
    required String platform,
    String? key,
  }) async {
    _setActionLoading(clientId, platform, true);
    _errorMessage = null;

    try {
      _codeVerifier = _createCodeVerifier();
      final authUrl = await _service.fetchAuthorizationUrl(
        platform,
        clientId: clientId,
        key: key,
      );

      // Persist BEFORE the browser opens — if Android kills this
      // process while the user is signing in, this is what lets
      // resumePendingConnectIfAny() finish the connect after restart.
      await OAuthDeepLinkService.instance.persistPendingFlow(
        clientId: clientId,
        platform: platform,
        codeVerifier: _codeVerifier!,
        key: key,
      );

      return authUrl;
    } catch (error) {
      _errorMessage = error.toString();
      return null;
    } finally {
      _setActionLoading(clientId, platform, false);
    }
  }

  Future<bool> completeSocialConnect({
    required String clientId,
    required String platform,
    required String code,
    required String state,
    String? key,
  }) async {
    _setActionLoading(clientId, platform, true);
    _errorMessage = null;

    if (_codeVerifier == null) {
      _errorMessage = 'Missing PKCE verifier for OAuth flow.';
      _setActionLoading(clientId, platform, false);
      return false;
    }

    try {
      await _service.connectSocialPlatform(
        platform: platform,
        code: code,
        state: state,
        codeVerifier: _codeVerifier!,
        clientId: clientId,
        key: key,
      );
      await loadClients();
      return true;
    } catch (error) {
      _errorMessage = error.toString();
      return false;
    } finally {
      _codeVerifier = null;
      _setActionLoading(clientId, platform, false);
      // The flow is done one way or another — drop any persisted state
      // for it so a later cold-start doesn't try to replay it.
      unawaited(OAuthDeepLinkService.instance.clearPendingFlow());
    }
  }

  /// Resumes a connect flow that completed its OAuth redirect while the
  /// app was cold-starting (Android killed the process mid-flow — see
  /// OAuthDeepLinkService for the full explanation). Call this once at
  /// app startup, after the widget tree is up. Returns true if a
  /// pending flow was found and successfully completed.
  Future<bool> resumePendingConnectIfAny() async {
    final pending = await OAuthDeepLinkService.instance.takePersistedCallback();
    if (pending == null) return false;

    final clientId = pending['clientId']!;
    final platform = pending['platform']!;

    _setActionLoading(clientId, platform, true);
    _errorMessage = null;

    try {
      await _service.connectSocialPlatform(
        platform: platform,
        code: pending['code']!,
        state: pending['state']!,
        codeVerifier: pending['codeVerifier']!,
        clientId: clientId,
        key: pending['key'],
      );
      await loadClients();
      return true;
    } catch (error) {
      _errorMessage = error.toString();
      return false;
    } finally {
      _setActionLoading(clientId, platform, false);
    }
  }

  Future<bool> disconnectAccount({
    required String clientId,
    required String accountId,
    required String platform,
    String? key,
  }) async {
    _setActionLoading(clientId, platform, true);
    _errorMessage = null;

    try {
      await _service.disconnectSocialPlatform(
        accountId,
        clientId: clientId,
        key: key,
      );
      await loadClients();
      return true;
    } catch (error) {
      _errorMessage = error.toString();
      return false;
    } finally {
      _setActionLoading(clientId, platform, false);
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setActionLoading(String clientId, String platform, bool value) {
    _actionLoading['$clientId:$platform'] = value;
    notifyListeners();
  }

  String _createCodeVerifier() {
    const charset = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~';
    final random = Random.secure();
    return List.generate(64, (_) => charset[random.nextInt(charset.length)]).join();
  }
}