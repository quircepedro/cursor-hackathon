import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:votio_mobile/core/config/app_config.dart';
import 'package:votio_mobile/features/auth/application/providers/auth_provider.dart';
import 'package:votio_mobile/features/auth/domain/repositories/auth_repository.dart';

// ─── Mocks ────────────────────────────────────────────────────────────────────

class MockAuthNotifier extends Mock implements AuthNotifier {}

class MockAuthRepository extends Mock implements AuthRepository {}

// ─── Provider overrides ───────────────────────────────────────────────────────

const _testConfig = AppConfig(
  environment: AppEnvironment.development,
  apiBaseUrl: '',
  geminiApiKey: 'test-gemini-key',
  apiTimeoutMs: 30000,
  analyticsEnabled: false,
  crashReportingEnabled: false,
);

/// Returns a list of standard test overrides for all global providers.
List<Override> get testOverrides => [
      appConfigProvider.overrideWithValue(_testConfig),
    ];

List<Override> authOverrides(AuthRepository repo) => [
      authRepositoryProvider.overrideWithValue(repo),
    ];
