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
    } catch (_) {
      await apiClient.clearToken();
      return null;
    }
    return null;
  }

  @override
  Future<void> logout() async {
    try {
      await apiClient.post(ApiConfig.logout, requiresAuth: true);
    } catch (_) {
      // Abaikan jika token di server sudah invalid
    } finally {
      await apiClient.clearToken();
    }
  }

  @override
  Future<bool> isAuthenticated() async {
    final token = await apiClient.getToken();
    return token != null && token.isNotEmpty;
  }
}

