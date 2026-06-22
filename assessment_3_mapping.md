# Pemetaan Pekerjaan Assessment 3 (Aplikasi Kairos)

Dokumen ini memetakan seluruh tugas dan pencapaian masing-masing anggota tim pengembang aplikasi Kairos (Hafizh, Afrisya, dan Johanes Darren) untuk memenuhi kriteria **Assessment 3 (Week 14 & 15)**.

Selain itu, dokumen ini juga mencatat integrasi dan perubahan *shared resources* (sumber daya bersama) yang perlu diketahui oleh seluruh anggota tim agar tidak terjadi kebingungan saat menggabungkan (*merge*) kode.

---

## 🎯 Kriteria Assessment 3
1. **Custom Widget**: Minimal 1 buah per anggota, harus memiliki fungsionalitas internal (bukan sekadar tampilan UI pasif).
2. **Art & Gesture**: Terdapat sentuhan seni (gambar/animasi) yang merespons gestur pengguna.
3. **External Libraries**: Menggunakan 3-5 library di luar SQLite & Shared Preferences.
4. **Theme & UX**: Tema tidak boleh sekadar CRUD sederhana; harus dipikirkan interaksi dan visualnya.

---

## 👨‍💻 1. Johanes Darren Yehuda (Modul Jurnal / Progress)
**Status:** ✅ Selesai 100%

### A. Pencapaian Assessment 3
*   **Custom Widget 1 (Art + Gesture):** `InteractiveDurationSlider`.
    *   *Art:* Menggunakan `CustomPainter` untuk menggambar busur indikator waktu (Circular Ring) dengan efek *glow*, *tick marks*, dan gradien.
    *   *Gesture:* Menggunakan `GestureDetector` (`onPanStart`, `onPanUpdate`) agar pengguna dapat melakukan *drag/swipe* memutar untuk menyetel durasi belajar. Dilengkapi getaran (*Haptic Feedback*).
*   **Custom Widget 2:** `ProgressHeatmapCalendar`.
    *   Menggunakan kalender interaktif untuk menampilkan intensitas belajar pengguna. Semakin sering belajar di hari tersebut, warnanya semakin pekat (Heatmap).
*   **External Libraries:**
    *   `fl_chart` (Grafik garis 7 hari).
    *   `table_calendar` (Fondasi kalender heatmap).
    *   `flutter_slidable` (Gestur hapus/selesai pada daftar jurnal).
    *   `lottie` (Animasi selebrasi konfeti saat tantangan selesai).
*   **Tema & UX:** Halaman diubah total menjadi 3 tab (Log, Tantangan, Analitik). Berubah dari sekadar daftar CRUD menjadi sistem gamifikasi yang menghitung *Streak* dan *Skill Focus*.

### B. Perubahan yang Memengaruhi Anggota Lain
*   **Dependencies (Penting):** Menambahkan 4 library baru ke `pubspec.yaml`. **Semua anggota harus menjalankan `flutter pub get` ulang** setelah menarik (*pull*) kode ini. Karena ada penambahan *plugin* native, **anggota tim wajib melakukan Cold Restart** (menutup IDE dan menjalankan ulang emulator).
*   **Integrasi dengan Modul Hafizh:** Modul Progress kini secara otomatis memanggil fungsi `skillProv.incrementSkillProgress()`. Ketika Darren menyelesaikan tantangan atau menambah durasi belajar, *progress bar* di Modul Keahlian milik Hafizh akan otomatis bertambah secara proporsional.

---

## 👨‍💻 2. Hafizh (Modul Keahlian / Skills)
**Status:** ✅ Selesai 100%

### A. Pencapaian Assessment 3
*   **Custom Widget (Art + Gesture):** `SkillHexagonRadar` (Radar Chart berbentuk heksagon) untuk menampilkan keseimbangan antar keahlian.
    *   *Art:* Menggunakan `CustomPainter` untuk menggambar jaring heksagon konsentris dengan 5 tingkatan persentase, daerah polygon dengan warna representatif, dot vertex, dan efek glow/halo di sekitar vertex yang sedang dipilih.
    *   *Gesture:* Menggunakan `GestureDetector` (`onPanStart`, `onPanUpdate`, `onTapDown`) agar radar kompetensi dapat diputar secara bebas (360 derajat) atau disentuh langsung pada ujung sumbunya untuk menampilkan detail penguasaan dengan Haptic Feedback (getaran selection click).
