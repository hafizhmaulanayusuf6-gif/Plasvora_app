import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:plasvora/core/network/api_client.dart';
import 'package:plasvora/models/activity_item.dart';
import 'package:plasvora/models/gallery_work.dart';
import 'package:plasvora/models/handover_item.dart';
import 'package:plasvora/models/impact_summary.dart';
import 'package:plasvora/models/matching_result.dart';
import 'package:plasvora/models/material_listing.dart';
import 'package:plasvora/models/material_request_item.dart';
import 'package:plasvora/models/order_item.dart';
import 'package:plasvora/models/plastic_analysis.dart';
import 'package:plasvora/models/user_address.dart';
import 'package:plasvora/repositories/activity_repository.dart';
import 'package:plasvora/repositories/address_repository.dart';
import 'package:plasvora/repositories/analysis_repository.dart';
import 'package:plasvora/repositories/auth_repository.dart';
import 'package:plasvora/repositories/gallery_repository.dart';
import 'package:plasvora/repositories/material_repository.dart';
import 'package:plasvora/repositories/order_repository.dart';
import 'package:plasvora/repositories/transaction_repository.dart';
import 'package:plasvora/viewmodels/activity_viewmodel.dart';
import 'package:plasvora/viewmodels/address_viewmodel.dart';
import 'package:plasvora/viewmodels/analysis_viewmodel.dart';
import 'package:plasvora/viewmodels/auth_viewmodel.dart';
import 'package:plasvora/viewmodels/gallery_viewmodel.dart';
import 'package:plasvora/viewmodels/home_viewmodel.dart';
import 'package:plasvora/viewmodels/marketplace_viewmodel.dart';
import 'package:plasvora/viewmodels/matching_viewmodel.dart';
import 'package:plasvora/viewmodels/material_request_viewmodel.dart';
import 'package:plasvora/viewmodels/order_viewmodel.dart';

// ─── Test Fixtures ────────────────────────────────────────────────────────────

UserAddress _address({
  required int id,
  required String label,
  required String recipientName,
  bool isDefault = false,
}) {
  return UserAddress(
    id: id,
    label: label,
    recipientName: recipientName,
    recipientPhone: '6281111111111',
    destinationId: 4949,
    destinationLabel: 'BANDUNG',
    addressDetail: 'Jl. $label No. $id',
    isDefault: isDefault,
  );
}

MaterialListing _listing({
  required int id,
  required String name,
  bool isFavorited = false,
}) {
  return MaterialListing(
    id: id,
    ownerId: 1,
    ownerName: 'Pemilik $id',
    name: name,
    category: 'PET',
    weightKg: 5.0,
    condition: 'clean',
    price: 15000,
    isFree: false,
    generalLocation: 'Bandung',
    description: 'Deskripsi $name',
    isFavorited: isFavorited,
    createdAt: DateTime(2026, 11, 20),
  );
}

MaterialRequestItem _materialRequest({
  required int id,
  required int requesterId,
  required String intendedUse,
}) {
  return MaterialRequestItem(
    id: id,
    requesterId: requesterId,
    materialCategory: 'PET',
    requestedWeightKg: 10.0,
    minimumCondition: 'clean',
    generalLocation: 'Bandung',
    intendedUse: intendedUse,
    status: 'active',
    requesterName: 'Requester $requesterId',
    createdAt: DateTime(2026, 11, 20),
  );
}

GalleryWork _galleryWork({
  required int id,
  required String title,
  int authorId = 1,
  bool likedByMe = false,
  int likesCount = 3,
}) {
  return GalleryWork.fromJson({
    'id': id,
    'title': title,
    'difficulty': 'mudah',
    'status': 'approved',
    'materials': ['Botol PET'],
    'tools': ['Gunting'],
    'steps': ['Potong botol'],
    'video_links': const <String>[],
    'images': const <Map<String, dynamic>>[],
    'likes_count': likesCount,
    'liked_by_me': likedByMe,
    'author': {'id': authorId, 'name': 'Author $authorId'},
    'created_at': '2026-11-20T10:00:00Z',
  });
}

OrderItem _order({
  required int id,
  required String orderNumber,
  int buyerId = 1,
  int sellerId = 2,
}) {
  return OrderItem.fromJson({
    'id': id,
    'order_number': orderNumber,
    'status': 'pending_payment',
    'buyer_id': buyerId,
    'seller_id': sellerId,
    'listing_id': 10,
    'listing_name_snapshot': 'PET $orderNumber',
    'listing_category_snapshot': 'PET',
    'listing_weight_kg_snapshot': 5,
    'item_price': 15000,
    'shipping_cost': 10000,
    'total_amount': 25000,
    'courier_code': 'jne',
    'courier_service': 'REG',
    'created_at': '2026-11-20T10:00:00Z',
  });
}

PlasticAnalysisResult _analysisResult(String id, String title) {
  return ApiAnalysisRepository.mapBackendDataToResult({
    'id': id,
    'declared_category': 'PET',
    'estimated_category': 'PET',
    'recommendations': {
      'object_name': title,
      'object_description': title,
      'material_title': title,
      'polymer_code': 'PET',
    },
  });
}

// ─── Controllable Fake Repositories ───────────────────────────────────────────

class _ControllableActivityRepository implements ActivityRepository {
  Completer<List<ActivityItem>>? activitiesCompleter;
  Completer<List<Map<String, dynamic>>>? analysesCompleter;
  List<ActivityItem> activities = [];
  List<Map<String, dynamic>> analyses = [];

  @override
  Future<List<ActivityItem>> getActivities() {
    if (activitiesCompleter != null) return activitiesCompleter!.future;
    return Future.value(List<ActivityItem>.from(activities));
  }

  @override
  Future<List<Map<String, dynamic>>> getAnalysisHistories() {
    if (analysesCompleter != null) return analysesCompleter!.future;
    return Future.value(List<Map<String, dynamic>>.from(analyses));
  }

  @override
  Future<PlasticAnalysisResult> getAnalysisDetail(int id) async {
    return _analysisResult('$id', 'Analisis #$id');
  }
}

class _ControllableAnalysisRepository implements AnalysisRepository {
  Completer<PlasticAnalysisResult>? submitCompleter;
  PlasticAnalysisResult result = _analysisResult('1', 'Hasil Analisis User A');

  @override
  Future<PlasticAnalysisResult> analyzePlastic(PlasticAnalysisInput input) {
    if (submitCompleter != null) return submitCompleter!.future;
    return Future.value(result);
  }
}

class _ControllableTransactionRepository implements TransactionRepository {
  Completer<List<MaterialRequestItem>>? requestsCompleter;
  Completer<MaterialRequestItem>? createRequestCompleter;
  Completer<void>? cancelRequestCompleter;
  Completer<MaterialRequestMatchingResponse>? requestMatchCompleter;
  Completer<MaterialListingMatchingResponse>? listingMatchCompleter;

