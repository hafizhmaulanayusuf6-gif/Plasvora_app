# Plasvora — Comprehensive Security Findings

**Scope:** Confirmed security vulnerabilities and separate `needs_validation` items across `C:\Project\Plasvora_app` (`FE`) and `C:\xampp\htdocs\backend_plasvora` (`BE`).  
**Methodology:** Source-first, evidence-backed audit. Every confirmed finding specifies a concrete trust boundary, affected principal/resource, exact `file:line` evidence, preconditions, realistic impact, safe verification, smallest effective fix, and regression test. Defense-in-depth items, unverified runtime behaviors, and functional bugs are strictly separated and never inflated into higher severities.

---

## 1. Summary Table of Confirmed Security Vulnerabilities

| ID | Severity | Confidence | Category | Repo | File:Line | Summary |
|---|---|---|---|---|---|---|
| `SEC-FE-01` | **HIGH** | Confirmed | Transport Security / MITM | FE | `android/app/src/main/AndroidManifest.xml:6`, `lib/core/network/api_config.dart:5-8` | Global `usesCleartextTraffic="true"` in release manifest + cleartext HTTP default API URL |
| `SEC-FE-02` | **HIGH** | Confirmed | Release Build & Signing | FE | `android/app/build.gradle.kts:8,19,32-38` | Release APK signed with Android debug keystore + placeholder `com.example.plasvora` App ID |
| `SEC-FE-03` | **HIGH** | Confirmed | Session Isolation / Data Leakage | FE | `lib/main.dart:89-93`, `profile_screen.dart:102-104`, `address_viewmodel.dart:128-295`, `gallery_viewmodel.dart:84,321-506` | Incomplete logout state wipe across 7+ stateful components + in-flight async logout races |
| `SEC-BE-08` | **HIGH** | Confirmed | Vulnerable Dependencies (CVE) | BE | `composer.lock` (6 packages, 9 advisories) | Unpatched `laravel/framework` and `symfony/*` packages with 9 published security advisories |
| `SEC-BE-01` | **MEDIUM** | Confirmed | Session / Token Management | BE | `config/sanctum.php:53`, `app/Http/Controllers/Api/AuthController.php:104` | Sanctum personal access tokens never expire and accumulate indefinitely |
| `SEC-BE-02` | **MEDIUM** | Confirmed | Rate Limiting / Resource Exhaustion | BE | `routes/api.php:42-51,79-116,133-149` | Missing rate limiting on mutating CRUD, handover, matching, activity, and 10-query public impact endpoints |
| `SEC-BE-03` | **MEDIUM** | Confirmed | Broken Object Level Authorization (BOLA) | BE | `app/Http/Controllers/Api/MatchingController.php:23-96` | Any authenticated user can query matches for any other user's inactive/cancelled/completed records |
| `SEC-BE-04` | **MEDIUM** | Confirmed | Broken File Access Control & Leak | BE | `app/Http/Controllers/Api/AnalysisController.php:116,175-184`, `app/Models/AnalysisHistory.php:46` | Private user analysis photos stored on unauthenticated `public` disk + orphan leak on Gemini failure |
| `SEC-BE-05` | **MEDIUM** | Confirmed | Prompt Injection & Error Disclosure | BE | `app/Services/GeminiVisionService.php:132-134,336`, `AnalysisController.php:182` | Unsanitized user `notes` interpolated into Gemini prompt + raw upstream 400 error echoed to client |
| `SEC-BE-06` | **MEDIUM** | Confirmed | Business Integrity / Input Validation | BE | `app/Http/Requests/UpdateHandoverStatusRequest.php:24-25`, `HandoverRequestController.php:258,265` | Unbounded `agreed_weight_kg` / `actual_weight_kg` allows arbitrary inflation of public impact metrics |
| `SEC-BE-07` | **MEDIUM** | Confirmed | Race Condition (TOCTOU) | BE | `app/Http/Controllers/Api/GalleryWorkController.php:223-298` | Gallery image count (`min 1`, `max 5`) validated before acquiring `lockForUpdate()` |
| `SEC-FE-04` | **MEDIUM** | Confirmed | Auth Lifecycle / Revocation | FE | `lib/core/network/api_client.dart:477-513` | No global HTTP 401 session-revocation handler during active sessions |
| `SEC-FE-05` | **MEDIUM** | Confirmed | Mobile Data Exposure | FE | `android/app/src/main/AndroidManifest.xml:5-9` | Android Auto Backup enabled by default (`android:allowBackup="false"` omitted) |
| `SEC-FE-06` | **LOW** | Confirmed | Token Migration Trust Boundary | FE | `lib/core/network/api_client.dart:94-113,178-188` | Legacy `.plasvora_auth_token` migration falls back to `Directory.systemTemp` |
| `SEC-FE-07` | **LOW** | Confirmed | Information / Header Leakage | FE | `lib/core/network/api_client.dart:271,339,391`, `gallery_widgets.dart:174` | `ngrok-skip-browser-warning: true` sent unconditionally, including to external image URLs |
| `SEC-BE-09` | **LOW** | Confirmed | Input Validation / External URL | BE | `StoreMaterialListingRequest.php:58`, `UpdateMaterialListingRequest.php:58` | Listing `image_url` allows arbitrary `http://` / non-HTTPS URLs (tracking pixel / mixed content) |
| `SEC-BE-10` | **LOW** | Confirmed | Privacy / Media Metadata | BE | `MaterialController.php:91,178`, `GalleryWorkController.php:161,287` | Uploaded user photos retain raw EXIF metadata (potential GPS coordinates on public disk) |
| `SEC-BE-11` | **LOW** | Confirmed | CORS Configuration | BE | `config/` (no `config/cors.php` published) | Relies on Laravel 12 default permissive CORS (`allowed_origins => ['*']`) |

