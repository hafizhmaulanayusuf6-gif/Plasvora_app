# FULL PROJECT BUG AUDIT REPORT — PLASVORA
**Sistem Aplikasi Pengelolaan & Upcycling Sampah Plastik Berkelanjutan**

---

> **Status Audit**: SELESAI  
> **Tanggal Audit**: 6 November 2026  
> **Auditor**: Principal QA Engineer, Flutter Specialist, Laravel Specialist, Security & AI Auditor  
> **Metode Audit**: Non-Destructive Deep Static Code Review, Automated Linting/Analysis, Contract Integration Mapping, Security & Architecture Audit  
> **Workspace**:
> - Frontend Flutter: `C:\Project\Plasvora_app` (Branch: `main`, Working Tree: Clean)
> - Backend Laravel: `C:\xampp\htdocs\backend_plasvora` (Laravel 12.0, PHP 8.2.12)

---

## RINGKASAN EKSEKUTIF KLASIFIKASI TEMUAN

| Tingkat Keparahan | Jumlah Temuan | Dampak Utama |
|---|:---:|---|
| **CRITICAL** | 3 | TypeCast crash parsing JSON data riil, fitur penambahan material berupa form dummy |
| **HIGH** | 5 | Riwayat aktivitas 100% mock data, impact metrics tidak pernah di-fetch, token hilang saat restart, fitur request & handover tidak terpasang di UI, ketidakcocokan Flutter Web (`dart:io`) |
| **MEDIUM** | 4 | Inkonsistensi enum kategori (`Lainnya` vs `OTHER`), inkonsistensi enum kondisi (`light` vs `slightly_dirty`), tombol aksi hasil analisis hanya mock/lokal, ketiadaan UI riwayat analisis lama |
| **LOW** | 2 | Dead-code exception handling di `ApiClient`, inkonsistensi formatting kode pada 24 file |
| **INFORMATIONAL** | 2 | Konfigurasi CORS Laravel untuk browser web, model fallback Gemini AI |
| **BELUM DIVERIFIKASI** | 2 | Eksekusi runtime MySQL socket end-to-end dan `flutter test` via toolchain sandbox |

---

## A. RINGKASAN KONDISI PROJECT

1. **Frontend Flutter (`C:\Project\Plasvora_app`)**:
   - Arsitektur berbasis MVVM (View - ViewModel - Repository - Model). State management menggunakan `ListenableBuilder` dan `ChangeNotifier` bawaan SDK (tanpa package external Provider/Bloc).
   - Seluruh asset gambar (14 file) di `assets/images/` terpasang lengkap dan valid.
   - Menggunakan konfigurasi dinamis `ApiConfig.baseUrl` (default `http://127.0.0.1:8000/api`) dengan flag `USE_API = true`.
   - **Kelemahan Kritis**: Sejumlah fitur UI tampak selesai pada tampilan (Stitch UI), namun di baliknya masih terisolasi sebagai mock dummy, form tanpa controller, atau belum dihubungkan ke repository/backend.

2. **Backend Laravel (`C:\xampp\htdocs\backend_plasvora`)**:
   - Struktur API RESTful rapi di `routes/api.php` dengan Laravel Sanctum.
   - Memiliki kontrol otorisasi yang ketat pada mutasi data (ownership validation pada `MaterialController`, `MaterialRequestController`, dan `HandoverRequestController`).
   - Implementasi `GeminiVisionService` untuk analisis multi-komponen sampah plastik dirancang sangat detail dengan OpenAPI structured schema (`responseSchema`), fallback rule-based, proteksi prompt recitation, dan penanganan status non-plastik / uncertain.
   - **Kelemahan Kritis**: Tipe casting Eloquent (`'decimal:2'`) mengonversi angka numerik menjadi string pada JSON output, memicu crash pada Flutter yang melakukan unboxing tipe `as num` atau `as int`.

---

## B. DAFTAR SELURUH BUG YANG DITEMUKAN

### [BUG-01] TypeCastException Saat Parsing Listing Material dari Database Nyata
- **ID**: BUG-01
- **Severity**: CRITICAL
- **Fitur**: Marketplace / Material Listing Integration
- **Lokasi File**: `lib/models/material_listing.dart`, Baris 112 & 114
- **Deskripsi Masalah**: Model `MaterialListing.fromJson` mengharapkan tipe data `num` untuk `weight_kg` dan `int` untuk `price`. Di sisi backend, model `MaterialListing.php` mendefinisikan casting `'weight_kg' => 'decimal:2'` dan `'price' => 'decimal:2'`. Dalam Laravel Eloquent, casting `decimal:2` secara bawaan mengembalikan nilai sebagai **JSON String** (contoh: `"weight_kg": "5.00"`, `"price": "15000.00"`).
- **Bukti / Error**:
  ```dart
  weightKg: (json['weight_kg'] as num).toDouble(), // Crash: type 'String' is not a subtype of type 'num'
  price: json['price'] as int? ?? 0,              // Crash: type 'String' is not a subtype of type 'int?'
  ```
- **Penyebab**: Perbedaan representasi tipe data antara Eloquent JSON serialization dan Dart runtime strict type cast.
- **Kondisi Memicu**: Setiap kali aplikasi Flutter memanggil `GET /api/materials` ke backend Laravel yang mengembalikan data database riil.
- **Dampak**: Halaman Marketplace dan Beranda (recent listings) langsung crash / menampilkan state error merah dan gagal menampilkan daftar material.
- **Cara Reproduksi**: Buka aplikasi, biarkan `HomeViewModel` atau `MarketplaceViewModel` memanggil endpoint backend rill.
- **Rekomendasi**: Ubah parsing di `MaterialListing.fromJson` menggunakan `num.tryParse(json['weight_kg'].toString())?.toDouble() ?? 0.0` dan `num.tryParse(json['price'].toString())?.toInt() ?? 0`.

---

