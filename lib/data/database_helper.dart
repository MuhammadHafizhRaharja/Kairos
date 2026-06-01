import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:path/path.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import '../models/skill.dart';
import '../models/skill_category.dart';
import '../models/resource.dart';
import '../models/user.dart';

/// Helper class untuk mengelola database SQLite menggunakan sqflite.
/// Menggunakan pola Singleton untuk memastikan hanya ada satu instance database yang aktif.
class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  // In-memory fallbacks untuk mendukung demo di Flutter Web tanpa crash SQLite
  static final List<SkillCategory> _webCategories = [];
  static final List<Skill> _webSkills = [];
  static final List<Resource> _webResources = [];
  static final List<User> _webUsers = [];
  static int _webIdCounter = 100;
  static bool _webDataLoaded = false;

  /// Memuat data web dari SharedPreferences secara asinkron agar persisten
  static Future<void> _loadWebDataFromPrefs() async {
    if (!kIsWeb) return;
    if (_webDataLoaded) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      
      final catStr = prefs.getString('web_categories');
      if (catStr != null) {
        final List decoded = json.decode(catStr);
        _webCategories.clear();
        _webCategories.addAll(decoded.map((json) => SkillCategory.fromMap(Map<String, dynamic>.from(json))).toList());
      } else {
        // Seed default categories jika pertama kali dibuka (userId = null / global)
        _webCategories.clear();
        _webCategories.addAll([
          SkillCategory(id: 1, userId: null, name: 'Pemrograman', icon: 'code', colorValue: 0xFF2196F3),
          SkillCategory(id: 2, userId: null, name: 'Kebugaran', icon: 'fitness_center', colorValue: 0xFF4CAF50),
          SkillCategory(id: 3, userId: null, name: 'Bahasa', icon: 'translate', colorValue: 0xFFFF9800),
          SkillCategory(id: 4, userId: null, name: 'Musik & Seni', icon: 'music_note', colorValue: 0xFF9C27B0),
        ]);
        // Simpan langsung data awal
        final categoriesJson = _webCategories.map((c) => c.toMap()).toList();
        await prefs.setString('web_categories', json.encode(categoriesJson));
      }
      
      final skillStr = prefs.getString('web_skills');
      if (skillStr != null) {
        final List decoded = json.decode(skillStr);
        _webSkills.clear();
        _webSkills.addAll(decoded.map((json) => Skill.fromMap(Map<String, dynamic>.from(json))).toList());
      }
      
      final resStr = prefs.getString('web_resources');
      if (resStr != null) {
        final List decoded = json.decode(resStr);
        _webResources.clear();
        _webResources.addAll(decoded.map((json) => Resource.fromMap(Map<String, dynamic>.from(json))).toList());
      }

      final userStr = prefs.getString('web_users');
      if (userStr != null) {
        final List decoded = json.decode(userStr);
        _webUsers.clear();
        _webUsers.addAll(decoded.map((json) => User.fromMap(Map<String, dynamic>.from(json))).toList());
      }
      
      _webIdCounter = prefs.getInt('web_id_counter') ?? 100;
      _webDataLoaded = true;
    } catch (e) {
      debugPrint('Error memuat data SharedPreferences Web: $e');
    }
  }

  /// Menyimpan data web ke SharedPreferences agar tidak hilang saat restart browser
  static Future<void> _saveWebDataToPrefs() async {
    if (!kIsWeb) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      
      final categoriesJson = _webCategories.map((c) => c.toMap()).toList();
      final skillsJson = _webSkills.map((s) => s.toMap()).toList();
      final resourcesJson = _webResources.map((r) => r.toMap()).toList();
      final usersJson = _webUsers.map((u) => u.toMap()).toList();
      
      await prefs.setString('web_categories', json.encode(categoriesJson));
      await prefs.setString('web_skills', json.encode(skillsJson));
      await prefs.setString('web_resources', json.encode(resourcesJson));
      await prefs.setString('web_users', json.encode(usersJson));
      await prefs.setInt('web_id_counter', _webIdCounter);
    } catch (e) {
      debugPrint('Error menyimpan data SharedPreferences Web: $e');
    }
  }

  DatabaseHelper._init();

  /// Mengambil instance database aktif. Jika belum diinisiasi, akan memicu inisiasi.
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('kairos_skills.db');
    return _database!;
  }

  /// Menginisialisasi file database pada storage lokal perangkat.
  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 4,
      onCreate: _createDB,
      onConfigure: _configureDB,
      onUpgrade: _upgradeDB,
    );
  }

  /// Mengonfigurasi database saat dibuka.
  /// Sangat penting untuk mengaktifkan Foreign Key support di SQLite secara eksplisit.
  Future _configureDB(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
  }

  /// Membuat tabel-tabel database saat database pertama kali dibuat.
  Future _createDB(Database db, int version) async {
    // 0. Membuat tabel Pengguna (Users)
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        email TEXT NOT NULL UNIQUE,
        password TEXT NOT NULL,
        createdAt TEXT NOT NULL
      )
    ''');

    // 1. Membuat tabel Kategori Keahlian (SkillCategories)
    await db.execute('''
      CREATE TABLE skill_categories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        userId INTEGER,
        name TEXT NOT NULL,
        icon TEXT NOT NULL,
        colorValue INTEGER NOT NULL
      )
    ''');

    // 2. Membuat tabel Keahlian (Skills) dengan relasi Foreign Key ke SkillCategories.
    // Ditambahkan aksi ON DELETE CASCADE agar saat kategori dihapus, seluruh skill di dalamnya ikut terhapus.
    await db.execute('''
      CREATE TABLE skills (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        userId INTEGER,
        categoryId INTEGER NOT NULL,
        name TEXT NOT NULL,
        description TEXT NOT NULL,
        level INTEGER NOT NULL DEFAULT 1,
        progress REAL NOT NULL DEFAULT 0.0,
        createdAt TEXT NOT NULL,
        FOREIGN KEY (categoryId) REFERENCES skill_categories (id) ON DELETE CASCADE
      )
    ''');

    // 3. Membuat tabel Sumber & Materi Belajar (Resources) dengan relasi Foreign Key ke Skills (nullable, cascade delete)
    await db.execute('''
      CREATE TABLE resources (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        userId INTEGER,
        skillId INTEGER,
        title TEXT NOT NULL,
        url TEXT NOT NULL,
        description TEXT NOT NULL DEFAULT '',
        category TEXT NOT NULL DEFAULT 'Lainnya',
        status INTEGER NOT NULL DEFAULT 0,
        createdAt TEXT NOT NULL,
        FOREIGN KEY (skillId) REFERENCES skills (id) ON DELETE CASCADE
      )
    ''');

    // 4. Memasukkan data awal (seed data) berupa beberapa kategori default agar UI tidak kosong saat pertama run.
    await _seedDefaultCategories(db);
  }

  /// Meng-upgrade database jika nomor versi bertambah.
  Future _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE resources (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          skillId INTEGER,
          title TEXT NOT NULL,
          url TEXT NOT NULL,
          description TEXT NOT NULL DEFAULT '',
          category TEXT NOT NULL DEFAULT 'Lainnya',
          status INTEGER NOT NULL DEFAULT 0,
          createdAt TEXT NOT NULL,
          FOREIGN KEY (skillId) REFERENCES skills (id) ON DELETE CASCADE
        )
      ''');
    }
    if (oldVersion < 3) {
      await db.execute('''
        CREATE TABLE users (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          email TEXT NOT NULL UNIQUE,
          password TEXT NOT NULL,
          createdAt TEXT NOT NULL
        )
      ''');
    }
    if (oldVersion < 4) {
      try {
        await db.execute('ALTER TABLE skill_categories ADD COLUMN userId INTEGER');
      } catch (e) {
        debugPrint('Migration: userId already exists in skill_categories: $e');
      }
      try {
        await db.execute('ALTER TABLE skills ADD COLUMN userId INTEGER');
      } catch (e) {
        debugPrint('Migration: userId already exists in skills: $e');
      }
      try {
        await db.execute('ALTER TABLE resources ADD COLUMN userId INTEGER');
      } catch (e) {
        debugPrint('Migration: userId already exists in resources: $e');
      }
    }
  }

  /// Memasukkan data kategori default ke dalam database.
  Future _seedDefaultCategories(Database db) async {
    final defaultCategories = [
      SkillCategory(
        userId: null, // Global
        name: 'Pemrograman',
        icon: 'code',
        colorValue: 0xFF2196F3,
      ), // Biru
      SkillCategory(
        userId: null, // Global
        name: 'Kebugaran',
        icon: 'fitness_center',
        colorValue: 0xFF4CAF50,
      ), // Hijau
      SkillCategory(
        userId: null, // Global
        name: 'Bahasa',
        icon: 'translate',
        colorValue: 0xFFFF9800,
      ), // Jingga
      SkillCategory(
        userId: null, // Global
        name: 'Musik & Seni',
        icon: 'music_note',
        colorValue: 0xFF9C27B0,
      ), // Ungu
    ];

    for (var category in defaultCategories) {
      await db.insert('skill_categories', category.toMap());
    }
  }

  // ==========================================
  // CRUD & AUTHENTICATION UNTUK TABEL USERS
  // ==========================================

  /// Create: Mendaftarkan user baru (Register)
  Future<int> insertUser(User user) async {
    if (kIsWeb) {
      await _loadWebDataFromPrefs();
      // Periksa duplikasi email secara case-insensitive
      final exists = _webUsers.any((u) => u.email.toLowerCase() == user.email.toLowerCase());
      if (exists) return -1; // Duplikat email

      final newId = _webIdCounter++;
      final newUser = User(
        id: newId,
        name: user.name,
        email: user.email,
        password: user.password,
        createdAt: user.createdAt,
      );
      _webUsers.add(newUser);
      await _saveWebDataToPrefs();
      return newId;
    }
    final db = await instance.database;
    try {
      return await db.insert('users', user.toMap());
    } catch (e) {
      return -1; // Menangani email UNIQUE constraint error
    }
  }

  /// Read: Mengambil user berdasarkan Email
  Future<User?> getUserByEmail(String email) async {
    if (kIsWeb) {
      await _loadWebDataFromPrefs();
      final idx = _webUsers.indexWhere((u) => u.email.toLowerCase() == email.toLowerCase());
      if (idx != -1) return _webUsers[idx];
      return null;
    }
    final db = await instance.database;
    final result = await db.query(
      'users',
      where: 'email = ?',
      whereArgs: [email],
    );
    if (result.isNotEmpty) {
      return User.fromMap(result.first);
    }
    return null;
  }

  /// Read: Mencocokkan email dan password untuk Login
  Future<User?> authenticateUser(String email, String password) async {
    if (kIsWeb) {
      await _loadWebDataFromPrefs();
      final idx = _webUsers.indexWhere(
        (u) => u.email.toLowerCase() == email.toLowerCase() && u.password == password
      );
      if (idx != -1) return _webUsers[idx];
      return null;
    }
    final db = await instance.database;
    final result = await db.query(
      'users',
      where: 'email = ? AND password = ?',
      whereArgs: [email, password],
    );
    if (result.isNotEmpty) {
      return User.fromMap(result.first);
    }
    return null;
  }

  // ==========================================
  // CRUD UNTUK TABEL SKILL_CATEGORIES
  // ==========================================

  /// Create: Menambahkan kategori baru.
  Future<int> insertCategory(SkillCategory category) async {
    if (kIsWeb) {
      await _loadWebDataFromPrefs();
      final newId = _webIdCounter++;
      final newCat = SkillCategory(
        id: newId,
        userId: category.userId,
        name: category.name,
        icon: category.icon,
        colorValue: category.colorValue,
      );
      _webCategories.add(newCat);
      await _saveWebDataToPrefs();
      return newId;
    }
    final db = await instance.database;
    return await db.insert('skill_categories', category.toMap());
  }

  /// Read: Mengambil semua data kategori milik user aktif (dan default global).
  Future<List<SkillCategory>> getAllCategories(int? userId) async {
    if (kIsWeb) {
      await _loadWebDataFromPrefs();
      final filtered = _webCategories.where((c) => c.userId == null || c.userId == userId).toList();
      filtered.sort((a, b) => a.name.compareTo(b.name));
      return filtered;
    }
    final db = await instance.database;
    final result = await db.query(
      'skill_categories',
      where: 'userId IS NULL OR userId = ?',
      whereArgs: [userId],
      orderBy: 'name ASC',
    );
    return result.map((json) => SkillCategory.fromMap(json)).toList();
  }

  /// Update: Memperbarui data kategori.
  Future<int> updateCategory(SkillCategory category) async {
    if (kIsWeb) {
      await _loadWebDataFromPrefs();
      final idx = _webCategories.indexWhere((c) => c.id == category.id);
      if (idx != -1) {
        _webCategories[idx] = category;
        await _saveWebDataToPrefs();
        return 1;
      }
      return 0;
    }
    final db = await instance.database;
    return await db.update(
      'skill_categories',
      category.toMap(),
      where: 'id = ?',
      whereArgs: [category.id],
    );
  }

  /// Delete: Menghapus kategori berdasarkan ID.
  /// Karena menggunakan ON DELETE CASCADE, semua skill dengan categoryId ini otomatis terhapus.
  Future<int> deleteCategory(int id) async {
    if (kIsWeb) {
      await _loadWebDataFromPrefs();
      _webCategories.removeWhere((c) => c.id == id);
      // Cascade delete skills
      _webSkills.removeWhere((s) => s.categoryId == id);
      // Cascade delete resources
      final skillIds = _webSkills.map((s) => s.id).toSet();
      _webResources.removeWhere((r) => r.skillId != null && !skillIds.contains(r.skillId));
      await _saveWebDataToPrefs();
      return 1;
    }
    final db = await instance.database;
    return await db.delete(
      'skill_categories',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ==========================================
  // CRUD UNTUK TABEL SKILLS
  // ==========================================

  /// Create: Menambahkan skill baru.
  Future<int> insertSkill(Skill skill) async {
    if (kIsWeb) {
      await _loadWebDataFromPrefs();
      final newId = _webIdCounter++;
      final newSkill = Skill(
        id: newId,
        userId: skill.userId,
        categoryId: skill.categoryId,
        name: skill.name,
        description: skill.description,
        level: skill.level,
        progress: skill.progress,
        createdAt: skill.createdAt,
      );
      _webSkills.add(newSkill);
      await _saveWebDataToPrefs();
      return newId;
    }
    final db = await instance.database;
    return await db.insert('skills', skill.toMap());
  }

  /// Read: Mengambil semua data skill milik user aktif.
  Future<List<Skill>> getAllSkills(int? userId) async {
    if (kIsWeb) {
      await _loadWebDataFromPrefs();
      final filtered = _webSkills.where((s) => s.userId == userId).toList();
      filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return filtered;
    }
    final db = await instance.database;
    final result = await db.query(
      'skills',
      where: 'userId = ?',
      whereArgs: [userId],
      orderBy: 'createdAt DESC',
    );
    return result.map((json) => Skill.fromMap(json)).toList();
  }

  /// Read: Mengambil semua skill yang berada di bawah kategori tertentu milik user aktif.
  Future<List<Skill>> getSkillsByCategoryId(int categoryId, int? userId) async {
    if (kIsWeb) {
      await _loadWebDataFromPrefs();
      final filtered = _webSkills.where((s) => s.categoryId == categoryId && s.userId == userId).toList();
      filtered.sort((a, b) => a.name.compareTo(b.name));
      return filtered;
    }
    final db = await instance.database;
    final result = await db.query(
      'skills',
      where: 'categoryId = ? AND userId = ?',
      whereArgs: [categoryId, userId],
      orderBy: 'name ASC',
    );
    return result.map((json) => Skill.fromMap(json)).toList();
  }

  /// Update: Memperbarui data skill.
  Future<int> updateSkill(Skill skill) async {
    if (kIsWeb) {
      await _loadWebDataFromPrefs();
      final idx = _webSkills.indexWhere((s) => s.id == skill.id);
      if (idx != -1) {
        _webSkills[idx] = skill;
        await _saveWebDataToPrefs();
        return 1;
      }
      return 0;
    }
    final db = await instance.database;
    return await db.update(
      'skills',
      skill.toMap(),
      where: 'id = ?',
      whereArgs: [skill.id],
    );
  }

  /// Delete: Menghapus data skill berdasarkan ID.
  Future<int> deleteSkill(int id) async {
    if (kIsWeb) {
      await _loadWebDataFromPrefs();
      _webSkills.removeWhere((s) => s.id == id);
      _webResources.removeWhere((r) => r.skillId == id);
      await _saveWebDataToPrefs();
      return 1;
    }
    final db = await instance.database;
    return await db.delete('skills', where: 'id = ?', whereArgs: [id]);
  }

  // ==========================================
  // CRUD UNTUK TABEL RESOURCES
  // ==========================================

  /// Create: Menambahkan resource/referensi materi baru.
  Future<int> insertResource(Resource resource) async {
    if (kIsWeb) {
      await _loadWebDataFromPrefs();
      final newId = _webIdCounter++;
      final newRes = Resource(
        id: newId,
        userId: resource.userId,
        skillId: resource.skillId,
        title: resource.title,
        url: resource.url,
        description: resource.description,
        category: resource.category,
        status: resource.status,
        createdAt: resource.createdAt,
      );
      _webResources.add(newRes);
      await _saveWebDataToPrefs();
      return newId;
    }
    final db = await instance.database;
    return await db.insert('resources', resource.toMap());
  }

  /// Read: Mengambil semua data resource materi milik user aktif.
  Future<List<Resource>> getAllResources(int? userId) async {
    if (kIsWeb) {
      await _loadWebDataFromPrefs();
      final filtered = _webResources.where((r) => r.userId == userId).toList();
      filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return filtered;
    }
    final db = await instance.database;
    final result = await db.query(
      'resources',
      where: 'userId = ?',
      whereArgs: [userId],
      orderBy: 'createdAt DESC',
    );
    return result.map((json) => Resource.fromMap(json)).toList();
  }

  /// Read: Mengambil data resource materi yang terkait dengan keahlian (skill) tertentu milik user aktif.
  Future<List<Resource>> getResourcesBySkillId(int skillId, int? userId) async {
    if (kIsWeb) {
      await _loadWebDataFromPrefs();
      final filtered = _webResources.where((r) => r.skillId == skillId && r.userId == userId).toList();
      filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return filtered;
    }
    final db = await instance.database;
    final result = await db.query(
      'resources',
      where: 'skillId = ? AND userId = ?',
      whereArgs: [skillId, userId],
      orderBy: 'createdAt DESC',
    );
    return result.map((json) => Resource.fromMap(json)).toList();
  }

  /// Update: Memperbarui data resource materi.
  Future<int> updateResource(Resource resource) async {
    if (kIsWeb) {
      await _loadWebDataFromPrefs();
      final idx = _webResources.indexWhere((r) => r.id == resource.id);
      if (idx != -1) {
        _webResources[idx] = resource;
        await _saveWebDataToPrefs();
        return 1;
      }
      return 0;
    }
    final db = await instance.database;
    return await db.update(
      'resources',
      resource.toMap(),
      where: 'id = ?',
      whereArgs: [resource.id],
    );
  }

  /// Delete: Menghapus data resource materi berdasarkan ID.
  Future<int> deleteResource(int id) async {
    if (kIsWeb) {
      await _loadWebDataFromPrefs();
      _webResources.removeWhere((r) => r.id == id);
      await _saveWebDataToPrefs();
      return 1;
    }
    final db = await instance.database;
    return await db.delete('resources', where: 'id = ?', whereArgs: [id]);
  }

  /// Menutup database jika tidak digunakan lagi (misalnya untuk pengujian).
  Future close() async {
    if (kIsWeb) return;
    final db = await instance.database;
    db.close();
  }
}
