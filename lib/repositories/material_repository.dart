import '../core/constants/app_assets.dart';
import '../core/network/api_client.dart';
import '../core/network/api_config.dart';
import '../models/impact_summary.dart';
import '../models/material_listing.dart';

/// Validasi ketat pasangan origin sebelum request dikirim.
/// Mengembalikan true bila pasangan valid disertakan, false bila keduanya absen.
/// Melempar ArgumentError untuk half-pair, ID <= 0, label whitespace-only, atau konflik clearOrigin.
bool _validateOriginPair({
  int? originDestinationId,
  String? originLabel,
  bool clearOrigin = false,
}) {
  final hasAnyOriginInput = originDestinationId != null || originLabel != null;

  if (clearOrigin && hasAnyOriginInput) {
    throw ArgumentError(
      'clearOrigin tidak boleh dikombinasikan dengan originDestinationId atau originLabel.',
    );
  }

  if (!hasAnyOriginInput) {
    return false;
  }

  if (originDestinationId == null || originDestinationId <= 0) {
    throw ArgumentError(
      'originDestinationId wajib berupa angka positif saat originLabel disertakan.',
    );
  }

  if (originLabel == null || originLabel.trim().isEmpty) {
    throw ArgumentError(
      'originLabel wajib diisi (tidak boleh kosong/spasi) saat originDestinationId disertakan.',
    );
  }

  return true;
}

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
    int? originDestinationId,
    String? originLabel,
    String? imagePath,
  });
  Future<MaterialListing> updateMaterial({
    required int id,
    String? name,
    String? category,
    double? weightKg,
    String? condition,
    int? price,
    bool? isFree,
    String? generalLocation,
    String? description,
    int? originDestinationId,
    String? originLabel,
    bool clearOrigin = false,
    String? imagePath,
  });
  Future<void> toggleFavorite(int id);
  Future<ImpactSummary> getImpactSummary();
  void clearUserData();
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
    int? originDestinationId,
    String? originLabel,
    String? imagePath,
  }) async {
    final hasValidOriginPair = _validateOriginPair(
      originDestinationId: originDestinationId,
      originLabel: originLabel,
    );
    final hasImage = imagePath != null && imagePath.trim().isNotEmpty;
    final dynamic response;

    if (hasImage) {
      final fields = <String, String>{
        'name': name,
        'category': category,
        'weight_kg': weightKg.toString(),
        'condition': condition,
        'price': price.toString(),
        'is_free': isFree ? '1' : '0',
        'general_location': generalLocation,
        'description': description,
      };
      if (hasValidOriginPair) {
        fields['origin_destination_id'] = originDestinationId.toString();
        fields['origin_label'] = originLabel!.trim();
      }

      response = await apiClient.postMultipart(
        ApiConfig.materials,
        fields: fields,
        fileField: 'image',
        filePath: imagePath.trim(),
        requiresAuth: true,
      );
    } else {
      final body = <String, dynamic>{
        'name': name,
        'category': category,
        'weight_kg': weightKg,
        'condition': condition,
        'price': price,
        'is_free': isFree,
        'general_location': generalLocation,
        'description': description,
      };
      if (hasValidOriginPair) {
        body['origin_destination_id'] = originDestinationId;
        body['origin_label'] = originLabel!.trim();
      }

      response = await apiClient.post(
        ApiConfig.materials,
        body: body,
        requiresAuth: true,
      );
    }

    if (response is Map<String, dynamic> && response['data'] != null) {
      final listing = MaterialListing.fromJson(
        response['data'] as Map<String, dynamic>,
      );
      return listing.copyWith(
        localAsset: _resolveLocalFallbackAsset(listing.category),
      );
    }
    throw ApiException('Gagal membuat listing material');
  }

  @override
  Future<MaterialListing> updateMaterial({
    required int id,
    String? name,
    String? category,
    double? weightKg,
    String? condition,
    int? price,
    bool? isFree,
    String? generalLocation,
    String? description,
    int? originDestinationId,
    String? originLabel,
    bool clearOrigin = false,
    String? imagePath,
  }) async {
    final hasValidOriginPair = _validateOriginPair(
      originDestinationId: originDestinationId,
      originLabel: originLabel,
      clearOrigin: clearOrigin,
    );
    final hasImage = imagePath != null && imagePath.trim().isNotEmpty;
    final dynamic response;

    if (hasImage) {
      final fields = <String, String>{'_method': 'PATCH'};
      if (name != null) fields['name'] = name;
      if (category != null) fields['category'] = category;
      if (weightKg != null) fields['weight_kg'] = weightKg.toString();
      if (condition != null) fields['condition'] = condition;
      if (price != null) fields['price'] = price.toString();
      if (isFree != null) fields['is_free'] = isFree ? '1' : '0';
      if (generalLocation != null) fields['general_location'] = generalLocation;
      if (description != null) fields['description'] = description;
      if (clearOrigin) {
        fields['origin_destination_id'] = '';
        fields['origin_label'] = '';
      } else if (hasValidOriginPair) {
        fields['origin_destination_id'] = originDestinationId.toString();
        fields['origin_label'] = originLabel!.trim();
      }

      response = await apiClient.postMultipart(
        ApiConfig.materialDetail(id),
        fields: fields,
        fileField: 'image',
        filePath: imagePath.trim(),
        requiresAuth: true,
      );
    } else {
      final body = <String, dynamic>{};
      if (name != null) body['name'] = name;
      if (category != null) body['category'] = category;
      if (weightKg != null) body['weight_kg'] = weightKg;
      if (condition != null) body['condition'] = condition;
      if (price != null) body['price'] = price;
      if (isFree != null) body['is_free'] = isFree;
      if (generalLocation != null) body['general_location'] = generalLocation;
      if (description != null) body['description'] = description;
      if (clearOrigin) {
        body['origin_destination_id'] = null;
        body['origin_label'] = null;
      } else if (hasValidOriginPair) {
        body['origin_destination_id'] = originDestinationId;
        body['origin_label'] = originLabel!.trim();
      }

      response = await apiClient.patch(
        ApiConfig.materialDetail(id),
        body: body,
        requiresAuth: true,
      );
    }

    if (response is Map<String, dynamic> && response['data'] != null) {
      final listing = MaterialListing.fromJson(
        response['data'] as Map<String, dynamic>,
      );
      return listing.copyWith(
        isFavorited: _favoriteIds.contains(listing.id),
        localAsset: _resolveLocalFallbackAsset(listing.category),
      );
    }
    throw ApiException('Gagal memperbarui listing material');
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
  void clearUserData() {
    _favoriteIds.clear();
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
    int? originDestinationId,
    String? originLabel,
    String? imagePath,
  }) async {
    final hasValidOriginPair = _validateOriginPair(
      originDestinationId: originDestinationId,
      originLabel: originLabel,
    );

    final newItem = MaterialListing(
      id: DateTime.now().millisecondsSinceEpoch,
      name: name,
      category: category,
      weightKg: weightKg,
      condition: condition,
      price: price,
      isFree: isFree,
      generalLocation: generalLocation,
      originDestinationId: hasValidOriginPair ? originDestinationId : null,
      originLabel: hasValidOriginPair ? originLabel!.trim() : null,
      description: description,
      imageUrl: imagePath,
      createdAt: DateTime.now(),
    );
    _items.insert(0, newItem);
    return newItem;
  }

  @override
  Future<MaterialListing> updateMaterial({
    required int id,
    String? name,
    String? category,
    double? weightKg,
    String? condition,
    int? price,
    bool? isFree,
    String? generalLocation,
    String? description,
    int? originDestinationId,
    String? originLabel,
    bool clearOrigin = false,
    String? imagePath,
  }) async {
    final hasValidOriginPair = _validateOriginPair(
      originDestinationId: originDestinationId,
      originLabel: originLabel,
      clearOrigin: clearOrigin,
    );

    final idx = _items.indexWhere((element) => element.id == id);
    if (idx == -1) {
      throw ApiException('Material tidak ditemukan', statusCode: 404);
    }
    final current = _items[idx];

    final updated = MaterialListing(
      id: current.id,
      ownerId: current.ownerId,
      ownerName: current.ownerName,
      ownerPhone: current.ownerPhone,
      name: name ?? current.name,
      category: category ?? current.category,
      weightKg: weightKg ?? current.weightKg,
      condition: condition ?? current.condition,
      price: (isFree == true) ? 0 : (price ?? current.price),
      isFree: isFree ?? current.isFree,
      generalLocation: generalLocation ?? current.generalLocation,
      originDestinationId: clearOrigin
          ? null
          : (hasValidOriginPair
              ? originDestinationId
              : current.originDestinationId),
      originLabel: clearOrigin
          ? null
          : (hasValidOriginPair ? originLabel!.trim() : current.originLabel),
      distanceKm: current.distanceKm,
      description: description ?? current.description,
      imageUrl: (imagePath != null && imagePath.trim().isNotEmpty)
          ? imagePath.trim()
          : current.imageUrl,
      localAsset: current.localAsset,
      status: current.status,
      isFavorited: current.isFavorited,
      createdAt: current.createdAt,
    );
    _items[idx] = updated;
    return updated;
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

  @override
  void clearUserData() {
    for (var i = 0; i < _items.length; i++) {
      if (_items[i].isFavorited) {
        _items[i] = _items[i].copyWith(isFavorited: false);
      }
    }
  }
}
