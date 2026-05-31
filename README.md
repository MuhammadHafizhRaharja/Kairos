# Kairos: Personal Growth Tracker

**Kairos** adalah aplikasi manajemen pengembangan diri berbasis Flutter yang dirancang untuk membantu pengguna memantau progres *skill* baru, mengelola materi pembelajaran, dan mengejar target penguasaan keahlian secara sistematis.

Aplikasi ini dikembangkan untuk memenuhi tugas besar mata kuliah PPBL dengan fokus pada implementasi basis data lokal dan manajemen state.

---

## 🚀 Fitur Utama
* **Skill Management:** Mengelola daftar keahlian (skills) dan kategori pembelajaran.
* **Resource Tracking:** Menyimpan tautan materi, referensi, dan modul belajar yang terintegrasi.
* **Growth Log:** Mencatat log aktivitas harian atau tantangan mingguan untuk melacak perkembangan.
* **Interactive Progress:** Visualisasi progres pembelajaran melalui *custom widget*.
* **Intuitive Gesture:** Mendukung interaksi *swipe*, *long-press*, dan *double-tap* untuk navigasi cepat.

## 🛠 Tech Stack
* **Framework:** Flutter (Dart)
* **Database:** SQLite (`sqflite`)
* **State Management:** Provider
* **Persistent Storage:** Shared Preferences
* **Dependencies (Library):**
    * `sqflite`: Pengelolaan basis data lokal.
    * `shared_preferences`: Penyimpanan preferensi aplikasi.
    * `provider`: State management reaktif.
    * `intl`: Format waktu dan angka.
    * `google_fonts`: Tipografi aplikasi.

## 👥 Tim Pengembang
| Anggota | Modul Utama |
| :--- | :--- |
| **Muhammad Hafizh Raharja** | Skill |
| **Afrisya Dwiky Mauliddinka** | Resource |
| **Johanes Darren Yehuda** | Progress |

---

## 🏗 Struktur Database & Pembagian Modul

| Modul | Fungsionalitas CRUD | Shared Preferences (2 per orang) |
| :--- | :--- | :--- |
| **Skill** | CRUD Skill & Kategori | `userName`, `appTheme` |
| **Resource** | CRUD Materi & Referensi | `defaultLang`, `isNotificationEnabled` |
| **Progress** | CRUD Log Progress & Tantangan | `fontSize`, `viewMode` |