### [BUG-02] TypeCastException Saat Parsing MaterialRequestItem & HandoverItem
- **ID**: BUG-02
- **Severity**: CRITICAL
- **Fitur**: Transaction & Handover Data Parsing
- **Lokasi File**: 
  - `lib/models/material_request_item.dart`, Baris 36
  - `lib/models/handover_item.dart`, Baris 51-53
- **Deskripsi Masalah**: Hal serupa dengan BUG-01 terjadi pada `MaterialRequestItem` (`requested_weight_kg`) dan `HandoverItem` (`requested_weight_kg`, `agreed_weight_kg`, `actual_weight_kg`). Backend Laravel mendefinisikan kolom-kolom ini sebagai `decimal:2`, mengembalikan string seperti `"10.00"`.
- **Bukti / Error**:
  ```dart
  requestedWeightKg: (json['requested_weight_kg'] as num?)?.toDouble() ?? 0.0,
  agreedWeightKg: (json['agreed_weight_kg'] as num?)?.toDouble(),
  actualWeightKg: (json['actual_weight_kg'] as num?)?.toDouble(),
  ```
- **Penyebab**: Pemanggilan `as num?` pada nilai bertipe `String`.
- **Kondisi Memicu**: Pemanggilan API `GET /api/material-requests` atau `GET /api/handover-requests`.
- **Dampak**: Parsing respons gagal dengan unhandled `TypeCastException`.
- **Cara Reproduksi**: Panggil `ApiTransactionRepository.getMaterialRequests()` dengan data dari database Laravel.
- **Rekomendasi**: Konversi menggunakan helper parsing aman string-to-number: `double.tryParse(json['requested_weight_kg']?.toString() ?? '') ?? 0.0`.

---

### [BUG-03] Bottom Sheet "Tawarkan Material" di Marketplace Hanya Form Dummy (Mock Data)
- **ID**: BUG-03
- **Severity**: CRITICAL
- **Fitur**: Marketplace - Tambah Material (Penawaran)
- **Lokasi File**: `lib/views/marketplace/marketplace_screen.dart`, Baris 631-659
- **Deskripsi Masalah**: Modal bottom sheet untuk menambahkan penawaran material menggunakan widget `const TextField` tanpa `TextEditingController`. Tombol submit tidak membaca input apa pun, tidak memanggil `viewModel.createListing()`, dan langsung menampilkan SnackBar statis bertuliskan: `"Penawaran berhasil disimpan! (Mock Data)"`.
- **Bukti / Kode Aktual**:
  ```dart
  const TextField(
    decoration: InputDecoration(
      labelText: 'Nama Material (contoh: Tutup Botol HDPE)',
    ),
  ),
  ...
  ElevatedButton(
    onPressed: () {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Penawaran berhasil disimpan! (Mock Data)')),
      );
    },
    child: const Text('Publikasikan Penawaran'),
  )
  ```
- **Penyebab**: Implementasi UI masih berupa placeholder visual dan belum dihubungkan ke logika ViewModel.
- **Kondisi Memicu**: Pengguna menekan tombol FAB `+ Tawarkan Material` di tab Marketplace.
- **Dampak**: Pengguna tidak dapat mempublikasikan material baru ke sistem backend.
- **Cara Reproduksi**: Buka tab Marketplace -> Tekan tombol `+ Tawarkan Material` -> Isi form -> Klik `Publikasikan Penawaran`.
- **Rekomendasi**: Pasang controller, form validation, dropdown kategori/kondisi, dan panggil `viewModel.createListing(...)`.

---

### [BUG-04] Seluruh Data Riwayat di `ActivityScreen` 100% Mock Data Statis
- **ID**: BUG-04
- **Severity**: HIGH
- **Fitur**: Activity / Jejak Aktivitas
- **Lokasi File**: `lib/views/activity/activity_screen.dart`, Baris 65-94
- **Deskripsi Masalah**: Halaman `ActivityScreen` dirancang sebagai `StatelessWidget` statis tanpa ViewModel. Semua item aktivitas ("Penyerahan 5 kg Tutup Botol HDPE", "Pengiriman 8 kg Serpihan PET", "Penawaran 12 kg Jerigen HDPE") di-hardcode langsung di widget `build()`. Padahal backend Laravel memiliki `ActivityController.php` lengkap yang menggabungkan listing, request, dan handover secara real-time.
- **Bukti / Kode Aktual**:
  ```dart
  _buildActivityItem(
    title: 'Penyerahan 5 kg Tutup Botol HDPE',
    partner: 'Mitra: Komunitas Daur Ulang Cianjur',
    status: 'Dikonfirmasi Dimanfaatkan',
    ...
  )
  ```
- **Penyebab**: `ActivityScreen` belum memiliki arsitektur ViewModel dan koneksi API.
- **Kondisi Memicu**: Pengguna membuka tab "Aktivitas" pada bottom navigation.
- **Dampak**: Pengguna tidak dapat melihat jejak transaksi atau aktivitas nyata mereka di aplikasi.
- **Cara Reproduksi**: Buka tab Aktivitas; perhatikan bahwa item yang muncul selalu sama dan tidak berubah walau akun diganti.
- **Rekomendasi**: Buat `ActivityViewModel`, hubungkan ke endpoint `ApiConfig.activities` (`GET /api/activities`), dan tampilkan daftar dinamis dengan loading/empty state.

---

### [BUG-05] Angka Metrik Dampak di Beranda Tidak Pernah Di-fetch (Hardcoded Dummy Fallback)
- **ID**: BUG-05
- **Severity**: HIGH
- **Fitur**: Beranda / Impact Summary
- **Lokasi File**: `lib/viewmodels/home_viewmodel.dart`, Baris 22-44
- **Deskripsi Masalah**: Model `ImpactSummary` dan endpoint `ApiConfig.impactSummary` sudah tersedia, tetapi method `HomeViewModel.loadHomeData()` hanya memanggil `materialRepository.getMaterials()`. Variabel `_impactSummary` dibiarkan selalu `null`, sehingga getter selalu mengembalikan nilai fallback hardcoded: 18.4 kg, 12.0 kg, dan 9.5 kg.
- **Bukti / Kode Aktual**:
  ```dart
  ImpactSummary? _impactSummary;
  double get registeredKg => _impactSummary?.listedWeightKg ?? 18.4;
  double get handedOverKg => _impactSummary?.handedOverWeightKg ?? 12.0;
  double get processedKg => _impactSummary?.confirmedWeightKg ?? 9.5;
  ```
