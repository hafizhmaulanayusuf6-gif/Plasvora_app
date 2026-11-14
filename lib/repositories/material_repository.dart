import '../core/constants/app_assets.dart';
import '../core/network/api_client.dart';
import '../core/network/api_config.dart';
import '../models/impact_summary.dart';
import '../models/material_listing.dart';

abstract class MaterialRepository {
  Future<List<MaterialListing>> getMaterials({
    String? category,
    String? query,
    String? condition,
    double? minWeight,
    double? maxWeight,
    String? location,
  });
  Future<MaterialListing> getMaterialDetail(int id);
  Future<MaterialListing> createMaterial({
    required String name,
    required String category,
    required double weightKg,
    required String condition,
    required int price,
    required bool isFree,
    required String generalLocation,
    required String description,
  });
  Future<void> toggleFavorite(int id);
  Future<ImpactSummary> getImpactSummary();
}

class ApiMaterialRepository implements MaterialRepository {
  final ApiClient apiClient;
  final Set<int> _favoriteIds = {};

  ApiMaterialRepository({required this.apiClient});

  @override
  Future<List<MaterialListing>> getMaterials({
    String? category,
    String? query,
    String? condition,
    double? minWeight,
    double? maxWeight,
    String? location,
  }) async {
    final params = <String>[];
    if (category != null && category.isNotEmpty && category != 'Semua') {
      final catParam = category == 'Lainnya' ? 'OTHER' : category;
      params.add('category=${Uri.encodeQueryComponent(catParam)}');
    }
    if (query != null && query.trim().isNotEmpty) {
      params.add('q=${Uri.encodeQueryComponent(query.trim())}');
    }
    if (condition != null && condition.isNotEmpty && condition != 'Semua') {
      params.add('condition=${Uri.encodeQueryComponent(condition)}');
    }
    if (minWeight != null && minWeight > 0) {
      params.add('min_weight=$minWeight');
    }
    if (maxWeight != null && maxWeight > 0) {
      params.add('max_weight=$maxWeight');
    }
    if (location != null && location.trim().isNotEmpty) {
      params.add('location=${Uri.encodeQueryComponent(location.trim())}');
    }

    final queryString = params.isNotEmpty ? '?${params.join('&')}' : '';
    final url = '${ApiConfig.materials}$queryString';

    final response = await apiClient.get(url, requiresAuth: false);
    if (response is Map<String, dynamic> && response['data'] is List) {
      final list = (response['data'] as List)
          .map((item) {
            final listing = MaterialListing.fromJson(item as Map<String, dynamic>);
            return listing.copyWith(
              isFavorited: _favoriteIds.contains(listing.id),
              localAsset: _resolveLocalFallbackAsset(listing.category),
            );
          })
          .toList();
      return list;
    }
    throw ApiException('Format respons materials tidak valid');
  }

  @override
  Future<MaterialListing> getMaterialDetail(int id) async {
    final response = await apiClient.get(
      ApiConfig.materialDetail(id),
      requiresAuth: false,
    );
    if (response is Map<String, dynamic> && response['data'] != null) {
      final listing = MaterialListing.fromJson(
        response['data'] as Map<String, dynamic>,
      );
      return listing.copyWith(
        isFavorited: _favoriteIds.contains(listing.id),
        localAsset: _resolveLocalFallbackAsset(listing.category),
      );
    }
    throw ApiException('Material tidak ditemukan');
  }

  @override
  Future<MaterialListing> createMaterial({
    required String name,
    required String category,
    required double weightKg,
    required String condition,
    required int price,
    required bool isFree,
    required String generalLocation,
    required String description,
  }) async {
    final response = await apiClient.post(
      ApiConfig.materials,
      body: {
        'name': name,
        'category': category,
        'weight_kg': weightKg,
        'condition': condition,
        'price': price,
        'is_free': isFree,
        'general_location': generalLocation,
        'description': description,
      },
      requiresAuth: true,
    );

    if (response is Map<String, dynamic> && response['data'] != null) {
      return MaterialListing.fromJson(response['data'] as Map<String, dynamic>);
    }
    throw ApiException('Gagal membuat listing material');
  }

  @override
  Future<void> toggleFavorite(int id) async {
    if (_favoriteIds.contains(id)) {
      _favoriteIds.remove(id);
    } else {
      _favoriteIds.add(id);
    }
  }

  @override
  Future<ImpactSummary> getImpactSummary() async {
    final response = await apiClient.get(
      ApiConfig.impactSummary,
      requiresAuth: false,
    );
    if (response is Map<String, dynamic> && response['data'] != null) {
      return ImpactSummary.fromJson(response['data'] as Map<String, dynamic>);
    }
    throw ApiException('Format respons impact summary tidak valid');
  }

  String? _resolveLocalFallbackAsset(String category) {
    switch (category.toUpperCase()) {
      case 'HDPE':
        return AppAssets.marketplaceHdpeCaps;
      case 'PET':
        return AppAssets.marketplacePetFlakes;
      case 'PP':
        return AppAssets.marketplacePpContainers;
      default:
        return AppAssets.marketplaceHdpeJerrycan;
    }
  }
}

class MockMaterialRepository implements MaterialRepository {
  final bool simulateDelay;

  MockMaterialRepository({this.simulateDelay = true});

