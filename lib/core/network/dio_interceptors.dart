import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../main.dart';
import '../providers/auth_provider.dart';
import '../services/token_service.dart';
import 'dio_client.dart';

// ─── Auth Token Interceptor ───────────────────────────────────────────────────
class AuthInterceptor extends Interceptor {
  // Prevents multiple simultaneous 401s from triggering the redirect repeatedly.
  static bool _isHandlingUnauthorized = false;

  @override
  Future<void> onRequest(
      RequestOptions options,
      RequestInterceptorHandler handler,
      ) async {
    final token = await TokenService.getToken();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final statusCode = err.response?.statusCode;

    if (statusCode == 401) {
      await handleUnauthorized();
    }

    handler.next(err);
  }

  // ── Public so it can be triggered from anywhere a 401 is detected ──
  // (e.g. ApiService, since Dio's validateStatus treats 401 as a normal
  // response rather than a DioException, so onError above never fires for it).
  static Future<void> handleUnauthorized() async {
    if (_isHandlingUnauthorized) return;
    _isHandlingUnauthorized = true;

    try {
      // Clear stored token/session so future requests don't keep resending it.
      await TokenService.clearAll();
      DioClient.reset();

      final context = rootNavigatorKey.currentContext;
      if (context != null) {
        // Reset app-level auth state (isLoggedIn = false, etc.)
        Provider.of<AuthProvider>(context, listen: false).logout();

        // Kick the user back to the welcome/login flow.
        GoRouter.of(context).go('/welcome');

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Session expired. Please log in again.'),
          ),
        );
      }
    } finally {
      _isHandlingUnauthorized = false;
    }
  }
}

// ─── Logging Interceptor ─────────────────────────────────────────────────────
class LoggingInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    _log('──── REQUEST ────────────────────────────────');
    _log('Method  : ${options.method}');
    _log('URL     : ${options.uri}');
    _log('Headers : ${_filterHeaders(options.headers)}');
    if (options.data != null) _log('Body    : ${options.data}');
    _log('─────────────────────────────────────────────');
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    _log('──── RESPONSE ───────────────────────────────');
    _log('Status  : ${response.statusCode}');
    _log('URL     : ${response.requestOptions.uri}');
    _log('Data    : ${response.data}');
    _log('─────────────────────────────────────────────');
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    _log('──── ERROR ──────────────────────────────────');
    _log('Type    : ${err.type}');
    _log('Message : ${err.message}');
    _log('URL     : ${err.requestOptions.uri}');
    if (err.response != null) _log('Response: ${err.response?.data}');
    _log('─────────────────────────────────────────────');
    handler.next(err);
  }

  Map<String, dynamic> _filterHeaders(Map<String, dynamic> headers) {
    final filtered = Map<String, dynamic>.from(headers);
    if (filtered.containsKey('Authorization')) {
      filtered['Authorization'] = '***REDACTED***';
    }
    return filtered;
  }

  void _log(String message) {
    // ignore: avoid_print
    print('[DIO] $message');
  }
}