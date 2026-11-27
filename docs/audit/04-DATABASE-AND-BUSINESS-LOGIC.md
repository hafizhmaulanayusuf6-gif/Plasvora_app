# Plasvora — Database Integrity, Business Logic & Special Project Verifications

**Scope:** Database schema & migration integrity (`C:\xampp\htdocs\backend_plasvora`), end-to-end business workflow verification across both repositories, and explicit verification of all five project-specific focus areas (Gallery Publication Policy, Environmental Impact Calculations, API Test Environment, Release Build Configuration, and Session/Cache Isolation).

---

## 1. Database Schema & Migration Integrity

### Current Schema Inventory
- **20 Laravel migrations** defining **12 core business tables** (`users`, `user_addresses`, `material_listings`, `material_requests`, `handover_requests`, `analysis_histories`, `orders`, `order_status_histories`, `payment_webhook_events`, `gallery_works`, `gallery_work_images`, `gallery_work_likes`) plus Laravel system tables (`personal_access_tokens`, `cache`, `cache_locks`, `jobs`, `job_batches`, `failed_jobs`, `password_reset_tokens`, `sessions`).
- **Well-designed relational invariants verified in migrations & models:**
  - `orders`: unique `(buyer_id, idempotency_key)`, unique `order_number`, unique `midtrans_order_id`, immutable snapshots of listing price/weight/origin and buyer address (`recipient_*_snapshot`, `destination_*_snapshot`), integer Rupiah columns (`item_price`, `shipping_cost`, `platform_fee`, `total_amount`).
  - `payment_webhook_events`: unique `payload_hash` (SHA-256), **no raw webhook payload column** (minimizes PII storage).
  - `gallery_works`: `SoftDeletes`, `ownership_confirmed_at`, `published_at`, `likes_count`, `status` (`pending`/`approved`/`rejected`), `rejection_reason`; `gallery_work_likes` enforces unique `(gallery_work_id, user_id)`.
  - `2026_11_23_000004_publish_legacy_pending_gallery_works.php`: clean data migration promoting pre-policy `pending` works to `approved` (`published_at = coalesce(published_at, created_at, now())`).

### Database Discrepancies & Findings

| ID | Severity | Repo | File:Line | Finding |
|---|---|---|---|---|
| `DB-01` | **MEDIUM** | BE | `database/backup_plasvora_db.sql` (Git-tracked) | **Severely Outdated Legacy SQL Dump Tracked in Git:** Dump from Oct 27, 2026 reflects a defunct 6-table schema (`analysis_history`, `users.role/address`, `material_listings.user_id/weight/image_path/location`, `material_requests.listing_id`) incompatible with all 20 migrations and current Eloquent models. Contains only demo placeholder (`demo@plasvora.test`, `'GANTI_DENGAN_HASH_PASSWORD'`), so no real user credentials leaked, but importing it breaks the application. |
| `DB-02` | **MEDIUM** | BE | `app/Http/Requests/StoreMaterialListingRequest.php:52`, `UpdateMaterialListingRequest.php:52`, `MaterialListing.php:31-32` | **Decimal vs. Whole-Rupiah Schema Mismatch:** `material_listings.price` is `decimal(12,2)` and validated as `numeric` without upper bound (`max`) or integer check, while `orders` stores integer Rupiah and `OrderService::validateListingForCheckout()` rejects any fractional `price` (e.g., `15000.50`) with HTTP 422. |
| `DB-03` | **MEDIUM** | BE | `app/Http/Controllers/Api/HandoverRequestController.php:59-141` | **Missing `is_free` Guard on Handover Creation:** `OrderService::createOrder()` (`L1161`) explicitly rejects `is_free == true` listings and directs buyers to Handover, but `HandoverRequestController::store()` never verifies `$listing->is_free === true`, permitting handover reservations on paid listings. |
| `DB-04` | **MEDIUM** | BE | `app/Http/Controllers/Api/HandoverRequestController.php:256-266`, `UpdateHandoverStatusRequest.php:24-25` | **No Upper Bound on `agreed_weight_kg` / `actual_weight_kg`:** Can exceed `listing->weight_kg` (distorting `ImpactSummaryController` sums) or overflow `decimal(8,2)` (`999999.99`), raising HTTP 500 `QueryException`. |
| `DB-05` | **LOW** | BE | `app/Http/Controllers/Api/MaterialController.php:109-131`, `MaterialRequestController.php:76-92` | **`show()` Returns Inactive/Cancelled Records Publicly:** `GET /api/materials/{id}` and `GET /api/material-requests/{id}` return `inactive`, `completed`, and `cancelled` rows to any unauthenticated caller (while `index()` correctly filters to `available` / `active`). If `whatsapp_public == true`, an inactive listing still exposes the seller's phone number. |
| `DB-06` | **LOW** | BE | `app/Http/Controllers/Api/GalleryWorkController.php:404-453` | **Soft-Delete vs. Hard Image File Deletion:** `destroy()` soft-deletes `gallery_works` (`SoftDeletes`) while hard-deleting `gallery_work_images` rows (`L427`) and unlinking image files from `public` disk (`L447`), making soft-deleted works unrecoverable with broken image references if ever restored. |

