# SmartDrop — Spesifikasi Kebutuhan, Rancangan Layout & Struktur Proyek

> **Versi**: 1.0.0  
> **Platform**: Flutter (Android/iOS)  
> **Backend**: Firebase (Authentication, Cloud Firestore)  
> **Terakhir Diperbarui**: Juni 2026

---

## I. Requirements (Spesifikasi Kebutuhan Sistem)

Sistem aplikasi ini dibangun menggunakan framework **Flutter** (Dart) untuk antarmuka pengguna dan ekosistem **Google Firebase** (Authentication, Cloud Firestore) untuk backend. Sistem menerapkan **Role-Based Access Control (RBAC)** dengan dua peran utama: **Buyer** dan **Admin**.

### 1. Kebutuhan Fitur Pembeli (Buyer)

| No | Fitur | Deskripsi |
|---|---|---|
| 1 | **Dashboard Produk** | Halaman utama menampilkan banner promosi, kategori, produk trending, deal of the day, dan new arrivals |
| 2 | **Pencarian Produk** | Pencarian real-time dengan filter kategori, rentang harga, dan sorting (relevance, harga, rating) |
| 3 | **Detail Produk** | Tampilan lengkap produk: gambar, deskripsi, harga, diskon, stok, lokasi seller, rating & review |
| 4 | **Keranjang Belanja (Cart)** | Manajemen item: tambah/hapus/update jumlah, peta lokasi seller, dan kalkulasi total harga |
| 5 | **Wishlist** | Daftar produk favorit dengan toggle dari halaman detail produk |
| 6 | **Checkout & Pembayaran** | Multi-metode pembayaran: VISA/Debit, PayPal, Maestro, Apple Pay, COD, dan QRIS (scan QR) |
| 7 | **Pelacakan Real-Time** | Peta interaktif menampilkan posisi kurir bergerak, rute jalan raya (OSRM), ETA, dan detail pesanan |
| 8 | **Riwayat Pesanan** | Daftar pesanan dengan status: Ordered → Shipped → In Transit → Delivered |
| 9 | **Profil & Pengaturan** | Edit profil, pilih alamat via peta, switch tema (6 preset), dan dark mode |
| 10 | **Laporan Masalah** | Form pelaporan dengan kategori: COD Di Luar Safe Zone, Masalah GPS, Penipuan, dll. |
| 11 | **AI Customer Service** | Chatbot berbasis Google Gemini AI dengan input suara (speech-to-text) |
| 12 | **Panel Seller** | Setiap buyer dapat menjadi seller: tambah/edit/hapus produk, kelola pesanan, simulasi pengiriman |

### 2. Kebutuhan Fitur Admin

| No | Fitur | Deskripsi |
|---|---|---|
| 1 | **Dashboard Ringkasan** | Statistik total pengguna, produk, pendapatan, pesanan, dan pertumbuhan per bulan |
| 2 | **Manajemen Produk** | CRUD produk: tambah, edit, hapus, dan toggle flag marketing (Deal, Trending, New Arrival) |
| 3 | **Manajemen Banner** | CRUD banner promosi untuk tampilan dashboard buyer |
| 4 | **Manajemen Laporan** | Review laporan masalah, ubah status: Pending → Investigating → Resolved |
| 5 | **Manajemen Pengguna** | Lihat, edit role, dan hapus akun pengguna |
| 6 | **Promosi & Marketing** | Kelola Deals of the Day, Trending Products, Discount, Special Offers, dan Sponsored items |
| 7 | **Kalender Acara** | Kalender built-in untuk mengelola event promosi (dengan visual marker) |
| 8 | **Profil Admin** | Edit profil admin: nama, foto, alamat |

### 3. Kebutuhan Non-Fungsional

| No | Aspek | Deskripsi |
|---|---|---|
| 1 | **Autentikasi** | Email/Password dan Google Sign-In; reset password via email |
| 2 | **Real-Time Sync** | Firestore Streams untuk pembaruan data real-time (produk, pesanan, tracking) |
| 3 | **Responsif** | Desain adaptif untuk berbagai ukuran layar mobile |
| 4 | **Tema Dinamis** | 6 preset tema warna + dark mode yang tersimpan di `SharedPreferences` |
| 5 | **Peta** | `FlutterMap` + CARTO tiles (light/dark) + OSRM routing |
| 6 | **AI** | Google Gemini 2.5 Flash dengan fallback mode simulasi |

