import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final Map<String, dynamic>? errors;

  ApiException(this.message, {this.statusCode, this.errors});

  @override
  String toString() => 'ApiException: $message (Status: $statusCode)';
}

abstract class AuthTokenStorage {
  Future<String?> getToken();
  Future<void> saveToken(String token);
  Future<void> clearToken();
}

class InMemoryAuthTokenStorage implements AuthTokenStorage {
  String? _token;

  @override
  Future<String?> getToken() async => _token;

  @override
  Future<void> saveToken(String token) async => _token = token;

  @override
  Future<void> clearToken() async => _token = null;
}

class ApiClient {
  final http.Client _client;
  final AuthTokenStorage tokenStorage;

  ApiClient({
    http.Client? client,
    AuthTokenStorage? tokenStorage,
  })  : _client = client ?? http.Client(),
        tokenStorage = tokenStorage ?? InMemoryAuthTokenStorage();

  /// Factory asynchronous untuk menginisialisasi ApiClient dengan SecurityContext
  /// yang menyertakan sertifikat root resmi ISRG Root X1 (Let's Encrypt).
  ///
  /// Tetap mempertahankan withTrustedRoots: true agar seluruh root certificate
  /// sistem Android tetap aktif. Memastikan kompatibilitas TLS handshake pada
  /// Android 7.0 (API 24) tanpa mengorbankan validasi sertifikat maupun hostname.
  static Future<ApiClient> create({
    http.Client? client,
    AuthTokenStorage? tokenStorage,
  }) async {
    if (client != null) {
      return ApiClient(client: client, tokenStorage: tokenStorage);
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
        tokenStorage: tokenStorage,
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
      throw ApiException('Koneksi ke backend timeout saat memproses analisis.');
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