  List<MaterialRequestItem> requests = [];
  MaterialRequestMatchingResponse? requestMatchResponse;
  MaterialListingMatchingResponse? listingMatchResponse;

  @override
  Future<List<MaterialRequestItem>> getMaterialRequests({
    String? category,
    String? location,
    String? condition,
  }) {
    if (requestsCompleter != null) return requestsCompleter!.future;
    return Future.value(List<MaterialRequestItem>.from(requests));
  }

  @override
  Future<MaterialRequestItem> getMaterialRequestDetail(int id) async =>
      requests.firstWhere((r) => r.id == id);

  @override
  Future<MaterialRequestItem> createMaterialRequest({
    required String materialCategory,
    required double requestedWeightKg,
    required String minimumCondition,
    required String generalLocation,
    required String intendedUse,
  }) {
    if (createRequestCompleter != null) return createRequestCompleter!.future;
    final created = _materialRequest(
      id: 901,
      requesterId: 1,
      intendedUse: intendedUse,
    );
    return Future.value(created);
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
    return _materialRequest(
      id: id,
      requesterId: 1,
      intendedUse: intendedUse ?? 'Updated',
    );
  }

  @override
  Future<void> cancelMaterialRequest(int id) {
    if (cancelRequestCompleter != null) return cancelRequestCompleter!.future;
    return Future.value();
  }

  @override
  Future<MaterialRequestMatchingResponse> getMatchesForRequest(int id) {
    if (requestMatchCompleter != null) return requestMatchCompleter!.future;
    return Future.value(
      requestMatchResponse ??
          MaterialRequestMatchingResponse(
            request: _materialRequest(
              id: id,
              requesterId: 1,
              intendedUse: 'Match Request $id',
            ),
            matches: const [],
            total: 0,
            note: 'Rule-based',
          ),
    );
  }

  @override
  Future<MaterialListingMatchingResponse> getMatchesForListing(int id) {
    if (listingMatchCompleter != null) return listingMatchCompleter!.future;
    return Future.value(
      listingMatchResponse ??
          MaterialListingMatchingResponse(
            listing: _listing(id: id, name: 'Listing $id'),
            matches: const [],
            total: 0,
            note: 'Rule-based',
          ),
    );
  }

  @override
  Future<List<HandoverItem>> getHandoverRequests() async => const [];

  @override
  Future<HandoverItem> createHandoverRequest({
    required int listingId,
    required double requestedWeightKg,
    String? note,
  }) =>
      throw UnimplementedError();

  @override
  Future<HandoverItem> updateHandoverStatus({
    required int handoverId,
    required String status,
    double? agreedWeightKg,
    double? actualWeightKg,
    String? note,
  }) =>
      throw UnimplementedError();
}

class _ControllableAddressRepository implements AddressRepository {
  Completer<List<UserAddress>>? loadCompleter;
  Completer<UserAddress>? createCompleter;
  Completer<UserAddress>? updateCompleter;
  Completer<void>? deleteCompleter;

  List<UserAddress> addresses = [];
  int getAddressesCallCount = 0;

  @override
  Future<List<UserAddress>> getAddresses() {
    getAddressesCallCount++;
    if (loadCompleter != null) return loadCompleter!.future;
    return Future.value(List<UserAddress>.from(addresses));
  }

  @override
  Future<UserAddress> createAddress({
    String? label,
    required String recipientName,
    required String recipientPhone,
    required int destinationId,
    required String destinationLabel,
    required String addressDetail,
    String? postalCode,
    String? deliveryNote,
    bool? isDefault,
  }) {
    if (createCompleter != null) return createCompleter!.future;
    return Future.value(
      _address(
        id: 500,
        label: label ?? 'Baru',
        recipientName: recipientName,
        isDefault: isDefault ?? false,
      ),
    );
  }

  @override
  Future<UserAddress> updateAddress({
    required int id,
    String? label,
    String? recipientName,
    String? recipientPhone,
    int? destinationId,
    String? destinationLabel,
    String? addressDetail,
    String? postalCode,
    String? deliveryNote,
    bool? isDefault,
  }) {
    if (updateCompleter != null) return updateCompleter!.future;
    return Future.value(
      _address(
        id: id,
        label: label ?? 'Diperbarui',
        recipientName: recipientName ?? 'Penerima',
        isDefault: isDefault ?? false,
      ),
    );
  }

  @override
  Future<void> deleteAddress(int id) {
    if (deleteCompleter != null) return deleteCompleter!.future;
    return Future.value();
  }
}

class _ControllableGalleryRepository implements GalleryRepository {
  Completer<GalleryPage>? feedCompleter;
  Completer<GalleryPage>? myWorksCompleter;
  Completer<GalleryWork>? detailCompleter;
  Completer<GalleryWork>? createCompleter;
  Completer<GalleryWork>? updateCompleter;
  Completer<void>? deleteCompleter;
  Completer<GalleryLikeResult>? toggleLikeCompleter;

  List<GalleryWork> feedWorks = [];
  List<GalleryWork> myWorks = [];

  @override
  Future<GalleryPage> fetchGallery({
    String? query,
    GalleryDifficulty? difficulty,
    String sort = 'latest',
    int page = 1,
    int perPage = 12,
  }) {
    if (feedCompleter != null) return feedCompleter!.future;
    return Future.value(
      GalleryPage(
        items: List<GalleryWork>.from(feedWorks),
        currentPage: page,
        lastPage: 1,
        perPage: perPage,
        total: feedWorks.length,
      ),
    );
  }

  @override
  Future<GalleryWork> fetchWorkDetail(int id) {
    if (detailCompleter != null) return detailCompleter!.future;
    final found = [...myWorks, ...feedWorks].firstWhere(
      (w) => w.id == id,
      orElse: () => _galleryWork(id: id, title: 'Detail #$id'),
    );
    return Future.value(found);
  }

  @override
  Future<GalleryPage> fetchMyWorks({int page = 1, int perPage = 12}) {
    if (myWorksCompleter != null) return myWorksCompleter!.future;
    return Future.value(
      GalleryPage(
        items: List<GalleryWork>.from(myWorks),
        currentPage: page,
        lastPage: 1,
        perPage: perPage,
        total: myWorks.length,
      ),
    );
  }

  @override
  Future<GalleryWork> createWork({
    required String title,
    required GalleryDifficulty difficulty,
    required List<String> materials,
    List<String> tools = const [],
    required List<String> steps,
    List<String> videoLinks = const [],
    required List<String> imagePaths,
    required bool ownershipConfirmed,
  }) {
    if (createCompleter != null) return createCompleter!.future;
    return Future.value(_galleryWork(id: 700, title: title));
  }

