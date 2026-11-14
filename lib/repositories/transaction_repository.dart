import '../core/network/api_client.dart';
import '../core/network/api_config.dart';
import '../models/handover_item.dart';
import '../models/matching_result.dart';
import '../models/material_listing.dart';
import '../models/material_request_item.dart';

abstract class TransactionRepository {
  Future<List<MaterialRequestItem>> getMaterialRequests({
    String? category,
    String? location,
    String? condition,
  });

  Future<MaterialRequestItem> getMaterialRequestDetail(int id);

  Future<MaterialRequestItem> createMaterialRequest({
    required String materialCategory,
    required double requestedWeightKg,
    required String minimumCondition,
    required String generalLocation,
    required String intendedUse,
  });

  Future<MaterialRequestItem> updateMaterialRequest({
    required int id,
    String? materialCategory,
    double? requestedWeightKg,
    String? minimumCondition,
    String? generalLocation,
    String? intendedUse,
    String? status,
  });

  Future<void> cancelMaterialRequest(int id);

  Future<MaterialRequestMatchingResponse> getMatchesForRequest(int id);

  Future<MaterialListingMatchingResponse> getMatchesForListing(int id);

  Future<List<HandoverItem>> getHandoverRequests();

  Future<HandoverItem> createHandoverRequest({
    required int listingId,
    required double requestedWeightKg,
    String? note,
  });

  Future<HandoverItem> updateHandoverStatus({
    required int handoverId,
    required String status,
    double? agreedWeightKg,
    double? actualWeightKg,
    String? note,
  });
}

class ApiTransactionRepository implements TransactionRepository {
  final ApiClient apiClient;

  ApiTransactionRepository({required this.apiClient});

  @override
  Future<List<MaterialRequestItem>> getMaterialRequests({
    String? category,
    String? location,
    String? condition,
  }) async {
    final queryParams = <String, String>{};
    if (category != null && category.isNotEmpty && category != 'Semua') {
      queryParams['category'] = category;
    }
    if (location != null && location.trim().isNotEmpty) {
      queryParams['location'] = location.trim();
    }
    if (condition != null && condition.isNotEmpty && condition != 'Semua') {
      queryParams['condition'] = condition;
    }

    final baseUri = Uri.parse(ApiConfig.materialRequests);
    final finalUri = queryParams.isEmpty
        ? baseUri
        : baseUri.replace(queryParameters: queryParams);

    final response = await apiClient.get(
      finalUri.toString(),
      requiresAuth: false,
    );

    if (response is Map<String, dynamic> && response['data'] is List) {
      return (response['data'] as List)
          .map((item) =>
              MaterialRequestItem.fromJson(item as Map<String, dynamic>))
          .toList();
    }
    throw ApiException('Format respons material-requests tidak valid');
  }

  @override
  Future<MaterialRequestItem> getMaterialRequestDetail(int id) async {
    final response = await apiClient.get(
      ApiConfig.materialRequestDetail(id),
      requiresAuth: false,
    );

    if (response is Map<String, dynamic> && response['data'] != null) {
      return MaterialRequestItem.fromJson(
        response['data'] as Map<String, dynamic>,
      );
    }
    throw ApiException('Detail kebutuhan material tidak ditemukan');
  }

  @override
  Future<MaterialRequestItem> createMaterialRequest({
    required String materialCategory,
    required double requestedWeightKg,
    required String minimumCondition,
    required String generalLocation,
    required String intendedUse,
  }) async {
    final response = await apiClient.post(
      ApiConfig.materialRequests,
      body: {
        'material_category': materialCategory,
        'requested_weight_kg': requestedWeightKg,
        'minimum_condition': minimumCondition,
        'general_location': generalLocation,
        'intended_use': intendedUse,
      },
      requiresAuth: true,
    );

    if (response is Map<String, dynamic> && response['data'] != null) {
      return MaterialRequestItem.fromJson(
        response['data'] as Map<String, dynamic>,
      );
    }
    throw ApiException('Gagal membuat permintaan material');
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
    final body = <String, dynamic>{};
    if (materialCategory != null) body['material_category'] = materialCategory;
    if (requestedWeightKg != null) {
      body['requested_weight_kg'] = requestedWeightKg;
    }
    if (minimumCondition != null) body['minimum_condition'] = minimumCondition;
    if (generalLocation != null) body['general_location'] = generalLocation;
    if (intendedUse != null) body['intended_use'] = intendedUse;
    if (status != null) body['status'] = status;

    final response = await apiClient.patch(
      ApiConfig.materialRequestDetail(id),
      body: body,
      requiresAuth: true,
    );

    if (response is Map<String, dynamic> && response['data'] != null) {
      return MaterialRequestItem.fromJson(
        response['data'] as Map<String, dynamic>,
      );
    }
    throw ApiException('Gagal memperbarui kebutuhan material');
  }

