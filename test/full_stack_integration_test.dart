import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:plasvora/core/network/api_client.dart';
import 'package:plasvora/models/plastic_analysis.dart';
import 'package:plasvora/repositories/analysis_repository.dart';
import 'package:plasvora/repositories/auth_repository.dart';
import 'package:plasvora/repositories/material_repository.dart';
import 'package:plasvora/repositories/transaction_repository.dart';
import 'package:plasvora/viewmodels/auth_viewmodel.dart';
import 'package:plasvora/viewmodels/home_viewmodel.dart';
import 'package:plasvora/viewmodels/marketplace_viewmodel.dart';

void main() {
  group('Full-Stack Contract Integration Tests', () {
    late ApiClient apiClient;

    setUp(() {
      final mockHttp = MockClient((request) async {
        final path = request.url.path;

        if (path.endsWith('/login')) {
          return http.Response(
            jsonEncode({
              'success': true,
              'message': 'Login successful',
              'data': {
                'user': {'id': 1, 'name': 'Ahmad', 'email': 'ahmad@plasvora.id'},
                'token': 'sanctum-mock-token-xyz',
              },
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }

        if (path.endsWith('/me')) {
          return http.Response(
            jsonEncode({
              'success': true,
              'data': {'id': 1, 'name': 'Ahmad', 'email': 'ahmad@plasvora.id'},
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }

        if (path.endsWith('/materials') && request.method == 'GET') {
          return http.Response(
            jsonEncode({
              'success': true,
              'data': [
                {
                  'id': 1,
                  'name': 'Botol Plastik PET',
                  'category': 'PET',
                  'weight_kg': 5.0,
                  'condition': 'clean',
                  'price': 10000,
                  'is_free': false,
                  'general_location': 'Bandung',
                  'description': 'Bersih dan kering',
                  'created_at': '2026-10-28T10:00:00Z',
                }
              ],
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }

        if (path.endsWith('/material-requests') && request.method == 'GET') {
          return http.Response(
            jsonEncode({
              'success': true,
              'data': [
                {
                  'id': 1,
                  'requester_id': 1,
                  'material_category': 'PP',
                  'requested_weight_kg': 15.0,
                  'minimum_condition': 'clean',
                  'general_location': 'Jakarta',
                  'intended_use': 'Paving block daur ulang',
                  'status': 'active',
                  'created_at': '2026-10-28T10:00:00Z',
                }
              ],
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }

        if (path.endsWith('/handover-requests') && request.method == 'POST') {
          return http.Response(
            jsonEncode({
              'success': true,
              'message': 'Handover request submitted successfully',
              'data': {
                'id': 1,
                'listing_id': 1,
                'owner_id': 2,
                'requester_id': 1,
                'requested_weight_kg': 5.0,
                'status': 'pending',
                'created_at': '2026-10-28T10:00:00Z',
              },
            }),
            201,
            headers: {'content-type': 'application/json'},
          );
        }

        if (path.endsWith('/analyses') && request.method == 'POST') {
          return http.Response(
            jsonEncode({
              'success': true,
              'message': 'Analysis completed',
              'data': {
                'id': 1,
                'declared_category': 'PET',
                'is_demo_result': true,
              },
            }),
            201,
            headers: {'content-type': 'application/json'},
          );
        }

        return http.Response('Not Found', 404);
      });

      apiClient = ApiClient(client: mockHttp);
    });

    test('AuthViewModel login updates state and persists session', () async {
      final authRepo = ApiAuthRepository(apiClient: apiClient);
      final vm = AuthViewModel(authRepository: authRepo);

      final success = await vm.login('ahmad@plasvora.id', 'password');
      expect(success, true);
      expect(vm.isAuthenticated, true);
      expect(vm.currentUser?.name, 'Ahmad');
      expect(await apiClient.getToken(), 'sanctum-mock-token-xyz');
    });

    test('MarketplaceViewModel loads listings from ApiMaterialRepository', () async {
      final repo = ApiMaterialRepository(apiClient: apiClient);
      final vm = MarketplaceViewModel(materialRepository: repo);

      await vm.loadListings();
      expect(vm.listings.length, 1);
      expect(vm.listings.first.name, 'Botol Plastik PET');
      expect(vm.isLoading, false);
      expect(vm.errorMessage, isNull);
    });

    test('HomeViewModel loads and exposes recent listings', () async {
      final repo = ApiMaterialRepository(apiClient: apiClient);
      final vm = HomeViewModel(materialRepository: repo);

      await vm.loadHomeData();
      expect(vm.recentListings.length, 1);
      expect(vm.isLoading, false);
    });

    test('ApiTransactionRepository manages material requests and handovers', () async {
      final repo = ApiTransactionRepository(apiClient: apiClient);

      final requests = await repo.getMaterialRequests();
      expect(requests.length, 1);
      expect(requests.first.materialCategory, 'PP');
      expect(requests.first.requestedWeightKg, 15.0);

      final handover = await repo.createHandoverRequest(
        listingId: 1,
        requestedWeightKg: 5.0,
      );
      expect(handover.id, 1);
      expect(handover.status, 'pending');
    });

    test('ApiAnalysisRepository executes rule-based analysis and marks isSimulated accurately', () async {
      final repo = ApiAnalysisRepository(apiClient: apiClient);
      final result = await repo.analyzePlastic(
        const PlasticAnalysisInput(
          imagePath: '/path/dummy.jpg',
          polymerCategory: 'PET',
        ),
      );

      expect(result.polymerCategory, 'PET');
      expect(result.isSimulated, true);
      expect(result.materialTitle, 'Botol Plastik PET Bening');
    });
  });
}