# 🚀 SmartDrop

> **Aplikasi E-Commerce dengan Live Tracking & AI Customer Service**

SmartDrop adalah aplikasi mobile e-commerce berbasis **Flutter** dan **Firebase** yang menyediakan pengalaman belanja lengkap mulai dari browsing produk, checkout multi-metode pembayaran, hingga pelacakan pengiriman secara real-time di peta interaktif. Dilengkapi dengan AI chatbot berbasis **Google Gemini** untuk layanan pelanggan otomatis.

---

## 📋 Daftar Isi

- [Fitur Utama](#-fitur-utama)
- [Screenshot Alur Aplikasi](#-screenshot-alur-aplikasi)
- [Tech Stack](#-tech-stack)
- [Arsitektur Sistem](#-arsitektur-sistem)
- [Prasyarat](#-prasyarat)
- [Instalasi & Konfigurasi](#-instalasi--konfigurasi)
- [Menjalankan Aplikasi](#-menjalankan-aplikasi)
- [Struktur Proyek](#-struktur-proyek)
- [Konfigurasi Firebase](#-konfigurasi-firebase)
- [Variabel Lingkungan](#-variabel-lingkungan)
- [Dokumentasi Lanjutan](#-dokumentasi-lanjutan)
- [Kontributor](#-kontributor)

---

## ✨ Fitur Utama

### 🛒 Pembeli (Buyer)
- **Dashboard Produk** — Banner promosi, kategori, deal of the day, trending, new arrivals
- **Pencarian Cerdas** — Filter kategori, rentang harga, sorting multi-kriteria
- **Keranjang & Checkout** — 6 metode pembayaran (VISA, PayPal, Maestro, Apple Pay, COD, QRIS)
- **Wishlist** — Simpan produk favorit dengan satu tap
- **Live Tracking** — Peta real-time posisi kurir, rute OSRM, estimasi waktu kedatangan
- **Riwayat Pesanan** — Status 4 tahap: Ordered → Shipped → In Transit → Delivered
- **Pelaporan Masalah** — Form laporan dengan 5 kategori masalah
- **6 Preset Tema** — Amber, Teal, Indigo, Rose, Emerald, Slate + Dark Mode

### 🏪 Penjual (Seller)
- **Manajemen Produk** — CRUD lengkap: tambah, edit, hapus produk dengan upload gambar
- **Dashboard Pesanan** — Daftar pesanan masuk secara real-time
- **Simulasi Pengiriman** — Rute otomatis via OSRM dengan animasi posisi kurir
- **Update Status** — Kontrol status: Start Delivery → In Transit → Arrived → Delivered

### 🔧 Admin
- **Dashboard Statistik** — Total user, produk, pendapatan, pesanan, dan grafik pertumbuhan
- **CRUD Produk & Banner** — Kelola seluruh konten yang tampil di dashboard buyer
- **Manajemen Pengguna** — Lihat, edit role, dan hapus akun
- **Laporan & Moderasi** — Review laporan masalah (Pending → Investigating → Resolved)
- **Promosi Marketing** — Deals of the Day, Trending, Discount, Special Offers, Sponsored
- **Kalender Acara** — Jadwalkan event promosi dengan visual marker

### 🤖 AI Customer Service
- **Google Gemini 2.5 Flash** — Chatbot AI yang memahami konteks SmartDrop
- **Speech-to-Text** — Input suara untuk bertanya ke AI
- **Suggested Questions** — Pertanyaan cepat yang sering ditanyakan
- **Fallback Mode** — Simulasi offline jika API key tidak tersedia

---

## 🖥 Tech Stack

| Layer | Teknologi |
|---|---|
| **Frontend** | Flutter 3.x (Dart) |
| **Authentication** | Firebase Auth (Email/Password, Google Sign-In) |
| **Database** | Cloud Firestore (NoSQL, real-time sync) |
| **AI** | Google Gemini 2.5 Flash API |
| **Maps** | FlutterMap + CARTO Tiles + OSRM Routing |
| **Speech** | `speech_to_text` package |
| **State Management** | `StatefulWidget` + Firestore Streams |

---

## 🏗 Arsitektur Sistem

```
┌─────────────────────────────────────────────────────────────┐
│                    SmartDrop Flutter App                      │
├───────────────┬──────────────┬──────────────┬───────────────┤
│   Splash &    │    Buyer     │    Seller    │     Admin     │
│   Auth        │   Module     │    Module    │    Module     │
├───────────────┴──────────────┴──────────────┴───────────────┤
│   AI Module   │   Models     │   Services                   │
│   (Gemini)    │   (Data)     │   (Business Logic)           │
├─────────────────────────────────────────────────────────────┤
│                    Firebase SDK                              │
│   firebase_auth  │  cloud_firestore  │  google_sign_in      │
├─────────────────────────────────────────────────────────────┤
│                   External APIs                              │
│   Gemini AI  │  OSRM Routing  │  CARTO Map Tiles            │
└─────────────────────────────────────────────────────────────┘
```

---

## 📝 Prasyarat

Sebelum memulai, pastikan perangkat Anda telah terinstal:

| Software | Versi Minimum | Perintah Cek |
|---|---|---|
| **Flutter SDK** | 3.11.5+ | `flutter --version` |
| **Dart SDK** | 3.11.5+ | `dart --version` |
| **Android Studio / VS Code** | Terbaru | — |
| **Android SDK** | API 21+ (Android 5.0) | `sdkmanager --list` |
| **Git** | 2.x+ | `git --version` |
| **Firebase CLI** | Terbaru | `firebase --version` |
| **Node.js** (untuk Firebase CLI) | 18+ | `node --version` |

---

## ⚙ Instalasi & Konfigurasi

### 1. Clone Repository

```bash
git clone https://github.com/Ryuzxy/PBM_TA.git
cd PBM_TA/frontend
```

### 2. Install Dependencies

```bash
flutter pub get
```

### 3. Konfigurasi Firebase

Proyek ini sudah memiliki file `firebase_options.dart` yang ter-generate. Jika Anda ingin menggunakan Firebase project sendiri:

```bash
# Install Firebase CLI & FlutterFire CLI
npm install -g firebase-tools
dart pub global activate flutterfire_cli

# Login ke Firebase
firebase login

# Generate konfigurasi baru
flutterfire configure
```

### 4. Konfigurasi API Key Gemini

Buat file `assets/public/.env` dengan isi:

```env
GEMINI_API_KEY=your_gemini_api_key_here
```

> **Catatan**: Dapatkan API key dari [Google AI Studio](https://aistudio.google.com/app/apikey). Jika tidak dikonfigurasi, fitur AI chatbot akan menggunakan mode simulasi.

### 5. Konfigurasi Android

Pastikan file `android/app/build.gradle` memiliki `minSdkVersion 21` atau lebih tinggi.

Tambahkan permission berikut di `android/app/src/main/AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION"/>
<uses-permission android:name="android.permission.CAMERA"/>
<uses-permission android:name="android.permission.RECORD_AUDIO"/>
```

---

## 🚀 Menjalankan Aplikasi

### Mode Development

```bash
cd frontend
flutter run
```

### Build APK (Release)

```bash
flutter build apk --release
```

APK hasil build berada di: `frontend/build/app/outputs/flutter-apk/app-release.apk`

### Build App Bundle (Play Store)

```bash
flutter build appbundle --release
```

---

## 📁 Struktur Proyek

```text
PBM_TA/
├── frontend/                        # Aplikasi Flutter
│   ├── lib/
│   │   ├── main.dart                # Entry point (Firebase init)
│   │   ├── firebase_options.dart    # Konfigurasi Firebase
│   │   │
│   │   ├── Splash/                  # 4 Splash screen + Get Started
│   │   ├── Login/                   # Sign In, Sign Up, Forgot Password
│   │   ├── Buyer/                   # Modul Pembeli
│   │   │   ├── dashboard/           # Home, Detail, Search, Wishlist, Orders, Tracking
│   │   │   └── chekout/             # Cart, Checkout, Payment, Confirm, Success
│   │   ├── Seller/                  # Dashboard seller + CRUD produk
│   │   ├── Admin/                   # Dashboard admin multi-tab + marketing
│   │   ├── AI/                      # AI Chatbot (Gemini)
│   │   ├── Models/                  # Product, Category, Banner models
│   │   └── Services/               # FirestoreService, AuthService, ThemeManager
│   │
│   ├── assets/public/.env           # API keys
│   └── pubspec.yaml                 # Dependencies
│
├── firestore.rules                  # Aturan keamanan Firestore
├── firestore.indexes.json           # Indeks Firestore
├── API.md                           # Dokumentasi API lengkap
├── layouts.md                       # Spesifikasi kebutuhan & layout
└── README.md                        # Dokumen ini
```

---

## 🔥 Konfigurasi Firebase

### Firestore Collections

Aplikasi menggunakan **8 collection/subcollection** Firestore:

| Collection | Deskripsi |
|---|---|
| `users` | Profil pengguna (uid, email, role, alamat, koordinat) |
| `users/{uid}/cart` | Keranjang belanja per user |
| `users/{uid}/wishlist` | Daftar keinginan per user |
| `users/{uid}/orders` | Riwayat pesanan per user |
| `products` | Katalog produk (title, price, stock, flags) |
| `categories` | Kategori produk (name, imageUrl, order) |
| `banners` | Banner promosi (title, imageUrl, type, order) |
| `tracking` | Data pelacakan real-time (posisi GPS, status, rute) |
| `reports` | Laporan masalah dari pengguna |
| `settings` | Konfigurasi global aplikasi |

> Lihat [API.md](API.md) untuk dokumentasi lengkap schema, operasi CRUD, dan contoh data.

### Firestore Security Rules

File `firestore.rules` saat ini menggunakan aturan development (batas waktu). **Sebelum production**, perbarui aturan menjadi:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users: hanya pemilik atau admin
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
      allow read: if request.auth != null;
    }
    // Products: semua bisa baca, hanya seller/admin bisa tulis
    match /products/{productId} {
      allow read: if true;
      allow write: if request.auth != null;
    }
    // dst...
  }
}
```

---

## 🔐 Variabel Lingkungan

| Variabel | Lokasi | Deskripsi |
|---|---|---|
| `GEMINI_API_KEY` | `assets/public/.env` | API Key Google Gemini AI |

---

## 📖 Dokumentasi Lanjutan

| Dokumen | Isi |
|---|---|
| [API.md](API.md) | Dokumentasi lengkap semua API (Firebase Auth, Firestore CRUD, External REST API, Data Models, Business Flow) |
| [layouts.md](layouts.md) | Spesifikasi kebutuhan sistem, rancangan layout/wireframe, dan struktur file proyek |

---

## 👥 Kontributor

| Nama | Role |
|---|---|
| **Ryuzxy** | Full-Stack Developer |

---

## 📄 Lisensi

Proyek ini dibuat untuk keperluan akademik — **Proyek Berbasis Masalah (PBM) Tugas Akhir**.

---

<p align="center">
  Dibuat dengan ❤ menggunakan Flutter & Firebase
</p>
