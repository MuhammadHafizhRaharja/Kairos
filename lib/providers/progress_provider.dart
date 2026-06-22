// ============================================================================
// MODUL: Jurnal & Progress (Pekerjaan: Johanes Darren Yehuda)
// FILE: progress_provider.dart
// DESKRIPSI: 
// File ini adalah "Otak" (State Management) dari Modul Jurnal dan Progress.
// Menggunakan arsitektur Provider (ChangeNotifier), file ini berfungsi memisahkan
// logika bisnis yang rumit (analisis data, perhitungan streak, operasi database) 
// dari tampilan UI. Setiap kali data berubah, `notifyListeners()` akan dipanggil
// agar UI otomatis me-render ulang bagian yang berubah.
// ============================================================================
import 'package:flutter/material.dart';
import '../data/database_helper.dart';
import '../data/preferences_helper.dart';
import '../models/progress_log.dart';
import '../models/challenge.dart';

class ProgressProvider extends ChangeNotifier {
  // Mengambil instansi tunggal (Singleton) dari DatabaseHelper agar akses data stabil.
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  // PreferencesHelper digunakan untuk menyimpan pengaturan lokal pengguna.
  final PreferencesHelper _prefsHelper = PreferencesHelper();

  // Variabel private untuk menyimpan status terkini di dalam memori (RAM).
  int? _currentUserId;
  List<ProgressLog> _logs = [];
  List<Challenge> _challenges = [];
  bool _isLoading = false;

  // Variabel pengaturan preferensi tampilan.
  double _fontSize = 14.0;
  String _viewMode = 'List';

  // Getter public agar variabel private di atas dapat dibaca oleh UI secara aman (Read-Only).
  int? get currentUserId => _currentUserId;
  List<ProgressLog> get logs => _logs;
  List<Challenge> get challenges => _challenges;
  bool get isLoading => _isLoading;
  double get fontSize => _fontSize;
  String get viewMode => _viewMode;

  /// [PENTING] Fungsi ini menghitung progress umum dari pengguna untuk UI animasi.
  /// Progress ini meningkat jika pengguna menyelesaikan tantangan atau menambah log.
  double get progressLogProgress {
    double progress = 0.3; // Basis awal
    if (_challenges.isNotEmpty) {
      // Menghitung rasio tantangan yang selesai
      final completed = _challenges.where((c) => c.isCompleted == 1).length;
      progress += (completed / _challenges.length) * 0.65;
    } else if (_logs.isNotEmpty) {
      progress += (_logs.length * 0.05);
    }
    // Dibatasi maksimal 0.95 (95%) agar bar tidak melebar terlalu ekstrim di UI.
    return progress.clamp(0.15, 0.95);
  }

  /// Mengatur ID Pengguna yang sedang login. 
  /// Sangat krusial karena semua query database akan difilter berdasarkan userId ini.
  Future<void> setUserId(int? userId) async {
    if (_currentUserId == userId) return;
    _currentUserId = userId;

    if (userId == null) {
      // Kosongkan memori jika logout.
      _logs = [];
      _challenges = [];
      notifyListeners();
    } else {
      _setLoading(true);
      try {
        await refreshData();
      } catch (e) {
        debugPrint('Error memuat data progress user: $e');
      } finally {
        _setLoading(false);
      }
    }
  }

