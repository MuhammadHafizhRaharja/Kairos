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
* **Konektivitas State Management (Otomatisasi Leveling):**
  Level Keahlian kini tidak diinput secara statis. Modul ini secara otomatis "mendengarkan" durasi belajar yang masuk dari Modul Jurnal milik Darren dan mengubahnya menjadi *Experience Points* (XP) untuk menaikkan level Keahlian secara algoritmik.
* **Custom Widget (Radar Chart Keseimbangan):**
  Visualisasi jaring laba-laba untuk melihat dominasi keahlian pengguna (mana yang sering dilatih dan mana yang tertinggal).
* **Gestur Manajemen Kategori (Swipe-to-Delete):**
  Menghapus kategori keahlian cukup dengan menggeser layar ke kiri (*Swipe Gesture*).
* **Library Tambahan (Progress Animasi):**
  Menggunakan *library* tambahan untuk menganimasikan perpindahan bar persentase level keahlian.

**🗣️ Catatan Penjelasan (Rincian Teknis & Alasan):**
> **1. Integrasi State Management (Fitur Utama):**
> *   Melalui pola *Provider State Management*, kami memastikan *Data Flow* (aliran data) terpusat. Ketika pengguna menyelesaikan tantangan "Pemrograman 60 Menit" di Modul Jurnal, Modul Keahlian akan menangkap data tersebut secara *real-time*. Fungsi `incrementSkillProgress()` akan memproses 60 menit tersebut menjadi rasio XP, menggerakkan *Progress Bar* keahlian pemrograman, dan bahkan memicu fungsi *Level Up* jika menembus angka 100%. Sinkronisasi database ini membuat Kairos terasa seperti aplikasi utuh.
> 
> **2. Radar Chart (Custom Widget & Art):**
> *   Daftar teks biasa tidak cukup untuk membandingkan seberapa seimbang keahlian seseorang. Kami menggunakan `CustomPainter` (Art) untuk menggambar grafik jaring laba-laba poligon. Ini adalah *Custom Widget* murni karena bentuk bangun datarnya dihitung menggunakan rumus Trigonometri Sin/Cos berdasarkan jumlah kategori keahlian dan persentase level masing-masing keahlian.
>
> **3. Gestur & Library (`flutter_slidable` & `percent_indicator`):**
> *   **Gestur:** Menggunakan gestur *Swipe* untuk menghapus Kategori. Selain mempercepat interaksi, *database* kami terkonfigurasi dengan fitur *Cascade Delete*. Artinya saat satu gestur *Swipe* dilakukan, seluruh keahlian dan materi referensi di bawah kategori tersebut akan ikut terhapus rapi.
> *   **Library:** Menggunakan library untuk animasi *Linear Progress Bar* agar saat XP keahlian bertambah dari Modul Jurnal, *user* bisa melihat indikator barnya berjalan mulus ke kanan, memberikan sensasi gamifikasi RPG yang sangat kental.

---

## SLIDE 6: Modul Referensi & Materi (Afrisya)
* **Aksesibilitas Pembelajaran Terpadu:**
  Membuka PDF dan video via `url_launcher`.
* **Interaksi & Gestur Pintar:**
  1. *Double Tap* (Ketuk Ganda) untuk *Bookmark* materi favorit.
  2. *Long Press* (Tekan Lama) pada Custom Widget untuk memunculkan pratinjau kartu.

**🗣️ Catatan Penjelasan (Rincian Teknis & Alasan):**
> **1. Gestur Intuitif (Gesture):**
> *   Kami meminjam kebiasaan pengguna dari Instagram (*Double Tap to Like*). Daripada mencari tombol kecil, *user* cukup mengetuk ganda pada modul materi untuk memfavoritkannya (*Bookmark*). Ini secara instan memicu transisi animasi pada ikon Bintang.
> *   Menggunakan gestur `LongPress` pada kartu materi untuk membuka efek pembesaran layar darurat (*Peek Preview*), mempercepat proses cek materi tanpa harus pindah halaman penuh.
>
> **2. `url_launcher` (Library):**
> *   Fitur ini mengomunikasikan aplikasi Kairos kami dengan sistem operasi Android (Intent) secara langsung, memastikan pengguna Kairos bisa belajar membaca artikel atau menonton *tutorial* eksternal dengan sangat mudah.

---

## SLIDE 7: Kesimpulan
* Kairos sepenuhnya **Merespons Gestur Fisik** (*Drag Rotasi*, *Swipe*, *Double Tap*, *Long Press*).
* Estetika Tinggi berkat algoritma **CustomPainter** murni (bukan gambar statis) dipadukan dengan **External Library** grafis.
* Fitur **Terintegrasi secara Utuh** (Keahlian otomatis merespons Jurnal aktivitas pengguna).