---

## II. Rancangan Layout (Wireframe Implementasi)

### 1. Layar Onboarding (4 Halaman Splash + Get Started)

```
┌─────────────────────────┐
│      Logo SmartDrop      │
│                          │
│   [Ilustrasi Animasi]    │
│                          │
│   "Tagline Fitur Ke-N"   │
│                          │
│       ● ○ ○ ○            │
│                          │
│    [ Get Started → ]     │
└─────────────────────────┘
```

- 4 layar splash berisi ilustrasi dan deskripsi fitur utama
- Halaman "Get Started" dengan tombol navigasi ke Sign In / Sign Up

---

### 2. Layar Autentikasi

```
┌─────────────────────────┐      ┌─────────────────────────┐
│      SIGN IN             │      │      SIGN UP             │
│                          │      │                          │
│  ┌────────────────────┐  │      │  ┌────────────────────┐  │
│  │ 📧 Email           │  │      │  │ 📧 Email           │  │
│  └────────────────────┘  │      │  └────────────────────┘  │
│  ┌────────────────────┐  │      │  ┌────────────────────┐  │
│  │ 🔒 Password     👁  │  │      │  │ 🔒 Password     👁  │  │
│  └────────────────────┘  │      │  └────────────────────┘  │
│                          │      │  ┌────────────────────┐  │
│  Forgot Password?        │      │  │ 🔒 Confirm Pass  👁  │  │
│                          │      │  └────────────────────┘  │
│  ┌────────────────────┐  │      │                          │
│  │     LOGIN          │  │      │  ┌────────────────────┐  │
│  └────────────────────┘  │      │  │    REGISTER        │  │
│                          │      │  └────────────────────┘  │
│  ─── or continue with ── │      │                          │
│  ┌────────────────────┐  │      │  ─── or continue with ── │
│  │   🔵 Google        │  │      │  ┌────────────────────┐  │
│  └────────────────────┘  │      │  │   🔵 Google        │  │
│                          │      │  └────────────────────┘  │
│  Don't have account?     │      │  Already have account?   │
│  Sign Up                 │      │  Sign In                 │
└─────────────────────────┘      └─────────────────────────┘
```

- **Routing otomatis**: Email `@admin.com` → `AdminDashboard`, lainnya → `BuyerDashboard`
- Email `@admin.com` diblokir dari halaman Sign Up (hanya bisa dibuat via admin)

---

### 3. Layar Pembeli — Dashboard Utama

```
┌─────────────────────────────────────┐
│ 🔍 Search...        [📱 QR] [🛒]  │
├─────────────────────────────────────┤
│  ┌──────── Banner Carousel ──────┐  │
│  │  🖼 Promo / Special Offer     │  │
│  └───────────────────────────────┘  │
│                                     │
│  Categories: [👟][👗][👜][⌚][🧢]   │
│                                     │
│  ── Deal of the Day ──────────────  │
│  ┌──────┐ ┌──────┐ ┌──────┐        │
│  │🖼 $XX│ │🖼 $XX│ │🖼 $XX│        │
│  │ ★★★★ │ │ ★★★★ │ │ ★★★★ │        │
│  └──────┘ └──────┘ └──────┘        │
│                                     │
│  ── Trending ─────────────────────  │
│  ┌──────┐ ┌──────┐ ┌──────┐        │
│  │🖼 $XX│ │🖼 $XX│ │🖼 $XX│        │
│  └──────┘ └──────┘ └──────┘        │
│                                     │
│  ── New Arrivals ─────────────────  │
│  ┌──────┐ ┌──────┐ ┌──────┐        │
│  │🖼 $XX│ │🖼 $XX│ │🖼 $XX│        │
│  └──────┘ └──────┘ └──────┘        │
│                                     │
├─────────────────────────────────────┤
│ 🏠 Home │ ❤ Wishlist │ 🛒 Cart │ ⚙ │
└─────────────────────────────────────┘
```

