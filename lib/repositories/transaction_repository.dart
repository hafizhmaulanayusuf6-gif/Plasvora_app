import '../core/network/api_client.dart';
import '../core/network/api_config.dart';
import '../models/handover_item.dart';
import '../models/material_request_item.dart';

abstract class TransactionRepository {
  Future<List<MaterialRequestItem>> getMaterialRequests();
  Future<MaterialRequestItem> createMaterialRequest({
    required String materialCategory,
    required double requestedWeightKg,
    required String minimumCondition,
    required String generalLocation,
    required String intendedUse,
  });
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
  Future<List<MaterialRequestItem>> getMaterialRequests() async {
    final response = await apiClient.get(
      ApiConfig.materialRequests,
      requiresAuth: false,
    );
    if (response is Map<String, dynamic> && response['data'] is List) {
      return (response['data'] as List)
          .map((item) => MaterialRequestItem.fromJson(item as Map<String, dynamic>))
          .toList();
    }
    throw ApiException('Format respons material-requests tidak valid');
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
  Future<List<HandoverItem>> getHandoverRequests() async {
    final response = await apiClient.get(
      ApiConfig.handoverRequests,
      requiresAuth: true,
    );
    if (response is Map<String, dynamic> && response['data'] is List) {
      return (response['data'] as List)
          .map((item) => HandoverItem.fromJson(item as Map<String, dynamic>))
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

