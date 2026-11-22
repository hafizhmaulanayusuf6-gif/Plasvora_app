import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:plasvora/models/order_item.dart';
import 'package:plasvora/repositories/order_repository.dart';
import 'package:plasvora/viewmodels/order_viewmodel.dart';

class _FakeOrderRepository implements OrderRepository {
  Future<OrderListPage> Function(String role, String? status, int page)?
      onGetOrders;
  Future<OrderItem> Function(int orderId)? onGetDetail;
  Future<OrderItem> Function({
    required int listingId,
    required int addressId,
    required String courierCode,
    required String courierService,
    String? buyerNote,
    required String idempotencyKey,
  })? onCreate;
  Future<OrderItem> Function(int orderId, String? reason)? onCancel;
  Future<OrderItem> Function(int orderId)? onRetry;
  Future<OrderRefreshResult> Function(int orderId)? onRefresh;
  Future<OrderItem> Function(int orderId, String tracking, String? notes)?
      onShip;
  Future<OrderItem> Function(int orderId)? onConfirm;

  int createCalls = 0;
  int refreshCalls = 0;

  @override
  Future<OrderListPage> getOrders({
    required String role,
    String? status,
    int page = 1,
    int perPage = 15,
  }) =>
      onGetOrders!(role, status, page);

  @override
  Future<OrderItem> getOrderDetail(int orderId) => onGetDetail!(orderId);

  @override
  Future<OrderItem> createOrder({
    required int listingId,
    required int addressId,
    required String courierCode,
    required String courierService,
    String? buyerNote,
    required String idempotencyKey,
  }) {
    createCalls++;
    return onCreate!(
      listingId: listingId,
      addressId: addressId,
      courierCode: courierCode,
      courierService: courierService,
      buyerNote: buyerNote,
      idempotencyKey: idempotencyKey,
    );
  }

  @override
  Future<OrderItem> cancelOrder(int orderId, {String? reason}) =>
      onCancel!(orderId, reason);

  @override
  Future<OrderItem> retryPayment(int orderId) => onRetry!(orderId);

  @override
  Future<OrderRefreshResult> refreshPaymentStatus(int orderId) {
    refreshCalls++;
    return onRefresh!(orderId);
  }

  @override
  Future<OrderItem> shipOrder({
    required int orderId,
    required String trackingNumber,
    String? shipmentNotes,
  }) =>
      onShip!(orderId, trackingNumber, shipmentNotes);

  @override
  Future<OrderItem> confirmDelivery(int orderId) => onConfirm!(orderId);
}

OrderItem _buildOrder({
  required int id,
  required int buyerId,
  required int sellerId,
  String status = OrderItem.statusPendingPayment,
  String paymentStatus = OrderItem.paymentUnpaid,
  String? trackingNumber,
}) {
  return OrderItem(
    id: id,
    orderNumber: 'PLV-TEST-$id',
    role: 'buyer',
    buyerId: buyerId,
    buyerName: 'User $buyerId',
    sellerId: sellerId,
    sellerName: 'User $sellerId',
    listingId: 100 + id,
    status: status,
    paymentStatus: paymentStatus,
    listing: OrderListingSnapshot(
      id: 100 + id,
      name: 'Lot PET #$id',
      category: 'PET',
      weightKg: 5.0,
    ),
    itemPrice: 50000,
    shippingCost: 18000,
    platformFee: 0,
    totalAmount: 68000,
    courierCode: 'jne',
    courierName: 'JNE',
    courierService: 'REG',
    trackingNumber: trackingNumber,
    midtransRedirectUrl:
        'https://app.sandbox.midtrans.com/snap/v4/redirection/tok-$id',
  );
}

