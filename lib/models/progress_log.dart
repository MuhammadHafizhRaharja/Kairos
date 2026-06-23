/// Model data `ProgressLog` (Pekerjaan: Johanes Darren Yehuda).
/// Kelas ini merepresentasikan struktur blueprint satu buah catatan (jurnal) belajar yang
/// diinput oleh pengguna. Berfungsi sebagai jembatan antara aplikasi Flutter dan tabel SQLite.
class ProgressLog {
  /// ID unik (Primary Key) dari log ini di database SQLite.
  final int? id;
  /// ID pengguna yang memiliki log ini (Foreign Key ke tabel User).
  final int? userId;
  /// ID keahlian yang terkait dengan log ini (Foreign Key ke tabel Skill).
  /// Memungkinkan aplikasi melacak log ini ditujukan untuk keahlian apa.
  final int? skillId;
  /// Judul singkat atau nama kegiatan dari log jurnal ini.
  final String title;
  /// Catatan panjang atau deskripsi dari kegiatan belajar.
  final String note;
  /// Total durasi waktu belajar yang dihabiskan (dalam menit).
  /// Data ini sangat krusial karena akan dijumlahkan dan diproses oleh Provider
  /// untuk menaikkan Experience Point (XP) di modul Keahlian.
  final int durationMinutes;
  /// Tanggal pasti kapan kegiatan ini dilakukan.
  final DateTime date;
  /// Path lokasi foto bukti kegiatan belajar (opsional, jika pengguna melampirkan foto).
  final String? photoPath;

  /// Konstruktor utama pembentuk objek `ProgressLog`.
  /// `required` berarti parameter tersebut mutlak harus diisi saat pembuatan objek.
  ProgressLog({
    this.id,
    this.userId,
    this.skillId,
    required this.title,
    this.note = '', // Default nilai jika note tidak diisi adalah string kosong
    this.durationMinutes = 0, // Default durasi adalah 0
    required this.date,
    this.photoPath,
  });

  /// Fungsi `copyWith` sangat penting dalam konsep Immutability (ketetapan data).
  /// Berfungsi membuat "Kloningan" dari log saat ini, lalu mengubah bagian tertentu saja,
  /// tanpa merusak objek aslinya.
  ProgressLog copyWith({
    int? id,
    int? userId,
    int? skillId,
    String? title,
    String? note,
    int? durationMinutes,
    DateTime? date,
    String? photoPath,
  }) {
    // Kembalikan objek baru dengan menggabungkan nilai lama dan nilai baru
    return ProgressLog(
      id: id ?? this.id, // Jika `id` baru null, pakai `this.id` yang lama
      userId: userId ?? this.userId,
      skillId: skillId ?? this.skillId,
      title: title ?? this.title,
      note: note ?? this.note,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      date: date ?? this.date,
      photoPath: photoPath ?? this.photoPath,
    );
  }

  /// Fungsi `toMap()` mengubah objek class Dart ini menjadi bentuk `Map` (mirip JSON).
  /// Bentuk `Map` ini adalah satu-satunya bentuk data yang dipahami oleh Database SQLite
  /// sebelum disimpan ke dalam tabel `progress_logs`.
  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'title': title,
      'note': note,
      'durationMinutes': durationMinutes,
      // SQLite tidak mengerti format waktu DateTime dari Dart,
      // sehingga kita harus mengonversinya menjadi teks string ISO 8601 standar Internasional.
      'date': date.toIso8601String(),
      'photoPath': photoPath,
    };
    // Secara opsional tambahkan atribut ID hanya jika nilainya tidak null
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

  /// `factory fromMap()` adalah kebalikan dari `toMap()`.
  /// Berfungsi membaca data `Map` (yang ditarik dari SQLite) lalu menyusunnya
  /// kembali menjadi wujud objek `ProgressLog` yang utuh agar bisa digunakan oleh aplikasi.
  factory ProgressLog.fromMap(Map<String, dynamic> map) {
    return ProgressLog(
      id: map['id'] as int?, // Konversi eksplisit memastikan tipe data adalah Integer
      userId: map['userId'] as int?,
      skillId: map['skillId'] as int?,
      title: map['title'] as String? ?? '',
      note: map['note'] as String? ?? '',
      durationMinutes: map['durationMinutes'] as int? ?? 0,
      // Konversi balik teks ISO 8601 dari database menjadi format DateTime menggunakan DateTime.parse
      date: DateTime.parse(
        map['date'] as String? ?? DateTime.now().toIso8601String(),
      ),
      photoPath: map['photoPath'] as String?,
    );
  }
}
