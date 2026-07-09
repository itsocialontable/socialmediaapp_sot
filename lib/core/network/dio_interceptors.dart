import 'package:dio/dio.dart';
import '../services/token_service.dart';

// ─── Auth Token Interceptor ───────────────────────────────────────────────────
class AuthInterceptor extends Interceptor {
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
  void onError(DioException err, ErrorInterceptorHandler handler) {
    handler.next(err);
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
