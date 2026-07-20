// ── PATCH: Add this static getter to ApiService class ──────────────────────
// lib/core/network/api_service.dart
//
// Inside the ApiService class body, add:
//
//   static Dio get rawDio => DioClient.instance;
//
// This exposes the singleton Dio instance for upload progress tracking.
// The full updated api_service.dart with the patch applied is below:

import 'package:dio/dio.dart';
import 'dio_client.dart';
import 'dio_interceptors.dart';
import 'error_handler.dart';
import '../errors/app_exceptions.dart';

class ApiService {
  final Dio _dio = DioClient.instance;

  // ── Static accessor for raw Dio (used for multipart progress) ─────────
  static Dio get rawDio => DioClient.instance;

  // ─── POST ─────────────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> post(
      String endpoint, {
        required Map<String, dynamic> body,
        Map<String, dynamic>? queryParams,
      }) async {
    try {
      final response = await _dio.post(
        endpoint,
        data: body,
        queryParameters: queryParams,
      );
      return _parseResponse(response);
    } on DioException catch (e) {
      throw ErrorHandler.handle(e);
    } catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  // ─── GET ──────────────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> get(
      String endpoint, {
        Map<String, dynamic>? queryParams,
      }) async {
    try {
      final response = await _dio.get(
        endpoint,
        queryParameters: queryParams,
      );
      return _parseResponse(response);
    } on DioException catch (e) {
      throw ErrorHandler.handle(e);
    } catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  // ─── PUT ──────────────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> put(
      String endpoint, {
        required Map<String, dynamic> body,
      }) async {
    try {
      final response = await _dio.put(endpoint, data: body);
      return _parseResponse(response);
    } on DioException catch (e) {
      throw ErrorHandler.handle(e);
    } catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  // ─── POST MULTIPART ───────────────────────────────────────────────────────
  Future<Map<String, dynamic>> postMultipart(
      String endpoint, {
        required FormData formData,
      }) async {
    try {
      final response = await _dio.post(endpoint, data: formData);
      return _parseResponse(response);
    } on DioException catch (e) {
      throw ErrorHandler.handle(e);
    } catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  // ─── PATCH ────────────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> patch(
      String endpoint, {
        required Map<String, dynamic> body,
        Map<String, dynamic>? queryParams,
      }) async {
    try {
      final response = await _dio.patch(
        endpoint,
        data: body,
        queryParameters: queryParams,
      );
      return _parseResponse(response);
    } on DioException catch (e) {
      throw ErrorHandler.handle(e);
    } catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  // ─── DELETE ───────────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> delete(String endpoint) async {
    try {
      final response = await _dio.delete(endpoint);
      return _parseResponse(response);
    } on DioException catch (e) {
      throw ErrorHandler.handle(e);
    } catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  // ─── Response Parser ──────────────────────────────────────────────────────
  Map<String, dynamic> _parseResponse(Response response) {
    final statusCode = response.statusCode ?? 0;

    if (statusCode >= 200 && statusCode < 300) {
      if (response.data is Map<String, dynamic>) {
        return response.data as Map<String, dynamic>;
      }
      return {'data': response.data};
    }

    final data = response.data;
    String message = 'Something went wrong.';
    if (data is Map<String, dynamic>) {
      for (final key in ['message', 'error', 'detail', 'msg']) {
        if (data[key] != null) {
          message = data[key].toString();
          break;
        }
      }
    }

    switch (statusCode) {
      case 400:
        throw ValidationException(message);
      case 401:
        // Centralized handling: works for every screen/provider that calls
        // ApiService, without needing per-screen redirect logic. Fire-and-forget
        // (this method is sync) — the caller's UnauthorizedException still
        // propagates normally as a fallback/local error state.
        AuthInterceptor.handleUnauthorized();
        throw UnauthorizedException(message);
      case 403:
        throw UnauthorizedException('Access denied.');
      case 404:
        throw NotFoundException(message);
      case 422:
        throw ValidationException(message);
      default:
        throw ServerException(message, statusCode: statusCode);
    }
  }
}