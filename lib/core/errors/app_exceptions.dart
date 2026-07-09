abstract class AppException implements Exception {
  final String message;
  final int? statusCode;

  const AppException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

class NetworkException extends AppException {
  const NetworkException(super.message);
}

class TimeoutException extends AppException {
  const TimeoutException(super.message);
}

class UnauthorizedException extends AppException {
  const UnauthorizedException(super.message) : super(statusCode: 401);
}

class ValidationException extends AppException {
  const ValidationException(super.message) : super(statusCode: 422);
}

class ServerException extends AppException {
  const ServerException(super.message, {super.statusCode});
}

class NotFoundException extends AppException {
  const NotFoundException(super.message) : super(statusCode: 404);
}

class UnknownException extends AppException {
  const UnknownException(super.message);
}
