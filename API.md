# 📘 Dokumentasi API Aplikasi SmartDrop

> **Versi**: 1.0.0  
> **Platform**: Flutter (Android/iOS)  
> **Backend**: Firebase (Authentication + Cloud Firestore)  
> **Terakhir Diperbarui**: Juni 2026

---

## Daftar Isi

1. [Arsitektur Sistem](#1-arsitektur-sistem)
2. [Firebase Authentication API](#2-firebase-authentication-api)
3. [Firestore Database API](#3-firestore-database-api)
   - [Collection: `users`](#31-collection-users)
   - [Subcollection: `users/{uid}/cart`](#32-subcollection-usersuidcart)
   - [Subcollection: `users/{uid}/wishlist`](#33-subcollection-usersuidwishlist)
   - [Subcollection: `users/{uid}/orders`](#34-subcollection-usersuidorders)
   - [Collection: `products`](#35-collection-products)
   - [Collection: `categories`](#36-collection-categories)
   - [Collection: `banners`](#37-collection-banners)
   - [Collection: `tracking`](#38-collection-tracking)
   - [Collection: `reports`](#39-collection-reports)
   - [Collection: `settings`](#310-collection-settings)
4. [External REST API](#4-external-rest-api)
   - [Google Gemini AI API](#41-google-gemini-ai-api)
   - [OSRM Routing API](#42-osrm-routing-api)
   - [CARTO Map Tiles API](#43-carto-map-tiles-api)
5. [Service Layer (Abstraksi)](#5-service-layer-abstraksi)
   - [FirestoreService](#51-firestoreservice)
   - [AuthService](#52-authservice)
   - [ThemeManager](#53-thememanager)
6. [Data Models](#6-data-models)
7. [Alur Bisnis (Business Flow)](#7-alur-bisnis-business-flow)

---

## 1. Arsitektur Sistem

```
┌──────────────────────────────────────────────────────────────┐
│                    SmartDrop Flutter App                      │
├──────────────┬───────────────┬───────────────┬───────────────┤
│   Login/     │  Buyer        │  Seller       │  Admin        │
│   SignUp     │  Dashboard    │  Panel        │  Dashboard    │
├──────────────┴───────────────┴───────────────┴───────────────┤
│                     Service Layer                            │
│   FirestoreService │ AuthService │ ThemeManager               │
├──────────────────────────────────────────────────────────────┤
│                   Firebase SDK                               │
│   firebase_auth │ cloud_firestore │ google_sign_in           │
├──────────────────────────────────────────────────────────────┤
│                External REST APIs                            │
│   Gemini AI │ OSRM Routing │ CARTO Map Tiles                 │
└──────────────────────────────────────────────────────────────┘
```

---

## 2. Firebase Authentication API

Firebase Authentication digunakan untuk mengelola identitas pengguna. Berikut adalah operasi-operasi yang digunakan:

### 2.1 Sign Up (Registrasi Email/Password)

| Properti | Detail |
|---|---|
| **Method** | `FirebaseAuth.instance.createUserWithEmailAndPassword()` |
| **File** | `lib/Login/sign_up.dart` |
| **Parameter** | `email: String`, `password: String` |
| **Return** | `UserCredential` |
| **Validasi** | Email `@admin.com` diblokir dari registrasi publik |
| **Side Effect** | Membuat dokumen baru di `users/{uid}` dengan role `buyer` |

**Contoh Data yang Ditulis ke Firestore Setelah Sign Up:**
```json
{
  "uid": "abc123xyz",
  "email": "user@gmail.com",
  "role": "buyer",
  "createdAt": "<ServerTimestamp>",
  "accountHolder": "user"
}
```

---

### 2.2 Sign In (Login Email/Password)

| Properti | Detail |
|---|---|
| **Method** | `FirebaseAuth.instance.signInWithEmailAndPassword()` |
| **File** | `lib/Login/sign_in.dart` |
| **Parameter** | `email: String`, `password: String` |
| **Return** | `UserCredential` |
| **Routing** | `@admin.com` → `AdminDashboard`, lainnya → `DashboardScreen` |
| **Side Effect** | Auto-sync email ke Firestore jika kosong; auto-promote ke `admin` jika email berakhiran `@admin.com` |

---

### 2.3 Sign In with Google

| Properti | Detail |
|---|---|
| **Method** | `AuthService.signInWithGoogle()` → `FirebaseAuth.signInWithCredential()` |
| **File** | `lib/Services/auth_service.dart`, `lib/Login/sign_in.dart` |
| **Flow** | Google OAuth → `GoogleSignInAuthentication` → `GoogleAuthProvider.credential()` → Firebase sign-in |
| **Side Effect** | Jika user baru: buat dokumen `users/{uid}` dengan `displayName` dan `photoUrl` dari Google |

---

### 2.4 Forgot Password (Reset Password)

| Properti | Detail |
|---|---|
| **Method** | `FirebaseAuth.instance.sendPasswordResetEmail()` |
| **File** | `lib/Login/forgot_pass.dart` |
| **Parameter** | `email: String` |
| **Return** | `void` (email terkirim) |

---

### 2.5 Sign Out

| Properti | Detail |
|---|---|
| **Method** | `FirebaseAuth.instance.signOut()` + `GoogleSignIn.signOut()` |
| **File** | `lib/Services/auth_service.dart`, `lib/Buyer/dashboard/setting.dart` |
| **Side Effect** | Redirect ke `SplashScreen1` dan hapus history routing |

---

## 3. Firestore Database API

### 3.1 Collection: `users`

**Path:** `users/{uid}`

**Deskripsi:** Menyimpan profil pengguna, kredensial, dan metadata akun.

#### Schema Dokumen

| Field | Tipe | Deskripsi | Wajib |
|---|---|---|---|
| `uid` | `string` | UID dari Firebase Auth | ✅ |
| `email` | `string` | Email pengguna | ✅ |
| `role` | `string` | Role: `buyer`, `admin` | ✅ |
| `accountHolder` | `string` | Nama pemegang akun | ✅ |
| `photoUrl` | `string` | URL foto profil (dari Google) | ❌ |
| `address` | `string` | Alamat pengiriman lengkap | ❌ |
| `lat` | `number` | Latitude lokasi pengguna | ❌ |
| `lng` | `number` | Longitude lokasi pengguna | ❌ |
| `city` | `string` | Kota pengguna | ❌ |
| `state` | `string` | Provinsi pengguna | ❌ |
| `createdAt` | `timestamp` | Waktu pembuatan akun | ✅ |

#### Operasi CRUD

| Operasi | Method | File | Deskripsi |
|---|---|---|---|
| **Create** | `.set()` | `sign_up.dart`, `sign_in.dart` | Saat user pertama kali login/register |
| **Read** | `.get()`, `.snapshots()` | `setting.dart`, `cart.dart`, `payment.dart`, `admin_dashboard.dart` | Memuat profil user |
| **Update** | `.update()` | `sign_in.dart`, `cart.dart`, `admin_dashboard.dart`, `profile.dart` | Update email, alamat, koordinat, role |
| **Delete** | `.delete()` | `admin_dashboard.dart` | Admin menghapus user |
| **Stream** | `.snapshots()` | `admin_dashboard.dart` | Admin melihat daftar semua user (real-time) |

---

### 3.2 Subcollection: `users/{uid}/cart`

**Path:** `users/{uid}/cart/{cartDocId}`

**Deskripsi:** Keranjang belanja masing-masing pengguna.

#### Schema Dokumen

| Field | Tipe | Deskripsi |
|---|---|---|
| `productId` | `string` | ID produk referensi ke collection `products` |
| `title` | `string` | Nama produk |
| `price` | `number` | Harga satuan |
| `imageUrl` | `string` | URL gambar produk |
| `oldPrice` | `number?` | Harga sebelum diskon (opsional) |
| `size` | `string?` | Ukuran yang dipilih (opsional) |
| `quantity` | `number` | Jumlah item |
| `sellerId` | `string?` | ID seller produk |
| `addedAt` | `timestamp` | Waktu ditambahkan ke cart |

#### Operasi CRUD

| Operasi | Method | File | Deskripsi |
|---|---|---|---|
| **Create** | `.add()` | `items_detail.dart` | Menambah item ke keranjang |
| **Read** | `.snapshots()`, `.get()` | `cart.dart`, `payment.dart` | Stream real-time isi keranjang |
| **Update** | `.update({'quantity': n})` | `cart.dart`, `items_detail.dart` | Mengubah jumlah item |
| **Delete** | `.delete()` | `cart.dart`, `payment.dart` | Hapus item, atau kosongkan setelah checkout |

---

### 3.3 Subcollection: `users/{uid}/wishlist`

**Path:** `users/{uid}/wishlist/{productId}`

**Deskripsi:** Daftar keinginan (wishlist) pengguna. Document ID = Product ID.

#### Schema Dokumen

| Field | Tipe | Deskripsi |
|---|---|---|
| `title` | `string` | Nama produk |
| `price` | `number` | Harga produk |
| `imageUrl` | `string` | URL gambar produk |
| `oldPrice` | `number?` | Harga sebelum diskon |
| `addedAt` | `timestamp` | Waktu ditambahkan ke wishlist |

#### Operasi CRUD

| Operasi | Method | File | Deskripsi |
|---|---|---|---|
| **Create** | `.set()` | `items_detail.dart` | Tambah ke wishlist (toggle) |
| **Read** | `.get()`, `.snapshots()` | `items_detail.dart`, `wishlist.dart` | Cek status & stream daftar wishlist |
| **Delete** | `.delete()` | `items_detail.dart`, `wishlist.dart` | Hapus dari wishlist (toggle / clear all) |

---

### 3.4 Subcollection: `users/{uid}/orders`

**Path:** `users/{uid}/orders/{orderId}`

**Deskripsi:** Riwayat pesanan pembeli (untuk tampilan "My Orders").

#### Schema Dokumen

| Field | Tipe | Deskripsi |
|---|---|---|
| `orderId` | `string` | ID pesanan unik (format: `SD-XXXXX`) |
| `status` | `number` | Status pesanan: `0`=Ordered, `1`=Shipped, `2`=In Transit, `3`=Delivered |
| `totalAmount` | `number` | Total harga pesanan |
| `estimatedDelivery` | `string` | Estimasi waktu pengiriman (contoh: `"Today, 15:45"`) |
| `sellerId` | `string` | UID seller |
| `buyerAddress` | `string` | Alamat pengiriman pembeli |
| `sellerAddress` | `string` | Alamat toko seller |
| `createdAt` | `timestamp` | Waktu pesanan dibuat |

#### Operasi CRUD

| Operasi | Method | File | Deskripsi |
|---|---|---|---|
| **Create** | `.set()` | `payment.dart` | Setelah pembayaran berhasil |
| **Read** | `.snapshots()` | `my_orders.dart`, `setting.dart` | Stream daftar pesanan |
| **Update** | `.update({'status': n})` | `seller/dashboard.dart` | Seller mengubah status pengiriman |

---

### 3.5 Collection: `products`

**Path:** `products/{productId}`

**Deskripsi:** Katalog produk aplikasi.

#### Schema Dokumen

| Field | Tipe | Deskripsi |
|---|---|---|
| `title` | `string` | Nama produk |
| `description` | `string` | Deskripsi produk |
| `price` | `number` | Harga jual |
| `oldPrice` | `number?` | Harga sebelum diskon |
| `discount` | `number?` | Persentase diskon |
| `imageUrl` | `string` | URL gambar produk |
| `rating` | `number` | Rating produk (0.0 - 5.0) |
| `reviews` | `number` | Jumlah review |
| `sellerId` | `string?` | UID penjual |
| `sellerName` | `string?` | Nama penjual |
| `location` | `string?` | Lokasi produk/toko |
| `isDealOfTheDay` | `boolean` | Flag Deal of the Day |
| `isTrending` | `boolean` | Flag Trending |
| `isNewArrival` | `boolean` | Flag New Arrival |
| `stock` | `number` | Stok tersedia |

#### Operasi CRUD

| Operasi | Method | File/Service | Deskripsi |
|---|---|---|---|
| **Create** | `addProduct()` → `.add()` | `FirestoreService`, `seller/product/add.dart` | Seller menambah produk baru |
| **Read (Stream)** | `getProducts()` → `.snapshots()` | `FirestoreService` | Stream semua produk |
| **Read (Filter)** | `getProductsBySeller()` | `FirestoreService` | Produk milik seller tertentu |
| **Read (Flag)** | `getDealProducts()`, `getTrendingProducts()`, `getNewArrivalProducts()` | `FirestoreService` | Produk berdasarkan flag marketing |
| **Update** | `updateProduct()` → `.update()` | `FirestoreService`, `seller/product/update.dart` | Edit detail produk |
| **Update (Flag)** | `toggleProductFlag()` | `FirestoreService` | Toggle flag `isDealOfTheDay`, `isTrending`, `isNewArrival` |
| **Update (Stock)** | `.update({stockKey: newStock})` | `payment.dart` | Kurangi stok setelah pembelian |
| **Delete** | `deleteProduct()` → `.delete()` | `FirestoreService` | Hapus produk |

---

### 3.6 Collection: `categories`

**Path:** `categories/{categoryId}`

**Deskripsi:** Kategori produk untuk navigasi dashboard.

#### Schema Dokumen

| Field | Tipe | Deskripsi |
|---|---|---|
| `name` | `string` | Nama kategori |
| `imageUrl` | `string` | URL ikon/gambar kategori |
| `order` | `number` | Urutan tampilan |

#### Operasi

| Operasi | Method | File/Service | Deskripsi |
|---|---|---|---|
| **Read (Stream)** | `getCategories()` → `.orderBy('order').snapshots()` | `FirestoreService` | Stream kategori terurut |

---

### 3.7 Collection: `banners`

**Path:** `banners/{bannerId}`

**Deskripsi:** Banner promosi yang ditampilkan di dashboard buyer.

#### Schema Dokumen

| Field | Tipe | Deskripsi |
|---|---|---|
| `imageUrl` | `string` | URL gambar banner |
| `title` | `string` | Judul banner |
| `subtitle` | `string` | Subjudul banner |
| `type` | `string` | Tipe: `promo`, `special_offer`, `flat_heels`, `summer_sale`, `sponsored` |
| `order` | `number` | Urutan tampilan |

#### Operasi CRUD

| Operasi | Method | File/Service | Deskripsi |
|---|---|---|---|
| **Create** | `addBanner()` → `.add()` | `FirestoreService` | Admin menambah banner |
| **Read (Stream)** | `getBanners()` → `.orderBy('order').snapshots()` | `FirestoreService` | Stream banner terurut |
| **Update** | `updateBanner()` → `.update()` | `FirestoreService` | Edit banner |
| **Delete** | `deleteBanner()` → `.delete()` | `FirestoreService` | Hapus banner |

---

### 3.8 Collection: `tracking`

**Path:** `tracking/{orderId}`

**Deskripsi:** Data pelacakan real-time untuk pengiriman pesanan (sistem GPS live tracking).

#### Schema Dokumen

| Field | Tipe | Deskripsi |
|---|---|---|
| `orderId` | `string` | ID pesanan (format: `SD-XXXXX`) |
| `buyerId` | `string` | UID pembeli |
| `buyerName` | `string` | Nama pembeli |
| `buyerAddress` | `string` | Alamat pembeli |
| `sellerId` | `string` | UID penjual |
| `sellerAddress` | `string` | Alamat toko penjual |
| `status` | `number` | Status: `2`=In Transit, `3`=Arrived/Delivered |
| `totalAmount` | `number` | Total harga pesanan |
| `storeLatitude` | `number` | Latitude toko penjual (titik awal) |
| `storeLongitude` | `number` | Longitude toko penjual |
| `buyerLatitude` | `number` | Latitude pembeli (titik akhir) |
| `buyerLongitude` | `number` | Longitude pembeli |
| `sellerLatitude` | `number` | Latitude posisi kurir saat ini (bergerak) |
| `sellerLongitude` | `number` | Longitude posisi kurir saat ini |
| `items` | `array<map>` | Daftar item pesanan |
| `createdAt` | `timestamp` | Waktu pesanan dibuat |

**Struktur Field `items` (Array Item):**
```json
{
  "productId": "prod_abc123",
  "quantity": 2,
  "title": "Nike Air Max 270",
  "price": 350000,
  "imageUrl": "https://...",
  "sellerId": "seller_xyz"
}
```

#### Operasi CRUD

| Operasi | Method | File | Deskripsi |
|---|---|---|---|
| **Create** | `.set()` | `payment.dart` | Membuat tracking record setelah checkout |
| **Read (Stream)** | `.snapshots()` | `tracking.dart`, `seller/dashboard.dart` | Real-time tracking data |
| **Read (Query)** | `.where('sellerId', isEqualTo: uid).snapshots()` | `seller/dashboard.dart` | Seller melihat semua order-nya |
| **Update (Status)** | `.update({'status': n})` | `seller/dashboard.dart` | Seller update status pesanan |
| **Update (Posisi Kurir)** | `.update({'sellerLatitude': lat, 'sellerLongitude': lng})` | `seller/dashboard.dart` | Update posisi GPS kurir |
| **Update (Posisi Buyer)** | `.update({'buyerLatitude': lat, 'buyerLongitude': lng})` | `tracking.dart` | Update posisi GPS buyer |

---

### 3.9 Collection: `reports`

**Path:** `reports/{reportId}`

**Deskripsi:** Laporan masalah/keluhan dari pengguna untuk ditinjau oleh admin.

#### Schema Dokumen

| Field | Tipe | Deskripsi |
|---|---|---|
| `reporter` | `string` | Nama pelapor |
| `reporterEmail` | `string` | Email pelapor |
| `title` | `string` | Kategori masalah (contoh: `"COD Di Luar Safe Zone"`, `"Penipuan / Fraud"`) |
| `target` | `string` | Pihak yang dilaporkan |
| `issue` | `string` | Deskripsi detail masalah |
| `timestamp` | `timestamp` | Waktu laporan dibuat |
| `status` | `string` | Status: `Pending`, `Investigating`, `Resolved` |

#### Kategori Masalah (Dropdown)

| Nilai | Deskripsi |
|---|---|
| `COD Di Luar Safe Zone` | Transaksi COD di luar titik aman |
| `Masalah GPS / Geofence` | Masalah validasi GPS/geofence |
| `Deskripsi Produk Tidak Sesuai` | Barang tidak sesuai deskripsi |
| `Penipuan / Fraud` | Dugaan penipuan |
| `Lainnya` | Masalah lainnya |

#### Operasi CRUD

| Operasi | Method | File | Deskripsi |
|---|---|---|---|
| **Create** | `.add()` | `setting.dart` | Buyer membuat laporan |
| **Read (Stream)** | `.orderBy('timestamp', descending: true).snapshots()` | `admin_dashboard.dart` | Admin melihat semua laporan |
| **Update** | `.update({'status': newStatus})` | `admin_dashboard.dart` | Admin mengubah status laporan |

---

### 3.10 Collection: `settings`

**Path:** `settings/{docName}`

**Deskripsi:** Konfigurasi global aplikasi.

#### Operasi

| Operasi | Method | File/Service | Deskripsi |
|---|---|---|---|
| **Read (Stream)** | `getSettings(docName)` → `.snapshots()` | `FirestoreService` | Stream konfigurasi |
| **Update** | `updateSettings(docName, data)` → `.set(data, merge: true)` | `FirestoreService` | Update konfigurasi (merge) |

---

## 4. External REST API

### 4.1 Google Gemini AI API

**Deskripsi:** Digunakan untuk fitur Customer Service AI (chatbot cerdas).

| Properti | Detail |
|---|---|
| **URL** | `https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent` |
| **Method** | `POST` |
| **Auth** | Query parameter `key={GEMINI_API_KEY}` |
| **File** | `lib/AI/chat.dart` |
| **Fallback** | Mode simulasi jika API key tidak tersedia |

#### Request Body

```json
{
  "system_instruction": {
    "parts": [
      { "text": "You are a helpful CS AI Assistant for SmartDrop..." }
    ]
  },
  "contents": [
    { "role": "user", "parts": [{ "text": "Pertanyaan user" }] },
    { "role": "model", "parts": [{ "text": "Jawaban AI sebelumnya" }] }
  ],
  "generationConfig": {
    "temperature": 0.7,
    "maxOutputTokens": 800
  }
}
```

#### Response (200 OK)

```json
{
  "candidates": [
    {
      "content": {
        "parts": [
          { "text": "Jawaban AI..." }
        ]
      }
    }
  ]
}
```

#### Konfigurasi API Key

- Disimpan di: `assets/public/.env`
- Format: `GEMINI_API_KEY=your_api_key_here`
- Dimuat saat `initState()` menggunakan `rootBundle.loadString()`

---

### 4.2 OSRM Routing API

**Deskripsi:** Menghitung rute jalan raya (road path) antara dua titik koordinat untuk simulasi pengiriman.

| Properti | Detail |
|---|---|
| **URL** | `https://router.project-osrm.org/route/v1/driving/{lng1},{lat1};{lng2},{lat2}` |
| **Method** | `GET` |
| **Auth** | Tidak diperlukan (public API) |
| **File** | `lib/Seller/dashboard.dart`, `lib/Buyer/dashboard/tracking.dart` |
| **Rate Limit** | Client-side: 1 request per 8 detik |

#### Query Parameters

| Parameter | Nilai | Deskripsi |
|---|---|---|
| `overview` | `full` | Mengembalikan geometri rute lengkap |
| `geometries` | `geojson` | Format geometri GeoJSON |

#### Response (200 OK)

```json
{
  "routes": [
    {
      "geometry": {
        "coordinates": [
          [106.8456, -6.2088],
          [106.8460, -6.2090],
          ...
        ]
      }
    }
  ]
}
```

#### Fallback

Jika OSRM offline/gagal, sistem menggunakan interpolasi garis lurus (straight line) antara titik awal dan akhir.

---

### 4.3 CARTO Map Tiles API

**Deskripsi:** Penyedia tile peta untuk komponen `FlutterMap`.

| Properti | Detail |
|---|---|
| **URL (Light Mode)** | `https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}.png` |
| **URL (Dark Mode)** | `https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}.png` |
| **URL (Voyager)** | `https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}.png` |
| **Method** | `GET` |
| **Auth** | Tidak diperlukan (public tiles) |
| **Subdomains** | `a`, `b`, `c`, `d` |
| **File** | `tracking.dart`, `seller/dashboard.dart`, `cart.dart` |

Pemilihan tema tile (light/dark) otomatis berdasarkan `bgColor.computeLuminance()`.

---

## 5. Service Layer (Abstraksi)

### 5.1 FirestoreService

**File:** `lib/Services/firestore_service.dart`

Abstraksi operasi Firestore untuk `products`, `categories`, `banners`, dan `settings`.

| Method | Return Type | Deskripsi |
|---|---|---|
| `getProducts()` | `Stream<List<Product>>` | Stream semua produk |
| `getProductsBySeller(sellerId)` | `Stream<List<Product>>` | Produk milik seller tertentu |
| `addProduct(product)` | `Future<void>` | Tambah produk baru |
| `updateProduct(product)` | `Future<void>` | Update produk |
| `deleteProduct(productId)` | `Future<void>` | Hapus produk |
| `getCategories()` | `Stream<List<CategoryModel>>` | Stream kategori (terurut) |
| `getBanners()` | `Stream<List<BannerModel>>` | Stream banner (terurut) |
| `getDealProducts()` | `Stream<List<Product>>` | Produk "Deal of the Day" |
| `getTrendingProducts()` | `Stream<List<Product>>` | Produk "Trending" |
| `getNewArrivalProducts()` | `Stream<List<Product>>` | Produk "New Arrival" |
| `toggleProductFlag(id, field, value)` | `Future<void>` | Toggle flag marketing |
| `addBanner(banner)` | `Future<void>` | Tambah banner |
| `updateBanner(banner)` | `Future<void>` | Update banner |
| `deleteBanner(id)` | `Future<void>` | Hapus banner |
| `getSettings(docName)` | `Stream<DocumentSnapshot>` | Stream dokumen settings |
| `updateSettings(docName, data)` | `Future<void>` | Update settings (merge) |

---

### 5.2 AuthService

**File:** `lib/Services/auth_service.dart`

Abstraksi operasi autentikasi Google Sign-In.

| Method | Return Type | Deskripsi |
|---|---|---|
| `signInWithGoogle()` | `Future<UserCredential?>` | Login via Google OAuth |
| `signOut()` | `Future<void>` | Logout dari Firebase + Google |

---

### 5.3 ThemeManager

**File:** `lib/Services/theme_manager.dart`

Mengelola tema visual aplikasi (dark mode, light mode, dll).

| Method | Deskripsi |
|---|---|
| `ThemeManager.loadTheme()` | Memuat tema dari preferensi |
| `ThemeManager.changeTheme(name)` | Mengubah tema aktif |
| `ThemeManager.currentTheme` | `ValueNotifier<AppTheme>` — state tema saat ini |
| `ThemeManager.themes` | Daftar semua preset tema |

---

## 6. Data Models

### 6.1 Product

**File:** `lib/Models/product.dart`

```dart
class Product {
  final String? id;
  final String title;
  final String description;
  final double price;
  final double? oldPrice;
  final double? discount;
  final String imageUrl;
  final double rating;       // default: 0.0
  final int reviews;         // default: 0
  final String? sellerId;
  final String? sellerName;
  final String? location;
  final bool isDealOfTheDay;  // default: false
  final bool isTrending;      // default: false
  final bool isNewArrival;    // default: false
  final int stock;            // default: 0
}
```

| Method | Deskripsi |
|---|---|
| `Product.fromFirestore(doc)` | Konversi `DocumentSnapshot` → `Product` (dengan error handling) |
| `product.toMap()` | Konversi `Product` → `Map<String, dynamic>` untuk Firestore |

---

### 6.2 CategoryModel

**File:** `lib/Models/category_model.dart`

```dart
class CategoryModel {
  final String id;
  final String name;
  final String imageUrl;
  final int order;
}
```

| Method | Deskripsi |
|---|---|
| `CategoryModel.fromFirestore(doc)` | Konversi dari Firestore |
| `toMap()` | Konversi ke Map |

---

### 6.3 BannerModel

**File:** `lib/Models/banner_model.dart`

```dart
class BannerModel {
  final String id;
  final String imageUrl;
  final String title;
  final String subtitle;
  final String type;   // 'promo', 'special_offer', 'flat_heels', 'summer_sale', 'sponsored'
  final int order;
}
```

| Method | Deskripsi |
|---|---|
| `BannerModel.fromFirestore(doc)` | Konversi dari Firestore |
| `toMap()` | Konversi ke Map |

---

## 7. Alur Bisnis (Business Flow)

### 7.1 Alur Checkout & Pembayaran

```
┌──────────┐    ┌──────────┐    ┌──────────────┐    ┌────────────┐
│  Browse  │───▶│ Add to   │───▶│   Cart       │───▶│  Payment   │
│ Products │    │ Cart     │    │   Screen     │    │  Screen    │
└──────────┘    └──────────┘    └──────────────┘    └─────┬──────┘
                                                          │
                        ┌─────────────────────────────────┘
                        ▼
              ┌──────────────────┐
              │ Payment Method:  │
              │ • VISA/Debit     │──▶ Simulasi 3 detik
              │ • PayPal         │
              │ • Maestro        │
              │ • Apple Pay      │
              │ • COD            │──▶ Langsung sukses
              │ • QRIS           │──▶ Scan QR → Simulasi 3 detik
              └────────┬─────────┘
                       ▼
              ┌──────────────────┐
              │ _processOrder    │
              │ ToDatabase():    │
              │ 1. Baca user     │
              │ 2. Baca cart     │
              │ 3. Kurangi stok  │
              │ 4. Baca seller   │
              │ 5. Tulis orders  │
              │ 6. Tulis tracking│
              │ 7. Kosongkan cart│
              └────────┬─────────┘
                       ▼
              ┌──────────────────┐
              │ Success Dialog   │
              │ → Track Delivery │
              │ → Back to Home   │
              └──────────────────┘
```

### 7.2 Alur Live Tracking

```
┌──────────────┐          ┌──────────────┐
│  Buyer       │          │  Seller      │
│  TrackingScreen│        │  Dashboard   │
└──────┬───────┘          └──────┬───────┘
       │                         │
       │  ◀── Stream tracking/{orderId} ──▶  │
       │                         │
       │  Update buyerLat/Lng    │  Update sellerLat/Lng
       │  (GPS real-time)        │  (Manual tap / Simulasi OSRM)
       │                         │
       │  Lihat peta real-time   │  Ubah status (In Transit → Arrived)
       │  Kirim chat/nudge       │  Simulasi rute otomatis
       └────────────────────────-┘
```

### 7.3 Alur Laporan Masalah

```
┌──────────────┐    ┌──────────────┐    ┌──────────────┐
│  Buyer       │───▶│  Form Report │───▶│  Firestore   │
│  Settings    │    │  (Dialog)    │    │  reports/    │
└──────────────┘    └──────────────┘    └──────┬───────┘
                                               │
                                               ▼
                                      ┌──────────────┐
                                      │  Admin       │
                                      │  Dashboard   │
                                      │  (Reports)   │
                                      │              │
                                      │ Pending →    │
                                      │ Investigating│
                                      │ → Resolved   │
                                      └──────────────┘
```

### 7.4 Alur Role-Based Access

```
┌──────────────┐
│    Login     │
└──────┬───────┘
       │
       ├── email@admin.com → AdminDashboard
       │   ├── Products CRUD
       │   ├── Banners CRUD
       │   ├── Reports Management
       │   ├── User Management (CRUD)
       │   ├── Calendar Events
       │   └── Promotions
       │
       └── email@*.com → BuyerDashboard
           ├── Browse Products
           ├── Cart & Checkout
           ├── Wishlist
           ├── My Orders
           ├── Live Tracking
           ├── Settings & Profile
           ├── Seller Panel (any buyer can sell)
           ├── Report Issues
           └── AI Customer Service
```

---

## Catatan Teknis

### Keamanan
- **Firestore Rules** harus dikonfigurasi terpisah di Firebase Console untuk membatasi akses berdasarkan `request.auth.uid`.
- API Key Gemini disimpan di `assets/public/.env` dan dimuat saat runtime (bukan di source code).
- Password reset dikirim via email resmi Firebase.

### Rate Limiting
- OSRM Routing: Client-side throttle 8 detik per request (`_lastRouteFetchTime`).
- Gemini AI: Tidak ada rate limit client-side (bergantung kuota Google API).

### Error Handling
- Semua operasi Firestore dibungkus `try-catch` dengan `debugPrint()`.
- `Product.fromFirestore()` memiliki fallback graceful yang mengembalikan "Error Loading Product" jika parsing gagal.
- Tracker memiliki fallback straight-line jika OSRM offline.

### Dependencies Utama
```yaml
firebase_auth: ^5.x
cloud_firestore: ^5.x
google_sign_in: ^6.x
flutter_map: ^7.x
latlong2: ^0.9.x
geolocator: ^13.x
geocoding: ^3.x
http: ^1.x
speech_to_text: ^7.x
```
