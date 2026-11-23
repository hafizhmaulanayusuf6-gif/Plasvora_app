import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:plasvora/core/network/api_client.dart';
import 'package:plasvora/core/theme/app_theme.dart';
import 'package:plasvora/core/widgets/plasvora_header.dart';
import 'package:plasvora/core/widgets/simple_page_app_bar.dart';
import 'package:plasvora/models/material_listing.dart';
import 'package:plasvora/models/order_item.dart';
import 'package:plasvora/models/shipping_destination.dart';
import 'package:plasvora/models/user_address.dart';
import 'package:plasvora/models/user_profile.dart';
import 'package:plasvora/repositories/address_repository.dart';
import 'package:plasvora/repositories/auth_repository.dart';
import 'package:plasvora/repositories/material_repository.dart';
import 'package:plasvora/repositories/order_repository.dart';
import 'package:plasvora/repositories/shipping_repository.dart';
import 'package:plasvora/viewmodels/address_viewmodel.dart';
import 'package:plasvora/viewmodels/auth_viewmodel.dart';
import 'package:plasvora/viewmodels/marketplace_viewmodel.dart';
import 'package:plasvora/viewmodels/order_viewmodel.dart';
import 'package:plasvora/views/checkout/checkout_screen.dart';
import 'package:plasvora/views/marketplace/material_detail_screen.dart';

class _StubAuthRepo implements AuthRepository {
  final UserProfile? user;
  _StubAuthRepo(this.user);

  @override
  Future<UserProfile?> getCurrentUser() async => user;
  @override
  Future<bool> isAuthenticated() async => user != null;
  @override
  Future<UserProfile> login({
    required String email,
    required String password,
  }) async =>
      user!;
  @override
  Future<void> logout() async {}
  @override
  Future<UserProfile> register({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
    String? phone,
  }) async =>
      user!;
  @override
  Future<UserProfile> updateProfile({
    String? name,
    String? phone,
    bool? whatsappPublic,
  }) async =>
      user!;
}

class _SingleListingMaterialRepo extends MockMaterialRepository {
  MaterialListing currentListing;

  _SingleListingMaterialRepo(this.currentListing) : super(simulateDelay: false);

  @override
  Future<MaterialListing> getMaterialDetail(int id) async => currentListing;

  @override
  Future<List<MaterialListing>> getMaterials({
    String? category,
    String? query,
    String? condition,
    double? minWeight,
    double? maxWeight,
    String? location,
  }) async =>
      [currentListing];
}

class _StubAddressRepo implements AddressRepository {
  List<UserAddress> items;
  bool failNextGet = false;
  _StubAddressRepo(this.items);

  @override
  Future<List<UserAddress>> getAddresses() async {
    if (failNextGet) {
      failNextGet = false;
      throw ApiException('Gagal mengambil alamat dari server.');
    }
    return items;
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
  }) async =>
      items.first;

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
  }) async =>
      items.first;

  @override
  Future<void> deleteAddress(int id) async {}
}

class _StubShippingRepo implements ShippingRepository {
  int estimateCalls = 0;
  bool returnEmptyOptions = false;
  List<ShippingCostOption>? customOptions;

  @override
  Future<List<ShippingDestination>> searchDestinations({
    required String query,
    int limit = 10,
    int offset = 0,
  }) async =>
      const [];

