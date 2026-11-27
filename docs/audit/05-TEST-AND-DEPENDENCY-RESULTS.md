# Plasvora — Test Execution, Static Analysis, Dependency & Git Audit Results

**Audit Date:** 2026-11-25  
**Execution Principle:** Every command below was strictly read-only / non-destructive. Zero production DB commands, zero dependency upgrades, and zero `.env` reads were performed. Blocked suites are reported explicitly without guessing pass/fail outcomes.

---

## 1. Static Analysis & Verification Summary

| Check | Repo | Command | Outcome | Exact Observations |
|---|---|---|---|---|
| **Flutter Static Analyzer** | FE | `flutter analyze` | **WARN (Exit 1)** | **0 errors in `lib/`**. 2 warnings in `test/gallery_feature_test.dart:95,99` (`unused_element_parameter` for `onFetchDetail` and `onDeleteWork`). |
| **Flutter Unit & Widget Tests** | FE | `flutter test` | **FAIL (161 passed, 6 failed)** | 167 total tests across 21 test files; 6 failures concentrated in `gallery_feature_test.dart` (5) and `order_detail_screen_test.dart` (1). Full breakdown in Section 2. |
| **Laravel Route Registration** | BE | `php artisan route:list --path=api` | **PASS (Exit 0)** | All **48 API routes** resolved cleanly with valid controller/method bindings and middleware declarations. |
| **Composer Schema Validation** | BE | `composer validate --no-interaction` | **PASS (Exit 0)** | `./composer.json is valid`. |
| **Composer Security Audit** | BE | `composer audit --no-interaction` | **FAIL (Exit 1)** | **9 security vulnerability advisories affecting 6 locked packages** (details in Section 3). |
| **Flutter Outdated Check** | FE | `flutter pub outdated --no-color` | **INFO (Exit 0)** | 2 direct dependencies outdated (`flutter_secure_storage 9.2.4 -> 11.2.0`, `cupertino_icons 1.0.9 -> 2.0.0`); 2 transitive packages discontinued (`flutter_secure_storage_macos`, `js`). |
| **Laravel Unit Tests** | BE | `phpunit -c phpunit.xml tests/Unit` | **PARTIAL (17 passed, 5 errored)** | All **16 `MidtransServiceTest`** + **1 `ExampleTest`** passed (57 assertions). All **5 `OrderModelTest`** DB tests errored because local MySQL (`127.0.0.1:3306`) is stopped. |
| **Laravel Feature Tests (16 suites)** | BE | *Not executed (DB stopped)* | **BLOCKED** | All 16 Feature test files use `RefreshDatabase` targeting MySQL `127.0.0.1:3306` (`plasvora_testing`), which actively refused connection (`SQLSTATE[HY000] [2002]`). |

---

## 2. Detailed Breakdown of the 6 Failing Flutter Tests

