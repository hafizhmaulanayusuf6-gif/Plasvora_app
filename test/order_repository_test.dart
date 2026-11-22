import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:plasvora/core/network/api_client.dart';
import 'package:plasvora/models/order_item.dart';
import 'package:plasvora/repositories/order_repository.dart';

void main() {
  Map<String, dynamic> sampleOrderData({
    int id = 10,
    String status = 'pending_payment',
    String paymentStatus = 'unpaid',
    String? trackingNumber,
  }) =>
      {
        'id': id,
        'order_number': 'PLV-20261122-00$id',
        'role': 'buyer',
        'status': status,
        'payment_status': paymentStatus,
        'item_price': 50000,
        'shipping_cost': 18000,
        'platform_fee': 0,
        'total_amount': 68000,
        'currency': 'IDR',
        'tracking_number': trackingNumber,
        'courier': {
          'code': 'jne',
          'name': 'JNE',
          'service': 'REG',
          'etd': '2-3 day',
        },
        'listing': {
          'id': 5,
          'name': 'PET Bening 5kg',
          'category': 'PET',
          'weight_kg': 5.0,
        },
        'buyer': {'id': 2, 'name': 'Pembeli'},
        'seller': {'id': 1, 'name': 'Penjual'},
        'payment': {
          'midtrans_order_id': 'PLV-MID-$id',
          'redirect_url':
              'https://app.sandbox.midtrans.com/snap/v4/redirection/tok-$id',
        },
      };

  group('ApiOrderRepository Tests', () {
    test('createOrder sends only allowed checkout fields and never authoritative totals', () async {
      Map<String, dynamic>? capturedBody;
      String? capturedPath;

      final mockClient = MockClient((request) async {
        capturedPath = request.url.path;
        capturedBody = jsonDecode(request.body) as Map<String, dynamic>;
        return http.Response(
          jsonEncode({
            'success': true,
            'message': 'Pesanan berhasil dibuat.',
            'data': sampleOrderData(id: 11),
          }),
          201,
        );
      });

      final storage = InMemoryAuthTokenStorage();
      await storage.saveToken('sanctum-token-123');
      final repo = ApiOrderRepository(
        apiClient: ApiClient(client: mockClient, tokenStorage: storage),
      );

      final created = await repo.createOrder(
        listingId: 5,
        addressId: 9,
        courierCode: 'JNE',
        courierService: 'REG',
        buyerNote: 'Kemas rapi',
        idempotencyKey: 'idem-key-001',
      );

      expect(created.id, 11);
      expect(capturedPath, '/api/orders');
      expect(capturedBody, {
        'listing_id': 5,
        'address_id': 9,
        'courier_code': 'jne',
        'courier_service': 'REG',
        'idempotency_key': 'idem-key-001',
        'buyer_note': 'Kemas rapi',
      });
      expect(capturedBody!.containsKey('item_price'), isFalse);
      expect(capturedBody!.containsKey('shipping_cost'), isFalse);
      expect(capturedBody!.containsKey('total_amount'), isFalse);
      expect(capturedBody!.containsKey('weight_kg'), isFalse);
      expect(capturedBody!.containsKey('payment_status'), isFalse);
    });

    test('getOrders, refreshPaymentStatus, cancel, retry, ship, and confirm hit exact backend endpoints', () async {
      final visited = <String>[];

      final mockClient = MockClient((request) async {
        visited.add('${request.method} ${request.url.path}?${request.url.query}');

        if (request.method == 'GET' && request.url.path == '/api/orders') {
          return http.Response(
            jsonEncode({
              'success': true,
              'data': [sampleOrderData(id: 12)],
              'meta': {
                'current_page': 1,
                'last_page': 2,
                'per_page': 15,
                'total': 20,
              },
            }),
            200,
          );
        }

        if (request.url.path.endsWith('/refresh-payment')) {
          return http.Response(
            jsonEncode({
              'success': true,
              'message': 'Status pembayaran diperbarui.',
              'data': sampleOrderData(
                id: 12,
                status: 'paid',
                paymentStatus: 'paid',
              ),
              'meta': {'provider_synced': true},
            }),
            200,
          );
        }

        if (request.url.path.endsWith('/ship')) {
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          return http.Response(
            jsonEncode({
              'success': true,
              'data': sampleOrderData(
                id: 12,
                status: 'shipped',
                paymentStatus: 'paid',
                trackingNumber: body['tracking_number'] as String?,
              ),
            }),
            200,
          );
        }

        if (request.url.path.endsWith('/confirm-delivery')) {
          return http.Response(
            jsonEncode({
              'success': true,
              'data': sampleOrderData(
                id: 12,
                status: 'completed',
                paymentStatus: 'paid',
              ),
            }),
            200,
          );
        }

        return http.Response(
          jsonEncode({
            'success': true,
            'data': sampleOrderData(id: 12),
          }),
          200,
        );
      });

      final repo = ApiOrderRepository(
        apiClient: ApiClient(
          client: mockClient,
          tokenStorage: InMemoryAuthTokenStorage(),
        ),
      );

      final listPage = await repo.getOrders(role: 'buyer', status: 'paid');
      expect(listPage.items.length, 1);
      expect(listPage.hasMore, isTrue);

      final detail = await repo.getOrderDetail(12);
      expect(detail.id, 12);

      final refreshed = await repo.refreshPaymentStatus(12);
      expect(refreshed.providerSynced, isTrue);
      expect(refreshed.order.status, OrderItem.statusPaid);

      final retried = await repo.retryPayment(12);
      expect(retried.id, 12);

      final cancelled = await repo.cancelOrder(12, reason: 'Batal');
      expect(cancelled.id, 12);

      final shipped = await repo.shipOrder(
        orderId: 12,
        trackingNumber: 'JNE99887766',
        shipmentNotes: 'Rapi',
      );
      expect(shipped.status, OrderItem.statusShipped);
      expect(shipped.trackingNumber, 'JNE99887766');

      final completed = await repo.confirmDelivery(12);
      expect(completed.status, OrderItem.statusCompleted);

      expect(
        visited.any((e) => e.contains('GET /api/orders?role=buyer') && e.contains('status=paid')),
        isTrue,
      );
      expect(visited.any((e) => e.startsWith('POST /api/orders/12/refresh-payment')), isTrue);
      expect(visited.any((e) => e.startsWith('POST /api/orders/12/retry-payment')), isTrue);
      expect(visited.any((e) => e.startsWith('POST /api/orders/12/cancel')), isTrue);
      expect(visited.any((e) => e.startsWith('POST /api/orders/12/ship')), isTrue);
      expect(visited.any((e) => e.startsWith('POST /api/orders/12/confirm-delivery')), isTrue);
    });

    test('propagates ApiException data payload on 504 reconciliation_required', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'success': false,
            'message': 'Timeout Snap. Silakan coba ulang.',
            'data': {
              'order_id': 77,
              'reconciliation_required': true,
            },
          }),
          504,
        );
      });

      final repo = ApiOrderRepository(
        apiClient: ApiClient(
          client: mockClient,
          tokenStorage: InMemoryAuthTokenStorage(),
        ),
      );

      await expectLater(
        repo.createOrder(
          listingId: 5,
          addressId: 9,
          courierCode: 'jne',
          courierService: 'REG',
          idempotencyKey: 'idem-timeout-1',
        ),
        throwsA(
          isA<ApiException>()
              .having((e) => e.statusCode, 'statusCode', 504)
              .having((e) => e.data?['order_id'], 'order_id', 77),
        ),
      );
    });
  });
}
