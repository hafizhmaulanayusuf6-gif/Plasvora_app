import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:plasvora/core/theme/app_theme.dart';
import 'package:plasvora/core/utils/payment_launcher.dart';
import 'package:plasvora/core/widgets/plasvora_header.dart';
import 'package:plasvora/core/widgets/simple_page_app_bar.dart';
import 'package:plasvora/models/order_item.dart';
import 'package:plasvora/models/user_profile.dart';
import 'package:plasvora/repositories/auth_repository.dart';
import 'package:plasvora/repositories/order_repository.dart';
import 'package:plasvora/viewmodels/auth_viewmodel.dart';
import 'package:plasvora/viewmodels/order_viewmodel.dart';
import 'package:plasvora/views/orders/order_detail_screen.dart';

class _FakePaymentLauncher implements PaymentLauncher {
  final List<String?> launchedUrls = [];
  bool succeed = true;

  @override
  Future<PaymentLaunchResult> launchPaymentUrl(String? url) async {
    launchedUrls.add(url);
    final valid = PaymentLauncher.validateTrustedMidtransUrl(url);
    if (valid == null) {
      return const PaymentLaunchResult.failure(
        'Tautan pembayaran tidak valid atau bukan dari domain resmi Midtrans.',
      );
    }
    if (!succeed) {
      return const PaymentLaunchResult.failure('Browser tidak tersedia.');
    }
    return const PaymentLaunchResult.success();
  }
}

class _StubAuthRepo implements AuthRepository {
  final UserProfile user;
  _StubAuthRepo(this.user);

  @override
  Future<UserProfile?> getCurrentUser() async => user;
  @override
  Future<bool> isAuthenticated() async => true;
  @override
  Future<UserProfile> login({
    required String email,
    required String password,
  }) async =>
      user;
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
      user;
  @override
  Future<UserProfile> updateProfile({
    String? name,
    String? phone,
    bool? whatsappPublic,
  }) async =>
      user;
}

class _DetailOrderRepo implements OrderRepository {
  OrderItem current;
  OrderItem? refreshResultOrder;
  int refreshCalls = 0;
  int shipCalls = 0;
  int confirmCalls = 0;
  String? lastTracking;

  _DetailOrderRepo(this.current);

  @override
  Future<OrderItem> getOrderDetail(int orderId) async => current;

  @override
  Future<OrderRefreshResult> refreshPaymentStatus(int orderId) async {
    refreshCalls++;
    if (refreshResultOrder != null) {
      current = refreshResultOrder!;
    }
    return OrderRefreshResult(
      order: current,
      providerSynced: true,
      message: 'Status pembayaran berhasil diperbarui.',
    );
  }

  @override
  Future<OrderItem> shipOrder({
    required int orderId,
    required String trackingNumber,
    String? shipmentNotes,
  }) async {
    shipCalls++;
    lastTracking = trackingNumber;
    current = OrderItem(
      id: current.id,
      orderNumber: current.orderNumber,
      role: 'seller',
      buyerId: current.buyerId,
      buyerName: current.buyerName,
      sellerId: current.sellerId,
      sellerName: current.sellerName,
      listingId: current.listingId,
      status: OrderItem.statusShipped,
      paymentStatus: OrderItem.paymentPaid,
      listing: current.listing,
      shippingAddress: current.shippingAddress,
      itemPrice: current.itemPrice,
      shippingCost: current.shippingCost,
      platformFee: current.platformFee,
      totalAmount: current.totalAmount,
      courierCode: current.courierCode,
      courierName: current.courierName,
      courierService: current.courierService,
      trackingNumber: trackingNumber,
      shipmentNotes: shipmentNotes,
      paidAt: current.paidAt,
      shippedAt: DateTime(2026, 11, 22, 16),
    );
    return current;
  }

  @override
  Future<OrderItem> confirmDelivery(int orderId) async {
    confirmCalls++;
    current = OrderItem(
      id: current.id,
      orderNumber: current.orderNumber,
      role: 'buyer',
      buyerId: current.buyerId,
      buyerName: current.buyerName,
      sellerId: current.sellerId,
      sellerName: current.sellerName,
      listingId: current.listingId,
      status: OrderItem.statusCompleted,
      paymentStatus: OrderItem.paymentPaid,
      listing: current.listing,
      shippingAddress: current.shippingAddress,
      itemPrice: current.itemPrice,
      shippingCost: current.shippingCost,
      platformFee: current.platformFee,
      totalAmount: current.totalAmount,
      courierCode: current.courierCode,
      courierName: current.courierName,
      courierService: current.courierService,
      trackingNumber: current.trackingNumber,
      paidAt: current.paidAt,
      shippedAt: current.shippedAt,
      completedAt: DateTime(2026, 11, 22, 18),
    );
    return current;
  }