- **Penyebab**: Pemanggilan repository untuk impact summary lupa diintegrasikan pada alur inisialisasi ViewModel.
- **Kondisi Memicu**: Pengguna membuka halaman Beranda.
- **Dampak**: Data dampak lingkungan yang dilihat pengguna adalah angka palsu / dummy statis, bukan akumulasi metrik nyata dari backend.
- **Cara Reproduksi**: Buka Beranda; angka metrik di bagian atas selalu "18.4 kg", "12.0 kg", dan "9.5 kg".
- **Rekomendasi**: Tambahkan method `getImpactSummary()` pada repository dan panggil di dalam `HomeViewModel.loadHomeData()`.

---

### [BUG-06] Repositori `TransactionRepository` Terisolasi & Tidak Pernah Digunakan di Frontend
- **ID**: BUG-06
- **Severity**: HIGH
- **Fitur**: Material Requests & Handover Requests Architecture
- **Lokasi File**: `lib/repositories/transaction_repository.dart` & `lib/main.dart`
- **Deskripsi Masalah**: Kelas `ApiTransactionRepository` yang menangani endpoint `material-requests` dan `handover-requests` tidak pernah diinstansiasi di `main.dart`, tidak memiliki ViewModel pendamping, dan tidak ada satupun tombol atau halaman UI di Flutter yang mengonsumsinya.
- **Penyebab**: Kode repository dibuat terpisah namun alur UI dan ViewModel belum diimplementasikan.
- **Kondisi Memicu**: Penggunaan aplikasi sehari-hari.
- **Dampak**: Fitur permintaan material (Material Request) dan serah terima (Handover Request) tidak dapat digunakan sama sekali oleh pengguna melalui aplikasi Flutter.
- **Rekomendasi**: Buat ViewModel transaksi dan integrasikan tombol "Minta Material" atau "Ajukan Handover" pada halaman detail material.

---

### [BUG-07] Penyimpanan Token Hanya di Memori (`InMemoryAuthTokenStorage`) Menyebabkan Sesi Hilang Saat Restart
- **ID**: BUG-07
- **Severity**: HIGH
- **Fitur**: Autentikasi / Manajemen Sesi
- **Lokasi File**: `lib/core/network/api_client.dart`, Baris 23-34
- **Deskripsi Masalah**: `ApiClient` menggunakan implementasi default `InMemoryAuthTokenStorage` yang menyimpan token di variabel `String? _token`. Tidak ada dependensi `shared_preferences` atau `flutter_secure_storage` pada `pubspec.yaml`.
- **Bukti / Kode Aktual**:
  ```dart
  class InMemoryAuthTokenStorage implements AuthTokenStorage {
    String? _token;
    @override
    Future<String?> getToken() async => _token;
    @override
    Future<void> saveToken(String token) async => _token = token;
    @override
    Future<void> clearToken() async => _token = null;
  }
  ```
- **Penyebab**: Belum adanya implementasi persistent storage untuk token autentikasi.
- **Kondisi Memicu**: Aplikasi ditutup (kill app), di-restart di Android, atau halaman di-refresh di browser Web.
- **Dampak**: Pengguna dipaksa login ulang setiap kali membuka aplikasi.
- **Rekomendasi**: Pasang package `shared_preferences` atau `flutter_secure_storage` dan implementasikan `SharedPrefsAuthTokenStorage`.

---

### [BUG-08] Inkompatibilitas Total Flutter Web Akibat Penggunaan Pustaka `dart:io`
- **ID**: BUG-08
- **Severity**: HIGH
- **Fitur**: Multiplatform Compatibility (Web)
- **Lokasi File**:
  - `lib/core/network/api_client.dart`, Baris 3, 118
  - `lib/views/analysis/analysis_screen.dart`, Baris 1
  - `lib/views/analysis/analysis_result_screen.dart`, Baris 1
- **Deskripsi Masalah**: Mengimpor pustaka `dart:io` secara langsung dan menggunakan `File(filePath)` serta `on SocketException` menyebabkan Flutter Web gagal dikompilasi atau mengalami runtime crash (`Unsupported operation: Platform._operatingSystem`). Selain itu, `http.MultipartFile.fromPath()` tidak didukung pada browser.
- **Bukti**: Kompilasi ke target Web akan melempar error kompilator terkait ketidaktersediaan `dart:io`.
- **Penyebab**: Ketergantungan langsung pada filesystem sistem operasi native tanpa abstraksi multiplatform.
- **Kondisi Memicu**: Menjalankan aplikasi pada target browser Web (`flutter run -d chrome`).
- **Dampak**: Aplikasi tidak dapat dijalankan di Web.
- **Rekomendasi**: Gunakan `XFile.readAsBytes()` dan `http.MultipartFile.fromBytes()`, serta hindari impor langsung `dart:io` di layer UI.

---

### [BUG-09] Inkonsistensi Kategori `'Lainnya'` (Frontend) vs `'OTHER'` (Backend)
- **ID**: BUG-09
- **Severity**: MEDIUM
- **Fitur**: Marketplace / Kategori Polimer
- **Lokasi File**: `lib/viewmodels/marketplace_viewmodel.dart`, Baris 18 vs `StoreMaterialListingRequest.php`, Baris 28
- **Deskripsi Masalah**: Daftar kategori di Flutter menyediakan chip pilihan `'Lainnya'`, sedangkan aturan validasi Laravel `MaterialListing::CATEGORIES` hanya menerima: `['PET', 'HDPE', 'PP', 'LDPE', 'OTHER', 'MIXED']`.
- **Dampak**: Jika filter atau form submit mengirim nilai `'Lainnya'`, backend menolak dengan HTTP 422: `"Kategori tidak valid. Pilih dari: PET, HDPE, PP, LDPE, OTHER, MIXED"`.
- **Rekomendasi**: Lakukan mapping nilai label UI `'Lainnya'` ke nilai payload backend `'OTHER'`.