---

## 2. Detailed Security Findings

### `SEC-FE-01` — Global Cleartext HTTP Allowed in Release Android Manifest & Default Base URL
- **Severity:** HIGH | **Confidence:** Confirmed | **Category:** Transport Security (MASVS-NETWORK-1)
- **Repository:** Frontend (`C:\Project\Plasvora_app`)
- **File & Line:** `android/app/src/main/AndroidManifest.xml:6`, `lib/core/network/api_config.dart:5-8`
- **Component:** Android Network Security & API Client Configuration
- **Evidence:**
  ```xml
  <!-- android/app/src/main/AndroidManifest.xml:5-6 -->
  <application
      android:usesCleartextTraffic="true"
  ```
  ```dart
  // lib/core/network/api_config.dart:5-8
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://127.0.0.1:8000/api',
  );
  ```
- **Technical Explanation:** Placing `android:usesCleartextTraffic="true"` in `src/main/AndroidManifest.xml` propagates cleartext permission into **release** APKs. Combined with a cleartext `defaultValue` and no `kReleaseMode` HTTPS assertion, any release build built without an HTTPS `--dart-define=API_BASE_URL` or loading HTTP URLs sends Sanctum Bearer tokens, passwords, addresses, and payment links in plaintext.
- **Preconditions:** Release build installed on Android; attacker on shared Wi-Fi / local network path (or misconfigured HTTP build flag).
- **Impact:** Credential/token theft, session hijacking, and PII interception on untrusted networks.
- **Safe Verification:** Inspect `android/app/src/main/AndroidManifest.xml:6` and `lib/core/network/api_config.dart:5-8`; verify absence of `android/app/src/main/res/xml/network_security_config.xml`.
- **Recommended Fix:** Set `android:usesCleartextTraffic="false"` in `src/main/AndroidManifest.xml`, move cleartext allowance strictly to `android/app/src/debug/AndroidManifest.xml` (or a debug-only `network_security_config.xml`), and enforce `https://` in `ApiConfig` when `kReleaseMode` is true.
- **Regression Test:** Add a unit test asserting `ApiConfig.validateReleaseBaseUrl('http://...')` throws in release mode and accepts `https://`.

---

### `SEC-FE-02` — Release Build Signed with Android Debug Keystore & Placeholder Application ID
- **Severity:** HIGH | **Confidence:** Confirmed | **Category:** Mobile Build & Code Signing Integrity
- **Repository:** Frontend (`C:\Project\Plasvora_app`)
- **File & Line:** `android/app/build.gradle.kts:8,19,32-38`
- **Component:** Android Gradle Release Pipeline
- **Evidence:**
  ```kotlin
  namespace = "com.example.plasvora"
  defaultConfig {
      applicationId = "com.example.plasvora"
      ...
  }
  buildTypes {
      release {
          signingConfig = signingConfigs.getByName("debug")
      }
  }
  ```
- **Technical Explanation:** Release artifacts are signed with the publicly known/developer debug keystore, use the placeholder `com.example.plasvora` package ID (rejected by Play Store and vulnerable to package collision), and omit `isMinifyEnabled = true` / `isShrinkResources = true`.
- **Preconditions:** Building a release APK/AAB using the current Gradle configuration.
- **Impact:** Anyone with the standard debug key or local build environment can sign tampered APKs matching the signature; Play Store distribution is blocked.
- **Safe Verification:** Read `android/app/build.gradle.kts:8-39`.
- **Recommended Fix:** Configure a dedicated release `signingConfigs` reading keystore path/passwords from environment variables or a gitignored `android/key.properties`, change `applicationId`/`namespace` to a domain-owned reverse-DNS ID (e.g., `id.plasvora.app`), and enable R8 minification/shrinking for release builds.
- **Regression Test:** Add a CI Gradle check failing release tasks when `signingConfig.name == "debug"` or `applicationId.startsWith("com.example.")`.

