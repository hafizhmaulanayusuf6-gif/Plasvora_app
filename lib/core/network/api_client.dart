import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import 'package:path_provider/path_provider.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final Map<String, dynamic>? errors;

  ApiException(this.message, {this.statusCode, this.errors});

  @override
  String toString() {
    if (statusCode != null) {
      return 'ApiException: $message (Status: $statusCode)';
    }
    return 'ApiException: $message';
  }
}

/// Abstraksi penyimpanan token autentikasi (TokenStorage).
///
/// Menyediakan method lengkap untuk menyimpan, membaca, dan menghapus
/// Sanctum Bearer Token secara terisolasi dan persisten.
abstract class TokenStorage {
  Future<String?> getToken();
  Future<void> saveToken(String token);
  Future<void> deleteToken();
  Future<void> clearToken();
}

typedef AuthTokenStorage = TokenStorage;

class InMemoryAuthTokenStorage implements TokenStorage {
  String? _token;

  @override
  Future<String?> getToken() async => _token;

  @override
  Future<void> saveToken(String token) async => _token = token;

  @override
  Future<void> deleteToken() async => _token = null;

  @override
  Future<void> clearToken() async => deleteToken();
}

/// Implementasi penyimpanan token terenkripsi level sistem operasi.
///
/// Menggunakan Android Keystore melalui `FlutterSecureStorage` dengan opsi
/// `encryptedSharedPreferences: true` dan `resetOnError: true` agar kompatibel
/// penuh dengan Android 7.0 (API 24, Samsung Galaxy A7).
///
/// Juga menyediakan alur migrasi transparan jika berkas token sandbox sebelumnya
/// (`.plasvora_auth_token`) ditemukan di memori perangkat.
class SecureAuthTokenStorage implements TokenStorage {
  static const String _keyToken = 'plasvora_auth_token_secure';
  static const String _legacyTokenFileName = '.plasvora_auth_token';

  final FlutterSecureStorage _storage;
  final Future<Directory> Function()? directoryProvider;
  String? _cachedToken;
  bool _isInitialized = false;

  SecureAuthTokenStorage({
    FlutterSecureStorage? secureStorage,
    this.directoryProvider,
  })  : _storage = secureStorage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(
                encryptedSharedPreferences: true,
                resetOnError: true,
              ),
            );

  /// Memeriksa dan memigrasikan token lama dari `.plasvora_auth_token` jika ada.
  /// Berkas lama HANYA dihapus jika token berhasil disimpan dan diverifikasi
  /// dari secure storage.
  Future<void> _migrateLegacyTokenIfNeeded() async {
    try {
      Directory dir;
      final provider = directoryProvider;
      if (provider != null) {
        dir = await provider();
      } else {
        try {
          dir = await getApplicationDocumentsDirectory();
        } catch (_) {
          dir = Directory.systemTemp;
        }
      }

      final legacyFile = File('${dir.path}/$_legacyTokenFileName');
      if (await legacyFile.exists()) {
        final legacyContent = await legacyFile.readAsString();
        final trimmed = legacyContent.trim();
        if (trimmed.isNotEmpty) {
          // 1. Simpan ke secure storage
          await _storage.write(key: _keyToken, value: trimmed);
          // 2. Verifikasi keterbacaan kembali dari secure storage
          final verified = await _storage.read(key: _keyToken);
          if (verified == trimmed) {
            // 3. Hapus berkas lama hanya setelah sukses terverifikasi
            await legacyFile.delete();
          }
        } else {
          await legacyFile.delete();
        }
      }
    } catch (_) {
      // Jika terjadi error pada migrasi, jangan hapus file lama
    }
  }

  @override
  Future<String?> getToken() async {
    if (_isInitialized && _cachedToken != null) {
      return _cachedToken;
    }

    try {
      await _migrateLegacyTokenIfNeeded();

      final token = await _storage.read(key: _keyToken);
      if (token != null && token.trim().isNotEmpty) {
        _cachedToken = token.trim();
      } else {
        _cachedToken = null;
      }
    } catch (_) {
      _cachedToken = null;
    } finally {
      _isInitialized = true;
    }

    return _cachedToken;
  }

  @override
  Future<void> saveToken(String token) async {
    final trimmed = token.trim();
    if (trimmed.isEmpty) return;

    _cachedToken = trimmed;
    _isInitialized = true;

    try {
      await _storage.write(key: _keyToken, value: trimmed);
    } catch (_) {
      // Token tetap berada di memori cache sesi aktif jika operasi IO terkendala
    }
  }

  @override
  Future<void> deleteToken() async {
    _cachedToken = null;
    _isInitialized = true;

    try {
      await _storage.delete(key: _keyToken);
    } catch (_) {}

    // Hapus juga file legacy jika masih tersisa
    try {
      Directory dir;
      final provider = directoryProvider;
      if (provider != null) {
        dir = await provider();
      } else {
        try {
          dir = await getApplicationDocumentsDirectory();
        } catch (_) {
          dir = Directory.systemTemp;
        }
      }
      final legacyFile = File('${dir.path}/$_legacyTokenFileName');
      if (await legacyFile.exists()) {
        await legacyFile.delete();
      }
    } catch (_) {}
  }

  @override
  Future<void> clearToken() => deleteToken();
}

