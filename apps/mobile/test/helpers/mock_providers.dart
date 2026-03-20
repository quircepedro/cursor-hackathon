import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';

import 'package:votio_mobile/core/config/app_config.dart';
import 'package:votio_mobile/features/auth/application/providers/auth_provider.dart';

// ─── Mocks ────────────────────────────────────────────────────────────────────

class MockAuthNotifier extends Mock implements AuthNotifier {}

// ─── Provider overrides ───────────────────────────────────────────────────────

/// Returns a list of standard test overrides for all global providers.
List<Override> get testOverrides => [
      appConfigProvider.overrideWithValue(AppConfig.development()),
    ];