**Komponen Dashboard:**
- **AppBar**: Search bar + tombol QR Scanner + Cart badge
- **Banner Carousel**: Slider banner promosi (dari collection `banners`)
- **Kategori**: Scroll horizontal ikon kategori (dari collection `categories`)
- **Produk Grid**: 3 section — Deal of the Day, Trending, New Arrivals
- **Bottom Navigation**: Home, Wishlist, Cart, Setting

---

### 4. Layar Pembeli — Detail Produk

```
┌─────────────────────────────────────┐
│  ← Back            ❤ Wishlist      │
├─────────────────────────────────────┤
│         ┌──────────────────┐        │
│         │                  │        │
│         │  🖼 Product Image │        │
│         │                  │        │
│         └──────────────────┘        │
│         ○ ● ○ (image dots)          │
│                                     │
│  Product Title                      │
│  ★★★★☆ (4.0) · 28 Reviews          │
│                                     │
│  Rp 350.000   ̶R̶p̶ ̶4̶5̶0̶.̶0̶0̶0̶  -22%   │
│                                     │
│  📍 Jakarta, DKI Jakarta           │
│  📦 Stock: 15 available             │
│                                     │
│  ── Select Size ──────────────────  │
│  [6UK] [7UK] [8UK] [9UK] [10UK]    │
│                                     │
│  ── Quantity ─────────────────────  │
│  [ - ]  2  [ + ]                    │
│                                     │
│  ── Description ──────────────────  │
│  Lorem ipsum dolor sit amet...      │
│                                     │
├─────────────────────────────────────┤
│  [ 🛒 Add to Cart ] [ Buy Now → ]  │
└─────────────────────────────────────┘
```

---

### 5. Layar Pembeli — Checkout & Pembayaran

```
┌───────────────────────────────────────────┐
│  ← Payment                               │
├───────────────────────────────────────────┤
│  Order Summary                            │
│  ┌───────────────────────────────────┐    │
│  │ Subtotal         Rp 700.000       │    │
│  │ Shipping         Rp  15.000       │    │
│  │ ─────────────────────────────     │    │
│  │ Total            Rp 715.000       │    │
│  └───────────────────────────────────┘    │
│                                           │
│  ── Payment Method ─────────────────────  │
│  ○ VISA / Debit Card                      │
│  ○ PayPal                                 │
│  ○ Maestro                                │
│  ○ Apple Pay                              │
│  ● Cash on Delivery (COD)                 │
│  ○ QRIS (Scan QR Code)                    │
│                                           │
│  ┌───────────────────────────────────┐    │
│  │        [ Confirm Payment ]        │    │
│  └───────────────────────────────────┘    │
└───────────────────────────────────────────┘
```

---

### 6. Layar Pembeli — Live Tracking

```
┌─────────────────────────────────────┐
│  ← Tracking          Order #SD-XXX │
├─────────────────────────────────────┤
│  ┌─────────────────────────────┐    │
│  │                             │    │
│  │     🗺 PETA INTERAKTIF      │    │
│  │     (FlutterMap + CARTO)    │    │
│  │                             │    │
│  │  🏪 ─── route ───── 🚗 ─── 📍  │
│  │  Seller          Courier   You  │
│  │                             │    │
│  └─────────────────────────────┘    │
│                                     │
│  ── Delivery Status ──────────────  │
│  ✅ Ordered                         │
│  ✅ Shipped                         │
│  🔵 In Transit (ETA: 15 min)       │
│  ○  Delivered                       │
│                                     │
│  ── Order Items ──────────────────  │
│  🖼 Nike Air Max 270 × 2           │
│     Rp 700.000                      │
│                                     │
│  Total: Rp 715.000                  │
└─────────────────────────────────────┘
```

---

### 7. Layar Admin — Dashboard

