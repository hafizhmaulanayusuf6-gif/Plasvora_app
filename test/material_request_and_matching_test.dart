import 'package:flutter_test/flutter_test.dart';
import 'package:plasvora/core/network/api_client.dart';
import 'package:plasvora/models/handover_item.dart';
import 'package:plasvora/models/matching_result.dart';
import 'package:plasvora/models/material_listing.dart';
import 'package:plasvora/models/material_request_item.dart';
import 'package:plasvora/repositories/transaction_repository.dart';
import 'package:plasvora/viewmodels/matching_viewmodel.dart';
import 'package:plasvora/viewmodels/material_request_viewmodel.dart';

/// Fake TransactionRepository untuk pengujian unit terisolasi
class FakeTransactionRepository implements TransactionRepository {
  String? lastCategory;
  String? lastLocation;
  String? lastCondition;

  Map<String, dynamic>? lastCreatedPayload;
  bool shouldThrowError = false;
  String errorMessage = 'Koneksi backend gagal';

  List<MaterialRequestItem> stubbedRequests = [];
  MaterialRequestItem? stubbedDetail;
  MaterialRequestMatchingResponse? stubbedRequestMatches;
  MaterialListingMatchingResponse? stubbedListingMatches;

  @override
  Future<List<MaterialRequestItem>> getMaterialRequests({
    String? category,
    String? location,
    String? condition,
  }) async {
    lastCategory = category;
    lastLocation = location;
    lastCondition = condition;

    if (shouldThrowError) {
      throw ApiException(errorMessage);
    }
    return stubbedRequests;
  }

  @override
  Future<MaterialRequestItem> getMaterialRequestDetail(int id) async {
    if (shouldThrowError) {
      throw ApiException(errorMessage, statusCode: 404);
    }
    if (stubbedDetail != null && stubbedDetail!.id == id) {
      return stubbedDetail!;
    }
    return MaterialRequestItem(
      id: id,
      requesterId: 7,
      materialCategory: 'PET',
      requestedWeightKg: 15.0,
      minimumCondition: 'clean',
      generalLocation: 'Bandung',
      intendedUse: 'Kebutuhan daur ulang botol',
      status: 'active',
      requesterName: 'Budi',
      createdAt: DateTime.now(),
    );
  }

  @override
  Future<MaterialRequestItem> createMaterialRequest({
    required String materialCategory,
    required double requestedWeightKg,
    required String minimumCondition,
    required String generalLocation,
    required String intendedUse,
  }) async {
    lastCreatedPayload = {
      'material_category': materialCategory,
      'requested_weight_kg': requestedWeightKg,
      'minimum_condition': minimumCondition,
      'general_location': generalLocation,
      'intended_use': intendedUse,
    };

    if (shouldThrowError) {
      throw ApiException(errorMessage, statusCode: 422);
    }

    final newItem = MaterialRequestItem(
      id: 99,
      requesterId: 1, // Diambil dari Sanctum user di backend
      materialCategory: materialCategory,
      requestedWeightKg: requestedWeightKg,
      minimumCondition: minimumCondition,
      generalLocation: generalLocation,
      intendedUse: intendedUse,
      status: 'active',
      requesterName: 'Pengguna Aktif',
      createdAt: DateTime.now(),
    );
    return newItem;
  }

  @override
  Future<MaterialRequestItem> updateMaterialRequest({
    required int id,
    String? materialCategory,
    double? requestedWeightKg,
    String? minimumCondition,
    String? generalLocation,
    String? intendedUse,
    String? status,
  }) async {
    if (shouldThrowError) {
      throw ApiException(errorMessage, statusCode: 403);
    }
    return MaterialRequestItem(
      id: id,
      requesterId: 1,
      materialCategory: materialCategory ?? 'PET',
      requestedWeightKg: requestedWeightKg ?? 10.0,
      minimumCondition: minimumCondition ?? 'clean',
      generalLocation: generalLocation ?? 'Jakarta',
      intendedUse: intendedUse ?? 'Penggunaan update',
      status: status ?? 'active',
      createdAt: DateTime.now(),
    );
  }

  @override
  Future<void> cancelMaterialRequest(int id) async {
    if (shouldThrowError) {
      throw ApiException(errorMessage, statusCode: 403);
    }
  }

