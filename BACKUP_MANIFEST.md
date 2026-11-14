# BACKUP MANIFEST — PLASVORA BUILD PREPARATION

**Tanggal Pembuatan**: 7 November 2026  
**Tujuan**: Pencatatan backup fisik file asli di luar workspace project sebelum dilakukan penyesuaian esensial untuk koneksi HTTPS Ngrok & perbaikan parsing desimal Eloquent sebelum build APK release.

---

## 1. Lokasi Penyimpanan Backup Fisik (Di Luar Folder Project)

Direktori Root Backup:
`C:\Users\PPLG\.gemini\antigravity\brain\ad4f1028-05be-433f-9c28-ee55610e9d07\backup\`

Struktur Folder Backup yang Dipertahankan:
```
backup/
└── lib/
    ├── core/
    │   └── network/
    │       └── api_client.dart
    └── models/
        ├── material_listing.dart
        ├── material_request_item.dart
        └── handover_item.dart
```

---

## 2. Catatan File yang Diubah & Alasan Perubahan

### File 1: `lib/core/network/api_client.dart`
- **Lokasi Backup**:
  `C:\Users\PPLG\.gemini\antigravity\brain\ad4f1028-05be-433f-9c28-ee55610e9d07\backup\lib\core\network\api_client.dart`
- **Alasan Perubahan**:
  Domain tunnel gratis Ngrok (`*.ngrok-free.app`) menyajikan halaman peringatan browser HTML (interstitial browser warning) pada HTTP GET request. Tanpa header `ngrok-skip-browser-warning: true`, panggilan API GET dari APK HP akan menerima respon HTML `<!DOCTYPE html>` bukan JSON, memicu `FormatException` saat `jsonDecode()`.
- **Perubahan Kode**:
  - Ditambahkan `'ngrok-skip-browser-warning': 'true'` pada method `_headers()` (Baris 54).
  - Ditambahkan `request.headers['ngrok-skip-browser-warning'] = 'true';` pada method `postMultipart()` (Baris 107).

---

### File 2: `lib/models/material_listing.dart`
- **Lokasi Backup**:
  `C:\Users\PPLG\.gemini\antigravity\brain\ad4f1028-05be-433f-9c28-ee55610e9d07\backup\lib\models\material_listing.dart`
- **Alasan Perubahan**:
  Backend Laravel meng-cast `weight_kg` dan `price` sebagai `decimal:2`. Dalam serialisasi JSON Eloquent, nilai tersebut direpresentasikan sebagai String (contoh: `"5.00"` dan `"15000.00"`). Kode Flutter sebelumnya menggunakan `(json['weight_kg'] as num).toDouble()` dan `json['price'] as int?`, yang memicu unhandled runtime `TypeCastException` dan membuat halaman Marketplace crash saat dibuka via APK.
- **Perubahan Kode**:
  - `weightKg` kini diparsing dengan pengecekan `json['weight_kg'] is num ? ... : double.tryParse(...) ?? 0.0`.
  - `price` kini diparsing dengan pengecekan `json['price'] is int ? ... : num.tryParse(...)?.toInt() ?? 0`.
  - `id`, `owner_id`, `distanceKm`, dan `isFree` juga diamankan dari string mismatch.

---

### File 3: `lib/models/material_request_item.dart`
- **Lokasi Backup**:
  `C:\Users\PPLG\.gemini\antigravity\brain\ad4f1028-05be-433f-9c28-ee55610e9d07\backup\lib\models\material_request_item.dart`
- **Alasan Perubahan**:
  Field `requested_weight_kg` pada `material_requests` di-cast `decimal:2` di Laravel, mengembalikan string desimal yang memicu `TypeCastException` saat dibaca model.
- **Perubahan Kode**:
  - `requestedWeightKg` kini diparsing fleksibel mendukung `num` maupun `String` desimal via `double.tryParse`.

---

### File 4: `lib/models/handover_item.dart`
- **Lokasi Backup**:
  `C:\Users\PPLG\.gemini\antigravity\brain\ad4f1028-05be-433f-9c28-ee55610e9d07\backup\lib\models\handover_item.dart`
- **Alasan Perubahan**:
  Field `requested_weight_kg`, `agreed_weight_kg`, dan `actual_weight_kg` di-cast `decimal:2` di Laravel, mengembalikan string desimal yang memicu crash saat transisi data serah terima.
- **Perubahan Kode**:
  - Ketiga atribut numerik diparsing dengan pengecekan ganda (`is num ? ... : double.tryParse(...)`).

---

## 3. Verifikasi Keutuhan
- Backup file asli tersimpan aman dan tidak ditimpa.
- Pemulihan file dapat dilakukan kapan saja dengan menyalin kembali file dari folder backup di atas ke dalam folder project tanpa bergantung pada Git.


---

## 4. Backup Khusus Fix Kompatibilitas TLS Android 7.0 (ISRG Root X1)

**Tanggal**: 7 November 2026  
**Tujuan**: Menambahkan CA resmi ISRG Root X1 ke HTTP Client Flutter untuk mengatasi `HandshakeException: CERTIFICATE_VERIFY_FAILED: unable to get local issuer certificate` pada Android 7.0 tanpa mengabaikan validasi TLS.

Direktori Backup Fisik:
`C:\Users\PPLG\.gemini\antigravity\brain\ad4f1028-05be-433f-9c28-ee55610e9d07\backup_tls_android7\`

Struktur Folder Backup yang Dipertahankan:
```
backup_tls_android7/
├── pubspec.yaml
└── lib/
    ├── main.dart
    └── core/
        └── network/
            └── api_client.dart
```

### File yang Diubah:
1. `assets/certificates/isrgrootx1.pem` (FILE BARU)
   - Sertifikat root resmi Let's Encrypt ISRG Root X1.
   - SHA-256 Fingerprint terverifikasi: `96:BC:EC:06:26:49:76:F3:74:60:77:9A:CF:28:C5:A7:CF:E8:A3:C0:AA:E1:1A:8F:FC:EE:05:C0:BD:DF:08:C6`.
2. `pubspec.yaml`
   - Mendaftarkan `- assets/certificates/`.
3. `lib/core/network/api_client.dart`
   - Menambahkan factory `ApiClient.create()` yang menginisialisasi `SecurityContext(withTrustedRoots: true)` dan menyematkan `setTrustedCertificatesBytes(certBytes)`.
   - Menggunakan `IOClient` dari package `http` yang melayani semua method HTTP (GET, POST, PATCH, DELETE, dan multipart upload).
4. `lib/main.dart`
   - Mengubah `void main()` menjadi asynchronous `void main() async`.
   - Menginisialisasi `final apiClient = await ApiClient.create();`.

### Langkah Pemulihan (Non-Git):
Jika ingin mengembalikan konfigurasi ke versi sebelum fix TLS:
```powershell
Copy-Item "C:\Users\PPLG\.gemini\antigravity\brain\ad4f1028-05be-433f-9c28-ee55610e9d07\backup_tls_android7\pubspec.yaml" "C:\Project\Plasvora_app\pubspec.yaml" -Force
Copy-Item "C:\Users\PPLG\.gemini\antigravity\brain\ad4f1028-05be-433f-9c28-ee55610e9d07\backup_tls_android7\lib\main.dart" "C:\Project\Plasvora_app\lib\main.dart" -Force
Copy-Item "C:\Users\PPLG\.gemini\antigravity\brain\ad4f1028-05be-433f-9c28-ee55610e9d07\backup_tls_android7\lib\core\network\api_client.dart" "C:\Project\Plasvora_app\lib\core\network\api_client.dart" -Force
Remove-Item "C:\Project\Plasvora_app\assets\certificates\isrgrootx1.pem" -Force
```

---

## 5. Backup Final Review — Penghapusan Silent Fallback & Pemurnian ByteData Buffer

**Tanggal**: 7 November 2026  
**Tujuan**: Menghilangkan silent fallback `catch (_) { effectiveClient = http.Client(); }` agar kegagalan inisialisasi TLS tidak disembunyikan secara diam-diam, serta memastikan parsing `ByteData` menggunakan `offsetInBytes` dan `lengthInBytes` yang presisi.

Direktori Backup Fisik:
`C:\Users\PPLG\.gemini\antigravity\brain\ad4f1028-05be-433f-9c28-ee55610e9d07\backup_tls_final_review\`

Struktur Folder Backup:
```
backup_tls_final_review/
└── lib/
    └── core/
        └── network/
            └── api_client.dart
