Tentu, ini adalah rangkuman terstruktur mengenai *requirements* (kebutuhan sistem), rancangan *layout*, dan usulan struktur file modular untuk proyek aplikasi **SmartDrop**.

### I. Requirements (Spesifikasi Kebutuhan Sistem)

Sistem aplikasi ini dibangun menggunakan framework Flutter (dengan bahasa Dart) untuk antarmuka dan ekosistem Google Firebase (Authentication, Firestore, Storage) untuk *backend*. Sistem ini membagi akses ke dalam tiga peran pengguna (*Role-Based Access Control*).

**1. Kebutuhan Fitur Pembeli**

* Fitur peta interaktif yang memungkinkan pembeli melakukan *drop pin* untuk menentukan titik temu COD yang akurat.


* Fitur rekomendasi *Safe Zones* (Titik Kumpul Aman) berupa *dropdown* lokasi publik yang strategis.


* Pelacakan pergerakan posisi penjual secara langsung (*real-time*) di layar perangkat pembeli.


* Informasi Estimasi Waktu Kedatangan (ETA) dan rincian total pembayaran tunai.


* Fitur komunikasi internal berupa *Chat In-App* dan tombol darurat *Quick Nudge* ("Ping!").



**2. Kebutuhan Fitur Penjual**

* Fitur navigasi peta (rute) menuju lokasi pembeli.


* Manajemen daftar pesanan bawaan.


* Fitur *slider* untuk memperbarui status perjalanan pengiriman (misalnya dari "Mulai Antar" menjadi "Tiba di Lokasi").


* Sistem validasi jarak (*geofencing*), di mana tombol "Tiba di Lokasi" hanya bisa ditekan jika penjual berada dalam radius 50 meter dari pembeli.


* Fitur validasi *Proof of Delivery* (PoD) yang mewajibkan penjual mengambil foto bukti serah terima menggunakan kamera perangkat.



**3. Kebutuhan Fitur Admin**

* Panel dasbor untuk melakukan moderasi dan audit konten secara terpusat.


* Fitur peninjauan, verifikasi identitas akun baru, serta penyaringan postingan produk sebelum tampil di aplikasi.


* Kemampuan untuk menyetujui, menolak, atau memblokir konten yang melanggar pedoman komunitas.



---

### II. Rancangan Layout (Wireframe)

Tata letak antarmuka dirancang secara intuitif sesuai dengan masing-masing peran:

**1. Layar Pembeli (Mobile)**

* 
**Bagian Atas:** Menampilkan informasi ETA (Estimasi Waktu Kedatangan) dan total harga tunai yang harus disiapkan oleh pembeli.


* 
**Bagian Tengah:** Menampilkan visual peta interaktif secara penuh, dengan pin lokasi penjual yang bergerak dan disinkronisasi secara *real-time*.


* 
**Bagian Bawah:** Menyediakan akses komunikasi berupa tombol "Chat" dan tombol darurat "Ping!".



**2. Layar Penjual (Mobile)**

* 
**Bagian Atas:** Menampilkan peta dengan garis rute navigasi menuju titik temu yang telah ditentukan pembeli.


* 
**Bagian Tengah:** Memuat kartu detail pesanan, lengkap dengan foto dan nama produk untuk mencegah kesalahan penyerahan barang.


* 
**Bagian Bawah:** Menyediakan *slider* pembaruan status ("Mulai Antar" $\rightarrow$ "Tiba di Lokasi") beserta tombol peluncuran sensor kamera untuk dokumentasi serah terima.



**3. Layar Admin (Dasbor Mobile / Web)**

* 
**Tampilan Utama:** Berupa daftar tabel atau tata letak *grid* yang memuat antrean (*Pending Review*) akun-akun baru dan postingan produk yang masuk.


* 
**Aksi:** Pada setiap *item* di dalam tabel/grid tersebut, terdapat dua tombol aksi utama, yaitu "Setujui" (*Approve*) atau "Tolak/Blokir" (*Reject/Ban*).



---

### III. Usulan Struktur File (Flutter - Pendekatan Modular)

Untuk mendukung ekosistem aplikasi berbasis Flutter dan Firebase, berikut adalah usulan struktur folder proyek yang modular untuk menjaga agar kode tetap terorganisir, terpisah sesuai fitur, dan terdokumentasi dengan baik.

```text
smartdrop_app/
│
├── android/                   # Konfigurasi native Android (termasuk permission GPS/Kamera)
├── ios/                       # Konfigurasi native iOS
[cite_start]├── lib/                       # Kode utama aplikasi Dart [cite: 52]
│   ├── core/                  # Utilitas global dan konfigurasi dasar
│   │   ├── constants/         # Warna, tema, URL, string
│   │   ├── services/          # Layanan global (Firebase Auth, LocationService, CameraService)
│   │   └── utils/             # Helper functions (Geofencing calculator, date formatter)
│   │
│   ├── features/              # Modul berdasarkan fitur utama (Modular)
│   │   ├── auth/              # Fitur login/register & Role-Based Access Control
│   │   ├── buyer/             # Khusus antarmuka dan logika Pembeli
│   │   │   ├── presentation/  # UI: Layar peta, ETA, tombol ping
│   │   │   └── data/          # Logika stream Firestore posisi penjual
│   │   ├── seller/            # Khusus antarmuka dan logika Penjual
│   │   │   ├── presentation/  # UI: Rute, kartu produk, slider status
│   │   │   └── data/          # Logika update lokasi GPS, upload foto PoD
│   │   ├── seller/            # Khusus antarmuka dan logika Penjual
│   │   │   ├── presentation/  # UI: Rute, kartu produk, slider status
│   │   │   └── data/          # Logika update lokasi GPS, upload foto PoD
│   │   ├── admin/             # Khusus dasbor audit Admin
│   │   │   ├── presentation/  # UI: Tabel review, tombol approve/reject
│   │   │   └── data/          # Logika query pending approval
│   │   └── chat/              # Modul komunikasi Chat In-App
│   │
│   ├── shared/                # Widget UI yang dipakai berulang (Tombol kustom, Loading, Dialog)
│   └── main.dart              # Entry point aplikasi
│
├── pubspec.yaml               # Manajemen dependensi (google_maps_flutter, geolocator, firebase_core, dll)
└── README.md                  # Manual book instalasi proyek, tata cara build, dan panduan fitur

```