  @override
  Future<MaterialRequestMatchingResponse> getMatchesForRequest(int id) async {
    if (shouldThrowError) {
      throw ApiException(errorMessage);
    }
    if (stubbedRequestMatches != null) {
      return stubbedRequestMatches!;
    }

    final dummyReq = MaterialRequestItem(
      id: id,
      requesterId: 1,
      materialCategory: 'PET',
      requestedWeightKg: 10.0,
      minimumCondition: 'clean',
      generalLocation: 'Bandung',
      intendedUse: 'Daur ulang',
      status: 'active',
      createdAt: DateTime.now(),
    );

    return MaterialRequestMatchingResponse(
      request: dummyReq,
      matches: [],
      total: 0,
      note: 'Hasil matching berbasis aturan, bukan kecerdasan buatan.',
    );
  }

  @override
  Future<MaterialListingMatchingResponse> getMatchesForListing(int id) async {
    if (shouldThrowError) {
      throw ApiException(errorMessage);
    }
    if (stubbedListingMatches != null) {
      return stubbedListingMatches!;
    }

    final dummyListing = MaterialListing(
      id: id,
      name: 'Listing Mock',
      category: 'PET',
      weightKg: 10.0,
      condition: 'clean',
      price: 0,
      isFree: true,
      generalLocation: 'Bandung',
      description: 'Deskripsi',
      createdAt: DateTime.now(),
    );

    return MaterialListingMatchingResponse(
      listing: dummyListing,
      matches: [],
      total: 0,
      note: 'Hasil matching berbasis aturan, bukan kecerdasan buatan.',
    );
  }

  @override
  Future<List<HandoverItem>> getHandoverRequests() async => [];

