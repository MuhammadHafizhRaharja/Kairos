import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/database_helper.dart';
import '../models/user.dart';

/// State Management Provider untuk Autentikasi Pengguna (Login, Register, Session).
class AuthProvider extends ChangeNotifier {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  User? _currentUser;
  bool _isLoggedIn = false;
  bool _isLoading = false;

  User? get currentUser => _currentUser;
  bool get isLoggedIn => _isLoggedIn;
  bool get isLoading => _isLoading;

  /// Memeriksa status login yang tersimpan di Shared Preferences (Startup Check)
  Future<void> checkLoginStatus() async {
    _setLoading(true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final email = prefs.getString('logged_in_user_email');
      
      if (email != null) {
        final user = await _dbHelper.getUserByEmail(email);
        if (user != null) {
          _currentUser = user;
          _isLoggedIn = true;
        } else {
          // Jika data user terhapus dari DB, bersihkan session
          await prefs.remove('logged_in_user_email');
          _currentUser = null;
          _isLoggedIn = false;
        }
      }
    } catch (e) {
      debugPrint('Error checking login status: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Mendaftarkan pengguna baru (Register)
  Future<String?> register(String name, String email, String password) async {
    _setLoading(true);
    try {
      final newUser = User(
        name: name,
        email: email,
        password: password,
        createdAt: DateTime.now(),
      );

      final resultId = await _dbHelper.insertUser(newUser);
      
      if (resultId == -1) {
        return 'Email sudah terdaftar. Gunakan email lain!';
      }

      // Berhasil registrasi, langsung set session
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('logged_in_user_email', email);
      
      _currentUser = newUser.copyWith(id: resultId);
      _isLoggedIn = true;
      notifyListeners();
      return null; // Registrasi sukses
    } catch (e) {
      return 'Terjadi kesalahan sistem: $e';
    } finally {
      _setLoading(false);
    }
  }

  /// Memproses masuk akun (Login)
  Future<bool> login(String email, String password) async {
    _setLoading(true);
    try {
      final user = await _dbHelper.authenticateUser(email, password);
      
      if (user != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('logged_in_user_email', user.email);
        
        _currentUser = user;
        _isLoggedIn = true;
        notifyListeners();
        return true;
      }
      return false; // Autentikasi gagal
    } catch (e) {
      debugPrint('Error during login: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Memproses keluar akun (Logout)
  Future<void> logout() async {
    _setLoading(true);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('logged_in_user_email');
      
      _currentUser = null;
      _isLoggedIn = false;
      notifyListeners();
    } catch (e) {
      debugPrint('Error during logout: $e');
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