```

### File yang Diperbarui:
`lib/core/network/api_client.dart`
- Pemrosesan `ByteData` disempurnakan:
  `certByteData.buffer.asUint8List(certByteData.offsetInBytes, certByteData.lengthInBytes)`
- Validasi data byte: pengecekan `certBytes.isEmpty`.
- Penghapusan silent fallback: jika rootBundle atau SecurityContext gagal, exception dilempar secara eksplisit (`throw StateError(...)`), bukan jatuh kembali ke `http.Client()` biasa yang tidak memiliki ISRG Root X1.
- Seluruh method GET, POST, PATCH, DELETE, dan Multipart tetap menggunakan satu instance `_client` yang sama.

---

## 6. Backup Perbaikan Form Penawaran Material Marketplace (BUG-03, BUG-09, BUG-10)

**Tanggal**: 8 November 2026  
**Tujuan**: Mengganti modal form mock data dengan form nyata ber-controller dan validasi penuh, menghubungkan submit ke `MarketplaceViewModel.createListing()`, memetakan kategori `Lainnya` ke `OTHER`, dan memetakan kondisi `light` ke `slightly_dirty`.

Direktori Backup Fisik:
`C:\Users\PPLG\.gemini\antigravity\brain\ad4f1028-05be-433f-9c28-ee55610e9d07\backup_marketplace_form\`

Struktur Folder Backup:
```
backup_marketplace_form/
└── lib/
    ├── viewmodels/
    │   └── marketplace_viewmodel.dart
    └── views/
        └── marketplace/
            └── marketplace_screen.dart
```

### File yang Di-backup Sebelum Diubah:
1. `lib/viewmodels/marketplace_viewmodel.dart`
   - Salinan asli sebelum penambahan normalisasi enum di `createListing` dan query filter `loadListings`.
2. `lib/views/marketplace/marketplace_screen.dart`
   - Salinan asli sebelum penggantian modal form mock `const TextField` menjadi form interaktif berbasis lifecycle widget.

### Langkah Pemulihan (Non-Git):
```powershell
Copy-Item "C:\Users\PPLG\.gemini\antigravity\brain\ad4f1028-05be-433f-9c28-ee55610e9d07\backup_marketplace_form\lib\viewmodels\marketplace_viewmodel.dart" "C:\Project\Plasvora_app\lib\viewmodels\marketplace_viewmodel.dart" -Force
Copy-Item "C:\Users\PPLG\.gemini\antigravity\brain\ad4f1028-05be-433f-9c28-ee55610e9d07\backup_marketplace_form\lib\views\marketplace\marketplace_screen.dart" "C:\Project\Plasvora_app\lib\views\marketplace\marketplace_screen.dart" -Force
```

---

## 7. Backup Fix Impact Summary Beranda (BUG-05) & Perbaikan UI Banner Hutan

**Tanggal**: 8 November 2026  
**Tujuan**: Menghubungkan metrik dampak lingkungan Beranda ke endpoint `GET /api/impact-summary`, menghapus angka palsu fallback (18.4, 12.0, 9.5), dan memperbaiki alignment gambar hutan banner agar menempel rapi tanpa celah kosong di atas.

Direktori Backup Fisik:
`C:\Users\PPLG\.gemini\antigravity\brain\ad4f1028-05be-433f-9c28-ee55610e9d07\backup_home_impact_banner\`

Struktur Folder Backup:
```
backup_home_impact_banner/
└── lib/
    ├── models/
    │   └── impact_summary.dart
    ├── repositories/
    │   └── material_repository.dart
    ├── viewmodels/
    │   └── home_viewmodel.dart
    └── views/
        └── home/
            └── home_screen.dart
```

### File yang Di-backup Sebelum Diubah:
1. `lib/models/impact_summary.dart`
2. `lib/repositories/material_repository.dart`
3. `lib/viewmodels/home_viewmodel.dart`
4. `lib/views/home/home_screen.dart`

### Langkah Pemulihan (Non-Git):
```powershell
Copy-Item "C:\Users\PPLG\.gemini\antigravity\brain\ad4f1028-05be-433f-9c28-ee55610e9d07\backup_home_impact_banner\lib\models\impact_summary.dart" "C:\Project\Plasvora_app\lib\models\impact_summary.dart" -Force
Copy-Item "C:\Users\PPLG\.gemini\antigravity\brain\ad4f1028-05be-433f-9c28-ee55610e9d07\backup_home_impact_banner\lib\repositories\material_repository.dart" "C:\Project\Plasvora_app\lib\repositories\material_repository.dart" -Force
Copy-Item "C:\Users\PPLG\.gemini\antigravity\brain\ad4f1028-05be-433f-9c28-ee55610e9d07\backup_home_impact_banner\lib\viewmodels\home_viewmodel.dart" "C:\Project\Plasvora_app\lib\viewmodels\home_viewmodel.dart" -Force
Copy-Item "C:\Users\PPLG\.gemini\antigravity\brain\ad4f1028-05be-433f-9c28-ee55610e9d07\backup_home_impact_banner\lib\views\home\home_screen.dart" "C:\Project\Plasvora_app\lib\views\home\home_screen.dart" -Force
```

---

## 8. Backup Perbaikan 3 Flutter Deprecation Notices (Marketplace Screen)

**Tanggal**: 8 November 2026  
**Tujuan**: Memperbaiki 3 deprecation warning dari `flutter analyze lib/` pada `lib/views/marketplace/marketplace_screen.dart`:
1. `DropdownButtonFormField.value` deprecated -> diganti `initialValue: selectedCategory`.
2. `DropdownButtonFormField.value` deprecated -> diganti `initialValue: selectedCondition`.
3. `Switch.activeColor` deprecated -> diganti `activeThumbColor: AppColors.primary`.

Direktori Backup Fisik:
`C:\Users\PPLG\.gemini\antigravity\brain\ad4f1028-05be-433f-9c28-ee55610e9d07\backup_marketplace_deprecations\`

Struktur Folder Backup:
```
backup_marketplace_deprecations/
└── lib/
    └── views/
        └── marketplace/
            └── marketplace_screen.dart
```

### File yang Di-backup Sebelum Diubah:
1. `lib/views/marketplace/marketplace_screen.dart`

### Langkah Pemulihan (Non-Git):
```powershell
Copy-Item "C:\Users\PPLG\.gemini\antigravity\brain\ad4f1028-05be-433f-9c28-ee55610e9d07\backup_marketplace_deprecations\lib\views\marketplace\marketplace_screen.dart" "C:\Project\Plasvora_app\lib\views\marketplace\marketplace_screen.dart" -Force
```

---

## 9. Backup Final Targeted Bug Fixes (BUG-04 Activity, BUG-11 Analysis Result, BUG-13 ApiClient)

**Tanggal**: 8 November 2026  
**Tujuan**:
1. BUG-04: Menghubungkan Jejak Aktivitas ke endpoint riil `GET /api/activities` (Sanctum auth, loading/empty/error state, model, repository, viewmodel).
2. BUG-11: Menghapus klaim palsu mitra & menghubungkan navigasi Marketplace, serta memperjelas status bahwa hasil analisis disimpan secara otomatis oleh backend tanpa membuat request ganda.
3. BUG-13: Menangani exception jaringan (`SocketException`, `TimeoutException`, `http.ClientException`) secara seragam pada `get()`, `post()`, `patch()`, `delete()` di `ApiClient`.

Direktori Backup Fisik:
`C:\Users\PPLG\.gemini\antigravity\brain\ad4f1028-05be-433f-9c28-ee55610e9d07\backup_final_bugfixes\`

Struktur Folder Backup:
```
backup_final_bugfixes/
└── lib/
    ├── main.dart
    ├── core/
    │   └── network/
    │       └── api_client.dart
    └── views/
        ├── activity/
        │   └── activity_screen.dart
        ├── analysis/
        │   └── analysis_result_screen.dart
        └── main_navigation_screen.dart
