import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:votio_mobile/app/theme/app_theme.dart';
import 'package:votio_mobile/core/config/app_config.dart';

/// Wraps a widget with all the providers and theme needed for widget testing.
const _testConfig = AppConfig(
  environment: AppEnvironment.development,
  apiBaseUrl: 'http://localhost:3000/api/v1',
  apiTimeoutMs: 30000,
  analyticsEnabled: false,
  crashReportingEnabled: false,
);

Widget buildTestableWidget(
  Widget child, {
  List<Override> overrides = const [],
}) {
  return ProviderScope(
    overrides: [
      appConfigProvider.overrideWithValue(_testConfig),
      ...overrides,
    ],
    child: MaterialApp(
      theme: AppTheme.light(),
      home: child,
    ),
  );
}
