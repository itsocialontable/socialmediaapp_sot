import 'package:dio/dio.dart';
import '../errors/app_exceptions.dart';

class ErrorHandler {
  /// Converts a [DioException] or generic [Exception] into a typed [AppException].
  static AppException handle(Object error) {
    if (error is DioException) {
      return _handleDioException(error);
    }
    if (error is AppException) return error;
    return UnknownException(error.toString());
  }

  static AppException _handleDioException(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const TimeoutException(
            'Request timed out. Please check your internet connection and try again.');

      case DioExceptionType.connectionError:
        return const NetworkException(
            'No internet connection. Please check your network settings.');

      case DioExceptionType.badResponse:
        return _handleBadResponse(e.response);

      case DioExceptionType.cancel:
        return const UnknownException('Request was cancelled.');

      default:
        return NetworkException(
            e.message ?? 'An unexpected network error occurred.');
    }
  }

  static AppException _handleBadResponse(Response? response) {
    if (response == null) {
      return const ServerException('No response from server.');
    }

    final statusCode = response.statusCode ?? 0;
    final data = response.data;

    // Extract message from response body
    String message = _extractMessage(data, statusCode);

    switch (statusCode) {
      case 400:
        return ValidationException(message);
      case 401:
        return UnauthorizedException(message);
      case 403:
        return UnauthorizedException(
            'You do not have permission to perform this action.');
      case 404:
        return NotFoundException(message);
      case 422:
        return ValidationException(message);
      case 429:
        return ServerException('Too many requests. Please try again later.',
            statusCode: 429);
      case 500:
      case 502:
      case 503:
        return ServerException('Server error. Please try again later.',
            statusCode: statusCode);
      default:
        return ServerException(message, statusCode: statusCode);
    }
  }

  static String _extractMessage(dynamic data, int statusCode) {
    if (data is Map<String, dynamic>) {
      // Try common message keys
      for (final key in ['message', 'error', 'detail', 'msg']) {
        if (data[key] != null) return data[key].toString();
      }
      // Validation errors (Laravel style)
      if (data['errors'] is Map) {
        final errors = data['errors'] as Map;
        final firstError = errors.values.first;
        if (firstError is List && firstError.isNotEmpty) {
          return firstError.first.toString();
        }
      }
    }
    return _defaultMessage(statusCode);
  }

  static String _defaultMessage(int statusCode) {
    switch (statusCode) {
      case 400:
        return 'Invalid request. Please check your input.';
      case 401:
        return 'Invalid credentials. Please try again.';
      case 403:
        return 'Access denied.';
      case 404:
        return 'Resource not found.';
      case 422:
        return 'Validation failed. Please check your input.';
      case 500:
        return 'Internal server error. Please try again later.';
      default:
        return 'Something went wrong. Please try again.';
    }
  }
}
