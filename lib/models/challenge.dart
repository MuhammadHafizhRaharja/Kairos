/// Model data `Challenge` (Pekerjaan: Johanes Darren Yehuda).
/// Kelas ini mempresentasikan struktur "Tantangan" atau misi belajar yang
/// bisa dibuat oleh pengguna untuk meningkatkan keterlibatan (Gamifikasi).
class Challenge {
  /// ID unik (Primary Key) dari tantangan ini di database SQLite.
  final int? id;
  /// ID pengguna yang memiliki tantangan ini (Foreign Key).
  final int? userId;
  /// ID keahlian opsional jika tantangan ini ditujukan spesifik untuk keahlian tertentu.
  final int? skillId;
  /// Judul dari tantangan (contoh: "Belajar Flutter 10 Jam").
  final String title;
  /// Deskripsi rincian dari tantangan tersebut.
  final String description;
  /// Tenggat waktu (Deadline) kapan tantangan ini harus diselesaikan.
  final DateTime targetDate;
  /// Status penyelesaian: 0 = Belum Selesai, 1 = Sudah Selesai.
  /// (SQLite tidak mendukung tipe boolean secara native, sehingga menggunakan Integer).
  final int isCompleted;

  /// Konstruktor utama pembentuk objek `Challenge`.
  Challenge({
    this.id,
    this.userId,
    this.skillId,
    required this.title, // Judul wajib diisi
    this.description = '',
    required this.targetDate, // Tenggat waktu wajib diisi
    this.isCompleted = 0, // Secara default, saat dibuat tantangan belum selesai (0)
  });

  /// Fungsi `copyWith` untuk membuat kloning objek dengan perubahan sebagian field.
  /// Sangat berguna ketika kita hanya ingin mengubah status `isCompleted` dari 0 ke 1
  /// tanpa perlu mendefinisikan ulang seluruh field lainnya.
  Challenge copyWith({
    int? id,
    int? userId,
    int? skillId,
    String? title,
    String? description,
    DateTime? targetDate,
    int? isCompleted,
  }) {
    // Return objek baru dengan nilai yang ditimpa (jika ada nilai baru yang dimasukkan)
    return Challenge(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      skillId: skillId ?? this.skillId,
      title: title ?? this.title,
      description: description ?? this.description,
      targetDate: targetDate ?? this.targetDate,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  /// Mengonversi objek class ke tipe data Map agar bisa di-Insert ke tabel SQLite.
  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'title': title,
      'description': description,
      // Konversi format tanggal bawaan Dart menjadi String ISO 8601 agar dipahami SQLite
      'targetDate': targetDate.toIso8601String(),
      'isCompleted': isCompleted,
    };
    // Masukkan ID hanya jika tidak null (jika null, biarkan SQLite Auto-Increment)
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

  /// Mengonversi balik dari tipe data Map (hasil query SQLite) ke objek class utuh.
  factory Challenge.fromMap(Map<String, dynamic> map) {
    return Challenge(
      // Casting eksplisit `as int?` memastikan tipe datanya dibaca dengan benar
      id: map['id'] as int?,
      userId: map['userId'] as int?,
      skillId: map['skillId'] as int?,
      title: map['title'] as String? ?? '',
      description: map['description'] as String? ?? '',
      // Konversi balik dari teks String ISO 8601 ke objek DateTime Dart
      targetDate: DateTime.parse(
        map['targetDate'] as String? ?? DateTime.now().toIso8601String(),
      ),
      isCompleted: map['isCompleted'] as int? ?? 0,
    );
  }
}
