import 'package:shared_preferences/shared_preferences.dart';

class AppPreferencesService {
  static const String _notificationsKey = 'app_notifications_enabled';
  static const String _compactLayoutKey = 'app_compact_layout';
  static const String _languageKey = 'app_language';

  static Future<bool> getNotificationsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_notificationsKey) ?? true;
  }

  static Future<void> setNotificationsEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_notificationsKey, enabled);
  }

  static Future<bool> getCompactLayout() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_compactLayoutKey) ?? false;
  }

  static Future<void> setCompactLayout(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_compactLayoutKey, enabled);
  }

  static Future<String> getLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_languageKey) ?? 'fr';
  }

  static Future<void> setLanguage(String languageCode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_languageKey, languageCode);
  }
}