import 'package:dio/dio.dart';

import '../../errors/app_exception.dart';

/// Converts Dio errors into typed [AppException] subclasses.
class ErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final exception = switch (err.type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.receiveTimeout ||
      DioExceptionType.sendTimeout =>
        const NetworkException('Request timed out'),
      DioExceptionType.connectionError => const NetworkException('No internet connection'),
      DioExceptionType.badResponse => _mapStatusCode(err.response?.statusCode),
      _ => AppException(err.message ?? 'Unknown error'),
    };

    handler.reject(
      DioException(
        requestOptions: err.requestOptions,
        error: exception,
        response: err.response,
        type: err.type,
      ),
    );
  }

  AppException _mapStatusCode(int? statusCode) {
    if (statusCode == 401) return const UnauthorizedException();
    if (statusCode == 404) return const NotFoundException();
    if (statusCode != null && statusCode >= 500) return const ServerException();
    return AppException('HTTP error $statusCode');
  }
}