```

### File Baru yang Dibuat:
- `lib/models/activity_item.dart`
- `lib/repositories/activity_repository.dart`
- `lib/viewmodels/activity_viewmodel.dart`

### File yang Di-backup Sebelum Diubah:
1. `lib/views/activity/activity_screen.dart`
2. `lib/views/analysis/analysis_result_screen.dart`
3. `lib/core/network/api_client.dart`
4. `lib/views/main_navigation_screen.dart`
5. `lib/main.dart`

### Langkah Pemulihan (Non-Git):
```powershell
Copy-Item "C:\Users\PPLG\.gemini\antigravity\brain\ad4f1028-05be-433f-9c28-ee55610e9d07\backup_final_bugfixes\lib\main.dart" "C:\Project\Plasvora_app\lib\main.dart" -Force
Copy-Item "C:\Users\PPLG\.gemini\antigravity\brain\ad4f1028-05be-433f-9c28-ee55610e9d07\backup_final_bugfixes\lib\views\main_navigation_screen.dart" "C:\Project\Plasvora_app\lib\views\main_navigation_screen.dart" -Force
Copy-Item "C:\Users\PPLG\.gemini\antigravity\brain\ad4f1028-05be-433f-9c28-ee55610e9d07\backup_final_bugfixes\lib\views\activity\activity_screen.dart" "C:\Project\Plasvora_app\lib\views\activity\activity_screen.dart" -Force
Copy-Item "C:\Users\PPLG\.gemini\antigravity\brain\ad4f1028-05be-433f-9c28-ee55610e9d07\backup_final_bugfixes\lib\views\analysis\analysis_result_screen.dart" "C:\Project\Plasvora_app\lib\views\analysis\analysis_result_screen.dart" -Force
Copy-Item "C:\Users\PPLG\.gemini\antigravity\brain\ad4f1028-05be-433f-9c28-ee55610e9d07\backup_final_bugfixes\lib\core\network\api_client.dart" "C:\Project\Plasvora_app\lib\core\network\api_client.dart" -Force
```

---

## 10. Backup Perbaikan 2 Analyzer Issues (Activity Screen)

**Tanggal**: 8 November 2026  
**Tujuan**:
1. Menghapus unused import `../../models/activity_item.dart` pada `lib/views/activity/activity_screen.dart`.
2. Memperbaiki lint `unnecessary_underscores` pada parameter callback `separatorBuilder` di baris 215.

Direktori Backup Fisik:
`C:\Users\PPLG\.gemini\antigravity\brain\ad4f1028-05be-433f-9c28-ee55610e9d07\backup_activity_analyzer_fix\`

Struktur Folder Backup:
```
backup_activity_analyzer_fix/
└── lib/
    └── views/
        └── activity/
            └── activity_screen.dart
```

### File yang Di-backup Sebelum Diubah:
1. `lib/views/activity/activity_screen.dart`

### Langkah Pemulihan (Non-Git):
```powershell
Copy-Item "C:\Users\PPLG\.gemini\antigravity\brain\ad4f1028-05be-433f-9c28-ee55610e9d07\backup_activity_analyzer_fix\lib\views\activity\activity_screen.dart" "C:\Project\Plasvora_app\lib\views\activity\activity_screen.dart" -Force
```

---

## 11. Backup Backend Rate Limiting Fix (SEC-001 & SEC-007)

**Tanggal**: 13 November 2026  
**Tujuan**:
1. SEC-001: Menerapkan rate limiting pada login (5 req/menit per email+IP hash, 60 req/menit per IP) dan registrasi (3 req/menit per IP, 20 req/jam per IP).
2. SEC-007: Menerapkan rate limiting pada analisis plastik (3 req/menit per user Sanctum, 20 req/hari per user Sanctum).
3. Penyiapan unit/feature tests untuk skenario rate limiting tanpa menjalankannya.

Direktori Backup Fisik:
`C:\Users\PPLG\.gemini\antigravity\brain\ad4f1028-05be-433f-9c28-ee55610e9d07\backup_rate_limiting\`

Struktur Folder Backup:
```
backup_rate_limiting/
├── app/
│   └── Providers/
│       └── AppServiceProvider.php
├── routes/
│   └── api.php
└── tests/
    └── Feature/
        ├── AuthTest.php
        └── ActivityAndAnalysisTest.php
```

### File yang Di-backup Sebelum Diubah:
1. `app/Providers/AppServiceProvider.php` (`C:\xampp\htdocs\backend_plasvora\app\Providers\AppServiceProvider.php`)
2. `routes/api.php` (`C:\xampp\htdocs\backend_plasvora\routes\api.php`)
3. `tests/Feature/AuthTest.php` (`C:\xampp\htdocs\backend_plasvora\tests\Feature\AuthTest.php`)
4. `tests/Feature/ActivityAndAnalysisTest.php` (`C:\xampp\htdocs\backend_plasvora\tests\Feature\ActivityAndAnalysisTest.php`)

### Langkah Pemulihan (Non-Git):
```powershell
Copy-Item "C:\Users\PPLG\.gemini\antigravity\brain\ad4f1028-05be-433f-9c28-ee55610e9d07\backup_rate_limiting\app\Providers\AppServiceProvider.php" "C:\xampp\htdocs\backend_plasvora\app\Providers\AppServiceProvider.php" -Force
Copy-Item "C:\Users\PPLG\.gemini\antigravity\brain\ad4f1028-05be-433f-9c28-ee55610e9d07\backup_rate_limiting\routes\api.php" "C:\xampp\htdocs\backend_plasvora\routes\api.php" -Force
Copy-Item "C:\Users\PPLG\.gemini\antigravity\brain\ad4f1028-05be-433f-9c28-ee55610e9d07\backup_rate_limiting\tests\Feature\AuthTest.php" "C:\xampp\htdocs\backend_plasvora\tests\Feature\AuthTest.php" -Force
Copy-Item "C:\Users\PPLG\.gemini\antigravity\brain\ad4f1028-05be-433f-9c28-ee55610e9d07\backup_rate_limiting\tests\Feature\ActivityAndAnalysisTest.php" "C:\xampp\htdocs\backend_plasvora\tests\Feature\ActivityAndAnalysisTest.php" -Force
```

---

## 12. Backup Penambahan Test Coverage Rate Limiting (SEC-001 & SEC-007)

**Tanggal**: 13 November 2026  
**Tujuan**:
1. Menambahkan pengujian rate limiting login 60 permintaan/menit per IP.
2. Menambahkan pengujian rate limiting registrasi 20 permintaan/jam per IP.
3. Menambahkan pengujian rate limiting analisis 20 permintaan/hari per user.
4. Menambahkan pengujian verifikasi permintaan analisis yang dibatasi (throttled) tidak memanggil layanan Gemini API dan tidak menyimpan gambar ke disk.

Direktori Backup Fisik:
`C:\Users\PPLG\.gemini\antigravity\brain\ad4f1028-05be-433f-9c28-ee55610e9d07\backup_rate_limiting_tests\`

Struktur Folder Backup:
```
backup_rate_limiting_tests/
└── tests/
    └── Feature/
        ├── AuthTest.php
        ├── ActivityAndAnalysisTest.php
        └── GeminiVisionAnalysisTest.php