---

## 2. End-to-End Business Workflow Audit

| Workflow | Status | Verified Controls & Gaps |
|---|---|---|
| **1. Authentication & Profile** | **Broken Error UX (`BUG-01`), Token Hygiene Gaps (`SEC-BE-01`, `SEC-FE-04`)** | Password hashing (`hashed` cast), login/register rate limiting, WhatsApp phone normalization (`628...`), and local-first logout work well. **Blockers:** `AuthState.error` redirects wrong passwords to 403 screen (`BUG-01`); Sanctum tokens never expire (`SEC-BE-01`); logout fails to wipe 7+ ViewModels (`SEC-FE-03`); no active-session 401 handler (`SEC-FE-04`). |
| **2. Plastic Analysis & Upcycling** | **Broken Dropdown Contract (`BUG-02`), AI/Safety Gaps (`AI-BUG-01`, `AI-SAFE-01`)** | Auth-gated, rate-limited (3/min, 20/day), real Gemini Vision with `gemini-2.5-flash-lite` failover. **Blockers:** Flutter `'1'`–`'7'` dropdown fails backend `Rule::in` with 422 (`BUG-02`); compressed PNG/WebP sends wrong MIME (`AI-BUG-01`); private photos stored on public disk & leaked on error (`SEC-BE-04`); history view cannot render remote URLs (`BUG-11`). |
| **3. Marketplace Listings** | **Functional with Validation Gaps (`BUG-08`, `SEC-BE-02`)** | Ownership checks, transaction-lock guards (`reserved`/`completed` cannot be mutated/deleted), and soft deactivation (`status = 'inactive'`) work properly. **Gaps:** Partial PATCH `is_free`/`price` drift (`BUG-08`), no POST/PATCH rate limiter (`SEC-BE-02`), unescaped `LIKE` wildcards (`BUG-17`), Flutter filter sheet controller leak (`BUG-12`). |
| **4. Material Requests & Smart Matching** | **Partially Broken (`BUG-05`, `BUG-10`, `SEC-BE-03`, `AI-MATCH-01`)** | Deterministic 40/30/20/10 scoring is honestly disclosed. **Gaps:** Flutter never sets `MaterialRequestViewModel.currentUserId` so users cannot cancel own requests (`BUG-05`); `MatchingResultsScreen` breaks checkout navigation (`BUG-10`); backend `MatchingController` lacks status/auth checks (`SEC-BE-03`); self-matching and `"Kota"` prefix false-positives (`AI-MATCH-01`). |
| **5. Handover Flow** | **Backend Active / Frontend Unwired** | Backend enforces strict state machine (`pending -> approved -> handed_over -> utilization_confirmed`), row-level locking against Orders, and role checks (`owner` approves/hands over, `requester` confirms utilization). **Gaps:** Missing `is_free` check (`DB-03`), unbounded weight inputs (`DB-04`), and Flutter UI has no wired Handover screen/ViewModel. |
| **6. Orders, Shipping & Midtrans Payments** | **Strongest Subsystem** | Server-authoritative totals, integer Rupiah, RajaOngkir lookup + re-verification under `lockForUpdate()`, `idempotency_key`, Midtrans SHA-512 webhook verification + `payload_hash` dedupe, monotonic reconciliation, seller pre-payment PII masking, and `orders:expire-unpaid` scheduled every 5 min (`routes/console.php:13-15`). **Operational requirement:** Laravel scheduler (`schedule:run`) must actually run in production so expired unpaid orders release reserved listings. |
| **7. Gallery of User Works** | **Backend Solid / Frontend Widget Test Failures (`BUG-06`, `BUG-07`)** | Immediate publication with mandatory ownership declaration works end-to-end; strict HTTPS video allowlist; atomic like toggle; `throttle:gallery-write` (5/min, 20/day). **Gaps:** Image-count TOCTOU race on concurrent `PATCH /api/gallery/{id}` (`SEC-BE-07`); `CheckboxListTile`-in-`Container` assertion (`BUG-06`) and `setState` during build (`BUG-07`) breaking 4 Flutter tests. |
| **8. Activity & Impact Summary** | **Live DB Data / UI & Query Gaps (`BUG-04`, `AI-CLAIM-03`, `PERF-01`)** | Backend aggregates genuine DB rows with handover/order deduplication. **Gaps:** `ActivityViewModel` fires before login and `ActivityScreen` never refreshes (`BUG-04`); Home `"Bulan ini"` label contradicts all-time totals (`AI-CLAIM-03`); 10 uncached SQL queries on unthrottled public `/api/impact-summary` (`PERF-01`, `SEC-BE-02`). |

---

## 3. Phase 12 — Special Project-Specific Verifications