---

### `SEC-FE-03` — Cross-Account Session Data Leakage on Logout & In-Flight Async Races
- **Severity:** HIGH | **Confidence:** Confirmed | **Category:** Authentication / Multi-User Session Isolation
- **Repository:** Frontend (`C:\Project\Plasvora_app`)
- **File & Line:** `lib/main.dart:89-93`, `lib/views/profile/profile_screen.dart:102-104`, `lib/viewmodels/activity_viewmodel.dart:23-36`, `lib/views/activity/activity_screen.dart:20`, `lib/viewmodels/analysis_viewmodel.dart:14-43`, `lib/viewmodels/matching_viewmodel.dart:10-16,62-68`, `lib/repositories/material_repository.dart:86`, `lib/viewmodels/address_viewmodel.dart:128-295`, `lib/viewmodels/gallery_viewmodel.dart:84,321-506`
- **Component:** Root DI Session Coordinator & Long-Lived ViewModels
- **Evidence:**
  ```dart
  // lib/main.dart:89-93 (duplicated in lib/views/profile/profile_screen.dart:102-104)
  void _clearUserScopedState() {
    _addressViewModel.clearUserData();
    _orderViewModel.clearUserData();
    _galleryViewModel.clearUserData();
  }
  ```
  - Uncleared ViewModels/caches retaining User A's state after logout:
    1. `ActivityViewModel` (`_activities`, `_analyses`) — compounded by `ActivityScreen` (`activity_screen.dart:20`) never calling `loadAll()` on mount.
    2. `AnalysisViewModel` (`_imagePath`, `_notes`, `_polymerCategory`, `_analysisResult`).
    3. `MatchingViewModel` (implements `clear()` at `L62-68`, never invoked on logout).
    4. `ApiMaterialRepository._favoriteIds` (`material_repository.dart:86`).
    5. `MaterialRequestViewModel`, `MarketplaceViewModel`, `HomeViewModel`, `NavigationViewModel`.
  - In-flight race conditions even in cleared ViewModels:
    - `AddressViewModel` (`L128-159, 205-237, 277-295`): `createAddress()`, `updateAddress()`, and `deleteAddress()` do not capture `_stateVersion` before `await`, so a slow response resolving after logout repopulates `_addresses` or `_errorMessage`.
    - `GalleryViewModel` (`L84, 321-336, 370-390, 450-456, 479-506`): `clearUserData()` does not bump `_feedRequestVersion`, and `createWork`/`updateWork`/`deleteWork`/`toggleLike` lack a session-version check before mutating state after `await`.
- **Preconditions:** User A logs out and User B logs in within the same app process (shared device, kiosk, demo device).
- **Impact:** User B immediately sees User A's private activity feed, private AI analysis history/photos, matching results, favorites, or stale address/gallery mutations.
- **Safe Verification:** Inspect `main.dart:89-93` and trace `ActivityScreen` after logout -> login as another account.
- **Recommended Fix:** Centralize logout cleanup into a single `SessionCoordinator.clearAllUserState()` called from `AuthViewModel` logout/account-switch/401 events, invoking `clearUserData()`/`reset()` on **all** stateful ViewModels and repository caches (`_favoriteIds`). Guard all async post-`await` writes in `AddressViewModel` and `GalleryViewModel` with a monotonically incremented `_sessionVersion`.
- **Regression Test:** Add a widget/unit test logging in User A, populating `ActivityViewModel`, `AnalysisViewModel`, `MatchingViewModel`, `_favoriteIds`, and an in-flight `AddressViewModel.createAddress()`, logging out, logging in User B, and asserting zero User A artifacts remain.

---

### `SEC-BE-08` — 9 Known Security Advisories in Locked Composer Packages
- **Severity:** HIGH | **Confidence:** Confirmed | **Category:** Vulnerable & Outdated Components (OWASP A06)
- **Repository:** Backend (`C:\xampp\htdocs\backend_plasvora`)
- **File & Line:** `composer.lock`
- **Component:** Laravel Framework & Symfony HTTP/Routing/MIME/YAML Components
- **Evidence:** Direct execution of `composer audit --no-interaction` reported **9 security vulnerability advisories affecting 6 locked packages**:
  - `laravel/framework` (`v12.70.1`): `CVE-2026-128083` (`PKSA-yxbx-3c9s-cjt9`, low — Task Output Injection, fixed `<12.71.0`).
  - `symfony/http-foundation` (`v7.4.21`): `CVE-2026-121619` (trusted proxy `private_ranges` bypass), `CVE-2026-135802` (client-chosen host in generated URLs), `CVE-2026-135801` (front-controller path rule bypass), `CVE-2026-118514` (`HEAD` request access-control bypass) — fixed in `>=7.4.23`.
  - `symfony/http-kernel` (`v7.4.21`): `CVE-2026-123339` (untrusted forwarded headers on inline fragments) — fixed in `>=7.4.23`.
  - `symfony/mime` (`v7.4.19`): `CVE-2026-45070` (medium — email header injection) — fixed in `>=7.4.22`.
  - `symfony/routing` (`v7.4.21`): `CVE-2026-118516` (host placeholder matching path start) — fixed in `>=7.4.23`.
  - `symfony/yaml` (`v7.4.21`): `CVE-2026-123792` (exponential/quadratic YAML parse DoS) — fixed in `>=7.4.23`.