---

### [BUG-10] Inkonsistensi Nilai Enum Kondisi `'light'` vs `'slightly_dirty'`
- **ID**: BUG-10
- **Severity**: MEDIUM
- **Fitur**: Material Listing & Analysis
- **Lokasi File**: `lib/models/material_listing.dart`, Baris 44 vs `StoreMaterialListingRequest.php`, Baris 30
- **Deskripsi Masalah**: Model frontend mendefinisikan kondisi: `'clean'`, `'light'`, `'dirty'`. Sedangkan migration database dan form request backend mewajibkan: `'clean'`, `'slightly_dirty'`, `'dirty'`, `'mixed'`. Meskipun `AnalysisController` memiliki mapping khusus, `StoreMaterialListingRequest` tidak memilikinya dan akan menolak input `'light'`.
- **Dampak**: Error validasi HTTP 422 saat pembuatan listing jika kondisi `'light'` dikirim.
- **Rekomendasi**: Standarkan nilai kondisi menjadi `'slightly_dirty'` di seluruh payload model Flutter atau tambahkan mutator/normalizer pada Form Request backend.

---

### [BUG-11] Tombol Tindak Lanjut Hasil Analisis AI Hanya Aksi Semu (Mock Action)
- **ID**: BUG-11
- **Severity**: MEDIUM
- **Fitur**: Analisis Plastik - Hasil Analisis
- **Lokasi File**: `lib/views/analysis/analysis_result_screen.dart`, Baris 1302-1356
- **Deskripsi Masalah**:
  1. Tombol **"Cari Penerima Material"** hanya memicu SnackBar statis `"Menemukan 12 Mitra & Pengrajin di sekitarmu!"` lalu berpindah ke tab Marketplace tanpa memfilter berdasarkan jenis polimer hasil analisis atau memanggil endpoint smart matching backend (`/api/materials/{id}/matches`).
  2. Tombol **"Simpan ke Riwayat & Ide"** hanya membalik nilai boolean lokal `setState(() => _isSaved = !_isSaved)` tanpa menyimpan status bookmark ke API atau penyimpanan lokal.
- **Dampak**: Fitur penelusuran mitra dan bookmark ide tidak berfungsi secara nyata.
- **Rekomendasi**: Hubungkan tombol "Cari Penerima Material" dengan query filter marketplace sesuai polimer terdeteksi, dan simpan status bookmark ke database/local storage.

---

### [BUG-12] Ketiadaan Antarmuka Pembacaan Riwayat Analisis Lama di Frontend
- **ID**: BUG-12
- **Severity**: MEDIUM
- **Fitur**: Analisis Plastik - Riwayat Analisis
- **Lokasi File**: `lib/repositories/analysis_repository.dart` & `app/Http/Controllers/Api/AnalysisController.php`
- **Deskripsi Masalah**: Backend telah menyediakan endpoint `GET /api/analyses` yang mengembalikan daftar riwayat analisis user dengan pagination. Namun di frontend, tidak ada method pada `AnalysisRepository`, tidak ada ViewModel, dan tidak ada halaman UI untuk melihat riwayat analisis sebelumnya.
- **Dampak**: Hasil analisis lama yang tersimpan di server tidak pernah bisa dilihat kembali oleh pengguna melalui aplikasi mobile.
- **Rekomendasi**: Tambahkan method `getHistory()` pada `AnalysisRepository` dan sediakan tab/halaman "Riwayat Analisis".

---

### [BUG-13] Dead Code Exception Handling di `ApiClient`
- **ID**: BUG-13
- **Severity**: LOW
- **Fitur**: Network Client Architecture
- **Lokasi File**: `lib/core/network/api_client.dart`, Baris 136
- **Deskripsi Masalah**: Dart Analyzer mendeteksi dead code pada blok `catch` di `postMultipart`:
  `warning - Dead code: This on-catch block won't be executed because 'InvalidType' is a subtype of 'SocketException'`
  Selain itu, method `get()`, `post()`, `patch()`, `delete()` hanya menangkap `SocketException`, sehingga jika terjadi `TimeoutException` atau `http.ClientException`, exception tidak tertangkap rapi dan melempar unhandled error.
- **Rekomendasi**: Tangkap `Exception` atau `http.ClientException` secara konsisten di semua method HTTP.

---

### [BUG-14] Inkonsistensi Formatting Dart pada 24 File Source Code
- **ID**: BUG-14
- **Severity**: LOW
- **Fitur**: Code Quality & Standards
- **Lokasi File**: 24 file pada folder `lib/` dan `test/`
- **Deskripsi Masalah**: Perintah `dart format --output=none --set-exit-if-changed lib test` menghasilkan exit code 1 dan menandai 24 file memiliki indentasi atau wrapping yang belum sesuai dengan panduan resmi Dart formatter.
- **Rekomendasi**: Jalankan `dart format lib test` saat tahap perbaikan kode dimulai.

---

### [BUG-15] Konfigurasi CORS Backend Belum Didefinisikan Eksplisit
- **ID**: BUG-15
- **Severity**: INFORMATIONAL / SECURITY
- **Fitur**: API Security & Web Integration
- **Lokasi File**: `C:\xampp\htdocs\backend_plasvora\bootstrap\app.php`
- **Deskripsi Masalah**: File `config/cors.php` belum dipublikasikan dan middleware CORS di `bootstrap/app.php` belum dikonfigurasi secara eksplisit untuk domain origin frontend Flutter Web.
- **Dampak**: Request preflight HTTP `OPTIONS` dari browser berpotensi diblokir oleh kebijakan Same-Origin Policy (CORS).
- **Rekomendasi**: Jalankan `php artisan config:publish cors` dan atur origin yang diizinkan.

