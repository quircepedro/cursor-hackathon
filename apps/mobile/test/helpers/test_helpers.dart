import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:votio_mobile/app/theme/app_theme.dart';
import 'package:votio_mobile/core/config/app_config.dart';

/// Wraps a widget with all the providers and theme needed for widget testing.
Widget buildTestableWidget(
  Widget child, {
  List<Override> overrides = const [],
}) {
  return ProviderScope(
    overrides: [
      appConfigProvider.overrideWithValue(AppConfig.development()),
      ...overrides,
    ],
    child: MaterialApp(
      theme: AppTheme.light(),
      home: child,
    ),
  );
}
