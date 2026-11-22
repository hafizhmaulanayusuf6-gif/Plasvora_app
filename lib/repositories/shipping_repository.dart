import '../core/network/api_client.dart';
import '../core/network/api_config.dart';
import '../models/shipping_destination.dart';

abstract class ShippingRepository {
  Future<List<ShippingDestination>> searchDestinations({
    required String query,
    int limit = 10,
    int offset = 0,
  });

  Future<ShippingEstimateResult> estimateShipping({
    required int listingId,
    required int addressId,
  });
}

class ApiShippingRepository implements ShippingRepository {
  final ApiClient apiClient;

  ApiShippingRepository({required this.apiClient});

  @override
  Future<List<ShippingDestination>> searchDestinations({
    required String query,
    int limit = 10,
    int offset = 0,
  }) async {
    final uri = Uri.parse(ApiConfig.shippingDestinations).replace(
      queryParameters: {
        'search': query.trim(),
        'limit': limit.toString(),
        'offset': offset.toString(),
      },
    );

    final response = await apiClient.get(
      uri.toString(),
      requiresAuth: true,
    );

    if (response is Map<String, dynamic> && response['data'] is List) {
      return (response['data'] as List)
          .whereType<Map<String, dynamic>>()
          .map(ShippingDestination.fromJson)
          .toList();
    }

    throw ApiException('Format respons pencarian lokasi pengiriman tidak valid.');
  }

  @override
  Future<ShippingEstimateResult> estimateShipping({
    required int listingId,
    required int addressId,
  }) async {
    // Klien hanya mengirim listing_id dan address_id; server menentukan origin, destination, weight, courier, dan price.
    final response = await apiClient.post(
      ApiConfig.shippingEstimate,
      body: {
        'listing_id': listingId,
        'address_id': addressId,
      },
      requiresAuth: true,
    );

    if (response is Map<String, dynamic> &&
        response['data'] is Map<String, dynamic>) {
      return ShippingEstimateResult.fromJson(
        response['data'] as Map<String, dynamic>,
        message: response['message']?.toString(),
      );
    }

    throw ApiException('Format respons estimasi ongkos kirim tidak valid.');
  }
}

/// Mock repository deterministik untuk pengujian / fallback offline (tidak dipakai pada USE_API=true).
class MockShippingRepository implements ShippingRepository {
  @override
  Future<List<ShippingDestination>> searchDestinations({
    required String query,
    int limit = 10,
    int offset = 0,
  }) async {
    final keyword = query.trim().toLowerCase();
    const samples = [
      ShippingDestination(
        destinationId: 4949,
        label: 'BRAGA, SUMUR BANDUNG, BANDUNG, JAWA BARAT, 40111',
        provinceName: 'JAWA BARAT',
        cityName: 'BANDUNG',
        districtName: 'SUMUR BANDUNG',
        subdistrictName: 'BRAGA',
        postalCode: '40111',
      ),
      ShippingDestination(
        destinationId: 6157,
        label: 'BABAKANKARET, CIANJUR, KAB. CIANJUR, JAWA BARAT, 43211',
        provinceName: 'JAWA BARAT',
        cityName: 'KAB. CIANJUR',
        districtName: 'CIANJUR',
        subdistrictName: 'BABAKANKARET',
        postalCode: '43211',
      ),
    ];

    return samples
        .where((item) => item.label.toLowerCase().contains(keyword))
        .skip(offset)
        .take(limit)
        .toList();
  }

  @override
  Future<ShippingEstimateResult> estimateShipping({
    required int listingId,
    required int addressId,
  }) async {
    return ShippingEstimateResult(
      listing: ShippingEstimateListingSummary(
        id: listingId,
        name: 'Material Simulasi',
        weightKg: 2.0,
        weightGrams: 2000,
        originDestinationId: 4949,
        originLabel: 'BRAGA, SUMUR BANDUNG, BANDUNG',
      ),
      destination: ShippingEstimateDestinationSummary(
        addressId: addressId,
        label: 'Rumah',
        destinationId: 6157,
        destinationLabel: 'BABAKANKARET, CIANJUR',
      ),
      options: const [
        ShippingCostOption(
          courierCode: 'jne',
          courierName: 'Jalur Nugraha Ekakurir (JNE)',
          service: 'REG',
          description: 'Layanan Reguler',
          cost: 16000,
          etd: '2-3 day',
        ),
        ShippingCostOption(
          courierCode: 'jnt',
          courierName: 'J&T Express',
          service: 'EZ',
          description: 'Reguler',
          cost: 15000,
          etd: null,
        ),
      ],
      message: 'Estimasi ongkos kirim berhasil diambil.',
    );
  }
}