  @override
  Future<GalleryWork> updateWork({
    required int id,
    required String title,
    required GalleryDifficulty difficulty,
    required List<String> materials,
    List<String> tools = const [],
    required List<String> steps,
    List<String> videoLinks = const [],
    List<String> newImagePaths = const [],
    List<int> removeImageIds = const [],
  }) {
    if (updateCompleter != null) return updateCompleter!.future;
    return Future.value(_galleryWork(id: id, title: title));
  }

  @override
  Future<void> deleteWork(int id) {
    if (deleteCompleter != null) return deleteCompleter!.future;
    return Future.value();
  }

  @override
  Future<GalleryLikeResult> toggleLike(int id) {
    if (toggleLikeCompleter != null) return toggleLikeCompleter!.future;
    return Future.value(const GalleryLikeResult(liked: true, likesCount: 4));
  }
}

class _ControllableOrderRepository implements OrderRepository {
  Completer<OrderListPage>? buyerOrdersCompleter;
  Completer<OrderItem>? createOrderCompleter;

  List<OrderItem> buyerOrders = [];
  List<OrderItem> sellerOrders = [];

  @override
  Future<OrderListPage> getOrders({
    required String role,
    String? status,
    int page = 1,
    int perPage = 15,
  }) {
    if (role == 'buyer' && buyerOrdersCompleter != null) {
      return buyerOrdersCompleter!.future;
    }
    final items = role == 'seller' ? sellerOrders : buyerOrders;
    return Future.value(
      OrderListPage(
        items: List<OrderItem>.from(items),
        currentPage: page,
        lastPage: 1,
        perPage: perPage,
        total: items.length,
      ),
    );
  }

  @override
  Future<OrderItem> getOrderDetail(int orderId) async =>
      [...buyerOrders, ...sellerOrders].firstWhere((o) => o.id == orderId);

  @override
  Future<OrderItem> createOrder({
    required int listingId,
    required int addressId,
    required String courierCode,
    required String courierService,
    String? buyerNote,
    required String idempotencyKey,
  }) {
    if (createOrderCompleter != null) return createOrderCompleter!.future;
    return Future.value(_order(id: 99, orderNumber: 'ORD-NEW'));
  }

  @override
  Future<OrderItem> cancelOrder(int orderId, {String? reason}) =>
      throw UnimplementedError();

  @override
  Future<OrderItem> retryPayment(int orderId) => throw UnimplementedError();

  @override
  Future<OrderRefreshResult> refreshPaymentStatus(int orderId) =>
      throw UnimplementedError();

  @override
  Future<OrderItem> shipOrder({
    required int orderId,
    required String trackingNumber,
    String? shipmentNotes,
  }) =>
      throw UnimplementedError();

  @override
  Future<OrderItem> confirmDelivery(int orderId) => throw UnimplementedError();
}

class _ControllableMaterialRepository implements MaterialRepository {
  Completer<List<MaterialListing>>? materialsCompleter;
  Completer<MaterialListing>? createCompleter;
  Completer<void>? toggleFavoriteCompleter;

  List<MaterialListing> listings = [];
  final Set<int> favoriteIds = {};
  int clearCallCount = 0;

  @override
  void clearUserData() {
    clearCallCount++;
    favoriteIds.clear();
  }

  @override
  Future<List<MaterialListing>> getMaterials({
    String? category,
    String? query,
    String? condition,
    double? minWeight,
    double? maxWeight,
    String? location,
  }) {
    if (materialsCompleter != null) return materialsCompleter!.future;
    return Future.value(
      listings
          .map((item) => item.copyWith(isFavorited: favoriteIds.contains(item.id)))
          .toList(),
    );
  }

  @override
  Future<MaterialListing> getMaterialDetail(int id) async {
    final item = listings.firstWhere((e) => e.id == id);
    return item.copyWith(isFavorited: favoriteIds.contains(id));
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
  }) {
    if (createCompleter != null) return createCompleter!.future;
    return Future.value(_listing(id: 888, name: name));
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
  }) async =>
      _listing(id: id, name: name ?? 'Updated');

  @override
  Future<void> toggleFavorite(int id) {
    if (toggleFavoriteCompleter != null) return toggleFavoriteCompleter!.future;
    if (favoriteIds.contains(id)) {
      favoriteIds.remove(id);
    } else {
      favoriteIds.add(id);
    }
    return Future.value();
  }

  @override
  Future<ImpactSummary> getImpactSummary() async => ImpactSummary(
        listedCount: 1,
        listedWeightKg: 5.0,
        availableCount: 1,
        availableWeightKg: 5.0,
        handedOverCount: 0,
        handedOverWeightKg: 0.0,
        confirmedCount: 0,
        confirmedWeightKg: 0.0,
      );
}

// ─── Tests ────────────────────────────────────────────────────────────────────

