# Plasvora — Bugs, Functional Errors, Code Quality & Performance Audit

**Scope:** Non-security functional bugs, cross-project API contract mismatches, live test failure root causes, code quality/maintainability findings, and performance/reliability issues across `C:\Project\Plasvora_app` (`FE`) and `C:\xampp\htdocs\backend_plasvora` (`BE`).

---

## 1. Confirmed Functional Bugs & Contract Mismatches

| ID | Severity | Repo | File:Line | Summary |
|---|---|---|---|---|
| `BUG-01` | **CRITICAL** | FE | `lib/viewmodels/auth_viewmodel.dart:109-113,140-144`, `lib/main.dart:304-386`, `lib/views/auth/login_screen.dart:69` | Login/registration failures redirect to full-screen `"403 Akses Dibatasi"` screen and swallow actual error messages |
| `BUG-02` | **CRITICAL** | FE+BE | `lib/views/analysis/analysis_screen.dart:428-455`, `app/Http/Controllers/Api/AnalysisController.php:79` | Analysis dropdown sends numeric resin codes `'1'`–`'7'` while Laravel only accepts `PET`/`HDPE`/`PP`/`LDPE`/`OTHER`/`MIXED` (guaranteed HTTP 422) |
| `BUG-03` | **HIGH** | BE | `app/Services/GeminiVisionService.php:74-75,258,496` | Compressed PNG/WebP images are re-encoded as JPEG bytes while `inlineData.mimeType` remains `image/png` or `image/webp` |
| `BUG-04` | **HIGH** | FE | `lib/main.dart:102-104`, `lib/viewmodels/activity_viewmodel.dart:11-14`, `lib/views/activity/activity_screen.dart:20` | `ActivityViewModel` fires protected endpoints before login, and `ActivityScreen` never refreshes on open |
| `BUG-05` | **HIGH** | FE | `lib/viewmodels/material_request_viewmodel.dart:8,263-266`, `lib/main.dart:105-107`, `material_request_detail_screen.dart:144-151` | `MaterialRequestViewModel.currentUserId` is never assigned, preventing users from cancelling their own requests |
| `BUG-06` | **HIGH** | FE | `lib/views/gallery/create_gallery_work_screen.dart:1217-1252` | `CheckboxListTile` wrapped in colored `Container`/`DecoratedBox` throws Flutter framework assertion (fails 3 widget tests) |
| `BUG-07` | **MEDIUM** | FE | `lib/views/gallery/my_gallery_works_screen.dart:52-76`, `create_gallery_work_screen.dart` | `setState() or markNeedsBuild() called during build` on `ListenableBuilder` when navigating to edit work (fails 1 widget test) |
| `BUG-08` | **MEDIUM** | BE | `app/Http/Requests/UpdateMaterialListingRequest.php:87-98`, `StoreMaterialListingRequest.php:52` | Partial PATCH allows inconsistent `is_free=false, price=0` state; fractional prices pass listing validation then fail `OrderService` with 422 |
| `BUG-09` | **MEDIUM** | BE | `app/Services/MaterialMatchingService.php:40-43,72-75,196-211` | Smart Matching returns user's own listings/requests (self-matching) and false-matches cities starting with `"Kota"` / `"Kab."` |
| `BUG-10` | **MEDIUM** | FE | `lib/views/matching/matching_results_screen.dart:12-33,344-351` | Navigating from `MatchingResultsScreen` to `MaterialDetailScreen` omits `orderViewModel`, breaking Checkout entry point |
| `BUG-11` | **MEDIUM** | FE | `lib/views/analysis/analysis_result_screen.dart:101-105` | Cannot render remote `http(s)://` analysis photos when reopening saved history (falls back to bottle-caps placeholder) |
| `BUG-12` | **MEDIUM** | FE | `lib/views/marketplace/marketplace_screen.dart:1400-1408` | 3 `TextEditingController`s allocated and never disposed every time the filter bottom sheet opens (memory leak) |
| `BUG-13` | **MEDIUM** | FE | `lib/views/marketplace/material_detail_screen.dart:73,352-359`, `material_request_detail_screen.dart:50` | Synchronous `setState` in `initState` and unguarded async `setState` after `await` |
| `BUG-14` | **LOW** | FE | `lib/views/home/home_screen.dart:818-839,947`, `lib/models/material_listing.dart:26,162` | Home cards display `"<City> • null km"`, ignore remote `item.imageUrl`, and `MaterialListing.fromJson` defaults missing `owner_id` to `1` |
| `BUG-15` | **LOW** | FE | `lib/core/network/api_client.dart:226-265`, `lib/views/gallery/gallery_widgets.dart:170-185` | Bundled `isrgrootx1.pem` CA is installed only on `ApiClient`'s `IOClient`, not `HttpOverrides.global` (`Image.network` fails Let's Encrypt TLS on Android 7.0) |
| `BUG-16` | **LOW** | FE | `lib/viewmodels/marketplace_viewmodel.dart:83-111,173-189`, `material_request_viewmodel.dart:154-257`, `order_viewmodel.dart:266-296` | Missing in-flight duplicate-submit / concurrency guards on list refresh and mutation paths |
| `BUG-17` | **LOW** | BE | `app/Http/Controllers/Api/MaterialController.php:29-35,54-56`, `MaterialRequestController.php:28-30` | Unescaped SQL `LIKE` wildcards (`%`, `_`) in `q` and `location` filters (unlike `GalleryWorkController.php:39`) |

