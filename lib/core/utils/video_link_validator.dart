/// Client-side validator for external tutorial video links in Galeri Karya.
///
/// Mirrors the backend `AllowedVideoUrl` rule:
/// - HTTPS only
/// - No URL credentials (userInfo)
/// - Host must exactly match or be a true subdomain of an allowed host
class VideoLinkValidator {
  VideoLinkValidator._();

  static const Set<String> allowedHosts = {
    'youtube.com',
    'youtu.be',
    'tiktok.com',
    'instagram.com',
  };

  static const int maxLength = 500;

  static bool isAllowedHost(String host) {
    final normalized = host.toLowerCase().trim().replaceAll(RegExp(r'\.+$'), '');
    if (normalized.isEmpty) return false;

    for (final allowed in allowedHosts) {
      if (normalized == allowed || normalized.endsWith('.$allowed')) {
        return true;
      }
    }
    return false;
  }

  /// Returns `null` when valid, or an Indonesian user-facing validation message.
  static String? validate(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) {
      return 'Tautan video tidak boleh kosong.';
    }
    if (trimmed.length > maxLength) {
      return 'Tautan video maksimal $maxLength karakter.';
    }
    if (RegExp(r'[\s\x00-\x1F\x7F]').hasMatch(trimmed)) {
      return 'Tautan video tidak boleh mengandung spasi.';
    }

    final uri = Uri.tryParse(trimmed);
    if (uri == null || !uri.hasScheme || !uri.hasAuthority) {
      return 'Format tautan video tidak valid.';
    }

    if (uri.scheme.toLowerCase() != 'https') {
      return 'Tautan video wajib menggunakan HTTPS (https://).';
    }

    if (uri.userInfo.isNotEmpty) {
      return 'Tautan video tidak diperbolehkan memuat kredensial.';
    }

    final host = uri.host;
    if (host.isEmpty || !isAllowedHost(host)) {
      return 'Tautan video hanya diperbolehkan dari YouTube, TikTok, atau Instagram.';
    }

    return null;
  }

  static bool isValid(String raw) => validate(raw) == null;

  /// Extracts a clean display host (e.g. `youtube.com`, `vm.tiktok.com`).
  static String extractDisplayHost(String raw) {
    final uri = Uri.tryParse(raw.trim());
    if (uri == null || uri.host.isEmpty) {
      return 'tautan eksternal';
    }
    return uri.host.toLowerCase().replaceFirst(RegExp(r'^www\.'), '');
  }
}
