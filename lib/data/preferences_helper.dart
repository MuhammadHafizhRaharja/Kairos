import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

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
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.setString(keyUserName, name);
    } catch (e) {
      debugPrint('Error setUserName: $e');
      return false;
    }
  }

  /// Mengambil nama pengguna dari Shared Preferences.
  Future<String> getUserName() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final value = prefs.get(keyUserName);
      if (value is String) return value;
      return 'Pengguna Kairos';
    } catch (e) {
      debugPrint('Error getUserName: $e');
      return 'Pengguna Kairos';
    }
  }

  /// Menyimpan status preferensi tema (mode gelap atau terang) ke Shared Preferences.
  Future<bool> setIsDarkMode(bool isDarkMode) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.setBool(keyIsDarkMode, isDarkMode);
    } catch (e) {
      debugPrint('Error setIsDarkMode: $e');
      return false;
    }
  }

  /// Mengambil status preferensi tema dari Shared Preferences.
  Future<bool> getIsDarkMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final value = prefs.get(keyIsDarkMode);
      if (value is bool) return value;
      if (value is String) return value.toLowerCase() == 'true';
      return false;
    } catch (e) {
      debugPrint('Error getIsDarkMode: $e');
      return false;
    }
  }

  // ==========================================
  // MODUL RESOURCE PREFERENCES
  // ==========================================

  /// Menyimpan bahasa default ke Shared Preferences.
  Future<bool> setDefaultLang(String lang) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.setString(keyDefaultLang, lang);
    } catch (e) {
      debugPrint('Error setDefaultLang: $e');
      return false;
    }
  }

  /// Mengambil bahasa default dari Shared Preferences.
  Future<String> getDefaultLang() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final value = prefs.get(keyDefaultLang);
      if (value is String) return value;
      return 'id';
    } catch (e) {
      debugPrint('Error getDefaultLang: $e');
      return 'id';
    }
  }

  /// Menyimpan status notifikasi ke Shared Preferences.
  Future<bool> setIsNotificationEnabled(bool enabled) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.setBool(keyIsNotificationEnabled, enabled);
    } catch (e) {
      debugPrint('Error setIsNotificationEnabled: $e');
      return false;
    }
  }

  /// Mengambil status notifikasi dari Shared Preferences.
  Future<bool> getIsNotificationEnabled() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final value = prefs.get(keyIsNotificationEnabled);
      if (value is bool) return value;
      if (value is String) return value.toLowerCase() == 'true';
      return true;
    } catch (e) {
      debugPrint('Error getIsNotificationEnabled: $e');
      return true;
    }
  }

  /// Menyimpan filter materi ke Shared Preferences.
  Future<bool> setResourceFilter(String filter) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.setString(keyResourceFilter, filter);
    } catch (e) {
      debugPrint('Error setResourceFilter: $e');
      return false;
    }
  }

  /// Mengambil filter materi dari Shared Preferences.
  Future<String> getResourceFilter() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final value = prefs.get(keyResourceFilter);
      if (value is String) return value;
      return 'Semua';
    } catch (e) {
      debugPrint('Error getResourceFilter: $e');
      return 'Semua';
    }
  }

  // ==========================================
  // MODUL PROGRESS PREFERENCES
  // ==========================================

  /// Menyimpan ukuran font ke Shared Preferences.
  Future<bool> setFontSize(double size) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.setDouble(keyFontSize, size);
    } catch (e) {
      debugPrint('Error setFontSize: $e');
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove(keyFontSize);
        return await prefs.setDouble(keyFontSize, size);
      } catch (_) {}
      return false;
    }
  }

  /// Mengambil ukuran font dari Shared Preferences.
  Future<double> getFontSize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final value = prefs.get(keyFontSize);
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 14.0;
      return 14.0;
    } catch (e) {
      debugPrint('Error getFontSize: $e');
      return 14.0;
    }
  }

  /// Menyimpan mode tampilan ke Shared Preferences.
  Future<bool> setViewMode(String mode) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.setString(keyViewMode, mode);
    } catch (e) {
      debugPrint('Error setViewMode: $e');
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove(keyViewMode);
        return await prefs.setString(keyViewMode, mode);
      } catch (_) {}
      return false;
    }
  }

  /// Mengambil mode tampilan dari Shared Preferences.
  Future<String> getViewMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final value = prefs.get(keyViewMode);
      if (value is String) return value;
      if (value is bool) return value ? 'Grid' : 'List';
      return 'List';
    } catch (e) {
      debugPrint('Error getViewMode: $e');
      return 'List';
    }
  }
}
