# Prompt for Google Stitch — PLASVORA Mobile UI

Design a polished **Android mobile app UI for PLASVORA**, an AI-assisted plastic upcycling and recycled-material marketplace. The tagline is **“Turn Plastic Into Possibility.”** The main language in the UI must be **Bahasa Indonesia**; keep the brand name and tagline in English.

Use the two supplied visual references as direction:
- Reference 1 (three travel-app screens): borrow its calm nature-inspired forest-green/sage palette, ivory backgrounds, large editorial hero typography, generous whitespace, rounded white cards, subtle shadows, high-quality imagery, and simple bottom navigation. Do NOT include travel content.
- Reference 2 (e-commerce marketplace screenshot): borrow only the information hierarchy of a search bar, category/filter chips, dense but readable product grid, product image, price, category, and availability. Do NOT copy its logo, pink sale banners, flash-sale countdown, cart badges, or promotional clutter.

The result should feel like a modern, trustworthy sustainability-tech startup. It should be clean and premium, practical rather than overly decorative, and feasible to implement in Flutter. Make the UI consistent across all screens and use reusable components.

## Brand and design system

- App name: PLASVORA
- Tagline: “Turn Plastic Into Possibility.”
- Palette: forest green `#205B46`, deep green `#153D32`, sage `#E8EFE5`, ivory `#F8F8F2`, white `#FFFFFF`, primary text `#20312A`, secondary text `#65746B`, mint `#C7E2C8`, warning amber `#D99A35`.
- Rounded card corners around 16–22 px; generous spacing; thin borders or soft shadows; legible text; restrained icons.
- Use a clean modern sans-serif typeface. Prioritize mobile readability.
- Design for a 393 × 852 dp Android screen and make layouts responsive for common phone widths.
- Use realistic images of sorted plastic caps, PET flakes, HDPE bottles, and recycled-plastic crafts. Avoid fabricated environmental statistics or false AI confidence values.

## Generate these screens

1. **Beranda / Home**
   - Header with PLASVORA icon/wordmark, notification icon if needed, and profile avatar.
   - Hero with an eco/nature image and a concise message such as “Beri Plastik Kesempatan Kedua”.
   - Main CTA “Analisis Plastik”.
   - Three quick-action cards: “Analisis Plastik”, “Cari Material”, “Tawarkan Plastik”.
   - Compact impact cards separately labeled “Terdaftar”, “Diserahkan”, and “Dikonfirmasi Dimanfaatkan”; label all sample metrics as demo data.
   - Marketplace preview with two material cards.
   - Bottom navigation: Beranda, Analisis, Marketplace, Aktivitas.

2. **Analisis Plastik**
   - Screen title, concise explanation, large photo capture/upload area, and fields for “Jenis plastik (jika diketahui)”, “Berat (kg)”, “Kondisi”, and “Catatan”.
   - Primary CTA “Analisis Material”.
   - Include a gentle note: “Hasil identifikasi dari foto merupakan perkiraan.”

3. **Hasil Analisis**
   - Photo preview, estimated material category and a clear uncertainty note.
   - Do not invent confidence percentages unless actual model output is available.
   - Recommendation cards with image, title, difficulty label, one-line description, and arrow.
   - Example ideas: aksesori dari tutup botol, mozaik/dekorasi, atau opsi penyaluran ke pengolah yang sesuai.
   - Primary CTA “Cari Penerima Material”; secondary action “Simpan Ide” if space permits.

4. **Marketplace**
   - Top search field “Cari jenis plastik, material, atau lokasi”.
   - Horizontal filter chips: Jenis, Kondisi, Berat, Jarak.
   - Category chips: Semua, PET, HDPE, PP, LDPE, Lainnya.
   - Two-column material cards similar in scanability to the supplied marketplace screenshot, but with PLASVORA’s green/ivory visual identity.
   - Each card shows photo, name, weight, condition, general location if available, price or “Gratis”, and availability status. Do not include fake star ratings, sold counts, discounts, or promotional badges.
   - Include a clear button/FAB “+ Tawarkan Material”.

5. **Detail Material**
   - Large material image, material name/category, weight, condition, price/free label, general location, description, and primary CTA “Ajukan Material”.

6. **Buat Listing Material**
   - Clean form for material name/category, photo, weight, condition, price/free, general location, description, and CTA “Publikasikan”. Show clear field labels and validation space.

7. **Kebutuhan & Smart Matching**
   - Browse material needs and create a need.
   - A match result card should explain why it matches: category compatible, required quantity, accepted condition, and nearby location if known.
   - Use labels such as “Rekomendasi Kecocokan”, not “Transaksi Berhasil”.

8. **Aktivitas / Perjalanan Material**
   - Timeline or status list showing “Menunggu”, “Disetujui”, “Diserahkan”, and “Pemanfaatan Dikonfirmasi”.
   - Clear status chips, dates, weight, and next action.

9. **Dashboard Dampak**
   - Separate metric cards for offered material, confirmed handover, and confirmed utilization. Use demo data labels. Do not show unsupported CO₂ or tree-equivalent claims.

10. **Profil**
   - Profile header, general location, links to own listings, own requests, and activity history.

## Important interaction and layout requirements

- Use the same app bar, bottom navigation, card styling, button style, spacing, and colors throughout.
- Prioritize Home, Analyze, Marketplace, Material Detail, and Activity if not all screens can be fully designed.
- Include empty, loading, error, and form-validation states where relevant.
- Do not add payment processing, delivery logistics, real-time chat, points/rewards, or complex admin screens.
- Avoid making this look like a travel app; use the first screenshot only for visual tone and the second only for marketplace layout hierarchy.
- Output high-fidelity mobile screens and reusable component guidance that a Flutter developer can implement.
