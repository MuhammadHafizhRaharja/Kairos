import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/skill.dart';
import '../models/skill_category.dart';

/// Helper class untuk mengelola database SQLite menggunakan sqflite.
/// Menggunakan pola Singleton untuk memastikan hanya ada satu instance database yang aktif.
class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

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
      version: 1,
      onCreate: _createDB,
      onConfigure: _configureDB,
    );
  }

  /// Mengonfigurasi database saat dibuka.
  /// Sangat penting untuk mengaktifkan Foreign Key support di SQLite secara eksplisit.
  Future _configureDB(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
  }

  /// Membuat tabel-tabel database saat database pertama kali dibuat.
  Future _createDB(Database db, int version) async {
    // 1. Membuat tabel Kategori Keahlian (SkillCategories)
    await db.execute('''
      CREATE TABLE skill_categories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
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
        categoryId INTEGER NOT NULL,
        name TEXT NOT NULL,
        description TEXT NOT NULL,
        level INTEGER NOT NULL DEFAULT 1,
        progress REAL NOT NULL DEFAULT 0.0,
        createdAt TEXT NOT NULL,
        FOREIGN KEY (categoryId) REFERENCES skill_categories (id) ON DELETE CASCADE
      )
    ''');

    // 3. Memasukkan data awal (seed data) berupa beberapa kategori default agar UI tidak kosong saat pertama run.
    await _seedDefaultCategories(db);
  }

  /// Memasukkan data kategori default ke dalam database.
  Future _seedDefaultCategories(Database db) async {
    final defaultCategories = [
      SkillCategory(name: 'Pemrograman', icon: 'code', colorValue: 0xFF2196F3), // Biru
      SkillCategory(name: 'Kebugaran', icon: 'fitness_center', colorValue: 0xFF4CAF50), // Hijau
      SkillCategory(name: 'Bahasa', icon: 'translate', colorValue: 0xFFFF9800), // Jingga
      SkillCategory(name: 'Musik & Seni', icon: 'music_note', colorValue: 0xFF9C27B0), // Ungu
    ];

    for (var category in defaultCategories) {
      await db.insert('skill_categories', category.toMap());
    }
  }

  // ==========================================
  // CRUD UNTUK TABEL SKILL_CATEGORIES
  // ==========================================

  /// Create: Menambahkan kategori baru.
  Future<int> insertCategory(SkillCategory category) async {
    final db = await instance.database;
    return await db.insert('skill_categories', category.toMap());
  }

  /// Read: Mengambil semua data kategori dari database.
  Future<List<SkillCategory>> getAllCategories() async {
    final db = await instance.database;
    final result = await db.query('skill_categories', orderBy: 'name ASC');
    return result.map((json) => SkillCategory.fromMap(json)).toList();
  }

  /// Update: Memperbarui data kategori.
  Future<int> updateCategory(SkillCategory category) async {
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
    final db = await instance.database;
    return await db.insert('skills', skill.toMap());
  }

  /// Read: Mengambil semua data skill tanpa memandang kategori.
  Future<List<Skill>> getAllSkills() async {
    final db = await instance.database;
    final result = await db.query('skills', orderBy: 'createdAt DESC');
    return result.map((json) => Skill.fromMap(json)).toList();
  }

  /// Read: Mengambil semua skill yang berada di bawah kategori tertentu.
  Future<List<Skill>> getSkillsByCategoryId(int categoryId) async {
    final db = await instance.database;
    final result = await db.query(
      'skills',
      where: 'categoryId = ?',
      whereArgs: [categoryId],
      orderBy: 'name ASC',
    );
    return result.map((json) => Skill.fromMap(json)).toList();
  }

  /// Update: Memperbarui data skill.
  Future<int> updateSkill(Skill skill) async {
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
    final db = await instance.database;
    return await db.delete(
      'skills',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Menutup database jika tidak digunakan lagi (misalnya untuk pengujian).
  Future close() async {
    final db = await instance.database;
    db.close();
  }
}
