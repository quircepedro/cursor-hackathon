import 'package:logger/logger.dart';

import '../config/app_config.dart';

/// Thin wrapper around the Logger package.
/// Call [LoggerService.init] once at bootstrap.
class LoggerService {
  LoggerService._();

  static Logger _instance = Logger(printer: PrettyPrinter());

  static Logger get instance => _instance;

  static void init({required AppConfig config}) {
    _instance = Logger(
      level: config.isDevelopment ? Level.debug : Level.warning,
      printer: config.isDevelopment
          ? PrettyPrinter(methodCount: 2, errorMethodCount: 6)
          : SimplePrinter(printTime: true),
    );
  }
}
