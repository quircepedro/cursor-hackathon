import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/app_config.dart';
import '../services/logger_service.dart';
import 'interceptors/auth_interceptor.dart';
import 'interceptors/error_interceptor.dart';
import 'interceptors/logging_interceptor.dart';

/// Cliente HTTP compartido (base URL, timeouts, Firebase Bearer, errores tipados).
final dioProvider = Provider<Dio>((ref) {
  final config = ref.watch(appConfigProvider);
  final timeout = Duration(milliseconds: config.apiTimeoutMs);

  final dio = Dio(
    BaseOptions(
      baseUrl: config.apiBaseUrl,
      connectTimeout: timeout,
      receiveTimeout: timeout,
      sendTimeout: timeout,
      headers: const {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ),
  );

  dio.interceptors.addAll([
    if (config.isDevelopment) LoggingInterceptor(LoggerService.instance),
    AuthInterceptor(dio),
    ErrorInterceptor(),
  ]);

  return dio;
});
