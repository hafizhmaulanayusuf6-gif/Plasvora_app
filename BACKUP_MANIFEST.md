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


---

## 26. Backup Perbaikan Horizontal Text Overflow & Responsive Layout Halaman Hasil Analisis

**Tanggal**: 20 November 2026

**Tujuan**:
1. Memperbaiki masalah horizontal text overflow pada Card Komponen Material di `lib/views/analysis/analysis_result_screen.dart` (termasuk baris badge `Dugaan Visual` + deskripsi resin panjang, baris `Material Dugaan`, dan baris `Titik leleh komponen` dalam kotak info material).
2. Memastikan header card komponen (ikon, judul komponen, tombol `Cara Cek`) responsif terhadap layar sempit (320px–412px) maupun pembesaran ukuran font sistem.
3. Mengaudit dan memperbaiki potensi text overflow pada seluruh bagian lain di halaman Hasil Analisis: badge preview foto, banner status AI Vision, header bagian `Komponen Material` & `Rekomendasi Upcycling`, kartu metrik `Karakter Titik Leleh` & `Emisi Terhindar`, kartu & detail modal `Rekomendasi Upcycling`, modal `Verifikasi Fisik`, serta tombol aksi dan indikator status bawah (menghapus fixed height dan menambahkan constraint wrapping).
4. Mempertahankan penuh desain visual Plasvora, data analisis AI, model, ViewModel, repository, dan alur navigasi tanpa perubahan logika bisnis.

Direktori Backup Fisik:
`C:\Users\PPLG\.gemini\antigravity\brain\9f4d9fd8-c98a-4cfd-b6f4-014e9debce8b\backup_analysis_result_overflow_fix\`

Struktur Folder Backup:
```
backup_analysis_result_overflow_fix/
└── lib/
    └── views/
        └── analysis/
            └── analysis_result_screen.dart
```

### File yang Di-backup Sebelum Diubah:
1. `lib/views/analysis/analysis_result_screen.dart` (52.896 bytes, SHA256: `189D1B7B8BB7BC36C03C6C63E7C6DA920AA6117C01103B700F2C17E025690FFC`)

### Langkah Pemulihan (Non-Git):
```powershell
Copy-Item "C:\Users\PPLG\.gemini\antigravity\brain\9f4d9fd8-c98a-4cfd-b6f4-014e9debce8b\backup_analysis_result_overflow_fix\lib\views\analysis\analysis_result_screen.dart" "C:\Project\Plasvora_app\lib\views\analysis\analysis_result_screen.dart" -Force
```



---

## 27. Backup Stage 1 Marketplace Foundation (Phone, WhatsApp Contact, Listing Image Upload & Lot Price Semantics — Frontend)

**Tanggal**: 21 November 2026

**Tujuan**:
1. Menambahkan dukungan nomor telepon/WhatsApp opsional saat registrasi serta pembaruan nomor telepon pada modal profil akun yang sudah ada.
2. Menambahkan tombol `Hubungi Penjual via WhatsApp` pada `MaterialDetailScreen` dengan format URL `https://wa.me/62...` dan pesan ter-encode berisi nama material (disembunyikan jika pemilik listing sendiri atau penjual belum memiliki nomor valid).
3. Menambahkan deklarasi dependensi `url_launcher` di `pubspec.yaml` dan `<queries>` HTTPS di `AndroidManifest.xml`.
4. Menambahkan pemilih & preview foto material dengan `image_picker` dan upload multipart pada `CreateMaterialListingScreen` dengan tetap menjaga alur `AI Analysis -> Jual Material Ini`.
5. Memperjelas semantik harga satu lot (`Harga total (satu lot)`) pada form listing serta menampilkan estimasi harga per kg (display-only) pada `MaterialDetailScreen`.
6. Menambahkan field nullable `ownerPhone`, `originDestinationId`, dan `originLabel` pada model `MaterialListing` serta memperbarui/menambah unit tests.

