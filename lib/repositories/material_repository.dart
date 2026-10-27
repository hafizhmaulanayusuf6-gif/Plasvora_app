import '../core/constants/app_assets.dart';
import '../models/material_listing.dart';

abstract class MaterialRepository {
  Future<List<MaterialListing>> getMaterials({String? category, String? query});
  Future<void> toggleFavorite(int id);
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
  }) async {
    if (simulateDelay) {
      // Simulate slight network delay for smooth UX
      await Future.delayed(const Duration(milliseconds: 200));
    }

    return _items.where((item) {
      final matchesCategory =
          category == null ||
          category == 'Semua' ||
          item.category.toLowerCase() == category.toLowerCase();

      final matchesQuery =
          query == null ||
          query.trim().isEmpty ||
          item.name.toLowerCase().contains(query.toLowerCase()) ||
          item.generalLocation.toLowerCase().contains(query.toLowerCase()) ||
          item.category.toLowerCase().contains(query.toLowerCase());

      return matchesCategory && matchesQuery;
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
}
