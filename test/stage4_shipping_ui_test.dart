import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:plasvora/core/constants/app_assets.dart';
import 'package:plasvora/core/network/api_client.dart';
import 'package:plasvora/core/theme/app_theme.dart';
import 'package:plasvora/core/widgets/destination_picker_sheet.dart';
import 'package:plasvora/core/widgets/plasvora_header.dart';
import 'package:plasvora/core/widgets/simple_page_app_bar.dart';
import 'package:plasvora/models/impact_summary.dart';
import 'package:plasvora/models/material_listing.dart';
import 'package:plasvora/models/plastic_analysis.dart';
import 'package:plasvora/models/shipping_destination.dart';
import 'package:plasvora/models/user_address.dart';
import 'package:plasvora/models/user_profile.dart';
import 'package:plasvora/repositories/address_repository.dart';
import 'package:plasvora/repositories/auth_repository.dart';
import 'package:plasvora/repositories/material_repository.dart';
import 'package:plasvora/repositories/shipping_repository.dart';
import 'package:plasvora/viewmodels/address_viewmodel.dart';
import 'package:plasvora/viewmodels/auth_viewmodel.dart';
import 'package:plasvora/viewmodels/marketplace_viewmodel.dart';
import 'package:plasvora/views/address/address_form_screen.dart';
import 'package:plasvora/views/address/address_list_screen.dart';
import 'package:plasvora/views/marketplace/create_material_listing_screen.dart';
import 'package:plasvora/views/marketplace/material_detail_screen.dart';

// ─── Test Fakes ──────────────────────────────────────────────────────────────

class _FakeAuthRepository implements AuthRepository {
  UserProfile? user;

  _FakeAuthRepository({this.user});

  @override
  Future<UserProfile?> getCurrentUser() async => user;

  @override
  Future<bool> isAuthenticated() async => user != null;

  @override
  Future<UserProfile> login({
    required String email,
    required String password,
  }) async =>
      user ??
      UserProfile(id: 99, name: 'Pembeli', email: email);

  @override
  Future<void> logout() async {
    user = null;
  }

  @override
  Future<UserProfile> register({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
    String? phone,
  }) async =>
      user ?? UserProfile(id: 99, name: name, email: email, phone: phone);

  @override
  Future<UserProfile> updateProfile({
    String? name,
    String? phone,
    bool? whatsappPublic,
  }) async =>
      user!;
}

class _FakeShippingRepository implements ShippingRepository {
  final List<String> searchedQueries = [];
  int estimateCallCount = 0;
  int? lastEstimateListingId;
  int? lastEstimateAddressId;

  Future<List<ShippingDestination>> Function(String query)? onSearch;
  Future<ShippingEstimateResult> Function(int listingId, int addressId)?
      onEstimate;

  @override
  Future<List<ShippingDestination>> searchDestinations({
    required String query,
    int limit = 10,
    int offset = 0,
  }) async {
    searchedQueries.add(query);
    if (onSearch != null) {
      return onSearch!(query);
    }
    return const [
      ShippingDestination(
        destinationId: 4949,
        label: 'BRAGA, SUMUR BANDUNG, BANDUNG, JAWA BARAT, 40111',
        provinceName: 'JAWA BARAT',
        cityName: 'BANDUNG',
        districtName: 'SUMUR BANDUNG',
        subdistrictName: 'BRAGA',
        postalCode: '40111',
      ),
    ];
  }

  @override
  Future<ShippingEstimateResult> estimateShipping({
    required int listingId,
    required int addressId,
  }) async {
    estimateCallCount++;
    lastEstimateListingId = listingId;
    lastEstimateAddressId = addressId;
    if (onEstimate != null) {
      return onEstimate!(listingId, addressId);
    }
    return ShippingEstimateResult(
      listing: ShippingEstimateListingSummary(
        id: listingId,
        name: 'Botol PET Bening',
        weightKg: 3.0,
        weightGrams: 3000,
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
          courierName: 'JNE',
          service: 'REG',
          description: 'Layanan Reguler',
          cost: 16000,
          etd: '2-3 hari',
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
    );
  }
}

class _FakeAddressRepository implements AddressRepository {
  List<UserAddress> items;
  int getCount = 0;
  int createCount = 0;
  int updateCount = 0;
  int deleteCount = 0;

  Future<List<UserAddress>> Function()? onGet;
  Future<UserAddress> Function({
    String? label,
    required String recipientName,
    required String recipientPhone,
    required int destinationId,
    required String destinationLabel,
    required String addressDetail,
    String? postalCode,
    String? deliveryNote,
    bool? isDefault,
  })? onCreate;
  Future<UserAddress> Function({required int id, bool? isDefault})? onUpdate;
  Future<void> Function(int id)? onDelete;

  Map<String, dynamic>? lastCreatePayload;

  _FakeAddressRepository({List<UserAddress>? initialItems})
      : items = List<UserAddress>.from(initialItems ?? const []);

  @override
  Future<List<UserAddress>> getAddresses() async {
    getCount++;
    if (onGet != null) {
      return onGet!();
    }
    return List<UserAddress>.from(items);
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
  }) async {
    createCount++;
    lastCreatePayload = {
      'label': label,
      'recipient_name': recipientName,
      'recipient_phone': recipientPhone,
      'destination_id': destinationId,
      'destination_label': destinationLabel,
      'address_detail': addressDetail,
      'postal_code': postalCode,
      'delivery_note': deliveryNote,
      'is_default': isDefault,
    };
    if (onCreate != null) {
      return onCreate!(
        label: label,
        recipientName: recipientName,
        recipientPhone: recipientPhone,
        destinationId: destinationId,
        destinationLabel: destinationLabel,
        addressDetail: addressDetail,
        postalCode: postalCode,
        deliveryNote: deliveryNote,
        isDefault: isDefault,
      );
    }
    final shouldDefault = items.isEmpty || (isDefault ?? false);
    if (shouldDefault) {
      items = items.map((a) => a.copyWith(isDefault: false)).toList();
    }
    final created = UserAddress(
      id: 100 + createCount,
      label: (label != null && label.trim().isNotEmpty) ? label.trim() : 'Rumah',
      recipientName: recipientName,
      recipientPhone: recipientPhone,
      destinationId: destinationId,
      destinationLabel: destinationLabel,
      addressDetail: addressDetail,
      postalCode: postalCode,
      deliveryNote: deliveryNote,
      isDefault: shouldDefault,
    );
    items.insert(0, created);
    return created;
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
  }) async {
    updateCount++;
    if (onUpdate != null) {
      return onUpdate!(id: id, isDefault: isDefault);
    }
    final idx = items.indexWhere((a) => a.id == id);
    if (isDefault == true) {
      items = items
          .map((a) => a.copyWith(isDefault: a.id == id))
          .toList();
    }
    final current = items[idx];
    final updated = current.copyWith(
      label: label ?? current.label,
      recipientName: recipientName ?? current.recipientName,
      recipientPhone: recipientPhone ?? current.recipientPhone,
      destinationId: destinationId ?? current.destinationId,
      destinationLabel: destinationLabel ?? current.destinationLabel,
      addressDetail: addressDetail ?? current.addressDetail,
      postalCode: postalCode ?? current.postalCode,
      deliveryNote: deliveryNote ?? current.deliveryNote,
      isDefault: isDefault ?? current.isDefault,
    );
    items[idx] = updated;
    return updated;
  }

  @override
  Future<void> deleteAddress(int id) async {
    deleteCount++;
    if (onDelete != null) {
      await onDelete!(id);
      return;
    }
    items.removeWhere((a) => a.id == id);
  }
}

