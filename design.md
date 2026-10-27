# PLASVORA — Design System & UI Direction

**Product:** PLASVORA — *Turn Plastic Into Possibility.*  
**Platform:** Flutter mobile app, Android-first  
**Primary language:** Bahasa Indonesia  
**Design goals:** calm, trustworthy, modern eco-technology; easy to scan; marketplace cards clear and practical.

## 1. Design references and interpretation

Use the supplied references as inspiration, not as assets to copy:

1. **Three-screen travel app reference:** borrow the calm nature-inspired palette, large editorial headline, generous whitespace, soft rounded cards, subtle shadows, elegant image use, and clear bottom navigation. Replace all travel content and controls with plastic analysis, materials, and environmental impact.
2. **Marketplace screenshot:** borrow the familiar shopping information hierarchy: a prominent search field, compact category/filter chips, grid product cards, clear price/weight/status information, and bottom navigation. Do not reproduce the marketplace's brand, pink promotion banners, sale countdowns, shopping cart badges, or commercial visual clutter.

The result should look like a credible sustainability-tech startup, not a travel app and not a copy of an existing e-commerce app.

## 2. Brand and visual tone

- Brand name: **PLASVORA**
- Tagline: **Turn Plastic Into Possibility.**
- Tone: hopeful, intelligent, practical, trustworthy, and community-focused.
- Avoid overly playful cartoon visuals, excessive gradients, neon green, gamification overload, and fake environmental impact claims.

## 3. Color tokens

| Token | Hex | Use |
|---|---|---|
| `forestGreen` | `#205B46` | Primary CTA, selected nav/filter, key accents |
| `deepGreen` | `#153D32` | Logo, main headings, dark accents |
| `sage` | `#E8EFE5` | Soft backgrounds and tinted sections |
| `ivory` | `#F8F8F2` | Main app background |
| `surface` | `#FFFFFF` | Cards, sheets, input surfaces |
| `textPrimary` | `#20312A` | Main content text |
| `textSecondary` | `#65746B` | Metadata and helper text |
| `mint` | `#C7E2C8` | Gentle emphasis and positive states |
| `warning` | `#D99A35` | Uncertain AI results or caution |
| `error` | `#B94C45` | Form errors and failed states |
| `outline` | `#DCE4DC` | Borders and dividers |

Use these colors from centralized theme files. Always maintain readable contrast; don't use the accent color as small text on a white background unless contrast is sufficient.

## 4. Typography

- Prefer a clean sans-serif such as Inter, Manrope, or the platform default if adding a font would delay the prototype.
- App name and large hero statement: bold/semibold, clear line breaks, restrained size.
- Screen titles: 22–28 sp depending on available space.
- Card title: 14–16 sp, semibold.
- Body: 14–16 sp.
- Metadata/labels: 11–13 sp, never too faint.
- Avoid mixing too many fonts. The reference uses editorial typography on the hero; the rest of the app should remain highly readable.

## 5. Spacing, shape, and component behavior

- Base spacing: 4, 8, 12, 16, 20, 24, 32.
- Screen horizontal padding: usually 20–24 dp.
- Card radius: 16–22 dp.
- Text field radius: 14–18 dp.
- Primary buttons: 52–56 dp high, rounded, clear label.
- Cards: white surface, fine outline or very soft shadow; avoid heavy drop shadows.
- Image crops: consistent aspect ratio within the same card list.
- Use consistent icons with clear labels where needed; don't rely on icons alone for essential actions.
- Buttons need loading/disabled states where asynchronous requests are possible.
- Forms need validation messages close to the related field.

## 6. Navigation

Use a four-item bottom navigation:

1. **Beranda** — home and activity summary.
2. **Analisis** — photo/input-based plastic analysis and recommendations.
3. **Marketplace** — material listings, material needs, and matching.
4. **Aktivitas** — requests, handover status, history, impact summary.

Profile can be opened from the avatar in the home header or from the activity screen. Keep navigation consistent across screens. Use one selected state and do not create nested bottom navigations.

## 7. Screen specifications

### 7.1 Home

- Header with PLASVORA wordmark/icon, notifications if implemented, and profile avatar.
- Hero area with a nature/material image or subtle eco illustration.
- Headline: “Beri Plastik Kesempatan Kedua” or “Turn Plastic Into Possibility”.
- Supporting text in Bahasa Indonesia.
- Large primary CTA: **Analisis Plastik** / **Unggah Material**.
- Three quick action cards: Analisis Plastik, Cari Material, Tawarkan Plastik.
- Small impact summary with separately labeled values: material listed, handed over, and confirmed utilized. Use sample figures only when visibly designated as demo data.
- Marketplace preview with two material cards and “Lihat semua”.

### 7.2 Analyze Plastic

