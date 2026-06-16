/// Model untuk Sumber & Materi Belajar (Resource)
/// Digunakan untuk menyimpan tautan, referensi, dan materi belajar yang terintegrasi dengan skill tertentu.
class Resource {
  final int? id; // ID unik (auto-increment di SQLite)
  final int? userId; // ID Pengguna pemilik materi belajar ini
  final int? skillId; // ID Keahlian yang terhubung (opsional, nullable)
  final String
  title; // Judul materi (misal: "Dokumentasi Flutter", "Tips Clean Code")
  final String url; // Tautan/Link web materi
  final String description; // Deskripsi singkat atau catatan belajar
  final String
  category; // Kategori materi (misal: Video, Artikel, Buku, Dokumentasi, Lainnya)
  final int
  status; // Status membaca (0 = Belum Dibaca, 1 = Sedang Dibaca, 2 = Selesai)
  final String resourceType; // Jenis resource ('materi' atau 'referensi')
  final DateTime createdAt; // Tanggal ditambahkan

  Resource({
    this.id,
    this.userId,
    this.skillId,
    required this.title,
    required this.url,
    this.description = '',
    this.category = 'Lainnya',
    this.status = 0,
    this.resourceType = 'materi',
    required this.createdAt,
  });

  /// Menyalin objek Resource dengan beberapa modifikasi bidang
  Resource copyWith({
    int? id,
    int? userId,
    int? skillId,
    String? title,
    String? url,
    String? description,
    String? category,
    int? status,
    String? resourceType,
    DateTime? createdAt,
  }) {
    return Resource(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      skillId: skillId ?? this.skillId,
      title: title ?? this.title,
      url: url ?? this.url,
      description: description ?? this.description,
      category: category ?? this.category,
      status: status ?? this.status,
      resourceType: resourceType ?? this.resourceType,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Mengonversi objek [Resource] menjadi [Map]
  /// Digunakan saat menyimpan data ke database SQLite.
  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'title': title,
      'url': url,
      'description': description,
      'category': category,
      'status': status,
      'resourceType': resourceType,
      'createdAt': createdAt
          .toIso8601String(), // Menyimpan DateTime sebagai String format ISO 8601
    };
    if (id != null) {
      map['id'] = id;
    }
    if (userId != null) {
      map['userId'] = userId;
    }
    if (skillId != null) {
      map['skillId'] = skillId;
    }
    return map;
  }

  /// Membuat objek [Resource] dari [Map]
  /// Digunakan saat mengambil data dari database SQLite.
  factory Resource.fromMap(Map<String, dynamic> map) {
    return Resource(
      id: map['id'] as int?,
      userId: map['userId'] as int?,
      skillId: map['skillId'] as int?,
      title: map['title'] as String? ?? '',
      url: map['url'] as String? ?? '',
      description: map['description'] as String? ?? '',
      category: map['category'] as String? ?? 'Lainnya',
      status: map['status'] as int? ?? 0,
      resourceType: map['resourceType'] as String? ?? 'materi',
      createdAt: DateTime.parse(
        map['createdAt'] as String? ?? DateTime.now().toIso8601String(),
      ),
    );
  }
}
