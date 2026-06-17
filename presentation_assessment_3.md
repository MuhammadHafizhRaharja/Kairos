---
marp: true
theme: default
paginate: true
backgroundColor: #f8f9fa
---

# 🚀 Evaluasi Assessment 3: Kairos App
**Fokus Pembaruan: Custom Widgets, Art & Gestures, Eksternal Libraries, & Gamifikasi**

---

## 🎯 Objektif Pembaruan Assessment 3
Pada Assessment 3 ini, aplikasi **Kairos** tidak lagi sekadar aplikasi CRUD biasa. Kami berfokus pada **Gamifikasi** dan **Interaktivitas Visual**, dengan memenuhi kriteria:
1. **Custom Widget Murni** (1 per anggota) yang interaktif.
2. **Sentuhan Art & Gesture**, merespons gestur pengguna (*swipe*, *drag*).
3. **External Libraries**, implementasi 4+ *library* tambahan (di luar SQLite & SharedPrefs).
4. **Perombakan UI/UX**, meninggalkan desain daftar kaku menjadi *dashboard* dinamis.

---

## 👨‍💻 Modul Jurnal & Progress (Johanes Darren Yehuda)
*Fokus: Mengubah CRUD biasa menjadi Dashboard Analitik & Gamifikasi*

**Pembaruan Signifikan:**
*   **Perombakan Layout:** Pemisahan menjadi 3 Tab (*Log*, *Tantangan*, *Analitik*) dengan animasi transisi *fade & slide-up*.
*   **Custom Widget 1 (Art + Gesture):** `InteractiveDurationSlider`. Pengguna menyetel durasi belajar dengan gestur memutar (drag melingkar) pada sebuah *ring* yang digambar mandiri menggunakan `CustomPainter` (lengkap dengan gradien dan *haptic feedback*).
*   **Custom Widget 2:** `ProgressHeatmapCalendar`. Visualisasi intensitas belajar per hari dalam bentuk kalender suhu/warna.
*   **Selebrasi Interaktif:** Penambahan animasi konfeti (Lottie) saat target tertandingi.

**Libraries:** `fl_chart`, `table_calendar`, `flutter_slidable`, `lottie`.

---

## 👨‍💻 Modul Keahlian / Skills (Hafizh)
*Fokus: Visualisasi Keseimbangan Keahlian & Keterhubungan Data*

**Pembaruan Signifikan:**
*   **Otomatisasi Progress:** Modul Keahlian sekarang *terhubung langsung* dengan Modul Progress milik Darren. *Level* dan *Progress Bar* keahlian akan otomatis bertambah saat pengguna menginput durasi belajar atau menyelesaikan tantangan.
*   **Custom Widget Keseimbangan (Radar):** Penambahan visualisasi Radar/Spider Chart (menggunakan `CustomPainter`) agar pengguna tahu keahlian mana yang kurang dilatih.
*   **Gestur Manajemen:** Menerapkan gestur geser (menggunakan `flutter_slidable`) untuk menghapus atau mengelola keahlian dengan cepat tanpa harus masuk ke halaman edit.

---

## 👩‍💻 Modul Referensi & Materi (Afrisya)
*Fokus: Aksesibilitas Pembelajaran & Interaksi Cepat*

**Pembaruan Signifikan:**
*   **Akses Materi Terintegrasi:** Peningkatan integrasi *URL Launcher* untuk membuka materi (video/PDF web) secara mulus.
*   **Interactive Link Preview (Custom Widget):** *Card* materi tidak lagi statis. Saat materi ditekan atau ditahan (Long Press Gesture), akan memunculkan animasi pratinjau atau buku terbuka.
*   **Quick Bookmark (Gesture):** Pengguna dapat melakukan gestur *Double Tap* (Ketuk Ganda) pada *card* materi untuk memfavoritkan bacaan tersebut, ditandai dengan animasi ikon Bintang/Hati.

---

## 💡 Kesimpulan
Melalui perbaikan di **Assessment 3**, aplikasi Kairos telah berhasil melakukan loncatan besar:
✅ **Bukan lagi CRUD polos:** Data diolah menjadi Analitik interaktif (Grafik, Heatmap).
✅ **Merespons Tindakan Pengguna:** Penggunaan *Drag*, *Swipe*, dan *Double Tap*.
✅ **Komponen Buatan Sendiri:** Tidak bergantung pada komponen bawaan Flutter, melainkan menggambar sendiri (CustomPainter).
✅ **Sistem Terpadu:** Pekerjaan ketiga anggota kini saling memengaruhi (*Data Flow* dari Jurnal -> Keahlian).

**Siap Menghadapi Evaluasi!** 🚀
