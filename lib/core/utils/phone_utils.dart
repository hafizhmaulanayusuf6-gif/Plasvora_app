/// Helper validasi & normalisasi nomor telepon Indonesia untuk kontak WhatsApp.
class PhoneUtils {
  PhoneUtils._();

  static final RegExp _indonesianMobilePattern = RegExp(
    r'^(?:\+?62|0)8[1-9][0-9]{7,11}$',
  );

  /// Normalisasi nomor Indonesia (`08...`, `62...`, `+62...`) ke digit-only `628...`.
  /// Mengembalikan null jika kosong atau tidak valid.
  static String? normalizeIndonesianPhone(String? raw) {
    if (raw == null) return null;
    final cleaned = raw.trim().replaceAll(RegExp(r'[\s\-\(\)\.]+'), '');
    if (cleaned.isEmpty) return null;
    if (!_indonesianMobilePattern.hasMatch(cleaned)) return null;

    if (cleaned.startsWith('+62')) {
      return cleaned.substring(1);
    }
    if (cleaned.startsWith('0')) {
      return '62${cleaned.substring(1)}';
    }
    return cleaned;
  }

  /// Validator untuk field nomor telepon opsional di form registrasi/profil.
  static String? validateOptionalIndonesianPhone(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    if (normalizeIndonesianPhone(value) == null) {
      return 'Format nomor tidak valid. Contoh: 081234567890 atau +6281234567890.';
    }
    return null;
  }

  /// Bangun URL WhatsApp resmi (`https://wa.me/62...`) dengan pesan ter-encode.
  /// Mengembalikan null jika nomor penjual tidak valid.
  static Uri? buildSellerWhatsAppUri({
    required String? sellerPhone,
    required String materialName,
  }) {
    final normalized = normalizeIndonesianPhone(sellerPhone);
    if (normalized == null) return null;

    final safeName = materialName.trim().isNotEmpty
        ? materialName.trim()
        : 'material plastik';
    final message =
        'Halo, saya tertarik dengan material $safeName yang Anda jual di Plasvora. Apakah masih tersedia?';
    final encodedMessage = Uri.encodeComponent(message);

    return Uri.parse('https://wa.me/$normalized?text=$encodedMessage');
  }

  /// Format nomor `628...` menjadi tampilan yang mudah dibaca (`+62 8...`).
  static String formatForDisplay(String? raw) {
    final normalized = normalizeIndonesianPhone(raw);
    if (normalized == null) return raw?.trim() ?? '';
    return '+$normalized';
  }
}
