/// Model untuk kategori keahlian (Skill Category)
/// Digunakan untuk mengelompokkan keterampilan yang dilacak.
class SkillCategory {
  final int? id; // ID unik (auto-increment di SQLite)
  final int? userId; // ID Pengguna pemilik (null berarti kategori global default)
  final String name; // Nama kategori (misal: "Pemrograman", "Olahraga")
  final String icon; // Nama atau identifier ikon (misal: "code", "fitness_center")
  final int colorValue; // Nilai warna dalam bentuk integer ARGB (misal: 0xFF4CAF50)

  SkillCategory({
    this.id,
    this.userId,
    required this.name,
    required this.icon,
    required this.colorValue,
  });

  /// Mengonversi objek [SkillCategory] menjadi [Map]
  /// Digunakan saat menyimpan data ke database SQLite.
  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'name': name,
      'icon': icon,
      'colorValue': colorValue,
    };
    if (id != null) {
      map['id'] = id;
    }
    if (userId != null) {
      map['userId'] = userId;
    }
    return map;
  }

  /// Membuat objek [SkillCategory] dari [Map]
  /// Digunakan saat mengambil data dari database SQLite.
  factory SkillCategory.fromMap(Map<String, dynamic> map) {
    return SkillCategory(
      id: map['id'] as int?,
      userId: map['userId'] as int?,
      name: map['name'] as String,
      icon: map['icon'] as String,
      colorValue: map['colorValue'] as int,
    );
  }
}