class _FakeMaterialRepository implements MaterialRepository {
  MaterialListing detailListing;
  int createCallCount = 0;
  int updateCallCount = 0;
  Map<String, dynamic>? lastCreateArgs;
  Map<String, dynamic>? lastUpdateArgs;
  Object? createError;
  Object? updateError;

  _FakeMaterialRepository({required this.detailListing});

  @override
  Future<List<MaterialListing>> getMaterials({
    String? category,
    String? query,
    String? condition,
    double? minWeight,
    double? maxWeight,
    String? location,
  }) async =>
      [detailListing];

  @override
  Future<MaterialListing> getMaterialDetail(int id) async => detailListing;

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
    createCallCount++;
    lastCreateArgs = {
      'name': name,
      'category': category,
      'weightKg': weightKg,
      'condition': condition,
      'price': price,
      'isFree': isFree,
      'generalLocation': generalLocation,
      'description': description,
      'originDestinationId': originDestinationId,
      'originLabel': originLabel,
      'imagePath': imagePath,
    };
    if (createError != null) {
      throw createError!;
    }
    return MaterialListing(
      id: 500 + createCallCount,
      ownerId: 10,
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
      createdAt: DateTime(2026, 11, 22),
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
    updateCallCount++;
    lastUpdateArgs = {
      'id': id,
      'name': name,
      'category': category,
      'weightKg': weightKg,
      'condition': condition,
      'price': price,
      'isFree': isFree,
      'generalLocation': generalLocation,
      'description': description,
      'originDestinationId': originDestinationId,
      'originLabel': originLabel,
      'clearOrigin': clearOrigin,
      'imagePath': imagePath,
    };
    if (updateError != null) {
      throw updateError!;
    }
    detailListing = MaterialListing(
      id: id,
      ownerId: detailListing.ownerId,
      ownerName: detailListing.ownerName,
      name: name ?? detailListing.name,
      category: category ?? detailListing.category,
      weightKg: weightKg ?? detailListing.weightKg,
      condition: condition ?? detailListing.condition,
      price: price ?? detailListing.price,
      isFree: isFree ?? detailListing.isFree,
      generalLocation: generalLocation ?? detailListing.generalLocation,
      originDestinationId: clearOrigin
          ? null
          : (originDestinationId ?? detailListing.originDestinationId),
      originLabel: clearOrigin
          ? null
          : (originLabel ?? detailListing.originLabel),
      description: description ?? detailListing.description,
      imageUrl: detailListing.imageUrl,
      createdAt: detailListing.createdAt,
    );
    return detailListing;
  }

  @override
  Future<void> toggleFavorite(int id) async {}

  @override
  void clearUserData() {}

  @override
  Future<ImpactSummary> getImpactSummary() async => ImpactSummary(
        listedCount: 0,
        listedWeightKg: 0.0,
        availableCount: 0,
        availableWeightKg: 0.0,
        handedOverCount: 0,
        handedOverWeightKg: 0.0,
        confirmedCount: 0,
        confirmedWeightKg: 0.0,
      );
}

// ─── Helpers ─────────────────────────────────────────────────────────────────

MaterialListing _sampleListing({
  int id = 11,
  int ownerId = 10,
  int? originDestinationId = 4949,
  String? originLabel = 'BRAGA, SUMUR BANDUNG, BANDUNG, JAWA BARAT, 40111',
  String? imageUrl,
  String? localAsset,
}) {
  return MaterialListing(
    id: id,
    ownerId: ownerId,
    ownerName: 'Penjual Bandung',
    name: 'Botol PET Bening',
    category: 'PET',
    weightKg: 3.0,
    condition: 'clean',
    price: 25000,
    isFree: false,
    generalLocation: 'Kota Bandung',
    originDestinationId: originDestinationId,
    originLabel: originLabel,
    description: 'Botol PET bersih sudah dipilah.',
    imageUrl: imageUrl,
    localAsset: localAsset,
    createdAt: DateTime(2026, 11, 22),
  );
}

UserAddress _sampleAddress({
  int id = 1,
  String label = 'Rumah',
  String recipientName = 'Rina Pembeli',
  String recipientPhone = '6281234567890',
  int destinationId = 6157,
  String destinationLabel = 'BABAKANKARET, CIANJUR, JAWA BARAT, 43211',
  String addressDetail = 'Jl. Raya Cianjur No. 88',
  String? postalCode = '43211',
  String? deliveryNote = 'Dekat masjid',
  bool isDefault = true,
}) {
  return UserAddress(
    id: id,
    label: label,
    recipientName: recipientName,
    recipientPhone: recipientPhone,
    destinationId: destinationId,
    destinationLabel: destinationLabel,
    addressDetail: addressDetail,
    postalCode: postalCode,
    deliveryNote: deliveryNote,
    isDefault: isDefault,
  );
}

Future<void> _scrollTo(WidgetTester tester, Finder finder) async {
  if (finder.evaluate().isEmpty) {
    await tester.scrollUntilVisible(
      finder,
      250,
      scrollable: find.byType(Scrollable).first,
    );
  }
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();

  // Pastikan target benar-benar berada dalam viewport 800x600 pada Scrollable ancestor-nya
  final scrollableAncestor = find.ancestor(
    of: finder,
    matching: find.byType(Scrollable),
  );
  if (scrollableAncestor.evaluate().isNotEmpty) {
    final scrollableState = tester.state<ScrollableState>(
      scrollableAncestor.first,
    );
    final viewportHeight =
        tester.view.physicalSize.height / tester.view.devicePixelRatio;
    final center = tester.getCenter(finder);
    if (center.dy > viewportHeight - 24 || center.dy < 24) {
      final position = scrollableState.position;
      final targetOffset = (position.pixels + (center.dy - viewportHeight / 2))
          .clamp(position.minScrollExtent, position.maxScrollExtent);
      position.jumpTo(targetOffset);
      await tester.pumpAndSettle();
    }
  }
}