```

### File yang Di-backup Sebelum Diubah:
1. `tests/Feature/AuthTest.php` (`C:\xampp\htdocs\backend_plasvora\tests\Feature\AuthTest.php`)
2. `tests/Feature/ActivityAndAnalysisTest.php` (`C:\xampp\htdocs\backend_plasvora\tests\Feature\ActivityAndAnalysisTest.php`)
3. `tests/Feature/GeminiVisionAnalysisTest.php` (`C:\xampp\htdocs\backend_plasvora\tests\Feature\GeminiVisionAnalysisTest.php`)

### Langkah Pemulihan (Non-Git):
```powershell
Copy-Item "C:\Users\PPLG\.gemini\antigravity\brain\ad4f1028-05be-433f-9c28-ee55610e9d07\backup_rate_limiting_tests\tests\Feature\AuthTest.php" "C:\xampp\htdocs\backend_plasvora\tests\Feature\AuthTest.php" -Force
Copy-Item "C:\Users\PPLG\.gemini\antigravity\brain\ad4f1028-05be-433f-9c28-ee55610e9d07\backup_rate_limiting_tests\tests\Feature\ActivityAndAnalysisTest.php" "C:\xampp\htdocs\backend_plasvora\tests\Feature\ActivityAndAnalysisTest.php" -Force
Copy-Item "C:\Users\PPLG\.gemini\antigravity\brain\ad4f1028-05be-433f-9c28-ee55610e9d07\backup_rate_limiting_tests\tests\Feature\GeminiVisionAnalysisTest.php" "C:\xampp\htdocs\backend_plasvora\tests\Feature\GeminiVisionAnalysisTest.php" -Force
```

---

## 13. Backup Perbaikan Kerentanan SEC-003: Race Condition Serah Terima

**Tanggal**: 13 November 2026, 21:09 WIB  
**Tujuan**:
1. Mengamankan alur perubahan status serah terima (`PATCH /api/handover-requests/{id}/status`) dari race condition / concurrency issue saat persetujuan (approval) permintaan serah terima material.
2. Membungkus seluruh proses perubahan status dan validasi state machine dalam `DB::transaction()` dengan row-level locking (`lockForUpdate()`) berurutan: `HandoverRequest` lalu `MaterialListing`.
3. Memastikan ketersediaan material dicek ulang di dalam transaksi sehingga material yang sama tidak dapat disetujui lebih dari satu kali (`409 Conflict` jika material sudah bukan `available`).
4. Menambahkan test cases komprehensif pada `HandoverRequestTest.php`.

Direktori Backup Fisik:
`C:\Users\PPLG\.gemini\antigravity\brain\ad4f1028-05be-433f-9c28-ee55610e9d07\backup_sec003\`

Struktur Folder Backup:
```
backup_sec003/
├── app/
│   └── Http/
│       └── Controllers/
│           └── Api/
│               └── HandoverRequestController.php
└── tests/
    └── Feature/
        └── HandoverRequestTest.php
```

### File yang Di-backup Sebelum Diubah:
1. `app/Http/Controllers/Api/HandoverRequestController.php` (`C:\xampp\htdocs\backend_plasvora\app\Http\Controllers\Api\HandoverRequestController.php`)
2. `tests/Feature/HandoverRequestTest.php` (`C:\xampp\htdocs\backend_plasvora\tests\Feature\HandoverRequestTest.php`)

### Langkah Pemulihan (Non-Git):
```powershell
Copy-Item "C:\Users\PPLG\.gemini\antigravity\brain\ad4f1028-05be-433f-9c28-ee55610e9d07\backup_sec003\app\Http\Controllers\Api\HandoverRequestController.php" "C:\xampp\htdocs\backend_plasvora\app\Http\Controllers\Api\HandoverRequestController.php" -Force
Copy-Item "C:\Users\PPLG\.gemini\antigravity\brain\ad4f1028-05be-433f-9c28-ee55610e9d07\backup_sec003\tests\Feature\HandoverRequestTest.php" "C:\xampp\htdocs\backend_plasvora\tests\Feature\HandoverRequestTest.php" -Force
```

---

## 14. Backup Pematangan Fitur Marketplace (Integrasi Backend & Filter Nyata)

**Tanggal**: 14 November 2026  
**Tujuan**:
1. Menghubungkan seluruh interaksi pengguna pada Marketplace secara nyata ke backend API (`GET /api/materials` & `GET /api/materials/{id}`).
2. Menghapus filter semu / SnackBar tiruan dan menggantikannya dengan query backend aktual (kategori, kondisi, rentang berat, lokasi, pencarian teks dengan debounce).
3. Memperbaiki model `MaterialListing` agar mendukung `ownerName` dari respons backend dan tidak menampilkan jarak fiktif jika tidak disediakan backend.
4. Menambahkan navigasi dan halaman detail material (`MaterialDetailScreen`) yang mengambil data aktual via `GET /api/materials/{id}`.
5. Memastikan modal filter lanjutan (Advanced Filter Modal) bekerja nyata untuk tombol Terapkan Filter dan Reset.

Direktori Backup Fisik:
`C:\Users\PPLG\.gemini\antigravity\brain\ad4f1028-05be-433f-9c28-ee55610e9d07\backup_marketplace_maturing\`

Struktur Folder Backup:
```
backup_marketplace_maturing/
└── lib/
    ├── models/
    │   └── material_listing.dart
    ├── repositories/
    │   └── material_repository.dart
    ├── viewmodels/
    │   └── marketplace_viewmodel.dart
    └── views/
        └── marketplace/
            └── marketplace_screen.dart
```

### File yang Di-backup Sebelum Diubah:
1. `lib/models/material_listing.dart`
2. `lib/repositories/material_repository.dart`
3. `lib/viewmodels/marketplace_viewmodel.dart`
4. `lib/views/marketplace/marketplace_screen.dart`

### Langkah Pemulihan (Non-Git):
```powershell
Copy-Item "C:\Users\PPLG\.gemini\antigravity\brain\ad4f1028-05be-433f-9c28-ee55610e9d07\backup_marketplace_maturing\lib\models\material_listing.dart" "C:\Project\Plasvora_app\lib\models\material_listing.dart" -Force
Copy-Item "C:\Users\PPLG\.gemini\antigravity\brain\ad4f1028-05be-433f-9c28-ee55610e9d07\backup_marketplace_maturing\lib\repositories\material_repository.dart" "C:\Project\Plasvora_app\lib\repositories\material_repository.dart" -Force
Copy-Item "C:\Users\PPLG\.gemini\antigravity\brain\ad4f1028-05be-433f-9c28-ee55610e9d07\backup_marketplace_maturing\lib\viewmodels\marketplace_viewmodel.dart" "C:\Project\Plasvora_app\lib\viewmodels\marketplace_viewmodel.dart" -Force
Copy-Item "C:\Users\PPLG\.gemini\antigravity\brain\ad4f1028-05be-433f-9c28-ee55610e9d07\backup_marketplace_maturing\lib\views\marketplace\marketplace_screen.dart" "C:\Project\Plasvora_app\lib\views\marketplace\marketplace_screen.dart" -Force
```

---

## 15. Backup Pematangan Smart Matching & Material Request

**Tanggal**: 14 November 2026  
**Tujuan**:
1. Menghubungkan fitur Material Request (Kebutuhan Material) dan Smart Matching (pencocokan berbasis aturan) dengan backend API Plasvora.
2. Mengintegrasikan CRUD Material Request (`GET /api/material-requests`, `POST /api/material-requests`, `GET /api/material-requests/{id}`, `PATCH /api/material-requests/{id}`, `DELETE /api/material-requests/{id}`).
3. Menghubungkan algoritma Smart Matching backend (`GET /api/material-requests/{id}/matches` dan `GET /api/materials/{id}/matches`) ke tampilan frontend dengan skor transparan berbasis aturan.
4. Menambahkan navigasi terpadu antara Marketplace, Material Request, Smart Matching, Material Detail, dan hasil Analisis Plastik.

Direktori Backup Fisik:
`C:\Users\PPLG\.gemini\antigravity\brain\ad4f1028-05be-433f-9c28-ee55610e9d07\backup_smart_matching_and_material_request\`

Struktur Folder Backup:
```
backup_smart_matching_and_material_request/
└── lib/
    ├── main.dart
    ├── models/
    │   └── material_request_item.dart
    ├── repositories/
    │   └── transaction_repository.dart
    └── views/
        ├── analysis/
        │   └── analysis_result_screen.dart
        └── marketplace/
            ├── marketplace_screen.dart
            └── material_detail_screen.dart