  /// Memuat pengaturan awal (seperti ukuran font) saat aplikasi pertama kali dibuka.
  Future<void> loadInitialData() async {
    _setLoading(true);
    try {
      _fontSize = await _prefsHelper.getFontSize();
      _viewMode = await _prefsHelper.getViewMode();
      await refreshData();
    } catch (e) {
      debugPrint('Error saat memuat data awal progress: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Membungkus status loading dan memberitahu UI untuk menampilkan animasi memuat data.
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  /// Fungsi utama yang selalu dipanggil setelah ada operasi Tambah/Ubah/Hapus.
  /// Fungsi ini memastikan data di layar (UI) dan di Database (SQLite) selalu sinkron.
  Future<void> refreshData() async {
    if (_currentUserId == null) return;
    _logs = await _dbHelper.getAllProgressLogs(_currentUserId);
    _challenges = await _dbHelper.getAllChallenges(_currentUserId);
    notifyListeners(); // Memicu UI me-render ulang daftar log dan grafik.
  }

  // ==========================================
  // PROGRESS LOGS CRUD (Create, Read, Update, Delete)
  // Semua fungsi di bawah memanipulasi tabel ProgressLog di SQLite.
  // ==========================================
  Future<void> addProgressLog({
    int? skillId,
    required String title,
    String note = '',
    int durationMinutes = 0,
    required DateTime date,
    String? photoPath,
  }) async {
    final newLog = ProgressLog(
      userId: _currentUserId,
      skillId: skillId,
      title: title,
      note: note,
      durationMinutes: durationMinutes,
      date: date,
      photoPath: photoPath,
    );
    await _dbHelper.insertProgressLog(newLog);
    await refreshData();
  }

  Future<void> updateProgressLog(ProgressLog log) async {
    await _dbHelper.updateProgressLog(log);
    await refreshData();
  }

  Future<void> deleteProgressLog(int id) async {
    await _dbHelper.deleteProgressLog(id);
    await refreshData();
  }

  // ==========================================
  // CHALLENGES CRUD (Pembuatan dan Pengelolaan Tantangan Belajar)
  // ==========================================
  Future<void> addChallenge({
    int? skillId,
    required String title,
    String description = '',
    required DateTime targetDate,
  }) async {
    final newChallenge = Challenge(
      userId: _currentUserId,
      skillId: skillId,
      title: title,
      description: description,
      targetDate: targetDate,
    );
    await _dbHelper.insertChallenge(newChallenge);
    await refreshData();
  }

  Future<void> updateChallenge(Challenge challenge) async {
    await _dbHelper.updateChallenge(challenge);
    await refreshData();
  }

  Future<void> deleteChallenge(int id) async {
    await _dbHelper.deleteChallenge(id);
    await refreshData();
  }

  // ==========================================
  // PREFERENCES (Pengaturan Tampilan Lokal)
  // ==========================================
  Future<void> updateFontSize(double size) async {
    _fontSize = size;
    notifyListeners();
    await _prefsHelper.setFontSize(size);
  }

  Future<void> updateViewMode(String mode) async {
    _viewMode = mode;
    notifyListeners();
    await _prefsHelper.setViewMode(mode);
  }

  // ==========================================
  // ANALYTICS & GAMIFICATION (Fitur Utama Assessment 3)
  // Kumpulan fungsi di bawah mengubah data baris mentah dari SQLite
  // menjadi angka statistik yang digunakan oleh grafik, heatmap, dan streak.
  // ==========================================

  /// [PENTING] Menghitung "Streak" (Jumlah hari berturut-turut mengisi jurnal).
  /// Fungsi ini menerapkan sistem gamifikasi seperti aplikasi Duolingo.
  int calculateCurrentStreak() {
    if (_logs.isEmpty) return 0;

    final now = DateTime.now();
    // Menggunakan UTC untuk mengamankan perhitungan beda hari dari masalah
    // pembulatan waktu Daylight Saving Time (DST) atau pergeseran Timezone.
    final today = DateTime.utc(now.year, now.month, now.day);

    // Filter tanggal unik: Jika ada 5 log di hari yang sama, hitung sebagai 1 hari.
    // `.where` mengamankan perhitungan dengan mengabaikan log dari tanggal di masa depan.
    final uniqueDays = _logs
        .map((l) => DateTime.utc(l.date.year, l.date.month, l.date.day))
        .where((d) => !d.isAfter(today))
        .toSet()
        .toList()
      ..sort((a, b) => b.compareTo(a)); // Urutkan tanggal dari yang paling terbaru (descending).

    if (uniqueDays.isEmpty) return 0;

    final yesterday = today.subtract(const Duration(days: 1));

    // Syarat ketat Streak: Rantai harus tersambung mulai dari "Hari ini" atau minimal "Kemarin".
    // Jika tidak, berarti streak sudah putus (kembali ke 0).
    if (uniqueDays.first != today && uniqueDays.first != yesterday) return 0;

    int streak = 1;
    // Lakukan iterasi loop dari hari terbaru mundur ke belakang.
    for (int i = 1; i < uniqueDays.length; i++) {
      // Jika selisih antar tanggal berurutan adalah tepat 1 hari, tambahkan poin Streak.
      final diff = uniqueDays[i - 1].difference(uniqueDays[i]).inDays;
      if (diff == 1) {
        streak++;
      } else {
        // Jika selisihnya > 1 hari, artinya ada "hari bolos", maka loop dihentikan.
        break; 
      }
    }
    return streak;
  }

  /// Menghitung total jam belajar per keahlian khusus pada "Minggu Berjalan" (Senin-Minggu).
  Map<int?, double> getTotalHoursThisWeek() {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final weekStart = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);

    final Map<int?, double> hoursMap = {};
    for (var log in _logs) {
      final logDate = DateTime(log.date.year, log.date.month, log.date.day);
      if (logDate.isAfter(weekStart.subtract(const Duration(days: 1)))) {
        final key = log.skillId;
        hoursMap[key] = (hoursMap[key] ?? 0) + (log.durationMinutes / 60.0);
      }
    }
    return hoursMap;
  }

  /// [PENTING] Mengambil data aktivitas harian untuk Heatmap Kalender (Custom Widget).
  /// Mengembalikan struktur `Map<DateTime, int>`, contoh: {2026-06-17: 3 aktivitas}.
  Map<DateTime, int> getActivityMap() {
    final Map<DateTime, int> activityMap = {};
    for (var log in _logs) {
      final day = DateTime(log.date.year, log.date.month, log.date.day);
      // Jika hari yang sama ditemukan lagi, tambahkan nilainya +1.
      activityMap[day] = (activityMap[day] ?? 0) + 1;
    }
    return activityMap;
  }

  /// [PENTING] Menghitung total durasi belajar harian khusus untuk 7 hari terakhir mundur.
  /// Ini digunakan langsung sebagai sumber data pada Line Chart `fl_chart`.
  List<MapEntry<DateTime, double>> getLast7DaysDuration() {
    final now = DateTime.now();
    final List<MapEntry<DateTime, double>> result = [];

    // Looping persis 7 iterasi untuk mendapatkan tanggal hari H sampai H-6.
    for (int i = 6; i >= 0; i--) {
      final day = DateTime(now.year, now.month, now.day).subtract(Duration(days: i));
      double totalMinutes = 0;
      // Kumpulkan dan jumlahkan semua durasi menit yang sesuai dengan tanggal `day`.
      for (var log in _logs) {
        final logDay = DateTime(log.date.year, log.date.month, log.date.day);
        if (logDay == day) {
          totalMinutes += log.durationMinutes;
        }
      }
      result.add(MapEntry(day, totalMinutes));
    }
    return result;
  }

  /// Menyajikan rekapitulasi data Tantangan (Challenges) menjadi persentase.
  Map<String, int> getChallengeStats() {
    final completed = _challenges.where((c) => c.isCompleted == 1).length;
    final pending = _challenges.length - completed;
    return {'completed': completed, 'pending': pending, 'total': _challenges.length};
  }
}