  @override
  Future<HandoverItem> createHandoverRequest({
    required int listingId,
    required double requestedWeightKg,
    String? note,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<HandoverItem> updateHandoverStatus({
    required int handoverId,
    required String status,
    double? agreedWeightKg,
    double? actualWeightKg,
    String? note,
  }) async {
    throw UnimplementedError();
  }
}

void main() {
  group('Material Request & Smart Matching Tests', () {
    late FakeTransactionRepository repository;
    late MaterialRequestViewModel requestViewModel;
    late MatchingViewModel matchingViewModel;

    final dummyRequest = MaterialRequestItem(
      id: 50,
      requesterId: 2,
      materialCategory: 'HDPE',
      requestedWeightKg: 20.0,
      minimumCondition: 'slightly_dirty',
      generalLocation: 'Surabaya Timur',
      intendedUse: 'Bahan daur ulang pembuatan tong sampah komunitas.',
      status: 'active',
      requesterName: 'Pak RT Bambang',
      createdAt: DateTime.parse('2026-11-14T08:00:00Z'),
    );

    setUp(() {
      repository = FakeTransactionRepository();
      repository.stubbedRequests = [dummyRequest];
      requestViewModel = MaterialRequestViewModel(
        transactionRepository: repository,
        currentUserId: 2,
      );
      matchingViewModel = MatchingViewModel(
        transactionRepository: repository,
      );
    });

    test('1. Mapping MaterialRequestItem dari JSON Eloquent Laravel aman dari tipe data desimal/string', () {
      final json = {
        'id': '50',
        'requester_id': '2',
        'material_category': 'OTHER',
        'requested_weight_kg': '25.50',
        'minimum_condition': 'dirty',
        'general_location': 'Yogyakarta Kota',
        'intended_use': 'Eksperimen kerajinan daur ulang plastik campur',
        'status': 'active',
        'requester': {
          'id': 2,
          'name': 'Bambang Sudiro',
        },
        'created_at': '2026-11-14T10:00:00Z',
      };

      final item = MaterialRequestItem.fromJson(json);

      expect(item.id, 50);
      expect(item.requesterId, 2);
      expect(item.materialCategory, 'OTHER');
      expect(item.categoryLabel, 'Lainnya');
      expect(item.requestedWeightKg, 25.5);
      expect(item.formattedWeight, '25.5 kg');
      expect(item.minimumCondition, 'dirty');
      expect(item.conditionLabel, 'Kotor');
      expect(item.status, 'active');
      expect(item.statusLabel, 'Aktif');
      expect(item.requesterName, 'Bambang Sudiro');
    });

    test('2. Validasi form Material Request menolak berat <= 0 dan intended_use < 5 karakter', () {
      // Berat <= 0
      final errWeight = requestViewModel.validateForm(
        category: 'PET',
        weightKg: 0.0,
        condition: 'clean',
        location: 'Bandung',
        intendedUse: 'Tujuan daur ulang',
      );
      expect(errWeight, isNotNull);
      expect(errWeight, contains('lebih besar dari 0 kg'));

      // Intended use terlalu pendek
      final errUse = requestViewModel.validateForm(
        category: 'PET',
        weightKg: 10.0,
        condition: 'clean',
        location: 'Bandung',
        intendedUse: 'Abc', // < 5 karakter
      );
      expect(errUse, isNotNull);
      expect(errUse, contains('minimal 5 karakter'));

      // Lokasi terlalu pendek
      final errLoc = requestViewModel.validateForm(
        category: 'PET',
        weightKg: 10.0,
        condition: 'clean',
        location: 'JK', // < 3 karakter
        intendedUse: 'Tujuan pemanfaatan plastik',
      );
      expect(errLoc, isNotNull);
      expect(errLoc, contains('minimal 3 karakter'));

      // Validasi lengkap sukses
      final valid = requestViewModel.validateForm(
        category: 'PET',
        weightKg: 10.0,
        condition: 'clean',
        location: 'Bandung Kulon',
        intendedUse: 'Tujuan pemanfaatan plastik daur ulang',
      );
      expect(valid, isNull);
    });

    test('3. Pembuatan Material Request tidak mengirim requester_id/user_id dari client', () async {
      final success = await requestViewModel.createRequest(
        category: 'HDPE',
        weightKg: 15.0,
        condition: 'clean',
        location: 'Jakarta Selatan',
        intendedUse: 'Bahan baku injection molding',
      );

      expect(success, isTrue);
      expect(repository.lastCreatedPayload, isNotNull);
      // Memastikan TIDAK ADA requester_id dalam payload yang dikirim ke backend
      expect(repository.lastCreatedPayload!.containsKey('requester_id'), isFalse);
      expect(repository.lastCreatedPayload!['material_category'], 'HDPE');
      expect(repository.lastCreatedPayload!['requested_weight_kg'], 15.0);
    });

    test('4. Filter kategori memetakan Lainnya ke OTHER dan Campuran ke MIXED', () async {
      requestViewModel.selectCategory('Lainnya');
      await Future.delayed(const Duration(milliseconds: 10));

      expect(repository.lastCategory, 'OTHER');
      expect(requestViewModel.selectedCategory, 'Lainnya');

      requestViewModel.selectCategory('Campuran');
      await Future.delayed(const Duration(milliseconds: 10));

      expect(repository.lastCategory, 'MIXED');
      expect(requestViewModel.selectedCategory, 'Campuran');
    });

    test('5. Penanganan error API Material Request menangkap pesan error dan membersihkan state', () async {
      repository.shouldThrowError = true;
      repository.errorMessage = 'Server sedang mengalami gangguan (500)';

      await requestViewModel.loadRequests();

      expect(requestViewModel.requests, isEmpty);
      expect(requestViewModel.errorMessage, 'Server sedang mengalami gangguan (500)');
      expect(requestViewModel.isLoading, isFalse);
    });

    test('6. Pengecekan kepemilikan Material Request (isOwner) akurat', () {
      expect(requestViewModel.isOwner(dummyRequest), isTrue); // requesterId = 2, currentUserId = 2

      final otherRequest = MaterialRequestItem(
        id: 51,
        requesterId: 99,
        materialCategory: 'PP',
        requestedWeightKg: 5.0,
        minimumCondition: 'clean',
        generalLocation: 'Medan',
        intendedUse: 'Daur ulang sedotan',
        status: 'active',
        createdAt: DateTime.now(),
      );
      expect(requestViewModel.isOwner(otherRequest), isFalse);
    });

    test('7. Pembatalan Material Request milik sendiri menghapus item dari daftar aktif', () async {
      expect(requestViewModel.requests.length, 1);

      final success = await requestViewModel.cancelRequest(50);

      expect(success, isTrue);
      expect(requestViewModel.requests.isEmpty, isTrue);
    });

    test('8. Mapping respons Smart Matching untuk Material Request memetakan skor dan alasan aturan', () {
      final jsonResponse = {
        'success': true,
        'message': 'Matching results retrieved successfully',
        'data': {
          'request': {
            'id': 50,
            'requester_id': 2,
            'material_category': 'HDPE',
            'requested_weight_kg': '20.00',
            'minimum_condition': 'clean',
            'general_location': 'Surabaya',
            'intended_use': 'Daur ulang paving block',
            'status': 'active',
            'created_at': '2026-11-14T08:00:00Z',
          },
          'matches': [
            {
              'listing': {
                'id': 105,
                'name': 'Tutup Botol HDPE Bersih',
                'category': 'HDPE',
                'weight_kg': '25.00',
                'condition': 'clean',
                'price': '0',
                'is_free': 1,
                'general_location': 'Surabaya Barat',
                'description': 'Tutup botol siap cacah',
                'created_at': '2026-11-14T07:00:00Z',
              },
              'match_reasons': ['category_match', 'weight_match', 'condition_match', 'nearby_location'],
              'match_reasons_detail': {
                'category_match': 'Kategori material sesuai dengan yang dibutuhkan.',
                'weight_match': 'Jumlah berat tersedia mencukupi kebutuhan.',
                'condition_match': 'Kondisi material memenuhi standar minimum yang diminta.',
                'nearby_location': 'Lokasi material dekat dengan lokasi yang diinginkan.',
              },
              'match_score': 100,
              'score_explanation': 'Skor dihitung berdasarkan: kategori (40 poin), berat (30 poin), kondisi (20 poin), lokasi (10 poin). Bukan probabilitas AI.',
            }
          ],
          'total': 1,
          'note': 'Hasil matching menggunakan sistem berbasis aturan, bukan kecerdasan buatan.',
        }
      };

      final parsed = MaterialRequestMatchingResponse.fromJson(jsonResponse);

      expect(parsed.total, 1);
      expect(parsed.request.id, 50);
      expect(parsed.matches.length, 1);

      final firstMatch = parsed.matches.first;
      expect(firstMatch.listing.id, 105);
      expect(firstMatch.listing.name, 'Tutup Botol HDPE Bersih');
      expect(firstMatch.matchScore, 100);
      expect(firstMatch.matchReasons.length, 4);
      expect(firstMatch.matchReasonsDetail['category_match'], contains('Kategori material sesuai'));
      expect(firstMatch.scoreExplanation, contains('Bukan probabilitas AI'));
    });

    test('9. Smart Matching untuk Listing Material memetakan kebutuhan yang cocok dengan tepat', () {
      final jsonResponse = {
        'success': true,
        'message': 'Matching results retrieved successfully',
        'data': {
          'listing': {
            'id': 105,
            'name': 'Tutup Botol HDPE Bersih',
            'category': 'HDPE',
            'weight_kg': '25.00',
            'condition': 'clean',
            'price': '0',
            'is_free': 1,
            'general_location': 'Surabaya Barat',
            'description': 'Tutup botol siap cacah',
            'created_at': '2026-11-14T07:00:00Z',
          },
          'matches': [
            {
              'request': {
                'id': 50,
                'requester_id': 2,
                'material_category': 'HDPE',
                'requested_weight_kg': '20.00',
                'minimum_condition': 'clean',
                'general_location': 'Surabaya',
                'intended_use': 'Daur ulang paving block',
                'status': 'active',
                'created_at': '2026-11-14T08:00:00Z',
              },
              'match_reasons': ['category_match', 'weight_match', 'condition_match'],
              'match_reasons_detail': {
                'category_match': 'Kategori material sesuai.',
                'weight_match': 'Jumlah berat tersedia mencukupi.',
                'condition_match': 'Kondisi material memenuhi standar.',
              },
              'match_score': 90,
              'score_explanation': 'Skor dihitung berbasis aturan.',
            }
          ],
          'total': 1,
          'note': 'Hasil matching berbasis aturan.',
        }
      };

      final parsed = MaterialListingMatchingResponse.fromJson(jsonResponse);

      expect(parsed.total, 1);
      expect(parsed.listing.id, 105);
      expect(parsed.matches.length, 1);
      expect(parsed.matches.first.request.id, 50);
      expect(parsed.matches.first.matchScore, 90);
    });

    test('10. Penanganan Smart Matching saat tidak ada material yang cocok (empty state)', () async {
      await matchingViewModel.findMatchesForRequest(50);

      expect(matchingViewModel.isLoading, isFalse);
      expect(matchingViewModel.errorMessage, isNull);
      expect(matchingViewModel.requestMatchingResponse, isNotNull);
      expect(matchingViewModel.requestMatchingResponse!.matches, isEmpty);
      expect(matchingViewModel.requestMatchingResponse!.total, 0);
    });
  });
}
