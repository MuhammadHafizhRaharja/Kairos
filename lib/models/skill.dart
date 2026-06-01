/// Model untuk Keahlian (Skill)
/// Digunakan untuk mencatat progres keterampilan individu yang terhubung ke suatu kategori.
class Skill {
  final int? id; // ID unik (auto-increment di SQLite)
  final int? userId; // ID Pengguna pemilik keahlian ini
  final int categoryId; // Foreign key yang menghubungkan ke tabel SkillCategory
  final String name; // Nama keahlian (misal: "State Management", "Tembakan Bebas")
  final String description; // Deskripsi detail keahlian
  final int level; // Tingkat kemahiran saat ini (misal: 1 s.d. 5)
  final double progress; // Persentase progres keahlian (rentang 0.0 s.d. 1.0)
  final DateTime createdAt; // Waktu pembuatan atau mulai melacak keahlian ini

  Skill({
    this.id,
    this.userId,
    required this.categoryId,
    required this.name,
    this.description = '',
    this.level = 1,
    this.progress = 0.0,
    required this.createdAt,
  });

  /// Menyalin objek Skill dengan beberapa modifikasi bidang
  Skill copyWith({
    int? id,
    int? userId,
    int? categoryId,
    String? name,
    String? description,
    int? level,
    double? progress,
    DateTime? createdAt,
  }) {
    return Skill(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      categoryId: categoryId ?? this.categoryId,
      name: name ?? this.name,
      description: description ?? this.description,
      level: level ?? this.level,
      progress: progress ?? this.progress,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Mengonversi objek [Skill] menjadi [Map]
  /// Digunakan saat menyimpan data ke database SQLite.
  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'categoryId': categoryId,
      'name': name,
      'description': description,
      'level': level,
      'progress': progress,
      'createdAt': createdAt.toIso8601String(), // Menyimpan DateTime sebagai String format ISO 8601
    };
    if (id != null) {
      map['id'] = id;
    }
    if (userId != null) {
      map['userId'] = userId;
    }
    return map;
  }

  /// Membuat objek [Skill] dari [Map]
  /// Digunakan saat mengambil data dari database SQLite.
  factory Skill.fromMap(Map<String, dynamic> map) {
    return Skill(
      id: map['id'] as int?,
      userId: map['userId'] as int?,
      categoryId: map['categoryId'] as int,
      name: map['name'] as String,
      description: map['description'] as String? ?? '',
      level: map['level'] as int? ?? 1,
      // SQLite menyimpan real sebagai double, num memastikan kompatibilitas konversi jika tipe data di map berupa int atau double
      progress: (map['progress'] as num?)?.toDouble() ?? 0.0,
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }
}