  @override
  Future<ShippingEstimateResult> estimateShipping({
    required int listingId,
    required int addressId,
  }) async {
    estimateCalls++;
    final cost = addressId == 1 ? 18000 : 25000;
    return ShippingEstimateResult(
      listing: ShippingEstimateListingSummary(
        id: listingId,
        name: 'PET Bening 10kg',
        weightKg: 10.0,
        weightGrams: 10000,
        originDestinationId: 4949,
        originLabel: 'BRAGA, BANDUNG',
      ),
      destination: ShippingEstimateDestinationSummary(
        addressId: addressId,
        label: addressId == 1 ? 'Rumah' : 'Gudang',
        destinationId: addressId == 1 ? 6157 : 7000,
        destinationLabel: addressId == 1 ? 'CIANJUR' : 'DEPOK',
      ),
      options: returnEmptyOptions
          ? const []
          : (customOptions ??
                [
                  ShippingCostOption(
                    courierCode: 'jne',
                    courierName: 'Jalur Nugraha Ekakurir (JNE)',
                    service: 'REG',
                    cost: cost,
                    etd: '2-3 day',
                  ),
                  ShippingCostOption(
                    courierCode: 'jnt',
                    courierName: 'J&T Express',
                    service: 'EZ',
                    cost: cost - 2000,
                    etd: '2-3 day',
                  ),
                ]),
    );
  }
}

class _RecordingOrderRepo implements OrderRepository {
  final List<String> submittedIdempotencyKeys = [];
  String? lastCourierCode;
  String? lastCourierService;
  int createCount = 0;
  bool failOnceWithTimeout = false;
  Completer<OrderItem>? holdCreate;

  OrderItem buildCreatedOrder({
    int listingId = 10,
    String courierCode = 'jne',
    String courierService = 'REG',
  }) {
    return OrderItem(
      id: 99,
      orderNumber: 'PLV-CHK-99',
      role: 'buyer',
      buyerId: 2,
      buyerName: 'Pembeli',
      sellerId: 1,
      sellerName: 'Penjual',
      listingId: listingId,
      status: OrderItem.statusPendingPayment,
      paymentStatus: OrderItem.paymentUnpaid,
      listing: OrderListingSnapshot(
        id: listingId,
        name: 'PET Bening 10kg',
        category: 'PET',
        weightKg: 10.0,
      ),
      itemPrice: 50000,
      shippingCost: 25000,
      platformFee: 0,
      totalAmount: 75000,
      courierCode: courierCode,
      courierName: 'JNE',
      courierService: courierService,
      midtransRedirectUrl:
          'https://app.sandbox.midtrans.com/snap/v4/redirection/tok-99',
    );
  }

  @override
  Future<OrderItem> createOrder({
    required int listingId,
    required int addressId,
    required String courierCode,
    required String courierService,
    String? buyerNote,
    required String idempotencyKey,
  }) async {
    createCount++;
    lastCourierCode = courierCode;
    lastCourierService = courierService;
    submittedIdempotencyKeys.add(idempotencyKey);

    if (holdCreate != null) {
      return holdCreate!.future;
    }

    if (failOnceWithTimeout) {
      failOnceWithTimeout = false;
      throw ApiException(
        'Sesi pembayaran timeout.',
        statusCode: 504,
        data: {'order_id': 99, 'reconciliation_required': true},
      );
    }

    return buildCreatedOrder(
      listingId: listingId,
      courierCode: courierCode,
      courierService: courierService,
    );
  }

  @override
  Future<OrderItem> getOrderDetail(int orderId) async => OrderItem(
        id: orderId,
        orderNumber: 'PLV-CHK-$orderId',
        role: 'buyer',
        buyerId: 2,
        sellerId: 1,
        listingId: 10,
        status: OrderItem.statusPendingPayment,
        paymentStatus: OrderItem.paymentUnpaid,
        listing: const OrderListingSnapshot(
          id: 10,
          name: 'PET Bening 10kg',
          category: 'PET',
          weightKg: 10.0,
        ),
        itemPrice: 50000,
        shippingCost: 18000,
        platformFee: 0,
        totalAmount: 68000,
        courierCode: 'jne',
        courierName: 'JNE',
        courierService: 'REG',
      );

  @override
  Future<OrderListPage> getOrders({
    required String role,
    String? status,
    int page = 1,
    int perPage = 15,
  }) async =>
      const OrderListPage(
        items: [],
        currentPage: 1,
        lastPage: 1,
        perPage: 15,
        total: 0,
      );

