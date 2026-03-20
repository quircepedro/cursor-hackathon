import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/app_config.dart';
import '../services/logger_service.dart';
import 'interceptors/auth_interceptor.dart';
import 'interceptors/error_interceptor.dart';
import 'interceptors/logging_interceptor.dart';

/// Builds and provides the configured Dio instance.
Dio buildDio(AppConfig config) {
  final dio = Dio(
    BaseOptions(
      baseUrl: config.apiBaseUrl,
      connectTimeout: Duration(milliseconds: config.apiTimeoutMs),
      receiveTimeout: Duration(milliseconds: config.apiTimeoutMs),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ),
  );

  // Add interceptors in order: logging → auth → error handling
  if (config.isDevelopment) {
    dio.interceptors.add(LoggingInterceptor(LoggerService.instance));
  }
  dio.interceptors.add(AuthInterceptor(dio));
  dio.interceptors.add(ErrorInterceptor());

  return dio;
}

final dioProvider = Provider<Dio>((ref) {
  final config = ref.watch(appConfigProvider);
  return buildDio(config);
});
