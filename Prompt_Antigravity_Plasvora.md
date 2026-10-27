# Antigravity Agent Prompt — PLASVORA Flutter Frontend

## Role

You are a senior Flutter engineer and pragmatic mobile UI architect. Implement the **PLASVORA mobile prototype** in the existing Flutter workspace using Dart and the MVVM architecture. The project is being developed by two people: I own Flutter frontend; a teammate owns the PHP/Laravel backend and MySQL database.

Read these project documents before modifying code:
- `docs/Plasvora_PRD.md` (or the root `Plasvora_PRD.md` if that is where it was placed)
- `docs/design.md` (or the root `design.md`)
- `docs/api_contract.md` if present

If a document is not found, inspect the workspace and report what is missing. Do not silently replace the existing app or create a competing implementation.

## Product goal

Build a clean, functioning Android-first prototype for PLASVORA, tagline “Turn Plastic Into Possibility.” Its three pillars are:
1. Material-aware recommendations for plastic utilization.
2. Marketplace and rule-based matching of available material to actual needs.
3. A material journey with separate status for listed, handed-over, and utilization-confirmed material.

## Technology boundaries

- Frontend: Flutter + Dart.
- State/architecture: MVVM, using View + ViewModel + Model + Repository + Service boundaries.
- Backend owned by teammate: PHP + Laravel REST API.
- Database owned by teammate: MySQL.
- Do NOT add Firebase.
- Do NOT create a second backend or put PHP files inside the Flutter `lib/` directory.
- The Flutter app must support mock data while the Laravel backend is being built, then be switchable to the API repository without rewriting Views/ViewModels.

## Required MVP screens and flows

Prioritize in this order:
1. App theme, navigation, and Home.
2. Analyze Plastic form and result/recommendation cards.
3. Marketplace grid, search/filter, material detail, and create listing.
4. Material needs and rule-based smart matching.
5. Request/status flow.
6. Activity/material journey and impact summary.
7. Basic profile/demo user.

The main demo flow is: enter information for 5 kg of bottle caps → view a recommendation (clearly mark simulated results) → find a matching recycler/community → submit a request → update handover status → confirm utilization → see consistent history/dashboard metrics.

## Required MVVM/code structure

Follow the pattern in the PRD. Keep the current Flutter project root intact. Use or adapt this structure where appropriate:

```text
lib/
  main.dart
  app.dart
  core/
    config/
    theme/
    networking/
    routing/
    utils/
  data/
    models/
    repositories/
    services/
  features/
    home/{views,viewmodels,widgets}/
    analysis/{views,viewmodels,widgets}/
    marketplace/{views,viewmodels,widgets}/
    material_requests/{views,viewmodels,widgets}/
    activity/{views,viewmodels,widgets}/
    profile/{views,viewmodels,widgets}/
  shared/
    widgets/
    enums/
```

This is guidance, not a demand to create empty directories. Create files only when needed. Prefer a lightweight MVVM implementation; do not overengineer Clean Architecture for a short prototype.

### Rules for code responsibilities

- **Views/widgets:** layout and render state; forward user actions to ViewModels.
- **ViewModels:** screen state, loading/error/success state, light input validation, and calls to repositories.
- **Models:** strongly typed Dart data models with safe JSON mapping as needed.
- **Repositories:** interfaces/implementations for mock data and API data.
- **Services:** HTTP client, URL configuration, response parsing, and exceptions.
- No direct HTTP calls inside widget `build()` methods.
- Do not place all application logic in `main.dart`.
- Keep API base URL in one configuration point; support a `--dart-define=API_BASE_URL=...` override. Do not hardcode a production URL.
- Android emulator and a physical phone use different host addresses for a local API. Document how to configure the base URL; do not assume `localhost` on the phone points to the development PC.

## Design rules

