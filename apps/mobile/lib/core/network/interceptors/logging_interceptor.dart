import 'package:dio/dio.dart';
import 'package:logger/logger.dart';

/// Logs all HTTP requests and responses in development.
class LoggingInterceptor extends Interceptor {
  const LoggingInterceptor(this._logger);
  final Logger _logger;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    _logger.d(
      '[HTTP] → ${options.method} ${options.path}',
      error: options.queryParameters.isNotEmpty ? options.queryParameters : null,
    );
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    _logger.d('[HTTP] ← ${response.statusCode} ${response.requestOptions.path}');
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    _logger.e(
      '[HTTP] ✗ ${err.requestOptions.path}',
      error: err.error ?? err.message,
    );
    handler.next(err);
  }
}