| # | Test File & Case | Failure Type | Observed Error & Exact Root Cause |
|---|---|---|---|
| 1 | `test/gallery_feature_test.dart:857` — *GalleryScreen filters, sorts, and guards guest Bagikan Karya CTA* | Test / Viewport Clipping | `Expected: 1, Actual: 0` for `"Dompet Anyaman Kemasan Sachet Kopi"`. Second card sits below the default 800x600 widget-test viewport fold before scrolling. |
| 2 | `test/order_detail_screen_test.dart:360-362` — *OrderDetailScreen ... collapses history by default...* | Test / SnackBar Overlap | `tap()` on `"Riwayat Status Pesanan"` at `(389.8, 541.0)` missed hit-test (obscured by the floating `"Nomor pesanan disalin"` SnackBar triggered at line 335), so accordion stayed collapsed and `"Pesanan dibuat oleh pembeli"` was not rendered. |
| 3 | `test/gallery_feature_test.dart:1068` — *CreateGalleryWorkScreen enforces ownership declaration, uses Posting CTA, publishes immediately with Tayang badge* | **Real App Widget Bug (`BUG-06`)** | 8x `FlutterError: ListTile background color or ink splashes may be invisible. The ListTile is wrapped in a DecoratedBox that has a background color.` Caused by `CheckboxListTile` inside colored `Container` at `lib/views/gallery/create_gallery_work_screen.dart:1217-1252`. |
| 4 | `test/gallery_feature_test.dart:1165` — *CreateGalleryWorkScreen prevents duplicate submission during loading and surfaces API errors* | **Real App Widget Bug (`BUG-06`)** | Same 8x `ListTile`/`DecoratedBox` framework assertion at `create_gallery_work_screen.dart:1217-1252`. |
| 5 | `test/gallery_feature_test.dart:1254` — *MyGalleryWorksScreen shows Tayang for approved, preserves rejected badge, and supports Edit & Delete* | **Real App Lifecycle Bug (`BUG-07`)** | `FlutterError: setState() or markNeedsBuild() called during build` on `ListenableBuilder` when navigating to edit `CreateGalleryWorkScreen`. |
| 6 | `test/gallery_feature_test.dart:1332` — *AnalysisResultScreen Bagikan ke Galeri prefills CreateGalleryWorkScreen without photo* | **Real App Widget Bug (`BUG-06`)** | Same `ListTile`/`DecoratedBox` framework assertion when `CreateGalleryWorkScreen` renders. |

---

## 3. Dependency & Supply-Chain Security Audit

### Backend (`C:\xampp\htdocs\backend_plasvora\composer.lock`) — 9 Advisories Found

| Locked Package | Installed Version | CVE / Advisory ID | Severity (Advisory) | Summary | Patched Version |
|---|---|---|---|---|---|
| `laravel/framework` | `v12.70.1` | `CVE-2026-128083` (`PKSA-yxbx-3c9s-cjt9`) | Low | Task Output Injection — Concurrency Process | `>=12.71.0` |
| `symfony/http-foundation` | `v7.4.21` | `CVE-2026-121619` (`PKSA-nxjs-s6hn-vb6m`) | Unspecified (Med/High) | `private_ranges` trusted proxy shortcut trusts IPv4-mapped / 6to4 / Teredo / NAT64 addresses | `>=7.4.23` |
| `symfony/http-foundation` | `v7.4.21` | `CVE-2026-135802` (`PKSA-qgp8-6q73-5w6n`) | Unspecified (Med/High) | Generated URLs can point to a host chosen by the client | `>=7.4.23` |
| `symfony/http-foundation` | `v7.4.21` | `CVE-2026-135801` (`PKSA-mfk7-7n9q-vfyt`) | Unspecified (Med/High) | Path rules enforced in front of PHP bypassed by appending path to script name | `>=7.4.23` |
| `symfony/http-foundation` | `v7.4.21` | `CVE-2026-118514` (`PKSA-24ph-xkrh-y79j`) | Unspecified (Med) | `HEAD` requests bypass `methods` option of access-control rules | `>=7.4.23` |
| `symfony/http-kernel` | `v7.4.21` | `CVE-2026-123339` (`PKSA-3gxv-7xhq-mgmz`) | Unspecified (Med) | Inline fragments let untrusted forwarded headers set host/scheme/port | `>=7.4.23` |
| `symfony/mime` | `v7.4.19` | `CVE-2026-45070` (`PKSA-wtxr-p26d-nn42`) | Medium | Email header injection via non-token chars in MIME parameter names | `>=7.4.22` |
| `symfony/routing` | `v7.4.21` | `CVE-2026-118516` (`PKSA-y8c5-1b7f-r1gj`) | Unspecified (Med) | Host placeholders match start of path in compiled URL matchers | `>=7.4.23` |
| `symfony/yaml` | `v7.4.21` | `CVE-2026-123792` (`PKSA-nktx-f1n1-b4yd`) | Unspecified (Med) | Exponential/quadratic YAML parse DoS | `>=7.4.23` |

