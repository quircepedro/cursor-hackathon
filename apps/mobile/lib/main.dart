import 'package:flutter/foundation.dart';

import 'bootstrap.dart';
import 'core/config/app_config.dart';

/// **Release** (tienda / `flutter build` sin profile) → producción (HTTPS).
///
/// **Debug y profile** (`flutter run`, `flutter run --profile` en iPhone físico)
/// → desarrollo: Nest en tu Mac / descubrimiento en LAN. Sin esto, `--profile`
/// usaría `kReleaseMode` y apuntaría a producción aunque no tengas API desplegada.
///
/// Forzar entorno: `--dart-define=APP_ENV=development|staging|production`
void main() {
  const forced = String.fromEnvironment('APP_ENV', defaultValue: '');
  final AppEnvironment env = switch (forced) {
    'production' => AppEnvironment.production,
    'staging' => AppEnvironment.staging,
    'development' => AppEnvironment.development,
    _ => (kReleaseMode && !kProfileMode)
        ? AppEnvironment.production
        : AppEnvironment.development,
  };
  bootstrap(environment: env);
}
