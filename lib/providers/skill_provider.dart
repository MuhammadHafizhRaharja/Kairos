import 'package:flutter/material.dart';
import '../data/database_helper.dart';
import '../data/preferences_helper.dart';
import '../models/skill.dart';
import '../models/skill_category.dart';
import '../models/resource.dart';

/// State Management Provider untuk modul Skill.
/// Menghubungkan database (SQLite) dan preferensi lokal (Shared Preferences) dengan UI.
class SkillProvider extends ChangeNotifier {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  final PreferencesHelper _prefsHelper = PreferencesHelper();

  // State internal
  int? _currentUserId;
  List<SkillCategory> _categories = [];
  List<Skill> _skills = [];
  String _userName = 'Pengguna Kairos';
  bool _isDarkMode = false;
  bool _isLoading = false;

  // State tambahan untuk Modul Resource & Progress rekan tim
  String _defaultLang = 'id';
  bool _isNotificationEnabled = true;
  String _selectedFilter = 'Semua';

  // State untuk Modul Resource (Materi & Referensi)
  List<Resource> _resources = [];

  // Getter untuk mengakses state dari UI
  int? get currentUserId => _currentUserId;
  List<SkillCategory> get categories => _categories;
  List<Skill> get skills => _skills;
  String get userName => _userName;
  bool get isDarkMode => _isDarkMode;
  bool get isLoading => _isLoading;

  // Getter tambahan
  String get defaultLang => _defaultLang;
  bool get isNotificationEnabled => _isNotificationEnabled;
  String get selectedFilter => _selectedFilter;
  List<Resource> get resources {
    // Pengamanan tambahan untuk hot-reload state injection pada Flutter Web
    final dynamic list = _resources;
    if (list == null) return [];
    return _resources;
  }

  /// Memperbarui ID user aktif dan menyegarkan workspace data secara dinamis
  Future<void> setUserId(int? userId) async {
    if (_currentUserId == userId) return;
    _currentUserId = userId;
    
    if (userId == null) {
      _categories = [];
      _skills = [];
      _resources = [];
      notifyListeners();
    } else {
      _setLoading(true);
      try {
        await refreshCategories();
        await refreshSkills();
        await refreshResources();
      } catch (e) {
        debugPrint('Error memuat data user-specific: $e');
      } finally {
        _setLoading(false);
      }
    }
  }

  /// Memuat seluruh data awal (kategori, skill, dan preferensi pengguna)
  /// Method ini wajib dipanggil saat inisiasi aplikasi di [main.dart].
  Future<void> loadInitialData() async {
    _setLoading(true);
    try {
      // 1. Mengambil preferensi pengguna
      _userName = await _prefsHelper.getUserName();
      _isDarkMode = await _prefsHelper.getIsDarkMode();

      // Memuat preferensi tambahan
      _defaultLang = await _prefsHelper.getDefaultLang();
      _isNotificationEnabled = await _prefsHelper.getIsNotificationEnabled();
      _selectedFilter = await _prefsHelper.getResourceFilter();

      // 2. Mengambil data dari database
      await refreshCategories();
      await refreshSkills();
      await refreshResources();
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
    await _prefsHelper.setUserName(
      newName,
    ); // Simpan ke Shared Preferences di background
  }

  /// Mengaktifkan/menonaktifkan mode gelap dan menyimpannya secara persisten.
  Future<void> toggleTheme(bool isDark) async {
    _isDarkMode = isDark;
    notifyListeners(); // Update UI langsung
    await _prefsHelper.setIsDarkMode(
      isDark,
    ); // Simpan ke Shared Preferences di background
  }

  /// Mengatur bahasa default untuk Modul Resource.
  Future<void> updateDefaultLang(String lang) async {
    _defaultLang = lang;
    notifyListeners();
    await _prefsHelper.setDefaultLang(lang);
  }

  Future<void> toggleNotification(bool enabled) async {
    _isNotificationEnabled = enabled;
    notifyListeners();
    await _prefsHelper.setIsNotificationEnabled(enabled);
  }

  Future<void> updateSelectedFilter(String filter) async {
    _selectedFilter = filter;
    notifyListeners();
    await _prefsHelper.setResourceFilter(filter);
  }

  // ==========================================
  // OPERASI STATE & CRUD: SKILL CATEGORY
  // ==========================================

  /// Menyegarkan daftar kategori di memori dengan data terbaru dari database.
  Future<void> refreshCategories() async {
    _categories = await _dbHelper.getAllCategories(_currentUserId);
    notifyListeners();
  }

  /// Create: Menambahkan kategori baru.
  Future<void> addCategory(String name, String icon, int colorValue) async {
    final newCategory = SkillCategory(
      userId: _currentUserId,
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
    _skills = await _dbHelper.getAllSkills(_currentUserId);
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
      userId: _currentUserId,
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
    await refreshResources(); // Perbarui daftar resource karena ada cascade delete dari database
  }

  /// Helper: Mengambil list skill yang difilter berdasarkan kategori tertentu di memori.
  /// Membantu mereduksi query database berulang ketika menampilkan detail per kategori.
  List<Skill> getSkillsForCategory(int categoryId) {
    return _skills.where((skill) => skill.categoryId == categoryId).toList();
  }

  // ==========================================
  // OPERASI STATE & CRUD: RESOURCES
  // ==========================================

  /// Menyegarkan daftar resource materi di memori dengan data terbaru dari database.
  Future<void> refreshResources() async {
    _resources = await _dbHelper.getAllResources(_currentUserId);
    notifyListeners();
  }

  /// Create: Menambahkan resource materi baru.
  Future<void> addResource({
    int? skillId,
    required String title,
    required String url,
    String description = '',
    String category = 'Lainnya',
    int status = 0,
    String resourceType = 'materi',
  }) async {
    final newResource = Resource(
      userId: _currentUserId,
      skillId: skillId,
      title: title,
      url: url,
      description: description,
      category: category,
      status: status,
      resourceType: resourceType,
      createdAt: DateTime.now(),
    );
    await _dbHelper.insertResource(newResource);
    await refreshResources(); // Perbarui daftar resource materi
  }

  /// Update: Memperbarui data resource materi.
  Future<void> updateResource(Resource resource) async {
    await _dbHelper.updateResource(resource);
    await refreshResources(); // Perbarui daftar resource materi
  }

  /// Delete: Menghapus data resource materi berdasarkan ID.
  Future<void> deleteResource(int id) async {
    await _dbHelper.deleteResource(id);
    await refreshResources(); // Perbarui daftar resource materi
  }
}
