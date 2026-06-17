# Draf Presentasi Kairos - Assessment 3

Berikut adalah susunan per-slide untuk dipindahkan ke PowerPoint / Canva:

---

## SLIDE 1: Judul
**(Visual: Logo Kairos & Nama Anggota Kelompok)**
*   **Judul Utama:** Evaluasi Assessment 3 - Kairos App
*   **Sub-judul:** Implementasi Gamifikasi, Custom Widget, dan Gestur Interaktif
*   **Anggota:** Hafizh, Afrisya, Johanes Darren Yehuda

---

## SLIDE 2: Objektif Pembaruan (Apa yang Baru?)
**(Visual: Bullet points singkat)**
*   **Judul Slide:** Fokus Utama Assessment 3
*   **Poin 1:** Pembuatan *Custom Widget* mandiri yang bukan sekadar UI pasif.
*   **Poin 2:** Implementasi sentuhan *Art* (Gambar/CustomPainter) & *Gesture* (Swipe/Drag).
*   **Poin 3:** Penggunaan 4 *External Libraries* baru (di luar basis data bawaan).
*   **Poin 4:** Transisi dari "Aplikasi CRUD Kaku" menjadi "Aplikasi Interaktif yang Terhubung".

---

## SLIDE 3: Modul Progress - Johanes Darren (Bagian 1)
**(Visual: Screenshot / Screen Record ring interaktif waktu & kalender heatmap)**
*   **Judul Slide:** Modul Jurnal & Progress (Johanes Darren)
*   **Poin 1: Interactive Duration Slider (Custom Widget 1)**
    *   Memanfaatkan `CustomPainter` (Art) untuk membuat *ring* gradien yang bisa diputar.
    *   Memanfaatkan `GestureDetector` (Gesture) agar pengguna dapat menyetel waktu dengan cara di-*drag* melingkar, lengkap dengan efek getaran.
*   **Poin 2: Progress Heatmap Calendar (Custom Widget 2)**
    *   Mengolah kumpulan aktivitas log harian menjadi warna peta panas (*heatmap*).

---

## SLIDE 4: Modul Progress - Johanes Darren (Bagian 2)
**(Visual: Screenshot 3 Tab baru, Grafik Garis, & Animasi Lottie)**
*   **Judul Slide:** Eksternal Library & Gamifikasi
*   **Poin 1: Eksternal Libraries:** 
    *   Menggunakan `fl_chart` untuk grafik analitik mingguan.
    *   Menggunakan `flutter_slidable` untuk gestur geser-hapus log aktivitas.
    *   Menggunakan `lottie` untuk animasi selebrasi saat tantangan selesai.
*   **Poin 2: UX Perombakan Tab:** Layar Jurnal dipecah elegan menjadi 3 Tab (Log, Tantangan, Analitik) dengan animasi meluncur (*slide-up*) untuk interaksi yang responsif.

---

## SLIDE 5: Modul Keahlian - Hafizh
**(Visual: Screenshot koneksi Progress Bar Keahlian & Radar Chart jika ada)**
*   **Judul Slide:** Modul Keahlian (Hafizh)
*   **Poin 1: Terhubung Otomatis dengan Jurnal.** 
    *   Keahlian pengguna tidak lagi di-update manual secara statis. Modul Keahlian kini mengambil data durasi dan status penyelesaian tantangan langsung dari Modul Jurnal milik Darren.
*   **Poin 2: Visualisasi Keseimbangan (Radar/Custom Widget).** 
    *   Membantu pengguna melihat keseimbangan level antar-keahlian.
*   **Poin 3: Manajemen Geser Cepat.**
    *   Penggunaan gestur geser (*swipe*) untuk mengatur keahlian.

---

## SLIDE 6: Modul Materi - Afrisya
**(Visual: Screenshot daftar materi dengan interaksi visual/link preview)**
*   **Judul Slide:** Modul Referensi & Materi (Afrisya)
*   **Poin 1: Aksesibilitas Pembelajaran Terpadu.**
    *   Integrasi `url_launcher` untuk membuka tautan eksternal (Video/PDF) secara instan tanpa keluar aplikasi secara kaku.
*   **Poin 2: Link Preview & Gestur Pintar.**
    *   Menerapkan *Double Tap* (Ketuk Ganda) untuk menyimpan/bookmark materi bacaan secara instan (Gestur).
    *   Membuat *Custom Widget* untuk *card* materi yang reaktif saat ditekan lama (*Long Press*).

---

## SLIDE 7: Kesimpulan
**(Visual: Tiga pilar kesuksesan: Interaktif, Estetik, Integratif)**
*   **Judul Slide:** Kesiapan Assessment 3
*   **Poin 1:** Kairos kini merespons sentuhan pengguna dengan sangat baik (*Drag*, *Swipe*, *Double Tap*).
*   **Poin 2:** Tampilan tidak lagi "mentah" karena menggunakan gabungan library eksternal dan lukisan komponen buatan sendiri (CustomPainter).
*   **Poin 3:** Data antar-modul kini saling terhubung layaknya aplikasi modern profesional.
