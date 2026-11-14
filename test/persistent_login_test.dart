import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:plasvora/core/network/api_client.dart';
import 'package:plasvora/core/network/api_config.dart';
import 'package:plasvora/repositories/auth_repository.dart';
import 'package:plasvora/viewmodels/auth_viewmodel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  final Map<String, String> mockSecureStorage = {};
  bool secureStorageShouldThrow = false;

  setUpAll(() {
    const channel = MethodChannel('plugins.it_nomads.com/flutter_secure_storage');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
      if (secureStorageShouldThrow) {
        throw PlatformException(
          code: 'KEYSTORE_ERROR',
          message: 'Android Keystore inaccessible',
        );
      }

      switch (methodCall.method) {
        case 'read':
          final key = methodCall.arguments['key'] as String?;
          return key != null ? mockSecureStorage[key] : null;
        case 'write':
          final key = methodCall.arguments['key'] as String;
          final value = methodCall.arguments['value'] as String;
          mockSecureStorage[key] = value;
          return null;
        case 'delete':
          final key = methodCall.arguments['key'] as String?;
          if (key != null) mockSecureStorage.remove(key);
          return null;
        case 'deleteAll':
          mockSecureStorage.clear();
          return null;
        case 'containsKey':
          final key = methodCall.arguments['key'] as String?;
          return key != null && mockSecureStorage.containsKey(key);
        default:
          return null;
      }
    });
  });

  setUp(() async {
    mockSecureStorage.clear();
    secureStorageShouldThrow = false;
    tempDir = await Directory.systemTemp.createTemp('plasvora_secure_test_');
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('Penyempurnaan Keamanan Token Storage (SecureAuthTokenStorage)', () {
    // 1. Token berhasil disimpan dan dibaca kembali
    test('1. Token berhasil disimpan dan dibaca kembali menggunakan secure storage', () async {
      final storage = SecureAuthTokenStorage(
        directoryProvider: () async => tempDir,
      );

      expect(await storage.getToken(), isNull);

      const testToken = '1|sanctum_secure_token_abc123';
      await storage.saveToken(testToken);

      final result = await storage.getToken();
      expect(result, equals(testToken));
      expect(mockSecureStorage['plasvora_auth_token_secure'], equals(testToken));
    });

    // 2. Token tetap tersedia setelah storage object dibuat ulang
    test('2. Token tetap tersedia setelah storage object dibuat ulang (persistent)', () async {
      final storage1 = SecureAuthTokenStorage(
        directoryProvider: () async => tempDir,
      );
      await storage1.saveToken('persistent_token_xyz');

      // Simulasi aplikasi restart: buat instance storage baru
      final storage2 = SecureAuthTokenStorage(
        directoryProvider: () async => tempDir,
      );
      final restored = await storage2.getToken();
      expect(restored, equals('persistent_token_xyz'));
    });

    // Migrasi file lama jika ada
    test('Migrasi berkas lama: token dari .plasvora_auth_token dipindahkan ke secure storage', () async {
      // Siapkan berkas legacy
      final legacyFile = File('${tempDir.path}/.plasvora_auth_token');
      await legacyFile.writeAsString('legacy_file_token_789');

      final storage = SecureAuthTokenStorage(
        directoryProvider: () async => tempDir,
      );

      // Saat getToken dipanggil, migrasi berjalan transparan
      final token = await storage.getToken();
      expect(token, equals('legacy_file_token_789'));

      // Token telah berpindah ke secure storage
      expect(mockSecureStorage['plasvora_auth_token_secure'], equals('legacy_file_token_789'));

      // Berkas legacy telah dihapus setelah verifikasi berhasil
      expect(await legacyFile.exists(), isFalse);
    });

    // 13. Kegagalan secure storage ditangani dengan benar
    test('13. Kegagalan secure storage ditangani dengan benar dan tidak menganggap token valid', () async {
      final storage = SecureAuthTokenStorage(
        directoryProvider: () async => tempDir,
      );

      secureStorageShouldThrow = true;
      final token = await storage.getToken();
      expect(token, isNull);
    });
  });

  group('Session Restoration & Perilaku Status HTTP', () {
    // 3. Token valid memulihkan sesi
    test('3. Token valid berhasil memulihkan sesi pengguna ke profil aktif', () async {
      final mockClient = MockClient((request) async {
        if (request.url.toString() == ApiConfig.me) {
          expect(request.headers['Authorization'], equals('Bearer valid_token_001'));
          return http.Response(
            jsonEncode({
              'success': true,
              'data': {
                'id': 10,
                'name': 'Budi Santoso',
                'email': 'budi@plasvora.id',
              }
            }),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        }
        return http.Response('Not Found', 404);
      });

      final storage = InMemoryAuthTokenStorage();
      await storage.saveToken('valid_token_001');

      final apiClient = ApiClient(client: mockClient, tokenStorage: storage);
      final authRepo = ApiAuthRepository(apiClient: apiClient);
      final viewModel = AuthViewModel(authRepository: authRepo);

      await Future.delayed(const Duration(milliseconds: 50));

      expect(viewModel.state, equals(AuthState.authenticated));
      expect(viewModel.isAuthenticated, isTrue);
      expect(viewModel.currentUser?.name, equals('Budi Santoso'));
    });

    // 4. Token tidak tersedia mengarahkan pengguna ke login
    test('4. Token tidak tersedia mengarahkan status autentikasi ke unauthenticated', () async {
      final storage = InMemoryAuthTokenStorage();
      final apiClient = ApiClient(tokenStorage: storage);
      final authRepo = ApiAuthRepository(apiClient: apiClient);
      final viewModel = AuthViewModel(authRepository: authRepo);

      await Future.delayed(const Duration(milliseconds: 50));

      expect(viewModel.state, equals(AuthState.unauthenticated));
      expect(viewModel.isAuthenticated, isFalse);
      expect(viewModel.currentUser, isNull);
    });

    // 5. HTTP 401 menghapus token
    test('5. HTTP 401 Unauthorized menghapus token dari storage dan mengarahkan ke unauthenticated', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({'message': 'Unauthenticated.'}),
          401,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      });

      final storage = InMemoryAuthTokenStorage();
      await storage.saveToken('invalid_revoked_token');

      final apiClient = ApiClient(client: mockClient, tokenStorage: storage);
      final authRepo = ApiAuthRepository(apiClient: apiClient);
      final viewModel = AuthViewModel(authRepository: authRepo);

      await Future.delayed(const Duration(milliseconds: 50));

      // Token lokal HARUS DIHAPUS pada 401
      expect(await storage.getToken(), isNull);
      expect(viewModel.state, equals(AuthState.unauthenticated));
      expect(viewModel.currentUser, isNull);
    });

    // 6. HTTP 403 tidak menghapus token
    test('6. HTTP 403 Forbidden TIDAK menghapus token dan tidak otomatis logout', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({'message': 'Akses ditolak untuk profil ini'}),
          403,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      });

      final storage = InMemoryAuthTokenStorage();
      await storage.saveToken('valid_token_but_forbidden');

      final apiClient = ApiClient(client: mockClient, tokenStorage: storage);
      final authRepo = ApiAuthRepository(apiClient: apiClient);
      final viewModel = AuthViewModel(authRepository: authRepo);

      await Future.delayed(const Duration(milliseconds: 50));

      // Token lokal HARUS TETAP ADA pada 403 (tidak boleh dihapus)
      expect(await storage.getToken(), equals('valid_token_but_forbidden'));
      // State berubah menjadi error, BUKAN unauthenticated (tidak logout)
      expect(viewModel.state, equals(AuthState.error));
      expect(viewModel.errorMessage, contains('Akses ditolak'));
    });

    // 7. HTTP 500 tidak menghapus token
    test('7. HTTP 500 Internal Server Error TIDAK menghapus token', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({'message': 'Database connection error'}),
          500,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      });

      final storage = InMemoryAuthTokenStorage();
      await storage.saveToken('token_protected_500');

      final apiClient = ApiClient(client: mockClient, tokenStorage: storage);
      final authRepo = ApiAuthRepository(apiClient: apiClient);
      final viewModel = AuthViewModel(authRepository: authRepo);

      await Future.delayed(const Duration(milliseconds: 50));

      expect(await storage.getToken(), equals('token_protected_500'));
      expect(viewModel.state, equals(AuthState.connectionError));
      expect(viewModel.hasConnectionError, isTrue);
    });

    // 8. HTTP 503 tidak menghapus token
    test('8. HTTP 503 Service Unavailable TIDAK menghapus token', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({'message': 'Sedang pemeliharaan server'}),
          503,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      });

      final storage = InMemoryAuthTokenStorage();
      await storage.saveToken('token_protected_503');

      final apiClient = ApiClient(client: mockClient, tokenStorage: storage);
      final authRepo = ApiAuthRepository(apiClient: apiClient);
      final viewModel = AuthViewModel(authRepository: authRepo);

      await Future.delayed(const Duration(milliseconds: 50));

      expect(await storage.getToken(), equals('token_protected_503'));
      expect(viewModel.state, equals(AuthState.connectionError));
    });

    // 9. Timeout tidak menghapus token
    test('9. Timeout / SocketException TIDAK menghapus token', () async {
      final mockClient = MockClient((request) async {
        throw const SocketException('No route to host');
      });

      final storage = InMemoryAuthTokenStorage();
      await storage.saveToken('token_protected_socket');

      final apiClient = ApiClient(client: mockClient, tokenStorage: storage);
      final authRepo = ApiAuthRepository(apiClient: apiClient);
      final viewModel = AuthViewModel(authRepository: authRepo);

      await Future.delayed(const Duration(milliseconds: 50));

      expect(await storage.getToken(), equals('token_protected_socket'));
      expect(viewModel.state, equals(AuthState.connectionError));
    });

    // 10 & 11. Logout menghapus token dan token lama tidak dapat digunakan
    test('10 & 11. Logout menghapus token dan token lama tidak dapat digunakan', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({'success': true, 'message': 'Logged out'}),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      });

      final storage = InMemoryAuthTokenStorage();
      await storage.saveToken('token_before_logout');

      final apiClient = ApiClient(client: mockClient, tokenStorage: storage);
      final authRepo = ApiAuthRepository(apiClient: apiClient);
      final viewModel = AuthViewModel(authRepository: authRepo);

      await viewModel.logout();

      expect(await storage.getToken(), isNull);
      expect(viewModel.state, equals(AuthState.unauthenticated));
      expect(viewModel.currentUser, isNull);

      // Cek sesi ulang: tidak dapat login kembali dengan token lama
      await viewModel.checkAuthSession();
      expect(viewModel.state, equals(AuthState.unauthenticated));
    });

    // 12. Restore session tidak berjalan berulang kali secara bersamaan (anti-race condition)
    test('12. Restore session tidak berjalan berulang kali secara bersamaan (single flight)', () async {
      int apiCallCount = 0;
      final mockClient = MockClient((request) async {
        apiCallCount++;
        await Future.delayed(const Duration(milliseconds: 30));
        return http.Response(
          jsonEncode({
            'success': true,
            'data': {
              'id': 1,
              'name': 'User Anti Race',
              'email': 'antirace@plasvora.id',
            }
          }),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      });

      final storage = InMemoryAuthTokenStorage();
      await storage.saveToken('race_test_token');

      final apiClient = ApiClient(client: mockClient, tokenStorage: storage);
      final authRepo = ApiAuthRepository(apiClient: apiClient);

      // Buat ViewModel tapi panggil checkAuthSession beberapa kali secara bersamaan
      final viewModel = AuthViewModel(authRepository: authRepo);
      final f1 = viewModel.checkAuthSession();
      final f2 = viewModel.checkAuthSession();
      final f3 = viewModel.checkAuthSession();

      await Future.wait([f1, f2, f3]);

      // Endpoint backend /me hanya dipanggil tepat 1 kali
      expect(apiCallCount, equals(1));
      expect(viewModel.state, equals(AuthState.authenticated));
    });
  });
}
