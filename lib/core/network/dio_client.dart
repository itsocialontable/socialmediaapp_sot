import 'package:dio/dio.dart';
import '../constants/app_constants.dart';
import 'dio_interceptors.dart';

class DioClient {
  static Dio? _instance;

  static Dio get instance {
    _instance ??= _createDio();
    return _instance!;
  }

  static Dio _createDio() {
    final dio = Dio(
      BaseOptions(
        baseUrl: AppConstants.baseUrl,
        connectTimeout:
            const Duration(milliseconds: AppConstants.connectTimeout),
        receiveTimeout:
            const Duration(milliseconds: AppConstants.receiveTimeout),
        sendTimeout: const Duration(milliseconds: AppConstants.sendTimeout),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          // ngrok header to bypass browser warning
          'ngrok-skip-browser-warning': 'true',
        },
        validateStatus: (status) => status != null && status < 500,
      ),
    );

    dio.interceptors.addAll([
      AuthInterceptor(),
      LoggingInterceptor(),
    ]);

    return dio;
  }

  // Reset instance (e.g. after token change)
  static void reset() => _instance = null;
}