### Frontend (`C:\Project\Plasvora_app\pubspec.yaml` / `pubspec.lock`)
- **Direct dependencies requiring attention:**
  - `flutter_secure_storage`: `9.2.4` -> `11.2.0` available (current v9 pulls discontinued transitive `flutter_secure_storage_macos` and `js`).
  - `cupertino_icons`: `1.0.9` -> `2.0.0`.
- **Clean security dependency posture:** Zero unused ML SDKs, zero sketchy third-party payment WebView wrappers, zero hardcoded debug HTTP inspector packages.

---

## 4. Git Hygiene & Secret Exposure Audit

- **Frontend (`C:\Project\Plasvora_app`, branch `feature/gallery`):**
  - Tracked sensitive-pattern filenames: **only** `assets/certificates/isrgrootx1.pem` (public Let's Encrypt CA root certificate — safe).
  - Full Git history check for `*.env`, `*.key`, `*.jks`, `*.keystore`, `*.sql`: **CLEAN (0 matches)**.
  - Operational note: Root directory contains development docs (`BACKUP_MANIFEST.md`, `FULL_BUG_AUDIT_PLASVORA.md`, `Prompt_Antigravity_Plasvora.md`, `Prompt_Google_Stitch_Plasvora.md`) documenting internal workstation paths (`C:\Users\PPLG\...`) and AI development prompts. Move to a private archive or exclude from public release repositories if sensitive.
- **Backend (`C:\xampp\htdocs\backend_plasvora`, branch `feature/gallery`):**
  - `.env` is **properly gitignored and NEVER committed in Git history** (only `.env.example` is tracked).
  - **Findings:**
    1. `database/backup_plasvora_db.sql` is tracked in Git (outdated 6-table schema; uses safe demo placeholder `'GANTI_DENGAN_HASH_PASSWORD'`, no real user hashes, but should be removed and `*.sql` added to `.gitignore`).
    2. `BACKUP_MANIFEST.md` is tracked in Git (contains local workstation paths `C:\Users\PPLG\...`).

---

## 5. Test Coverage Gaps Identified

Even with 21 Flutter test files and 19 Laravel test files, critical regressions slipped through due to specific coverage gaps:
1. **Frontend Login/Register Error-State Integration (`BUG-01`):** Existing `auth_ui_test.dart` tests `LoginScreen` in isolation rather than mounted inside `PlasvoraApp`, missing that `AuthState.error` unmounts `LoginScreen` into a 403 screen.
2. **Cross-Project Analysis Dropdown Contract (`BUG-02`):** No contract test asserts that every dropdown value emitted by `AnalysisScreen` (`'1'`–`'7'`) belongs to `AnalysisController`'s accepted enum (`PET`, `HDPE`, `PP`, `LDPE`, `OTHER`, `MIXED`).
3. **Full Multi-Account Logout Isolation (`SEC-FE-03`):** `profile_logout_security_test.dart` tests `AddressViewModel` and `OrderViewModel` cleanup, but omits `ActivityViewModel`, `AnalysisViewModel`, `MatchingViewModel`, `ApiMaterialRepository._favoriteIds`, and in-flight mutation races.
4. **Backend Gemini Compression + Prompt Delimiter Tests (`AI-BUG-01`, `AI-SEC-01`):** No test feeds a real `>1200px` PNG into `GeminiVisionService` to assert that the outgoing `inlineData.mimeType` matches the JPEG-compressed payload bytes.
5. **Backend Matching BOLA, Self-Matching & Handover Weight Bounds (`SEC-BE-03`, `AI-MATCH-01`, `SEC-BE-06`):** No feature tests verify non-owner access to cancelled/inactive `/matches`, self-owned listing exclusion, or `actual_weight_kg > listing->weight_kg` rejection.
6. **CI MySQL Service for Backend Feature Suite:** Without MySQL running in local/CI test pipelines, all 16 Laravel Feature test suites (covering Auth, Orders, Midtrans Webhooks, Shipping, Handover, Gallery, Gemini Analysis, Impact Summary) cannot verify regressions.