- **Preconditions:** Deployed backend reachable over HTTP/HTTPS (note: `CVE-2026-135802` and `CVE-2026-135801` directly affect `symfony/http-foundation` request handling used on every Laravel API request, including `asset('storage/...')` URL generation).
- **Impact:** Host-header poisoning on generated URLs (such as `image_url`), proxy-trust spoofing when behind reverse proxies, path-rule bypass, or process DoS.
- **Safe Verification:** Run `composer audit --working-dir=C:\xampp\htdocs\backend_plasvora --no-interaction`.
- **Recommended Fix:** Run `composer update laravel/framework symfony/http-foundation symfony/http-kernel symfony/mime symfony/routing symfony/yaml` to update to patched Laravel 12 (`>=12.71.0`) and Symfony 7.4 (`>=7.4.23`), then re-run `composer audit` and PHPUnit.
- **Regression Test:** Add `composer audit` as a required CI gate.

---

### `SEC-BE-01` — Sanctum Tokens Never Expire and Accumulate Indefinitely
- **Severity:** MEDIUM | **Confidence:** Confirmed | **Category:** Session Management (OWASP A07)
- **Repository:** Backend (`C:\xampp\htdocs\backend_plasvora`)
- **File & Line:** `config/sanctum.php:53`, `app/Http/Controllers/Api/AuthController.php:104-106`
- **Component:** Laravel Sanctum Authentication
- **Evidence:** `config/sanctum.php:53` sets `'expiration' => null`. In `AuthController::login()` (`L104`), `// $user->tokens()->delete();` is commented out, and `createToken('plasvora-auth')` sets no `expiresAt` argument.
- **Preconditions:** User logs in multiple times or a device/token is lost or compromised.
- **Impact:** Stolen Bearer tokens remain valid forever unless the user explicitly calls `/api/logout` from that exact token; there is no `/logout-all` endpoint and no upper bound on active tokens per user.
- **Safe Verification:** Inspect `config/sanctum.php:53` and `AuthController.php:104-106`.
- **Recommended Fix:** Configure finite `SANCTUM_EXPIRATION` (e.g., `10080` minutes / 7 days, or `43200` / 30 days for mobile), schedule `sanctum:prune-expired` daily in `routes/console.php`, optionally prune excess tokens per user (e.g., keep latest 5 devices), and add `POST /api/logout-all`.
- **Regression Test:** Feature test verifying an expired token receives HTTP `401` on `GET /api/me`.

---

### `SEC-BE-02` — Missing Rate Limiting on Mutating CRUD, Matching, Activity & Public Impact Endpoints
- **Severity:** MEDIUM | **Confidence:** Confirmed | **Category:** API4:2023 Unrestricted Resource Consumption
- **Repository:** Backend (`C:\xampp\htdocs\backend_plasvora`)
- **File & Line:** `routes/api.php:42-51,79-116,133-149`, `app/Http/Controllers/Api/ImpactSummaryController.php:29-73`
- **Component:** API Routing & Throttling
- **Evidence:** While Auth, Analyses, Shipping, Orders, Webhooks, and Gallery routes have explicit named throttle limiters, the following routes have **zero** `throttle` middleware:
  - Public: `GET /api/impact-summary` (runs **10 separate SQL queries** per request with zero caching!), `GET /api/materials`, `GET /api/materials/{id}`, `GET /api/material-requests`, `GET /api/material-requests/{id}`.
  - Authenticated mutating/heavy: `POST/PATCH/DELETE /api/materials`, `POST/PATCH/DELETE /api/material-requests`, `POST /api/handover-requests`, `PATCH /api/handover-requests/{id}/status`, `POST/PATCH/DELETE /api/addresses`, `GET /api/materials/{id}/matches`, `GET /api/material-requests/{id}/matches`, `GET /api/activities`.
