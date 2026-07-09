enum ApiStatus { idle, loading, success, error }

class ApiResponse<T> {
  final ApiStatus status;
  final T? data;
  final String? message;
  final int? statusCode;

  const ApiResponse._({
    required this.status,
    this.data,
    this.message,
    this.statusCode,
  });

  factory ApiResponse.idle() =>
      const ApiResponse._(status: ApiStatus.idle);

  factory ApiResponse.loading() =>
      const ApiResponse._(status: ApiStatus.loading);

  factory ApiResponse.success(T data, {String? message}) =>
      ApiResponse._(status: ApiStatus.success, data: data, message: message);

  factory ApiResponse.error(String message, {int? statusCode}) =>
      ApiResponse._(
          status: ApiStatus.error,
          message: message,
          statusCode: statusCode);

  bool get isIdle => status == ApiStatus.idle;
  bool get isLoading => status == ApiStatus.loading;
  bool get isSuccess => status == ApiStatus.success;
  bool get isError => status == ApiStatus.error;
}