  final List<MaterialListing> _items = [
    MaterialListing(
      id: 101,
      ownerId: 1,
      name: 'Tutup Botol HDPE Campur',
      category: 'HDPE',
      weightKg: 5.0,
      condition: 'clean',
      price: 15000,
      isFree: false,
      generalLocation: 'Jakarta Selatan',
      distanceKm: 2.8,
      description: 'Tutup botol HDPE aneka warna, telah dipilah dan dicuci bersih siap diolah.',
      localAsset: AppAssets.marketplaceHdpeCaps,
      status: 'available',
      createdAt: DateTime.now().subtract(const Duration(hours: 3)),
    ),
    MaterialListing(
      id: 102,
      ownerId: 2,
      name: 'Serpihan PET Bening (Flakes)',
      category: 'PET',
      weightKg: 8.0,
      condition: 'clean',
      price: 0,
      isFree: true,
      generalLocation: 'Tangerang',
      distanceKm: 4.2,
      description: 'Serpihan botol mineral bening bersih siap masuk mesin ekstrusi daur ulang.',
      localAsset: AppAssets.marketplacePetFlakes,
      status: 'available',
      createdAt: DateTime.now().subtract(const Duration(hours: 6)),
    ),
    MaterialListing(
      id: 103,
      ownerId: 3,
      name: 'Jerigen HDPE Industri',
      category: 'HDPE',
      weightKg: 12.0,
      condition: 'light',
      price: 28000,
      isFree: false,
      generalLocation: 'Depok',
      distanceKm: 6.7,
      description: 'Jerigen tebal warna biru eks wadah non-B3, kondisi utuh dan siap lebur.',
      localAsset: AppAssets.marketplaceHdpeJerrycan,
      status: 'available',
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
    MaterialListing(
      id: 104,
      ownerId: 4,
      name: 'Wadah Kemasan PP',
      category: 'PP',
      weightKg: 6.0,
      condition: 'clean',
      price: 20000,
      isFree: false,
      generalLocation: 'Bekasi',
      distanceKm: 8.3,
      description: 'Kemasan food grade bening microwave safe telah dicuci bersih dan kering.',
      localAsset: AppAssets.marketplacePpContainers,
      status: 'available',
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
    ),
  ];

  @override
  Future<List<MaterialListing>> getMaterials({
    String? category,
    String? query,
    String? condition,
    double? minWeight,
    double? maxWeight,
    String? location,
  }) async {
    if (simulateDelay) {
      // Simulate slight network delay for smooth UX
      await Future.delayed(const Duration(milliseconds: 200));
    }

    return _items.where((item) {
      final matchesCategory =
          category == null ||
          category == 'Semua' ||
          item.category.toLowerCase() == category.toLowerCase() ||
          (category == 'OTHER' && item.category.toLowerCase() == 'lainnya');

      final matchesQuery =
          query == null ||
          query.trim().isEmpty ||
          item.name.toLowerCase().contains(query.toLowerCase()) ||
          item.generalLocation.toLowerCase().contains(query.toLowerCase()) ||
          item.category.toLowerCase().contains(query.toLowerCase());

      final matchesCondition =
          condition == null ||
          condition == 'Semua' ||
          item.condition.toLowerCase() == condition.toLowerCase();

      final matchesMinWeight =
          minWeight == null || item.weightKg >= minWeight;

      final matchesMaxWeight =
          maxWeight == null || item.weightKg <= maxWeight;

      final matchesLocation =
          location == null ||
          location.trim().isEmpty ||
          item.generalLocation.toLowerCase().contains(location.toLowerCase());

      return matchesCategory &&
          matchesQuery &&
          matchesCondition &&
          matchesMinWeight &&
          matchesMaxWeight &&
          matchesLocation;
    }).toList();
  }

  @override
  Future<void> toggleFavorite(int id) async {
    final index = _items.indexWhere((element) => element.id == id);
    if (index != -1) {
      final item = _items[index];
      _items[index] = item.copyWith(isFavorited: !item.isFavorited);
    }
  }

  @override
  Future<MaterialListing> getMaterialDetail(int id) async {
    final item = _items.firstWhere(
      (element) => element.id == id,
      orElse: () => _items.first,
    );
    return item;
  }

  @override
  Future<MaterialListing> createMaterial({
    required String name,
    required String category,
    required double weightKg,
    required String condition,
    required int price,
    required bool isFree,
    required String generalLocation,
    required String description,
  }) async {
    final newItem = MaterialListing(
      id: DateTime.now().millisecondsSinceEpoch,
      name: name,
      category: category,
      weightKg: weightKg,
      condition: condition,
      price: price,
      isFree: isFree,
      generalLocation: generalLocation,
      description: description,
      createdAt: DateTime.now(),
    );
    _items.insert(0, newItem);
    return newItem;
  }

  @override
  Future<ImpactSummary> getImpactSummary() async {
    final totalListedKg = _items.fold<double>(
      0.0,
      (sum, item) => sum + item.weightKg,
    );
    final availableItems = _items.where((i) => i.status == 'available');
    final availableKg = availableItems.fold<double>(
      0.0,
      (sum, item) => sum + item.weightKg,
    );

    return ImpactSummary(
      listedCount: _items.length,
      listedWeightKg: totalListedKg,
      availableCount: availableItems.length,
      availableWeightKg: availableKg,
      handedOverCount: 0,
      handedOverWeightKg: 0.0,
      confirmedCount: 0,
      confirmedWeightKg: 0.0,
    );
  }
}
