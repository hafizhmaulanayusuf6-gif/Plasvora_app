# PLASVORA — Product Requirements Document (PRD)

**Versi:** 1.0  
**Jenis produk:** Prototype aplikasi mobile Android  
**Nama produk:** PLASVORA  
**Tagline:** *Turn Plastic Into Possibility.*  
**Tim:** 2 orang — Flutter frontend dan PHP/Laravel backend  
**Target:** Prototype lomba inovasi; fokus pada alur utama yang dapat didemonstrasikan, bukan produk produksi penuh.

---

## 1. Ringkasan Produk

PLASVORA adalah aplikasi mobile yang membantu pengguna menemukan potensi pemanfaatan sampah plastik dan menghubungkan pemilik material dengan pengrajin, sekolah, komunitas lingkungan, serta pelaku daur ulang yang membutuhkan bahan tersebut.

Aplikasi menggabungkan tiga pilar:

1. **Material-Aware Recommendations** — rekomendasi ide pemanfaatan berdasarkan informasi material.
2. **Idea-to-Market Matching** — pencocokan material yang tersedia dengan kebutuhan pengguna lain.
3. **Verified Material Journey** — pencatatan status material dari penawaran hingga konfirmasi penyerahan dan pemanfaatan.

Untuk prototype, analisis AI boleh menggunakan data demo atau aturan sederhana jika layanan AI sungguhan belum siap. Antarmuka harus menyatakan dengan jelas jika hasil merupakan simulasi. Jangan mengklaim data demo sebagai hasil AI atau dampak lingkungan nyata.

## 2. Masalah yang Ingin Ditangani

- Masyarakat belum tentu mengetahui cara memanfaatkan jenis plastik yang mereka miliki.
- Pengrajin dan komunitas mungkin kesulitan menemukan material yang sesuai dengan kebutuhannya.
- Pemilik plastik tidak selalu tahu siapa yang bersedia menerima atau mengolah material tersebut.
- Penawaran material belum tentu berakhir pada penyerahan atau pemanfaatan yang benar-benar terjadi.
- Statistik lingkungan perlu memisahkan material yang baru terdaftar dari material yang telah diserahkan dan dikonfirmasi pemanfaatannya.

Masalah ini merupakan dasar hipotesis produk dan dapat divalidasi lebih lanjut melalui uji coba pengguna.

## 3. Target Pengguna

### 3.1 Pemilik material
Mencatat, menawarkan, atau menyalurkan plastik yang dimiliki serta mencari ide pemanfaatan.

### 3.2 Pengrajin dan pelaku daur ulang
Mencari bahan baku, memublikasikan kebutuhan, mengajukan permintaan, dan mengonfirmasi penerimaan/pemanfaatan.

### 3.3 Sekolah dan komunitas lingkungan
Menemukan material untuk proyek dan mencatat kegiatan pemanfaatan plastik.

**Catatan MVP:** satu akun dapat menawarkan sekaligus mencari material. Hindari pemisahan role yang rumit pada tahap awal.

## 4. Tiga Pilar Inovasi

### 4.1 Material-Aware Recommendations
Pengguna memilih/mengunggah foto plastik dan melengkapi data seperti kategori bila diketahui, berat, kondisi, serta deskripsi. Aplikasi menampilkan perkiraan kategori dan ide pemanfaatan yang sesuai, termasuk tingkat kesulitan, alat/bahan, langkah ringkas, dan catatan keselamatan.

Identifikasi berdasarkan gambar adalah perkiraan, bukan kepastian jenis resin atau keamanan material. Jangan menyarankan pembakaran atau pemanasan plastik yang tidak teridentifikasi.

### 4.2 Idea-to-Market Matching
Pengguna dapat beralih dari hasil rekomendasi ke marketplace. Pencocokan mempertimbangkan kategori material, berat/jumlah, kondisi, dan lokasi umum jika datanya tersedia. Untuk MVP, matching menggunakan aturan yang sederhana dan transparan, bukan model machine learning khusus.

### 4.3 Verified Material Journey
Status minimum: `listed`, `requested`, `approved`, `handed_over`, `utilization_confirmed`, `rejected`, `cancelled`. Statistik dashboard menggunakan status dan berat aktual yang dicatat. Jangan menghitung semua listing sebagai material yang berhasil dimanfaatkan.

