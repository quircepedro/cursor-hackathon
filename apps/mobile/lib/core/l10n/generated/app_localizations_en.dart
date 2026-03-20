// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Votio';

  @override
  String get continueButton => 'Continue';

  @override
  String get saveButton => 'Save';

  @override
  String get cancelButton => 'Cancel';

  @override
  String get retryButton => 'Try again';

  @override
  String get errorGeneric => 'Something went wrong';

  @override
  String get errorNoInternet => 'No internet connection';

  @override
  String get loadingDefault => 'Loading...';

  @override
  String get emptyStateDefault => 'Nothing here yet';
}
