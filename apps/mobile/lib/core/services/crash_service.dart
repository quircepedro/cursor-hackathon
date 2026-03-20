/// Interface for crash / error reporting.
/// Wire a real implementation (Sentry, Firebase Crashlytics) at bootstrap.
abstract class CrashService {
  Future<void> init();
  Future<void> recordError(Object error, StackTrace stackTrace, {String? hint});
  Future<void> setUser(String userId);
}

class NullCrashService implements CrashService {
  const NullCrashService();

  @override
  Future<void> init() async {}

  @override
  Future<void> recordError(Object error, StackTrace stackTrace, {String? hint}) async {}

  @override
  Future<void> setUser(String userId) async {}
}