void main() {
  group('OrderViewModel Lifecycle & Session Isolation Tests', () {
    test('handles full CRUD and lifecycle actions with duplicate submission guards', () async {
      final repo = _FakeOrderRepository();
      final order1 = _buildOrder(id: 1, buyerId: 10, sellerId: 20);
      final orderPaid = _buildOrder(
        id: 1,
        buyerId: 10,
        sellerId: 20,
        status: OrderItem.statusPaid,
        paymentStatus: OrderItem.paymentPaid,
      );
      final orderShipped = _buildOrder(
        id: 1,
        buyerId: 10,
        sellerId: 20,
        status: OrderItem.statusShipped,
        paymentStatus: OrderItem.paymentPaid,
        trackingNumber: 'JNE123456',
      );
      final orderDone = _buildOrder(
        id: 1,
        buyerId: 10,
        sellerId: 20,
        status: OrderItem.statusCompleted,
        paymentStatus: OrderItem.paymentPaid,
        trackingNumber: 'JNE123456',
      );
      final orderCancelled = _buildOrder(
        id: 2,
        buyerId: 10,
        sellerId: 20,
        status: OrderItem.statusCancelled,
        paymentStatus: OrderItem.paymentCancelled,
      );

      final createCompleter = Completer<OrderItem>();
      repo.onCreate = ({
        required listingId,
        required addressId,
        required courierCode,
        required courierService,
        buyerNote,
        required idempotencyKey,
      }) =>
          createCompleter.future;

      repo.onGetOrders = (role, status, page) async => OrderListPage(
            items: [role == 'buyer' ? order1 : orderPaid],
            currentPage: 1,
            lastPage: 1,
            perPage: 15,
            total: 1,
          );
      repo.onGetDetail = (id) async => order1;
      repo.onRetry = (id) async => order1;
      repo.onRefresh = (id) async => OrderRefreshResult(
            order: orderPaid,
            providerSynced: true,
            message: 'Lunas',
          );
      repo.onShip = (id, tracking, notes) async => orderShipped;
      repo.onConfirm = (id) async => orderDone;
      repo.onCancel = (id, reason) async => orderCancelled;

      final vm = OrderViewModel(orderRepository: repo);

      // Duplicate createOrder prevented while in-flight
      final f1 = vm.createOrder(
        listingId: 101,
        addressId: 1,
        courierCode: 'jne',
        courierService: 'REG',
        idempotencyKey: 'idem-1',
      );
      final f2 = vm.createOrder(
        listingId: 101,
        addressId: 1,
        courierCode: 'jne',
        courierService: 'REG',
        idempotencyKey: 'idem-1',
      );
      createCompleter.complete(order1);
      final r1 = await f1;
      final r2 = await f2;
      expect(r1?.id, 1);
      expect(r2, isNull);
      expect(repo.createCalls, 1);

      await vm.loadBuyerOrders();
      expect(vm.buyerOrders.length, 1);

      await vm.loadSellerOrders();
      expect(vm.sellerOrders.length, 1);

      await vm.loadOrderDetail(1);
      expect(vm.currentOrder?.id, 1);

      await vm.retryPayment(1);
      final refreshed = await vm.refreshPaymentStatus(1);
      expect(refreshed?.order.status, OrderItem.statusPaid);
      expect(vm.currentOrder?.status, OrderItem.statusPaid);

      final shipped = await vm.shipOrder(orderId: 1, trackingNumber: 'JNE123456');
      expect(shipped?.status, OrderItem.statusShipped);

      final done = await vm.confirmDelivery(1);
      expect(done?.status, OrderItem.statusCompleted);

      final cancelled = await vm.cancelOrder(2, reason: 'Batal');
      expect(cancelled?.status, OrderItem.statusCancelled);
    });

    test('clearUserData wipes User A cache and blocks stale async responses before User B loads', () async {
      final repo = _FakeOrderRepository();
      final userACompleter = Completer<OrderListPage>();
      final userAOrder = _buildOrder(id: 10, buyerId: 1, sellerId: 99);
      final userBOrder = _buildOrder(id: 20, buyerId: 2, sellerId: 88);

      var activeUser = 'A';
      repo.onGetOrders = (role, status, page) {
        if (activeUser == 'A') {
          return userACompleter.future;
        }
        return Future.value(
          OrderListPage(
            items: [userBOrder],
            currentPage: 1,
            lastPage: 1,
            perPage: 15,
            total: 1,
          ),
        );
      };

      final vm = OrderViewModel(orderRepository: repo);
      vm.setCurrentOrderPreview(userAOrder);
      vm.markPendingPaymentReturn(userAOrder.id);

      // User A starts async load
      final staleFuture = vm.loadBuyerOrders();

      // User A logs out BEFORE async load completes
      vm.clearUserData();
      expect(vm.buyerOrders, isEmpty);
      expect(vm.sellerOrders, isEmpty);
      expect(vm.currentOrder, isNull);
      expect(vm.pendingPaymentOrderId, isNull);

      // Stale response for User A arrives AFTER logout -> MUST be ignored!
      userACompleter.complete(
        OrderListPage(
          items: [userAOrder],
          currentPage: 1,
          lastPage: 1,
          perPage: 15,
          total: 1,
        ),
      );
      await staleFuture;
      expect(vm.buyerOrders, isEmpty);
      expect(vm.currentOrder, isNull);

      // User B logs in and loads orders -> sees ONLY User B's orders
      activeUser = 'B';
      await vm.loadBuyerOrders();
      expect(vm.buyerOrders.length, 1);
      expect(vm.buyerOrders.first.id, 20);
      expect(vm.buyerOrders.first.buyerId, 2);
    });
  });
}
