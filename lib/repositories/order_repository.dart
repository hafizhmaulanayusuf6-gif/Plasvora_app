import '../core/network/api_client.dart';
import '../core/network/api_config.dart';
import '../models/order_item.dart';

class OrderRefreshResult {
  final OrderItem order;
  final bool providerSynced;
  final String message;

  const OrderRefreshResult({
    required this.order,
    required this.providerSynced,
    required this.message,
  });
}

abstract class OrderRepository {
  Future<OrderItem> createOrder({
    required int listingId,
    required int addressId,
    required String courierCode,
    required String courierService,
    String? buyerNote,
    required String idempotencyKey,
  });

  Future<OrderListPage> getOrders({
    required String role,
    String? status,
    int page = 1,
    int perPage = 15,
  });

  Future<OrderItem> getOrderDetail(int orderId);

  Future<OrderItem> cancelOrder(int orderId, {String? reason});

  Future<OrderItem> retryPayment(int orderId);

  Future<OrderRefreshResult> refreshPaymentStatus(int orderId);

  Future<OrderItem> shipOrder({
    required int orderId,
    required String trackingNumber,
    String? shipmentNotes,
  });

  Future<OrderItem> confirmDelivery(int orderId);
}

class ApiOrderRepository implements OrderRepository {
  final ApiClient apiClient;

  ApiOrderRepository({required this.apiClient});

  @override
  Future<OrderItem> createOrder({
    required int listingId,
    required int addressId,
    required String courierCode,
    required String courierService,
    String? buyerNote,
    required String idempotencyKey,
  }) async {
    // Klien HANYA mengirim field checkout yang diizinkan; harga & ongkir otoritatif dihitung server.
    final trimmedNote = buyerNote?.trim();
    final body = <String, dynamic>{
      'listing_id': listingId,
      'address_id': addressId,
      'courier_code': courierCode.trim().toLowerCase(),
      'courier_service': courierService.trim(),
      'idempotency_key': idempotencyKey.trim(),
      if (trimmedNote != null && trimmedNote.isNotEmpty) 'buyer_note': trimmedNote,
    };

    final response = await apiClient.post(
      ApiConfig.orders,
      body: body,
      requiresAuth: true,
    );

    return _parseOrderEnvelope(response, 'Format respons pembuatan pesanan tidak valid.');
  }

  @override
  Future<OrderListPage> getOrders({
    required String role,
    String? status,
    int page = 1,
    int perPage = 15,
  }) async {
    final queryParams = <String, String>{
      'role': role,
      'page': page.toString(),
      'per_page': perPage.toString(),
      if (status != null && status.trim().isNotEmpty) 'status': status.trim(),
    };

    final uri = Uri.parse(ApiConfig.orders).replace(
      queryParameters: queryParams,
    );

    final response = await apiClient.get(
      uri.toString(),
      requiresAuth: true,
    );

    if (response is Map<String, dynamic> && response['data'] is List) {
      final items = (response['data'] as List)
          .whereType<Map<String, dynamic>>()
          .map(OrderItem.fromJson)
          .toList();

      final meta = response['meta'] is Map<String, dynamic>
          ? response['meta'] as Map<String, dynamic>
          : const <String, dynamic>{};

      return OrderListPage(
        items: items,
        currentPage: _metaInt(meta['current_page'], fallback: page),
        lastPage: _metaInt(meta['last_page'], fallback: page),
        perPage: _metaInt(meta['per_page'], fallback: perPage),
        total: _metaInt(meta['total'], fallback: items.length),
      );
    }

    throw ApiException('Format respons daftar pesanan tidak valid.');
  }

  @override
  Future<OrderItem> getOrderDetail(int orderId) async {
    final response = await apiClient.get(
      ApiConfig.orderDetail(orderId),
      requiresAuth: true,
    );

    return _parseOrderEnvelope(response, 'Format respons detail pesanan tidak valid.');
  }

  @override
  Future<OrderItem> cancelOrder(int orderId, {String? reason}) async {
    final trimmedReason = reason?.trim();
    final response = await apiClient.post(
      ApiConfig.orderCancel(orderId),
      body: trimmedReason != null && trimmedReason.isNotEmpty
          ? {'reason': trimmedReason}
          : const <String, dynamic>{},
      requiresAuth: true,
    );

    return _parseOrderEnvelope(response, 'Format respons pembatalan pesanan tidak valid.');
  }

  @override
  Future<OrderItem> retryPayment(int orderId) async {
    final response = await apiClient.post(
      ApiConfig.orderRetryPayment(orderId),
      requiresAuth: true,
    );

    return _parseOrderEnvelope(response, 'Format respons sesi pembayaran ulang tidak valid.');
  }

  @override
  Future<OrderRefreshResult> refreshPaymentStatus(int orderId) async {
    final response = await apiClient.post(
      ApiConfig.orderRefreshPayment(orderId),
      requiresAuth: true,
    );

    final order = _parseOrderEnvelope(
      response,
      'Format respons sinkronisasi status pembayaran tidak valid.',
    );

    final meta = response is Map<String, dynamic> && response['meta'] is Map<String, dynamic>
        ? response['meta'] as Map<String, dynamic>
        : const <String, dynamic>{};

    return OrderRefreshResult(
      order: order,
      providerSynced: meta['provider_synced'] == true,
      message: (response is Map<String, dynamic> && response['message'] is String)
          ? (response['message'] as String)
          : 'Status pembayaran berhasil diperbarui.',
    );
  }

