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



