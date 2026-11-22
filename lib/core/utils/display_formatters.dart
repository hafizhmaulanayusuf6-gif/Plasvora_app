/// Helper murni lapisan presentasi (tidak pernah mengubah data tersimpan atau payload backend).
class DisplayFormatters {
  DisplayFormatters._();

  /// Menghapus segmen lokasi berurutan yang identik (case-insensitive),
  /// mis. "BOJONGHERANG, CIANJUR, CIANJUR, JAWA BARAT" -> "BOJONGHERANG, CIANJUR, JAWA BARAT".
  static String deduplicateLocationLabel(String? raw) {
    if (raw == null) return '';
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return '';

    final parts = trimmed.split(',');
    final result = <String>[];
    String? prevNormalized;

    for (final part in parts) {
      final cleaned = part.trim().replaceAll(RegExp(r'\s+'), ' ');
      if (cleaned.isEmpty) continue;
      final normalized = cleaned.toLowerCase();
      if (normalized == prevNormalized) continue;
      result.add(cleaned);
      prevNormalized = normalized;
    }

    return result.join(', ');
  }

  /// Memformat estimasi pengiriman (ETD) dari kurir ke Bahasa Indonesia yang rapi.
  /// Mengembalikan "Estimasi belum tersedia" bila backend tidak menyediakan ETD.
  static String formatIndonesianEtd(String? raw) {
    if (raw == null) return 'Estimasi belum tersedia';
    final trimmed = raw.trim();
    if (trimmed.isEmpty || RegExp(r'^[\-\s]+$').hasMatch(trimmed)) {
      return 'Estimasi belum tersedia';
    }

    var text = trimmed
        .replaceAll(RegExp(r'\bdays?\b', caseSensitive: false), 'hari')
        .replaceAll(RegExp(r'\bhari\b', caseSensitive: false), 'hari')
        .replaceAll(RegExp(r'\bhours?\b', caseSensitive: false), 'jam')
        .replaceAll(RegExp(r'\bjam\b', caseSensitive: false), 'jam')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    if (RegExp(r'^\d+(?:\s*-\s*\d+)?$').hasMatch(text)) {
      text = '$text hari';
    }

    if (text.toLowerCase().startsWith('estimasi')) {
      return text;
    }
    return 'Estimasi $text';
  }

  /// Mengekstrak angka hari minimum dari ETD aktual (mis. "2-3 day" -> 2).
  /// Mengembalikan null jika ETD kosong atau tidak dapat dibandingkan secara objektif.
  static int? parseMinEtdDays(String? raw) {
    if (raw == null) return null;
    final trimmed = raw.trim().toLowerCase();
    if (trimmed.isEmpty) return null;
    // Jangan campurkan satuan jam dengan hari secara sembarangan
    if (trimmed.contains('jam') || trimmed.contains('hour')) {
      return 0;
    }
    final match = RegExp(r'(\d+)').firstMatch(trimmed);
    if (match == null) return null;
    return int.tryParse(match.group(1)!);
  }

  /// Meringkas nama kurir verbose hanya untuk tampilan UI.
  /// Nilai courierCode dan service asli yang dikirim ke backend tidak pernah diubah.
  static String formatShortCourierTitle({
    required String courierName,
    required String courierCode,
    required String service,
  }) {
    final code = courierCode.trim().toLowerCase();
    final svc = service.trim();
    String shortName;

    switch (code) {
      case 'jne':
        shortName = 'JNE';
        break;
      case 'jnt':
        shortName = 'J&T Express';
        break;
      case 'sicepat':
        shortName = 'SiCepat';
        break;
      case 'pos':
        shortName = 'Pos Indonesia';
        break;
      case 'tiki':
        shortName = 'TIKI';
        break;
      case 'anteraja':
        shortName = 'AnterAja';
        break;
      case 'ninja':
        shortName = 'Ninja Xpress';
        break;
      case 'lion':
        shortName = 'Lion Parcel';
        break;
      default:
        final cleanName = courierName.trim();
        shortName = cleanName.isNotEmpty ? cleanName : courierCode.toUpperCase();
    }

    if (svc.isEmpty) return shortName;
    if (code == 'jne' || code == 'tiki') {
      return '$shortName $svc';
    }
    return '$shortName ($svc)';
  }

  static const List<String> _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
    'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
  ];

  static String formatDateTime(DateTime dt) {
    final local = dt.toLocal();
    final hh = local.hour.toString().padLeft(2, '0');
    final mm = local.minute.toString().padLeft(2, '0');
    return '${local.day} ${_months[local.month - 1]} ${local.year} · $hh:$mm';
  }

  static String formatShortDate(DateTime dt) {
    final local = dt.toLocal();
    return '${local.day} ${_months[local.month - 1]} ${local.year}';
  }
}
