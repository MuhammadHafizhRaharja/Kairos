import 'package:shared_preferences/shared_preferences.dart';

/// Helper class untuk mengelola penyimpanan persisten lokal sederhana menggunakan [shared_preferences].
/// Digunakan untuk menyimpan nama pengguna untuk profil dan status tema aplikasi (Dark/Light).
class PreferencesHelper {
  static const String keyUserName = 'user_name';
  static const String keyIsDarkMode = 'is_dark_mode';

  // Key tambahan untuk Modul Resource (Materi & Referensi)
  static const String keyDefaultLang = 'default_lang';
  static const String keyIsNotificationEnabled = 'is_notification_enabled';
  static const String keyResourceFilter = 'resource_filter';

  // Key tambahan untuk Modul Progress (Log Progress & Tantangan)
  static const String keyFontSize = 'font_size';
  static const String keyViewMode = 'view_mode';

  // ==========================================
  // MODUL SKILL PREFERENCES
  // ==========================================

  /// Menyimpan nama pengguna ke Shared Preferences.
  Future<bool> setUserName(String name) async {
    final prefs = await SharedPreferences.getInstance();
    return await prefs.setString(keyUserName, name);
  }

  /// Mengambil nama pengguna dari Shared Preferences.
  Future<String> getUserName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(keyUserName) ?? 'Pengguna Kairos';
  }

  /// Menyimpan status preferensi tema (mode gelap atau terang) ke Shared Preferences.
  Future<bool> setIsDarkMode(bool isDarkMode) async {
    final prefs = await SharedPreferences.getInstance();
    return await prefs.setBool(keyIsDarkMode, isDarkMode);
  }

  /// Mengambil status preferensi tema dari Shared Preferences.
  Future<bool> getIsDarkMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(keyIsDarkMode) ?? false;
  }

  // ==========================================
  // MODUL RESOURCE PREFERENCES
  // ==========================================

  /// Menyimpan bahasa default ke Shared Preferences.
  Future<bool> setDefaultLang(String lang) async {
    final prefs = await SharedPreferences.getInstance();
    return await prefs.setString(keyDefaultLang, lang);
  }

  /// Mengambil bahasa default dari Shared Preferences.
  Future<String> getDefaultLang() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(keyDefaultLang) ?? 'id';
  }

  /// Menyimpan status notifikasi ke Shared Preferences.
  Future<bool> setIsNotificationEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    return await prefs.setBool(keyIsNotificationEnabled, enabled);
  }

  /// Mengambil status notifikasi dari Shared Preferences.
  Future<bool> getIsNotificationEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(keyIsNotificationEnabled) ?? true;
  }

  /// Menyimpan filter materi ke Shared Preferences.
  Future<bool> setResourceFilter(String filter) async {
    final prefs = await SharedPreferences.getInstance();
    return await prefs.setString(keyResourceFilter, filter);
  }

  /// Mengambil filter materi dari Shared Preferences.
  Future<String> getResourceFilter() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(keyResourceFilter) ?? 'Semua';
  }

  // ==========================================
  // MODUL PROGRESS PREFERENCES
  // ==========================================

  /// Menyimpan ukuran font ke Shared Preferences.
  Future<bool> setFontSize(double size) async {
    final prefs = await SharedPreferences.getInstance();
    return await prefs.setDouble(keyFontSize, size);
  }

  /// Mengambil ukuran font dari Shared Preferences.
  Future<double> getFontSize() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(keyFontSize) ?? 14.0;
  }

  /// Menyimpan mode tampilan ke Shared Preferences.
  Future<bool> setViewMode(String mode) async {
    final prefs = await SharedPreferences.getInstance();
    return await prefs.setString(keyViewMode, mode);
  }

  /// Mengambil mode tampilan dari Shared Preferences.
  Future<String> getViewMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(keyViewMode) ?? 'List';
  }
}