## 5. Scope dan Prioritas MVP

### P0 — wajib untuk demo
1. **Home**: akses cepat ke analisis dan marketplace, ringkasan aktivitas, serta listing pilihan.
2. **Analyze Plastic**: input kategori/berat/kondisi/deskripsi dan pilih foto; hasil rekomendasi, dengan penanda bila menggunakan data demo.
3. **Upcycling Idea Detail**: bahan, alat, tingkat kesulitan, langkah ringkas dan catatan keselamatan.
4. **Marketplace**: katalog listing, search/filter sederhana, detail listing, dan form untuk menambahkan listing.
5. **Material Needs**: katalog kebutuhan pengrajin/komunitas dan form membuat kebutuhan.
6. **Smart Matching**: menampilkan kandidat material berdasarkan aturan jenis, jumlah, kondisi dan lokasi bila tersedia, disertai alasan kecocokan.
7. **Request and Status**: ajukan permintaan, lihat status, dan lakukan konfirmasi sesuai peran.
8. **Activity/Impact**: riwayat aktivitas serta angka listing, penyerahan, dan pemanfaatan yang dikonfirmasi dengan definisi terpisah.
9. **Profile**: profil demo sederhana dan listing/permintaan milik pengguna.

### P1 — bila waktu cukup
- Login/register terhubung backend.
- Favorit/simpan ide.
- Notifikasi sederhana di dalam aplikasi.
- Upload gambar ke API backend.

### Tidak termasuk MVP
- Pembayaran online, logistik/pengiriman otomatis, chat real-time, sistem poin, dashboard admin kompleks, GPS real-time, pengenalan semua jenis resin dengan computer vision khusus, dan layanan AI mahal.

## 6. Alur Demo Utama

1. Pengguna memasukkan informasi 5 kg tutup botol plastik.
2. Aplikasi menampilkan rekomendasi pemanfaatan (hasil demo harus diberi label jika bukan keluaran AI langsung).
3. Pengguna membuka marketplace atau pencocokan kebutuhan.
4. Aplikasi merekomendasikan komunitas/pengrajin yang membutuhkan tutup botol.
5. Pengguna mengajukan penyerahan; pemilik atau penerima yang sesuai memperbarui status.
6. Setelah penyerahan dan pemanfaatan dikonfirmasi, status muncul di riwayat dan dashboard.

## 7. Teknologi dan Pembagian Tanggung Jawab

### Mobile frontend — dikerjakan oleh anggota 1
- **Flutter + Dart** untuk aplikasi mobile Android.
- **MVVM** dengan `ChangeNotifier`/`Provider` jika sudah tersedia atau jika diperlukan; jangan menambah dependency tanpa alasan yang jelas.
- `http` atau klien HTTP ringan untuk mengonsumsi REST API.
- `image_picker` hanya jika diperlukan untuk memilih foto; tambahkan dependency setelah memeriksa kebutuhan dan kompatibilitasnya.
- Repository interface memungkinkan UI berjalan memakai data demo sementara backend dibuat.

### Backend — dikerjakan oleh anggota 2
- **PHP + Laravel** untuk REST API.
- **MySQL** sebagai relational database.
- Validasi input, aturan bisnis, akses data, dan status transaksi berada di backend.
- Backend mengembalikan JSON dengan format konsisten.

### AI
- MVP boleh memakai repository data demo atau rule-based recommendations.
- Jika layanan AI sungguhan ditambahkan nanti, panggil melalui backend atau server tepercaya. Jangan menanamkan secret API key di kode Flutter.

### Penyimpanan gambar
- MVP boleh memakai gambar placeholder/aset lokal.
- Untuk integrasi selanjutnya, backend dapat menyediakan upload endpoint dan menyimpan file sesuai kemampuan server. Jangan memaksa integrasi cloud storage jika belum diperlukan.

### Pembagian kerja
- Frontend owner bertanggung jawab atas `lib/`, navigasi, state, view, view model, model UI, dan integrasi API.
- Backend owner bertanggung jawab atas proyek Laravel, migrations, models, controllers, validation, endpoints, dan MySQL.
- Keduanya menyepakati endpoint dan format JSON melalui `docs/api_contract.md` sebelum integrasi. Jangan mengubah kontrak API sepihak.

