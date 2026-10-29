import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

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

  Future<String?> getToken() => tokenStorage.getToken();
  Future<void> saveToken(String token) => tokenStorage.saveToken(token);
  Future<void> clearToken() => tokenStorage.clearToken();

  Future<Map<String, String>> _headers({bool requiresAuth = true}) async {
    final headers = <String, String>{
      'Accept': 'application/json',
      'Content-Type': 'application/json',
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
      );
      return _processResponse(response);
    } on SocketException {
      throw ApiException('Tidak dapat terhubung ke server backend');
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
      );
      return _processResponse(response);
    } on SocketException {
      throw ApiException('Tidak dapat terhubung ke server backend');
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
      );
      return _processResponse(response);
    } on SocketException {
      throw ApiException('Tidak dapat terhubung ke server backend');
    }
  }

  Future<dynamic> delete(String url, {bool requiresAuth = true}) async {
    try {
      final response = await _client.delete(
        Uri.parse(url),
        headers: await _headers(requiresAuth: requiresAuth),
      );
      return _processResponse(response);
    } on SocketException {
      throw ApiException('Tidak dapat terhubung ke server backend');
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
