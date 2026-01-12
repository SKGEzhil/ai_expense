import 'package:shared_preferences/shared_preferences.dart';

/// Service for managing app settings with SharedPreferences persistence
class SettingsService {
  static const String _keyBaseUrl = 'settings_base_url';
  static const String _defaultBaseUrl = 'http://localhost:8000';

  static SettingsService? _instance;
  static SharedPreferences? _prefs;

  // Cached values
  String _baseUrl = _defaultBaseUrl;

  SettingsService._();

  /// Get singleton instance
  static Future<SettingsService> getInstance() async {
    if (_instance == null) {
      _instance = SettingsService._();
      _prefs = await SharedPreferences.getInstance();
      await _instance!._loadSettings();
    }
    return _instance!;
  }

  /// Load settings from SharedPreferences
  Future<void> _loadSettings() async {
    _baseUrl = _prefs?.getString(_keyBaseUrl) ?? _defaultBaseUrl;
  }

  /// Get base URL
  String get baseUrl => _baseUrl;

  /// Set base URL
  Future<void> setBaseUrl(String url) async {
    _baseUrl = url;
    await _prefs?.setString(_keyBaseUrl, url);
  }

  /// Reset to defaults
  Future<void> resetToDefaults() async {
    _baseUrl = _defaultBaseUrl;
    await _prefs?.remove(_keyBaseUrl);
  }
}