- **Preconditions:** Any network client (for public routes) or authenticated user (for protected routes).
- **Impact:** Unauthenticated flood on `/api/impact-summary` triggers 10 DB queries/request; authenticated abuser can spam unlimited listings with 10 MB uploads (`POST /api/materials`), addresses, or handover requests, exhausting disk and DB capacity.
- **Safe Verification:** Inspect `routes/api.php` and `php artisan route:list --path=api`.
- **Recommended Fix:** Apply a default API rate limiter (`throttle:60,1` for reads, tighter write limiters like `throttle:20,1` for `POST/PATCH/DELETE` and `POST /api/materials` image uploads), and cache `GET /api/impact-summary` for 30–60 seconds.
- **Regression Test:** Feature test confirming HTTP `429` after exceeding rate limits on `/api/materials` (POST) and `/api/impact-summary`.

---

### `SEC-BE-03` — Broken Object Level Authorization (BOLA) & Missing Status Checks on Smart Matching Endpoints
- **Severity:** MEDIUM | **Confidence:** Confirmed | **Category:** API1:2023 Broken Object Level Authorization
- **Repository:** Backend (`C:\xampp\htdocs\backend_plasvora`)
- **File & Line:** `app/Http/Controllers/Api/MatchingController.php:23-96`
- **Component:** Smart Matching Controller
- **Evidence:**
  - `GET /api/material-requests/{id}/matches` (`L23-58`) calls `MaterialRequest::find($id)` with **no check** on `requester_id === Auth::id()` and **no check** that `status === 'active'`.
  - `GET /api/materials/{id}/matches` (`L64-96`) calls `MaterialListing::find($id)` with **no check** on `owner_id === Auth::id()` and **no check** that `status === 'available'`.
- **Preconditions:** Any authenticated user iterates numeric `{id}` values.
- **Impact:** Any logged-in user can inspect metadata (`material_category`, `requested_weight_kg`, `general_location`, `status`) of other users' `cancelled`/`fulfilled` material requests and `inactive`/`reserved`/`completed` listings via the matching response `request` / `listing` header object.
- **Safe Verification:** Inspect `MatchingController.php:23-96`.
- **Recommended Fix:** Require either public active status (`status === 'active'` / `'available'`) OR ownership (`requester_id === Auth::id()` / `owner_id === Auth::id()`), returning `404` for non-active records owned by others; if matching is intended strictly as an owner/requester action, enforce ownership directly.
- **Regression Test:** Feature test asserting User B receives `404` when querying `/matches` on User A's `cancelled` material request or `inactive` listing.

---

### `SEC-BE-04` — Private Analysis Photos Stored on Unauthenticated `public` Disk + Orphan Leak on Exception
- **Severity:** MEDIUM | **Confidence:** Confirmed | **Category:** Sensitive Data Exposure / Broken File Access Control
- **Repository:** Backend (`C:\xampp\htdocs\backend_plasvora`)
- **File & Line:** `app/Http/Controllers/Api/AnalysisController.php:116,175-184`, `app/Models/AnalysisHistory.php:46`
- **Component:** Plastic Analysis Image Storage
- **Evidence:**
  - `GET /api/analyses/{id}` (`AnalysisController.php:209-214`) enforces owner-only access (`user_id === Auth::id()`).
  - Yet `store()` (`L116`) saves the photo via `$request->file('image')->store('analyses', 'public')` and `AnalysisHistory::getImageUrlAttribute()` (`L46`) exposes `asset('storage/' . $this->input_image_path)` — publicly readable without authentication via `/storage/analyses/<filename>`.
  - In addition, `catch (Exception $e)` (`L175-184`) returns HTTP 500/400/503 without deleting `$imagePath`, leaving orphaned user photos on public storage whenever Gemini fails.
- **Preconditions:** `php artisan storage:link` enabled in deployment; URL leaked via logs, Referer, device screenshots, or directory indexing.
- **Impact:** Bypasses owner-only API access control for private user photos, directly contradicting Flutter's UI claim *"Pemrosesan citra aman & tidak disebarluaskan"* (`analysis_screen.dart:828`), and leaks disk space on failed analyses.
- **Safe Verification:** Inspect `AnalysisController.php:116,175-184` and `AnalysisHistory.php:36-47`.
- **Recommended Fix:** Store analysis photos on the `local` (private) disk, delete `$imagePath` inside the `catch` block before returning errors, and serve images through an authenticated owner-checked route `GET /api/analyses/{id}/image` (or short-lived signed URL).
- **Regression Test:** Feature test asserting (1) failed Gemini call leaves 0 files in storage, and (2) unauthenticated or non-owner requests to `/api/analyses/{id}/image` return `401`/`403`/`404`.

---