  @override
  Future<void> cancelMaterialRequest(int id) async {
    await apiClient.delete(
      ApiConfig.materialRequestDetail(id),
      requiresAuth: true,
    );
  }

  @override
  Future<MaterialRequestMatchingResponse> getMatchesForRequest(int id) async {
    final response = await apiClient.get(
      ApiConfig.materialRequestMatches(id),
      requiresAuth: true,
    );

    if (response is Map<String, dynamic>) {
      return MaterialRequestMatchingResponse.fromJson(response);
    }
    throw ApiException('Format respons matching request tidak valid');
  }

  @override
  Future<MaterialListingMatchingResponse> getMatchesForListing(int id) async {
    final response = await apiClient.get(
      ApiConfig.materialMatches(id),
      requiresAuth: true,
    );

    if (response is Map<String, dynamic>) {
      return MaterialListingMatchingResponse.fromJson(response);
    }
    throw ApiException('Format respons matching listing tidak valid');
  }

  @override
  Future<List<HandoverItem>> getHandoverRequests() async {
    final response = await apiClient.get(
      ApiConfig.handoverRequests,
      requiresAuth: true,
    );
    if (response is Map<String, dynamic> && response['data'] is List) {
      return (response['data'] as List)
          .map((item) =>
              HandoverItem.fromJson(item as Map<String, dynamic>))
          .toList();
    }
    throw ApiException('Format respons handover-requests tidak valid');
  }

  @override
  Future<HandoverItem> createHandoverRequest({
    required int listingId,
    required double requestedWeightKg,
    String? note,
  }) async {
    final body = <String, dynamic>{
      'listing_id': listingId,
      'requested_weight_kg': requestedWeightKg,
    };
    if (note != null && note.isNotEmpty) {
      body['note'] = note;
    }

    final response = await apiClient.post(
      ApiConfig.handoverRequests,
      body: body,
      requiresAuth: true,
    );

    if (response is Map<String, dynamic> && response['data'] != null) {
      return HandoverItem.fromJson(response['data'] as Map<String, dynamic>);
    }
    throw ApiException('Gagal mengajukan serah terima material');
  }

  @override
  Future<HandoverItem> updateHandoverStatus({
    required int handoverId,
    required String status,
    double? agreedWeightKg,
    double? actualWeightKg,
    String? note,
  }) async {
    final body = <String, dynamic>{'status': status};
    if (agreedWeightKg != null) body['agreed_weight_kg'] = agreedWeightKg;
    if (actualWeightKg != null) body['actual_weight_kg'] = actualWeightKg;
    if (note != null) body['note'] = note;

    final response = await apiClient.patch(
      ApiConfig.updateHandoverStatus(handoverId),
      body: body,
      requiresAuth: true,
    );

    if (response is Map<String, dynamic> && response['data'] != null) {
      return HandoverItem.fromJson(response['data'] as Map<String, dynamic>);
    }
    throw ApiException('Gagal memperbarui status serah terima');
  }
}