*   **Art & UX/Animasi:**
    *   Menggunakan animasi masuk (scale-up) transisi halus berbasis `AnimationController` & `CurvedAnimation` (`Curves.easeOutBack`) saat inisiasi halaman.
    *   Menyediakan dashboard statistik dengan `AnimatedCrossFade` untuk beralih antara visual radar chart heksagon dan visual proporsi distribusi kompetensi.
*   **External Libraries:**
    *   Mendaur ulang (*reuse*) library `flutter_slidable` untuk memberikan gestur geser hapus dan edit pada baris kategori keahlian di mode tampilan List.
    *   Menggunakan `google_fonts` untuk menerapkan tipografi premium (Poppins) pada judul halaman dan label widget kustom.

### B. Integrasi dengan Darren (Modul Progress)
*   **Fungsi `incrementSkillProgress()`**: Logika fungsi `incrementSkillProgress` di `SkillProvider` dipertahankan sepenuhnya dan siap dipanggil oleh tantangan harian di Modul Jurnal milik Darren.
*   **Kolom `colorValue`**: Kolom warna dari `SkillCategory` tetap tersimpan utuh di database SQLite sehingga modul Darren dapat memanfaatkannya untuk mewarnai log aktivitas secara otomatis.

---

## 👩‍💻 3. Afrisya (Modul Materi / Learning Resource)
**Status:** Dalam Pengerjaan / Penyesuaian

### A. Rencana Pencapaian Assessment 3
Afrisya bertanggung jawab pada halaman pengelolaan referensi belajar dan tautan materi.
*   **Custom Widget (Saran):** Membuat `InteractiveLinkPreview` atau `ResourceBookmarkCard`.
*   **Art & Gesture (Saran):** Membuat animasi buku terbuka saat *card* ditekan (menggunakan `AnimatedBuilder` & `Transform`), atau gestur *Double Tap* untuk memfavoritkan (*bookmark*) materi dengan animasi *Love/Star*.
*   **External Libraries:** Menggunakan `url_launcher` (sudah ada) untuk membuka tautan web. Bisa menambahkan `webview_flutter` untuk membaca materi langsung di dalam aplikasi (tanpa keluar ke *browser* eksternal), atau `any_link_preview` untuk me-load gambar dan judul dari link artikel/YouTube secara otomatis.

### B. Perubahan dari Darren yang Perlu Diperhatikan Afrisya
*   Darren menambahkan *library* `flutter_slidable`. Afrisya sangat disarankan untuk ikut menggunakannya di daftar materi (`ListView` milik Afrisya) agar desain aplikasi Kairos seragam.
*   *File picker* yang digunakan Darren (`file_picker`) untuk mengunggah foto jurnal juga bisa digunakan Afrisya jika Afrisya ingin menambahkan fitur unggah *file* PDF untuk materi lokal.

---

## ⚠️ Peringatan Penting Saat Penggabungan Kode (Git Merge)

> [!WARNING]
> **Kepada Hafizh & Afrisya:**
> Ketika kalian melakukan `git pull` dari cabang (branch) milik Johanes Darren, perhatikan hal berikut:
> 1. Jangan melakukan *overwrite* sepihak pada `pubspec.yaml`. Jika ada konflik, pastikan `fl_chart`, `table_calendar`, `flutter_slidable`, dan `lottie` milik Darren tetap ada.
> 2. Jangan mengubah secara drastis `lib/providers/progress_provider.dart` atau `lib/screens/progress_screen.dart` karena file tersebut telah diuji lolos `dart analyze` untuk kriteria Assessment 3 Darren.
> 3. Wajib menyalakan **Developer Mode** di Windows agar *symlink* untuk *library* Flutter tidak gagal saat menjalankan `flutter pub get`.

---
**Kesimpulan:** Aplikasi Kairos kini bukan lagi sekadar CRUD. Modul Jurnal (Darren) telah menetapkan standar gamifikasi dan visual. Hafizh dan Afrisya didorong untuk mengimplementasikan *Custom Widget* dengan kualitas visual serupa agar aplikasi Kairos terasa premium dan konsisten secara keseluruhan.
