import 'dart:math';

import 'package:flutter/material.dart';

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
      return await _service.fetchAuthorizationUrl(
        platform,
        clientId: clientId,
        key: key,
      );
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