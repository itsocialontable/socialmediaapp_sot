import 'dart:math';

import 'package:flutter/material.dart';

import '../../model/social_platform_model.dart';
import '../services/social_service.dart';

class SocialProvider extends ChangeNotifier {
  final SocialService _service;

  SocialProvider([SocialService? service]) : _service = service ?? SocialService();

  List<SocialPlatformModel> _platforms = SocialPlatformModel.supportedPlatforms;
  bool _isLoading = false;
  String? _errorMessage;
  String? _codeVerifier;
  final Map<String, bool> _actionLoading = {};

  List<SocialPlatformModel> get platforms => List.unmodifiable(_platforms);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  bool isPlatformLoading(String platform) => _actionLoading[platform] == true;

  Future<void> loadPlatforms() async {
    _setLoading(true);
    _errorMessage = null;

    try {
      final connectedAccounts = await _service.fetchConnectedAccounts();
      _platforms = SocialPlatformModel.supportedPlatforms.map((platform) {
        final account = connectedAccounts.firstWhere(
          (item) => item.platform == platform.platform,
          orElse: () => const SocialPlatformModel(
            platform: '',
            name: '',
            icon: Icons.public,
            color: Colors.transparent,
          ),
        );

        if (account.platform.isEmpty) {
          return platform;
        }

        return platform.copyWith(
          connected: true,
          accountId: account.accountId,
          connectedAs: account.connectedAs,
          statusMessage: account.statusMessage,
        );
      }).toList();
    } catch (error) {
      _errorMessage = error.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<String?> prepareAuthUrl(String platform) async {
    _setActionLoading(platform, true);
    _errorMessage = null;

    try {
      _codeVerifier = _createCodeVerifier();
      return await _service.fetchAuthorizationUrl(platform);
    } catch (error) {
      _errorMessage = error.toString();
      return null;
    } finally {
      _setActionLoading(platform, false);
    }
  }

  Future<bool> completeSocialConnect({
    required String platform,
    required String code,
    required String state,
  }) async {
    _setActionLoading(platform, true);
    _errorMessage = null;

    if (_codeVerifier == null) {
      _errorMessage = 'Missing PKCE verifier for OAuth flow.';
      _setActionLoading(platform, false);
      return false;
    }

    try {
      await _service.connectSocialPlatform(
        platform: platform,
        code: code,
        state: state,
        codeVerifier: _codeVerifier!,
      );
      await loadPlatforms();
      return true;
    } catch (error) {
      _errorMessage = error.toString();
      return false;
    } finally {
      _codeVerifier = null;
      _setActionLoading(platform, false);
    }
  }

  Future<bool> disconnectAccount({
    required String accountId,
    required String platform,
  }) async {
    _setActionLoading(platform, true);
    _errorMessage = null;

    try {
      await _service.disconnectSocialPlatform(accountId);
      await loadPlatforms();
      return true;
    } catch (error) {
      _errorMessage = error.toString();
      return false;
    } finally {
      _setActionLoading(platform, false);
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setActionLoading(String platform, bool value) {
    _actionLoading[platform] = value;
    notifyListeners();
  }

  String _createCodeVerifier() {
    const charset = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~';
    final random = Random.secure();
    return List.generate(64, (_) => charset[random.nextInt(charset.length)]).join();
  }
}
