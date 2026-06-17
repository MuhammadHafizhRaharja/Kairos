# Draf Presentasi Kairos - Assessment 3

Berikut adalah susunan teks mentah per-slide untuk dipindahkan ke PowerPoint / Canva:

---

## SLIDE 1: Judul Utama
* **Judul:** Evaluasi Assessment 3 - Kairos App
* **Sub-judul:** Implementasi Gamifikasi, Custom Widget, dan Gestur Interaktif
* **Anggota:** Hafizh, Afrisya, Johanes Darren Yehuda
*(Saran Visual: Logo Kairos & Nama Anggota Kelompok di tengah layar)*

---

## SLIDE 2: Fokus Utama Assessment 3
* **Poin 1:** Pembuatan *Custom Widget* murni (bukan bawaan Flutter) yang interaktif.
* **Poin 2:** Sentuhan *Art* (Gambar/CustomPainter) & *Gesture* (Swipe/Drag).
* **Poin 3:** Penggunaan 4 *External Libraries* tambahan di luar database bawaan.
* **Poin 4:** Transisi dari "Aplikasi CRUD Kaku" menjadi "Aplikasi Dinamis yang Saling Terhubung".
*(Saran Visual: Gunakan bullet points atau ikon check-mark ✅ yang rapi)*

---

## SLIDE 3: Modul Jurnal & Progress (Johanes Darren - Bagian 1)
* **Custom Widget 1 (Interactive Duration Slider):**
  Menggunakan `CustomPainter` (Art) untuk menggambar *ring* waktu bergradien, dan `GestureDetector` (Gesture) agar *ring* bisa di-*drag* memutar layaknya kenop fisik (ditambah efek getaran).
* **Custom Widget 2 (Progress Heatmap Calendar):**
  Mengolah data ribuan aktivitas menjadi kalender *heatmap* untuk melihat intensitas belajar per harinya.
*(Saran Visual: Letakkan screenshot ring interaktif & kalender heatmap berdampingan)*

---

## SLIDE 4: Modul Jurnal & Progress (Johanes Darren - Bagian 2)
* **Gamifikasi & UX Baru:**
  Layar Jurnal dipecah elegan menjadi 3 Tab (Log, Tantangan, Analitik) dengan animasi meluncur (*slide-up*) saat diakses.
* **Penggunaan External Libraries:**
  1. `fl_chart` (Grafik garis analitik mingguan).
  2. `flutter_slidable` (Gestur geser-hapus yang cepat).
  3. `lottie` (Animasi selebrasi konfeti saat target selesai).
*(Saran Visual: Screenshot Tab Analitik yang menampilkan grafik garis dan streak)*

---

## SLIDE 5: Modul Keahlian (Hafizh)
* **Terhubung Secara Otomatis:**
  Level dan kemajuan *Progress Bar* pada daftar Keahlian kini tidak lagi diatur secara manual, melainkan otomatis membaca durasi log aktivitas dari Modul Jurnal (Pekerjaan Darren).
* **Visualisasi Keseimbangan (Custom Widget):**
  Penambahan visualisasi Radar Chart (*CustomPainter*) untuk menunjukkan keahlian mana yang mendominasi.
* **Manajemen Geser Cepat:**
  Penerapan gestur *swipe* untuk mengelola kategori.
*(Saran Visual: Screenshot halaman detail keahlian dengan radar chart)*

---

## SLIDE 6: Modul Referensi & Materi (Afrisya)
* **Aksesibilitas Pembelajaran Terpadu:**
  Integrasi library *url_launcher* yang mulus sehingga PDF dan video eksternal dapat terbuka instan layaknya fitur internal.
* **Interaksi & Gestur Pintar:**
  1. Gestur *Double Tap* (Ketuk Ganda) pada kartu materi untuk menyimpannya ke daftar Favorit (*Bookmark*).
  2. Kartu materi yang bisa ditekan lama (*Long Press*) untuk melihat pratinjau cepat (Custom Widget interaktif).
*(Saran Visual: Screenshot daftar materi dengan ikon bookmark)*

---

## SLIDE 7: Kesimpulan Keseluruhan
* Kairos kini sepenuhnya **Merespons Tindakan** (*Drag*, *Swipe*, *Double Tap*).
* Tampilan **Lebih Estetik** dengan gabungan efek animasi dan lukisan komponen (*CustomPainter*).
* **Sistem Terpadu**, data antar-modul saling memengaruhi (*Data Flow* berjalan secara harmonis).
*(Saran Visual: Tiga kotak berisi pilar kesuksesan: Interaktif, Estetik, Integratif)*
