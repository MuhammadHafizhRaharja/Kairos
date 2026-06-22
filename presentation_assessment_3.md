# Draf Presentasi Kairos - Assessment 3 (Beserta Catatan Penjelasan Detail)

Berikut adalah susunan teks per-slide, dilengkapi dengan **Catatan Penjelasan (Speaker Notes)** yang menjabarkan secara rinci alasan teknis penggunaan *library*, *gesture*, dan fitur untuk Anda sampaikan saat presentasi.

---

## SLIDE 1: Judul Utama
* **Judul:** Evaluasi Assessment 3 - Kairos App
* **Sub-judul:** Implementasi Gamifikasi, Custom Widget, dan Gestur Interaktif
* **Anggota:** Hafizh, Afrisya, Johanes Darren Yehuda

---

## SLIDE 2: Fokus Utama Assessment 3
* **Poin 1:** Pembuatan *Custom Widget* murni dengan *State* dan fungsionalitas logika.
* **Poin 2:** Penerapan sentuhan *Art* (`CustomPainter`) & *Gesture* (Swipe/Drag/Double Tap).
* **Poin 3:** Integrasi 4 *External Libraries* tambahan di luar komponen bawaan.
* **Poin 4:** Merubah paradigma aplikasi "CRUD Biasa" menjadi "Dashboard Dinamis".

**🗣️ Catatan Penjelasan (Untuk Presenter):**
> "Di Assessment 3 ini, tujuan utama kelompok kami adalah *menghidupkan* aplikasi. Kami tidak lagi menggunakan widget bawaan yang kaku. Kami melukis komponen kami sendiri, menangkap gerakan jari pengguna secara langsung, dan memastikan setiap data di modul anggota satu memengaruhi modul anggota lainnya. Kami juga memasukkan unsur psikologis (gamifikasi) agar aplikasi terasa *rewarding*."

---

## SLIDE 3: Modul Jurnal & Progress (Johanes Darren - Bagian 1)
* **Custom Widget 1: Interactive Duration Slider**
  Mengatur waktu belajar menggunakan cincin (*ring*) yang bisa diputar dengan gestur jari.
* **Custom Widget 2: Progress Heatmap Calendar**
  Visualisasi kalender peta panas (*heatmap*) untuk melihat rekam jejak intensitas harian.

**🗣️ Catatan Penjelasan (Rincian Teknis & Alasan):**
> **1. Interactive Slider (Art & Gesture):**
> *   **Art:** Kami menggunakan kelas `CustomPainter` untuk melukis lingkaran murni bergradien warna menggunakan Canvas API. Ini bukan gambar statis.
> *   **Gesture & Fitur:** Daripada meminta *user* mengetik angka menit di *keyboard* (membosankan), kami menggunakan `GestureDetector` (`onPanUpdate`). Sistem menghitung sudut sentuhan jari (*drag*) terhadap titik tengah lingkaran dengan rumus matematika Trigonometri (Atan2), lalu mengubahnya menjadi nilai menit (0-120 menit). Ini memberi sensasi fisik seperti memutar kenop radio asli.
>
> **2. Heatmap Calendar:**
> *   **Fitur:** Meniru fitur visual "GitHub Commit History". Semakin lama *user* belajar di hari itu, semakin gelap kotak kalendernya. Ini menciptakan efek gamifikasi "berantai" yang membuat pengguna tidak ingin memutus rantai belajarnya (*streak*).

---

## SLIDE 4: Modul Jurnal & Progress (Johanes Darren - Bagian 2)
* **Gamifikasi & UX Baru:**
  Layar dipecah menjadi 3 Tab (Log, Tantangan, Analitik) dengan transisi animasi *slide-up* dan *fade*.
* **Penggunaan External Libraries:**
  1. `fl_chart`: Grafik garis analitik mingguan.
  2. `flutter_slidable`: Gestur geser-hapus.
  3. `lottie`: Animasi konfeti JSON.

**🗣️ Catatan Penjelasan (Rincian Teknis & Alasan):**
> **Penggunaan Library & Gestur Tambahan:**
> *   **`fl_chart` (Library):** Kami butuh grafik interaktif yang bisa disentuh untuk melihat detail menit per harinya.
> *   **`flutter_slidable` (Library & Gesture):** Menggunakan gestur usap/geser (*Swipe Left/Right*) pada daftar aktivitas untuk langsung menyelesaikan tantangan atau menghapus data tanpa perlu menekan tombol lambat.
> *   **`lottie` (Library & Art):** Memutar animasi vektor ringan (Konfeti) ketika tantangan terpenuhi. Fitur ini memicu hormon dopamin (*reward system*) bagi pengguna, mencegah aplikasi terasa seperti sekadar alat pencatat biasa.

---

## SLIDE 5: Modul Keahlian (Hafizh)
* **Custom Widget 1 — `SkillHexagonRadar`** *(CustomDrawing + Gesture)*
  Grafik radar heksagon dilukis murni dari `CustomPainter` (*Canvas API*), bisa diputar 360° dengan *Drag Gesture* dan disentuh untuk memilih sumbu kompetensi (*Haptic Feedback*).
* **Custom Widget 2 — `InteractiveProgressCard`** *(Gesture)*
  Kartu keahlian yang merespons geseran jari secara horizontal untuk mengubah *progress bar* XP secara langsung di layar.
