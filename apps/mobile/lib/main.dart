import 'package:flutter/foundation.dart';

import 'bootstrap.dart';
import 'core/config/app_config.dart';

/// Release (APK/AAB de tienda o instalada sin depurador) → producción: API HTTPS
/// para grabación/análisis; los goals viven en local (SharedPreferences).
///
/// Debug (`flutter run`) → desarrollo: Nest local / descubrimiento LAN.
///
/// Forzar entorno en un build:
/// `--dart-define=APP_ENV=development|staging|production`
void main() {
  const forced = String.fromEnvironment('APP_ENV', defaultValue: '');
  final AppEnvironment env = switch (forced) {
    'production' => AppEnvironment.production,
    'staging' => AppEnvironment.staging,
    'development' => AppEnvironment.development,
    _ => kReleaseMode ? AppEnvironment.production : AppEnvironment.development,
  };
  bootstrap(environment: env);
}
