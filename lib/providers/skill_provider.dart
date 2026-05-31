import 'package:flutter/material.dart';
import '../data/database_helper.dart';
import '../data/preferences_helper.dart';
import '../models/skill.dart';
import '../models/skill_category.dart';

/// State Management Provider untuk modul Skill.
/// Menghubungkan database (SQLite) dan preferensi lokal (Shared Preferences) dengan UI.
class SkillProvider extends ChangeNotifier {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  final PreferencesHelper _prefsHelper = PreferencesHelper();

  // State internal
  List<SkillCategory> _categories = [];
  List<Skill> _skills = [];
  String _userName = 'Pengguna Kairos';
  bool _isDarkMode = false;
  bool _isLoading = false;

  // Getter untuk mengakses state dari UI
  List<SkillCategory> get categories => _categories;
  List<Skill> get skills => _skills;
  String get userName => _userName;
  bool get isDarkMode => _isDarkMode;
  bool get isLoading => _isLoading;

  /// Memuat seluruh data awal (kategori, skill, dan preferensi pengguna)
  /// Method ini wajib dipanggil saat inisiasi aplikasi di [main.dart].
  Future<void> loadInitialData() async {
    _setLoading(true);
    try {
      // 1. Mengambil preferensi pengguna
      _userName = await _prefsHelper.getUserName();
      _isDarkMode = await _prefsHelper.getIsDarkMode();

      // 2. Mengambil data dari database
      await refreshCategories();
      await refreshSkills();
    } catch (e) {
      debugPrint('Error saat memuat data awal: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Helper untuk mengubah status loading dan memberitahu UI.
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  // ==========================================
  // MANAJEMEN PREFERENSI (SHARED PREFERENCES)
  // ==========================================

  /// Memperbarui nama pengguna dan menyimpannya secara persisten.
  Future<void> updateUserName(String newName) async {
    _userName = newName;
    notifyListeners(); // Update UI langsung
    await _prefsHelper.setUserName(newName); // Simpan ke Shared Preferences di background
  }

  /// Mengaktifkan/menonaktifkan mode gelap dan menyimpannya secara persisten.
  Future<void> toggleTheme(bool isDark) async {
    _isDarkMode = isDark;
    notifyListeners(); // Update UI langsung
    await _prefsHelper.setIsDarkMode(isDark); // Simpan ke Shared Preferences di background
  }

  // ==========================================
  // OPERASI STATE & CRUD: SKILL CATEGORY
  // ==========================================

  /// Menyegarkan daftar kategori di memori dengan data terbaru dari database.
  Future<void> refreshCategories() async {
    _categories = await _dbHelper.getAllCategories();
    notifyListeners();
  }

  /// Create: Menambahkan kategori baru.
  Future<void> addCategory(String name, String icon, int colorValue) async {
    final newCategory = SkillCategory(
      name: name,
      icon: icon,
      colorValue: colorValue,
    );
    await _dbHelper.insertCategory(newCategory);
    await refreshCategories(); // Perbarui state kategori
  }

  /// Update: Memperbarui data kategori.
  Future<void> updateCategory(SkillCategory category) async {
    await _dbHelper.updateCategory(category);
    await refreshCategories(); // Perbarui state kategori
  }

  /// Delete: Menghapus kategori beserta skill di dalamnya (efek cascade).
  Future<void> deleteCategory(int id) async {
    await _dbHelper.deleteCategory(id);
    await refreshCategories(); // Perbarui state kategori
    await refreshSkills(); // Perbarui state skill karena ada cascade delete
  }

  // ==========================================
  // OPERASI STATE & CRUD: SKILLS
  // ==========================================

  /// Menyegarkan daftar skill di memori dengan data terbaru dari database.
  Future<void> refreshSkills() async {
    _skills = await _dbHelper.getAllSkills();
    notifyListeners();
  }

  /// Create: Menambahkan skill baru ke kategori tertentu.
  Future<void> addSkill({
    required int categoryId,
    required String name,
    String description = '',
    int level = 1,
    double progress = 0.0,
  }) async {
    final newSkill = Skill(
      categoryId: categoryId,
      name: name,
      description: description,
      level: level,
      progress: progress,
      createdAt: DateTime.now(),
    );
    await _dbHelper.insertSkill(newSkill);
    await refreshSkills(); // Perbarui daftar skill
  }

  /// Update: Memperbarui data skill (misalnya menaikkan level atau mengubah progres).
  Future<void> updateSkill(Skill skill) async {
    await _dbHelper.updateSkill(skill);
    await refreshSkills(); // Perbarui daftar skill
  }

  /// Delete: Menghapus skill berdasarkan ID.
  Future<void> deleteSkill(int id) async {
    await _dbHelper.deleteSkill(id);
    await refreshSkills(); // Perbarui daftar skill
  }

  /// Helper: Mengambil list skill yang difilter berdasarkan kategori tertentu di memori.
  /// Membantu mereduksi query database berulang ketika menampilkan detail per kategori.
  List<Skill> getSkillsForCategory(int categoryId) {
    return _skills.where((skill) => skill.categoryId == categoryId).toList();
  }
}
