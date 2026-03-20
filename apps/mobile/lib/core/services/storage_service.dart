import 'package:shared_preferences/shared_preferences.dart';

/// Abstracts local persistent storage (tokens, user prefs).
/// Call [StorageService.init] once at bootstrap before use.
class StorageService {
  StorageService._(this._prefs);

  static late StorageService _instance;
  static StorageService get instance => _instance;

  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _instance = StorageService._(prefs);
  }

  final SharedPreferences _prefs;

  static const _kAccessToken = 'access_token';
  static const _kRefreshToken = 'refresh_token';
  static const _kUserId = 'user_id';
  static const _kOnboardingCompleted = 'onboarding_completed';

  Future<String?> getAccessToken() async => _prefs.getString(_kAccessToken);
  Future<void> setAccessToken(String token) => _prefs.setString(_kAccessToken, token);

  Future<String?> getRefreshToken() async => _prefs.getString(_kRefreshToken);
  Future<void> setRefreshToken(String token) => _prefs.setString(_kRefreshToken, token);

  Future<String?> getUserId() async => _prefs.getString(_kUserId);
  Future<void> setUserId(String id) => _prefs.setString(_kUserId, id);

  Future<bool> isOnboardingCompleted() async =>
      _prefs.getBool(_kOnboardingCompleted) ?? false;
  Future<void> setOnboardingCompleted() => _prefs.setBool(_kOnboardingCompleted, true);

  Future<void> clearTokens() async {
    await _prefs.remove(_kAccessToken);
    await _prefs.remove(_kRefreshToken);
    await _prefs.remove(_kUserId);
  }

  Future<void> clearAll() => _prefs.clear();
}