## 8. Arsitektur Frontend: MVVM Praktis

- **View**: layar/widget Flutter; menampilkan state dan meneruskan tindakan pengguna.
- **ViewModel**: mengelola state layar, validasi ringan, loading/error/success, dan memanggil repository. Tidak berisi widget UI atau SQL.
- **Model**: representasi data seperti `MaterialListing`, `MaterialRequest`, `AnalysisResult`, `Handover`, dan `UserProfile`.
- **Repository**: abstraksi sumber data; dapat berpindah dari mock repository ke API repository tanpa mengubah View.
- **Service**: `ApiClient` untuk HTTP, serialisasi JSON, base URL, dan penanganan error.

Gunakan MVVM yang sederhana. Tidak perlu memaksakan Clean Architecture penuh pada prototype singkat. Hindari logika bisnis menumpuk di `build()` atau seluruh aplikasi dimasukkan ke `main.dart`.

## 9. Struktur Folder Flutter yang Disarankan

Pertahankan root Flutter yang saat ini sudah dibuat (`plasvora/`); jangan memindah semua file platform Flutter ke subfolder tanpa kebutuhan.

```text
plasvora/
├── android/
├── ios/
├── web/
├── test/
├── docs/
│   ├── Plasvora_PRD.md
│   ├── design.md
│   └── api_contract.md
├── assets/
│   ├── images/
│   └── icons/
├── lib/
│   ├── main.dart
│   ├── app.dart
│   ├── core/
│   │   ├── config/
│   │   │   └── app_config.dart
│   │   ├── theme/
│   │   │   ├── app_colors.dart
│   │   │   ├── app_theme.dart
│   │   │   └── app_text_styles.dart
│   │   ├── networking/
│   │   │   ├── api_client.dart
│   │   │   └── api_exception.dart
│   │   ├── routing/
│   │   │   └── app_router.dart
│   │   └── utils/
│   ├── data/
│   │   ├── models/
│   │   ├── repositories/
│   │   │   ├── material_repository.dart
│   │   │   ├── request_repository.dart
│   │   │   └── activity_repository.dart
│   │   └── services/
│   │       └── mock_data_service.dart
│   ├── features/
│   │   ├── home/
│   │   │   ├── views/
│   │   │   ├── viewmodels/
│   │   │   └── widgets/
│   │   ├── analysis/
│   │   │   ├── views/
│   │   │   ├── viewmodels/
│   │   │   └── widgets/
│   │   ├── marketplace/
│   │   │   ├── views/
│   │   │   ├── viewmodels/
│   │   │   └── widgets/
│   │   ├── material_requests/
│   │   │   ├── views/
│   │   │   ├── viewmodels/
│   │   │   └── widgets/
│   │   ├── activity/
│   │   │   ├── views/
│   │   │   └── viewmodels/
│   │   └── profile/
│   │       ├── views/
│   │       └── viewmodels/
│   └── shared/
│       ├── widgets/
│       └── enums/
├── pubspec.yaml
└── README.md
```

Folder boleh disederhanakan jika jumlah file kecil. Jangan membuat banyak file abstrak yang tidak digunakan.

Backend Laravel sebaiknya berada di workspace/folder terpisah milik anggota backend, atau direktori `/backend` jika tim benar-benar memakai satu repository. Jangan letakkan kode PHP di dalam `lib/` Flutter.

## 10. Kontrak Integrasi API Awal

Seluruh endpoint menggunakan prefix `/api`. Nama final harus disepakati tim di `docs/api_contract.md`.

- `GET /api/materials` — daftar material; mendukung query search/filter bila siap.
- `GET /api/materials/{id}` — detail listing.
- `POST /api/materials` — membuat listing.
- `GET /api/material-requests` — daftar kebutuhan material.
- `POST /api/material-requests` — membuat kebutuhan.
- `POST /api/handover-requests` — membuat permintaan terhadap listing.
- `PATCH /api/handover-requests/{id}/status` — memperbarui status oleh pihak berwenang.
- `GET /api/activities` — riwayat aktivitas pengguna.
- `POST /api/analyses` — menyimpan riwayat analisis, jika dibutuhkan.

Contoh response sukses:

```json
{
  "success": true,
  "message": "Materials retrieved successfully",
  "data": []
}
```

Contoh error:

