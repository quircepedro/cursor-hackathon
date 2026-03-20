import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Attaches a fresh Firebase ID token to each outbound request.
/// On 401, force-refreshes the token and retries once using the same
/// configured Dio instance (so all interceptors and base options are preserved).
class AuthInterceptor extends Interceptor {
  // The app's configured Dio instance is injected to avoid creating a bare
  // Dio() for retries, which would bypass all other interceptors.
  AuthInterceptor(this._dio);
  final Dio _dio;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await FirebaseAuth.instance.currentUser?.getIdToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (err.response?.statusCode == 401) {
      final token =
          await FirebaseAuth.instance.currentUser?.getIdToken(true);
      if (token != null) {
        final retryOptions = err.requestOptions
          ..headers['Authorization'] = 'Bearer $token';
        try {
          final response = await _dio.fetch<dynamic>(retryOptions);
          return handler.resolve(response);
        } catch (_) {
          // fall through — propagate original error
        }
      }
    }
    handler.next(err);
  }
}