  @override
  Future<OrderItem> shipOrder({
    required int orderId,
    required String trackingNumber,
    String? shipmentNotes,
  }) async {
    final trimmedNotes = shipmentNotes?.trim();
    final response = await apiClient.post(
      ApiConfig.orderShip(orderId),
      body: {
        'tracking_number': trackingNumber.trim(),
        if (trimmedNotes != null && trimmedNotes.isNotEmpty)
          'shipment_notes': trimmedNotes,
      },
      requiresAuth: true,
    );

    return _parseOrderEnvelope(response, 'Format respons pengiriman pesanan tidak valid.');
  }

  @override
  Future<OrderItem> confirmDelivery(int orderId) async {
    final response = await apiClient.post(
      ApiConfig.orderConfirmDelivery(orderId),
      requiresAuth: true,
    );

    return _parseOrderEnvelope(
      response,
      'Format respons konfirmasi penerimaan pesanan tidak valid.',
    );
  }

  OrderItem _parseOrderEnvelope(dynamic response, String errorMessage) {
    if (response is Map<String, dynamic> &&
        response['data'] is Map<String, dynamic>) {
      try {
        return OrderItem.fromJson(response['data'] as Map<String, dynamic>);
      } on FormatException catch (e) {
        throw ApiException(e.message);
      }
    }
    throw ApiException(errorMessage);
  }

  int _metaInt(dynamic raw, {required int fallback}) {
    if (raw is int) return raw;
    if (raw is String) return int.tryParse(raw) ?? fallback;
    return fallback;
  }
}

/// Mock repository deterministik untuk fallback USE_API=false dan pengujian offline.
class MockOrderRepository implements OrderRepository {
  final List<OrderItem> _orders = [];
  int _nextId = 1;

  @override
  Future<OrderItem> createOrder({
    required int listingId,
    required int addressId,
    required String courierCode,
    required String courierService,
    String? buyerNote,
    required String idempotencyKey,
  }) async {
    final id = _nextId++;
    final now = DateTime.now();
    final created = OrderItem(
      id: id,
      orderNumber: 'PLV-MOCK-00$id',
      role: 'buyer',
      buyerId: 1,
      buyerName: 'Pembeli Demo',
      sellerId: 2,
      sellerName: 'Penjual Demo',
      listingId: listingId,
      status: OrderItem.statusPendingPayment,
      paymentStatus: OrderItem.paymentUnpaid,
      listing: OrderListingSnapshot(
        id: listingId,
        name: 'Lot Material Simulasi #$listingId',
        category: 'PET',
        weightKg: 5.0,
        originDestinationId: 4949,
        originLabel: 'BRAGA, SUMUR BANDUNG, BANDUNG',
      ),
      shippingAddress: const OrderAddressSnapshot(
        recipientName: 'Pembeli Demo',
        recipientPhone: '6281234567890',
        destinationId: 6157,
        destinationLabel: 'BABAKANKARET, CIANJUR',
        addressDetail: 'Jl. Simulasi No. 1',
        postalCode: '43211',
      ),
      itemPrice: 50000,
      shippingCost: 16000,
      platformFee: 0,
      totalAmount: 66000,
      courierCode: courierCode,
      courierName: courierCode.toUpperCase(),
      courierService: courierService,
      estimatedEtd: '2-3 day',
      buyerNote: buyerNote,
      midtransOrderId: 'PLV-MID-MOCK-$id',
      midtransSnapToken: 'mock-snap-token-$id',
      midtransRedirectUrl:
          'https://app.sandbox.midtrans.com/snap/v4/redirection/mock-snap-token-$id',
      createdAt: now,
      paymentExpiresAt: now.add(const Duration(hours: 24)),
      statusHistories: [
        OrderStatusHistoryItem(
          id: id,
          fromStatus: null,
          toStatus: OrderItem.statusPendingPayment,
          actorType: 'buyer',
          source: 'checkout',
          reason: 'Pesanan dibuat.',
          createdAt: now,
        ),
      ],
    );
    _orders.insert(0, created);
    return created;
  }

  @override
  Future<OrderListPage> getOrders({
    required String role,
    String? status,
    int page = 1,
    int perPage = 15,
  }) async {
    final filtered = _orders
        .where((o) => status == null || o.status == status)
        .toList();
    return OrderListPage(
      items: filtered,
      currentPage: page,
      lastPage: 1,
      perPage: perPage,
      total: filtered.length,
    );
  }

  @override
  Future<OrderItem> getOrderDetail(int orderId) async {
    return _orders.firstWhere(
      (o) => o.id == orderId,
      orElse: () => throw ApiException('Pesanan tidak ditemukan.', statusCode: 404),
    );
  }

  @override
  Future<OrderItem> cancelOrder(int orderId, {String? reason}) =>
      getOrderDetail(orderId);

  @override
  Future<OrderItem> retryPayment(int orderId) => getOrderDetail(orderId);

  @override
  Future<OrderRefreshResult> refreshPaymentStatus(int orderId) async {
    final order = await getOrderDetail(orderId);
    return OrderRefreshResult(
      order: order,
      providerSynced: false,
      message: 'Status pembayaran simulasi diperbarui.',
    );
  }

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