### `SEC-BE-05` — Unsanitized User `notes` Prompt Injection Surface & Raw Gemini 400 Error Passthrough
- **Severity:** MEDIUM | **Confidence:** Confirmed | **Category:** AI Security / Prompt Injection & Information Exposure
- **Repository:** Backend (`C:\xampp\htdocs\backend_plasvora`)
- **File & Line:** `app/Services/GeminiVisionService.php:132-134,336`, `app/Http/Controllers/Api/AnalysisController.php:82,182`
- **Component:** Gemini Vision Prompt Builder & Error Handler
- **Evidence:**
  - `AnalysisController.php:82` allows up to `1000` characters of free-form `notes`.
  - `GeminiVisionService.php:132-134` directly concatenates `$notes` into the instruction prompt (`$promptText .= "\nCatatan tambahan dari pengguna: {$notes}";`) with no structural delimiters or instruction-hierarchy framing.
  - `GeminiVisionService.php:336` throws `new RuntimeException('Gambar tidak dapat dianalisis oleh Gemini AI: ' . $errorMsg, 400)` and `AnalysisController.php:182` returns `$e->getMessage()` verbatim to the client.
- **Preconditions:** Authenticated user submits adversarial instructions in `notes` or malformed payload triggering Gemini 400.
- **Impact:** User can steer Gemini's JSON fields (`object_name`, `recommendations`, `safety_notes`, `avoided_emission`) into generating arbitrary/unsafe text stored in `analysis_histories` (and later pre-filled into Marketplace listings or Gallery drafts); upstream provider error internals leak to clients.
- **Safe Verification:** Inspect `GeminiVisionService.php:130-136,330-342` and `AnalysisController.php:175-184`.
- **Recommended Fix:** Strip control characters and limit `notes` server-side to `250` chars, wrap user metadata in explicit `<user_untrusted_context>...</user_untrusted_context>` delimiters with a system instruction to treat it strictly as passive data and ignore embedded instructions, and map Gemini 400 errors to a generic localized user message while keeping upstream details in server logs only.
- **Regression Test:** Unit test verifying `GeminiVisionService` wraps `notes` in delimiters and never forwards raw upstream Gemini error strings in HTTP responses.

---

### `SEC-BE-06` — Unbounded Handover Weight Fields Allow Inflation of Public Environmental Impact Metrics
- **Severity:** MEDIUM | **Confidence:** Confirmed | **Category:** Business Logic / Data Integrity
- **Repository:** Backend (`C:\xampp\htdocs\backend_plasvora`)
- **File & Line:** `app/Http/Requests/UpdateHandoverStatusRequest.php:24-25`, `app/Http/Controllers/Api/HandoverRequestController.php:258,265`
- **Component:** Handover Status Update & Impact Aggregation
- **Evidence:** `UpdateHandoverStatusRequest.php:24-25` validates `'agreed_weight_kg' => ['sometimes', 'numeric', 'min:0.01']` and `'actual_weight_kg' => ['sometimes', 'numeric', 'min:0.01']` with **no `max` rule** and **no check against `$listing->weight_kg`** in `HandoverRequestController.php:256-266`. `ImpactSummaryController.php:43-54` directly sums `actual_weight_kg` for platform-wide public metrics.
- **Preconditions:** Listing owner approves/marks handover as `handed_over` with an inflated `actual_weight_kg` (e.g., `999999.99` on a `1.00 kg` listing, or `> 999999.99` causing MySQL `decimal(8,2)` overflow 500 error).
- **Impact:** Any user with two accounts (or one listing + requester) can arbitrarily falsify Plasvora's public environmental impact dashboard (`materials_handed_over`, `materials_utilized`) or trigger a DB numeric overflow 500.
- **Safe Verification:** Inspect `UpdateHandoverStatusRequest.php:20-28` and `HandoverRequestController.php:256-266`.
- **Recommended Fix:** Add `max:99999` in `UpdateHandoverStatusRequest` and enforce `$agreedWeight <= $listing->weight_kg` and `$actualWeight <= max($listing->weight_kg, $handover->agreed_weight_kg)` inside `HandoverRequestController::updateStatus()`.
- **Regression Test:** Feature test asserting `actual_weight_kg` exceeding `listing->weight_kg` returns HTTP `422`.

---

