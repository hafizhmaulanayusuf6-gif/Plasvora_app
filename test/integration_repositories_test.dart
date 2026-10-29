import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:plasvora/core/network/api_client.dart';
import 'package:plasvora/core/network/api_config.dart';
import 'package:plasvora/repositories/auth_repository.dart';
import 'package:plasvora/repositories/material_repository.dart';

void main() {
  group('ApiAuthRepository Tests', () {
    test('login success returns user and stores token', () async {
      final mockHttp = MockClient((request) async {
        if (request.url.toString() == ApiConfig.login) {
          return http.Response(
            jsonEncode({
              'success': true,
              'message': 'Login successful',
              'data': {
                'user': {
                  'id': 1,
                  'name': 'Test User',
                  'email': 'test@plasvora.id',
                },
                'token': 'mock-auth-token-123',
                'token_type': 'Bearer',
              },
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response('Not Found', 404);
      });

      final apiClient = ApiClient(client: mockHttp);
      final authRepo = ApiAuthRepository(apiClient: apiClient);

      final user = await authRepo.login(
        email: 'test@plasvora.id',
        password: 'password123',
      );

      expect(user.id, 1);
      expect(user.name, 'Test User');
      expect(await apiClient.getToken(), 'mock-auth-token-123');
      expect(await authRepo.isAuthenticated(), true);
    });

    test('login failure throws ApiException', () async {
      final mockHttp = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'success': false,
            'message': 'Email atau password tidak valid',
          }),
          401,
          headers: {'content-type': 'application/json'},
        );
      });

      final apiClient = ApiClient(client: mockHttp);
      final authRepo = ApiAuthRepository(apiClient: apiClient);

      expect(
        () => authRepo.login(
          email: 'wrong@plasvora.id',
          password: 'wrong',
        ),
        throwsA(isA<ApiException>()),
      );
    });
  });

  group('ApiMaterialRepository Tests', () {
    test('getMaterials parses response properly', () async {
      final mockHttp = MockClient((request) async {
        if (request.url.path.contains('/materials')) {
          return http.Response(
            jsonEncode({
              'success': true,
              'message': 'Materials retrieved successfully',
              'data': [
                {
                  'id': 101,
                  'owner_id': 1,
                  'name': 'Tutup Botol HDPE',
                  'category': 'HDPE',
                  'weight_kg': 5.0,
                  'condition': 'clean',
                  'price': 15000,
                  'is_free': false,
                  'general_location': 'Jakarta Selatan',
                  'description': 'Tutup botol bersih',
                  'created_at': '2026-10-28T12:00:00Z',
                }
              ],
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response('Not Found', 404);
      });

      final apiClient = ApiClient(client: mockHttp);
      final repo = ApiMaterialRepository(apiClient: apiClient);

      final materials = await repo.getMaterials();
      expect(materials.length, 1);
      expect(materials.first.id, 101);
      expect(materials.first.name, 'Tutup Botol HDPE');
      expect(materials.first.formattedPrice, 'Rp 15.000');
    });

    test('createMaterial posts validated payload', () async {
      final mockHttp = MockClient((request) async {
        if (request.method == 'POST' && request.url.path.contains('/materials')) {
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          expect(body['name'], 'Plastik PP Bening');
          expect(body['weight_kg'], 10.0);

          return http.Response(
            jsonEncode({
              'success': true,
              'message': 'Material listing created successfully',
              'data': {
                'id': 202,
                'name': body['name'],
                'category': body['category'],
                'weight_kg': body['weight_kg'],
                'condition': body['condition'],
                'price': body['price'],
                'is_free': body['is_free'],
                'general_location': body['general_location'],
                'description': body['description'],
                'created_at': '2026-10-28T12:30:00Z',
              },
            }),
            201,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response('Not Found', 404);
      });

      final apiClient = ApiClient(client: mockHttp);
      await apiClient.saveToken('valid-token');
      final repo = ApiMaterialRepository(apiClient: apiClient);

      final created = await repo.createMaterial(
        name: 'Plastik PP Bening',
        category: 'PP',
        weightKg: 10.0,
        condition: 'clean',
        price: 25000,
        isFree: false,
        generalLocation: 'Bandung',
        description: 'Karung plastik PP bersih.',
      );

      expect(created.id, 202);
      expect(created.name, 'Plastik PP Bening');
    });
  });
}