* **Gesture (5 Jenis Selain Tap):**
  *Drag Horizontal* (ubah XP), *Drag Rotasi/Pan* (putar radar), *Swipe* (hapus/edit kategori), *Long Press* (opsi menu), *Double Tap* (tambah keahlian cepat).
* **4 External Libraries** *(di luar SQLite & SharedPreferences)*:
  `flutter_slidable`, `provider`, `intl`, `google_fonts`.

**🗣️ Catatan Penjelasan (Rincian Teknis & Alasan):**
> **1. Custom Widget & CustomDrawing:**
> *   Widget `SkillHexagonRadar` bukan sekadar tampilan statis; ia memiliki *state* internal (`_rotationAngle`, `_selectedIndex`) dan logika fungsionalitas sendiri. Grafik jaring heksagonnya dilukis secara murni menggunakan kelas `CustomPainter` dengan perhitungan koordinat Trigonometri (Sin/Cos) untuk memetakan 6 sumbu poligon, ditambah efek visual berupa *glow/halo* (`MaskFilter.blur`) pada titik vertex yang aktif.
> *   Widget `InteractiveProgressCard` juga memiliki *state* internal lengkap (`_localProgress`, `_localLevel`, `_isDragging`, `_isExpanded`). Ia menggunakan `GestureDetector` dengan `onHorizontalDragUpdate` yang menghitung perpindahan piksel relatif terhadap lebar layar untuk mengubah nilai XP secara presisi. Ketika nilai menembus 100%, sistem otomatis menaikkan level dan memicu animasi `TweenAnimationBuilder` dengan `Curves.elasticOut` serta getaran *Haptic Feedback*.
>
> **2. Gesture Selain Tap:**
> *   Modul ini mengimplementasikan 5 variasi gestur selain *Tap*: (a) **Drag Horizontal** pada *progress bar* untuk mengubah XP, (b) **Pan/Rotasi** pada radar untuk memutar grafik heksagon 360 derajat, (c) **Swipe Left/Right** via `flutter_slidable` dan `Dismissible` untuk menghapus/mengedit kategori dan keahlian, (d) **Long Press** untuk memunculkan *Bottom Sheet* opsi, dan (e) **Double Tap** sebagai jalan pintas menambah keahlian baru tanpa membuka form lengkap.
>
> **3. Pemanfaatan 4 External Library:**
> *   **`provider`**: Menjadi tulang punggung *State Management* yang menghubungkan data durasi belajar dari Modul Jurnal (Darren) ke Modul Keahlian ini secara reaktif. Ketika pengguna mencatat aktivitas belajar, *progress bar* keahlian terkait langsung bergerak naik.
> *   **`flutter_slidable`**: Memberikan pengalaman gestur geser (*Swipe*) pada mode tampilan daftar kategori untuk aksi hapus dan edit yang gesit dan elegan.
> *   **`intl`**: Digunakan untuk memformat tanggal pembuatan keahlian (misal: "22 Jun 2026") pada kartu detail `InteractiveProgressCard` agar lebih *human-readable*.
> *   **`google_fonts`**: Menerapkan tipografi premium Poppins pada judul halaman dan label widget kustom, memberikan identitas visual yang berbeda dari font bawaan sistem.

---

## SLIDE 6: Modul Referensi & Materi (Afrisya)
* **Aksesibilitas Pembelajaran Terpadu:**
  Membuka PDF dan video via `url_launcher`.
* **Interaksi & Gestur Pintar:**
  1. *Double Tap* (Ketuk Ganda) untuk *Bookmark* materi favorit.
  2. *Long Press* (Tekan Lama) pada Custom Widget untuk memunculkan pratinjau kartu.

**🗣️ Catatan Penjelasan (Rincian Teknis & Alasan):**
> **1. Custom Widget (Art & Gesture):**
> *   **Art:** Kami mengimplementasikan `CustomPainter` murni untuk menggambar **Pita Pembatas Buku (Bookmark Ribbon)** pada sudut kartu. Warna pita ini bereaksi secara dinamis menyesuaikan status baca pengguna (Misalnya hijau jika sudah selesai dibaca). Ini membuktikan bahwa widget ini bukan sekadar UI statis.
> *   **Gesture:** Kami meminjam kebiasaan pengguna dari Instagram (*Double Tap to Like*). Daripada mencari tombol kecil, *user* cukup mengetuk ganda pada modul materi untuk memfavoritkannya (*Bookmark*). Ini secara instan memicu transisi animasi pada ikon Bintang.
> *   Menggunakan gestur `LongPress` pada kartu materi untuk membuka efek pembesaran layar darurat (*Peek Preview*), mempercepat proses cek materi tanpa harus pindah halaman penuh.
>
> **2. `url_launcher` (Library):**
> *   Fitur ini mengomunikasikan aplikasi Kairos kami dengan sistem operasi Android (Intent) secara langsung, memastikan pengguna Kairos bisa belajar membaca artikel atau menonton *tutorial* eksternal dengan sangat mudah.

---

## SLIDE 7: Kesimpulan
* Kairos sepenuhnya **Merespons Gestur Fisik** (*Drag Rotasi*, *Swipe*, *Double Tap*, *Long Press*).
* Estetika Tinggi berkat algoritma **CustomPainter** murni (bukan gambar statis) dipadukan dengan **External Library** grafis.
* Fitur **Terintegrasi secara Utuh** (Keahlian otomatis merespons Jurnal aktivitas pengguna).