### `SEC-BE-07` — TOCTOU Race Condition on Gallery Image Count Limits (`min 1` / `max 5`)
- **Severity:** MEDIUM | **Confidence:** Confirmed | **Category:** Concurrency / Validation Bypass
- **Repository:** Backend (`C:\xampp\htdocs\backend_plasvora`)
- **File & Line:** `app/Http/Controllers/Api/GalleryWorkController.php:223-298`
- **Component:** Gallery Work Update Endpoint
- **Evidence:** `update()` reads `$workCheck = GalleryWork::with('images')->find($id)` at `L223`, validates `remove_image_ids`, `$minImages` (1), and `$maxImages` (5) at `L243-280`, uploads files to public disk at `L286-288`, and only acquires `GalleryWork::where('id', $id)->lockForUpdate()` afterward at `L298` without re-checking the image count inside the lock.
- **Preconditions:** Authenticated work author sends two concurrent `PATCH /api/gallery/{id}` requests.
- **Impact:** Concurrent uploads can bypass `max_images = 5` (storing 6–10 images on a single work) or concurrent removals can leave a published gallery work with `0` images (violating `min_images = 1`).
- **Safe Verification:** Inspect `GalleryWorkController.php:223-364`.
- **Recommended Fix:** Re-query existing image IDs and re-validate `$invalidRemoveIds`, `$finalCount >= $minImages`, and `$finalCount <= $maxImages` *inside* the `DB::transaction` after `lockForUpdate()`, aborting and cleaning up `$newlyStoredPaths` on violation.
- **Regression Test:** Feature test simulating stale image set before lock and verifying invariant enforcement + zero orphaned files.

---

### `SEC-FE-04` — No Global HTTP 401 Session Revocation Handler During Active Sessions
- **Severity:** MEDIUM | **Confidence:** Confirmed | **Category:** Authentication Lifecycle
- **Repository:** Frontend (`C:\Project\Plasvora_app`)
- **File & Line:** `lib/core/network/api_client.dart:477-513`, `lib/repositories/auth_repository.dart:132-135`
- **Component:** HTTP Client / Auth Session Management
- **Evidence:** `ApiClient._handleResponse()` throws `ApiException(statusCode: 401)` without deleting the local token or notifying `AuthViewModel`. Only startup `getCurrentUser()` (`auth_repository.dart:132-135`) handles 401 cleanup.
- **Preconditions:** Token is revoked server-side (or expires once `SEC-BE-01` is fixed) while the app is open.
- **Impact:** The UI remains stuck in `AuthState.authenticated`, displaying generic error states across screens instead of wiping session data and returning to `LoginScreen`.
- **Safe Verification:** Inspect `api_client.dart:477-513`.
- **Recommended Fix:** Add an optional `onUnauthorized` callback to `ApiClient`, invoke it on HTTP `401` for `requiresAuth: true` requests, and bind it in `main.dart` to clear token + user-scoped state and transition `AuthViewModel` to `AuthState.unauthenticated`.
- **Regression Test:** Unit test verifying a 401 response on a protected endpoint clears secure token storage and triggers `onUnauthorized` exactly once.

---

### `SEC-FE-05` — Android Auto Backup Enabled by Default
- **Severity:** MEDIUM | **Confidence:** Confirmed | **Category:** Mobile Local Data Protection (MASVS-STORAGE-2)
- **Repository:** Frontend (`C:\Project\Plasvora_app`)
- **File & Line:** `android/app/src/main/AndroidManifest.xml:5-9`
- **Component:** Android Application Manifest
- **Evidence:** `<application>` omits `android:allowBackup="false"` and omits `android:fullBackupContent` / `android:dataExtractionRules`.
- **Preconditions:** Android device with Google Cloud Backup or ADB backup enabled.
- **Impact:** App SharedPreferences/app-data files (including `FlutterSecureStorage` encrypted prefs metadata and any cached files) may be backed up or extracted across devices, causing decryption errors or unnecessary data exposure.
- **Safe Verification:** Inspect `android/app/src/main/AndroidManifest.xml:5-9`.
- **Recommended Fix:** Add `android:allowBackup="false"` (and explicit `android:dataExtractionRules` for Android 12+ excluding secure storage files) in `AndroidManifest.xml`.
- **Regression Test:** Verify manifest attributes in build/CI check.

---

### Low-Severity Security Findings (`SEC-FE-06`, `SEC-FE-07`, `SEC-BE-09`, `SEC-BE-10`, `SEC-BE-11`)