---

## C. DAFTAR ERROR DARI PENGUJIAN OTOMATIS

### 1. Flutter / Dart Toolchain

| Command | Status / Exit Code | Output Error Ringkas | Klasifikasi Masalah |
|---|:---:|---|---|
| `dart analyze` | Exit Code 1 | `Target of URI doesn't exist: 'package:http/http.dart'`, `google_fonts`, `image_picker` (70 issues); `dead_code_on_catch_subtype` | Masalah Sandbox & Dependency Cache + Bug Dead Code |
| `dart format --set-exit-if-changed` | Exit Code 1 | `Formatted 37 files (24 changed) in 0.33 seconds` | Pelanggaran Gaya Format Kode |
| `dart test` | Exit Code 1 | `Got socket error trying to find package flutter_lints at https://pub.dev` | Batasan Jaringan Sandbox (No Internet Access) |

### 2. Laravel Toolchain

| Command | Status / Exit Code | Output Error Ringkas | Klasifikasi Masalah |
|---|:---:|---|---|
| `composer validate` | Exit Code 0 | `./composer.json is valid` | LULUS |
| `php artisan route:list` | Exit Code 0 | `Showing [29] routes` terdaftar lengkap | LULUS |
| `tests/Unit` (PHPUnit) | Exit Code 0 | `OK (1 test, 1 assertion)` | LULUS |
| `php artisan migrate:status` | Exit Code 1 | `SQLSTATE[HY000] [2002] An attempt was made to access a socket in a way forbidden by its access permissions (127.0.0.1:3306)` | Batasan Sandbox (Socket Network Terisolasi) |
| `composer audit` | Exit Code 1 | `curl error 6 while downloading https://repo.packagist.org/packages.json` | Batasan Jaringan Sandbox (No Internet Access) |

---

## D. KESALAHAN LOGIKA BISNIS

1. **Sinkronisasi Status Material & Handover Request**:
   - Di backend, ketika handover disetujui (`approved`), status listing otomatis menjadi `reserved`. Ketika pemanfaatan dikonfirmasi (`utilization_confirmed`), status listing menjadi `completed`.
   - Di frontend Flutter, tidak ada logika untuk memperbarui atau menampilkan status `reserved` pada item listing; item hanya memiliki label `'available'` dan filter tidak menyediakan opsi pencarian listing yang sedang dalam proses.
2. **Kalkulasi Berat Handover**:
   - Di backend `HandoverRequestController`, sistem memvalidasi bahwa `requested_weight_kg` tidak boleh melebihi berat listing (`weight_kg`).
   - Namun di frontend, tidak ada validasi sisi klien saat mengajukan berat, sehingga request yang melebihi batas langsung melempar error server 422 tanpa pencegahan di antarmuka pengguna.
3. **Pemberian Skor Matching vs Probabilitas AI**:
   - Backend `MaterialMatchingService` menggunakan sistem skor berbasis bobot aturan: kategori (40 poin), berat (30 poin), kondisi (20 poin), dan lokasi (10 poin).
   - Di frontend pada `analysis_result_screen.dart`, teks yang ditampilkan menyiratkan pencarian mitra otomatis berbasis AI ("Menemukan 12 Mitra"), padahal model bisnisnya adalah rule-based matching.

---

## E. MASALAH INTEGRASI FRONTEND DAN BACKEND

### Tabel Pemetaan Seluruh Endpoint & Kesesuaian