/// Alias kompatibilitas untuk kode atau pengujian yang merujuk PersistentAuthTokenStorage
class PersistentAuthTokenStorage extends SecureAuthTokenStorage {
  PersistentAuthTokenStorage({
    super.secureStorage,
    super.directoryProvider,
  });
}

class ApiClient {
  final http.Client _client;
  final TokenStorage tokenStorage;

  ApiClient({
    http.Client? client,
    TokenStorage? tokenStorage,
  })  : _client = client ?? http.Client(),
        tokenStorage = tokenStorage ?? SecureAuthTokenStorage();

  /// Factory asynchronous untuk menginisialisasi ApiClient dengan SecurityContext
  /// yang menyertakan sertifikat root resmi ISRG Root X1 (Let's Encrypt).
  ///
  /// Tetap mempertahankan withTrustedRoots: true agar seluruh root certificate
  /// sistem Android tetap aktif. Memastikan kompatibilitas TLS handshake pada
  /// Android 7.0 (API 24) tanpa mengorbankan validasi sertifikat maupun hostname.
  static Future<ApiClient> create({
    http.Client? client,
    TokenStorage? tokenStorage,
  }) async {
    final effectiveStorage = tokenStorage ?? SecureAuthTokenStorage();
    // Inisialisasi awal token dari penyimpanan lokal
    await effectiveStorage.getToken();

    if (client != null) {
      return ApiClient(client: client, tokenStorage: effectiveStorage);
    }

    try {
      final certByteData = await rootBundle.load('assets/certificates/isrgrootx1.pem');
      final certBytes = certByteData.buffer.asUint8List(
        certByteData.offsetInBytes,
        certByteData.lengthInBytes,
      );

      if (certBytes.isEmpty) {
        throw StateError('File sertifikat assets/certificates/isrgrootx1.pem kosong.');
      }

      final securityContext = SecurityContext(withTrustedRoots: true);
      securityContext.setTrustedCertificatesBytes(certBytes);
      final ioHttpClient = HttpClient(context: securityContext);

      return ApiClient(
        client: IOClient(ioHttpClient),
        tokenStorage: effectiveStorage,
      );
    } catch (e) {
      // Tangani kegagalan secara eksplisit tanpa silent fallback
      throw StateError(
        'Gagal mengonfigurasi TLS Trust Store dengan ISRG Root X1: $e\n'
        'Pastikan asset "assets/certificates/isrgrootx1.pem" terdaftar di pubspec.yaml dan valid.',
      );
    }
  }

  Future<String?> getToken() => tokenStorage.getToken();
  Future<void> saveToken(String token) => tokenStorage.saveToken(token);
  Future<void> deleteToken() => tokenStorage.deleteToken();
  Future<void> clearToken() => tokenStorage.clearToken();

  Future<Map<String, String>> _headers({bool requiresAuth = true}) async {
    final headers = <String, String>{
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      'ngrok-skip-browser-warning': 'true',
    };

    if (requiresAuth) {
      final token = await getToken();
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
    }
    return headers;
  }

  Future<dynamic> get(String url, {bool requiresAuth = false}) async {
    try {
      final response = await _client.get(
        Uri.parse(url),
        headers: await _headers(requiresAuth: requiresAuth),
      ).timeout(const Duration(seconds: 30));
      return _processResponse(response);
    } on SocketException {
      throw ApiException('Tidak dapat terhubung ke server backend');
    } on TimeoutException {
      throw ApiException('Waktu tunggu koneksi ke server habis (timeout).');
    } on http.ClientException catch (e) {
      throw ApiException('Gagal berkomunikasi dengan backend: ${e.message}');
    }
  }