```
┌───────────────────────────────────────────────────────────┐
│  ☰ SmartDrop Admin                       🔔  👤 Admin    │
├──────────┬────────────────────────────────────────────────┤
│          │                                                │
│ 📊 Dashboard│  ┌──────┐ ┌──────┐ ┌──────┐ ┌──────┐      │
│ 📦 Products │  │ 👥   │ │ 📦   │ │ 💰   │ │ 📋   │      │
│ 🖼 Banners  │  │Users │ │Prods │ │Rev.  │ │Orders│      │
│ 📋 Reports  │  │ 245  │ │ 189  │ │ 50M  │ │ 523  │      │
│ 🎯 Promotions│ └──────┘ └──────┘ └──────┘ └──────┘      │
│ 👥 Administ.│                                            │
│ 📅 Calendar │  ── Recent Reports ────────────────────    │
│ 👤 Profile  │  ┌─────────────────────────────────────┐   │
│             │  │ #  Reporter  Title   Status  Action │   │
│             │  │ 1  John      Fraud   ⏳ Pending  ▸ │   │
│             │  │ 2  Jane      GPS     🔍 Invest. ▸ │   │
│             │  │ 3  Ali       COD     ✅ Resolved ▸ │   │
│             │  └─────────────────────────────────────┘   │
│             │                                            │
│  🚪 Logout │                                            │
├──────────┴────────────────────────────────────────────────┤
```

**Komponen Admin:**
- **Sidebar**: Menu navigasi 7 tab (Dashboard, Products, Banners, Reports, Promotions, Administration, Calendar, Profile)
- **Dashboard Tab**: 4 kartu statistik + tabel laporan terbaru + daftar pengguna terbaru
- **Products Tab**: CRUD produk + toggle flag marketing
- **Reports Tab**: Tabel laporan dengan aksi perubahan status
- **Administration Tab**: CRUD pengguna (edit role, hapus akun)

---

## III. Struktur File Proyek (Implementasi Aktual)