Direktori Backup Fisik:
`C:\Users\PPLG\.gemini\antigravity\brain\d907174e-f225-41e2-a0df-e727922bd3aa\backup_stage1_marketplace_foundation_fe\`

### File yang Di-backup Sebelum Diubah:
1. `pubspec.yaml`
2. `android/app/src/main/AndroidManifest.xml`
3. `lib/core/network/api_client.dart`
4. `lib/models/user_profile.dart`
5. `lib/models/material_listing.dart`
6. `lib/repositories/auth_repository.dart`
7. `lib/repositories/material_repository.dart`
8. `lib/viewmodels/auth_viewmodel.dart`
9. `lib/viewmodels/marketplace_viewmodel.dart`
10. `lib/views/auth/register_screen.dart`
11. `lib/views/home/home_screen.dart`
12. `lib/views/main_navigation_screen.dart`
13. `lib/views/marketplace/marketplace_screen.dart`
14. `lib/views/marketplace/material_detail_screen.dart`
15. `lib/views/marketplace/create_material_listing_screen.dart`
16. `lib/views/matching/matching_results_screen.dart`
17. `test/auth_ui_test.dart`
18. `test/marketplace_viewmodel_test.dart`

### Langkah Pemulihan (Non-Git):
```powershell
$bak = "C:\Users\PPLG\.gemini\antigravity\brain\d907174e-f225-41e2-a0df-e727922bd3aa\backup_stage1_marketplace_foundation_fe"
Copy-Item "$bak\*" "C:\Project\Plasvora_app\" -Recurse -Force
```


---

## 28. Backup Stage 1.1 WhatsApp Contact Privacy (Consent Toggle — Frontend)

**Tanggal**: 21 November 2026
**Tujuan**:
1. Menambahkan field `whatsappPublic` (default `false`) pada model `UserProfile`.
2. Memperluas `AuthRepository.updateProfile` dan `AuthViewModel.updateProfile` untuk mengirim `whatsapp_public` ke `PATCH /api/me` dengan proteksi toggle beruntun.
3. Menambahkan kontrol switch `Tampilkan nomor WhatsApp saya pada detail material` beserta penjelasan, validasi ketersediaan nomor telepon, rollback saat gagal simpan, dan sinkronisasi state otomatis pada modal `Profil Akun` di `HomeScreen`.
4. Menambahkan unit & widget tests pada `test/stage1_marketplace_foundation_test.dart` dan penyesuaian fake di `test/auth_ui_test.dart`.

Direktori Backup Fisik:
`C:\Users\PPLG\.gemini\antigravity\brain\d907174e-f225-41e2-a0df-e727922bd3aa\backup_stage1_1_whatsapp_privacy_fe\`

### File yang Di-backup Sebelum Diubah:
1. `lib/models/user_profile.dart`
2. `lib/repositories/auth_repository.dart`
3. `lib/viewmodels/auth_viewmodel.dart`
4. `lib/views/home/home_screen.dart`
5. `test/auth_ui_test.dart`
6. `test/stage1_marketplace_foundation_test.dart`

### Langkah Pemulihan (Non-Git):
```powershell
$bak = "C:\Users\PPLG\.gemini\antigravity\brain\d907174e-f225-41e2-a0df-e727922bd3aa\backup_stage1_1_whatsapp_privacy_fe"
Copy-Item "$bak\*" "C:\Project\Plasvora_app\" -Recurse -Force
```


---

## 29. Backup Perbaikan Widget Test Helper Modal Profil (Stage 1.1)

**Tanggal**: 21 November 2026
**Tujuan**:
Memperbaiki finder avatar pada helper `openProfileModal()` di `test/stage1_marketplace_foundation_test.dart` agar menargetkan `GestureDetector` milik avatar pengguna (`child is ClipRRect`) di dalam `PlasvoraHeader`, bukan `GestureDetector` internal milik `InkWell` tombol notifikasi yang muncul lebih awal di widget tree. Tidak ada perubahan pada kode UI produksi.

Direktori Backup Fisik:
`C:\Users\PPLG\.gemini\antigravity\brain\d907174e-f225-41e2-a0df-e727922bd3aa\backup_stage1_1_profile_modal_test_fix\`

### File yang Di-backup Sebelum Diubah:
1. `test/stage1_marketplace_foundation_test.dart`

### Langkah Pemulihan (Non-Git):
```powershell
Copy-Item "C:\Users\PPLG\.gemini\antigravity\brain\d907174e-f225-41e2-a0df-e727922bd3aa\backup_stage1_1_profile_modal_test_fix\test\stage1_marketplace_foundation_test.dart" "C:\Project\Plasvora_app\test\stage1_marketplace_foundation_test.dart" -Force
```


---

## 30. Backup Perbaikan Assertion Material ListTile pada Modal Profil (Stage 1.1)

**Tanggal**: 21 November 2026
**Tujuan**:
Mengganti pembungkus `Container(decoration: BoxDecoration(...))` yang memicu assertion Flutter `ListTile background color or ink splashes may be invisible` pada `SwitchListTile.adaptive` di modal `Profil Akun` (`lib/views/home/home_screen.dart`) dengan `Material(color: ..., shape: RoundedRectangleBorder(...), clipBehavior: Clip.antiAlias)` agar efek ink splash tampil benar dan tampilan visual (warna latar, border, radius 14px, padding, tipografi) tetap identik.

Direktori Backup Fisik:
`C:\Users\PPLG\.gemini\antigravity\brain\d907174e-f225-41e2-a0df-e727922bd3aa\backup_stage1_1_listtile_material_fix\`

### File yang Di-backup Sebelum Diubah:
1. `lib/views/home/home_screen.dart`

### Langkah Pemulihan (Non-Git):
```powershell
Copy-Item "C:\Users\PPLG\.gemini\antigravity\brain\d907174e-f225-41e2-a0df-e727922bd3aa\backup_stage1_1_listtile_material_fix\lib\views\home\home_screen.dart" "C:\Project\Plasvora_app\lib\views\home\home_screen.dart" -Force
```


---

## 31. Backup Perbaikan Konsistensi Query Reset Filter Kategori pada MarketplaceViewModel

**Tanggal**: 21 November 2026
**Tujuan**:
Menyelaraskan pemetaan `categoryQuery` di `MarketplaceViewModel.loadListings()` (`lib/viewmodels/marketplace_viewmodel.dart`) agar nilai default UI `'Semua'` dipetakan menjadi `null` saat dikirim ke `materialRepository.getMaterials(...)`, konsisten dengan pemetaan `conditionQuery` (`_selectedCondition == 'Semua' ? null : _selectedCondition`) dan kontrak pengujian `test/marketplace_viewmodel_test.dart`.

Direktori Backup Fisik:
`C:\Users\PPLG\.gemini\antigravity\brain\d907174e-f225-41e2-a0df-e727922bd3aa\backup_marketplace_filter_reset_fix\`

### File yang Di-backup Sebelum Diubah:
1. `lib/viewmodels/marketplace_viewmodel.dart`

### Langkah Pemulihan (Non-Git):
```powershell
Copy-Item "C:\Users\PPLG\.gemini\antigravity\brain\d907174e-f225-41e2-a0df-e727922bd3aa\backup_marketplace_filter_reset_fix\lib\viewmodels\marketplace_viewmodel.dart" "C:\Project\Plasvora_app\lib\viewmodels\marketplace_viewmodel.dart" -Force
```


---

## 32. Backup Stage 2 Batch 3 — Flutter Data Layer (Addresses, Shipping & Listing Origin/Update)

**Tanggal**: 22 November 2026
**Tujuan**:
1. Menambahkan endpoint terpusat `/addresses`, `/shipping/destinations`, dan `/shipping/estimate` di `lib/core/network/api_config.dart`.
2. Membuat model data (`ShippingDestination`, `ShippingCostOption`, `ShippingEstimateResult`, `UserAddress`), repository (`AddressRepository`, `ShippingRepository`), serta `AddressViewModel`.
3. Memperluas `MaterialRepository` dan `MarketplaceViewModel` untuk mendukung field origin (`originDestinationId`, `originLabel`) saat create serta operasi `updateMaterial` / `updateListing` (JSON PATCH dan multipart replacement image dengan `_method=PATCH`).
4. Menyiapkan injeksi dependensi manual (`AddressViewModel`, `ShippingRepository`) di `lib/main.dart` dan `lib/views/main_navigation_screen.dart` tanpa perubahan UI.
5. Menambahkan unit tests data layer pada `test/stage3_data_layer_test.dart` serta pembaruan fake repository di `test/marketplace_viewmodel_test.dart`.

Direktori Backup Fisik:
`C:\Users\PPLG\.gemini\antigravity\brain\d907174e-f225-41e2-a0df-e727922bd3aa\backup_stage2_batch3_fe\`

### File yang Di-backup Sebelum Diubah:
1. `lib/core/network/api_config.dart`
2. `lib/repositories/material_repository.dart`
3. `lib/viewmodels/marketplace_viewmodel.dart`
4. `lib/main.dart`
5. `lib/views/main_navigation_screen.dart`
6. `test/marketplace_viewmodel_test.dart`

### Langkah Pemulihan (Non-Git):
```powershell
$bak = "C:\Users\PPLG\.gemini\antigravity\brain\d907174e-f225-41e2-a0df-e727922bd3aa\backup_stage2_batch3_fe"
Copy-Item "$bak\*" "C:\Project\Plasvora_app\" -Recurse -Force
```


---

## 33. Backup Perbaikan Code Review Stage 2 Batch 3 (Origin Pair Strictness & AddressViewModel Refresh Resilience)

**Tanggal**: 22 November 2026
**Tujuan**:
1. Memperketat validasi pasangan `originDestinationId` / `originLabel` di `lib/repositories/material_repository.dart` (dan meneruskan `ArgumentError` di `lib/viewmodels/marketplace_viewmodel.dart`) agar half-pair, label whitespace-only, ID `<= 0`, serta konflik `clearOrigin: true` dengan origin baru selalu melempar `ArgumentError` sebelum request HTTP dikirim.
2. Memisahkan penanganan error mutasi dan refresh pasca-mutasi (`getAddresses()`) pada `lib/viewmodels/address_viewmodel.dart` agar mutasi yang sukses di backend tidak keliru dilaporkan gagal jika refresh gagal, serta mencegah `loadAddresses()` usang menimpa data mutasi terbaru.
3. Memperbarui dan menambah unit tests pada `test/stage3_data_layer_test.dart` untuk seluruh kasus validasi origin ketat dan ketahanan refresh pasca-mutasi.

Direktori Backup Fisik:
`C:\Users\PPLG\.gemini\antigravity\brain\d907174e-f225-41e2-a0df-e727922bd3aa\backup_stage2_batch3_review_fix_fe\`

### File yang Di-backup Sebelum Diubah:
1. `lib/repositories/material_repository.dart`
2. `lib/viewmodels/marketplace_viewmodel.dart`
3. `lib/viewmodels/address_viewmodel.dart`
4. `test/stage3_data_layer_test.dart`

### Langkah Pemulihan (Non-Git):
```powershell
$bak = "C:\Users\PPLG\.gemini\antigravity\brain\d907174e-f225-41e2-a0df-e727922bd3aa\backup_stage2_batch3_review_fix_fe"
Copy-Item "$bak\*" "C:\Project\Plasvora_app\" -Recurse -Force
```


---

## 34. Backup Stage 2 Batch 4 — Flutter UI & Shipping Integration

**Tanggal**: 22 November 2026
**Tujuan**:
1. Menambahkan `lib/core/widgets/destination_picker_sheet.dart` sebagai pemilih destinasi domestik reusable (debounce 400ms, minimal 2 karakter, stale-response guard, loading/empty/error/retry).
2. Menambahkan Buku Alamat (`lib/views/address/address_list_screen.dart`) dan Form Alamat (`lib/views/address/address_form_screen.dart`) serta memperluas `AddressViewModel` (`fieldErrors`) untuk menampilkan error validasi backend per field.
3. Menambahkan akses `Kelola Alamat Pengiriman` pada modal Profil Akun di `lib/views/home/home_screen.dart`.
4. Memperluas `lib/views/marketplace/create_material_listing_screen.dart` dengan pemilihan lokasi asal pengiriman (wajib pada mode create, kompatibel listing lama null-origin + `clearOrigin: true` pada mode edit, preservasi prefill AI Analysis & gambar existing, serta penanganan `ArgumentError` lokal sebagai feedback validasi UI).
5. Menambahkan tombol `Edit Listing` (khusus pemilik) dan panel Estimasi Ongkos Kirim eksplisit (`Cek Ongkir`) pada `lib/views/marketplace/material_detail_screen.dart` dengan penanganan kepemilikan & tamu.
6. Menghubungkan injeksi dependensi konstruktor (`AddressViewModel`, `ShippingRepository`) lintas `MainNavigationScreen`, `HomeScreen`, `MarketplaceScreen`, `MatchingResultsScreen`, `MaterialRequestDetailScreen`, `AnalysisScreen`, `AnalysisResultScreen`, dan `ActivityScreen`.
7. Menambahkan suite widget test `test/stage4_shipping_ui_test.dart`.

Direktori Backup Fisik:
`C:\Users\PPLG\.gemini\antigravity\brain\d907174e-f225-41e2-a0df-e727922bd3aa\backup_stage2_batch4_fe\`

### File yang Di-backup Sebelum Diubah:
1. `lib/viewmodels/address_viewmodel.dart`
2. `lib/views/main_navigation_screen.dart`
3. `lib/views/home/home_screen.dart`
4. `lib/views/marketplace/create_material_listing_screen.dart`
5. `lib/views/marketplace/material_detail_screen.dart`
6. `lib/views/marketplace/marketplace_screen.dart`
7. `lib/views/matching/matching_results_screen.dart`
8. `lib/views/material_request/material_request_detail_screen.dart`
9. `lib/views/analysis/analysis_screen.dart`
10. `lib/views/analysis/analysis_result_screen.dart`
11. `lib/views/activity/activity_screen.dart`

### Langkah Pemulihan (Non-Git):
```powershell
$bak = "C:\Users\PPLG\.gemini\antigravity\brain\d907174e-f225-41e2-a0df-e727922bd3aa\backup_stage2_batch4_fe"
Copy-Item "$bak\*" "C:\Project\Plasvora_app\" -Recurse -Force
```


---

## 35. Backup Perbaikan Stage 4 Test Fixture (ImpactSummary Constructor Mismatch)

**Tanggal**: 22 November 2026
**Tujuan**:
Memperbaiki konstruktor `ImpactSummary` pada `_FakeMaterialRepository.getImpactSummary()` di `test/stage4_shipping_ui_test.dart` (menghapus `const` yang tidak valid serta mengganti 4 parameter lama dengan 8 parameter wajib sesuai kontrak produksi `lib/models/impact_summary.dart`). Tidak ada perubahan pada model produksi.

Direktori Backup Fisik:
`C:\Users\PPLG\.gemini\antigravity\brain\d907174e-f225-41e2-a0df-e727922bd3aa\backup_stage2_batch4_impact_summary_fix\`

### File yang Di-backup Sebelum Diubah:
1. `test/stage4_shipping_ui_test.dart`

### Langkah Pemulihan (Non-Git):
```powershell
Copy-Item "C:\Users\PPLG\.gemini\antigravity\brain\d907174e-f225-41e2-a0df-e727922bd3aa\backup_stage2_batch4_impact_summary_fix\test\stage4_shipping_ui_test.dart" "C:\Project\Plasvora_app\test\stage4_shipping_ui_test.dart" -Force
```


---

## 36. Backup Perbaikan Stage 4 Widget Test (Asset Fixture, Viewport Scroll Visibility, & Multipart Async I/O)

**Tanggal**: 22 November 2026
**Tujuan**:
1. Mengganti fixture asset tidak valid `'assets/images/plastic_pet.png'` dengan konstanta asset resmi `AppAssets.petFlakes` (`assets/images/pet_flakes.jpg`) pada `test/stage4_shipping_ui_test.dart`.
2. Memperbaiki helper `_scrollTo` / `_scrollToAndTap` agar memanggil `tester.ensureVisible(finder)` sehingga tombol di dalam `SingleChildScrollView` / `ListView` (seperti `Simpan Perubahan` dan `Cek Ongkir`) benar-benar digulir ke dalam viewport 800×600 sebelum di-tap.
3. Memperbaiki test multipart image replacement agar tidak deadlock di zona `FakeAsync` (menulis/menghapus temp file secara sinkron, mengganti `imageUrl` dummy dengan `localAsset: AppAssets.petFlakes` agar `Image.network` tidak membuat `HttpClient`, serta menggunakan `tester.runAsync` untuk menyelesaikan `dart:io` file I/O milik `ApiClient.postMultipart` sebelum `pumpAndSettle`).

Direktori Backup Fisik:
`C:\Users\PPLG\.gemini\antigravity\brain\d907174e-f225-41e2-a0df-e727922bd3aa\backup_stage2_batch4_test_fixes\`

### File yang Di-backup Sebelum Diubah:
1. `test/stage4_shipping_ui_test.dart`

### Langkah Pemulihan (Non-Git):
```powershell
Copy-Item "C:\Users\PPLG\.gemini\antigravity\brain\d907174e-f225-41e2-a0df-e727922bd3aa\backup_stage2_batch4_test_fixes\test\stage4_shipping_ui_test.dart" "C:\Project\Plasvora_app\test\stage4_shipping_ui_test.dart" -Force
```


---

## 37. Backup Perbaikan Putaran 2 Stage 4 Widget Tests (EditableText Scroll-Back & Multipart FakeAsync Interleaving)

**Tanggal**: 22 November 2026
**Tujuan**:
1. Menyelesaikan timer internal `EditableText` (`_showCaretOnScreen`) di `_ensureAndEnterText()` melalui `pumpAndSettle()` setelah `enterText()` serta memverifikasi/menggulir langsung `Scrollable` ancestor di `_scrollTo()`/`_scrollToAndTap()` agar `Simpan Perubahan` tidak terdorong keluar viewport 800×600 sebelum di-tap.
2. Memperbaiki deadlock zona `FakeAsync` vs `dart:io` pada test multipart image replacement (`ApiClient.postMultipart` → `MultipartFile.fromPath` → `MockClient.streaming`) dengan menginterleave `tester.runAsync(10ms)` dan `tester.pump()`, menggunakan direktori/berkas temporer unik per test, mem-pop `CreateMaterialListingScreen` ke route induk agar `Image.file` & spinner terlepas sebelum `tempDir.deleteSync(recursive: true)`, serta menghindari `pumpAndSettle` selama spinner aktif.

Direktori Backup Fisik:
`C:\Users\PPLG\.gemini\antigravity\brain\d907174e-f225-41e2-a0df-e727922bd3aa\backup_stage2_batch4_round2_fixes\`

### File yang Di-backup Sebelum Diubah:
1. `test/stage4_shipping_ui_test.dart`

### Langkah Pemulihan (Non-Git):
```powershell
Copy-Item "C:\Users\PPLG\.gemini\antigravity\brain\d907174e-f225-41e2-a0df-e727922bd3aa\backup_stage2_batch4_round2_fixes\test\stage4_shipping_ui_test.dart" "C:\Project\Plasvora_app\test\stage4_shipping_ui_test.dart" -Force
```


---

## 38. Backup Perbaikan Final Multipart Saving-State Lifecycle, Route Pop Pumping, & GoogleFonts Test Isolation

**Tanggal**: 22 November 2026
**Tujuan**:
1. Mereset `_isSubmitting = false` pada cabang sukses create & edit di `lib/views/marketplace/create_material_listing_screen.dart` sebelum `Navigator.of(context).pop(...)` agar spinner tombol submit berhenti segera setelah penyimpanan berhasil (tidak terus berputar sepanjang animasi pop 300ms).
2. Memperbarui test multipart pada `test/stage4_shipping_ui_test.dart` dengan sinyal penyelesaian eksplisit (`requestStreamConsumed`, `responseReturned`, `!marketVm.isSaving`, `updatedResult != null`) dan 3 tahap bounded `pump()` (`pump()` → `pump(350ms)` → `pump()`) untuk menyelesaikan animasi reverse `MaterialPageRoute` secara deterministik sebelum memeriksa penghapusan `CreateMaterialListingScreen` dan `CircularProgressIndicator`.
3. Menonaktifkan runtime fetching `GoogleFonts.config.allowRuntimeFetching = false` di `setUpAll` (dipulihkan di `tearDownAll`) pada `test/stage4_shipping_ui_test.dart` agar widget test tidak membuat `HttpClient` ke `fonts.gstatic.com`.

Direktori Backup Fisik:
`C:\Users\PPLG\.gemini\antigravity\brain\d907174e-f225-41e2-a0df-e727922bd3aa\backup_stage2_batch4_round3_fixes\`

### File yang Di-backup Sebelum Diubah:
1. `lib/views/marketplace/create_material_listing_screen.dart`
2. `test/stage4_shipping_ui_test.dart`

### Langkah Pemulihan (Non-Git):
```powershell
$bak = "C:\Users\PPLG\.gemini\antigravity\brain\d907174e-f225-41e2-a0df-e727922bd3aa\backup_stage2_batch4_round3_fixes"
Copy-Item "$bak\*" "C:\Project\Plasvora_app\" -Recurse -Force
```


---

## 39. Backup Perbaikan Putaran 4 Stage 4 (Navigator Route Completion Signal & Bundling Lokal Plus Jakarta Sans)

**Tanggal**: 22 November 2026
**Tujuan**:
1. Mengganti asumsi durasi tunggal 350ms pada test multipart `test/stage4_shipping_ui_test.dart` dengan sinyal deterministik `editRoute.completed` + verifikasi `Future` dari `Navigator.push` (`pushFuture`) sehingga penghapusan `CreateMaterialListingScreen` dan `CircularProgressIndicator` terverifikasi tepat setelah transisi reverse route selesai.
2. Membundel 4 bobot resmi Google Fonts `Plus Jakarta Sans` yang digunakan aplikasi (`Regular` 400, `Medium` 500, `SemiBold` 600, `Bold` 700 — terverifikasi SHA-256 & panjang byte sesuai deskriptor `google_fonts 9.0.0`) beserta lisensi resmi `OFL.txt` (SIL Open Font License 1.1) di `assets/fonts/` dan mendeklarasikan `- assets/fonts/` pada `pubspec.yaml`.
3. Menambahkan verifikasi pemuatan lokal 4 bobot `PlusJakartaSans` dengan `GoogleFonts.config.allowRuntimeFetching = false` (dipulihkan di `tearDownAll`) tanpa request HTTP ke `fonts.gstatic.com`.

Direktori Backup Fisik:
`C:\Users\PPLG\.gemini\antigravity\brain\d907174e-f225-41e2-a0df-e727922bd3aa\backup_stage2_batch4_round4_fixes\`

### File yang Di-backup Sebelum Diubah:
1. `pubspec.yaml`
2. `test/stage4_shipping_ui_test.dart`

### File Baru Ditambahkan:
1. `assets/fonts/PlusJakartaSans-Regular.ttf`
2. `assets/fonts/PlusJakartaSans-Medium.ttf`
3. `assets/fonts/PlusJakartaSans-SemiBold.ttf`
4. `assets/fonts/PlusJakartaSans-Bold.ttf`
5. `assets/fonts/OFL.txt`

### Langkah Pemulihan (Non-Git):
```powershell
$bak = "C:\Users\PPLG\.gemini\antigravity\brain\d907174e-f225-41e2-a0df-e727922bd3aa\backup_stage2_batch4_round4_fixes"
Copy-Item "$bak\*" "C:\Project\Plasvora_app\" -Recurse -Force
```


---

## 40. Backup Perbaikan Lifecycle Logout Modal Profil & Keamanan Isolasi Sesi Pengguna

**Tanggal**: 22 November 2026
**Tujuan**:
1. Memisahkan konten modal Profil Akun pada `lib/views/home/home_screen.dart` menjadi `StatefulWidget` privat (`_ProfileAccountSheet`) agar `TextEditingController` dimiliki dan dibuang hanya pada `State.dispose()` (menghapus `.whenComplete(phoneController.dispose)` yang prematur).
2. Mengamankan urutan transisi keluar dan navigasi Buku Alamat menggunakan `TransitionRoute.completed` dari `ModalRoute.of(...)` sehingga `ModalBottomSheetRoute` benar-benar selesai di-unmount sebelum `AuthViewModel.logout()` atau `Navigator.push(AddressListScreen)` dijalankan.
3. Memperkuat `PlasvoraApp` (`lib/main.dart`) dan `AuthViewModel` (`lib/viewmodels/auth_viewmodel.dart`) agar `MainNavigationScreen` tidak dilepas prematur pada `AuthState.loading` selama proses logout berlangsung serta menyediakan callback `onSessionCleared`.
4. Menambahkan `AddressViewModel.clearUserData()` (`lib/viewmodels/address_viewmodel.dart`) dengan increment `_stateVersion` untuk mengisolasi cache alamat antar-akun saat logout / sesi dicabut dan mencegah respons async usang memulihkan data akun sebelumnya.
5. Mengamankan pembersihan token lokal pada `ApiAuthRepository.logout()` (`lib/repositories/auth_repository.dart`) dan `ApiClient.post()` (`lib/core/network/api_client.dart`) agar token lokal dihapus terlebih dahulu sebelum revokasi server-side best-effort (dengan timeout 5 detik).
6. Menambahkan regression widget & unit tests pada `test/profile_logout_security_test.dart`.

Direktori Backup Fisik:
`C:\Users\PPLG\.gemini\antigravity\brain\d907174e-f225-41e2-a0df-e727922bd3aa\backup_logout_lifecycle_session_security\`

### File yang Di-backup Sebelum Diubah:
1. `lib/views/home/home_screen.dart`
2. `lib/main.dart`
3. `lib/viewmodels/auth_viewmodel.dart`
4. `lib/viewmodels/address_viewmodel.dart`
5. `lib/repositories/auth_repository.dart`
6. `lib/core/network/api_client.dart`

### File Baru Ditambahkan:
1. `test/profile_logout_security_test.dart`

### Langkah Pemulihan (Non-Git):
```powershell
$bak = "C:\Users\PPLG\.gemini\antigravity\brain\d907174e-f225-41e2-a0df-e727922bd3aa\backup_logout_lifecycle_session_security"
Copy-Item "$bak\*" "C:\Project\Plasvora_app\" -Recurse -Force
```


---

## 41. Backup Perbaikan Null-Aware Access `activeRoute?.completed` di `home_screen.dart`

**Tanggal**: 22 November 2026
**Tujuan**:
Memperbaiki 2 error `flutter analyze` pada `lib/views/home/home_screen.dart` (`_handleOpenAddresses` dan `_handleLogout`) dengan mengganti pengecekan `activeRoute is TransitionRoute<dynamic> ? activeRoute.completed : null` menjadi akses null-aware langsung `activeRoute?.completed` sesuai tipe `ModalRoute<Object?>?` (yang merupakan subkelas `TransitionRoute`).

Direktori Backup Fisik:
`C:\Users\PPLG\.gemini\antigravity\brain\d907174e-f225-41e2-a0df-e727922bd3aa\backup_home_screen_completed_null_aware\`

### File yang Di-backup Sebelum Diubah:
1. `lib/views/home/home_screen.dart`

### Langkah Pemulihan (Non-Git):
```powershell
Copy-Item "C:\Users\PPLG\.gemini\antigravity\brain\d907174e-f225-41e2-a0df-e727922bd3aa\backup_home_screen_completed_null_aware\lib\views\home\home_screen.dart" "C:\Project\Plasvora_app\lib\views\home\home_screen.dart" -Force
```


---

## 42. Backup Perbaikan Finder Tombol Back pada Test B (`profile_logout_security_test.dart`)

**Tanggal**: 22 November 2026
**Tujuan**:
Mengganti `tester.pageBack()` pada Test B di `test/profile_logout_security_test.dart` dengan interaksi langsung pada tombol kembali aktual `IconButton(icon: Icon(Icons.arrow_back))` di dalam `PlasvoraHeader` milik `AddressListScreen`, karena `PlasvoraHeader` menggunakan tombol kembali kustom (bukan `BackButton` dengan tooltip `'Back'` atau `CupertinoNavigationBarBackButton`). Tidak ada perubahan pada kode produksi.

Direktori Backup Fisik:
`C:\Users\PPLG\.gemini\antigravity\brain\d907174e-f225-41e2-a0df-e727922bd3aa\backup_test_b_back_button_fix\`

### File yang Di-backup Sebelum Diubah:
1. `test/profile_logout_security_test.dart`

### Langkah Pemulihan (Non-Git):
```powershell
Copy-Item "C:\Users\PPLG\.gemini\antigravity\brain\d907174e-f225-41e2-a0df-e727922bd3aa\backup_test_b_back_button_fix\test\profile_logout_security_test.dart" "C:\Project\Plasvora_app\test\profile_logout_security_test.dart" -Force
```


---

## 43. Backup Stage 3 — Flutter Transaction Experience (Checkout, Midtrans Snap Redirect, Order Management & Seller Fulfillment)

**Tanggal**: 22 November 2026  
**Fitur**: Stage 3 — Flutter Transaction Experience (Data Layer, Checkout, Midtrans Payment Launch & Resume Sync, Buyer/Seller Order Management, Session Isolation)  
**Tujuan**:
1. Menambahkan kontrak endpoint `/api/orders*` di `lib/core/network/api_config.dart` serta propagasi `ApiException.data` pada `lib/core/network/api_client.dart` untuk dukungan `reconciliation_required` / `order_id`.
2. Membuat data layer Stage 3 (`lib/models/order_item.dart`, `lib/repositories/order_repository.dart`, `lib/viewmodels/order_viewmodel.dart`, `lib/core/utils/payment_launcher.dart`) sesuai arsitektur MVVM (`ChangeNotifier` + `ListenableBuilder`) dan isolasi sesi `OrderViewModel.clearUserData()` dengan `_sessionVersion`.
3. Menyambungkan shared `OrderViewModel` via constructor injection di `lib/main.dart`, `lib/views/main_navigation_screen.dart`, `lib/views/home/home_screen.dart`, `lib/views/marketplace/marketplace_screen.dart`, `lib/views/marketplace/material_detail_screen.dart`, dan `lib/views/activity/activity_screen.dart`, serta menggabungkan `orderViewModel.clearUserData()` bersama `addressViewModel.clearUserData()` pada `AuthViewModel.onSessionCleared`.
4. Membuat UI transaksi `CheckoutScreen`, `OrderListScreen`, dan `OrderDetailScreen` dengan validasi host resmi Midtrans Snap (`app.sandbox.midtrans.com` / `app.midtrans.com`), sinkronisasi `refresh-payment` saat app resume, privasi alamat pembeli sebelum bayar, form input resi penjual, konfirmasi penerimaan pembeli, dan navigasi `Pesanan Saya` yang lifecycle-safe (`TransitionRoute.completed`).
5. Memperluas `lib/models/activity_item.dart` untuk ikon/status aktivitas `'order'` dan menambahkan 6 file automated tests (`test/order_model_test.dart`, `test/order_repository_test.dart`, `test/order_viewmodel_test.dart`, `test/checkout_screen_test.dart`, `test/order_list_screen_test.dart`, `test/order_detail_screen_test.dart`).

Direktori Backup Fisik:
`C:\Users\PPLG\.gemini\antigravity\brain\d907174e-f225-41e2-a0df-e727922bd3aa\backup_stage3_flutter_transaction_fe\`

### File Eksisting yang Di-backup & Dimodifikasi:
1. `lib/core/network/api_config.dart`
2. `lib/core/network/api_client.dart`
3. `lib/models/activity_item.dart`
4. `lib/main.dart`
5. `lib/views/main_navigation_screen.dart`
6. `lib/views/home/home_screen.dart`
7. `lib/views/marketplace/marketplace_screen.dart`
8. `lib/views/marketplace/material_detail_screen.dart`
9. `lib/views/activity/activity_screen.dart`

### File Baru yang Dibuat:
1. `lib/core/utils/payment_launcher.dart`
2. `lib/models/order_item.dart`
3. `lib/repositories/order_repository.dart`
4. `lib/viewmodels/order_viewmodel.dart`
5. `lib/views/checkout/checkout_screen.dart`
6. `lib/views/orders/order_list_screen.dart`
7. `lib/views/orders/order_detail_screen.dart`
8. `test/order_model_test.dart`
9. `test/order_repository_test.dart`
10. `test/order_viewmodel_test.dart`
11. `test/checkout_screen_test.dart`
12. `test/order_list_screen_test.dart`
13. `test/order_detail_screen_test.dart`

### Langkah Pemulihan (Non-Git):
```powershell
$bak = "C:\Users\PPLG\.gemini\antigravity\brain\d907174e-f225-41e2-a0df-e727922bd3aa\backup_stage3_flutter_transaction_fe"
Copy-Item "$bak\*" "C:\Project\Plasvora_app\" -Recurse -Force
```



---

## 44. Backup Perbaikan Comprehensive Debugging Stage 3 — Flutter Transaction Experience (Package Imports, PlasvoraHeader Parameter, Lifecycle Safety, & Test Interface Alignment)

**Tanggal**: 22 November 2026  
**Fitur**: Stage 3 — Flutter Transaction Experience (Comprehensive Debugging & Static/Test Alignment Fix)  
**Tujuan**:
1. Memperbaiki parameter konstruktor `PlasvoraHeader` (`showBackButton: true` -> `showBack: true`) pada `CheckoutScreen`, `OrderListScreen`, dan `OrderDetailScreen` agar sesuai definisi aktual `lib/core/widgets/plasvora_header.dart`.
2. Mengamankan pemanggilan `notifyListeners()` selama `initState()`: memindahkan `orderViewModel.clearErrors()` di `CheckoutScreen.initState()` ke dalam `addPostFrameCallback`, serta menambahkan parameter `{bool notify = true}` pada `OrderViewModel.setCurrentOrderPreview(...)` dan memanggil `notify: false` di `OrderDetailScreen.initState()`.
3. Menambahkan pembersihan defensif `orderViewModel?.clearUserData()` di `HomeScreen._logoutAfterModalClose` mendampingi `onSessionCleared` di `lib/main.dart`.
4. Memperbaiki prefix import paket pada seluruh 6 file test Stage 3 (`package:plasvora_app/...` -> `package:plasvora/...` sesuai `name: plasvora` di `pubspec.yaml`), yang menjadi akar penyebab ratusan error `Undefined name` / `isn't a type`.
5. Menyelaraskan stub dan interaksi widget test di `test/checkout_screen_test.dart`, `test/order_list_screen_test.dart`, dan `test/order_detail_screen_test.dart` dengan kontrak produksi aktual (`UserProfile` di `models/user_profile.dart`, interface `AuthRepository` lengkap, `MockMaterialRepository.getMaterials(...)` dengan `simulateDelay: false`, finder avatar `PlasvoraHeader`, `ElevatedButton.icon` ancestor finder, `GoogleFonts.config.allowRuntimeFetching = false`, `ValueKey` unik per skenario, `scrollUntilVisible`/`ensureVisible`, dan uji blokir double-tap).

