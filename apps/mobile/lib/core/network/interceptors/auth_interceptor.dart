import 'package:dio/dio.dart';

import '../../services/storage_service.dart';

/// Attaches the Bearer token to outbound requests.
/// On 401, clears the token and lets the caller handle re-authentication.
class AuthInterceptor extends Interceptor {
  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await StorageService.instance.getAccessToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (err.response?.statusCode == 401) {
      // Token expired — clear it, downstream error handling will redirect to login
      StorageService.instance.clearTokens();
    }
    handler.next(err);
  }
}
