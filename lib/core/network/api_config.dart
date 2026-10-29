class ApiConfig {
  /// Base URL backend Laravel.
  /// Gunakan 10.0.2.2 untuk Android emulator, 127.0.0.1 untuk web/desktop emulator/host.
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

  static String materialDetail(int id) => '$baseUrl/materials/$id';
  static String materialMatches(int id) => '$baseUrl/materials/$id/matches';
  static String materialRequestDetail(int id) => '$baseUrl/material-requests/$id';
  static String materialRequestMatches(int id) => '$baseUrl/material-requests/$id/matches';
  static String handoverRequestDetail(int id) => '$baseUrl/handover-requests/$id';
  static String updateHandoverStatus(int id) => '$baseUrl/handover-requests/$id/status';
}