```json
{
  "success": false,
  "message": "Validation failed",
  "errors": {
    "weight_kg": ["The weight field is required."]
  }
}
```

Response nyata boleh menyesuaikan konvensi Laravel, tetapi harus konsisten. API client di Flutter harus punya satu konfigurasi base URL. Untuk Android emulator, `localhost` biasanya bukan komputer host; tentukan base URL sesuai emulator atau perangkat fisik, jangan hardcode alamat yang tidak valid.

## 11. Pedoman UI/UX

- Platform mobile-first, target Android.
- Bahasa UI utama: Bahasa Indonesia; nama merek dan tagline boleh berbahasa Inggris.
- Referensi visual utama: mockup pertama — hijau sage/forest, latar ivory, whitespace luas, rounded cards, shadow halus, foto alam/material yang besar, dan tipografi modern dengan kesan editorial.
- Referensi marketplace: screenshot kedua — search bar di atas, filter chips, grid dua kolom, gambar material, harga, berat, kondisi, lokasi, dan status ketersediaan yang mudah dipindai.
- Jangan menyalin brand, harga, badge promosi, atau identitas marketplace dari screenshot. Gunakan pola layout yang relevan untuk material daur ulang.
- Navigasi bawah: Home, Analyze, Marketplace, Activity. Profile dapat dibuka dari avatar atau halaman Activity; sederhanakan bila diperlukan.
- Semua layar memiliki loading, error, dan empty states yang layak.

Warna dasar yang direkomendasikan:
- Forest green `#205B46`
- Deep green `#153D32`
- Sage `#E8EFE5`
- Ivory `#F8F8F2`
- Card white `#FFFFFF`
- Main text `#20312A`
- Secondary text `#65746B`
- Accent mint `#C7E2C8`
- Warning `#D99A35`

Gunakan token warna terpusat di theme, hindari menulis warna acak di tiap widget.

## 12. Kualitas Kode dan Verifikasi

Wajib:
1. Pisahkan View, ViewModel, Model, Repository, dan Service sesuai MVVM.
2. UI tidak melakukan HTTP secara langsung; panggil ViewModel/Repository.
3. Tampilkan loading, empty state, dan error state bila relevan.
4. Beri komentar singkat pada logika krusial, bukan komentar untuk setiap baris.
5. Hindari perubahan besar terhadap struktur yang sudah ada sebelum memeriksa workspace.
6. Jangan menambah dependency tanpa menjelaskan kegunaannya.
7. Setelah implementasi, jalankan dari root Flutter:

```bash
dart format .
flutter pub get
flutter analyze
flutter test
```

`flutter test` dijalankan bila folder test dan tes tersedia; bila belum tersedia, tulis keterbatasannya dan minimal tambahkan tes untuk logika matching yang penting jika waktu memungkinkan. Perbaiki semua error analyzer. Jangan mengklaim perintah lulus jika belum benar-benar dijalankan.

## 13. Kriteria Selesai (Acceptance Criteria)

- Aplikasi terbuka dengan identitas PLASVORA dan navigasi utama yang konsisten.
- Pengguna bisa memasukkan informasi material dan melihat hasil/rekomendasi.
- Katalog material dan detail listing dapat dibuka.
- Pengguna bisa membuat listing dan kebutuhan melalui validasi form.
- Smart matching menghasilkan kandidat berdasarkan kriteria yang dijelaskan.
- Pengajuan dan status penyerahan tercermin konsisten pada detail, riwayat, dan statistik.
- Jika data masih mock, UI/README menyebutnya sebagai demo.
- `dart format .` dan `flutter analyze` dijalankan; tidak ada error yang belum dijelaskan.
- Integrasi backend menggunakan kontrak API yang disepakati kedua anggota.

## 14. Batasan dan Risiko

- Jangan mengklaim identifikasi foto sebagai kepastian jenis plastik.
- Jangan menghitung berat listed sebagai dampak yang telah terbukti.
- Jangan menaruh API secret di aplikasi mobile.
- Jangan membuka alamat rumah atau nomor telepon secara publik.
- Jangan membangun fitur pembayaran/logistik sebelum MVP selesai.
- Karena tim terdiri dari dua orang, integrasi backend perlu kontrak endpoint yang disepakati dan data demo agar frontend tetap dapat berjalan selama backend dalam pengerjaan.