/// Mock / Fake TransactionRepository untuk fallback offline dan testing
class MockTransactionRepository implements TransactionRepository {
  final List<MaterialRequestItem> _mockRequests = [
    MaterialRequestItem(
      id: 1,
      requesterId: 1,
      materialCategory: 'PET',
      requestedWeightKg: 25.0,
      minimumCondition: 'clean',
      generalLocation: 'Bandung Kulon',
      intendedUse: 'Bahan baku daur ulang filament 3D print dan pot tanaman.',
      status: 'active',
      requesterName: 'Budi Santoso',
      createdAt: DateTime.now().subtract(const Duration(hours: 4)),
    ),
    MaterialRequestItem(
      id: 2,
      requesterId: 2,
      materialCategory: 'HDPE',
      requestedWeightKg: 10.0,
      minimumCondition: 'slightly_dirty',
      generalLocation: 'Surabaya Timur',
      intendedUse: 'Pembuatan paving block plastik daur ulang komunitas.',
      status: 'active',
      requesterName: 'Komunitas Daur Bersama',
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
  ];

  @override
  Future<List<MaterialRequestItem>> getMaterialRequests({
    String? category,
    String? location,
    String? condition,
  }) async {
    var list = _mockRequests.where((r) => r.status == 'active').toList();
    if (category != null && category.isNotEmpty && category != 'Semua') {
      list = list.where((r) => r.materialCategory == category).toList();
    }
    if (condition != null && condition.isNotEmpty && condition != 'Semua') {
      list = list.where((r) => r.minimumCondition == condition).toList();
    }
    if (location != null && location.isNotEmpty) {
      list = list
          .where((r) =>
              r.generalLocation.toLowerCase().contains(location.toLowerCase()))
          .toList();
    }
    return list;
  }

  @override
  Future<MaterialRequestItem> getMaterialRequestDetail(int id) async {
    return _mockRequests.firstWhere(
      (r) => r.id == id,
      orElse: () => throw ApiException('Material request not found', statusCode: 404),
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
    final newId = _mockRequests.isEmpty ? 1 : _mockRequests.map((r) => r.id).reduce((a, b) => a > b ? a : b) + 1;
    final item = MaterialRequestItem(
      id: newId,
      requesterId: 1, // Simulasi user aktif
      materialCategory: materialCategory,
      requestedWeightKg: requestedWeightKg,
      minimumCondition: minimumCondition,
      generalLocation: generalLocation,
      intendedUse: intendedUse,
      status: 'active',
      requesterName: 'Saya (Pengguna)',
      createdAt: DateTime.now(),
    );
    _mockRequests.insert(0, item);
    return item;
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
    final idx = _mockRequests.indexWhere((r) => r.id == id);
    if (idx == -1) throw ApiException('Material request not found', statusCode: 404);
    final current = _mockRequests[idx];
    final updated = current.copyWith(
      materialCategory: materialCategory,
      requestedWeightKg: requestedWeightKg,
      minimumCondition: minimumCondition,
      generalLocation: generalLocation,
      intendedUse: intendedUse,
      status: status,
    );
    _mockRequests[idx] = updated;
    return updated;
  }

  @override
  Future<void> cancelMaterialRequest(int id) async {
    final idx = _mockRequests.indexWhere((r) => r.id == id);
    if (idx != -1) {
      _mockRequests[idx] = _mockRequests[idx].copyWith(status: 'cancelled');
    }
  }

  @override
  Future<MaterialRequestMatchingResponse> getMatchesForRequest(int id) async {
    final req = await getMaterialRequestDetail(id);
    return MaterialRequestMatchingResponse(
      request: req,
      matches: [
        MaterialRequestMatchItem(
          listing: MaterialListing(
            id: 101,
            name: 'Botol PET Bening Bersih',
            category: req.materialCategory,
            weightKg: req.requestedWeightKg + 5.0,
            condition: 'clean',
            price: 0,
            isFree: true,
            generalLocation: req.generalLocation,
            description: 'Material plastik bersih siap pakai.',
            ownerName: 'Ibu Siti',
            createdAt: DateTime.now(),
          ),
          matchReasons: ['category_match', 'weight_match', 'condition_match', 'nearby_location'],
          matchReasonsDetail: {
            'category_match': 'Kategori material sesuai dengan yang dibutuhkan.',
            'weight_match': 'Jumlah berat tersedia mencukupi kebutuhan.',
            'condition_match': 'Kondisi material memenuhi standar minimum yang diminta.',
            'nearby_location': 'Lokasi material dekat dengan lokasi yang diinginkan.',
          },
          matchScore: 100,
          scoreExplanation:
              'Skor dihitung berdasarkan: kategori (40 poin), berat (30 poin), kondisi (20 poin), lokasi (10 poin). Bukan probabilitas AI.',
        ),
      ],
      total: 1,
      note: 'Hasil matching berbasis aturan, bukan kecerdasan buatan.',
    );
  }

  @override
  Future<MaterialListingMatchingResponse> getMatchesForListing(int id) async {
    return MaterialListingMatchingResponse(
      listing: MaterialListing(
        id: id,
        name: 'Listing Sample',
        category: 'PET',
        weightKg: 15.0,
        condition: 'clean',
        price: 0,
        isFree: true,
        generalLocation: 'Bandung',
        description: 'Sampel deskripsi',
        createdAt: DateTime.now(),
      ),
      matches: [
        MaterialListingMatchItem(
          request: _mockRequests.first,
          matchReasons: ['category_match', 'weight_match', 'condition_match'],
          matchReasonsDetail: {
            'category_match': 'Kategori material sesuai.',
            'weight_match': 'Berat mencukupi.',
            'condition_match': 'Kondisi memenuhi syarat.',
          },
          matchScore: 90,
          scoreExplanation: 'Skor dihitung berbasis aturan.',
        ),
      ],
      total: 1,
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
    return HandoverItem(
      id: 1,
      listingId: listingId,
      ownerId: 2,
      requesterId: 1,
      requestedWeightKg: requestedWeightKg,
      status: 'pending',
      note: note,
      listingName: 'Material Plastik Bersih',
      ownerName: 'Ibu Siti',
      requesterName: 'Saya (Pengguna)',
      createdAt: DateTime.now(),
    );
  }

  @override
  Future<HandoverItem> updateHandoverStatus({
    required int handoverId,
    required String status,
    double? agreedWeightKg,
    double? actualWeightKg,
    String? note,
  }) async {
    return HandoverItem(
      id: handoverId,
      listingId: 1,
      ownerId: 2,
      requesterId: 1,
      requestedWeightKg: 10.0,
      status: status,
      agreedWeightKg: agreedWeightKg,
      actualWeightKg: actualWeightKg,
      note: note,
      listingName: 'Material Plastik Bersih',
      ownerName: 'Ibu Siti',
      requesterName: 'Saya (Pengguna)',
      createdAt: DateTime.now(),
    );
  }
}
