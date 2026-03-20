/// Interface for analytics tracking.
/// Inject a real implementation (Firebase Analytics, Mixpanel, etc.) at bootstrap.
abstract class AnalyticsService {
  Future<void> logEvent(String name, {Map<String, dynamic>? parameters});
  Future<void> setUserId(String userId);
  Future<void> setUserProperty(String name, String value);
  Future<void> logScreenView(String screenName);
}

/// No-op implementation used in development / before a real service is wired.
class NullAnalyticsService implements AnalyticsService {
  const NullAnalyticsService();

  @override
  Future<void> logEvent(String name, {Map<String, dynamic>? parameters}) async {}

  @override
  Future<void> setUserId(String userId) async {}

  @override
  Future<void> setUserProperty(String name, String value) async {}

  @override
  Future<void> logScreenView(String screenName) async {}
}
