import 'package:url_launcher/url_launcher.dart';

class PaymentLaunchResult {
  final bool launched;
  final String? errorMessage;

  const PaymentLaunchResult({
    required this.launched,
    this.errorMessage,
  });

  const PaymentLaunchResult.success()
      : launched = true,
        errorMessage = null;

  const PaymentLaunchResult.failure(String message)
      : launched = false,
        errorMessage = message;
}

/// Abstraksi peluncur URL Midtrans Snap yang memvalidasi skema HTTPS dan host tepercaya.
abstract class PaymentLauncher {
  static const Set<String> trustedMidtransHosts = {
    'app.sandbox.midtrans.com',
    'app.midtrans.com',
  };

  /// Validasi URL Midtrans Snap sebelum dibuka. Hanya izinkan HTTPS ke host resmi Midtrans Snap.
  static Uri? validateTrustedMidtransUrl(String? rawUrl) {
    if (rawUrl == null) return null;
    final trimmed = rawUrl.trim();
    if (trimmed.isEmpty) return null;

    final uri = Uri.tryParse(trimmed);
    if (uri == null || !uri.hasScheme || !uri.hasAuthority) return null;
    if (uri.scheme.toLowerCase() != 'https') return null;
    if (uri.userInfo.isNotEmpty) return null;

    final host = uri.host.toLowerCase();
    if (!trustedMidtransHosts.contains(host)) return null;

    return uri;
  }

  Future<PaymentLaunchResult> launchPaymentUrl(String? url);
}

typedef UrlLaunchExecutor = Future<bool> Function(
  Uri uri, {
  required LaunchMode mode,
});

class UrlPaymentLauncher implements PaymentLauncher {
  final UrlLaunchExecutor _executor;

  UrlPaymentLauncher({UrlLaunchExecutor? executor})
      : _executor = executor ?? _defaultExecutor;

  static Future<bool> _defaultExecutor(Uri uri, {required LaunchMode mode}) {
    return launchUrl(uri, mode: mode);
  }

  @override
  Future<PaymentLaunchResult> launchPaymentUrl(String? url) async {
    final uri = PaymentLauncher.validateTrustedMidtransUrl(url);
    if (uri == null) {
      return const PaymentLaunchResult.failure(
        'Tautan pembayaran tidak valid atau bukan dari domain resmi Midtrans.',
      );
    }

    try {
      final openedInApp = await _executor(
        uri,
        mode: LaunchMode.inAppBrowserView,
      );
      if (openedInApp) {
        return const PaymentLaunchResult.success();
      }
    } catch (_) {
      // Lanjut fallback ke browser eksternal hanya jika in-app browser tidak tersedia
    }

    try {
      final openedExternal = await _executor(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (openedExternal) {
        return const PaymentLaunchResult.success();
      }
      return const PaymentLaunchResult.failure(
        'Tidak dapat membuka halaman pembayaran. Pastikan browser tersedia di perangkat Anda.',
      );
    } catch (_) {
      return const PaymentLaunchResult.failure(
        'Gagal membuka halaman pembayaran Midtrans. Silakan coba lagi.',
      );
    }
  }
}