```text
PBM_TA/
│
├── frontend/                        # Aplikasi Flutter utama
│   ├── lib/                         # Kode sumber Dart
│   │   ├── main.dart                # Entry point aplikasi (Firebase init)
│   │   ├── firebase_options.dart    # Konfigurasi Firebase (auto-generated)
│   │   │
│   │   ├── Splash/                  # Onboarding & Splash Screens
│   │   │   ├── splash_1.dart        # Splash screen halaman 1
│   │   │   ├── splash_2.dart        # Splash screen halaman 2
│   │   │   ├── splash_3.dart        # Splash screen halaman 3
│   │   │   ├── splash_4.dart        # Splash screen halaman 4
│   │   │   └── get_start.dart       # Halaman Get Started (→ Sign In / Sign Up)
│   │   │
│   │   ├── Login/                   # Autentikasi
│   │   │   ├── sign_in.dart         # Login Email/Password & Google Sign-In
│   │   │   ├── sign_up.dart         # Registrasi akun baru
│   │   │   └── forgot_pass.dart     # Reset password via email
│   │   │
│   │   ├── Buyer/                   # Modul Pembeli
│   │   │   ├── dashboard/           # Halaman utama buyer
│   │   │   │   ├── dashboard.dart   # Dashboard utama (banner, kategori, produk)
│   │   │   │   ├── items_detail.dart# Detail produk + add to cart/wishlist
│   │   │   │   ├── search.dart      # Pencarian produk dengan filter
│   │   │   │   ├── wishlist.dart    # Daftar wishlist
│   │   │   │   ├── my_orders.dart   # Riwayat pesanan buyer
│   │   │   │   ├── tracking.dart    # Live tracking pesanan (peta real-time)
│   │   │   │   ├── profile.dart     # Profil pembeli
│   │   │   │   ├── setting.dart     # Pengaturan (tema, report, about)
│   │   │   │   └── qr_scanner.dart  # Scanner QR Code (untuk QRIS)
│   │   │   │
│   │   │   └── chekout/             # Alur checkout
│   │   │       ├── cart.dart        # Keranjang belanja
│   │   │       ├── checkout.dart    # Halaman konfirmasi checkout
│   │   │       ├── payment.dart     # Pilihan metode pembayaran
│   │   │       ├── confirm.dart     # Konfirmasi pembayaran
│   │   │       └── sucessfull.dart  # Halaman sukses pembayaran
│   │   │
│   │   ├── Seller/                  # Modul Penjual
│   │   │   ├── dashboard.dart       # Dashboard seller (pesanan + simulasi pengiriman)
│   │   │   └── product/             # Manajemen produk seller
│   │   │       ├── dashboard.dart   # Daftar produk milik seller
│   │   │       ├── add.dart         # Form tambah produk baru
│   │   │       ├── update.dart      # Form edit produk
│   │   │       └── delete.dart      # Konfirmasi hapus produk
│   │   │
│   │   ├── Admin/                   # Modul Admin
│   │   │   ├── admin_dashboard.dart # Dashboard utama admin (multi-tab)
│   │   │   ├── profile.dart         # Profil admin
│   │   │   ├── market/              # Halaman marketing/promosi
│   │   │   │   ├── deals_of_days.dart   # Kelola Deal of the Day
│   │   │   │   ├── trending.dart        # Kelola produk Trending
│   │   │   │   ├── discount.dart        # Kelola diskon produk
│   │   │   │   ├── spesial_offer.dart   # Kelola Special Offers
│   │   │   │   └── sponsored.dart       # Kelola produk Sponsored
│   │   │   └── report/              # Laporan detail
│   │   │       └── dashboard.dart   # Dashboard laporan
│   │   │
│   │   ├── AI/                      # Modul Kecerdasan Buatan
│   │   │   └── chat.dart            # AI Chatbot (Gemini 2.5 Flash + STT)
│   │   │
│   │   ├── Models/                  # Data Models
│   │   │   ├── product.dart         # Model Product (fromFirestore/toMap)
│   │   │   ├── category_model.dart  # Model Category
│   │   │   └── banner_model.dart    # Model Banner
│   │   │
│   │   └── Services/               # Service Layer
│   │       ├── firestore_service.dart  # Abstraksi CRUD Firestore
│   │       ├── auth_service.dart       # Google Sign-In service
│   │       └── theme_manager.dart      # Manajemen tema aplikasi
│   │
│   ├── assets/
│   │   └── public/
│   │       └── .env                 # API Key (GEMINI_API_KEY)
│   │
│   ├── pubspec.yaml                 # Dependensi Flutter
│   └── android/ & ios/              # Konfigurasi native platform
│
├── dataconnect/                     # Firebase Data Connect config
├── functions/                       # Cloud Functions (jika ada)
│
├── firestore.rules                  # Aturan keamanan Firestore
├── firestore.indexes.json           # Indeks Firestore
│
├── API.md                           # Dokumentasi API lengkap
├── layouts.md                       # Dokumen ini — Spesifikasi & Layout
└── README.md                        # Panduan instalasi & penggunaan
```

---

## IV. Dependensi Utama

| Package | Versi | Kegunaan |
|---|---|---|
| `firebase_core` | ^4.9.0 | Inisialisasi Firebase |
| `firebase_auth` | ^6.5.1 | Autentikasi (email, Google) |
| `cloud_firestore` | ^6.5.0 | Database NoSQL real-time |
| `google_sign_in` | ^7.2.0 | Login via Google |
| `flutter_map` | ^8.3.0 | Peta interaktif (OpenStreetMap) |
| `latlong2` | ^0.9.1 | Koordinat latitude/longitude |
| `geolocator` | ^14.0.3 | Akses GPS perangkat |
| `geocoding` | ^4.0.0 | Konversi alamat ↔ koordinat |
| `http` | ^1.2.1 | HTTP client (Gemini AI, OSRM) |
| `speech_to_text` | ^7.4.0 | Input suara untuk AI chat |
| `image_picker` | ^1.1.2 | Ambil gambar dari kamera/galeri |
| `mobile_scanner` | ^7.2.0 | QR Code scanner (QRIS) |
| `shared_preferences` | ^2.5.5 | Penyimpanan lokal (tema) |
| `google_fonts` | ^8.1.0 | Font kustom |
| `csc_picker` | (git) | Country/State/City picker |