Direktori Backup Fisik:
`C:\Users\PPLG\.gemini\antigravity\brain\d907174e-f225-41e2-a0df-e727922bd3aa\backup_stage3_flutter_debug_fix_fe\`

### File yang Di-backup & Dimodifikasi:
1. `lib/viewmodels/order_viewmodel.dart`
2. `lib/views/checkout/checkout_screen.dart`
3. `lib/views/orders/order_list_screen.dart`
4. `lib/views/orders/order_detail_screen.dart`
5. `lib/views/home/home_screen.dart`
6. `test/order_model_test.dart`
7. `test/order_repository_test.dart`
8. `test/order_viewmodel_test.dart`
9. `test/checkout_screen_test.dart`
10. `test/order_list_screen_test.dart`
11. `test/order_detail_screen_test.dart`

### Langkah Pemulihan (Non-Git):
```powershell
$bak = "C:\Users\PPLG\.gemini\antigravity\brain\d907174e-f225-41e2-a0df-e727922bd3aa\backup_stage3_flutter_debug_fix_fe"
Copy-Item "$bak\*" "C:\Project\Plasvora_app\" -Recurse -Force
```



---

## 45. Backup Perbaikan Targeted Widget Test Scrolling Stage 3 (`checkout_screen_test.dart` & `order_detail_screen_test.dart`)

**Tanggal**: 22 November 2026  
**Fitur**: Stage 3 — Targeted Widget Test Fix (Scrollable Disambiguation & Post-`ensureVisible` Layout Settling)  
**Tujuan**:
1. Memperbaiki kegagalan `Bad state: Too many elements` pada `tester.scrollUntilVisible(...)` di `test/checkout_screen_test.dart` akibat kemunculan `Scrollable` internal milik `TextField` catatan pembeli (`maxLines: 2`) di dalam `ListView`, dengan menargetkan secara eksplisit `Scrollable` utama milik `ListView` (`find.descendant(of: find.byType(ListView), matching: find.byType(Scrollable)).first`), menambahkan `await tester.pumpAndSettle()` setelah `ensureVisible`, serta menghapus `warnIfMissed: false` pada verifikasi double-tap tombol `bottomNavigationBar`.
2. Memperbaiki kegagalan `Offset(400.0, 680.0) is outside the bounds Size(800.0, 600.0)` pada `test/order_detail_screen_test.dart` dengan menargetkan `Scrollable` milik `ListView` secara eksplisit pada `scrollUntilVisible(shipBtn, ...)` dan memanggil `await tester.pumpAndSettle()` setelah setiap `tester.ensureVisible(...)` agar layout `RenderBox` tombol `Input Resi & Kirim Pesanan` dan field `Nomor Resi *` selesai diperbarui masuk ke dalam viewport sebelum `tap`/`enterText`.
3. Tidak ada perubahan pada kode produksi Flutter maupun backend Laravel.

Direktori Backup Fisik:
`C:\Users\PPLG\.gemini\antigravity\brain\d907174e-f225-41e2-a0df-e727922bd3aa\backup_stage3_widget_test_scroll_fix\`

### File yang Di-backup & Dimodifikasi:
1. `test/checkout_screen_test.dart`
2. `test/order_detail_screen_test.dart`

### Langkah Pemulihan (Non-Git):
```powershell
$bak = "C:\Users\PPLG\.gemini\antigravity\brain\d907174e-f225-41e2-a0df-e727922bd3aa\backup_stage3_widget_test_scroll_fix"
Copy-Item "$bak\*" "C:\Project\Plasvora_app\" -Recurse -Force
```



---

## 46. Backup Perbaikan CheckoutScreen Blank pada Perangkat Android Fisik (`AppTheme.lightTheme` Infinite-Width `ElevatedButton` Layout Crash + Address Error & Empty Courier States)

**Tanggal**: 22 November 2026  
**Fitur**: Stage 3 — CheckoutScreen Runtime Layout Fix & Complete Error/Empty States  
**Tujuan**:
1. Memperbaiki akar penyebab layar `CheckoutScreen` tampil kosong di bawah `PlasvoraHeader` pada perangkat Android fisik: `AppTheme.lightTheme.elevatedButtonTheme` menetapkan `minimumSize: const Size.fromHeight(50)` (`width: double.infinity`), sehingga `ElevatedButton` (`Buat Pesanan & Bayar`) di dalam `Row` milik `CheckoutScreen.bottomNavigationBar` yang tidak meng-override `minimumSize` memicu `BoxConstraints forces an infinite width` saat `Scaffold` melayout `bottomNavigationBar` (sebelum `body`), menggagalkan layout seluruh `bottomNavigationBar` dan `body`. Ditambahkan `minimumSize: const Size(140, 48)` pada tombol bottom bar serta `maxLines: 1, overflow: TextOverflow.ellipsis` pada teks total pembayaran dan `minimumSize: const Size(0, 48)` pada tombol `Tambah Alamat Pengiriman`.
2. Menambahkan state error pemuatan alamat (`addrVm.errorMessage != null && addrVm.addresses.isEmpty`) dengan tombol `Coba Lagi` di `_buildAddressCard` serta aksi `Coba Hitung Lagi` & `Ganti Alamat` pada state opsi pengiriman kosong di `_buildCourierSelectionCard`.
3. Menambahkan `theme: AppTheme.lightTheme` dan test regresi viewport HP (`360x800`) pada `test/checkout_screen_test.dart` untuk memastikan bug tema ini tidak pernah terulang.
4. Tidak ada perubahan pada backend Laravel, `.env`, migrasi database, repository, maupun ViewModel.

Direktori Backup Fisik:
`C:\Users\PPLG\.gemini\antigravity\brain\d907174e-f225-41e2-a0df-e727922bd3aa\backup_stage3_checkout_blank_screen_fix\`

### File yang Di-backup & Dimodifikasi:
1. `lib/views/checkout/checkout_screen.dart`
2. `test/checkout_screen_test.dart`

### Langkah Pemulihan (Non-Git):
```powershell
$bak = "C:\Users\PPLG\.gemini\antigravity\brain\d907174e-f225-41e2-a0df-e727922bd3aa\backup_stage3_checkout_blank_screen_fix"
Copy-Item "$bak\*" "C:\Project\Plasvora_app\" -Recurse -Force
```



---

## 47. Backup UI/UX Refinement & Navigation Restructuring (Full Profile Tab, Activity Relocation, SimplePageAppBar, Checkout/Orders Polish)

**Tanggal**: 22 November 2026  
**Fitur**: Plasvora UI/UX Refinement & Navigation Restructuring (Stage 3 Polish + Global Layout Consistency)  
**Tujuan**:
1. Memperkenalkan `SimplePageAppBar` (`lib/core/widgets/simple_page_app_bar.dart`) untuk halaman internal (`CheckoutScreen`, `OrderListScreen`, `OrderDetailScreen`, `ActivityScreen`, `AddressListScreen`, `AddressFormScreen`, `EditProfileScreen`) dan heading tab root `Profil`, sambil mempertahankan `PlasvoraHeader` khusus pada tab utama (`Beranda`, `Analisis`, `Marketplace`).
2. Merestrukturisasi 4 tab navigasi bawah (`AppBottomNav` & `MainNavigationScreen`) menjadi `Beranda | Analisis | Marketplace | Profil` dengan menambahkan `ProfileScreen` (`lib/views/profile/profile_screen.dart`), memigrasikan pengaturan nomor telepon & privasi WhatsApp dari modal lama `_ProfileAccountSheet` ke `EditProfileScreen` (`lib/views/profile/edit_profile_screen.dart`), merelokasi `ActivityScreen` ke dalam `Profil -> Aktivitas`, serta mengarahkan ketukan avatar header pada tab utama ke tab `Profil` (jika authenticated) atau `LoginScreen` (jika guest).
3. Memperkenalkan helper presentasi murni `DisplayFormatters` (`lib/core/utils/display_formatters.dart`) untuk deduplikasi label lokasi berurutan, lokalisasi estimasi ETD ke Bahasa Indonesia, ringkasan nama kurir untuk tampilan UI, dan pemformatan tanggal tanpa mengubah payload backend.
4. Menyempurnakan `CheckoutScreen` (top-3 opsi kurir awal dengan badge objektif `Termurah` / `Estimasi Lebih Cepat` + toggle `Lihat Opsi Lain` yang mempertahankan kurir terpilih, menghapus `Biaya Platform: Rp 0` hardcoded, sticky SafeArea bottom bar `Bayar Rp ...` dengan finite `minimumSize` anti-crash `AppTheme`), `OrderDetailScreen` (single-line nomor pesanan + tombol salin nilai penuh, panel Next Step / Primary Action tepat di bawah header, `Ringkasan Material`, pengelompokan Pengiriman & Alamat Tujuan dengan privasi penjual, `Biaya Platform` hanya tampil bila `> 0`, `Riwayat Status Pesanan` terlipat secara default), serta `OrderListScreen` (5 filter status utama `Semua`, `Belum Bayar`, `Diproses`, `Dikirim`, `Selesai`, kartu pesanan ringkas bebas PII).
5. Memperbarui suite widget tests terkait (`test/profile_logout_security_test.dart`, `test/stage1_marketplace_foundation_test.dart`, `test/checkout_screen_test.dart`, `test/order_list_screen_test.dart`, `test/order_detail_screen_test.dart`) serta menambahkan `test/profile_navigation_refinement_test.dart`.
6. Tidak ada perubahan pada backend Laravel, `.env`, migrasi database, repository, ViewModel data bisnis, maupun dependensi paket.

Direktori Backup Fisik:
`C:\Users\PPLG\.gemini\antigravity\brain\d907174e-f225-41e2-a0df-e727922bd3aa\backup_ui_ux_refinement_nav_restructure_fe\`

### File Eksisting yang Di-backup & Dimodifikasi (17 file):
1. `lib/core/widgets/app_bottom_nav.dart`
2. `lib/viewmodels/navigation_viewmodel.dart`
3. `lib/views/main_navigation_screen.dart`
4. `lib/views/activity/activity_screen.dart`
5. `lib/views/address/address_list_screen.dart`
6. `lib/views/address/address_form_screen.dart`
7. `lib/views/analysis/analysis_screen.dart`
8. `lib/views/home/home_screen.dart`
9. `lib/views/marketplace/marketplace_screen.dart`
10. `lib/views/checkout/checkout_screen.dart`
11. `lib/views/orders/order_list_screen.dart`
12. `lib/views/orders/order_detail_screen.dart`
13. `test/profile_logout_security_test.dart`
14. `test/stage1_marketplace_foundation_test.dart`
15. `test/checkout_screen_test.dart`
16. `test/order_list_screen_test.dart`
17. `test/order_detail_screen_test.dart`

### File Baru Ditambahkan (5 file):
1. `lib/core/widgets/simple_page_app_bar.dart`
2. `lib/core/utils/display_formatters.dart`
3. `lib/views/profile/edit_profile_screen.dart`
4. `lib/views/profile/profile_screen.dart`
5. `test/profile_navigation_refinement_test.dart`

### Langkah Pemulihan (Non-Git):
```powershell
$bak = "C:\Users\PPLG\.gemini\antigravity\brain\d907174e-f225-41e2-a0df-e727922bd3aa\backup_ui_ux_refinement_nav_restructure_fe"
Copy-Item "$bak\*" "C:\Project\Plasvora_app\" -Recurse -Force
```



---

## 48. Backup Targeted UI Refinement — Checkout Sticky Bottom Payment Bar (`checkout_screen.dart` & `checkout_screen_test.dart`)

**Tanggal**: 23 November 2026  
**Fitur**: Stage 3 — Targeted UI Refinement (Checkout Sticky Bottom Payment Bar)  
**Tujuan**:
1. Menyempurnakan keseimbangan visual Sticky Bottom Payment Bar pada `lib/views/checkout/checkout_screen.dart`:
   - Area kiri menampilkan label `Total Pembayaran` (`AppColors.onSurfaceVariant`) dan nominal besar tegas (`AppTypography.headlineMd`, `AppColors.primaryContainer`, `FontWeight.w800`) hanya satu kali tanpa pengulangan di tombol.
   - Area kanan menggunakan label tombol `Bayar Sekarang` dengan tinggi 52 px, `BorderRadius.circular(16)` (menggantikan bentuk kapsul `StadiumBorder`), warna primary Plasvora (`AppColors.primaryContainer`), teks putih semibold terpusat (`FontWeight.w600`), serta lebar proporsional (`minimumSize: const Size(152, 52)` + `maxWidth: constraints.maxWidth * 0.58`).
   - Mempertahankan `Row(crossAxisAlignment: CrossAxisAlignment.center)` dengan jarak 16 px, `LayoutBuilder` adaptif (bertumpuk vertikal secara otomatis bila lebar sangat sempit `< 310` atau skala font sangat besar `>= 1.45` di `< 360`), `DecoratedBox` dengan top border halus, `SafeArea(top: false)`, dan padding ringkas `16 x 12 px`.
   - Seluruh logika finansial, validasi enabled/disabled, state loading, pencegahan double-tap, dan idempotency key tidak diubah.
2. Memperbarui assertion label tombol pada `test/checkout_screen_test.dart` agar selaras dengan label baru `Bayar Sekarang` dan label `Total Pembayaran`.

Direktori Backup Fisik:
`C:\Users\PPLG\.gemini\antigravity\brain\d907174e-f225-41e2-a0df-e727922bd3aa\backup_checkout_sticky_payment_bar_fe\`

### File Eksisting yang Di-backup & Dimodifikasi (2 file):
1. `lib/views/checkout/checkout_screen.dart`
2. `test/checkout_screen_test.dart`

### Langkah Pemulihan (Non-Git):
```powershell
$bak = "C:\Users\PPLG\.gemini\antigravity\brain\d907174e-f225-41e2-a0df-e727922bd3aa\backup_checkout_sticky_payment_bar_fe"
Copy-Item "$bak\*" "C:\Project\Plasvora_app\" -Recurse -Force
```


---

## 49. Backup Fitur Galeri Karya ("Galeri Karya" — End-to-End Flutter)

**Tanggal**: 23 November 2026  
**Tujuan**:
1. Menambahkan fondasi fitur Galeri Karya: `VideoLinkValidator`, endpoint galeri di `ApiConfig`, metode multipart aditif `ApiClient.postMultipartForm()`, model `GalleryWork` & `GalleryWorkDraft`, `GalleryRepository` (`ApiGalleryRepository` & `MockGalleryRepository`), serta `GalleryViewModel` dengan pagination, optimistic like + rollback, stale-response guard, dan `clearUserData()`.
2. Memperluas navigasi utama menjadi 5 tab (`Beranda | Analisis | Marketplace | Galeri | Profil`) pada `NavigationViewModel`, `AppBottomNav`, `MainNavigationScreen`, dan `main.dart` dengan isolasi sesi pada `onSessionCleared`.
3. Membangun 4 layar Galeri Karya (`GalleryScreen`, `GalleryDetailScreen`, `CreateGalleryWorkScreen`, `MyGalleryWorksScreen`) beserta komponen bersama `gallery_widgets.dart`.
4. Mengintegrasikan menu `Karya Saya` dan pembersihan cache pada `ProfileScreen`, serta tombol `Bagikan ke Galeri` (dengan prefill `GalleryWorkDraft` tanpa foto) pada `AnalysisResultScreen` (diteruskan dari `AnalysisScreen` dan `ActivityScreen`).
5. Memperbarui indeks tab Profil pada test eksisting (`profile_logout_security_test.dart`, `profile_navigation_refinement_test.dart`) dan menambahkan suite pengujian komprehensif `test/gallery_feature_test.dart`.

Direktori Backup Fisik:
`C:\Users\PPLG\.gemini\antigravity\brain\d907174e-f225-41e2-a0df-e727922bd3aa\backup_gallery_feature_fe\`

### File Eksisting yang Di-backup & Dimodifikasi:
1. `lib/core/network/api_config.dart`
2. `lib/core/network/api_client.dart`
3. `lib/viewmodels/navigation_viewmodel.dart`
4. `lib/core/widgets/app_bottom_nav.dart`
5. `lib/views/main_navigation_screen.dart`
6. `lib/main.dart`
7. `lib/views/profile/profile_screen.dart`
8. `lib/views/analysis/analysis_screen.dart`
9. `lib/views/activity/activity_screen.dart`
10. `lib/views/analysis/analysis_result_screen.dart`
11. `test/profile_logout_security_test.dart`
12. `test/profile_navigation_refinement_test.dart`

### File Baru yang Dibuat:
1. `lib/core/utils/video_link_validator.dart`
2. `lib/models/gallery_work.dart`
3. `lib/repositories/gallery_repository.dart`
4. `lib/viewmodels/gallery_viewmodel.dart`
5. `lib/views/gallery/gallery_widgets.dart`
6. `lib/views/gallery/gallery_screen.dart`
7. `lib/views/gallery/gallery_detail_screen.dart`
8. `lib/views/gallery/create_gallery_work_screen.dart`
9. `lib/views/gallery/my_gallery_works_screen.dart`
10. `test/gallery_feature_test.dart`

### Langkah Pemulihan (Non-Git):
```powershell
$bak = "C:\Users\PPLG\.gemini\antigravity\brain\d907174e-f225-41e2-a0df-e727922bd3aa\backup_gallery_feature_fe"
Copy-Item "$bak\*" "C:\Project\Plasvora_app\" -Recurse -Force
```


---

## 50. Backup Targeted Fix — Gallery Feature Test Compilation Errors

**Tanggal**: 23 November 2026  
**Tujuan**:
1. Memperbaiki dua error kompilasi pada `test/gallery_feature_test.dart` (`onToggleLike` dan `onFetchMyWorks` yang keliru terikat pada `GalleryPage` akibat presedensi operator cascade `..` terhadap arrow function `=>`).
2. Mengonversi `_ControllableGalleryRepository` agar menerima callback melalui named constructor parameters (`final`) sehingga seluruh skenario fake repository (toggle like rollback, stale `fetchMyWorks`, pagination, stale search) eksplisit dan aman dari ambiguitas presedensi cascade.
3. Mempersempit finder chip filter (`ChoiceChip`) pada test `GalleryScreen` agar tidak bertabrakan dengan badge tingkat kesulitan pada kartu.

Direktori Backup Fisik:
`C:\Users\PPLG\.gemini\antigravity\brain\d907174e-f225-41e2-a0df-e727922bd3aa\backup_gallery_test_fix_fe\`

### File Eksisting yang Di-backup & Dimodifikasi (1 file):
1. `test/gallery_feature_test.dart`

### Langkah Pemulihan (Non-Git):
```powershell
$bak = "C:\Users\PPLG\.gemini\antigravity\brain\d907174e-f225-41e2-a0df-e727922bd3aa\backup_gallery_test_fix_fe"
Copy-Item "$bak\*" "C:\Project\Plasvora_app\" -Recurse -Force
```


---

## 51. Backup Gallery Regression Fix — Responsive HomeScreen & Duplicate FAB Hero Tags

**Tanggal**: 23 November 2026  
**Tujuan**:
1. Memperbaiki RenderFlex overflow pada `lib/views/home/home_screen.dart` pada viewport `360dp` dengan skala teks `1.3x`:
   - Header `Pasar Terkini` (overflow 23px): membungkus kolom judul/subjudul dengan `Expanded` + jarak aman `12px` terhadap aksi `Lihat semua`.
   - Grid & kartu `Pasar Terkini` (overflow 31px & 35px pada `maxWidth: 80.7`): mengubah tata letak 3 kartu sejajar menjadi grid responsif berbasis `LayoutBuilder` (2 kolom pada lebar `< 460dp`, 3 kolom pada layar lebar) dan melindungi baris harga + ikon di `_buildListingCard` dengan `Expanded` + `FittedBox(fit: BoxFit.scaleDown)` agar harga tidak pernah overflow maupun terpotong.
   - Proteksi preventif pada header/baris terkait di `HomeScreen` (`_buildPrimaryScanCard`, `_buildQuickActions` + `_buildActionTile`, `_buildImpactSummary`, metadata berat kartu) agar aman pada skala teks besar.
2. Menghilangkan kolisi Hero tag `<default FloatingActionButton tag>` antar tab yang aktif bersamaan dalam `IndexedStack` di `MainNavigationScreen` dengan menetapkan `heroTag: null` secara eksplisit pada seluruh FAB tab root (`GalleryScreen` dan `MarketplaceScreen`).
3. Memperbaiki dua isu uji tambahan yang ditemukan lewat inspeksi source code pada `test/gallery_feature_test.dart`: decoding byte multipart biner dengan `latin1.decode(request.bodyBytes)` alih-alih `request.body` (UTF-8 ketat), serta `ensureVisible` + menunggu `SnackBar` validasi selesai sebelum mengetuk tombol submit pada test `CreateGalleryWorkScreen`.

Direktori Backup Fisik:
`C:\Users\PPLG\.gemini\antigravity\brain\d907174e-f225-41e2-a0df-e727922bd3aa\backup_gallery_regression_fix_fe\`

### File Eksisting yang Di-backup & Dimodifikasi (4 file):
1. `lib/views/home/home_screen.dart`
2. `lib/views/marketplace/marketplace_screen.dart`
3. `lib/views/gallery/gallery_screen.dart`
4. `test/gallery_feature_test.dart`

### Langkah Pemulihan (Non-Git):
```powershell
$bak = "C:\Users\PPLG\.gemini\antigravity\brain\d907174e-f225-41e2-a0df-e727922bd3aa\backup_gallery_regression_fix_fe"
Copy-Item "$bak\*" "C:\Project\Plasvora_app\" -Recurse -Force
```



---

## 52. Backup Perbaikan Alur Publikasi Langsung Galeri Karya (Keep Ownership Declaration, Posting CTA, Badge Tayang & Feed Refresh — Frontend)

**Tanggal**: 23 November 2026  
**Tujuan**:
1. Mempertahankan checkbox pernyataan kepemilikan (`Saya menyatakan bahwa karya dan foto ini adalah milik saya sendiri serta aman dibagikan ke komunitas Plasvora.`) sebagai syarat wajib submit pada `CreateGalleryWorkScreen`, sambil menghapus seluruh teks moderasi/verifikasi admin (termasuk banner verifikasi ulang pada mode edit).
2. Mengubah tombol aksi utama pembuatan karya menjadi `Posting` yang nonaktif sampai seluruh field wajib dan pernyataan kepemilikan valid, dilengkapi indikator loading anti-double-submit, pesan SnackBar `Karya berhasil diposting dan sekarang tampil di Galeri!`, serta penyegaran otomatis feed publik `GalleryViewModel` tanpa panggilan API ganda.
3. Mengubah label status tayang `GalleryWorkStatus.approved` menjadi `Tayang` dan memastikan `MyGalleryWorksScreen` menampilkan badge berdasarkan status tersimpan dari backend (bukan hardcoded dan tidak fallback ke `pending`).
4. Menyelaraskan `MockGalleryRepository`, `GalleryViewModel` (create/update sync), `GalleryDetailScreen` (copy status tayang & like guard), serta memperbarui dan menambah skenario pengujian di `test/gallery_feature_test.dart`.

Direktori Backup Fisik:
`C:\Users\PPLG\.gemini\antigravity\brain\d907174e-f225-41e2-a0df-e727922bd3aa\backup_gallery_publication_flow_fe\`

### File Eksisting yang Di-backup & Dimodifikasi (7 file):
1. `lib/models/gallery_work.dart`
2. `lib/repositories/gallery_repository.dart`
3. `lib/viewmodels/gallery_viewmodel.dart`
4. `lib/views/gallery/create_gallery_work_screen.dart`
5. `lib/views/gallery/my_gallery_works_screen.dart`
6. `lib/views/gallery/gallery_detail_screen.dart`
7. `test/gallery_feature_test.dart`

### Langkah Pemulihan (Non-Git):
```powershell
$bak = "C:\Users\PPLG\.gemini\antigravity\brain\d907174e-f225-41e2-a0df-e727922bd3aa\backup_gallery_publication_flow_fe"
Copy-Item "$bak\*" "C:\Project\Plasvora_app\" -Recurse -Force
```