  @override
  Future<OrderItem> cancelOrder(int orderId, {String? reason}) =>
      getOrderDetail(orderId);
  @override
  Future<OrderItem> retryPayment(int orderId) => getOrderDetail(orderId);
  @override
  Future<OrderRefreshResult> refreshPaymentStatus(int orderId) async =>
      OrderRefreshResult(
        order: await getOrderDetail(orderId),
        providerSynced: true,
        message: 'OK',
      );
  @override
  Future<OrderItem> shipOrder({
    required int orderId,
    required String trackingNumber,
    String? shipmentNotes,
  }) =>
      getOrderDetail(orderId);
  @override
  Future<OrderItem> confirmDelivery(int orderId) => getOrderDetail(orderId);
}

MaterialListing _sampleListing({
  int id = 10,
  int ownerId = 1,
  bool isFree = false,
  int price = 50000,
  String status = 'available',
}) {
  return MaterialListing(
    id: id,
    ownerId: ownerId,
    ownerName: 'Penjual A',
    name: 'PET Bening 10kg',
    category: 'PET',
    weightKg: 10.0,
    condition: 'clean',
    price: price,
    isFree: isFree,
    generalLocation: 'Bandung',
    originDestinationId: 4949,
    originLabel: 'BRAGA, BANDUNG',
    description: 'Lot siap kirim',
    status: status,
    createdAt: DateTime(2026, 11, 22),
  );
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

  group('MaterialDetailScreen Checkout Entry Point Eligibility', () {
    testWidgets('hides Beli Sekarang for owner and free listing, prompts guest, shows for eligible buyer', (tester) async {
      final paidListing = _sampleListing(ownerId: 1, isFree: false, price: 50000);
      final freeListing = _sampleListing(ownerId: 1, isFree: true, price: 0);
      final materialRepo = _SingleListingMaterialRepo(paidListing);
      final marketVm = MarketplaceViewModel(materialRepository: materialRepo);
      final orderVm = OrderViewModel(orderRepository: _RecordingOrderRepo());
      final shippingRepo = _StubShippingRepo();
      final addressVm = AddressViewModel(addressRepository: _StubAddressRepo([]));

      // 1. Owner NEVER sees Beli Sekarang
      final ownerAuth = AuthViewModel(
        authRepository: _StubAuthRepo(
          UserProfile(id: 1, name: 'Penjual', email: 'seller@test.com'),
        ),
      );
      await ownerAuth.checkAuthSession();

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: MaterialDetailScreen(
            key: const ValueKey('owner-case'),
            materialId: 10,
            initialMaterial: paidListing,
            viewModel: marketVm,
            authViewModel: ownerAuth,
            addressViewModel: addressVm,
            shippingRepository: shippingRepo,
            orderViewModel: orderVm,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(find.text('Edit Listing'), 200);
      expect(find.text('Beli Sekarang'), findsNothing);
      expect(find.text('Edit Listing'), findsOneWidget);

      // 2. Guest sees login prompt, not Beli Sekarang
      final guestAuth = AuthViewModel(authRepository: _StubAuthRepo(null));
      await guestAuth.checkAuthSession();
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: MaterialDetailScreen(
            key: const ValueKey('guest-case'),
            materialId: 10,
            initialMaterial: paidListing,
            viewModel: marketVm,
            authViewModel: guestAuth,
            addressViewModel: addressVm,
            shippingRepository: shippingRepo,
            orderViewModel: orderVm,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Masuk untuk Membeli Material'),
        200,
      );
      expect(find.text('Beli Sekarang'), findsNothing);
      expect(find.text('Masuk untuk Membeli Material'), findsOneWidget);

      // 3. Free listing does NOT show Beli Sekarang for authenticated buyer
      materialRepo.currentListing = freeListing;
      final buyerAuth = AuthViewModel(
        authRepository: _StubAuthRepo(
          UserProfile(id: 2, name: 'Pembeli', email: 'buyer@test.com'),
        ),
      );
      await buyerAuth.checkAuthSession();
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: MaterialDetailScreen(
            key: const ValueKey('free-case'),
            materialId: 10,
            initialMaterial: freeListing,
            viewModel: marketVm,
            authViewModel: buyerAuth,
            addressViewModel: addressVm,
            shippingRepository: shippingRepo,
            orderViewModel: orderVm,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(find.text('Estimasi Ongkos Kirim'), 200);
      expect(find.text('Beli Sekarang'), findsNothing);

      // 4. Paid eligible listing shows Beli Sekarang for authenticated buyer
      materialRepo.currentListing = paidListing;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: MaterialDetailScreen(
            key: const ValueKey('paid-case'),
            materialId: 10,
            initialMaterial: paidListing,
            viewModel: marketVm,
            authViewModel: buyerAuth,
            addressViewModel: addressVm,
            shippingRepository: shippingRepo,
            orderViewModel: orderVm,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(find.text('Beli Sekarang'), 200);
      expect(find.text('Beli Sekarang'), findsOneWidget);
    });
  });

  group('CheckoutScreen Flow, Courier UX, Address Change & Idempotency Tests', () {
    testWidgets('uses SimplePageAppBar, shows Tambah Alamat when empty, and omits hardcoded Biaya Platform', (tester) async {
      final addressVm = AddressViewModel(addressRepository: _StubAddressRepo([]));
      final orderVm = OrderViewModel(orderRepository: _RecordingOrderRepo());

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: CheckoutScreen(
            listing: _sampleListing(),
            addressViewModel: addressVm,
            shippingRepository: _StubShippingRepo(),
            orderViewModel: orderVm,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(SimplePageAppBar), findsOneWidget);
      expect(find.byType(PlasvoraHeader), findsNothing);
      expect(find.text('Tambah Alamat'), findsOneWidget);
      expect(find.text('Biaya Platform'), findsNothing);

      expect(find.text('Total Pembayaran'), findsOneWidget);
      final submitButton = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'Bayar Sekarang'),
      );
      expect(submitButton.onPressed, isNull);
      expect(find.text('Bayar Rp 50.000'), findsNothing);
    });

    testWidgets('selects courier, recalculates on address change, reuses idempotency key on retry, and prevents double tap', (tester) async {
      const addr1 = UserAddress(
        id: 1,
        label: 'Rumah',
        recipientName: 'Budi',
        recipientPhone: '6281234567890',
        destinationId: 6157,
        destinationLabel: 'BOJONGHERANG, CIANJUR, CIANJUR, JAWA BARAT',
        addressDetail: 'Jl. Cianjur 1',
        isDefault: true,
      );
      const addr2 = UserAddress(
        id: 2,
        label: 'Gudang',
        recipientName: 'Budi',
        recipientPhone: '6281234567890',
        destinationId: 7000,
        destinationLabel: 'DEPOK',
        addressDetail: 'Jl. Depok 2',
        isDefault: false,
      );

      final addressVm = AddressViewModel(
        addressRepository: _StubAddressRepo([addr1, addr2]),
      );
      final shippingRepo = _StubShippingRepo();
      final orderRepo = _RecordingOrderRepo()..failOnceWithTimeout = true;
      final orderVm = OrderViewModel(orderRepository: orderRepo);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: CheckoutScreen(
            listing: _sampleListing(),
            addressViewModel: addressVm,
            shippingRepository: shippingRepo,
            orderViewModel: orderVm,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Dedup lokasi berurutan & format nomor +62
      expect(
        find.text('BOJONGHERANG, CIANJUR, JAWA BARAT'),
        findsOneWidget,
      );
      expect(find.text('+6281234567890'), findsOneWidget);

      final checkoutScrollable = find
          .descendant(
            of: find.byType(ListView),
            matching: find.byType(Scrollable),
          )
          .first;

      // Pilih JNE REG (Rp 18.000) -> Total = Rp 68.000 & ETD berbahasa Indonesia
      final jneOption = find.text('JNE REG');
      await tester.scrollUntilVisible(
        jneOption,
        200,
        scrollable: checkoutScrollable,
      );
      await tester.ensureVisible(jneOption);
      await tester.pumpAndSettle();
      expect(find.text('Estimasi 2-3 hari'), findsWidgets);

      await tester.tap(jneOption);
      await tester.pumpAndSettle();
      expect(find.text('Rp 68.000'), findsWidgets);
      expect(find.text('Bayar Sekarang'), findsOneWidget);

      // Ganti alamat ke addr2 -> pilihan kurir lama dibersihkan & ongkir baru dihitung
      addressVm.selectAddress(2);
      await tester.pumpAndSettle();
      expect(shippingRepo.estimateCalls, 2);
      await tester.scrollUntilVisible(
        jneOption,
        200,
        scrollable: checkoutScrollable,
      );
      await tester.ensureVisible(jneOption);
      await tester.pumpAndSettle();
      expect(find.text('Rp 25.000'), findsOneWidget);
      expect(
        tester
            .widget<ElevatedButton>(
              find.widgetWithText(ElevatedButton, 'Bayar Sekarang'),
            )
            .onPressed,
        isNull,
      );

      // Pilih JNE REG lagi pada addr2 -> submit pertama gagal timeout 504
      await tester.ensureVisible(jneOption);
      await tester.pumpAndSettle();
      await tester.tap(jneOption);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Bayar Sekarang'));
      await tester.pumpAndSettle();

      // Recovery button muncul untuk reconciliationOrderId & payload asli tidak berubah
      final recoveryButton = find.text('Buka Pesanan Tersimpan');
      await tester.scrollUntilVisible(
        recoveryButton,
        200,
        scrollable: checkoutScrollable,
      );
      await tester.ensureVisible(recoveryButton);
      await tester.pumpAndSettle();
      expect(recoveryButton, findsOneWidget);
      expect(orderRepo.submittedIdempotencyKeys.length, 1);
      expect(orderRepo.lastCourierCode, 'jne');
      expect(orderRepo.lastCourierService, 'REG');

      // Retry submit dengan holdCreate aktif -> pastikan double tap diblokir & idempotency_key sama
      final holdCompleter = Completer<OrderItem>();
      orderRepo.holdCreate = holdCompleter;

      await tester.tap(find.text('Bayar Sekarang'));
      await tester.pump();

      expect(orderVm.isCreatingOrder, isTrue);
      expect(orderRepo.createCount, 2);

      // Tap kedua saat submit masih berjalan harus diabaikan (tombol disabled)
      final inFlightButton = find.byWidgetPredicate(
        (widget) => widget is ElevatedButton && widget.onPressed == null,
      );
      expect(inFlightButton, findsOneWidget);
      await tester.tap(inFlightButton);
      await tester.pump();
      expect(orderRepo.createCount, 2);

      holdCompleter.complete(orderRepo.buildCreatedOrder());
      await tester.pumpAndSettle();

      expect(orderRepo.submittedIdempotencyKeys.length, 2);
      expect(
        orderRepo.submittedIdempotencyKeys[0],
        orderRepo.submittedIdempotencyKeys[1],
      );
      expect(find.text('Detail Pesanan'), findsOneWidget);
    });

    testWidgets('shows top 3 couriers initially, expands Lihat Opsi Lain, and keeps selected 4th option visible on collapse', (tester) async {
      const addr = UserAddress(
        id: 1,
        label: 'Rumah',
        recipientName: 'Budi',
        recipientPhone: '6281234567890',
        destinationId: 6157,
        destinationLabel: 'CIANJUR',
        addressDetail: 'Jl. Cianjur 1',
        isDefault: true,
      );

      final shippingRepo = _StubShippingRepo()
        ..customOptions = const [
          ShippingCostOption(
            courierCode: 'pos',
            courierName: 'POS Indonesia',
            service: 'Pos Reguler',
            cost: 12000,
            etd: '4 day',
          ),
          ShippingCostOption(
            courierCode: 'jne',
            courierName: 'JNE',
            service: 'YES',
            cost: 30000,
            etd: '1 day',
          ),
          ShippingCostOption(
            courierCode: 'jnt',
            courierName: 'J&T Express',
            service: 'EZ',
            cost: 16000,
            etd: '3 day',
          ),
          ShippingCostOption(
            courierCode: 'tiki',
            courierName: 'TIKI',
            service: 'ONS',
            cost: 35000,
            etd: '2 day',
          ),
        ];

      final addressVm = AddressViewModel(
        addressRepository: _StubAddressRepo([addr]),
      );
      final orderVm = OrderViewModel(orderRepository: _RecordingOrderRepo());

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: CheckoutScreen(
            listing: _sampleListing(),
            addressViewModel: addressVm,
            shippingRepository: shippingRepo,
            orderViewModel: orderVm,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Top 3 tampil: Pos Reguler (Termurah), JNE YES (Estimasi Lebih Cepat), J&T Express (EZ)
      expect(find.text('Pos Indonesia (Pos Reguler)'), findsOneWidget);
      expect(find.text('Termurah'), findsOneWidget);
      expect(find.text('JNE YES'), findsOneWidget);
      expect(find.text('Estimasi Lebih Cepat'), findsOneWidget);
      expect(find.text('TIKI ONS'), findsNothing);
      expect(find.text('Lihat Opsi Lain (1)'), findsOneWidget);

      // Expand opsi lain -> TIKI ONS muncul
      await tester.ensureVisible(find.text('Lihat Opsi Lain (1)'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Lihat Opsi Lain (1)'));
      await tester.pumpAndSettle();
      expect(find.text('TIKI ONS'), findsOneWidget);

      // Pilih TIKI ONS lalu collapse -> opsi terpilih tetap terlihat
      await tester.ensureVisible(find.text('TIKI ONS'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('TIKI ONS'));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Tampilkan Lebih Sedikit'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Tampilkan Lebih Sedikit'));
      await tester.pumpAndSettle();

      expect(find.text('TIKI ONS'), findsOneWidget);
      expect(find.text('Rp 85.000'), findsWidgets);
      expect(find.text('Bayar Sekarang'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders full checkout body under AppTheme.lightTheme on 360dp phone with 1.3x text scale including error and empty courier states', (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      const addr = UserAddress(
        id: 1,
        label: 'Rumah',
        recipientName: 'Budi',
        recipientPhone: '6281234567890',
        destinationId: 6157,
        destinationLabel: 'CIANJUR',
        addressDetail: 'Jl. Cianjur 1',
        isDefault: true,
      );

      final addressRepo = _StubAddressRepo([addr])..failNextGet = true;
      final addressVm = AddressViewModel(addressRepository: addressRepo);
      final shippingRepo = _StubShippingRepo()..returnEmptyOptions = true;
      final orderVm = OrderViewModel(orderRepository: _RecordingOrderRepo());

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: const TextScaler.linear(1.3),
            ),
            child: child!,
          ),
          home: CheckoutScreen(
            listing: _sampleListing(),
            addressViewModel: addressVm,
            shippingRepository: shippingRepo,
            orderViewModel: orderVm,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tidak ada error layout AppTheme atau overflow teks besar
      expect(tester.takeException(), isNull);
      expect(find.text('Ringkasan Material'), findsOneWidget);
      expect(find.text('PET Bening 10kg'), findsOneWidget);
      expect(find.text('Gagal mengambil alamat dari server.'), findsOneWidget);
      expect(find.text('Total Pembayaran'), findsOneWidget);
      expect(find.text('Bayar Sekarang'), findsOneWidget);

      // Coba Lagi -> alamat termuat -> opsi kurir kosong menampilkan pesan & aksi pemulihan
      await tester.ensureVisible(find.text('Coba Lagi'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Coba Lagi'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Rumah · Budi'), findsOneWidget);
      expect(
        find.text('Layanan pengiriman belum tersedia untuk rute ini.'),
        findsOneWidget,
      );
      expect(find.text('Coba Hitung Lagi'), findsOneWidget);
    });
  });
}