Future<void> _scrollToAndTap(WidgetTester tester, Finder finder) async {
  await _scrollTo(tester, finder);
  final viewportSize =
      tester.view.physicalSize / tester.view.devicePixelRatio;
  final center = tester.getCenter(finder);
  expect(
    center.dy,
    inInclusiveRange(0.0, viewportSize.height),
    reason: 'Target tombol harus berada di dalam viewport sebelum di-tap',
  );
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<void> _ensureAndEnterText(
  WidgetTester tester,
  Finder finder,
  String text,
) async {
  await _scrollTo(tester, finder);
  await tester.enterText(finder, text);
  // Selesaikan timer internal EditableText (_showCaretOnScreen ~100ms) sebelum scroll berikutnya
  await tester.pumpAndSettle();
}

void main() {
  late bool previousAllowRuntimeFetching;

  setUpAll(() {
    previousAllowRuntimeFetching = GoogleFonts.config.allowRuntimeFetching;
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  tearDownAll(() {
    GoogleFonts.config.allowRuntimeFetching = previousAllowRuntimeFetching;
  });

  group('Stage 2 Batch 4 — Bundled Plus Jakarta Sans Fonts', () {
    testWidgets(
      'loads all required PlusJakartaSans weights from local assets with runtime fetching disabled',
      (tester) async {
        expect(GoogleFonts.config.allowRuntimeFetching, isFalse);

        await tester.runAsync(() async {
          await GoogleFonts.pendingFonts([
            GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w400),
            GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w500),
            GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
            GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
          ]);
        });
      },
    );
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // 1. DESTINATION PICKER
  // ═══════════════════════════════════════════════════════════════════════════
  group('Stage 2 Batch 4 — DestinationPickerSheet', () {
    testWidgets('shows initial hint and skips API for query < 2 chars', (
      tester,
    ) async {
      final shippingRepo = _FakeShippingRepository();

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: DestinationPickerSheet(shippingRepository: shippingRepo),
          ),
        ),
      );

      expect(
        find.text(
          'Ketik minimal 2 karakter untuk mencari kelurahan, kecamatan, atau kota.',
        ),
        findsOneWidget,
      );

      await tester.enterText(find.byType(TextField), 'b');
      await tester.pump(const Duration(milliseconds: 500));

      expect(shippingRepo.searchedQueries, isEmpty);
    });

    testWidgets('debounces rapid input and returns selected ShippingDestination', (
      tester,
    ) async {
      final shippingRepo = _FakeShippingRepository();
      ShippingDestination? picked;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Builder(
            builder: (context) => Scaffold(
              body: ElevatedButton(
                onPressed: () async {
                  picked = await DestinationPickerSheet.show(
                    context,
                    shippingRepository: shippingRepo,
                  );
                },
                child: const Text('Buka Picker'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Buka Picker'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'ba');
      await tester.pump(const Duration(milliseconds: 200));
      await tester.enterText(find.byType(TextField), 'bandung');
      await tester.pump(const Duration(milliseconds: 200));
      expect(shippingRepo.searchedQueries, isEmpty);

      await tester.pump(const Duration(milliseconds: 250));
      await tester.pumpAndSettle();

      expect(shippingRepo.searchedQueries, ['bandung']);
      expect(
        find.text('BRAGA, SUMUR BANDUNG, BANDUNG, JAWA BARAT, 40111'),
        findsOneWidget,
      );
      expect(find.text('Kode Pos 40111'), findsOneWidget);

      await tester.tap(
        find.text('BRAGA, SUMUR BANDUNG, BANDUNG, JAWA BARAT, 40111'),
      );
      await tester.pumpAndSettle();

      expect(picked, isNotNull);
      expect(picked!.destinationId, 4949);
      expect(picked!.label, 'BRAGA, SUMUR BANDUNG, BANDUNG, JAWA BARAT, 40111');
    });

    testWidgets('shows empty state when no destinations match', (tester) async {
      final shippingRepo = _FakeShippingRepository()
        ..onSearch = (_) async => const [];

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: DestinationPickerSheet(shippingRepository: shippingRepo),
          ),
        ),
      );

      await tester.enterText(find.byType(TextField), 'zzzz');
      await tester.pump(const Duration(milliseconds: 450));
      await tester.pumpAndSettle();

      expect(find.text('Lokasi tidak ditemukan.'), findsOneWidget);
    });

    testWidgets('shows friendly error state and supports retry', (
      tester,
    ) async {
      var attempt = 0;
      final shippingRepo = _FakeShippingRepository()
        ..onSearch = (_) async {
          attempt++;
          if (attempt == 1) {
            throw ApiException('Layanan ongkir sedang sibuk.');
          }
          return const [
            ShippingDestination(
              destinationId: 6157,
              label: 'BABAKANKARET, CIANJUR, JAWA BARAT, 43211',
              postalCode: '43211',
            ),
          ];
        };

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: DestinationPickerSheet(shippingRepository: shippingRepo),
          ),
        ),
      );

      await tester.enterText(find.byType(TextField), 'cianjur');
      await tester.pump(const Duration(milliseconds: 450));
      await tester.pumpAndSettle();

      expect(find.text('Layanan ongkir sedang sibuk.'), findsOneWidget);
      expect(find.text('Coba Lagi'), findsOneWidget);

      await tester.tap(find.text('Coba Lagi'));
      await tester.pumpAndSettle();

      expect(
        find.text('BABAKANKARET, CIANJUR, JAWA BARAT, 43211'),
        findsOneWidget,
      );
    });

    testWidgets('ignores stale responses that resolve after newer query', (
      tester,
    ) async {
      final firstCompleter = Completer<List<ShippingDestination>>();
      final secondCompleter = Completer<List<ShippingDestination>>();

      final shippingRepo = _FakeShippingRepository()
        ..onSearch = (query) {
          if (query == 'bandung') return firstCompleter.future;
          return secondCompleter.future;
        };

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: DestinationPickerSheet(shippingRepository: shippingRepo),
          ),
        ),
      );

      await tester.enterText(find.byType(TextField), 'bandung');
      await tester.pump(const Duration(milliseconds: 450));

      await tester.enterText(find.byType(TextField), 'cianjur');
      await tester.pump(const Duration(milliseconds: 450));

      // Newer query finishes first
      secondCompleter.complete(const [
        ShippingDestination(
          destinationId: 6157,
          label: 'BABAKANKARET, CIANJUR, JAWA BARAT, 43211',
        ),
      ]);
      await tester.pumpAndSettle();
      expect(
        find.text('BABAKANKARET, CIANJUR, JAWA BARAT, 43211'),
        findsOneWidget,
      );

      // Older query finishes later and MUST be ignored
      firstCompleter.complete(const [
        ShippingDestination(
          destinationId: 4949,
          label: 'BRAGA, SUMUR BANDUNG, BANDUNG, JAWA BARAT, 40111',
        ),
      ]);
      await tester.pumpAndSettle();

      expect(
        find.text('BABAKANKARET, CIANJUR, JAWA BARAT, 43211'),
        findsOneWidget,
      );
      expect(
        find.text('BRAGA, SUMUR BANDUNG, BANDUNG, JAWA BARAT, 40111'),
        findsNothing,
      );
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // 2. ADDRESS LIST & FORM
  // ═══════════════════════════════════════════════════════════════════════════
  group('Stage 2 Batch 4 — Address List & Form', () {
    testWidgets('displays loading state while fetching addresses', (
      tester,
    ) async {
      final completer = Completer<List<UserAddress>>();
      final addrRepo = _FakeAddressRepository()
        ..onGet = () => completer.future;
      final addressVm = AddressViewModel(addressRepository: addrRepo);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: AddressListScreen(
            addressViewModel: addressVm,
            shippingRepository: _FakeShippingRepository(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Memuat daftar alamat...'), findsOneWidget);

      completer.complete(const []);
      await tester.pumpAndSettle();
    });

    testWidgets('displays empty state with Tambah Alamat CTA', (tester) async {
      final addrRepo = _FakeAddressRepository(initialItems: const []);
      final addressVm = AddressViewModel(addressRepository: addrRepo);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: AddressListScreen(
            addressViewModel: addressVm,
            shippingRepository: _FakeShippingRepository(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Belum Ada Alamat Pengiriman'), findsOneWidget);
      expect(find.text('Tambah Alamat'), findsOneWidget);
    });

    testWidgets('displays error state when loading addresses fails', (
      tester,
    ) async {
      final addrRepo = _FakeAddressRepository()
        ..onGet = () async => throw ApiException('Server alamat bermasalah.');
      final addressVm = AddressViewModel(addressRepository: addrRepo);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: AddressListScreen(
            addressViewModel: addressVm,
            shippingRepository: _FakeShippingRepository(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Gagal Memuat Alamat'), findsOneWidget);
      expect(find.text('Server alamat bermasalah.'), findsOneWidget);
      expect(find.text('Coba Lagi'), findsOneWidget);
    });

    testWidgets(
      'displays addresses, default badge, set-default mutation refresh, and delete confirmation',
      (tester) async {
        final addr1 = _sampleAddress(id: 1, label: 'Rumah', isDefault: true);
        final addr2 = _sampleAddress(
          id: 2,
          label: 'Gudang',
          recipientName: 'Andi Gudang',
          isDefault: false,
        );
        final addrRepo = _FakeAddressRepository(initialItems: [addr1, addr2]);
        final addressVm = AddressViewModel(addressRepository: addrRepo);

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.lightTheme,
            home: AddressListScreen(
              addressViewModel: addressVm,
              shippingRepository: _FakeShippingRepository(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Rumah'), findsOneWidget);
        expect(find.text('Gudang'), findsOneWidget);
        expect(find.text('Alamat Utama'), findsOneWidget);
        expect(find.text('Jadikan Utama'), findsOneWidget);

        // Set addr2 as default
        await tester.tap(find.text('Jadikan Utama'));
        await tester.pumpAndSettle();

        expect(addrRepo.updateCount, 1);
        expect(addressVm.defaultAddress?.id, 2);

        // Delete confirmation cancel & confirm
        await tester.tap(find.text('Hapus').first);
        await tester.pumpAndSettle();
        expect(find.text('Hapus Alamat?'), findsOneWidget);

        await tester.tap(find.text('Batal'));
        await tester.pumpAndSettle();
        expect(addrRepo.deleteCount, 0);

        await tester.tap(find.text('Hapus').first);
        await tester.pumpAndSettle();
        await tester.tap(find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text('Hapus'),
        ));
        await tester.pumpAndSettle();

        expect(addrRepo.deleteCount, 1);
        expect(addressVm.addresses.length, 1);
      },
    );

    testWidgets(
      'AddressFormScreen validates phone, required/whitespace fields, selects destination, and submits',
      (tester) async {
        final addrRepo = _FakeAddressRepository();
        final addressVm = AddressViewModel(addressRepository: addrRepo);
        final shippingRepo = _FakeShippingRepository();

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.lightTheme,
            home: AddressFormScreen(
              addressViewModel: addressVm,
              shippingRepository: shippingRepo,
            ),
          ),
        );

        // Trigger validation on empty form
        await _scrollToAndTap(tester, find.text('Simpan Alamat'));
        expect(find.text('Nama penerima wajib diisi.'), findsOneWidget);
        expect(find.text('Nomor telepon penerima wajib diisi.'), findsOneWidget);
        expect(
          find.text('Wilayah tujuan wajib dipilih dari daftar pencarian.'),
          findsOneWidget,
        );
        expect(find.text('Alamat lengkap wajib diisi.'), findsOneWidget);

        // Invalid phone + whitespace address detail
        await _ensureAndEnterText(
          tester,
          find.widgetWithText(TextFormField, 'Nama Penerima *'),
          'Siti Pembeli',
        );
        await _ensureAndEnterText(
          tester,
          find.widgetWithText(TextFormField, 'Nomor Telepon Penerima *'),
          '12345',
        );
        await _ensureAndEnterText(
          tester,
          find.widgetWithText(TextFormField, 'Alamat Lengkap *'),
          '   ',
        );
        await _scrollToAndTap(tester, find.text('Simpan Alamat'));
        expect(
          find.text(
            'Format nomor tidak valid. Contoh: 081234567890 atau +6281234567890.',
          ),
          findsOneWidget,
        );
        expect(find.text('Alamat lengkap wajib diisi.'), findsOneWidget);

        // Enter valid phone & address detail + pick destination
        await _ensureAndEnterText(
          tester,
          find.widgetWithText(TextFormField, 'Nomor Telepon Penerima *'),
          '081234567890',
        );
        await _ensureAndEnterText(
          tester,
          find.widgetWithText(TextFormField, 'Alamat Lengkap *'),
          'Jl. Braga No. 10 RT 01 RW 02',
        );

        final pickerTrigger = find.text('Pilih kelurahan, kecamatan, atau kota');
        await tester.ensureVisible(pickerTrigger);
        await tester.pumpAndSettle();
        await tester.tap(pickerTrigger);
        await tester.pumpAndSettle();

        await tester.enterText(
          find.descendant(
            of: find.byType(DestinationPickerSheet),
            matching: find.byType(TextField),
          ),
          'bandung',
        );
        await tester.pump(const Duration(milliseconds: 450));
        await tester.pumpAndSettle();
        await tester.tap(
          find.text('BRAGA, SUMUR BANDUNG, BANDUNG, JAWA BARAT, 40111'),
        );
        await tester.pumpAndSettle();

        // Postal code autofilled from destination
        expect(find.text('40111'), findsOneWidget);

        await _scrollToAndTap(tester, find.text('Simpan Alamat'));

        expect(addrRepo.createCount, 1);
        expect(addrRepo.lastCreatePayload?['destination_id'], 4949);
        expect(
          addrRepo.lastCreatePayload?['destination_label'],
          'BRAGA, SUMUR BANDUNG, BANDUNG, JAWA BARAT, 40111',
        );
        expect(addrRepo.lastCreatePayload?['postal_code'], '40111');
      },
    );

    testWidgets('AddressFormScreen prefills existing address in edit mode', (
      tester,
    ) async {
      final existing = _sampleAddress(
        id: 7,
        label: 'Kantor',
        recipientName: 'Budi Kantor',
        recipientPhone: '6281398765432',
        destinationLabel: 'BABAKANKARET, CIANJUR, JAWA BARAT, 43211',
        addressDetail: 'Jl. Siliwangi No. 5',
        postalCode: '43211',
        deliveryNote: 'Titip resepsionis',
        isDefault: true,
      );
      final addrRepo = _FakeAddressRepository(initialItems: [existing]);
      final addressVm = AddressViewModel(addressRepository: addrRepo);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: AddressFormScreen(
            addressViewModel: addressVm,
            shippingRepository: _FakeShippingRepository(),
            existingAddress: existing,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Edit Alamat'), findsOneWidget);
      expect(find.text('Kantor'), findsOneWidget);
      expect(find.text('Budi Kantor'), findsOneWidget);
      expect(find.text('6281398765432'), findsOneWidget);
      expect(
        find.text('BABAKANKARET, CIANJUR, JAWA BARAT, 43211'),
        findsOneWidget,
      );
      expect(find.text('Jl. Siliwangi No. 5'), findsOneWidget);
      expect(find.text('43211'), findsOneWidget);
      expect(find.text('Titip resepsionis'), findsOneWidget);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // 3. LISTING CREATE & EDIT
  // ═══════════════════════════════════════════════════════════════════════════
  group('Stage 2 Batch 4 — Listing Create & Edit', () {
    testWidgets(
      'Create requires origin, preserves AI prefill, and submits both origin fields',
      (tester) async {
        final materialRepo = _FakeMaterialRepository(
          detailListing: _sampleListing(),
        );
        final marketVm = MarketplaceViewModel(materialRepository: materialRepo);
        final shippingRepo = _FakeShippingRepository();

        const analysis = PlasticAnalysisResult(
          id: 'ai-1',
          localAsset: AppAssets.petFlakes,
          objectName: 'Botol Air Mineral',
          materialTitle: 'Botol PET AI',
          polymerCategory: 'PET',
          polymerCode: '#1',
          meltingPoint: '250°C',
          avoidedEmission: '2.1 kg CO2',
          qualitativeNote: 'Layak daur ulang',
          ideas: [],
        );

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.lightTheme,
            home: CreateMaterialListingScreen(
              viewModel: marketVm,
              initialAnalysis: analysis,
              shippingRepository: shippingRepo,
            ),
          ),
        );
        await tester.pumpAndSettle();

        // AI prefill preserved
        expect(find.text('Botol PET AI'), findsOneWidget);
        expect(find.textContaining('Material hasil analisis AI Plasvora.'), findsOneWidget);

        // Fill weight & location without selecting origin -> blocked locally
        await _ensureAndEnterText(
          tester,
          find.widgetWithText(TextFormField, 'Berat Aktual (kg) *'),
          '4.5',
        );
        await _ensureAndEnterText(
          tester,
          find.widgetWithText(TextFormField, 'Lokasi Umum *'),
          'Bandung Tengah',
        );
        await _scrollToAndTap(tester, find.text('Publikasikan Penawaran'));

        expect(
          find.text('Lokasi asal pengiriman wajib dipilih dari daftar pencarian.'),
          findsOneWidget,
        );
        expect(materialRepo.createCallCount, 0);

        // Select origin via DestinationPickerSheet
        final originTrigger =
            find.text('Pilih kelurahan, kecamatan, atau kota asal');
        await tester.ensureVisible(originTrigger);
        await tester.pumpAndSettle();
        await tester.tap(originTrigger);
        await tester.pumpAndSettle();

        await tester.enterText(
          find.descendant(
            of: find.byType(DestinationPickerSheet),
            matching: find.byType(TextField),
          ),
          'bandung',
        );
        await tester.pump(const Duration(milliseconds: 450));
        await tester.pumpAndSettle();
        await tester.tap(
          find.text('BRAGA, SUMUR BANDUNG, BANDUNG, JAWA BARAT, 40111'),
        );
        await tester.pumpAndSettle();

        // Manual generalLocation NOT overwritten, AI name intact
        expect(find.text('Bandung Tengah'), findsOneWidget);
        expect(find.text('Botol PET AI'), findsOneWidget);

        await _scrollToAndTap(tester, find.text('Publikasikan Penawaran'));

        expect(materialRepo.createCallCount, 1);
        expect(materialRepo.lastCreateArgs?['originDestinationId'], 4949);
        expect(
          materialRepo.lastCreateArgs?['originLabel'],
          'BRAGA, SUMUR BANDUNG, BANDUNG, JAWA BARAT, 40111',
        );
        expect(materialRepo.lastCreateArgs?['name'], 'Botol PET AI');
      },
    );

    testWidgets('Edit mode rejects corrupted half-pair origin locally', (
      tester,
    ) async {
      final halfPairListing = _sampleListing(
        originDestinationId: 4949,
        originLabel: null,
      );
      final materialRepo = _FakeMaterialRepository(
        detailListing: halfPairListing,
      );
      final marketVm = MarketplaceViewModel(materialRepository: materialRepo);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: CreateMaterialListingScreen(
            viewModel: marketVm,
            existingListing: halfPairListing,
            shippingRepository: _FakeShippingRepository(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await _scrollToAndTap(tester, find.text('Simpan Perubahan'));

      expect(
        find.text(
          'Lokasi asal pengiriman tidak lengkap. Pilih lokasi valid dari daftar pencarian.',
        ),
        findsOneWidget,
      );
      expect(materialRepo.updateCallCount, 0);
    });

    testWidgets(
      'Edit mode prefills fields, allows editing legacy null-origin listing, and preserves existing image',
      (tester) async {
        final legacyListing = _sampleListing(
          id: 22,
          originDestinationId: null,
          originLabel: null,
          localAsset: AppAssets.petFlakes,
        );
        final materialRepo = _FakeMaterialRepository(
          detailListing: legacyListing,
        );
        final marketVm = MarketplaceViewModel(materialRepository: materialRepo);

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.lightTheme,
            home: CreateMaterialListingScreen(
              viewModel: marketVm,
              existingListing: legacyListing,
              shippingRepository: _FakeShippingRepository(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Edit Listing'), findsOneWidget);
        expect(find.text('Botol PET Bening'), findsOneWidget);
        expect(find.text('25000'), findsOneWidget);
        expect(find.text('Foto Saat Ini'), findsOneWidget);

        await _ensureAndEnterText(
          tester,
          find.widgetWithText(TextFormField, 'Nama Material *'),
          'Botol PET Bening Update',
        );
        await _scrollToAndTap(tester, find.text('Simpan Perubahan'));

        expect(materialRepo.updateCallCount, 1);
        expect(materialRepo.lastUpdateArgs?['name'], 'Botol PET Bening Update');
        expect(materialRepo.lastUpdateArgs?['clearOrigin'], isFalse);
        expect(materialRepo.lastUpdateArgs?['originDestinationId'], isNull);
        expect(materialRepo.lastUpdateArgs?['imagePath'], isNull);
      },
    );

    testWidgets('Edit mode explicit origin clearing sends clearOrigin: true', (
      tester,
    ) async {
      final listing = _sampleListing(
        id: 23,
        originDestinationId: 4949,
        originLabel: 'BRAGA, SUMUR BANDUNG, BANDUNG, JAWA BARAT, 40111',
      );
      final materialRepo = _FakeMaterialRepository(detailListing: listing);
      final marketVm = MarketplaceViewModel(materialRepository: materialRepo);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: CreateMaterialListingScreen(
            viewModel: marketVm,
            existingListing: listing,
            shippingRepository: _FakeShippingRepository(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await _scrollToAndTap(tester, find.text('Hapus Lokasi Asal'));
      await _scrollToAndTap(tester, find.text('Simpan Perubahan'));

      expect(materialRepo.updateCallCount, 1);
      expect(materialRepo.lastUpdateArgs?['clearOrigin'], isTrue);
      expect(materialRepo.lastUpdateArgs?['originDestinationId'], isNull);
      expect(materialRepo.lastUpdateArgs?['originLabel'], isNull);
    });

    testWidgets(
      'Edit mode new image replacement uses multipart POST with _method=PATCH',
      (tester) async {
        final tempDir = Directory.systemTemp.createTempSync(
          'plasvora_stage4_mp_',
        );
        final tempFile = File(
          '${tempDir.path}${Platform.pathSeparator}replace_${DateTime.now().microsecondsSinceEpoch}.png',
        );
        // Minimal 1x1 PNG bytes (sinkron agar tidak memblokir FakeAsync)
        tempFile.writeAsBytesSync(const [
          0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A,
          0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52,
          0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
          0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4,
          0x89, 0x00, 0x00, 0x00, 0x0A, 0x49, 0x44, 0x41,
          0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
          0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00,
          0x00, 0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE,
          0x42, 0x60, 0x82,
        ]);
        addTearDown(() {
          PaintingBinding.instance.imageCache.clear();
          if (tempDir.existsSync()) {
            tempDir.deleteSync(recursive: true);
          }
        });

        http.BaseRequest? updateRequest;
        String? multipartBody;
        final requestStreamConsumed = Completer<void>();
        final responseReturned = Completer<void>();

        final storage = InMemoryAuthTokenStorage();
        await storage.saveToken('test-token');
        final apiClient = ApiClient(
          client: MockClient.streaming((request, bodyStream) async {
            if (request.method == 'GET' &&
                request.url.path.endsWith('/api/materials')) {
              return http.StreamedResponse(
                Stream.value(
                  utf8.encode(jsonEncode({'success': true, 'data': []})),
                ),
                200,
              );
            }
            try {
              updateRequest = request;
              final bodyBytes = await bodyStream.toBytes();
              multipartBody = utf8.decode(bodyBytes, allowMalformed: true);
              if (!requestStreamConsumed.isCompleted) {
                requestStreamConsumed.complete();
              }
              final response = http.StreamedResponse(
                Stream.value(
                  utf8.encode(
                    jsonEncode({
                      'success': true,
                      'data': {
                        'id': 31,
                        'owner_id': 10,
                        'name': 'Botol PET Bening',
                        'category': 'PET',
                        'weight_kg': 3.0,
                        'condition': 'clean',
                        'price': 25000,
                        'is_free': false,
                        'general_location': 'Kota Bandung',
                        'origin_destination_id': 4949,
                        'origin_label':
                            'BRAGA, SUMUR BANDUNG, BANDUNG, JAWA BARAT, 40111',
                        'description': 'Botol PET bersih sudah dipilah.',
                        'image_url': null,
                        'status': 'available',
                        'created_at': '2026-11-22T00:00:00Z',
                      },
                    }),
                  ),
                ),
                200,
              );
              if (!responseReturned.isCompleted) {
                responseReturned.complete();
              }
              return response;
            } finally {
              if (!requestStreamConsumed.isCompleted) {
                requestStreamConsumed.complete();
              }
              if (!responseReturned.isCompleted) {
                responseReturned.complete();
              }
            }
          }),
          tokenStorage: storage,
        );

        final apiMaterialRepo = ApiMaterialRepository(apiClient: apiClient);
        final marketVm = MarketplaceViewModel(
          materialRepository: apiMaterialRepo,
        );
        final existing = _sampleListing(
          id: 31,
          localAsset: AppAssets.petFlakes,
        );
        MaterialListing? updatedResult;
        Future<Object?>? pushFuture;
        final routeRemoved = Completer<void>();

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.lightTheme,
            home: Builder(
              builder: (context) => Scaffold(
                body: Center(
                  child: ElevatedButton(
                    onPressed: () {
                      final editRoute = MaterialPageRoute<Object?>(
                        builder: (_) => CreateMaterialListingScreen(
                          viewModel: marketVm,
                          existingListing: existing,
                          shippingRepository: _FakeShippingRepository(),
                          pickImageOverride: (_) async => tempFile.path,
                        ),
                      );
                      editRoute.completed.whenComplete(() {
                        if (!routeRemoved.isCompleted) {
                          routeRemoved.complete();
                        }
                      });
                      pushFuture = Navigator.of(
                        context,
                      ).push<Object?>(editRoute);
                      pushFuture!.then((res) {
                        if (res is MaterialListing) {
                          updatedResult = res;
                        }
                      });
                    },
                    child: const Text('Buka Edit'),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('Buka Edit'));
        await tester.pumpAndSettle();

        await _scrollToAndTap(tester, find.text('Ganti Foto Material'));
        await tester.tap(find.text('Pilih dari Galeri'));
        await tester.pump();
        // Beri waktu event loop asli agar FileImage selesai membaca dan menutup file sementara
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 50)),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        final submitBtn = find.text('Simpan Perubahan');
        await _scrollTo(tester, submitBtn);
        expect(
          tester.getCenter(submitBtn).dy,
          inInclusiveRange(0.0, 600.0),
        );
        await tester.tap(submitBtn);
        await tester.pump();

        // Bergantian memajukan event loop I/O asli (file.exists, MultipartFile.fromPath,
        // bodyStream.toBytes) dan microtask FakeAsync hingga seluruh pipeline & Navigator.pop selesai
        final stopwatch = Stopwatch()..start();
        while ((!requestStreamConsumed.isCompleted ||
                !responseReturned.isCompleted ||
                marketVm.isSaving ||
                updatedResult == null) &&
            stopwatch.elapsed < const Duration(seconds: 5)) {
          await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 10)),
          );
          await tester.pump();
        }

        // Pompa frame transisi reverse MaterialPageRoute secara deterministik
        // sampai sinyal editRoute.completed selesai (tanpa asumsi durasi tunggal 350ms)
        var popFrames = 0;
        while (!routeRemoved.isCompleted && popFrames < 20) {
          await tester.pump(const Duration(milliseconds: 100));
          popFrames++;
        }
        await tester.pump();

        final poppedValue = await pushFuture;

        expect(requestStreamConsumed.isCompleted, isTrue);
        expect(responseReturned.isCompleted, isTrue);
        expect(routeRemoved.isCompleted, isTrue);
        expect(updateRequest, isA<http.MultipartRequest>());
        expect(updateRequest!.method, 'POST');
        expect(updateRequest!.url.path, endsWith('/api/materials/31'));
        expect(multipartBody, contains('name="_method"'));
        expect(multipartBody, contains('PATCH'));
        expect(multipartBody, contains('name="image"'));
        expect(poppedValue, isA<MaterialListing>());
        expect((poppedValue as MaterialListing).id, 31);
        expect(updatedResult, isNotNull);
        expect(updatedResult!.id, 31);
        expect(marketVm.isSaving, isFalse);
        expect(find.byType(CreateMaterialListingScreen), findsNothing);
        expect(find.byType(CircularProgressIndicator), findsNothing);
      },
    );

    testWidgets(
      'Local ArgumentError from repository is presented as UI validation without uncaught exception',
      (tester) async {
        final listing = _sampleListing(id: 41);
        final materialRepo = _FakeMaterialRepository(detailListing: listing)
          ..updateError = ArgumentError(
            'Pasangan lokasi asal pengiriman tidak konsisten.',
          );
        final marketVm = MarketplaceViewModel(materialRepository: materialRepo);

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.lightTheme,
            home: CreateMaterialListingScreen(
              viewModel: marketVm,
              existingListing: listing,
              shippingRepository: _FakeShippingRepository(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        await _scrollToAndTap(tester, find.text('Simpan Perubahan'));

        expect(tester.takeException(), isNull);
        expect(
          find.text('Pasangan lokasi asal pengiriman tidak konsisten.'),
          findsWidgets,
        );
      },
    );

    testWidgets(
      'AppBar uses SimplePageAppBar (not PlasvoraHeader) with dynamic titles and working back navigation',
      (tester) async {
        final listing = _sampleListing(id: 51);
        final materialRepo = _FakeMaterialRepository(detailListing: listing);
        final marketVm = MarketplaceViewModel(materialRepository: materialRepo);
        final shippingRepo = _FakeShippingRepository();

        // 1. New listing mode -> 'Tawarkan Material' + working back pop
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.lightTheme,
            home: Builder(
              builder: (ctx) => Scaffold(
                body: Center(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(ctx).push(
                        MaterialPageRoute<void>(
                          builder: (_) => CreateMaterialListingScreen(
                            viewModel: marketVm,
                            shippingRepository: shippingRepo,
                          ),
                        ),
                      );
                    },
                    child: const Text('Buka Form Material'),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.tap(find.text('Buka Form Material'));
        await tester.pumpAndSettle();

        expect(find.byType(SimplePageAppBar), findsOneWidget);
        expect(find.byType(PlasvoraHeader), findsNothing);
        expect(
          find.descendant(
            of: find.byType(SimplePageAppBar),
            matching: find.text('Tawarkan Material'),
          ),
          findsOneWidget,
        );
        expect(find.text('Informasi Material'), findsOneWidget);

        await tester.tap(
          find.descendant(
            of: find.byType(SimplePageAppBar),
            matching: find.widgetWithIcon(IconButton, Icons.arrow_back),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.byType(CreateMaterialListingScreen), findsNothing);
        expect(find.text('Buka Form Material'), findsOneWidget);

        // 2. Launched from AI Analysis -> 'Jual Material Ini'
        const analysis = PlasticAnalysisResult(
          id: 'an-appbar',
          localAsset: AppAssets.petFlakes,
          materialTitle: 'Botol HDPE AI',
          polymerCategory: 'HDPE',
          polymerCode: '#2',
          meltingPoint: '130°C',
          avoidedEmission: '1.8 kg CO2',
          qualitativeNote: 'Siap dijual',
          ideas: [],
        );
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.lightTheme,
            home: CreateMaterialListingScreen(
              viewModel: marketVm,
              initialAnalysis: analysis,
              shippingRepository: shippingRepo,
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(SimplePageAppBar), findsOneWidget);
        expect(find.byType(PlasvoraHeader), findsNothing);
        expect(
          find.descendant(
            of: find.byType(SimplePageAppBar),
            matching: find.text('Jual Material Ini'),
          ),
          findsOneWidget,
        );
        expect(find.text('Botol HDPE AI'), findsOneWidget);

        // 3. Edit mode -> 'Edit Listing'
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.lightTheme,
            home: CreateMaterialListingScreen(
              viewModel: marketVm,
              existingListing: listing,
              shippingRepository: shippingRepo,
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(SimplePageAppBar), findsOneWidget);
        expect(find.byType(PlasvoraHeader), findsNothing);
        expect(
          find.descendant(
            of: find.byType(SimplePageAppBar),
            matching: find.text('Edit Listing'),
          ),
          findsOneWidget,
        );
        expect(find.text('Simpan Perubahan'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // 4. SHIPPING ESTIMATOR ON MATERIAL DETAIL SCREEN
  // ═══════════════════════════════════════════════════════════════════════════
  group('Stage 2 Batch 4 — MaterialDetailScreen Shipping Estimator', () {
    testWidgets('Owner sees Edit Listing and does not see Shipping Estimator', (
      tester,
    ) async {
      final listing = _sampleListing(id: 60, ownerId: 10);
      final materialRepo = _FakeMaterialRepository(detailListing: listing);
      final marketVm = MarketplaceViewModel(materialRepository: materialRepo);
      final authVm = AuthViewModel(
        authRepository: _FakeAuthRepository(
          user: UserProfile(id: 10, name: 'Pemilik', email: 'owner@test.id'),
        ),
      );
      await authVm.checkAuthSession();

      final addrRepo = _FakeAddressRepository(initialItems: [_sampleAddress()]);
      final addressVm = AddressViewModel(addressRepository: addrRepo);
      final shippingRepo = _FakeShippingRepository();

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: MaterialDetailScreen(
            materialId: listing.id,
            initialMaterial: listing,
            viewModel: marketVm,
            authViewModel: authVm,
            addressViewModel: addressVm,
            shippingRepository: shippingRepo,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.text('Edit Listing'),
        250,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Edit Listing'), findsOneWidget);
      expect(find.text('Estimasi Ongkos Kirim'), findsNothing);
      expect(addrRepo.getCount, 0);
      expect(shippingRepo.estimateCallCount, 0);
    });

    testWidgets('Guest does not call protected endpoints and sees login prompt', (
      tester,
    ) async {
      final listing = _sampleListing(id: 61, ownerId: 10);
      final materialRepo = _FakeMaterialRepository(detailListing: listing);
      final marketVm = MarketplaceViewModel(materialRepository: materialRepo);
      final authVm = AuthViewModel(
        authRepository: _FakeAuthRepository(user: null),
      );
      await authVm.checkAuthSession();

      final addrRepo = _FakeAddressRepository();
      final addressVm = AddressViewModel(addressRepository: addrRepo);
      final shippingRepo = _FakeShippingRepository();

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: MaterialDetailScreen(
            materialId: listing.id,
            initialMaterial: listing,
            viewModel: marketVm,
            authViewModel: authVm,
            addressViewModel: addressVm,
            shippingRepository: shippingRepo,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.text('Masuk untuk Cek Ongkir'),
        250,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Estimasi Ongkos Kirim'), findsOneWidget);
      expect(find.text('Masuk untuk Cek Ongkir'), findsOneWidget);
      expect(addrRepo.getCount, 0);
      expect(shippingRepo.estimateCallCount, 0);
    });

    testWidgets('Missing origin prevents estimation and shows clear message', (
      tester,
    ) async {
      final listing = _sampleListing(
        id: 62,
        ownerId: 10,
        originDestinationId: null,
        originLabel: null,
      );
      final materialRepo = _FakeMaterialRepository(detailListing: listing);
      final marketVm = MarketplaceViewModel(materialRepository: materialRepo);
      final authVm = AuthViewModel(
        authRepository: _FakeAuthRepository(
          user: UserProfile(id: 20, name: 'Pembeli', email: 'buyer@test.id'),
        ),
      );
      await authVm.checkAuthSession();

      final addrRepo = _FakeAddressRepository(initialItems: [_sampleAddress()]);
      final addressVm = AddressViewModel(addressRepository: addrRepo);
      final shippingRepo = _FakeShippingRepository();

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: MaterialDetailScreen(
            materialId: listing.id,
            initialMaterial: listing,
            viewModel: marketVm,
            authViewModel: authVm,
            addressViewModel: addressVm,
            shippingRepository: shippingRepo,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.text('Penjual belum mengatur lokasi asal pengiriman.'),
        250,
        scrollable: find.byType(Scrollable).first,
      );
      expect(
        find.text('Penjual belum mengatur lokasi asal pengiriman.'),
        findsOneWidget,
      );
      expect(find.text('Cek Ongkir'), findsNothing);
      expect(shippingRepo.estimateCallCount, 0);
    });

    testWidgets('Buyer with no saved address sees Tambah Alamat Tujuan CTA', (
      tester,
    ) async {
      final listing = _sampleListing(id: 63, ownerId: 10);
      final materialRepo = _FakeMaterialRepository(detailListing: listing);
      final marketVm = MarketplaceViewModel(materialRepository: materialRepo);
      final authVm = AuthViewModel(
        authRepository: _FakeAuthRepository(
          user: UserProfile(id: 20, name: 'Pembeli', email: 'buyer@test.id'),
        ),
      );
      await authVm.checkAuthSession();

      final addrRepo = _FakeAddressRepository(initialItems: const []);
      final addressVm = AddressViewModel(addressRepository: addrRepo);
      final shippingRepo = _FakeShippingRepository();

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: MaterialDetailScreen(
            materialId: listing.id,
            initialMaterial: listing,
            viewModel: marketVm,
            authViewModel: authVm,
            addressViewModel: addressVm,
            shippingRepository: shippingRepo,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.text('Tambah Alamat Tujuan'),
        250,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Tambah Alamat Tujuan'), findsOneWidget);
      expect(shippingRepo.estimateCallCount, 0);
    });

    testWidgets(
      'Selects default address without auto-estimate, Cek Ongkir prevents duplicate requests, renders options + null ETD, and clears on address change',
      (tester) async {
        final listing = _sampleListing(id: 64, ownerId: 10);
        final materialRepo = _FakeMaterialRepository(detailListing: listing);
        final marketVm = MarketplaceViewModel(materialRepository: materialRepo);
        final authVm = AuthViewModel(
          authRepository: _FakeAuthRepository(
            user: UserProfile(id: 20, name: 'Pembeli', email: 'buyer@test.id'),
          ),
        );
        await authVm.checkAuthSession();

        final nonDefaultAddr = _sampleAddress(
          id: 1,
          label: 'Kantor',
          isDefault: false,
        );
        final defaultAddr = _sampleAddress(
          id: 2,
          label: 'Rumah Utama',
          isDefault: true,
        );
        final addrRepo = _FakeAddressRepository(
          initialItems: [nonDefaultAddr, defaultAddr],
        );
        final addressVm = AddressViewModel(addressRepository: addrRepo);

        final estimateCompleter = Completer<ShippingEstimateResult>();
        final shippingRepo = _FakeShippingRepository()
          ..onEstimate = (_, _) => estimateCompleter.future;

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.lightTheme,
            home: MaterialDetailScreen(
              materialId: listing.id,
              initialMaterial: listing,
              viewModel: marketVm,
              authViewModel: authVm,
              addressViewModel: addressVm,
              shippingRepository: shippingRepo,
            ),
          ),
        );
        await tester.pumpAndSettle();

        await _scrollTo(tester, find.text('Cek Ongkir'));

        // Backend default address selected, ZERO automatic estimate calls
        expect(find.text('Tujuan: Rumah Utama'), findsOneWidget);
        expect(shippingRepo.estimateCallCount, 0);

        // Tap Cek Ongkir twice while in-flight -> exactly 1 request
        await tester.tap(find.text('Cek Ongkir'));
        await tester.pump();
        expect(find.text('Menghitung Ongkir...'), findsOneWidget);
        await tester.tap(find.text('Menghitung Ongkir...'));
        await tester.pump();
        expect(shippingRepo.estimateCallCount, 1);
        expect(shippingRepo.lastEstimateListingId, 64);
        expect(shippingRepo.lastEstimateAddressId, 2);

        // Complete request with JNE (with ETD) & J&T (null ETD)
        estimateCompleter.complete(
          ShippingEstimateResult(
            listing: const ShippingEstimateListingSummary(
              id: 64,
              name: 'Botol PET Bening',
              weightKg: 3.0,
              weightGrams: 3000,
              originDestinationId: 4949,
              originLabel: 'BRAGA, SUMUR BANDUNG, BANDUNG',
            ),
            destination: const ShippingEstimateDestinationSummary(
              addressId: 2,
              label: 'Rumah Utama',
              destinationId: 6157,
              destinationLabel: 'BABAKANKARET, CIANJUR',
            ),
            options: const [
              ShippingCostOption(
                courierCode: 'jne',
                courierName: 'JNE',
                service: 'REG',
                description: 'Layanan Reguler',
                cost: 16000,
                etd: '2-3 hari',
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
          ),
        );
        await tester.pumpAndSettle();

        await tester.scrollUntilVisible(
          find.text('Estimasi belum tersedia'),
          200,
          scrollable: find.byType(Scrollable).first,
        );
        expect(find.text('JNE'), findsOneWidget);
        expect(find.text('REG'), findsOneWidget);
        expect(find.text('Rp 16.000'), findsOneWidget);
        expect(find.text('Estimasi: 2-3 hari'), findsOneWidget);
        expect(find.text('J&T Express'), findsOneWidget);
        expect(find.text('Rp 15.000'), findsOneWidget);
        expect(find.text('Estimasi belum tersedia'), findsOneWidget);

        // Switching selected address clears previous results and does NOT auto-estimate
        addressVm.selectAddress(1);
        await tester.pumpAndSettle();

        expect(find.text('Tujuan: Kantor'), findsOneWidget);
        expect(find.text('Rp 16.000'), findsNothing);
        expect(find.text('Estimasi belum tersedia'), findsNothing);
        expect(shippingRepo.estimateCallCount, 1);
      },
    );

    testWidgets('Empty shipping options displays empty state with retry', (
      tester,
    ) async {
      final listing = _sampleListing(id: 65, ownerId: 10);
      final materialRepo = _FakeMaterialRepository(detailListing: listing);
      final marketVm = MarketplaceViewModel(materialRepository: materialRepo);
      final authVm = AuthViewModel(
        authRepository: _FakeAuthRepository(
          user: UserProfile(id: 20, name: 'Pembeli', email: 'buyer@test.id'),
        ),
      );
      await authVm.checkAuthSession();

      final addrRepo = _FakeAddressRepository(initialItems: [_sampleAddress()]);
      final addressVm = AddressViewModel(addressRepository: addrRepo);
      final shippingRepo = _FakeShippingRepository()
        ..onEstimate = (listingId, addressId) async => ShippingEstimateResult(
              listing: ShippingEstimateListingSummary(
                id: listingId,
                name: listing.name,
                weightKg: listing.weightKg,
                weightGrams: 3000,
                originDestinationId: 4949,
                originLabel: listing.originLabel,
              ),
              destination: ShippingEstimateDestinationSummary(
                addressId: addressId,
                label: 'Rumah',
                destinationId: 6157,
                destinationLabel: 'BABAKANKARET, CIANJUR',
              ),
              options: const [],
            );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: MaterialDetailScreen(
            materialId: listing.id,
            initialMaterial: listing,
            viewModel: marketVm,
            authViewModel: authVm,
            addressViewModel: addressVm,
            shippingRepository: shippingRepo,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await _scrollToAndTap(tester, find.text('Cek Ongkir'));
      await tester.scrollUntilVisible(
        find.text('Layanan pengiriman tidak tersedia untuk rute ini saat ini.'),
        200,
        scrollable: find.byType(Scrollable).first,
      );

      expect(
        find.text('Layanan pengiriman tidak tersedia untuk rute ini saat ini.'),
        findsOneWidget,
      );
      expect(find.text('Coba Lagi'), findsOneWidget);
    });

    testWidgets('Shipping API failure displays retry state and retries cleanly', (
      tester,
    ) async {
      final listing = _sampleListing(id: 66, ownerId: 10);
      final materialRepo = _FakeMaterialRepository(detailListing: listing);
      final marketVm = MarketplaceViewModel(materialRepository: materialRepo);
      final authVm = AuthViewModel(
        authRepository: _FakeAuthRepository(
          user: UserProfile(id: 20, name: 'Pembeli', email: 'buyer@test.id'),
        ),
      );
      await authVm.checkAuthSession();

      final addrRepo = _FakeAddressRepository(initialItems: [_sampleAddress()]);
      final addressVm = AddressViewModel(addressRepository: addrRepo);

      var attempts = 0;
      final shippingRepo = _FakeShippingRepository()
        ..onEstimate = (listingId, addressId) async {
          attempts++;
          if (attempts == 1) {
            throw ApiException('Gagal menghubungi layanan ongkir.');
          }
          return ShippingEstimateResult(
            listing: ShippingEstimateListingSummary(
              id: listingId,
              name: listing.name,
              weightKg: listing.weightKg,
              weightGrams: 3000,
              originDestinationId: 4949,
              originLabel: listing.originLabel,
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
                courierName: 'JNE',
                service: 'REG',
                cost: 18000,
                etd: '1-2 hari',
              ),
            ],
          );
        };

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: MaterialDetailScreen(
            materialId: listing.id,
            initialMaterial: listing,
            viewModel: marketVm,
            authViewModel: authVm,
            addressViewModel: addressVm,
            shippingRepository: shippingRepo,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await _scrollToAndTap(tester, find.text('Cek Ongkir'));
      await tester.scrollUntilVisible(
        find.text('Gagal menghubungi layanan ongkir.'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Gagal menghubungi layanan ongkir.'), findsOneWidget);
      expect(find.text('Coba Lagi'), findsOneWidget);

      await _scrollToAndTap(tester, find.text('Coba Lagi'));
      await tester.scrollUntilVisible(
        find.text('Rp 18.000'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Rp 18.000'), findsOneWidget);
      expect(shippingRepo.estimateCallCount, 2);
    });
  });
}