```

### File yang Di-backup Sebelum Diubah:
1. `lib/models/material_request_item.dart`
2. `lib/repositories/transaction_repository.dart`
3. `lib/main.dart`
4. `lib/views/marketplace/marketplace_screen.dart`
5. `lib/views/marketplace/material_detail_screen.dart`
6. `lib/views/analysis/analysis_result_screen.dart`

### Langkah Pemulihan (Non-Git):
```powershell
Copy-Item "C:\Users\PPLG\.gemini\antigravity\brain\ad4f1028-05be-433f-9c28-ee55610e9d07\backup_smart_matching_and_material_request\lib\models\material_request_item.dart" "C:\Project\Plasvora_app\lib\models\material_request_item.dart" -Force
Copy-Item "C:\Users\PPLG\.gemini\antigravity\brain\ad4f1028-05be-433f-9c28-ee55610e9d07\backup_smart_matching_and_material_request\lib\repositories\transaction_repository.dart" "C:\Project\Plasvora_app\lib\repositories\transaction_repository.dart" -Force
Copy-Item "C:\Users\PPLG\.gemini\antigravity\brain\ad4f1028-05be-433f-9c28-ee55610e9d07\backup_smart_matching_and_material_request\lib\main.dart" "C:\Project\Plasvora_app\lib\main.dart" -Force
Copy-Item "C:\Users\PPLG\.gemini\antigravity\brain\ad4f1028-05be-433f-9c28-ee55610e9d07\backup_smart_matching_and_material_request\lib\views\marketplace\marketplace_screen.dart" "C:\Project\Plasvora_app\lib\views\marketplace\marketplace_screen.dart" -Force
Copy-Item "C:\Users\PPLG\.gemini\antigravity\brain\ad4f1028-05be-433f-9c28-ee55610e9d07\backup_smart_matching_and_material_request\lib\views\marketplace\material_detail_screen.dart" "C:\Project\Plasvora_app\lib\views\marketplace\material_detail_screen.dart" -Force
Copy-Item "C:\Users\PPLG\.gemini\antigravity\brain\ad4f1028-05be-433f-9c28-ee55610e9d07\backup_smart_matching_and_material_request\lib\views\analysis\analysis_result_screen.dart" "C:\Project\Plasvora_app\lib\views\analysis\analysis_result_screen.dart" -Force
```

---

## 16. Backup Perbaikan Error & Warning Flutter (Smart Matching & Analysis Navigation)

**Tanggal**: 14 November 2026  
**Tujuan**:
1. Memperbaiki error parameter `ownerId` pada constructor `HandoverItem` di `MockTransactionRepository`.
2. Memperbaiki undefined getter `polymerType` menjadi `polymerCategory` pada `PlasticAnalysisResult` di `AnalysisResultScreen`.
3. Menghapus unused import `material_listing.dart` pada `MatchingResultsScreen`.
4. Mengganti parameter deprecated `value` menjadi `initialValue` pada `DropdownButtonFormField` di `CreateMaterialRequestScreen`.

Direktori Backup Fisik:
`C:\Users\PPLG\.gemini\antigravity\brain\ad4f1028-05be-433f-9c28-ee55610e9d07\backup_flutter_fixes\`

Struktur Folder Backup:
```
backup_flutter_fixes/
└── lib/
    ├── repositories/
    │   └── transaction_repository.dart
    └── views/
        ├── analysis/
        │   └── analysis_result_screen.dart
        ├── matching/
        │   └── matching_results_screen.dart
        └── material_request/
            └── create_material_request_screen.dart
```

### File yang Di-backup Sebelum Diubah:
1. `lib/repositories/transaction_repository.dart`
2. `lib/views/analysis/analysis_result_screen.dart`
3. `lib/views/matching/matching_results_screen.dart`
4. `lib/views/material_request/create_material_request_screen.dart`

### Langkah Pemulihan (Non-Git):
```powershell
Copy-Item "C:\Users\PPLG\.gemini\antigravity\brain\ad4f1028-05be-433f-9c28-ee55610e9d07\backup_flutter_fixes\lib\repositories\transaction_repository.dart" "C:\Project\Plasvora_app\lib\repositories\transaction_repository.dart" -Force
Copy-Item "C:\Users\PPLG\.gemini\antigravity\brain\ad4f1028-05be-433f-9c28-ee55610e9d07\backup_flutter_fixes\lib\views\analysis\analysis_result_screen.dart" "C:\Project\Plasvora_app\lib\views\analysis\analysis_result_screen.dart" -Force
Copy-Item "C:\Users\PPLG\.gemini\antigravity\brain\ad4f1028-05be-433f-9c28-ee55610e9d07\backup_flutter_fixes\lib\views\matching\matching_results_screen.dart" "C:\Project\Plasvora_app\lib\views\matching\matching_results_screen.dart" -Force
Copy-Item "C:\Users\PPLG\.gemini\antigravity\brain\ad4f1028-05be-433f-9c28-ee55610e9d07\backup_flutter_fixes\lib\views\material_request\create_material_request_screen.dart" "C:\Project\Plasvora_app\lib\views\material_request\create_material_request_screen.dart" -Force
```

---

## 17. Backup Perbaikan Penanganan Error ApiException (Status: null Elimination)

**Tanggal**: 14 November 2026  
**Tujuan**:
1. Memperbaiki method `toString()` pada `ApiException` di `lib/core/network/api_client.dart` agar suffix `(Status: $statusCode)` hanya disertakan saat `statusCode` benar-benar ada (tidak bernilai null).
2. Memperbaiki penanganan error pada `MaterialRequestViewModel` di `lib/viewmodels/material_request_viewmodel.dart` agar mempertahankan pesan error asli tanpa suffix palsu `(Status: null)`.

Direktori Backup Fisik:
`C:\Users\PPLG\.gemini\antigravity\brain\ad4f1028-05be-433f-9c28-ee55610e9d07\backup_api_exception_status_null\`

Struktur Folder Backup:
```
backup_api_exception_status_null/
└── lib/
    ├── core/
    │   └── network/
    │       └── api_client.dart
    └── viewmodels/
        └── material_request_viewmodel.dart
```

### File yang Di-backup Sebelum Diubah:
1. `lib/core/network/api_client.dart`
2. `lib/viewmodels/material_request_viewmodel.dart`

### Langkah Pemulihan (Non-Git):
```powershell
Copy-Item "C:\Users\PPLG\.gemini\antigravity\brain\ad4f1028-05be-433f-9c28-ee55610e9d07\backup_api_exception_status_null\lib\core\network\api_client.dart" "C:\Project\Plasvora_app\lib\core\network\api_client.dart" -Force
Copy-Item "C:\Users\PPLG\.gemini\antigravity\brain\ad4f1028-05be-433f-9c28-ee55610e9d07\backup_api_exception_status_null\lib\viewmodels\material_request_viewmodel.dart" "C:\Project\Plasvora_app\lib\viewmodels\material_request_viewmodel.dart" -Force
```








## 18. Backup Integrasi Hasil Analisis, Marketplace, dan Riwayat Aktivitas

**Tanggal**: 14 November 2026  
**Tujuan**:
1. Mengintegrasikan hasil analisis plastik dengan form pembuatan penawaran material Marketplace ("Jual Material Ini") secara pre-filled tanpa memasukkan data fiktif untuk berat/lokasi.
2. Mengintegrasikan riwayat analisis plastik ke halaman Aktivitas (tab filter jejak & riwayat analisis, kartu riwayat dengan thumbnail foto, polimer, tanggal, dan navigasi ke detail hasil analisis).
3. Mendukung pembukaan kembali hasil analisis tersimpan tanpa request ulang ke AI Gemini serta tombol "Jual Material Ini" dari hasil analisis riwayat.

Direktori Backup Fisik:
`C:\Users\PPLG\.gemini\antigravity\brain\ad4f1028-05be-433f-9c28-ee55610e9d07\backup_analysis_marketplace_activity_fe\`

Struktur Folder Backup:
```
backup_analysis_marketplace_activity_fe/
└── lib/
    ├── core/
    │   └── network/
    │       └── api_config.dart
    ├── models/
    │   └── activity_item.dart
    ├── repositories/
    │   └── activity_repository.dart
    ├── viewmodels/
    │   └── activity_viewmodel.dart
    └── views/
        ├── main_navigation_screen.dart
        ├── activity/
        │   └── activity_screen.dart
        ├── analysis/
        │   ├── analysis_result_screen.dart
        │   └── analysis_screen.dart
        └── marketplace/
            └── marketplace_screen.dart
