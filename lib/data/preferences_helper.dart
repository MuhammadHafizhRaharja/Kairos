import 'package:shared_preferences/shared_preferences.dart';

/// Helper class untuk mengelola penyimpanan persisten lokal sederhana menggunakan [shared_preferences].
/// Digunakan untuk menyimpan nama pengguna untuk profil dan status tema aplikasi (Dark/Light).
class PreferencesHelper {
  static const String keyUserName = 'user_name';
  static const String keyIsDarkMode = 'is_dark_mode';

  /// Menyimpan nama pengguna ke Shared Preferences.
  Future<bool> setUserName(String name) async {
    final prefs = await SharedPreferences.getInstance();
    return await prefs.setString(keyUserName, name);
  }

  /// Mengambil nama pengguna dari Shared Preferences.
  /// Mengembalikan 'Pengguna Kairos' sebagai nama default jika belum diset.
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
  /// Mengembalikan `false` (Mode Terang) secara default jika belum pernah diset.
  Future<bool> getIsDarkMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(keyIsDarkMode) ?? false;
  }
}