---

### Deep-Dive Notes on High-Impact Bugs

#### `BUG-01` — Login / Registration Error Hijacks Navigation to "403 Akses Dibatasi"
- **Exact Flow:**
  1. User enters wrong password on `LoginScreen` -> `AuthViewModel.login()` catches `ApiException(401)` -> sets `_state = AuthState.error` (`lib/viewmodels/auth_viewmodel.dart:109-113`). Same in `register()` (`L140-144`).
  2. `PlasvoraApp` (`lib/main.dart:304-386`) rebuilds whenever `authViewModel` notifies. Because `state == AuthState.error`, it **replaces** `LoginScreen` with `_buildAuthErrorScreen` displaying `"Akses Dibatasi"` / `"403 Forbidden"`.
  3. `LoginScreen` is unmounted before its `SnackBar` renders, hiding the actual validation/auth error. Additionally, `login_screen.dart:69` does not wrap the button in `ListenableBuilder`, and `onFieldSubmitted` does not check `isLoading`.
- **Smallest Fix:** Keep `_state = AuthState.unauthenticated` on interactive `login()` / `register()` failures (storing `_errorMessage` only), and reserve `AuthState.error` strictly for cold-start `checkAuthSession()` failures (`403`/`500`/network).

#### `BUG-02` — Analysis Polymer Dropdown Contract Mismatch (`'1'`–`'7'` vs Canonical Codes)
- **Exact Flow:** `lib/views/analysis/analysis_screen.dart:428-455` defines dropdown item values as `'1'` (PET), `'2'` (HDPE), `'3'` (PVC), `'4'` (LDPE), `'5'` (PP), `'6'` (PS), `'7'` (Other). Laravel `AnalysisController.php:79` validates `declared_category` with `Rule::in(['PET', 'HDPE', 'PP', 'LDPE', 'OTHER', 'MIXED'])`.
- **Observed Consequence:** Every single dropdown selection produces a guaranteed **HTTP 422 Validation Error** from Laravel, and even in local fallback (`ApiAnalysisRepository._mapCategoryToDefaultResult`, `analysis_repository.dart:280-311`), `'1'`–`'7'` misses every `switch` branch and falls through to `default` (`Tipe #7 (Other)`).
- **Smallest Fix:** Change `AnalysisScreen` dropdown values to canonical strings (`'PET'`, `'HDPE'`, `'PP'`, `'LDPE'`, `'OTHER'`, `'MIXED'`, mapping PVC/PS clearly to `'OTHER'` or adding `'PVC'`/`'PS'` across both BE & FE consistently).