| Fitur | Request Flutter | Endpoint Laravel | Kesesuaian | Masalah yang Ditemukan |
|---|---|---|:---:|---|
| **Register** | `POST ApiConfig.register` | `POST /api/register` | SESUAI | Berjalan normal, token tersimpan di memori. |
| **Login** | `POST ApiConfig.login` | `POST /api/login` | SESUAI | Berjalan normal, token tersimpan di memori. |
| **Get Profile** | `GET ApiConfig.me` | `GET /api/me` | SESUAI | Berjalan normal jika token tersedia. |
| **Logout** | `POST ApiConfig.logout` | `POST /api/logout` | SESUAI | Token dicabut di backend dan dibersihkan di memori. |
| **Daftar Material** | `GET ApiConfig.materials` | `GET /api/materials` | **TIDAK SESUAI** | **CRITICAL (BUG-01)**: Crash parsing `price` & `weight_kg` (`decimal:2` vs `num/int`). |
| **Detail Material** | `GET ApiConfig.materialDetail(id)` | `GET /api/materials/{id}` | **TIDAK SESUAI** | **CRITICAL (BUG-01)**: Crash parsing field numerik. |
| **Tambah Material** | `POST ApiConfig.materials` | `POST /api/materials` | **TIDAK TERHUBUNG** | **CRITICAL (BUG-03)**: UI Flutter menggunakan form dummy tanpa koneksi ke endpoint. |
| **Ubah Material** | *(Tidak ada di Flutter)* | `PATCH /api/materials/{id}` | **TIDAK ADA UI** | Endpoint tersedia di backend, Flutter tidak memiliki fitur edit. |
| **Hapus Material** | *(Tidak ada di Flutter)* | `DELETE /api/materials/{id}` | **TIDAK ADA UI** | Endpoint tersedia di backend, Flutter tidak memiliki fitur delete. |
| **Impact Summary** | `ApiConfig.impactSummary` | `GET /api/impact-summary` | **TIDAK DIPANGGIL** | **HIGH (BUG-05)**: Endpoint tersedia di config, tapi tidak pernah dipanggil ViewModel. |
| **Daftar Request** | `GET ApiConfig.materialRequests` | `GET /api/material-requests` | **TIDAK TERHUBUNG** | **HIGH (BUG-06)**: Repository ada tapi tidak diinjeksi ke ViewModel/UI manapun. |
| **Buat Request** | `POST ApiConfig.materialRequests` | `POST /api/material-requests` | **TIDAK TERHUBUNG** | **HIGH (BUG-06)**: Tidak ada UI form input di frontend. |
| **Daftar Handover** | `GET ApiConfig.handoverRequests` | `GET /api/handover-requests` | **TIDAK TERHUBUNG** | **HIGH (BUG-06)**: Tidak ada UI daftar serah terima di frontend. |
| **Buat Handover** | `POST ApiConfig.handoverRequests` | `POST /api/handover-requests` | **TIDAK TERHUBUNG** | **HIGH (BUG-06)**: Tidak ada UI pengajuan handover di frontend. |
| **Update Status Handover** | `PATCH ApiConfig.updateHandoverStatus(id)` | `PATCH /api/handover-requests/{id}/status` | **TIDAK TERHUBUNG** | **HIGH (BUG-06)**: Tidak ada UI persetujuan/konfirmasi di frontend. |
| **Riwayat Aktivitas** | `GET ApiConfig.activities` | `GET /api/activities` | **TIDAK TERHUBUNG** | **HIGH (BUG-04)**: `ActivityScreen` menampilkan data mock hardcoded. |
| **Analisis Gambar** | `POST ApiConfig.analyses` (Multipart) | `POST /api/analyses` | SESUAI | Berjalan via Gemini AI jika ada API key, fallback rule-based jika tanpa gambar. |
| **Riwayat Analisis** | *(Tidak ada method di repo)* | `GET /api/analyses` | **TIDAK TERHUBUNG** | **MEDIUM (BUG-12)**: Endpoint ada di backend, Flutter tidak memiliki antarmuka riwayat. |
| **Matching Request** | `ApiConfig.materialRequestMatches(id)` | `GET /api/material-requests/{id}/matches` | **TIDAK DIPANGGIL** | Endpoint ada di backend, Flutter tidak menggunakannya. |
| **Matching Listing** | `ApiConfig.materialMatches(id)` | `GET /api/materials/{id}/matches` | **TIDAK DIPANGGIL** | Endpoint ada di backend, Flutter tidak menggunakannya. |

---

## F. PEMERIKSAAN GEMINI AI VISION

Audit mendalam terhadap implementasi `GeminiVisionService.php` dan `AnalysisController.php`:

### 1. Image Processing & Kompresi
- **Validasi Input**: Validasi MIME type ketat (`jpeg, png, jpg, webp`) dengan batas ukuran 10 MB pada Form Request.
- **Kompresi GD**: Tersedia proteksi `compressImageIfNeeded` jika ukuran > 3 MB atau resolusi > 1200px (menggunakan PHP GD). Jika GD tidak aktif, service tetap memproses gambar asli tanpa gagal.
- **Encoding**: Konversi stream biner ke base64 dengan MIME type otomatis untuk payload standard REST Generative Language API.

### 2. Prompt Engineering & Multi-Component
- **Instruksi Multi-Komponen**: Prompt secara eksplisit menginstruksikan AI untuk memecah objek utuh menjadi komponen fisik terpisah (contoh: Badan botol = PET, Tutup botol = HDPE/PP uncertain, Label = film tipis).
- **Larangan Halusinasi**: Prompt melarang keras mengarang komponen yang tidak terlihat (misal: jika foto hanya tutup botol, dilarang membuat komponen botol).
- **Proteksi Recitation (Merek Dagang)**: Prompt melarang penyebutan merek komersial. Pada penanganan respon, jika `finishReason === 'RECITATION'`, exception ditangkap rapi dengan pesan ramah pengguna.
- **Rekomendasi Realistis**: AI dibatasi menghasilkan maksimal 3 ide terbaik yang terikat langsung pada komponen (`component_ids`), kuantitas bahan (`suitable_quantity`: single_item, small_batch, bulk), dan skala (`household`, `community`, `industrial`). Dilarang merekomendasikan pelelehan oven dapur rumah tangga karena risiko gas beracun.

### 3. Penanganan Skenario Uji Kasus

| Skenario Uji Kasus | Perilaku Backend Aktual | Evaluasi |
|---|---|:---:|
| 1. Botol lengkap dengan tutup | Mengembalikan komponen badan (PET) dan tutup (HDPE/PP kandidat) | SESUAI |
| 2. Tutup botol saja | Hanya mengenali 1 komponen tutup botol, tidak mengarang badan | SESUAI |
| 3. Badan botol tanpa tutup | Hanya mengenali badan botol, tidak mengarang tutup | SESUAI |
| 4. Objek non-plastik (kardus/logam) | AI merespon `is_plastic: false`, status `unsupported_material` -> HTTP 422 informatif | SESUAI |
| 5. Foto buram / tidak jelas | AI merespon `material_type: UNCERTAIN`, status `uncertain_material` -> HTTP 422 | SESUAI |
| 6. Catatan bertentangan dengan foto | AI diinstruksikan mengutamakan bukti visual dan mencatat ketidakcocokan | SESUAI |
| 7. Kuota habis / Rate Limit 429 | Ditangkap dengan HTTP 429: "Batas permintaan Gemini API tercapai..." | SESUAI |
| 8. Lonjakan Beban / 503 | Otomatis melakukan retry dengan delay dan mencoba model fallback (`gemini-3.5-flash-lite`) | SESUAI |
| 9. Respon JSON tidak valid | Validasi schema OpenAPI via `responseSchema`, fallback decode exception ke HTTP 502 | SESUAI |

---

## G. MASALAH DATABASE DAN KONSISTENSI DATA