void main() {
  group('SEC-FE-03 — Test A: Individual State Holder Reset', () {
    test('ActivityViewModel.clearUserData clears activities, analyses, tabs, and errors', () async {
      final repo = _ControllableActivityRepository()
        ..activities = const [
          ActivityItem(
            type: 'order',
            action: 'Pesanan Dibuat',
            description: 'Aktivitas privat User A',
            status: 'paid',
            referenceId: 10,
            rawTimestamp: '2026-11-20T10:00:00Z',
          ),
        ]
        ..analyses = [
          {'id': 1, 'estimated_category': 'PET', 'notes': 'Catatan User A'},
        ];
      final vm = ActivityViewModel(activityRepository: repo);
      await vm.loadActivities();
      await vm.loadAnalysisHistories();
      vm.setTabIndex(1);

      expect(vm.activities, hasLength(1));
      expect(vm.analyses, hasLength(1));
      expect(vm.selectedTabIndex, 1);

      int notifyCount = 0;
      vm.addListener(() => notifyCount++);
      vm.clearUserData();

      expect(vm.activities, isEmpty);
      expect(vm.analyses, isEmpty);
      expect(vm.selectedTabIndex, 0);
      expect(vm.isLoading, isFalse);
      expect(vm.isLoadingAnalyses, isFalse);
      expect(vm.errorMessage, isNull);
      expect(vm.analysesError, isNull);
      expect(notifyCount, 1);
    });

    test('AnalysisViewModel.clearUserData clears draft form, image path, and analysis result', () async {
      final repo = _ControllableAnalysisRepository();
      final vm = AnalysisViewModel(analysisRepository: repo);
      vm.setPolymer('PET');
      vm.setWeight(12.5);
      vm.setCondition('dirty');
      vm.setNotes('Catatan rahasia User A');
      await vm.submitAnalysis();

      expect(vm.analysisResult, isNotNull);
      expect(vm.isSuccess, isTrue);
      expect(vm.polymerCategory, 'PET');

      int notifyCount = 0;
      vm.addListener(() => notifyCount++);
      vm.clearUserData();

      expect(vm.imagePath, isNull);
      expect(vm.hasImage, isFalse);
      expect(vm.polymerCategory, isNull);
      expect(vm.weightKg, 0.0);
      expect(vm.condition, 'clean');
      expect(vm.notes, isEmpty);
      expect(vm.isLoading, isFalse);
      expect(vm.isSuccess, isFalse);
      expect(vm.errorMessage, isNull);
      expect(vm.analysisResult, isNull);
      expect(notifyCount, 1);
    });

    test('MatchingViewModel.clearUserData clears request and listing matching responses', () async {
      final repo = _ControllableTransactionRepository();
      final vm = MatchingViewModel(transactionRepository: repo);
      await vm.findMatchesForRequest(10);
      await vm.findMatchesForListing(20);

      expect(vm.requestMatchingResponse, isNotNull);
      expect(vm.listingMatchingResponse, isNotNull);

      int notifyCount = 0;
      vm.addListener(() => notifyCount++);
      vm.clearUserData();

      expect(vm.requestMatchingResponse, isNull);
      expect(vm.listingMatchingResponse, isNull);
      expect(vm.isLoading, isFalse);
      expect(vm.errorMessage, isNull);
      expect(notifyCount, 1);
    });

    test('ApiMaterialRepository.clearUserData clears in-memory favorite IDs', () async {
      final storage = InMemoryAuthTokenStorage();
      final client = ApiClient(
        tokenStorage: storage,
        client: MockClient((request) async {
          if (request.url.path.endsWith('/api/materials/101')) {
            return http.Response(
              jsonEncode({
                'success': true,
                'data': {
                  'id': 101,
                  'name': 'Botol PET Bening',
                  'category': 'PET',
                  'weight_kg': 10,
                  'condition': 'clean',
                  'price': 10000,
                  'is_free': false,
                  'general_location': 'Bandung',
                  'description': 'Desc',
                  'created_at': '2026-11-20T10:00:00Z',
                },
              }),
              200,
            );
          }
          return http.Response(
            jsonEncode({
              'success': true,
              'data': [
                {
                  'id': 101,
                  'name': 'Botol PET Bening',
                  'category': 'PET',
                  'weight_kg': 10,
                  'condition': 'clean',
                  'price': 10000,
                  'is_free': false,
                  'general_location': 'Bandung',
                  'description': 'Desc',
                  'created_at': '2026-11-20T10:00:00Z',
                },
              ],
            }),
            200,
          );
        }),
      );

      final repo = ApiMaterialRepository(apiClient: client);
      await repo.toggleFavorite(101);
      final beforeClear = await repo.getMaterials();
      expect(beforeClear.single.isFavorited, isTrue);

      repo.clearUserData();

      final afterClear = await repo.getMaterials();
      final detailAfterClear = await repo.getMaterialDetail(101);
      expect(afterClear.single.isFavorited, isFalse);
      expect(detailAfterClear.isFavorited, isFalse);
    });

    test('MaterialRequestViewModel.clearUserData clears currentUserId, requests, and filters', () async {
      final repo = _ControllableTransactionRepository()
        ..requests = [
          _materialRequest(
            id: 1,
            requesterId: 42,
            intendedUse: 'Kebutuhan User A',
          ),
        ];
      final vm = MaterialRequestViewModel(
        transactionRepository: repo,
        currentUserId: 42,
      );
      await Future<void>.delayed(Duration.zero);
      vm.applyFilters(category: 'PET', condition: 'clean', location: 'Bandung');
      await Future<void>.delayed(Duration.zero);

      expect(vm.currentUserId, 42);
      expect(vm.requests, hasLength(1));
      expect(vm.hasActiveFilters, isTrue);

      vm.clearUserData();

      expect(vm.currentUserId, isNull);
      expect(vm.requests, isEmpty);
      expect(vm.selectedCategory, 'Semua');
      expect(vm.selectedCondition, 'Semua');
      expect(vm.locationFilter, isNull);
      expect(vm.hasActiveFilters, isFalse);
      expect(vm.isLoading, isFalse);
      expect(vm.isSubmitting, isFalse);
      expect(vm.errorMessage, isNull);
    });

    test('MarketplaceViewModel.clearUserData cancels debounce, clears favorites, and resets filters', () async {
      final repo = _ControllableMaterialRepository()
        ..listings = [_listing(id: 101, name: 'PET User A')];
      final vm = MarketplaceViewModel(materialRepository: repo);
      await Future<void>.delayed(Duration.zero);

      await vm.toggleFavorite(101);
      expect(vm.listings.single.isFavorited, isTrue);
      expect(repo.favoriteIds.contains(101), isTrue);

      // Start debounced search + advanced filters
      vm.applyAdvancedFilters(
        category: 'PET',
        condition: 'clean',
        minWeight: 5.0,
        maxWeight: 50.0,
        location: 'Bandung',
      );
      await Future<void>.delayed(Duration.zero);
      vm.updateSearchQuery('rahasia user A');

      vm.clearUserData();

      expect(repo.clearCallCount, 1);
      expect(repo.favoriteIds, isEmpty);
      expect(vm.selectedCategory, 'Semua');
      expect(vm.selectedCondition, 'Semua');
      expect(vm.minWeight, isNull);
      expect(vm.maxWeight, isNull);
      expect(vm.locationFilter, isNull);
      expect(vm.searchQuery, isEmpty);
      expect(vm.listings, isEmpty);

      // Verify cancelled debounce timer does not fire loadListings() later
      await Future<void>.delayed(const Duration(milliseconds: 500));
      expect(vm.listings, isEmpty);
      expect(vm.searchQuery, isEmpty);
    });

    test('HomeViewModel.clearUserData strips favorites and resets loading/errors', () async {
      final repo = _ControllableMaterialRepository()
        ..listings = [_listing(id: 101, name: 'PET Home')];
      final vm = HomeViewModel(materialRepository: repo);
      await Future<void>.delayed(Duration.zero);
      await vm.toggleFavorite(101);
      expect(vm.recentListings.single.isFavorited, isTrue);

      vm.clearUserData();

      expect(vm.recentListings.single.isFavorited, isFalse);
      expect(vm.isLoading, isFalse);
      expect(vm.isImpactLoading, isFalse);
      expect(vm.errorMessage, isNull);
      expect(vm.impactErrorMessage, isNull);
    });
  });

  group('SEC-FE-03 — Test B: Cross-Account Isolation (User A -> Logout -> User B)', () {
    test('User A logs out and User B logs in with zero leaked state across all ViewModels and repositories', () async {
      final tokenStorage = InMemoryAuthTokenStorage();
      await tokenStorage.saveToken('token-user-a');

      final apiClient = ApiClient(
        tokenStorage: tokenStorage,
        client: MockClient((request) async {
          if (request.url.path.endsWith('/api/me')) {
            final auth = request.headers['Authorization'];
            if (auth == 'Bearer token-user-a') {
              return http.Response(
                jsonEncode({
                  'success': true,
                  'data': {
                    'id': 1,
                    'name': 'User A',
                    'email': 'a@plasvora.test',
                  },
                }),
                200,
              );
            }
            return http.Response(jsonEncode({'message': 'Unauthenticated'}), 401);
          }
          if (request.url.path.endsWith('/api/logout')) {
            return http.Response(jsonEncode({'success': true}), 200);
          }
          if (request.url.path.endsWith('/api/login')) {
            return http.Response(
              jsonEncode({
                'success': true,
                'data': {
                  'token': 'token-user-b',
                  'user': {
                    'id': 2,
                    'name': 'User B',
                    'email': 'b@plasvora.test',
                  },
                },
              }),
              200,
            );
          }
          if (request.url.path.endsWith('/api/materials/impact-summary')) {
            return http.Response(
              jsonEncode({
                'success': true,
                'data': {
                  'listed_count': 1,
                  'listed_weight_kg': 10,
                  'available_count': 1,
                  'available_weight_kg': 10,
                  'handed_over_count': 0,
                  'handed_over_weight_kg': 0,
                  'confirmed_count': 0,
                  'confirmed_weight_kg': 0,
                },
              }),
              200,
            );
          }
          if (request.url.path.endsWith('/api/materials')) {
            return http.Response(
              jsonEncode({
                'success': true,
                'data': [
                  {
                    'id': 101,
                    'name': 'Botol PET Publik',
                    'category': 'PET',
                    'weight_kg': 10,
                    'condition': 'clean',
                    'price': 10000,
                    'is_free': false,
                    'general_location': 'Bandung',
                    'description': 'Listing publik',
                    'created_at': '2026-11-20T10:00:00Z',
                  },
                ],
              }),
              200,
            );
          }
          return http.Response(jsonEncode({'success': true}), 200);
        }),
      );

      final authRepo = ApiAuthRepository(apiClient: apiClient);
      final materialRepo = ApiMaterialRepository(apiClient: apiClient);
      final activityRepo = _ControllableActivityRepository();
      final analysisRepo = _ControllableAnalysisRepository();
      final transactionRepo = _ControllableTransactionRepository();
      final addressRepo = _ControllableAddressRepository();
      final orderRepo = _ControllableOrderRepository();
      final galleryRepo = _ControllableGalleryRepository();

      final homeVm = HomeViewModel(materialRepository: materialRepo);
      final analysisVm = AnalysisViewModel(analysisRepository: analysisRepo);
      final marketplaceVm = MarketplaceViewModel(materialRepository: materialRepo);
      final activityVm = ActivityViewModel(activityRepository: activityRepo);
      final materialRequestVm = MaterialRequestViewModel(
        transactionRepository: transactionRepo,
      );
      final matchingVm = MatchingViewModel(transactionRepository: transactionRepo);
      final addressVm = AddressViewModel(addressRepository: addressRepo);
      final orderVm = OrderViewModel(orderRepository: orderRepo);
      final galleryVm = GalleryViewModel(galleryRepository: galleryRepo);

      // Wired identically to lib/main.dart
      final authVm = AuthViewModel(
        authRepository: authRepo,
        onSessionCleared: () {
          materialRepo.clearUserData();
          homeVm.clearUserData();
          analysisVm.clearUserData();
          marketplaceVm.clearUserData();
          activityVm.clearUserData();
          materialRequestVm.clearUserData();
          matchingVm.clearUserData();
          addressVm.clearUserData();
          orderVm.clearUserData();
          galleryVm.clearUserData();
        },
      );

      await Future<void>.delayed(Duration.zero);
      expect(authVm.isAuthenticated, isTrue);
      expect(authVm.currentUser?.id, 1);

      // Populate ALL state holders with User A data
      activityRepo.activities = const [
        ActivityItem(
          type: 'order',
          action: 'Order User A',
          description: 'Rahasia A',
          status: 'paid',
          referenceId: 1,
          rawTimestamp: '2026-11-20T10:00:00Z',
        ),
      ];
      activityRepo.analyses = [
        {'id': 1, 'notes': 'Scan rahasia A'},
      ];
      await activityVm.loadActivities();
      await activityVm.loadAnalysisHistories();
      activityVm.setTabIndex(1);

      analysisVm.setPolymer('HDPE');
      analysisVm.setWeight(7.5);
      analysisVm.setNotes('Draft analisis User A');
      await analysisVm.submitAnalysis();

      transactionRepo.requests = [
        _materialRequest(id: 11, requesterId: 1, intendedUse: 'Request User A'),
      ];
      materialRequestVm.currentUserId = 1;
      await materialRequestVm.loadRequests();
      await matchingVm.findMatchesForRequest(11);
      await matchingVm.findMatchesForListing(101);

      await marketplaceVm.loadListings();
      await marketplaceVm.toggleFavorite(101);
      marketplaceVm.applyAdvancedFilters(category: 'PET', location: 'Bandung');
      await Future<void>.delayed(Duration.zero);
      await homeVm.loadHomeData();

      addressRepo.addresses = [
        _address(id: 1, label: 'Rumah User A', recipientName: 'User A', isDefault: true),
      ];
      await addressVm.loadAddresses();

      orderRepo.buyerOrders = [_order(id: 501, orderNumber: 'ORD-A-BUY', buyerId: 1)];
      orderRepo.sellerOrders = [_order(id: 502, orderNumber: 'ORD-A-SELL', sellerId: 1)];
      await orderVm.loadBuyerOrders();
      await orderVm.loadSellerOrders();
      await orderVm.loadOrderDetail(501);

      galleryRepo.feedWorks = [
        _galleryWork(id: 801, title: 'Karya Publik', authorId: 1, likedByMe: true),
      ];
      galleryRepo.myWorks = [
        _galleryWork(id: 801, title: 'Karya Privat User A', authorId: 1, likedByMe: true),
      ];
      await galleryVm.loadFeed();
      await galleryVm.loadMyWorks();
      await galleryVm.loadWorkDetail(801);
      await galleryVm.setSearchQuery('rahasia');

      // ─── User A logs out ───
      await authVm.logout();

      expect(await tokenStorage.getToken(), isNull);
      expect(authVm.state, AuthState.unauthenticated);
      expect(authVm.currentUser, isNull);

      // Verify EVERY state holder is cleanly reset immediately after logout
      expect(activityVm.activities, isEmpty);
      expect(activityVm.analyses, isEmpty);
      expect(activityVm.selectedTabIndex, 0);

      expect(analysisVm.polymerCategory, isNull);
      expect(analysisVm.notes, isEmpty);
      expect(analysisVm.analysisResult, isNull);
      expect(analysisVm.isSuccess, isFalse);

      expect(matchingVm.requestMatchingResponse, isNull);
      expect(matchingVm.listingMatchingResponse, isNull);

      expect(materialRequestVm.currentUserId, isNull);
      expect(materialRequestVm.requests, isEmpty);

      expect(marketplaceVm.selectedCategory, 'Semua');
      expect(marketplaceVm.locationFilter, isNull);
      expect(marketplaceVm.listings, isEmpty);
      expect(homeVm.recentListings.every((m) => !m.isFavorited), isTrue);

      expect(addressVm.addresses, isEmpty);
      expect(addressVm.selectedAddress, isNull);

      expect(orderVm.buyerOrders, isEmpty);
      expect(orderVm.sellerOrders, isEmpty);
      expect(orderVm.currentOrder, isNull);

      expect(galleryVm.myWorks, isEmpty);
      expect(galleryVm.getCachedDetail(801), isNull);
      expect(galleryVm.searchQuery, isEmpty);
      expect(galleryVm.works, isEmpty);

      // ─── User B logs in on the SAME instances ───
      final loggedInB = await authVm.login('b@plasvora.test', 'password123');
      expect(loggedInB, isTrue);
      expect(authVm.currentUser?.id, 2);

      // Switch backend stubs to User B data
      activityRepo.activities = const [
        ActivityItem(
          type: 'order',
          action: 'Order User B',
          description: 'Aktivitas B',
          status: 'pending_payment',
          referenceId: 2,
          rawTimestamp: '2026-11-21T10:00:00Z',
        ),
      ];
      activityRepo.analyses = [
        {'id': 2, 'notes': 'Scan User B'},
      ];
      addressRepo.addresses = [
        _address(id: 2, label: 'Gudang User B', recipientName: 'User B', isDefault: true),
      ];
      orderRepo.buyerOrders = [_order(id: 601, orderNumber: 'ORD-B-BUY', buyerId: 2)];
      orderRepo.sellerOrders = [];
      galleryRepo.feedWorks = [
        _galleryWork(id: 801, title: 'Karya Publik', authorId: 1, likedByMe: false),
      ];
      galleryRepo.myWorks = [
        _galleryWork(id: 802, title: 'Karya User B', authorId: 2, likedByMe: false),
      ];

      await marketplaceVm.loadListings();
      await activityVm.loadActivities();
      await activityVm.loadAnalysisHistories();
      await addressVm.loadAddresses();
      await orderVm.loadBuyerOrders();
      await galleryVm.loadFeed();
      await galleryVm.loadMyWorks();

      // User B sees ONLY User B's data and NEVER User A's favorites/likes/PII
      expect(marketplaceVm.listings.single.isFavorited, isFalse);
      expect(activityVm.activities.single.action, 'Order User B');
      expect(activityVm.analyses.single.id, '2');
      expect(addressVm.addresses.single.label, 'Gudang User B');
      expect(orderVm.buyerOrders.single.orderNumber, 'ORD-B-BUY');
      expect(orderVm.sellerOrders, isEmpty);
      expect(galleryVm.works.single.likedByMe, isFalse);
      expect(galleryVm.myWorks.single.title, 'Karya User B');
    });
  });

  group('SEC-FE-03 — Test C: Async Race Conditions & Disposal Safety', () {
    test('AddressViewModel in-flight createAddress (success & error) cannot repopulate after logout', () async {
      final repo = _ControllableAddressRepository();
      final vm = AddressViewModel(addressRepository: repo);

      // Case 1: in-flight createAddress succeeds AFTER User A logs out and User B loads addresses
      final createCompleter = Completer<UserAddress>();
      repo.createCompleter = createCompleter;
      final createFuture = vm.createAddress(
        label: 'Alamat User A',
        recipientName: 'User A',
        recipientPhone: '6281111111111',
        destinationId: 4949,
        destinationLabel: 'BANDUNG',
        addressDetail: 'Jl. Rahasia User A',
        isDefault: true,
      );
      expect(vm.isSaving, isTrue);

      // User A logs out
      vm.clearUserData();
      expect(vm.isSaving, isFalse);
      expect(vm.addresses, isEmpty);

      // User B loads User B's addresses
      repo.createCompleter = null;
      repo.addresses = [
        _address(id: 202, label: 'Alamat User B', recipientName: 'User B', isDefault: true),
      ];
      await vm.loadAddresses();
      final callsBeforeStaleComplete = repo.getAddressesCallCount;

      // Now User A's createAddress resolves late
      createCompleter.complete(
        _address(id: 101, label: 'Alamat User A', recipientName: 'User A', isDefault: true),
      );
      final staleResult = await createFuture;

      expect(staleResult, isNull);
      expect(repo.getAddressesCallCount, callsBeforeStaleComplete);
      expect(vm.addresses.single.id, 202);
      expect(vm.selectedAddress?.id, 202);
      expect(vm.errorMessage, isNull);

      // Case 2: in-flight updateAddress fails AFTER logout — must NOT pollute User B errorMessage/fieldErrors
      final updateCompleter = Completer<UserAddress>();
      repo.updateCompleter = updateCompleter;
      final updateFuture = vm.updateAddress(id: 101, label: 'Stale Update');
      vm.clearUserData();
      updateCompleter.completeError(
        ApiException('Stale validation error', statusCode: 422, errors: {
          'label': ['Label tidak valid'],
        }),
      );
      final staleUpdate = await updateFuture;

      expect(staleUpdate, isNull);
      expect(vm.errorMessage, isNull);
      expect(vm.fieldErrors, isEmpty);
      expect(vm.addresses, isEmpty);

      // Case 3: in-flight deleteAddress succeeds AFTER logout — must NOT trigger getAddresses()
      final deleteCompleter = Completer<void>();
      repo.deleteCompleter = deleteCompleter;
      final deleteFuture = vm.deleteAddress(101);
      vm.clearUserData();
      final callsBeforeDeleteComplete = repo.getAddressesCallCount;
      deleteCompleter.complete();
      final staleDelete = await deleteFuture;

      expect(staleDelete, isFalse);
      expect(repo.getAddressesCallCount, callsBeforeDeleteComplete);
      expect(vm.addresses, isEmpty);
    });

    test('GalleryViewModel in-flight createWork, toggleLike (success & error), and loadMyWorks cannot leak after logout', () async {
      final repo = _ControllableGalleryRepository()
        ..feedWorks = [
          _galleryWork(id: 10, title: 'Karya Publik', likedByMe: false, likesCount: 5),
        ];
      final vm = GalleryViewModel(galleryRepository: repo);
      await vm.loadFeed();

      // 1. In-flight toggleLike (User A likes work #10, then logs out before API responds)
      final likeCompleter = Completer<GalleryLikeResult>();
      repo.toggleLikeCompleter = likeCompleter;
      final likeFuture = vm.toggleLike(10);
      expect(vm.works.single.likedByMe, isTrue);

      vm.clearUserData();
      expect(vm.works.single.likedByMe, isFalse);

      // API responds for User A's like -> MUST be ignored!
      likeCompleter.complete(const GalleryLikeResult(liked: true, likesCount: 6));
      await likeFuture;
      expect(vm.works.single.likedByMe, isFalse);
      expect(vm.isLiking(10), isFalse);

      // 2. In-flight toggleLike error rollback after logout must NOT restore User A's likedByMe=true
      repo.feedWorks = [
        _galleryWork(id: 10, title: 'Karya Publik', likedByMe: true, likesCount: 6),
      ];
      await vm.loadFeed(refresh: true);
      final rollbackCompleter = Completer<GalleryLikeResult>();
      repo.toggleLikeCompleter = rollbackCompleter;
      final unlikeFuture = vm.toggleLike(10); // previousLiked was true!
      vm.clearUserData();
      expect(vm.works.single.likedByMe, isFalse);

      rollbackCompleter.completeError(ApiException('Server error', statusCode: 500));
      await unlikeFuture;
      expect(vm.works.single.likedByMe, isFalse);

      // 3. In-flight createWork completes after logout -> must NOT populate myWorks or detailCache
      final createCompleter = Completer<GalleryWork>();
      repo.createCompleter = createCompleter;
      final createFuture = vm.createWork(
        title: 'Karya User A',
        difficulty: GalleryDifficulty.mudah,
        materials: const ['PET'],
        steps: const ['Langkah 1'],
        imagePaths: const ['/tmp/a.jpg'],
        ownershipConfirmed: true,
      );
      vm.clearUserData();

      createCompleter.complete(_galleryWork(id: 999, title: 'Karya User A', authorId: 1));
      final created = await createFuture;

      expect(created, isNull);
      expect(vm.myWorks, isEmpty);
      expect(vm.getCachedDetail(999), isNull);
      expect(vm.isSubmitting, isFalse);

      // 4. In-flight loadFeed completes after logout -> must NOT populate feed with User A's likedByMe
      final feedCompleter = Completer<GalleryPage>();
      repo.feedCompleter = feedCompleter;
      final feedFuture = vm.loadFeed(refresh: true);
      vm.clearUserData();

      feedCompleter.complete(
        GalleryPage(
          items: [_galleryWork(id: 777, title: 'Stale Feed A', likedByMe: true)],
          currentPage: 1,
          lastPage: 1,
          perPage: 12,
          total: 1,
        ),
      );
      await feedFuture;
      expect(vm.works.where((w) => w.id == 777), isEmpty);
    });

    test('Activity, Analysis, Matching, MaterialRequest, Marketplace, Home, and Order ignore stale in-flight completions after clearUserData', () async {
      // ActivityViewModel
      final activityRepo = _ControllableActivityRepository();
      final activitiesCompleter = Completer<List<ActivityItem>>();
      final analysesCompleter = Completer<List<Map<String, dynamic>>>();
      activityRepo.activitiesCompleter = activitiesCompleter;
      activityRepo.analysesCompleter = analysesCompleter;
      final activityVm = ActivityViewModel(activityRepository: activityRepo);
      final fAct = activityVm.loadActivities();
      final fAna = activityVm.loadAnalysisHistories();
      activityVm.clearUserData();
      activitiesCompleter.complete(const [
        ActivityItem(
          type: 'order',
          action: 'Stale A',
          description: 'Stale',
          status: 'paid',
          rawTimestamp: '2026-11-20T10:00:00Z',
        ),
      ]);
      analysesCompleter.complete([
        {'id': 1, 'notes': 'Stale A'},
      ]);
      await Future.wait([fAct, fAna]);
      expect(activityVm.activities, isEmpty);
      expect(activityVm.analyses, isEmpty);

      // AnalysisViewModel
      final analysisRepo = _ControllableAnalysisRepository();
      final submitCompleter = Completer<PlasticAnalysisResult>();
      analysisRepo.submitCompleter = submitCompleter;
      final analysisVm = AnalysisViewModel(analysisRepository: analysisRepo);
      final fSub = analysisVm.submitAnalysis();
      analysisVm.clearUserData();
      submitCompleter.complete(_analysisResult('99', 'Stale Analysis A'));
      final subResult = await fSub;
      expect(subResult, isNull);
      expect(analysisVm.analysisResult, isNull);
      expect(analysisVm.isSuccess, isFalse);

      // MatchingViewModel
      final txRepo = _ControllableTransactionRepository();
      final matchCompleter = Completer<MaterialRequestMatchingResponse>();
      txRepo.requestMatchCompleter = matchCompleter;
      final matchingVm = MatchingViewModel(transactionRepository: txRepo);
      final fMatch = matchingVm.findMatchesForRequest(1);
      matchingVm.clearUserData();
      matchCompleter.complete(
        MaterialRequestMatchingResponse(
          request: _materialRequest(id: 1, requesterId: 1, intendedUse: 'Stale'),
          matches: const [],
          total: 0,
          note: 'Stale',
        ),
      );
      await fMatch;
      expect(matchingVm.requestMatchingResponse, isNull);

      // MaterialRequestViewModel
      final reqCompleter = Completer<MaterialRequestItem>();
      txRepo.createRequestCompleter = reqCompleter;
      final reqVm = MaterialRequestViewModel(transactionRepository: txRepo);
      await Future<void>.delayed(Duration.zero);
      final fReq = reqVm.createRequest(
        category: 'PET',
        weightKg: 10,
        condition: 'clean',
        location: 'Bandung',
        intendedUse: 'Daur ulang botol',
      );
      reqVm.clearUserData();
      reqCompleter.complete(
        _materialRequest(id: 55, requesterId: 1, intendedUse: 'Stale Request A'),
      );
      final createdReq = await fReq;
      expect(createdReq, isFalse);
      expect(reqVm.requests, isEmpty);

      // MarketplaceViewModel & HomeViewModel
      final matRepo = _ControllableMaterialRepository();
      final matCompleter = Completer<List<MaterialListing>>();
      matRepo.materialsCompleter = matCompleter;
      final marketVm = MarketplaceViewModel(materialRepository: matRepo);
      final homeVm = HomeViewModel(materialRepository: matRepo);
      marketVm.clearUserData();
      homeVm.clearUserData();
      matCompleter.complete([_listing(id: 1, name: 'Stale Listing A', isFavorited: true)]);
      await Future<void>.delayed(Duration.zero);
      expect(marketVm.listings, isEmpty);
      expect(homeVm.recentListings, isEmpty);

      // OrderViewModel
      final orderRepo = _ControllableOrderRepository();
      final orderCompleter = Completer<OrderListPage>();
      orderRepo.buyerOrdersCompleter = orderCompleter;
      final orderVm = OrderViewModel(orderRepository: orderRepo);
      final fOrd = orderVm.loadBuyerOrders();
      orderVm.clearUserData();
      orderCompleter.complete(
        OrderListPage(
          items: [_order(id: 99, orderNumber: 'STALE-ORD-A')],
          currentPage: 1,
          lastPage: 1,
          perPage: 15,
          total: 1,
        ),
      );
      await fOrd;
      expect(orderVm.buyerOrders, isEmpty);
    });

    test('In-flight async completions after dispose() do not throw FlutterError', () async {
      final activityRepo = _ControllableActivityRepository()
        ..activitiesCompleter = Completer<List<ActivityItem>>();
      final activityVm = ActivityViewModel(activityRepository: activityRepo);
      final fAct = activityVm.loadActivities();
      activityVm.dispose();
      activityRepo.activitiesCompleter!.complete(const []);
      await fAct;

      final addressRepo = _ControllableAddressRepository()
        ..createCompleter = Completer<UserAddress>();
      final addressVm = AddressViewModel(addressRepository: addressRepo);
      final fAddr = addressVm.createAddress(
        recipientName: 'A',
        recipientPhone: '628111111111',
        destinationId: 1,
        destinationLabel: 'BANDUNG',
        addressDetail: 'Jl. Test',
      );
      addressVm.dispose();
      addressRepo.createCompleter!.complete(
        _address(id: 1, label: 'A', recipientName: 'A'),
      );
      await fAddr;

      final galleryRepo = _ControllableGalleryRepository()
        ..createCompleter = Completer<GalleryWork>();
      final galleryVm = GalleryViewModel(galleryRepository: galleryRepo);
      final fGal = galleryVm.createWork(
        title: 'T',
        difficulty: GalleryDifficulty.mudah,
        materials: const ['PET'],
        steps: const ['S'],
        imagePaths: const ['/a.jpg'],
        ownershipConfirmed: true,
      );
      galleryVm.dispose();
      galleryRepo.createCompleter!.complete(_galleryWork(id: 1, title: 'T'));
      await fGal;
    });
  });

  group('SEC-FE-03 — Test D: Backend Logout Failure Still Clears All Local State', () {
    test('SocketException on POST /api/logout still clears token, favorites, and all ViewModels', () async {
      final tokenStorage = InMemoryAuthTokenStorage();
      await tokenStorage.saveToken('token-offline');

      final apiClient = ApiClient(
        tokenStorage: tokenStorage,
        client: MockClient((request) async {
          if (request.url.path.endsWith('/api/me')) {
            return http.Response(
              jsonEncode({
                'success': true,
                'data': {'id': 7, 'name': 'Offline User', 'email': 'off@plasvora.test'},
              }),
              200,
            );
          }
          if (request.url.path.endsWith('/api/logout')) {
            throw const SocketException('Network down');
          }
          return http.Response(jsonEncode({'success': true, 'data': []}), 200);
        }),
      );

      final authRepo = ApiAuthRepository(apiClient: apiClient);
      final materialRepo = ApiMaterialRepository(apiClient: apiClient);
      final activityRepo = _ControllableActivityRepository()
        ..activities = const [
          ActivityItem(
            type: 'order',
            action: 'Aktivitas Offline',
            description: 'Desc',
            status: 'paid',
            rawTimestamp: '2026-11-20T10:00:00Z',
          ),
        ];
      final activityVm = ActivityViewModel(activityRepository: activityRepo);
      final analysisVm = AnalysisViewModel(
        analysisRepository: _ControllableAnalysisRepository(),
      );
      final matchingVm = MatchingViewModel(
        transactionRepository: _ControllableTransactionRepository(),
      );
      final addressVm = AddressViewModel(
        addressRepository: _ControllableAddressRepository()
          ..addresses = [_address(id: 1, label: 'Rumah', recipientName: 'Off')],
      );

      final authVm = AuthViewModel(
        authRepository: authRepo,
        onSessionCleared: () {
          materialRepo.clearUserData();
          activityVm.clearUserData();
          analysisVm.clearUserData();
          matchingVm.clearUserData();
          addressVm.clearUserData();
        },
      );

      await Future<void>.delayed(Duration.zero);
      await materialRepo.toggleFavorite(101);
      await activityVm.loadActivities();
      analysisVm.setNotes('Sensitive draft');
      await matchingVm.findMatchesForRequest(1);
      await addressVm.loadAddresses();

      await authVm.logout();

      expect(await tokenStorage.getToken(), isNull);
      expect(authVm.state, AuthState.unauthenticated);
      expect(authVm.currentUser, isNull);
      expect(activityVm.activities, isEmpty);
      expect(analysisVm.notes, isEmpty);
      expect(matchingVm.requestMatchingResponse, isNull);
      expect(addressVm.addresses, isEmpty);
    });

    test('HTTP 500 on POST /api/logout still clears token and all user state', () async {
      final tokenStorage = InMemoryAuthTokenStorage();
      await tokenStorage.saveToken('token-500');

      final apiClient = ApiClient(
        tokenStorage: tokenStorage,
        client: MockClient((request) async {
          if (request.url.path.endsWith('/api/me')) {
            return http.Response(
              jsonEncode({
                'success': true,
                'data': {'id': 8, 'name': 'ServerErr User', 'email': 'err@plasvora.test'},
              }),
              200,
            );
          }
          if (request.url.path.endsWith('/api/logout')) {
            return http.Response(jsonEncode({'message': 'Internal Server Error'}), 500);
          }
          return http.Response(jsonEncode({'success': true}), 200);
        }),
      );

      final authRepo = ApiAuthRepository(apiClient: apiClient);
      final orderVm = OrderViewModel(
        orderRepository: _ControllableOrderRepository()
          ..buyerOrders = [_order(id: 1, orderNumber: 'ORD-500')],
      );
      final galleryVm = GalleryViewModel(
        galleryRepository: _ControllableGalleryRepository()
          ..myWorks = [_galleryWork(id: 1, title: 'My Work 500')],
      );

      final authVm = AuthViewModel(
        authRepository: authRepo,
        onSessionCleared: () {
          orderVm.clearUserData();
          galleryVm.clearUserData();
        },
      );

      await Future<void>.delayed(Duration.zero);
      await orderVm.loadBuyerOrders();
      await galleryVm.loadMyWorks();

      await authVm.logout();

      expect(await tokenStorage.getToken(), isNull);
      expect(authVm.state, AuthState.unauthenticated);
      expect(authVm.currentUser, isNull);
      expect(orderVm.buyerOrders, isEmpty);
      expect(galleryVm.myWorks, isEmpty);
    });
  });
}