```

### File yang Di-backup Sebelum Diubah:
1. `lib/core/network/api_config.dart`
2. `lib/models/activity_item.dart`
3. `lib/repositories/activity_repository.dart`
4. `lib/viewmodels/activity_viewmodel.dart`
5. `lib/views/main_navigation_screen.dart`
6. `lib/views/activity/activity_screen.dart`
7. `lib/views/analysis/analysis_result_screen.dart`
8. `lib/views/analysis/analysis_screen.dart`
9. `lib/views/marketplace/marketplace_screen.dart`

### Langkah Pemulihan (Non-Git):
```powershell
Copy-Item "C:\Users\PPLG\.gemini\antigravity\brain\ad4f1028-05be-433f-9c28-ee55610e9d07\backup_analysis_marketplace_activity_fe\lib\core\network\api_config.dart" "C:\Project\Plasvora_app\lib\core\network\api_config.dart" -Force
Copy-Item "C:\Users\PPLG\.gemini\antigravity\brain\ad4f1028-05be-433f-9c28-ee55610e9d07\backup_analysis_marketplace_activity_fe\lib\models\activity_item.dart" "C:\Project\Plasvora_app\lib\models\activity_item.dart" -Force
Copy-Item "C:\Users\PPLG\.gemini\antigravity\brain\ad4f1028-05be-433f-9c28-ee55610e9d07\backup_analysis_marketplace_activity_fe\lib\repositories\activity_repository.dart" "C:\Project\Plasvora_app\lib\repositories\activity_repository.dart" -Force
Copy-Item "C:\Users\PPLG\.gemini\antigravity\brain\ad4f1028-05be-433f-9c28-ee55610e9d07\backup_analysis_marketplace_activity_fe\lib\viewmodels\activity_viewmodel.dart" "C:\Project\Plasvora_app\lib\viewmodels\activity_viewmodel.dart" -Force
Copy-Item "C:\Users\PPLG\.gemini\antigravity\brain\ad4f1028-05be-433f-9c28-ee55610e9d07\backup_analysis_marketplace_activity_fe\lib\views\main_navigation_screen.dart" "C:\Project\Plasvora_app\lib\views\main_navigation_screen.dart" -Force
Copy-Item "C:\Users\PPLG\.gemini\antigravity\brain\ad4f1028-05be-433f-9c28-ee55610e9d07\backup_analysis_marketplace_activity_fe\lib\views\activity\activity_screen.dart" "C:\Project\Plasvora_app\lib\views\activity\activity_screen.dart" -Force
Copy-Item "C:\Users\PPLG\.gemini\antigravity\brain\ad4f1028-05be-433f-9c28-ee55610e9d07\backup_analysis_marketplace_activity_fe\lib\views\analysis\analysis_result_screen.dart" "C:\Project\Plasvora_app\lib\views\analysis\analysis_result_screen.dart" -Force
Copy-Item "C:\Users\PPLG\.gemini\antigravity\brain\ad4f1028-05be-433f-9c28-ee55610e9d07\backup_analysis_marketplace_activity_fe\lib\views\analysis\analysis_screen.dart" "C:\Project\Plasvora_app\lib\views\analysis\analysis_screen.dart" -Force
Copy-Item "C:\Users\PPLG\.gemini\antigravity\brain\ad4f1028-05be-433f-9c28-ee55610e9d07\backup_analysis_marketplace_activity_fe\lib\views\marketplace\marketplace_screen.dart" "C:\Project\Plasvora_app\lib\views\marketplace\marketplace_screen.dart" -Force
```

## 19. Backup Perbaikan 7 Temuan Flutter Analyze (Info Unnecessary Underscores & Warning Unused Method)

**Tanggal**: 14 November 2026  
**Tujuan**:
1. Memperbaiki 6 temuan `info - Unnecessary use of multiple underscores` pada `lib/views/activity/activity_screen.dart` dan `lib/views/marketplace/create_material_listing_screen.dart` dengan menggunakan wildcard variable `_` tunggal yang konsisten dengan standar Dart modern (Dart 3.7+).
2. Memperbaiki 1 temuan `warning - The declaration '_showOfferMaterialBottomSheet' isn't referenced` pada `lib/views/marketplace/marketplace_screen.dart` dengan menghapus fungsi modal bottom sheet privat lama yang sudah sepenuhnya digantikan oleh halaman terdedikasi `CreateMaterialListingScreen`.

Direktori Backup Fisik:
`C:\Users\PPLG\.gemini\antigravity\brain\ad4f1028-05be-433f-9c28-ee55610e9d07\backup_flutter_analyze_7_fixes\`

Struktur Folder Backup:
```
backup_flutter_analyze_7_fixes/
└── lib/
    └── views/
        ├── activity/
        │   └── activity_screen.dart
        └── marketplace/
            ├── create_material_listing_screen.dart
            └── marketplace_screen.dart
```

### File yang Di-backup Sebelum Diubah:
1. `lib/views/activity/activity_screen.dart`
2. `lib/views/marketplace/create_material_listing_screen.dart`
3. `lib/views/marketplace/marketplace_screen.dart`

### Langkah Pemulihan (Non-Git):
```powershell
Copy-Item "C:\Users\PPLG\.gemini\antigravity\brain\ad4f1028-05be-433f-9c28-ee55610e9d07\backup_flutter_analyze_7_fixes\lib\views\activity\activity_screen.dart" "C:\Project\Plasvora_app\lib\views\activity\activity_screen.dart" -Force
Copy-Item "C:\Users\PPLG\.gemini\antigravity\brain\ad4f1028-05be-433f-9c28-ee55610e9d07\backup_flutter_analyze_7_fixes\lib\views\marketplace\create_material_listing_screen.dart" "C:\Project\Plasvora_app\lib\views\marketplace\create_material_listing_screen.dart" -Force
Copy-Item "C:\Users\PPLG\.gemini\antigravity\brain\ad4f1028-05be-433f-9c28-ee55610e9d07\backup_flutter_analyze_7_fixes\lib\views\marketplace\marketplace_screen.dart" "C:\Project\Plasvora_app\lib\views\marketplace\marketplace_screen.dart" -Force
```

## 20. Backup Penggantian Logo Asli Plasvora & Penyesuaian Sudut Melengkung Search Bar Marketplace

**Tanggal**: 14 November 2026  
**Tujuan**:
1. Mengganti asset logo placeholder lama (`BioLoop Technologies` pada `assets/images/logo.png`) dengan logo resmi asli Plasvora yang bersumber dari asset aplikasi (`assets/icon/Icon_app.png`), sehingga tampilan logo pada header aplikasi (`PlasvoraHeader`) dan halaman login (`LoginScreen`) menggunakan logo identitas asli Plasvora.
2. Memperbaiki search bar pada halaman Marketplace (`lib/views/marketplace/marketplace_screen.dart`) yang sebelumnya memiliki ujung siku-siku tajam agar menjadi melengkung halus seirama dengan tombol filter (`borderRadius: BorderRadius.circular(14)`) dengan `clipBehavior: Clip.antiAlias` dan `filled: false` tanpa membuatnya terlalu melengkung (tidak stadium pill 999).
3. Menyesuaikan tombol filter (tune icon) di samping search bar agar menggunakan radius seragam `BorderRadius.circular(14)`.

Direktori Backup Fisik:
`C:\Users\PPLG\.gemini\antigravity\brain\ad4f1028-05be-433f-9c28-ee55610e9d07\backup_logo_and_searchbar\`

Struktur Folder Backup:
```
backup_logo_and_searchbar/
├── assets/
│   └── images/
│       └── logo.png
└── lib/
    ├── core/
    │   └── widgets/
    │       └── plasvora_header.dart
    └── views/
        ├── auth/
        │   └── login_screen.dart
        └── marketplace/
            └── marketplace_screen.dart
