import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:plasvora/core/widgets/plasvora_header.dart';
import 'package:plasvora/models/material_listing.dart';
import 'package:plasvora/models/order_item.dart';
import 'package:plasvora/models/user_profile.dart';
import 'package:plasvora/repositories/auth_repository.dart';
import 'package:plasvora/repositories/material_repository.dart';
import 'package:plasvora/repositories/order_repository.dart';
import 'package:plasvora/viewmodels/auth_viewmodel.dart';
import 'package:plasvora/viewmodels/home_viewmodel.dart';
import 'package:plasvora/viewmodels/navigation_viewmodel.dart';
import 'package:plasvora/viewmodels/order_viewmodel.dart';
import 'package:plasvora/views/home/home_screen.dart';
import 'package:plasvora/views/orders/order_list_screen.dart';

class _StubOrderRepo implements OrderRepository {
  List<OrderItem> buyerItems = [];
  List<OrderItem> sellerItems = [];
  bool failNext = false;

  @override
  Future<OrderListPage> getOrders({
    required String role,
    String? status,
    int page = 1,
    int perPage = 15,
  }) async {
    if (failNext) {
      failNext = false;
      throw Exception('Koneksi gagal');
    }
    final items = role == 'seller' ? sellerItems : buyerItems;
    final filtered = status == null
        ? items
        : items.where((o) => o.status == status).toList();
    return OrderListPage(
      items: filtered,
      currentPage: 1,
      lastPage: 1,
      perPage: 15,
      total: filtered.length,
    );
  }

  @override
  Future<OrderItem> getOrderDetail(int orderId) async =>
      [...buyerItems, ...sellerItems].firstWhere((o) => o.id == orderId);

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

class _StubMaterialRepo extends MockMaterialRepository {
  _StubMaterialRepo() : super(simulateDelay: false);

  @override
  Future<List<MaterialListing>> getMaterials({
    String? category,
    String? query,
    String? condition,
    double? minWeight,
    double? maxWeight,
    String? location,
  }) async =>
      const [];
}

OrderItem _order({
  required int id,
  required String role,
  required String status,
  required String name,
}) {
  return OrderItem(
    id: id,
    orderNumber: 'PLV-LIST-$id',
    role: role,
    buyerId: role == 'buyer' ? 1 : 2,
    buyerName: 'Budi Pembeli',
    sellerId: role == 'seller' ? 1 : 2,
    sellerName: 'Siti Penjual',
    listingId: 50 + id,
    status: status,
    paymentStatus: status == OrderItem.statusPaid
        ? OrderItem.paymentPaid
        : OrderItem.paymentUnpaid,
    listing: OrderListingSnapshot(
      id: 50 + id,
      name: name,
      category: 'PET',
      weightKg: 8.0,
    ),
    shippingAddress: const OrderAddressSnapshot(
      recipientName: 'Nama Rahasia',
      recipientPhone: '628999888777',
      addressDetail: 'Jl. Rahasia Banget No. 1',
    ),
    itemPrice: 40000,
    shippingCost: 15000,
    platformFee: 0,
    totalAmount: 55000,
    courierCode: 'jne',
    courierName: 'JNE',
    courierService: 'REG',
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

  group('OrderListScreen & Profile Navigation Tests', () {
    testWidgets('shows buyer and seller tabs, empty state, error retry, and hides buyer PII on cards', (tester) async {
      final repo = _StubOrderRepo()
        ..failNext = true
        ..buyerItems = [
          _order(
            id: 1,
            role: 'buyer',
            status: OrderItem.statusPendingPayment,
            name: 'Lot PET Pembelian',
          ),
        ]
        ..sellerItems = [
          _order(
            id: 2,
            role: 'seller',
            status: OrderItem.statusPaid,
            name: 'Lot HDPE Penjualan',
          ),
        ];

      final vm = OrderViewModel(orderRepository: repo);

      await tester.pumpWidget(
        MaterialApp(
          home: OrderListScreen(orderViewModel: vm),
        ),
      );
      await tester.pumpAndSettle();

      // Error state + retry
      expect(find.text('Coba Lagi'), findsOneWidget);
      await tester.tap(find.text('Coba Lagi'));
      await tester.pumpAndSettle();

      // Buyer tab data visible, no PII address/phone leaked on list card
      expect(find.text('Lot PET Pembelian'), findsOneWidget);
      expect(find.text('Lanjutkan Pembayaran'), findsOneWidget);
      expect(find.textContaining('628999888777'), findsNothing);
      expect(find.textContaining('Jl. Rahasia Banget'), findsNothing);

      // Switch to Seller tab
      await tester.tap(find.text('Penjualan'));
      await tester.pumpAndSettle();
      expect(find.text('Lot HDPE Penjualan'), findsOneWidget);
      expect(find.text('Pesanan Siap Dikirim'), findsOneWidget);
      expect(find.textContaining('628999888777'), findsNothing);

      // Filter by status with no matches -> empty state
      await tester.ensureVisible(find.text('Selesai'));
      await tester.tap(find.text('Selesai'));
      await tester.pumpAndSettle();
      expect(find.text('Belum Ada Pesanan Masuk'), findsOneWidget);
    });

    testWidgets('Profile Account modal navigates to OrderListScreen lifecycle-safely', (tester) async {
      final orderRepo = _StubOrderRepo();
      final orderVm = OrderViewModel(orderRepository: orderRepo);
      final authVm = AuthViewModel(
        authRepository: _StubAuthRepo(
          UserProfile(id: 1, name: 'Budi', email: 'budi@test.com'),
        ),
        onSessionCleared: orderVm.clearUserData,
      );
      await authVm.checkAuthSession();

      await tester.pumpWidget(
        MaterialApp(
          home: HomeScreen(
            viewModel: HomeViewModel(materialRepository: _StubMaterialRepo()),
            navigationViewModel: NavigationViewModel(),
            authViewModel: authVm,
            orderViewModel: orderVm,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Buka modal Profil Akun melalui tombol avatar aktual di PlasvoraHeader
      final avatarButton = find.descendant(
        of: find.byType(PlasvoraHeader),
        matching: find.byWidgetPredicate(
          (widget) => widget is GestureDetector && widget.child is ClipRRect,
        ),
      );
      expect(avatarButton, findsOneWidget);
      await tester.tap(avatarButton);
      await tester.pumpAndSettle();

      expect(find.text('Pesanan Saya'), findsOneWidget);
      await tester.ensureVisible(find.text('Pesanan Saya'));
      await tester.tap(find.text('Pesanan Saya'));
      await tester.pumpAndSettle();

      // OrderListScreen terbuka tanpa error lifecycle
      expect(find.byType(OrderListScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}