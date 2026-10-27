# Plasvora — Team Handoff

## Documents
- `Plasvora_PRD.md`: product description, feature scope, tech stack, MVVM structure, MVP acceptance criteria.
- `design.md`: UI system and screen-by-screen design direction based on the supplied references.
- `Prompt_Google_Stitch_Plasvora.md`: paste into Google Stitch to produce mobile UI designs.
- `Prompt_Antigravity_Plasvora.md`: give to Antigravity for Flutter implementation.
- `api_contract.md`: draft API agreement between Flutter and Laravel developers.

## Agreed stack
- Mobile: Flutter + Dart
- Frontend architecture: pragmatic MVVM
- Backend: PHP + Laravel REST API (teammate)
- Database: MySQL (teammate)
- Prototype can use mock repositories until agreed API endpoints are ready.

## Suggested workflow
1. Use the Google Stitch prompt to design screens, then compare the output against `design.md`.
2. Keep the existing Flutter project root; don't regenerate project files unnecessarily.
3. Flutter developer builds Views/ViewModels/Models/Repositories and mock data.
4. Backend developer builds Laravel endpoints and MySQL schema using `api_contract.md` as a draft.
5. Agree changes to API contract before integration.
6. From Flutter project root run `dart format .`, `flutter pub get`, `flutter analyze`, and `flutter test`; report actual outcomes.
