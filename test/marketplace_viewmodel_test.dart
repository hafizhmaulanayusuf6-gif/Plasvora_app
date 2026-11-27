import 'package:flutter_test/flutter_test.dart';
import 'package:plasvora/core/network/api_client.dart';
import 'package:plasvora/models/impact_summary.dart';
import 'package:plasvora/models/material_listing.dart';
import 'package:plasvora/repositories/material_repository.dart';
import 'package:plasvora/viewmodels/marketplace_viewmodel.dart';

/// Fake repository for isolated MarketplaceViewModel unit testing
class FakeMaterialRepository implements MaterialRepository {
  String? lastCategory;
  String? lastQuery;
  String? lastCondition;
  double? lastMinWeight;
  double? lastMaxWeight;
  String? lastLocation;

  List<MaterialListing> stubbedListings = [];
  bool shouldThrowError = false;
  String errorMessage = 'Koneksi internet bermasalah';

  MaterialListing? stubbedDetail;
  bool detailShouldThrow = false;

  @override
  Future<List<MaterialListing>> getMaterials({
    String? category,
    String? query,
    String? condition,
    double? minWeight,
    double? maxWeight,
    String? location,
  }) async {
    lastCategory = category;
    lastQuery = query;
    lastCondition = condition;
    lastMinWeight = minWeight;
    lastMaxWeight = maxWeight;
    lastLocation = location;

    if (shouldThrowError) {
      throw ApiException(errorMessage);
    }
    return stubbedListings;
  }

  @override
  Future<MaterialListing> getMaterialDetail(int id) async {
    if (detailShouldThrow) {
      throw ApiException('Material tidak ditemukan');
    }
    if (stubbedDetail != null && stubbedDetail!.id == id) {
      return stubbedDetail!;
    }
    return MaterialListing(
      id: id,
      name: 'Detail Material #$id',
      category: 'PET',
      weightKg: 10.0,
      condition: 'clean',
      price: 0,
      isFree: true,
      generalLocation: 'Jakarta',
      description: 'Deskripsi detail',
      ownerName: 'Pak Budi',
      createdAt: DateTime.now(),
    );
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
    return MaterialListing(
      id: 999,
      name: name,
      category: category,
      weightKg: weightKg,
      condition: condition,
      price: price,
      isFree: isFree,
      generalLocation: generalLocation,
      originDestinationId: originDestinationId,
      originLabel: originLabel,
      description: description,
      imageUrl: imagePath,
      createdAt: DateTime.now(),
    );
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
    return MaterialListing(
      id: id,
      name: name ?? 'Updated Material #$id',
      category: category ?? 'PET',
      weightKg: weightKg ?? 5.0,
      condition: condition ?? 'clean',
      price: price ?? 0,
      isFree: isFree ?? true,
      generalLocation: generalLocation ?? 'Bandung',
      originDestinationId: clearOrigin ? null : originDestinationId,
      originLabel: clearOrigin ? null : originLabel,
      description: description ?? '',
      imageUrl: imagePath,
      createdAt: DateTime.now(),
    );
  }

  @override
  Future<void> toggleFavorite(int id) async {}

  @override
  void clearUserData() {}

  @override
  Future<ImpactSummary> getImpactSummary() async {
    return ImpactSummary(
      listedCount: 1,
      listedWeightKg: 10.0,
      availableCount: 1,
      availableWeightKg: 10.0,
      handedOverCount: 0,
      handedOverWeightKg: 0.0,
      confirmedCount: 0,
      confirmedWeightKg: 0.0,
    );
  }
}

