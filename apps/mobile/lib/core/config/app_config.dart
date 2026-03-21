import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum AppEnvironment { development, staging, production }

class AppConfig {
  final AppEnvironment environment;
  final String apiBaseUrl;
  final int apiTimeoutMs;
  final bool analyticsEnabled;
  final bool crashReportingEnabled;

  const AppConfig({
    required this.environment,
    required this.apiBaseUrl,
    required this.apiTimeoutMs,
    required this.analyticsEnabled,
    required this.crashReportingEnabled,
  });

  factory AppConfig.development({required String apiBaseUrl}) => AppConfig(
        environment: AppEnvironment.development,
        apiBaseUrl: apiBaseUrl,
        apiTimeoutMs: int.tryParse(dotenv.env['API_TIMEOUT_MS'] ?? '') ?? 30000,
        analyticsEnabled: false,
        crashReportingEnabled: false,
      );

  factory AppConfig.staging() {
    const fromDefine = String.fromEnvironment('API_BASE_URL', defaultValue: '');
    return AppConfig(
        environment: AppEnvironment.staging,
        apiBaseUrl: fromDefine.isNotEmpty
            ? fromDefine
            : (dotenv.env['API_BASE_URL'] ?? 'https://api-staging.votio.app/api/v1'),
        apiTimeoutMs: int.tryParse(dotenv.env['API_TIMEOUT_MS'] ?? '') ?? 30000,
        analyticsEnabled: true,
        crashReportingEnabled: true,
      );
  }

  factory AppConfig.production() {
    const fromDefine = String.fromEnvironment('API_BASE_URL', defaultValue: '');
    return AppConfig(
        environment: AppEnvironment.production,
        apiBaseUrl: fromDefine.isNotEmpty
            ? fromDefine
            : (dotenv.env['API_BASE_URL'] ?? 'https://api.votio.app/api/v1'),
        apiTimeoutMs: int.tryParse(dotenv.env['API_TIMEOUT_MS'] ?? '') ?? 30000,
        analyticsEnabled: true,
        crashReportingEnabled: true,
      );
  }

  String get envFileName => switch (environment) {
        AppEnvironment.development => '.env.development',
        AppEnvironment.staging => '.env.staging',
        AppEnvironment.production => '.env.production',
      };

  bool get isDevelopment => environment == AppEnvironment.development;
  bool get isProduction => environment == AppEnvironment.production;
}

/// Riverpod provider — overridden at bootstrap with the correct flavor config.
final appConfigProvider = Provider<AppConfig>(
  (_) => throw UnimplementedError('Override appConfigProvider in ProviderScope'),
);
