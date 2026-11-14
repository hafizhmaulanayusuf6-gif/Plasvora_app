import '../core/network/api_client.dart';
import '../core/network/api_config.dart';
import '../models/user_profile.dart';

abstract class AuthRepository {
  Future<UserProfile> login({required String email, required String password});
  Future<UserProfile> register({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
  });
  Future<UserProfile?> getCurrentUser();
  Future<void> logout();
  Future<bool> isAuthenticated();
}

class ApiAuthRepository implements AuthRepository {
  final ApiClient apiClient;

  ApiAuthRepository({required this.apiClient});

  @override
  Future<UserProfile> login({
    required String email,
    required String password,
  }) async {
    final response = await apiClient.post(
      ApiConfig.login,
      body: {
        'email': email,
        'password': password,
      },
      requiresAuth: false,
    );

    if (response is Map<String, dynamic> && response['data'] != null) {
      final data = response['data'] as Map<String, dynamic>;
      final token = data['token'] as String?;
      if (token != null) {
        await apiClient.saveToken(token);
      }
      return UserProfile.fromJson(data['user'] as Map<String, dynamic>);
    }
    throw ApiException('Format respons autentikasi tidak valid');
  }

  @override
  Future<UserProfile> register({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
  }) async {
    final response = await apiClient.post(
      ApiConfig.register,
      body: {
        'name': name,
        'email': email,
        'password': password,
        'password_confirmation': passwordConfirmation,
      },
      requiresAuth: false,
    );

    if (response is Map<String, dynamic> && response['data'] != null) {
      final data = response['data'] as Map<String, dynamic>;
      final token = data['token'] as String?;
      if (token != null) {
        await apiClient.saveToken(token);
      }
      return UserProfile.fromJson(data['user'] as Map<String, dynamic>);
    }
    throw ApiException('Format respons registrasi tidak valid');
  }

  @override
  Future<UserProfile?> getCurrentUser() async {
    final token = await apiClient.getToken();
    if (token == null || token.isEmpty) return null;

    try {
      final response = await apiClient.get(ApiConfig.me, requiresAuth: true);
      if (response is Map<String, dynamic> && response['data'] != null) {
        return UserProfile.fromJson(response['data'] as Map<String, dynamic>);
      }
      return null;
    } on ApiException catch (e) {
      // HTTP 401 Unauthorized: Sesi tidak valid / token telah dicabut backend.
      // Hapus token dari secure storage & ApiClient, lalu kembalikan null agar diarahkan ke Login.
      if (e.statusCode == 401) {
        await apiClient.deleteToken();
        return null;
      }
      // HTTP 403 Forbidden: Hak akses ditolak oleh server, TETAPI identitas/token masih valid.
      // JANGAN hapus token lokal dan JANGAN logout otomatis.
      // Lempar ApiException agar ViewModel melaporkan status akses ditolak.
      // HTTP 500, 503, dll: Error server, token lokal TETAP DIPERTAHANKAN.
      rethrow;
    } catch (_) {
      // Untuk kendala jaringan, socket exception, timeout: jangan hapus token lokal
      rethrow;
    }
  }

  @override
  Future<void> logout() async {
    try {
      await apiClient.post(ApiConfig.logout, requiresAuth: true);
    } catch (_) {
      // Abaikan jika token di server sudah invalid
    } finally {
      await apiClient.deleteToken();
    }
  }

  @override
  Future<bool> isAuthenticated() async {
    final token = await apiClient.getToken();
    return token != null && token.isNotEmpty;
  }
}