  Future<dynamic> post(
    String url, {
    Map<String, dynamic>? body,
    bool requiresAuth = true,
  }) async {
    try {
      final response = await _client.post(
        Uri.parse(url),
        headers: await _headers(requiresAuth: requiresAuth),
        body: body != null ? jsonEncode(body) : null,
      ).timeout(const Duration(seconds: 30));
      return _processResponse(response);
    } on SocketException {
      throw ApiException('Tidak dapat terhubung ke server backend');
    } on TimeoutException {
      throw ApiException('Waktu tunggu koneksi ke server habis (timeout).');
    } on http.ClientException catch (e) {
      throw ApiException('Gagal berkomunikasi dengan backend: ${e.message}');
    }
  }

  /// Mengirim request multipart/form-data untuk upload file gambar
  Future<dynamic> postMultipart(
    String url, {
    Map<String, String>? fields,
    String? fileField,
    String? filePath,
    bool requiresAuth = true,
  }) async {
    try {
      final request = http.MultipartRequest('POST', Uri.parse(url));

      request.headers['Accept'] = 'application/json';
      request.headers['ngrok-skip-browser-warning'] = 'true';
      if (requiresAuth) {
        final token = await getToken();
        if (token != null && token.isNotEmpty) {
          request.headers['Authorization'] = 'Bearer $token';
        }
      }

      if (fields != null) {
        request.fields.addAll(fields);
      }

      if (fileField != null && filePath != null && filePath.isNotEmpty) {
        final file = File(filePath);
        if (await file.exists()) {
          request.files.add(
            await http.MultipartFile.fromPath(fileField, filePath),
          );
        }
      }

      final streamedResponse = await _client.send(request).timeout(
        const Duration(seconds: 90),
        onTimeout: () => throw TimeoutException('Waktu tunggu koneksi ke server habis (timeout).'),
      );
      final response = await http.Response.fromStream(streamedResponse);
      return _processResponse(response);
    } on SocketException {
      throw ApiException('Tidak dapat terhubung ke server backend');
    } on TimeoutException {
      throw ApiException('Waktu tunggu upload ke server habis (timeout).');
    } on http.ClientException catch (e) {
      throw ApiException('Gagal berkomunikasi dengan backend: ${e.message}');
    }
  }

  Future<dynamic> patch(
    String url, {
    Map<String, dynamic>? body,
    bool requiresAuth = true,
  }) async {
    try {
      final response = await _client.patch(
        Uri.parse(url),
        headers: await _headers(requiresAuth: requiresAuth),
        body: body != null ? jsonEncode(body) : null,
      ).timeout(const Duration(seconds: 30));
      return _processResponse(response);
    } on SocketException {
      throw ApiException('Tidak dapat terhubung ke server backend');
    } on TimeoutException {
      throw ApiException('Waktu tunggu koneksi ke server habis (timeout).');
    } on http.ClientException catch (e) {
      throw ApiException('Gagal berkomunikasi dengan backend: ${e.message}');
    }
  }

  Future<dynamic> delete(String url, {bool requiresAuth = true}) async {
    try {
      final response = await _client.delete(
        Uri.parse(url),
        headers: await _headers(requiresAuth: requiresAuth),
      ).timeout(const Duration(seconds: 30));
      return _processResponse(response);
    } on SocketException {
      throw ApiException('Tidak dapat terhubung ke server backend');
    } on TimeoutException {
      throw ApiException('Waktu tunggu koneksi ke server habis (timeout).');
    } on http.ClientException catch (e) {
      throw ApiException('Gagal berkomunikasi dengan backend: ${e.message}');
    }
  }

  dynamic _processResponse(http.Response response) {
    dynamic jsonBody;
    try {
      // Gunakan UTF-8 decoding eksplisit agar karakter non-ASCII tidak rusak
      final bodyStr = utf8.decode(response.bodyBytes);
      jsonBody = jsonDecode(bodyStr);
    } catch (_) {
      jsonBody = null;
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonBody;
    }

    String errorMessage = 'Terjadi kesalahan pada server';
    Map<String, dynamic>? errors;

    if (jsonBody is Map<String, dynamic>) {
      if (jsonBody['message'] is String) {
        errorMessage = jsonBody['message'];
      }
      if (jsonBody['errors'] is Map<String, dynamic>) {
        errors = jsonBody['errors'];
      }
    }

    throw ApiException(
      errorMessage,
      statusCode: response.statusCode,
      errors: errors,
    );
  }
}