### A. Gallery Publication Policy (Intentional MVP Behavior vs. Security Trade-offs)
- **Verified Implementation:**
  - `StoreGalleryWorkRequest.php:73` requires `'ownership_confirmed' => ['required', 'accepted']`.
  - `GalleryWorkController::store()` (`L174-178`) intentionally sets `status = 'approved'`, `published_at = now()`, `ownership_confirmed_at = now()`, `reviewed_at = null`, `rejection_reason = null` — **immediate publication**.
  - `GalleryWorkController::update()` (`L326-330`) preserves existing status (approved stays approved; legacy rejected does not auto-publish).
  - Migration `2026_11_23_000004_publish_legacy_pending_gallery_works.php` migrates legacy `pending` rows cleanly.
  - Moderation schema columns (`status`, `rejection_reason`, `reviewed_at`) and CLI commands (`gallery:pending`, `gallery:review`) remain intentionally preserved for reactive operator takedown without a web admin panel.
- **Audit Assessment:** This is **not a bug**—it faithfully implements the user-approved MVP publication policy. The legitimate trade-off is unmoderated public UGC exposure (spam, off-topic/inappropriate photos, copyright claims). Existing mitigations (`throttle:gallery-write` 5/min & 20/day, strict MIME/4MB/5-image limits, `AllowedVideoUrl`, reactive `gallery:review reject`) are appropriate for MVP; before large public rollout, add a user "Report Content" endpoint and image EXIF stripping (`SEC-BE-10`).

### B. Environmental Impact Estimates (Fact vs. Misstatement)
- **Home Screen `Jejak Kontribusi` (`GET /api/impact-summary`):** **Genuine live DB aggregation** (`ImpactSummaryController.php:26-111`) with explicit handover-vs-order deduplication (`L57-69`) and zero hardcoded fallback numbers on Flutter (`HomeViewModel` renders `'...'`/`'-'`). **Only defect:** Flutter (`home_screen.dart:524-546`) displays a static `"Bulan ini"` pill over all-time totals (`AI-CLAIM-03`), and backend runs 10 uncached queries with no rate limit (`PERF-01`, `SEC-BE-02`).
- **Analysis Result `Emisi Terhindar` (`AnalysisResultScreen`):** **NOT verified LCA** — uses LLM free-text or hardcoded per-polymer strings (`~1.5`–`~2.1 kg CO₂/kg`) without source citation, mass multiplication, or guaranteed `(Estimasi)` qualifier (`AI-CLAIM-02`).

### C. API Test Environment (`phpunit.xml` & MySQL Blocker)
- **Verified Configuration (`C:\xampp\htdocs\backend_plasvora\phpunit.xml`):** Configured for `DB_CONNECTION=mysql`, `DB_HOST=127.0.0.1`, `DB_PORT=3306`, `DB_DATABASE=plasvora_testing`, `DB_USERNAME=root`, `DB_PASSWORD=""`.
- **Observed Execution Result:** All **17 database-free unit tests passed** (`MidtransServiceTest`: 16 tests, `ExampleTest`: 1 test). All **5 DB-dependent unit tests** (`OrderModelTest`) errored immediately with `SQLSTATE[HY000] [2002] No connection could be made because the target machine actively refused it` because the local XAMPP MySQL service is stopped. Consequently, none of the 16 `RefreshDatabase` Feature suites could be executed (see [05-TEST-AND-DEPENDENCY-RESULTS.md](05-TEST-AND-DEPENDENCY-RESULTS.md)).

### D. Release Build Configuration (Android)
- **Confirmed Release Blockers:**
  1. `android/app/build.gradle.kts:36` signs `release` with `signingConfigs.getByName("debug")` (`SEC-FE-02`).
  2. `android/app/build.gradle.kts:8,19` uses placeholder `com.example.plasvora` and omits R8 minification/shrinking (`SEC-FE-02`).
  3. `android/app/src/main/AndroidManifest.xml:6` globally enables `android:usesCleartextTraffic="true"` (`SEC-FE-01`).
  4. `android/app/src/main/AndroidManifest.xml:5-9` omits `android:allowBackup="false"` (`SEC-FE-05`).
  5. `lib/core/network/api_config.dart:7` defaults to `http://127.0.0.1:8000/api` with no `kReleaseMode` HTTPS check (`SEC-FE-01`).

### E. User Session & Cache Isolation
- **Confirmed Isolation Failure (`SEC-FE-03`):**
  - Cleared on logout: `AuthViewModel`, `AddressViewModel` (partially—mutations race), `OrderViewModel`, `GalleryViewModel` (partially—feed version & mutations race), `SecureAuthTokenStorage`.
  - **NOT cleared on logout:** `ActivityViewModel` (`_activities`, `_analyses`), `AnalysisViewModel` (`_imagePath`, `_notes`, `_polymerCategory`, `_analysisResult`), `MatchingViewModel`, `ApiMaterialRepository._favoriteIds`, `MaterialRequestViewModel`, `MarketplaceViewModel`, `HomeViewModel`, `NavigationViewModel`.
  - Compounded by `ActivityScreen` never refreshing on open (`BUG-04`), guaranteeing User B sees User A's cached activity & analysis history immediately after switching accounts.