```

### File yang Di-backup Sebelum Diubah:
1. `assets/images/logo.png`
2. `lib/core/widgets/plasvora_header.dart`
3. `lib/views/auth/login_screen.dart`
4. `lib/views/marketplace/marketplace_screen.dart`

### Langkah Pemulihan (Non-Git):
```powershell
Copy-Item "C:\Users\PPLG\.gemini\antigravity\brain\ad4f1028-05be-433f-9c28-ee55610e9d07\backup_logo_and_searchbar\assets\images\logo.png" "C:\Project\Plasvora_app\assets\images\logo.png" -Force
Copy-Item "C:\Users\PPLG\.gemini\antigravity\brain\ad4f1028-05be-433f-9c28-ee55610e9d07\backup_logo_and_searchbar\lib\core\widgets\plasvora_header.dart" "C:\Project\Plasvora_app\lib\core\widgets\plasvora_header.dart" -Force
Copy-Item "C:\Users\PPLG\.gemini\antigravity\brain\ad4f1028-05be-433f-9c28-ee55610e9d07\backup_logo_and_searchbar\lib\views\auth\login_screen.dart" "C:\Project\Plasvora_app\lib\views\auth\login_screen.dart" -Force
Copy-Item "C:\Users\PPLG\.gemini\antigravity\brain\ad4f1028-05be-433f-9c28-ee55610e9d07\backup_logo_and_searchbar\lib\views\marketplace\marketplace_screen.dart" "C:\Project\Plasvora_app\lib\views\marketplace\marketplace_screen.dart" -Force
```

## 21. Backup Koreksi dan Penyesuaian UI (Posisi Logo AppBar Kiri Atas, BoxFit Login, & BorderRadius Search Bar)

**Tanggal**: 14 November 2026  
**Tujuan**:
1. Mengonfirmasi dan memastikan posisi logo asli Plasvora berada secara absolut di **kiri atas** (leading area) AppBar horizontal berdampingan dengan teks "PLASVORA", dengan rasio aspek asli `BoxFit.contain` dan ukuran 32x32, serta mempertahankan elemen aksi notifikasi dan profil di sisi kanan.
2. Memperbaiki tampilan logo pada halaman Login (`LoginScreen`) dengan menggunakan `BoxFit.contain` sesuai spesifikasi desain resmi.
3. Memastikan dekorasi search bar Marketplace (`MarketplaceScreen`) konsisten menggunakan `BorderRadius.circular(14)` pada container, normal border, enabled border, dan focused border (`OutlineInputBorder`), seirama dengan tombol filter di sampingnya (radius 14), tanpa sudut siku maupun radius kapsul/pill ekstrem.

Direktori Backup Fisik:
`C:\Users\PPLG\.gemini\antigravity\brain\ad4f1028-05be-433f-9c28-ee55610e9d07\backup_ui_corrections_appbar_searchbar\`

Struktur Folder Backup:
```
backup_ui_corrections_appbar_searchbar/
└── lib/
    ├── core/
    │   └── widgets/
    │       └── plasvora_header.dart
    └── views/
        ├── auth/
        │   └── login_screen.dart
        └── marketplace/
            └── marketplace_screen.dart
```

### File yang Di-backup Sebelum Diubah:
1. `lib/core/widgets/plasvora_header.dart`
2. `lib/views/auth/login_screen.dart`
3. `lib/views/marketplace/marketplace_screen.dart`

### Langkah Pemulihan (Non-Git):
```powershell
Copy-Item "C:\Users\PPLG\.gemini\antigravity\brain\ad4f1028-05be-433f-9c28-ee55610e9d07\backup_ui_corrections_appbar_searchbar\lib\core\widgets\plasvora_header.dart" "C:\Project\Plasvora_app\lib\core\widgets\plasvora_header.dart" -Force
Copy-Item "C:\Users\PPLG\.gemini\antigravity\brain\ad4f1028-05be-433f-9c28-ee55610e9d07\backup_ui_corrections_appbar_searchbar\lib\views\auth\login_screen.dart" "C:\Project\Plasvora_app\lib\views\auth\login_screen.dart" -Force
Copy-Item "C:\Users\PPLG\.gemini\antigravity\brain\ad4f1028-05be-433f-9c28-ee55610e9d07\backup_ui_corrections_appbar_searchbar\lib\views\marketplace\marketplace_screen.dart" "C:\Project\Plasvora_app\lib\views\marketplace\marketplace_screen.dart" -Force
```


---

## 22. Backup Persistensi Login / Pemulihan Sesi (Persistent Login & Session Restoration)

**Tanggal**: 14 November 2026  
**Tujuan**:
1. Mengatasi masalah di mana setiap kali aplikasi ditutup sepenuhnya lalu dibuka kembali, sesi login hilang dan pengguna selalu diminta login ulang ke `LoginScreen`.
2. Mengganti implementasi penyimpanan token berbasis memori murni (`InMemoryAuthTokenStorage`) dengan penyimpanan persisten (`PersistentAuthTokenStorage`) yang menyimpan Sanctum Bearer Token ke media penyimpanan internal aplikasi secara aman dan terisolasi sandbox.
3. Memperbaiki logika `ApiAuthRepository.getCurrentUser()` agar HANYA menghapus token dan memutus sesi ketika server backend secara eksplisit merespons status HTTP 401 Unauthorized atau 403 Forbidden. Pada kondisi gangguan jaringan, timeout, atau HTTP 500, token lokal TETAP DIPERTAHANKAN.
4. Menambahkan state `connectionError` pada `AuthViewModel` beserta aksi `retryCheckAuthSession()` dan tampilan layar pemulihan koneksi ramah pengguna di `main.dart`, sehingga kegagalan jaringan sementara tidak menghapus akun dan pengguna dapat mencoba menghubungkan kembali sesi loginnya.

Direktori Backup Fisik:
`C:\Users\PPLG\.gemini\antigravity\brain\ad4f1028-05be-433f-9c28-ee55610e9d07\backup_persistent_login\`

Struktur Folder Backup:
```
backup_persistent_login/
├── pubspec.yaml
└── lib/
    ├── main.dart
    ├── core/
    │   └── network/
    │       └── api_client.dart
    ├── repositories/
    │   └── auth_repository.dart
    └── viewmodels/
        └── auth_viewmodel.dart
```

### File yang Di-backup Sebelum Diubah:
1. `pubspec.yaml`
2. `lib/core/network/api_client.dart`
3. `lib/repositories/auth_repository.dart`
4. `lib/viewmodels/auth_viewmodel.dart`
5. `lib/main.dart`

### Langkah Pemulihan (Non-Git):
```powershell
Copy-Item "C:\Users\PPLG\.gemini\antigravity\brain\ad4f1028-05be-433f-9c28-ee55610e9d07\backup_persistent_login\pubspec.yaml" "C:\Project\Plasvora_app\pubspec.yaml" -Force
Copy-Item "C:\Users\PPLG\.gemini\antigravity\brain\ad4f1028-05be-433f-9c28-ee55610e9d07\backup_persistent_login\lib\core\network\api_client.dart" "C:\Project\Plasvora_app\lib\core\network\api_client.dart" -Force
Copy-Item "C:\Users\PPLG\.gemini\antigravity\brain\ad4f1028-05be-433f-9c28-ee55610e9d07\backup_persistent_login\lib\repositories\auth_repository.dart" "C:\Project\Plasvora_app\lib\repositories\auth_repository.dart" -Force
Copy-Item "C:\Users\PPLG\.gemini\antigravity\brain\ad4f1028-05be-433f-9c28-ee55610e9d07\backup_persistent_login\lib\viewmodels\auth_viewmodel.dart" "C:\Project\Plasvora_app\lib\viewmodels\auth_viewmodel.dart" -Force
Copy-Item "C:\Users\PPLG\.gemini\antigravity\brain\ad4f1028-05be-433f-9c28-ee55610e9d07\backup_persistent_login\lib\main.dart" "C:\Project\Plasvora_app\lib\main.dart" -Force
```


---

## 23. Backup Penyempurnaan Keamanan Persistent Login (Flutter Secure Storage, Proteksi 403, & Migrasi Sandboxed Storage)

**Tanggal**: 15 November 2026  
**Tujuan**:
1. Menyempurnakan penyimpanan token autentikasi agar menggunakan mekanisme Android Keystore / `FlutterSecureStorage` (terenkripsi pada level OS) dengan kompatibilitas penuh terhadap Android 7 (Samsung Galaxy A7, API 24).
2. Menyediakan abstraksi `TokenStorage` yang lengkap (`saveToken()`, `getToken()`, `deleteToken()`, serta `clearToken()` untuk interoperabilitas).
3. Mengoreksi aturan penanganan HTTP 403 Forbidden pada `ApiAuthRepository.getCurrentUser()` agar TIDAK langsung menghapus token atau memutus sesi pengguna (karena HTTP 403 merupakan status penolakan hak akses/authorization, bukan kredensial tidak valid/unauthenticated). Token hanya dihapus pada status HTTP 401 Unauthorized.
4. Menambahkan mekanisme migrasi transparan jika berkas lama `.plasvora_auth_token` ditemukan, memindahkannya ke secure storage dan memverifikasi keterbacaannya sebelum berkas lama dihapus.
5. Mencegah race condition pada alur pemulihan sesi dengan pengaman single-execution di `AuthViewModel`.
6. Menambahkan suite pengujian komprehensif pada `test/persistent_login_test.dart` yang mencakup 13 skenario keamanan dan siklus sesi.

Direktori Backup Fisik:
`C:\Users\PPLG\.gemini\antigravity\brain\ad4f1028-05be-433f-9c28-ee55610e9d07\backup_persistent_login_security\`

Struktur Folder Backup:
```
backup_persistent_login_security/
├── pubspec.yaml
├── test/
│   └── persistent_login_test.dart
└── lib/
    ├── main.dart
    ├── core/
    │   └── network/
    │       └── api_client.dart
    ├── repositories/
    │   └── auth_repository.dart
    └── viewmodels/
        └── auth_viewmodel.dart