- **`SEC-FE-06` [LOW, FE] Legacy Token Migration Fallback to `Directory.systemTemp` (`lib/core/network/api_client.dart:94-113,178-188`):** If `getApplicationDocumentsDirectory()` throws, `SecureAuthTokenStorage` reads `.plasvora_auth_token` from `Directory.systemTemp` and promotes it into secure storage. **Fix:** Remove the `systemTemp` fallback; fail closed (`return null`) if documents directory lookup fails.
- **`SEC-FE-07` [LOW, FE] Unconditional `ngrok-skip-browser-warning` Header (`lib/core/network/api_client.dart:271,339,391`, `lib/views/gallery/gallery_widgets.dart:174`):** Sent on every API request and every `Image.network` request (even non-ngrok hosts). **Fix:** Only attach this header in `!kReleaseMode` and only when host matches `*.ngrok-free.app` / `*.ngrok.io`.
- **`SEC-BE-09` [LOW, BE] Unrestricted `image_url` Scheme/Host on Material Listings (`StoreMaterialListingRequest.php:58`, `UpdateMaterialListingRequest.php:58`):** Accepts any PHP `url` (`http://`, internal hosts, arbitrary third-party tracking servers) rendered by buyers' Flutter `Image.network` widgets. **Fix:** Enforce `https://` scheme (or disallow external `image_url` when multipart upload is used).
- **`SEC-BE-10` [LOW, BE] EXIF Metadata Preserved on Publicly Uploaded Photos (`MaterialController.php:91,178`, `GalleryWorkController.php:161,287`):** Mobile camera photos uploaded to `public/materials/` and `public/gallery/` retain EXIF headers (potentially exposing exact GPS home coordinates despite Plasvora's `general_location` privacy design). **Fix:** Re-encode uploaded images via GD/Imagick (stripping EXIF) before saving.
- **`SEC-BE-11` [LOW, BE] Default Permissive CORS (`config/` missing `cors.php`):** Laravel 12's default `HandleCors` permits `allowed_origins => ['*']`. Because Sanctum uses Bearer headers (not cookies) and the primary client is native Flutter, direct CSRF impact is low, but if any web client/admin is added, wildcard origins weaken defense-in-depth. **Fix:** Publish `config/cors.php` (`php artisan config:publish cors`) and restrict `allowed_origins` via `CORS_ALLOWED_ORIGINS` env.

---

## 3. Verified Strong Security Controls (Confirmed in Source)

The following controls were directly verified and **do NOT** require rework:
1. **Midtrans Webhook Signature & Deduplication (`MidtransWebhookController.php`, `MidtransService.php`):** Dedicated `MIDTRANS_SIGNATURE_SECRET_KEY` (no silent fallback to Server Key), `hash_equals()` SHA-512 verification, SHA-256 `payload_hash` uniqueness without persisting raw webhook PII, and sandbox guard preventing production URLs when `is_production=false`.
2. **Server-Authoritative Checkout & Price Integrity (`StoreOrderRequest.php`, `OrderService.php`):** Explicitly rejects client-supplied `item_price`, `shipping_cost`, `platform_fee`, `total_amount`, `weight_kg`, `buyer_id`, `seller_id`, `status`; uses integer Rupiah (`RupiahAmount::parseExactWhole`) with zero floating-point drift; locks `MaterialListing` via `lockForUpdate()`.
3. **Order Privacy & Anti-Enumeration (`OrderController.php:97-104,265-280`, `OrderService.php:1073-1108`):** Non-participants receive HTTP `404`; sellers only see buyer `destination_label` before payment and full recipient name/phone/street address only after `paid_at !== null` + `paid/shipped/completed`; `snap_token`/`redirect_url` visible only to buyer.
4. **Gallery Video URL Allowlist & Mass-Assignment Protection (`AllowedVideoUrl.php`, `GalleryWork.php:43-51`):** Strictly validates `https`, rejects embedded `user:pass@host` credentials, matches exact host or subdomain of YouTube/TikTok/Instagram, and excludes `user_id`/`status`/`likes_count` from `$fillable`.
5. **WhatsApp Contact Privacy (`MaterialController.php:120-124`):** Seller `phone` is nulled unless `whatsapp_public === true`.
6. **Flutter Secret Hygiene & TLS Verification:** Zero API keys or secrets in `lib/`; zero `badCertificateCallback` overrides; OS default roots preserved alongside bundled public ISRG Root X1 CA (`assets/certificates/isrgrootx1.pem`); zero sensitive `print`/`debugPrint` calls; strict HTTPS host allowlist for Midtrans Snap URLs (`order_detail_screen.dart`).
7. **Auth & AI Rate Limiting (`AppServiceProvider.php`):** `login` (5/min email+IP, 60/min IP), `register` (3/min, 20/hr IP), `analyses` (3/min, 20/day user), `orders-checkout` (10/min), `midtrans-webhook` (120/min), `gallery-write` (5/min, 20/day).

---

## 4. Items Requiring Runtime / Environment Validation (`needs_validation`)

*Per audit policy, items below are NOT assigned a vulnerability severity because they depend on deployment infrastructure not present in the source repository:*

1. **`NV-01` — Production Reverse Proxy `TrustProxies` & Real Client IP:** `bootstrap/app.php` does not configure `trustProxies()`. If deployed behind Nginx/Cloudflare/ngrok, `$request->ip()` may resolve to the proxy IP, causing IP-based rate limiters (`login`, `register`, `midtrans-webhook`) to share a single bucket across all users. **Validate** in staging/production deployment config.
2. **`NV-02` — Web Server Directory Listing & PHP Execution Prevention in `public/storage/`:** Verify Apache/Nginx disables `Indexes` and PHP execution inside `public/storage/` (`materials/`, `gallery/`, `analyses/`) in the target production host.
