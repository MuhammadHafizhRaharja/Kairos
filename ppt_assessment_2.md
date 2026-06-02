# Slide Presentasi Assesment 2: Kairos

File ini berisi draf konten slide presentasi untuk **Kairos: Personal Growth Tracker** yang dapat langsung Anda salin ke PowerPoint (PPT).

---

## Slide 1: Judul Proyek
* **Judul Utama:** Kairos: Personal Growth Tracker
* **Subjudul:** Aplikasi Manajemen Pengembangan Diri Berbasis Flutter
* **Deskripsi:** Dirancang untuk membantu pengguna memantau progres skill baru, mengelola materi pembelajaran, dan mengejar target secara sistematis.
* **Tim Pengembang (PPBL):**
  1. **Muhammad Hafizh Raharja** (Modul Skill)
  2. **Afrisya Dwiky Mauliddinka** (Modul Resource)
  3. **Johanes Darren Yehuda** (Modul Progress)

---

## Slide 2: Latar Belakang & Masalah
* **Masalah:**
  * Sulitnya melacak progres pembelajaran mandiri secara konsisten.
  * Referensi materi belajar sering tersebar dan tidak terorganisasi berdasarkan tingkat keahlian.
  * Kurangnya visualisasi dan pencatatan log harian untuk memantau grafik perkembangan.
* **Solusi Kairos:**
  * Wadah tersentralisasi untuk mengelompokkan keahlian berdasarkan kategori.
  * Fitur pelacakan sumber belajar terintegrasi dengan modul pembelajaran.
  * Pencatatan log aktivitas belajar harian dan tantangan target waktu.

---

## Slide 3: Teknologi & Arsitektur (Tech Stack)
* **Framework Utama:** Flutter & Dart (Material 3)
* **Basis Data Lokal:** SQLite via package `sqflite` (dengan Foreign Key constraints aktif)
* **State Management:** `Provider` (Reaktif dengan notifyListeners)
* **Penyimpanan Preferensi:** `Shared Preferences` (Penyimpanan data pengaturan persisten)
* **UI & Estetika:** Google Fonts (Outfit), Custom Widgets, Animasi Mikro, dan Gestur Responsif.
* **Web Demo Support:** In-memory fallback database terintegrasi SharedPreferences agar dapat dicoba langsung di platform Flutter Web tanpa crash SQLite.

---

## Slide 4: Pembagian Modul Tim & Fitur CRUD
Setiap anggota bertanggung jawab atas modul CRUD spesifik:
1. **Muhammad Hafizh Raharja (Modul Skill)**
   * CRUD Kategori Keahlian (`skill_categories`)
   * CRUD Detail Keahlian (`skills`)
2. **Afrisya Dwiky Mauliddinka (Modul Resource)**
   * CRUD Sumber Daya & Tautan Pembelajaran (`resources`)
3. **Johanes Darren Yehuda (Modul Progress)**
   * CRUD Catatan Harian (`progress_logs`)
   * CRUD Tantangan Target Keahlian (`challenges`)

---

## Slide 5: Skema Relasi Database SQLite
Menggunakan SQLite dengan integritas data (Foreign Keys & Cascading):
1. **users**: `id` (PK), `name`, `email` (Unique), `password`, `createdAt`, `photoPath`, `phone`
2. **skill_categories**: `id` (PK), `userId`, `name`, `icon`, `colorValue`
3. **skills**: `id` (PK), `userId`, `categoryId` (FK, `ON DELETE CASCADE`), `name`, `description`, `level`, `progress`, `createdAt`
4. **resources**: `id` (PK), `userId`, `skillId` (FK, `ON DELETE CASCADE`), `title`, `url`, `description`, `category`, `status`, `resourceType`, `createdAt`
5. **progress_logs**: `id` (PK), `userId`, `skillId` (FK, `ON DELETE SET NULL`), `title`, `note`, `durationMinutes`, `date`, `photoPath`
6. **challenges**: `id` (PK), `userId`, `skillId` (FK, `ON DELETE SET NULL`), `title`, `description`, `targetDate`, `isCompleted`

---

## Slide 6: Implementasi Shared Preferences (6 Pengaturan)
Sesuai dengan ketentuan tugas (2 pengaturan persisten per orang):
* **Modul Skill (Hafizh):**
  * `userName` (Nama pengguna kustom yang tersimpan secara lokal)
  * `appTheme` (Pengaturan mode gelap / terang aplikasi)
* **Modul Resource (Afrisya):**
  * `defaultLang` (Pilihan bahasa aplikasi - Localization)
  * `isNotificationEnabled` (Status toggle notifikasi)
* **Modul Progress (Darren):**
  * `fontSize` (Ukuran skala font teks global di aplikasi)
  * `viewMode` (Mode tampilan UI - List atau Grid view)

---

## Slide 7: Manajemen State dengan Provider
Aplikasi menggunakan `MultiProvider` di `main.dart` untuk koordinasi state yang responsif:
* **AuthProvider:**
  * Mengelola sesi login, pendaftaran pengguna (Register), validasi email unik, dan logout.
* **SkillProvider:**
  * Mengelola state kategori, skill, serta resource materi belajar.
  * Mengakomodasi sinkronisasi tema gelap-terang secara instan.
* **ProgressProvider:**
  * Mengelola log aktivitas dan daftar tantangan.
  * Mengatur perubahan skala ukuran font global secara dinamis via `MediaQuery`.

---

## Slide 8: UI/UX & Interaksi Gestur
Untuk meningkatkan pengalaman pengguna, Kairos dilengkapi dengan:
* **Gestur Responsif:**
  * *Swipe-to-Action:* Menyelesaikan tantangan atau menghapus data secara cepat.
  * *Long-Press:* Membuka dialog edit/modifikasi item.
  * *Double-Tap:* Navigasi cepat atau melihat detil log.
* **Visual Progres Interaktif:**
  * Progress bar dinamis yang otomatis terisi berdasarkan pencatatan log belajar.
  * Fitur otomatis naik level (*level up* maks. 5) ketika progres skill mencapai 100%.

---

## Slide 9: Kesimpulan & Keunggulan
* **Integritas Data Kuat:** Penggunaan Foreign Keys SQLite memastikan data bersih (misalnya, jika kategori dihapus, seluruh skill di dalamnya ikut terhapus otomatis melalui *Cascade*).
* **UI/UX Modern:** Desain minimalis yang ramah pengguna dengan dukungan bahasa ganda (Indonesian/English) dan tema adaptif.
* **Performa Tinggi:** Penyimpanan offline lokal memastikan aplikasi tetap dapat diakses tanpa koneksi internet dengan manajemen state yang reaktif.
