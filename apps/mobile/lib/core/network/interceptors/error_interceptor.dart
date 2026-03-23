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
      DioExceptionType.connectionError => NetworkException(
            _connectionErrorMessage(err),
          ),
      DioExceptionType.badResponse => _mapBadResponse(err),
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

  static String _connectionErrorMessage(DioException err) {
    final uri = err.requestOptions.uri;
    final detail = err.message;
    final tail = (detail != null && detail.isNotEmpty) ? ' ($detail)' : '';
    return 'No se pudo conectar con $uri.$tail '
        'Comprueba internet, que API_BASE_URL en .env.development sea correcta '
        'y, si usas Nest en tu Mac, que esté en marcha (npm run backend:dev).';
  }

  AppException _mapBadResponse(DioException err) {
    final statusCode = err.response?.statusCode;
    if (statusCode == 401) return const UnauthorizedException();
    if (statusCode == 404) {
      final uri = err.requestOptions.uri;
      return NotFoundException(
        'El servidor respondió «no encontrado» (404) para $uri. '
        'En desarrollo, API_BASE_URL debe ser tu Nest en este repo: '
        'simulador iOS → http://127.0.0.1:3000/api/v1; '
        'emulador Android → http://10.0.2.2:3000/api/v1. '
        'No uses api.votio.app salvo que allí esté desplegado este mismo API.',
      );
    }
    if (statusCode != null && statusCode >= 500) return const ServerException();
    return AppException('HTTP error $statusCode');
  }
}
