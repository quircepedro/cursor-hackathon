// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'Votio';

  @override
  String get continueButton => 'Continuar';

  @override
  String get saveButton => 'Guardar';

  @override
  String get cancelButton => 'Cancelar';

  @override
  String get retryButton => 'Intentar de nuevo';

  @override
  String get errorGeneric => 'Algo salió mal';

  @override
  String get errorNoInternet => 'Sin conexión a internet';

  @override
  String get loadingDefault => 'Cargando...';

  @override
  String get emptyStateDefault => 'Aún no hay nada aquí';
}