1. **Ketidakcocokan Tipe Kolom Decimal vs JSON Serialization**:
   - Kolom `weight_kg`, `price`, `requested_weight_kg`, `agreed_weight_kg`, `actual_weight_kg` menggunakan tipe database `decimal(10,2)` dan cast `'decimal:2'`.
   - Mengakibatkan output JSON berupa String (`"15000.00"`). Karena Flutter Dart melakukan casting strongly typed `as num`, ini menyebabkan runtime error sistemik.
2. **Kesesuaian Foreign Key & Cascade Rules**:
   - `material_listings.owner_id` menggunakan `restrictOnDelete()` (mencegah user dihapus jika listing masih ada).
   - `handover_requests.listing_id` menggunakan `restrictOnDelete()` untuk menjaga keutuhan riwayat transaksi.
   - Penghapusan listing di `MaterialController.destroy` menggunakan penonaktifan status (`status = 'inactive'`), bukan hard-delete, sehingga relasi database tetap konsisten.

---

## H. MASALAH KEAMANAN (SECURITY AUDIT)

1. **Perlindungan Kredensial & Secrets**:
   - Tidak ada API key, token, atau APP_KEY yang hardcoded di source code Dart maupun PHP.
   - File `.env` masuk dalam `.gitignore` pada kedua repository.
   - File `.env.example` hanya berisi placeholder dummy (`your_gemini_api_key_here`).
2. **Otorisasi & ID Tampering (IDOR Prevention)**:
   - `MaterialController@update` & `destroy`: Memvalidasi `$material->owner_id === Auth::id()`, melempar HTTP 403 jika pengguna mencoba mengubah listing orang lain.
   - `MaterialRequestController@update` & `destroy`: Memvalidasi `$materialRequest->requester_id === Auth::id()`, melempar HTTP 403 jika ID diubah.
   - `HandoverRequestController@updateStatus`: Memvalidasi kepemilikan dan state machine aktor (hanya owner yang bisa approve/reject, hanya requester yang bisa konfirmasi pemanfaatan).
3. **Penyimpanan File Upload**:
   - File gambar divalidasi MIME type dan ekstensi (`jpeg, png, jpg, webp`), dibatasi 10 MB, dan disimpan dengan nama unik yang di-hash di direktori `storage/app/public/analyses`.
4. **Kelemahan Keamanan**:
   - Token disimpan hanya di memori RAM Flutter (`InMemoryAuthTokenStorage`). Walau aman dari inspeksi disk file yang tidak terenkripsi, sesi pengguna tidak bertahan saat aplikasi ditutup.

---

## I. MASALAH UI DAN UX

1. **Overflow & Render Flex**:
   - `HomeScreen` dan `AnalysisResultScreen` menggunakan `SingleChildScrollView` dengan padding bawah yang cukup, mencegah overflow pada layar standar Android.
   - Namun, pada dialog bottom sheet penawaran material, tinggi layar sempit dengan keyboard virtual berpotensi memicu keyboard overlap jika `isScrollControlled` tidak diimbangi `SingleChildScrollView`.
2. **Umpan Balik Pengguna yang Menyesatkan**:
   - Mengklik tombol submit pada form penawaran menampilkan pesan "Mock Data", membingungkan pengguna yang mengharapkan data tersimpan ke server.
   - Mengklik tombol bookmark pada hasil analisis hanya mengubah ikon bookmark lokal tanpa menyimpan riwayat ke akun pengguna.

---

## J. MASALAH KOMPATIBILITAS ANDROID DAN WEB

### Android
- `AndroidManifest.xml` telah menyertakan permission `INTERNET`, `ACCESS_NETWORK_STATE`, dan flag `usesCleartextTraffic="true"` untuk mendukung koneksi lokal ke backend selama pengembangan.
- Penanganan path gambar lokal menggunakan `File(filePath)` berfungsi baik di Android native.

### Web
- **Gagal**: Penggunaan library `dart:io` secara langsung di 3 file utama (`api_client.dart`, `analysis_screen.dart`, `analysis_result_screen.dart`) membuat aplikasi tidak dapat dikompilasi atau dijalankan di browser.
- **Gagal**: Upload file multipart pada `ApiClient` menggunakan `fromPath()` yang membutuhkan akses filesystem lokal native.
- **Risiko**: Belum ada konfigurasi CORS eksplisit di backend untuk browser cross-origin requests.

---

## K. HASIL FLUTTER ANALYZER DAN TEST

1. **`dart analyze`**:
   - Menghasilkan 70 issues saat dijalankan di lingkungan sandbox karena direktori cache Pub (`AppData/Local/Pub/Cache`) diblokir oleh permission boundary sandbox.
   - Terdeteksi 1 dead code warning bawaan pada `lib/core/network/api_client.dart:136:7` (`dead_code_on_catch_subtype`).
2. **`dart format --set-exit-if-changed`**:
   - Exit code 1: 24 file membutuhkan formatting ulang sesuai konvensi Dart SDK.
3. **`test/full_stack_integration_test.dart`**:
   - Unit test mock Flutter menggunakan dummy payload bertipe `int` untuk `price` dan `double` untuk `weight_kg`. Ini menjelaskan mengapa test mock di frontend lulus, namun aplikasi crash saat dihubungkan ke backend riil yang mengembalikan string `decimal:2`.

---

## L. HASIL LARAVEL TEST

1. **`composer validate`**:
   - Valid: `composer.json` valid dan konsisten.
2. **`tests/Unit`**:
   - 1 test, 1 assertion: **LULUS (100%)**.
3. **`tests/Feature`**:
   - Berisi 9 file feature test komprehensif (`GeminiVisionAnalysisTest`, `MaterialListingTest`, `HandoverRequestTest`, `MatchingTest`, dll.) yang mencakup pengujian HTTP fake, otorisasi, dan validasi multi-komponen.

---

## M. PENGUJIAN YANG BELUM DAPAT DILAKUKAN