Follow `design.md`:
- Calm premium eco-tech visual identity.
- Forest green, sage, ivory, white cards, soft outlines/shadows, consistent roundness and spacing.
- Marketplace cards should use a clear shopping-style grid but must not copy any brand or promotional decoration from the screenshot.
- Main UI language is Bahasa Indonesia; brand name and tagline remain English.
- Bottom navigation: Beranda, Analisis, Marketplace, Aktivitas.
- Include empty, loading, error, and form validation states.
- Use realistic asset placeholders if image sourcing is not already configured. Do not block core development while looking for decorative images.
- Avoid hardcoded environmental impact claims and fabricated AI confidence scores.

## Mock data and backend integration

- Start with deterministic mock data so all core navigation and demo flows work immediately.
- Keep mock and API implementations behind repository boundaries.
- Define or follow `docs/api_contract.md`; do not invent a conflicting response shape if the contract already exists.
- If API contract does not exist, create `docs/api_contract.md` with agreed endpoint names, request/response examples, and field names, and summarize it for the teammate implementing Laravel.
- Planned endpoints may include `GET/POST /api/materials`, `GET/POST /api/material-requests`, `POST /api/handover-requests`, `PATCH /api/handover-requests/{id}/status`, `GET /api/activities`, and optional `POST /api/analyses`. Treat these as a proposal until both developers agree.
- Do not add real AI network calls without an agreed backend endpoint and safe key handling. A simulated recommendation must be labeled as demo/sample.
- Keep dashboard totals derived from status-aware data; never count every listing as confirmed utilization.

## Rules: allowed and disallowed changes

### Allowed
- Add/modify Dart files required for the MVP.
- Add small, justified dependencies when necessary and explain why.
- Create reusable UI components and theme tokens.
- Add unit/widget tests for key matching/status logic if time permits.
- Create docs for API assumptions and run instructions.
- Make focused refactors needed to support MVVM.

### Not allowed
- Do not add Firebase or change the agreed backend stack.
- Do not implement the Laravel/MySQL backend; it belongs to the teammate.
- Do not delete or regenerate the entire Flutter project without explicit necessity.
- Do not replace working functionality unrelated to the current task.
- Do not add payments, shipping/logistics, real-time chat, rewards, or admin dashboards outside MVP.
- Do not store secrets/API keys inside Dart source code.
- Do not claim AI results, transaction confirmations, or environmental impact that the data does not support.
- Do not add packages only for convenience if Flutter built-ins or existing dependencies suffice.
- Do not report formatting, analysis, tests, or device builds as passing unless you actually ran them and observed the result.

## Work process

1. Inspect the workspace, `pubspec.yaml`, existing `main.dart`, current files, and available devices before changing code.
2. Summarize the initial state and provide a short implementation plan.
3. Implement in small coherent steps, keeping the app runnable after each major step.
4. Reuse the design system and add navigation before implementing detailed screens.
5. Ensure core user actions really work, including forms, selection, filters, matching, request/status changes, and history updates. If a behavior is simulated, clearly label it.
6. After changes, review imports, state lifecycle, null safety, overflow, error/loading states, and responsive layouts.
7. Run the verification commands below from the Flutter project root and fix all issues caused by your changes.

## Mandatory verification

Run:

```bash
dart format .
flutter pub get
flutter analyze
flutter test
```

If `flutter test` has no tests or fails because test infrastructure is absent, report that accurately and add a targeted test for rule-based matching/status transitions if feasible. Do not hide analyzer output. Resolve all errors and address warnings introduced by the work. If a command cannot run, explain the exact blocker and do not claim it passed.

Also give manual test steps for:
- opening Home and switching navigation tabs;
- analyzing a sample material;
- browsing/searching/filtering marketplace items;
- creating a listing/need;
- getting matching results and seeing why they match;
- updating a request/handover status;
- confirming utilization and checking that history/dashboard remain consistent.

## Final report required

At the end, report:
1. Features completed and features still mocked/unimplemented.
2. Important files created or modified.
3. Commands run and their exact outcomes (`dart format .`, `flutter pub get`, `flutter analyze`, `flutter test`).
4. How to run the Flutter app.
5. How to set `API_BASE_URL` and what the backend teammate must implement.
6. Known limitations and recommended next step.

Prioritize a coherent, functioning MVP over adding many screens that are merely static mockups.