```

### File yang Di-backup Sebelum Diubah:
1. `pubspec.yaml`
2. `lib/core/network/api_client.dart`
3. `lib/repositories/auth_repository.dart`
4. `lib/viewmodels/auth_viewmodel.dart`
5. `lib/main.dart`
6. `test/persistent_login_test.dart`

### Langkah Pemulihan (Non-Git):
```powershell
Copy-Item "C:\Users\PPLG\.gemini\antigravity\brain\ad4f1028-05be-433f-9c28-ee55610e9d07\backup_persistent_login_security\pubspec.yaml" "C:\Project\Plasvora_app\pubspec.yaml" -Force
Copy-Item "C:\Users\PPLG\.gemini\antigravity\brain\ad4f1028-05be-433f-9c28-ee55610e9d07\backup_persistent_login_security\lib\core\network\api_client.dart" "C:\Project\Plasvora_app\lib\core\network\api_client.dart" -Force
Copy-Item "C:\Users\PPLG\.gemini\antigravity\brain\ad4f1028-05be-433f-9c28-ee55610e9d07\backup_persistent_login_security\lib\repositories\auth_repository.dart" "C:\Project\Plasvora_app\lib\repositories\auth_repository.dart" -Force
Copy-Item "C:\Users\PPLG\.gemini\antigravity\brain\ad4f1028-05be-433f-9c28-ee55610e9d07\backup_persistent_login_security\lib\viewmodels\auth_viewmodel.dart" "C:\Project\Plasvora_app\lib\viewmodels\auth_viewmodel.dart" -Force
Copy-Item "C:\Users\PPLG\.gemini\antigravity\brain\ad4f1028-05be-433f-9c28-ee55610e9d07\backup_persistent_login_security\lib\main.dart" "C:\Project\Plasvora_app\lib\main.dart" -Force
Copy-Item "C:\Users\PPLG\.gemini\antigravity\brain\ad4f1028-05be-433f-9c28-ee55610e9d07\backup_persistent_login_security\test\persistent_login_test.dart" "C:\Project\Plasvora_app\test\persistent_login_test.dart" -Force
```


---

## 24. Backup Perbaikan Analyzer & Koreksi Final Test Persistent Login

**Tanggal**: 15 November 2026  
**Tujuan**:
1. Memperbaiki temuan analyzer pada `lib/core/network/api_client.dart`:
   - Menerapkan initializing formal (`this.directoryProvider`) pada constructor `SecureAuthTokenStorage`.
   - Menghapus unnecessary non-null assertion (`!`) pada pemanggilan `directoryProvider()`.
   - Menerapkan super parameters pada constructor `PersistentAuthTokenStorage`.
2. Memperbaiki peringatan deprecated member use pada `lib/main.dart` dengan mengganti `withOpacity(...)` menjadi `withValues(alpha: ...)`.
3. Memperbaiki error kompilasi dan peringatan import pada `test/persistent_login_test.dart`:
   - Memperbaiki parameter constructor `AuthViewModel(authRepository: authRepo)` dari sebelumnya `authRepo: authRepo`.
   - Menghapus unused import `dart:async` dan `user_profile.dart`.
4. Melakukan audit komprehensif terhadap Android Auto Backup dan SharedPreferences terenkripsi (`FlutterSecureStorage.xml`) pada `flutter_secure_storage: 9.2.4`.

Direktori Backup Fisik:
`C:\Users\PPLG\.gemini\antigravity\brain\ad4f1028-05be-433f-9c28-ee55610e9d07\backup_persistent_login_final_correction\`

Struktur Folder Backup:
```
backup_persistent_login_final_correction/
├── lib/
│   ├── main.dart
│   └── core/
│       └── network/
│           └── api_client.dart
└── test/
    └── persistent_login_test.dart
```

### File yang Di-backup Sebelum Diubah:
1. `lib/core/network/api_client.dart`
2. `lib/main.dart`
3. `test/persistent_login_test.dart`

### Langkah Pemulihan (Non-Git):
```powershell
Copy-Item "C:\Users\PPLG\.gemini\antigravity\brain\ad4f1028-05be-433f-9c28-ee55610e9d07\backup_persistent_login_final_correction\lib\core\network\api_client.dart" "C:\Project\Plasvora_app\lib\core\network\api_client.dart" -Force
Copy-Item "C:\Users\PPLG\.gemini\antigravity\brain\ad4f1028-05be-433f-9c28-ee55610e9d07\backup_persistent_login_final_correction\lib\main.dart" "C:\Project\Plasvora_app\lib\main.dart" -Force
Copy-Item "C:\Users\PPLG\.gemini\antigravity\brain\ad4f1028-05be-433f-9c28-ee55610e9d07\backup_persistent_login_final_correction\test\persistent_login_test.dart" "C:\Project\Plasvora_app\test\persistent_login_test.dart" -Force
```


---

## 25. Backup Hotfix Null Safety Directory Provider pada Persistent Login

**Tanggal**: 15 November 2026  
**Tujuan**:
Memperbaiki error Dart flow analysis pada `lib/core/network/api_client.dart` di mana properti publik nullable `directoryProvider` tidak dapat dipromosikan langsung secara aman tanpa binding variabel lokal (`The function can't be unconditionally invoked because it can be 'null'`). Menerapkan pola idiomatik Dart dengan binding variabel lokal `final provider = directoryProvider;` sebelum null check pada method `_migrateLegacyTokenIfNeeded()` dan `deleteToken()`.

Direktori Backup Fisik:
`C:\Users\PPLG\.gemini\antigravity\brain\ad4f1028-05be-433f-9c28-ee55610e9d07\backup_directory_provider_null_safety\`

Struktur Folder Backup:
```
backup_directory_provider_null_safety/
└── lib/
    └── core/
        └── network/
            └── api_client.dart
```

### File yang Di-backup Sebelum Diubah:
1. `lib/core/network/api_client.dart`

### Langkah Pemulihan (Non-Git):
```powershell
Copy-Item "C:\Users\PPLG\.gemini\antigravity\brain\ad4f1028-05be-433f-9c28-ee55610e9d07\backup_directory_provider_null_safety\lib\core\network\api_client.dart" "C:\Project\Plasvora_app\lib\core\network\api_client.dart" -Force
```