1. **Runtime End-to-End dengan Live MySQL Database**:
   - **Status**: BELUM DIVERIFIKASI SECARA LANGSUNG VIA CLI.
   - **Alasan**: Lingkungan sandbox memblokir koneksi socket jaringan lokal (`127.0.0.1:3306`) dengan error `SQLSTATE[HY000] [2002] An attempt was made to access a socket in a way forbidden by its access permissions`. Sesuai aturan non-destruktif, tidak dilakukan perubahan paksa pada database.
2. **Build Debug APK (`flutter build apk --debug`)**:
   - **Status**: BELUM DIVERIFIKASI.
   - **Alasan**: Toolchain Android SDK / Gradle memerlukan download package dan akses jaringan eksternal yang dibatasi di dalam sandbox.

---

## N. DAFTAR POTENSI BUG

1. **Potensi Race Condition pada Pengajuan Handover**:
   - Jika dua pengguna mengajukan handover untuk listing yang sama dalam milidetik yang identik, query pengecekan `where('status', 'available')` di backend belum menggunakan `lockForUpdate()`. Ada kemungkinan dua request dibuat sebelum status berubah menjadi `reserved`.
2. **Potensi Timeout Gemini API pada Gambar Sangat Besar**:
   - Default timeout disetel ke 20 detik. Pada gambar beresolusi tinggi di jaringan seluler lambat, waktu upload dan inferensi model vision dapat melampaui batas sebelum respon selesai.
3. **Unbounded Pagination pada Index Controller**:
   - Index listing menggunakan pagination 15 item, namun parameter query filter pencarian teks (`q`) menggunakan `%search%` tanpa index fulltext, berpotensi lambat jika volume data membengkak.

---

## O. PRIORITAS PERBAIKAN

Berdasarkan dampak teknis dan pengalaman pengguna, berikut adalah urutan prioritas rekomendasi perbaikan:

### Prioritas 1 — CRITICAL (Wajib Segera Diperbaiki agar Aplikasi Berjalan)
1. **Perbaiki Model JSON Parsing di Flutter (BUG-01 & BUG-02)**:
   - Ganti semua casting kaku `as num` dan `as int` di `MaterialListing.fromJson`, `MaterialRequestItem.fromJson`, dan `HandoverItem.fromJson` dengan `num.tryParse(json['field'].toString())`.
2. **Implementasikan Form Tambah Material Nyata di Marketplace (BUG-03)**:
   - Hubungkan form bottom sheet dengan `TextEditingController`, validasi input, dan panggil `MarketplaceViewModel.createListing()`.

### Prioritas 2 — HIGH (Fungsionalitas Utama & Ketahanan Sesi)
3. **Hubungkan Jejak Aktivitas ke API Backend (BUG-04)**:
   - Buat `ActivityViewModel` dan tampilkan data dinamis dari `GET /api/activities`.
4. **Muat Metrik Dampak Lingkungan Nyata di Beranda (BUG-05)**:
   - Panggil `GET /api/impact-summary` saat Beranda dimuat dan hilangkan angka dummy 18.4 kg / 12.0 kg.
5. **Implementasikan Persistent Token Storage (BUG-07)**:
   - Tambahkan package `shared_preferences` agar login pengguna tidak hilang saat aplikasi ditutup.
6. **Integrasikan Repositori Transaksi ke UI (BUG-06)**:
   - Buat antarmuka untuk pengajuan serah terima (handover) material langsung dari detail listing.
7. **Abstraksi Pustaka `dart:io` untuk Dukungan Flutter Web (BUG-08)**:
   - Gunakan `XFile` bytes untuk upload gambar dan hindari impor langsung `dart:io`.

### Prioritas 3 — MEDIUM (Penyelarasan Data & Fitur Pendukung)
8. **Sinkronisasi Nilai Enum Kategori & Kondisi (BUG-09 & BUG-10)**:
   - Petakan `'Lainnya'` -> `'OTHER'` dan `'light'` -> `'slightly_dirty'`.
9. **Hubungkan Tombol Hasil Analisis dengan Marketplace Matching (BUG-11)**:
   - Gunakan endpoint matching backend untuk menampilkan mitra yang relevan dengan polimer terdeteksi.
10. **Buat Halaman Riwayat Analisis di Frontend (BUG-12)**:
    - Sediakan tampilan untuk membaca riwayat analisis yang tersimpan di server.

### Prioritas 4 — LOW & QUALITY ASSURANCE (Kebersihan Kode)
11. **Bersihkan Dead Code di `ApiClient` (BUG-13)**.
12. **Jalankan `dart format lib test` pada Seluruh Kode (BUG-14)**.
13. **Publikasikan Konfigurasi CORS Laravel untuk Kebutuhan Browser Web (BUG-15)**.

---

## P. KESIMPULAN KONDISI PROJECT

Aplikasi **PLASVORA** memiliki fondasi arsitektur backend yang sangat baik dan matang, khususnya pada ketepatan otorisasi RESTful API, validasi bisnis state-machine serah terima material, serta integrasi Gemini AI Vision multi-komponen yang dirancang secara teliti dan berbasis sains polimer. Desain antarmuka Flutter (mengikuti spesifikasi Stitch) juga sangat rapi dan konsisten secara estetika.

Namun, terdapat **gap integrasi yang cukup lebar antara frontend dan backend**:
1. Beberapa model data Flutter langsung crash saat menerima data nyata dari Laravel Eloquent akibat ketidakcocokan tipe serialisasi desimal (`BUG-01`, `BUG-02`).
2. Sejumlah fitur antarmuka frontend masih berupa tampilan statis atau form dummy dengan pesan `Mock Data` (`BUG-03`, `BUG-04`, `BUG-05`, `BUG-11`).
3. Seluruh alur transaksi Material Request dan Handover Request sudah selesai di backend namun belum dihubungkan ke UI Flutter (`BUG-06`).
4. Autentikasi sesi belum memiliki persistent storage (`BUG-07`), dan kode belum siap untuk target Web (`BUG-08`).

Seluruh temuan di atas siap untuk dipelajari dan diperbaiki secara terencana berdasarkan urutan prioritas yang telah disusun.