- Clear screen title and short explanation.
- Large dashed/outlined photo-upload area with camera/gallery action.
- Form fields: jenis jika diketahui, berat (kg), kondisi, and optional notes.
- Primary button: **Analisis Material**.
- Explain that image-based category is an estimate; do not imply laboratory certainty.
- Loading state during analysis.

### 7.3 Analysis Result

- Large photo preview.
- Estimated material/category with an uncertainty note or confidence only if the service actually supplies a meaningful score.
- If confidence is not real, do not fabricate a percentage.
- Recommended idea cards with image, title, difficulty, short description, and arrow affordance.
- Each idea detail includes tools, other materials, steps, and safety notes.
- Primary CTA: **Cari Penerima Material**.
- Secondary CTA: **Simpan Ide** if implemented.

### 7.4 Marketplace

This screen should borrow the card/grid information hierarchy of the marketplace reference but use PLASVORA’s quieter eco identity.

- Search field at the top: “Cari jenis plastik, material, atau lokasi”.
- Filter chips: Jenis, Kondisi, Berat, Jarak; allow horizontal scrolling if necessary.
- Category chips: Semua, PET, HDPE, PP, LDPE, Lainnya.
- Two-column grid on typical phone width; switch to one column if accessibility/text scaling requires it.
- Each material card contains:
  - photo of material;
  - material name/category;
  - weight in kg;
  - condition;
  - general location/distance only if supplied by data;
  - price or “Gratis”;
  - availability state;
  - optional bookmark.
- Do not show fake ratings or fake sold counts. Avoid discount, flash-sale, and shopping-platform badges.
- A clear add/list-material action should be easy to find (FAB or visible button).

### 7.5 Material Detail

- Photo gallery/hero image.
- Title, category, weight, condition, price/free, general location, and description.
- Owner/community details only if permitted and available.
- CTA: **Ajukan Material**.
- Show listing status and relevant safety/condition notes.

### 7.6 Create Material Listing

Fields: material name/category, optional image, weight, condition, price or free toggle, general location, and description. Validate required values and positive weight. Explain that exact home address should not be public.

### 7.7 Material Needs and Smart Matching

- Toggle/tab between **Material Tersedia** and **Kebutuhan**.
- Form for desired material category, amount, minimum condition, general location, and intended use.
- Matching results show why each match is suggested, e.g. category compatible, enough quantity, condition accepted, location nearby.
- Do not call a candidate a confirmed transaction until both parties have acted.

### 7.8 Activity / Material Journey

- Filter/status chips: Semua, Menunggu, Disetujui, Diserahkan, Dimanfaatkan.
- Each entry displays material, date, amount, role, and status.
- Timeline may show listing → request → handover → utilization confirmation.
- Confirmation actions must be role-aware and update the source of truth.

### 7.9 Impact Dashboard

- Separate metric cards for listed, handed-over, and confirmed-utilized material.
- Transaction count uses confirmed statuses.
- Display a note if the app is using sample/demo data.
- Avoid unverified CO₂-saved, tree-equivalent, or “pollution prevented” estimates.

### 7.10 Profile

- Avatar, name, general location, and profile edit if implemented.
- Links to own listings, own requests, and history.
- Logout only if real authentication has been implemented.

## 8. UI states and accessibility

Every data-driven list/form should account for:
- Loading state.
- Empty state with a useful next action.
- Error state with retry where appropriate.
- Form validation.
- Disabled/submitting button state.
- Long text and larger system text size without overflow.
- Image loading errors/placeholders.

Do not hardcode all business data inside screen widgets. Use ViewModels and repositories so the UI can swap mock data for the Laravel API.

## 9. Component inventory

Reusable components to consider:
- `PlasvoraAppBar`
- `PlasvoraBottomNavigation`
- `PrimaryButton`
- `SearchField`
- `FilterChipRow`
- `MaterialCard`
- `MaterialStatusChip`
- `ImpactMetricCard`
- `AnalysisUploadCard`
- `RecommendationCard`
- `EmptyStateView`
- `LoadingView`
- `ErrorStateView`

Do not create a separate component for every one-off visual. Reuse only where it keeps the UI consistent.

## 10. Design acceptance checklist

- [ ] The screens feel visually connected to the forest-green/ivory reference.
- [ ] Marketplace search and grid cards are easy to scan on a phone.
- [ ] Material weight, condition, price/free, and status are easy to distinguish.
- [ ] The app does not imitate the travel app or e-commerce brand literally.
- [ ] Primary user actions are obvious and consistently placed.
- [ ] All screens use the same spacing, colors, typography, and corner radii.
- [ ] Loading, empty, error, and form validation states are considered.
- [ ] UI data comes through ViewModels/repositories, not static widget-only business logic.