#### `BUG-06` & `BUG-07` — Real Flutter Framework Assertions Breaking Gallery Widget Tests
- **`BUG-06` (`create_gallery_work_screen.dart:1217-1252`):** `_buildOwnershipSection` places a `CheckboxListTile` inside `Container(decoration: BoxDecoration(color: AppColors.surfaceContainerLowest, ...))`. Flutter's `ListTile` asserts in debug/test mode that a colored `DecoratedBox` ancestor hides ink splashes (`ListTile background color or ink splashes may be invisible`), causing **8 framework exceptions per render** and failing 3 tests in `test/gallery_feature_test.dart`.
  - **Fix:** Replace the outer `Container` with `Material(color: AppColors.surfaceContainerLowest, shape: RoundedRectangleBorder(...), clipBehavior: Clip.antiAlias, child: ...)`.
- **`BUG-07` (`my_gallery_works_screen.dart` + `create_gallery_work_screen.dart`):** Navigating to edit triggers a synchronous `notifyListeners()` during the active build phase while `MyGalleryWorksScreen`'s `ListenableBuilder` is mounted, throwing `setState() or markNeedsBuild() called during build`.
  - **Fix:** Defer `clearSubmitError()` with `WidgetsBinding.instance.addPostFrameCallback` or invoke it with `notify: false` inside `initState`.

#### `BUG-08` — Partial PATCH `is_free`/`price` Drift & Decimal Price Mismatch
- **`UpdateMaterialListingRequest.php:87-98`:** Only checks `is_free`/`price` consistency when **both** fields are sent in the same PATCH request. Sending `{"is_free": false}` alone or `{"price": 0}` alone leaves a paid listing with `price = 0`, which later fails checkout in `OrderService::validateListingForCheckout` (`L1201`) with HTTP 422.
- **`StoreMaterialListingRequest.php:52` & `UpdateMaterialListingRequest.php:52`:** Accepts decimal prices (e.g., `15000.50`) and has no `max` bound (`decimal(12,2)` overflow risk), whereas `OrderService` (`L1192`) requires whole Rupiah integers via `RupiahAmount::parseExactWhole()`.
- **Fix:** Validate merged effective `(is_free, price)` against the existing listing model on PATCH, enforce whole-Rupiah integer pricing (`integer`, `min:0`, `max:999999999`), and add `max` bounds consistently.

---

## 2. Code Quality & Maintainability Assessment

### Strengths
- **Consistent Pattern Adherence:** Both repos maintain clean layer boundaries (Flutter: `models/` -> `repositories/` -> `viewmodels/` -> `views/`; Laravel: `routes/` -> `Http/Requests/` -> `Http/Controllers/Api/` -> `Services/` + `Policies/` -> `Models/`).
- **Strong Domain Modeling in Newer Features:** `OrderService` and `GalleryWorkController` use explicit constants (`Order::STATUS_*`, `GalleryWork::STATUS_*`), atomic DB transactions, and clear Indonesian error messages.
- **Zero Analyzer Errors in Flutter Production Code:** `flutter analyze` produced **0 issues in `lib/`** (only 2 unused-parameter warnings in `test/gallery_feature_test.dart:95,99`).

### Maintainability & Architectural Weaknesses
1. **Oversized Monolithic Files:**
   - `OrderService.php` (**1,649 lines**) mixes checkout orchestration, Midtrans Snap/reconciliation, expiry sweeps, and API JSON serialization (should extract `OrderSerializer` and `OrderPaymentReconciler`).
   - `analysis_result_screen.dart` (**1,800+ lines**), `marketplace_screen.dart` (**1,400+ lines**), and `create_gallery_work_screen.dart` (**1,426 lines**) mix layout, dialogs, and form logic in single widget files.