void main() {
  group('Marketplace Feature & ViewModel Tests', () {
    late FakeMaterialRepository repository;
    late MarketplaceViewModel viewModel;

    final dummyListing = MaterialListing(
      id: 101,
      ownerId: 5,
      ownerName: 'Ahmad Subardjo',
      name: 'Botol PET Bening Bersih',
      category: 'PET',
      weightKg: 12.5,
      condition: 'clean',
      price: 0,
      isFree: true,
      generalLocation: 'Bandung Kulon',
      distanceKm: null, // Tanpa jarak fiktif
      description: 'Botol plastik PET telah disortir dan dicuci.',
      imageUrl: 'https://storage.plasvora.id/materials/pet.jpg',
      status: 'available',
      createdAt: DateTime.parse('2026-11-14T08:00:00Z'),
    );

    setUp(() {
      repository = FakeMaterialRepository();
      repository.stubbedListings = [dummyListing];
      viewModel = MarketplaceViewModel(materialRepository: repository);
    });

    test('1. Mapping material dari respons API akurat dan aman dari jarak fiktif', () {
      final json = {
        'id': '101',
        'owner_id': '5',
        'name': 'Galon PC Bekas',
        'category': 'OTHER',
        'weight_kg': '15.50',
        'condition': 'slightly_dirty',
        'price': '25000.00',
        'is_free': 0,
        'general_location': 'Surabaya Timur',
        'distance_km': null,
        'description': 'Galon utuh layak guna.',
        'owner': {
          'id': 5,
          'name': 'Ibu Siti',
        },
        'created_at': '2026-11-14T09:00:00Z',
      };

      final item = MaterialListing.fromJson(json);

      expect(item.id, 101);
      expect(item.ownerId, 5);
      expect(item.ownerName, 'Ibu Siti');
      expect(item.name, 'Galon PC Bekas');
      expect(item.category, 'OTHER');
      expect(item.categoryLabel, 'Lainnya');
      expect(item.weightKg, 15.5);
      expect(item.condition, 'slightly_dirty');
      expect(item.conditionLabel, 'Sedikit Kotor');
      expect(item.price, 25000);
      expect(item.isFree, false);
      expect(item.formattedPrice, 'Rp 25.000');
      expect(item.generalLocation, 'Surabaya Timur');
      expect(item.distanceKm, isNull); // Tidak mengarang jarak fiktif
    });

    test('2. Pencarian mengirim query yang benar ke backend', () async {
      viewModel.updateSearchQuery('tutup botol', immediate: true);
      await Future.delayed(const Duration(milliseconds: 10));

      expect(repository.lastQuery, 'tutup botol');
      expect(viewModel.searchQuery, 'tutup botol');
    });

    test('3. Filter kategori memetakan Lainnya ke OTHER dan kondisi diteruskan ke backend', () async {
      viewModel.selectCategory('Lainnya');
      await Future.delayed(const Duration(milliseconds: 10));

      expect(repository.lastCategory, 'OTHER');
      expect(viewModel.selectedCategory, 'Lainnya');

      viewModel.applyAdvancedFilters(condition: 'slightly_dirty');
      await Future.delayed(const Duration(milliseconds: 10));

      expect(repository.lastCondition, 'slightly_dirty');
      expect(viewModel.selectedCondition, 'slightly_dirty');
    });

    test('4. Filter rentang berat (min_weight & max_weight) dikirim dengan benar', () async {
      viewModel.applyAdvancedFilters(
        minWeight: 5.0,
        maxWeight: 20.0,
      );
      await Future.delayed(const Duration(milliseconds: 10));

      expect(repository.lastMinWeight, 5.0);
      expect(repository.lastMaxWeight, 20.0);
      expect(viewModel.minWeight, 5.0);
      expect(viewModel.maxWeight, 20.0);
      expect(viewModel.hasActiveAdvancedFilters, isTrue);
    });

    test('5. Filter lokasi dikirim dengan benar ke backend', () async {
      viewModel.applyAdvancedFilters(location: 'Bandung');
      await Future.delayed(const Duration(milliseconds: 10));

      expect(repository.lastLocation, 'Bandung');
      expect(viewModel.locationFilter, 'Bandung');
    });

    test('6. Reset filter mengembalikan seluruh parameter ke kondisi awal', () async {
      viewModel.applyAdvancedFilters(
        category: 'HDPE',
        condition: 'dirty',
        minWeight: 10.0,
        maxWeight: 50.0,
        location: 'Yogyakarta',
      );
      await Future.delayed(const Duration(milliseconds: 10));
      expect(viewModel.hasActiveAdvancedFilters, isTrue);

      viewModel.resetFilters();
      await Future.delayed(const Duration(milliseconds: 10));

      expect(viewModel.selectedCategory, 'Semua');
      expect(viewModel.selectedCondition, 'Semua');
      expect(viewModel.minWeight, isNull);
      expect(viewModel.maxWeight, isNull);
      expect(viewModel.locationFilter, isNull);
      expect(viewModel.searchQuery, '');
      expect(viewModel.hasActiveAdvancedFilters, isFalse);
      expect(repository.lastCategory, isNull);
      expect(repository.lastCondition, isNull);
    });

    test('7. Penanganan data kosong menghasilkan list kosong tanpa error', () async {
      repository.stubbedListings = [];
      await viewModel.loadListings();

      expect(viewModel.listings, isEmpty);
      expect(viewModel.errorMessage, isNull);
      expect(viewModel.isLoading, isFalse);
    });

    test('8. Penanganan error API menangkap pesan error dan mengosongkan list', () async {
      repository.shouldThrowError = true;
      repository.errorMessage = 'Gagal terhubung ke server backend';
      await viewModel.loadListings();

      expect(viewModel.listings, isEmpty);
      expect(viewModel.errorMessage, 'Gagal terhubung ke server backend');
      expect(viewModel.isLoading, isFalse);
    });

    test('9. Pembukaan detail material mengambil data dari endpoint show/{id}', () async {
      final detail = await viewModel.getMaterialDetail(101);

      expect(detail.id, 101);
      expect(detail.ownerName, 'Pak Budi');
      expect(detail.category, 'PET');
    });

    test('10. Penanganan detail material yang tidak ditemukan melempar ApiException', () async {
      repository.detailShouldThrow = true;

      expect(
        () => viewModel.getMaterialDetail(999),
        throwsA(isA<ApiException>()),
      );
    });
  });
}

