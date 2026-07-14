import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:url_launcher/url_launcher.dart';

/// Handles the OAuth "connect account" flow using the SYSTEM BROWSER
/// (Chrome Custom Tabs / SFSafariViewController) instead of an in-app
/// WebView.
///
/// WHY: Google blocks sign-in requests coming from embedded WebViews
/// ("Error 403: disallowed_useragent"). This is a Google security policy,
/// not something that can be worked around from inside a WebView — the
/// only supported fix is to launch the auth URL externally and receive
/// the result back via a deep link.
///
/// FLOW:
/// 1. App opens `authUrl` with `launchUrl(..., mode: LaunchMode.externalApplication)`.
/// 2. User completes sign-in in the real browser.
/// 3. Backend's /auth/callback (after exchanging nothing — it just has
///    the `code`/`state` from Google) 302-redirects the browser to a
///    custom URL scheme, e.g.:
///       smmapp://oauth-callback?code=...&state=...
/// 4. The OS hands that URL back to this app, `app_links` picks it up,
///    and we resolve the pending Future with the code/state.
class OAuthDeepLinkService {
  OAuthDeepLinkService._internal();
  static final OAuthDeepLinkService instance = OAuthDeepLinkService._internal();

  /// Must match the custom scheme registered in AndroidManifest.xml /
  /// Info.plist (see setup notes).
  static const String callbackScheme = 'smmapp';
  static const String callbackHost = 'oauth-callback';

  final AppLinks _appLinks = AppLinks();
  StreamSubscription<Uri>? _sub;
  Completer<Map<String, String?>?>? _pendingCompleter;

  // ── Persisted flow state ──────────────────────────────────────────────
  // WHY THIS EXISTS: Android can (and often does, especially on the
  // FIRST connect attempt, when the Google consent screen has extra
  // steps) kill the app process entirely while the user is in the
  // browser. When that happens, the deep link comes back to a freshly
  // cold-started app: `_pendingCompleter` above is null again because
  // this whole object was just re-constructed. Without persisting
  // somewhere durable, the code/state from Google would silently be
  // dropped and the account would never actually get connected — which
  // is exactly the "first time nothing happens, second time it works"
  // symptom, since the second attempt happens while the app is already
  // warm in memory.
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );
  static const _kPendingClientId = 'oauth_pending_client_id';
  static const _kPendingPlatform = 'oauth_pending_platform';
  static const _kPendingKey = 'oauth_pending_key';
  static const _kPendingCodeVerifier = 'oauth_pending_code_verifier';
  static const _kCallbackCode = 'oauth_callback_code';
  static const _kCallbackState = 'oauth_callback_state';

  /// Call this once, early in app startup (e.g. in main.dart), so the
  /// listener is alive even if a link arrives while the app is
  /// backgrounded / cold-started from the browser.
  void init() {
    _sub ??= _appLinks.uriLinkStream.listen(_handleIncomingUri, onError: (_) {});

    // Explicitly check the link that may have cold-started this process.
    // uriLinkStream isn't guaranteed to replay it before this listener is
    // attached, so this covers the exact "app restarted" scenario.
    _appLinks.getInitialLink().then((uri) {
      if (uri != null) _handleIncomingUri(uri);
    }).catchError((_) {});
  }

  void dispose() {
    _sub?.cancel();
    _sub = null;
  }

  /// Call right before/while launching the browser so the flow can be
  /// resumed even if Android kills the app process mid-flow.
  Future<void> persistPendingFlow({
    required String clientId,
    required String platform,
    required String codeVerifier,
    String? key,
  }) async {
    await Future.wait([
      _storage.write(key: _kPendingClientId, value: clientId),
      _storage.write(key: _kPendingPlatform, value: platform),
      _storage.write(key: _kPendingCodeVerifier, value: codeVerifier),
      _storage.write(key: _kPendingKey, value: key ?? ''),
    ]);
  }

  Future<void> _persistCallback({required String code, required String state}) async {
    await Future.wait([
      _storage.write(key: _kCallbackCode, value: code),
      _storage.write(key: _kCallbackState, value: state),
    ]);
  }

  /// If a callback arrived while the app was cold-starting (see
  /// `_handleIncomingUri` below), this returns everything needed to
  /// finish that connect flow — the code/state from Google plus the
  /// clientId/platform/key/codeVerifier that were persisted before the
  /// browser was launched. Clears all of it from storage once read, so
  /// it's only ever consumed once. Returns null if there's nothing
  /// pending (the normal, warm-app case).
  Future<Map<String, String>?> takePersistedCallback() async {
    final code = await _storage.read(key: _kCallbackCode);
    final state = await _storage.read(key: _kCallbackState);
    final clientId = await _storage.read(key: _kPendingClientId);
    final platform = await _storage.read(key: _kPendingPlatform);
    final codeVerifier = await _storage.read(key: _kPendingCodeVerifier);
    final key = await _storage.read(key: _kPendingKey);

    await clearPendingFlow();

    if (code == null || state == null || clientId == null || platform == null || codeVerifier == null) {
      return null;
    }

    return {
      'code': code,
      'state': state,
      'clientId': clientId,
      'platform': platform,
      'codeVerifier': codeVerifier,
      if (key != null && key.isNotEmpty) 'key': key,
    };
  }

  Future<void> clearPendingFlow() async {
    await Future.wait([
      _storage.delete(key: _kPendingClientId),
      _storage.delete(key: _kPendingPlatform),
      _storage.delete(key: _kPendingCodeVerifier),
      _storage.delete(key: _kPendingKey),
      _storage.delete(key: _kCallbackCode),
      _storage.delete(key: _kCallbackState),
    ]);
  }

  void _handleIncomingUri(Uri uri) {
    if (uri.scheme != callbackScheme || uri.host != callbackHost) return;

    final code = uri.queryParameters['code'];
    final state = uri.queryParameters['state'];
    final error = uri.queryParameters['error'];

    // WARM case: the screen/provider that started this flow is still
    // alive and `authenticate()` below is actively awaiting this — just
    // resolve it directly, same as before.
    if (_pendingCompleter != null && !_pendingCompleter!.isCompleted) {
      if (error != null) {
        _pendingCompleter!.complete(null);
      } else {
        _pendingCompleter!.complete({'code': code, 'state': state});
      }
      return;
    }

    // COLD-START case: the process was killed while the browser was
    // open, so there's no in-memory completer to resolve anymore.
    // Persist the callback instead of dropping it, so it can be
    // completed once the app finishes booting back up (see
    // SocialProvider.resumePendingConnectIfAny, called from main.dart).
    if (error == null && code != null && state != null) {
      _persistCallback(code: code, state: state);
    }
  }

  /// Launches [authUrl] in the external browser and waits for the app to
  /// receive the `smmapp://oauth-callback?...` deep link.
  ///
  /// Returns `{'code': ..., 'state': ...}` on success, `null` if the user
  /// cancelled, the callback errored, or the flow timed out.
  Future<Map<String, String?>?> authenticate(
      String authUrl, {
        Duration timeout = const Duration(minutes: 5),
      }) async {
    // Reset any previous pending flow.
    _pendingCompleter = Completer<Map<String, String?>?>();

    final uri = Uri.parse(authUrl);
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);

    if (!launched) {
      _pendingCompleter = null;
      return null;
    }

    try {
      return await _pendingCompleter!.future.timeout(
        timeout,
        onTimeout: () => null,
      );
    } finally {
      _pendingCompleter = null;
    }
  }
}