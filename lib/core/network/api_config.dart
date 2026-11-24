class ApiConfig {
  /// Base URL backend Laravel.
  /// Gunakan IP LAN laptop (misal http://192.168.0.146:8000/api) agar bisa diakses langsung dari HP fisik.
  /// Gunakan 10.0.2.2 untuk Android emulator, 127.0.0.1 jika menggunakan adb reverse / desktop.
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://127.0.0.1:8000/api',
  );

  // Auth endpoints
  static const String register = '$baseUrl/register';
  static const String login = '$baseUrl/login';
  static const String logout = '$baseUrl/logout';
  static const String me = '$baseUrl/me';

  // Materials & Requests
  static const String materials = '$baseUrl/materials';
  static const String materialRequests = '$baseUrl/material-requests';
  static const String impactSummary = '$baseUrl/impact-summary';
  static const String handoverRequests = '$baseUrl/handover-requests';
  static const String activities = '$baseUrl/activities';
  static const String analyses = '$baseUrl/analyses';

  // Addresses & Shipping (Stage 2)
  static const String addresses = '$baseUrl/addresses';
  static const String shippingDestinations = '$baseUrl/shipping/destinations';
  static const String shippingEstimate = '$baseUrl/shipping/estimate';

  // Orders & Transactions (Stage 3)
  static const String orders = '$baseUrl/orders';

  // Gallery ("Galeri Karya")
  static const String gallery = '$baseUrl/gallery';
  static const String myGallery = '$baseUrl/me/gallery';

  static String materialDetail(int id) => '$baseUrl/materials/$id';
  static String materialMatches(int id) => '$baseUrl/materials/$id/matches';
  static String materialRequestDetail(int id) => '$baseUrl/material-requests/$id';
  static String materialRequestMatches(int id) => '$baseUrl/material-requests/$id/matches';
  static String handoverRequestDetail(int id) => '$baseUrl/handover-requests/$id';
  static String updateHandoverStatus(int id) => '$baseUrl/handover-requests/$id/status';
  static String analysisDetail(int id) => '$baseUrl/analyses/$id';
  static String addressDetail(int id) => '$baseUrl/addresses/$id';
  static String orderDetail(int id) => '$baseUrl/orders/$id';
  static String orderCancel(int id) => '$baseUrl/orders/$id/cancel';
  static String orderRetryPayment(int id) => '$baseUrl/orders/$id/retry-payment';
  static String orderRefreshPayment(int id) => '$baseUrl/orders/$id/refresh-payment';
  static String orderShip(int id) => '$baseUrl/orders/$id/ship';
  static String orderConfirmDelivery(int id) => '$baseUrl/orders/$id/confirm-delivery';
  static String galleryDetail(int id) => '$baseUrl/gallery/$id';
  static String galleryLike(int id) => '$baseUrl/gallery/$id/like';
}