  @override
  Future<OrderListPage> getOrders({
    required String role,
    String? status,
    int page = 1,
    int perPage = 15,
  }) async =>
      OrderListPage(
        items: [current],
        currentPage: 1,
        lastPage: 1,
        perPage: 15,
        total: 1,
      );

  @override
  Future<OrderItem> createOrder({
    required int listingId,
    required int addressId,
    required String courierCode,
    required String courierService,
    String? buyerNote,
    required String idempotencyKey,
  }) =>
      throw UnimplementedError();
  @override
  Future<OrderItem> cancelOrder(int orderId, {String? reason}) async => current;
  @override
  Future<OrderItem> retryPayment(int orderId) async => current;
}

OrderItem _makeOrder({
  required String status,
  required String paymentStatus,
  required String role,
  bool includeFullPii = true,
  String? redirectUrl =
      'https://app.sandbox.midtrans.com/snap/v4/redirection/tok-1',
  String? trackingNumber,
  int platformFee = 0,
  List<OrderStatusHistoryItem> histories = const [],
}) {
  return OrderItem(
    id: 50,
    orderNumber: 'PLV-20261122-ORDER-DET-50-LONG',
    role: role,
    buyerId: 2,
    buyerName: 'Budi Pembeli',
    sellerId: 1,
    sellerName: 'Siti Penjual',
    listingId: 99,
    status: status,
    paymentStatus: paymentStatus,
    listing: const OrderListingSnapshot(
      id: 99,
      name: 'Lot PET Bening 10kg',
      category: 'PET',
      weightKg: 10.0,
      originLabel: 'BRAGA, BANDUNG, BANDUNG, JAWA BARAT',
    ),
    shippingAddress: includeFullPii
        ? const OrderAddressSnapshot(
            recipientName: 'Budi Pembeli',
            recipientPhone: '6281234567890',
            destinationId: 6157,
            destinationLabel: 'BABAKANKARET, CIANJUR, CIANJUR',
            addressDetail: 'Jl. Cianjur No. 12',
            postalCode: '43211',
          )
        : const OrderAddressSnapshot(
            destinationId: 6157,
            destinationLabel: 'BABAKANKARET, CIANJUR, CIANJUR',
          ),
    itemPrice: 50000,
    shippingCost: 18000,
    platformFee: platformFee,
    totalAmount: 68000 + platformFee,
    courierCode: 'jne',
    courierName: 'JNE',
    courierService: 'REG',
    estimatedEtd: '2-3 day',
    trackingNumber: trackingNumber,
    midtransRedirectUrl: redirectUrl,
    statusHistories: histories,
    paidAt: paymentStatus == OrderItem.paymentPaid
        ? DateTime(2026, 11, 22, 15)
        : null,
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

  group('OrderDetailScreen Hierarchy, Payment Launch, Resume Sync & Role Guards', () {
    testWidgets('uses SimplePageAppBar, copies full order number, hides zero platformFee, collapses history by default, and syncs payment on resume', (tester) async {
      String? copiedClipboardText;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, (call) async {
        if (call.method == 'Clipboard.setData') {
          copiedClipboardText = (call.arguments as Map)['text'] as String?;
        }
        return null;
      });
      addTearDown(() {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(SystemChannels.platform, null);
      });

      final pendingOrder = _makeOrder(
        status: OrderItem.statusPendingPayment,
        paymentStatus: OrderItem.paymentUnpaid,
        role: 'buyer',
        platformFee: 0,
        histories: [
          OrderStatusHistoryItem(
            id: 1,
            toStatus: OrderItem.statusPendingPayment,
            actorType: 'buyer',
            source: 'checkout',
            reason: 'Pesanan dibuat oleh pembeli',
            createdAt: DateTime(2026, 11, 22, 14),
          ),
        ],
      );
      final paidOrder = _makeOrder(
        status: OrderItem.statusPaid,
        paymentStatus: OrderItem.paymentPaid,
        role: 'buyer',
        platformFee: 2500,
      );

      final repo = _DetailOrderRepo(pendingOrder)
        ..refreshResultOrder = paidOrder;
      final vm = OrderViewModel(orderRepository: repo);
      final authVm = AuthViewModel(
        authRepository: _StubAuthRepo(
          UserProfile(id: 2, name: 'Budi', email: 'budi@test.com'),
        ),
      );
      await authVm.checkAuthSession();
      final launcher = _FakePaymentLauncher();

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: OrderDetailScreen(
            orderId: 50,
            initialOrder: pendingOrder,
            orderViewModel: vm,
            authViewModel: authVm,
            paymentLauncher: launcher,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // SimplePageAppBar digunakan, tanpa PlasvoraHeader
      expect(find.byType(SimplePageAppBar), findsOneWidget);
      expect(find.byType(PlasvoraHeader), findsNothing);
      expect(find.text('Ringkasan Material'), findsOneWidget);

      // Copy full order number
      await tester.tap(find.byTooltip('Salin nomor pesanan'));
      await tester.pumpAndSettle();
      expect(copiedClipboardText, 'PLV-20261122-ORDER-DET-50-LONG');

      // Biaya Platform disembunyikan saat platformFee == 0
      expect(find.text('Biaya Platform'), findsNothing);

      // Riwayat Status Pesanan terlipat (collapsed) secara default
      final orderDetailScrollable = find
          .descendant(
            of: find.byType(ListView),
            matching: find.byType(Scrollable),
          )
          .first;
      final historyHeader = find.text('Riwayat Status Pesanan');
      await tester.scrollUntilVisible(
        historyHeader,
        250,
        scrollable: orderDetailScrollable,
      );
      await tester.ensureVisible(historyHeader);
      await tester.pumpAndSettle();
      expect(find.text('Pesanan dibuat oleh pembeli'), findsNothing);

      // Expand Riwayat Status Pesanan
      await tester.tap(historyHeader);
      await tester.pumpAndSettle();
      expect(find.text('Pesanan dibuat oleh pembeli'), findsOneWidget);

      // Gulir kembali ke tombol Bayar Sekarang (Next Step di bagian atas) lalu tap
      final payBtn = find.text('Bayar Sekarang');
      await tester.scrollUntilVisible(
        payBtn,
        -250,
        scrollable: orderDetailScrollable,
      );
      await tester.ensureVisible(payBtn);
      await tester.pumpAndSettle();
      await tester.tap(payBtn);
      await tester.pumpAndSettle();

      expect(launcher.launchedUrls, [
        'https://app.sandbox.midtrans.com/snap/v4/redirection/tok-1',
      ]);
      expect(vm.pendingPaymentOrderId, 50);
      expect(vm.currentOrder?.status, OrderItem.statusPendingPayment);

      // Simulasikan app kembali ke foreground -> panggil refresh-payment server
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();

      expect(repo.refreshCalls, 1);
      expect(vm.currentOrder?.status, OrderItem.statusPaid);
      expect(find.text('Menunggu Penjual Mengirim'), findsOneWidget);

      // Saat platformFee > 0, baris Biaya Platform tampil
      await tester.scrollUntilVisible(
        find.text('Biaya Platform'),
        250,
        scrollable: orderDetailScrollable,
      );
      expect(find.text('Biaya Platform'), findsOneWidget);
    });

    testWidgets('rejects arbitrary untrusted payment URL safely', (tester) async {
      final badOrder = _makeOrder(
        status: OrderItem.statusPendingPayment,
        paymentStatus: OrderItem.paymentUnpaid,
        role: 'buyer',
        redirectUrl: 'https://untrusted.example.com/pay?status=paid',
      );
      final repo = _DetailOrderRepo(badOrder);
      final vm = OrderViewModel(orderRepository: repo);
      final authVm = AuthViewModel(
        authRepository: _StubAuthRepo(
          UserProfile(id: 2, name: 'Budi', email: 'budi@test.com'),
        ),
      );
      await authVm.checkAuthSession();
      final launcher = _FakePaymentLauncher();

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: OrderDetailScreen(
            orderId: 50,
            initialOrder: badOrder,
            orderViewModel: vm,
            authViewModel: authVm,
            paymentLauncher: launcher,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final payBtn = find.text('Bayar Sekarang');
      await tester.ensureVisible(payBtn);
      await tester.pumpAndSettle();
      await tester.tap(payBtn);
      await tester.pumpAndSettle();

      expect(vm.pendingPaymentOrderId, isNull);
      expect(vm.currentOrder?.status, OrderItem.statusPendingPayment);
      expect(
        find.textContaining('bukan dari domain resmi Midtrans'),
        findsOneWidget,
      );
    });

    testWidgets('enforces seller privacy before payment and validates tracking form with selected courier after payment', (tester) async {
      // 1. Seller unpaid: PII hidden, no ship form
      final sellerUnpaid = _makeOrder(
        status: OrderItem.statusPendingPayment,
        paymentStatus: OrderItem.paymentUnpaid,
        role: 'seller',
        includeFullPii: false,
        redirectUrl: null,
      );
      final repo = _DetailOrderRepo(sellerUnpaid);
      final vm = OrderViewModel(orderRepository: repo);
      final sellerAuth = AuthViewModel(
        authRepository: _StubAuthRepo(
          UserProfile(id: 1, name: 'Siti', email: 'siti@test.com'),
        ),
      );
      await sellerAuth.checkAuthSession();

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: OrderDetailScreen(
            orderId: 50,
            initialOrder: sellerUnpaid,
            orderViewModel: vm,
            authViewModel: sellerAuth,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final orderDetailScrollable = find
          .descendant(
            of: find.byType(ListView),
            matching: find.byType(Scrollable),
          )
          .first;
      await tester.scrollUntilVisible(
        find.text('BABAKANKARET, CIANJUR'),
        250,
        scrollable: orderDetailScrollable,
      );
      expect(find.text('BABAKANKARET, CIANJUR'), findsOneWidget);
      expect(find.text('+6281234567890'), findsNothing);
      expect(find.text('Jl. Cianjur No. 12'), findsNothing);
      expect(find.text('Input Resi & Kirim Pesanan'), findsNothing);

      // 2. Seller paid: full shipping address shown, tracking form near top with selected courier
      final sellerPaid = _makeOrder(
        status: OrderItem.statusPaid,
        paymentStatus: OrderItem.paymentPaid,
        role: 'seller',
        includeFullPii: true,
        redirectUrl: null,
      );
      repo.current = sellerPaid;
      await vm.loadOrderDetail(50);
      await tester.pumpAndSettle();

      // Pastikan form resi dan informasi kurir tampil di bagian atas
      final shipBtn = find.ancestor(
        of: find.text('Input Resi & Kirim Pesanan'),
        matching: find.byWidgetPredicate((widget) => widget is ElevatedButton),
      );
      await tester.scrollUntilVisible(
        shipBtn,
        -250,
        scrollable: orderDetailScrollable,
      );
      await tester.ensureVisible(shipBtn);
      await tester.pumpAndSettle();
      expect(find.text('Kurir dipilih: JNE - REG'), findsOneWidget);

      // Validasi kosong gagal
      await tester.tap(shipBtn);
      await tester.pumpAndSettle();
      expect(find.text('Nomor resi pengiriman wajib diisi.'), findsOneWidget);
      expect(repo.shipCalls, 0);

      // Isi resi valid -> muncul dialog konfirmasi -> konfirmasi -> shipped
      final trackingField = find.widgetWithText(TextFormField, 'Nomor Resi *');
      await tester.ensureVisible(trackingField);
      await tester.pumpAndSettle();
      await tester.enterText(trackingField, '  JNE88776655  ');
      await tester.pumpAndSettle();

      await tester.ensureVisible(shipBtn);
      await tester.pumpAndSettle();
      await tester.tap(shipBtn);
      await tester.pumpAndSettle();
      expect(find.text('Konfirmasi Pengiriman Pesanan?'), findsOneWidget);

      await tester.tap(find.text('Kirim Pesanan'));
      await tester.pumpAndSettle();

      expect(repo.shipCalls, 1);
      expect(repo.lastTracking, 'JNE88776655');
      expect(vm.currentOrder?.status, OrderItem.statusShipped);

      // Alamat lengkap & telepon terformat +62 tampil untuk penjual setelah paid
      await tester.scrollUntilVisible(
        find.text('+6281234567890'),
        250,
        scrollable: orderDetailScrollable,
      );
      expect(find.text('+6281234567890'), findsOneWidget);
      expect(find.text('Jl. Cianjur No. 12'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('buyer delivery confirmation requires dialog confirmation', (tester) async {
      final buyerShipped = _makeOrder(
        status: OrderItem.statusShipped,
        paymentStatus: OrderItem.paymentPaid,
        role: 'buyer',
        trackingNumber: 'JNE88776655',
      );
      final repo = _DetailOrderRepo(buyerShipped);
      final vm = OrderViewModel(orderRepository: repo);
      final buyerAuth = AuthViewModel(
        authRepository: _StubAuthRepo(
          UserProfile(id: 2, name: 'Budi', email: 'budi@test.com'),
        ),
      );
      await buyerAuth.checkAuthSession();

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: OrderDetailScreen(
            orderId: 50,
            initialOrder: buyerShipped,
            orderViewModel: vm,
            authViewModel: buyerAuth,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final confirmBtn = find.text('Konfirmasi Pesanan Diterima');
      await tester.ensureVisible(confirmBtn);
      await tester.pumpAndSettle();
      await tester.tap(confirmBtn);
      await tester.pumpAndSettle();

      expect(find.text('Konfirmasi Pesanan Diterima?'), findsOneWidget);
      expect(repo.confirmCalls, 0);

      await tester.tap(find.text('Ya, Sudah Diterima'));
      await tester.pumpAndSettle();

      expect(repo.confirmCalls, 1);
      expect(vm.currentOrder?.status, OrderItem.statusCompleted);
      expect(tester.takeException(), isNull);
    });
  });
}