2. **Dead / Unwired Legacy Code:**
   - Flutter `lib/models/handover_item.dart` and handover methods in `lib/repositories/transaction_repository.dart` are never wired to any ViewModel or screen (paid checkout replaced the UI flow while Handover remains active only on the backend API).
   - `MaterialMatchingService.php` duplicates identical scoring logic across `evaluateListing()` (`L103-147`) and `evaluateRequest()` (`L154-191`) — extract one shared `scorePair()` helper.
3. **Duplicated Session Cleanup Logic (`FE`):** `_clearUserScopedState()` is duplicated identically in `lib/main.dart:89-93` and `lib/views/profile/profile_screen.dart:102-104`, which caused newly added/older ViewModels to drift out of sync.
4. **Inconsistent Validation & Error Envelopes (`BE`):**
   - `MaterialController::index()` and `MaterialRequestController::index()` do not validate query params (`category`, `condition`, `min_weight`, `max_weight`, `per_page`), unlike `OrderController::index()` and `GalleryWorkController::index()`.
   - Language mixes English (`Material listing not found`, `Handover request submitted successfully`) in older controllers with Indonesian (`Pesanan berhasil dibuat`, `Karya galeri tidak ditemukan`) in newer controllers.
5. **Missing Null-Safe Operator (`ActivityController.php:91,98`):** Uses `$handover->requester->name` / `$handover->owner->name` directly while line 92 uses `$handover->listing?->name`.

---

## 3. Performance & Reliability Audit

| ID | Impact | Repo | File:Line | Observation & Recommendation |
|---|---|---|---|---|
| `PERF-01` | **MEDIUM** | BE | `app/Http/Controllers/Api/ImpactSummaryController.php:29-73` | Executes **10 separate SQL queries** per unauthenticated hit, pulls all transferred `listing_id`s into PHP memory via `->pluck('listing_id')->all()`, and injects them into `WHERE listing_id NOT IN (...)` (hits MySQL placeholder limits at scale). **Fix:** Rewrite using SQL `NOT EXISTS` / conditional `SUM(CASE WHEN ...)` in 2–3 aggregate queries and cache for 60s. |
| `PERF-02` | **MEDIUM** | BE | `app/Services/MaterialMatchingService.php:40-43,72-75` | Loads **all** rows matching `category` into PHP memory (`->get()`) before scoring and slicing to top 10. **Fix:** Add pre-filtering/limits (`latest()->limit(200)`) or push category/weight/owner exclusions into SQL. |
| `PERF-03` | **MEDIUM** | BE | `app/Http/Controllers/Api/ActivityController.php:29-186` | Fires 5 separate DB queries per request with no pagination and merges up to 70 rows in PHP before taking 30; also omits Gallery work activity. |
| `PERF-04` | **LOW** | BE | `app/Services/OrderService.php:1241-1263,1382-1407` | If `createOrder()` commits the DB row and Midtrans Snap times out, replaying `POST /api/orders` with the same `idempotency_key` returns `200` with `snap_token: null` instead of transparently initiating or instructing `/retry-payment`. |
| `PERF-05` | **LOW** | FE | `lib/views/gallery/gallery_widgets.dart`, `marketplace_screen.dart` | Uses raw `Image.network` without disk image caching (`cached_network_image`) or `cacheWidth`/`cacheHeight` decoding bounds on high-res uploads (up to 10 MB listings / 4 MB gallery photos), increasing mobile RAM usage during scrolling. |
| `PERF-06` | **LOW** | BE | `app/Services/RajaOngkirService.php:124-207` | Destination searches are cached (`search_cache_ttl = 300s`), but `calculateDomesticCost()` has no short-TTL route/weight cache, consuming upstream RajaOngkir quota on repeated estimate taps for the same `(origin, destination, weight)` tuple. |
