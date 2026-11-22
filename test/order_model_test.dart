import 'package:flutter_test/flutter_test.dart';
import 'package:plasvora/core/utils/payment_launcher.dart';
import 'package:plasvora/models/order_item.dart';
import 'package:url_launcher/url_launcher.dart';

void main() {
  group('OrderItem & PaymentLauncher Unit Tests', () {
    Map<String, dynamic> fullBackendOrderJson() => {
          'id': 42,
          'order_number': 'PLV-20261122-AB12CD34',
          'role': 'buyer',
          'status': 'pending_payment',
          'payment_status': 'unpaid',
          'item_price': 50000,
          'shipping_cost': '18000.00',
          'platform_fee': 0,
          'total_amount': '68000',
          'currency': 'IDR',
          'buyer_note': 'Kemas rapi',
          'tracking_number': null,
          'shipment_notes': null,
          'courier': {
            'code': 'jne',
            'name': 'Jalur Nugraha Ekakurir (JNE)',
            'service': 'REG',
            'description': 'Layanan Reguler',
            'etd': '2-3 day',
          },
          'listing': {
            'id': 101,
            'name': 'Botol PET Bening 10kg',
            'category': 'PET',
            'weight_kg': 10.0,
            'image_url': 'http://127.0.0.1:8000/storage/materials/pet.jpg',
          },
          'origin': {
            'destination_id': 4949,
            'label': 'BRAGA, SUMUR BANDUNG, BANDUNG',
          },
          'shipping_address': {
            'recipient_name': 'Budi Pembeli',
            'recipient_phone': '6281234567890',
            'destination_id': 6157,
            'destination_label': 'BABAKANKARET, CIANJUR',
            'address_detail': 'Jl. Raya Cianjur No. 12',
            'postal_code': '43211',
            'delivery_note': 'Dekat masjid',
          },
          'buyer': {'id': 7, 'name': 'Budi'},
          'seller': {'id': 3, 'name': 'Siti'},
          'payment': {
            'midtrans_order_id': 'PLV-MID-20261122-XYZ',
            'snap_token': 'snap-tok-123',
            'redirect_url':
                'https://app.sandbox.midtrans.com/snap/v4/redirection/snap-tok-123',
            'payment_type': null,
            'transaction_status': null,
            'expires_at': '2026-11-23T08:00:00+00:00',
          },
          'created_at': '2026-11-22T08:00:00+00:00',
          'payment_expires_at': '2026-11-23T08:00:00+00:00',
          'status_histories': [
            {
              'id': 1,
              'from_status': null,
              'to_status': 'pending_payment',
              'actor_type': 'buyer',
              'source': 'checkout',
              'reason': 'Pesanan dibuat.',
              'created_at': '2026-11-22T08:00:00+00:00',
            },
          ],
        };

    test('parses actual backend JSON including numeric strings and histories', () {
      final order = OrderItem.fromJson(fullBackendOrderJson());

      expect(order.id, 42);
      expect(order.orderNumber, 'PLV-20261122-AB12CD34');
      expect(order.buyerId, 7);
      expect(order.sellerId, 3);
      expect(order.listingId, 101);
      expect(order.itemPrice, 50000);
      expect(order.shippingCost, 18000);
      expect(order.platformFee, 0);
      expect(order.totalAmount, 68000);
      expect(order.formattedTotalAmount, 'Rp 68.000');
      expect(order.statusLabel, 'Menunggu Pembayaran');
      expect(order.paymentStatusLabel, 'Belum Dibayar');
      expect(order.listing.name, 'Botol PET Bening 10kg');
      expect(order.listing.originLabel, 'BRAGA, SUMUR BANDUNG, BANDUNG');
      expect(order.shippingAddress?.hasFullShippingDetails, isTrue);
      expect(order.shippingAddress?.recipientPhone, '6281234567890');
      expect(
        order.midtransRedirectUrl,
        'https://app.sandbox.midtrans.com/snap/v4/redirection/snap-tok-123',
      );
      expect(order.statusHistories.length, 1);
      expect(order.statusHistories.first.toStatus, 'pending_payment');
    });

    test('preserves redacted seller address before payment without inventing PII', () {
      final json = fullBackendOrderJson();
      json['role'] = 'seller';
      json['shipping_address'] = {
        'destination_id': 6157,
        'destination_label': 'BABAKANKARET, CIANJUR',
      };
      json['payment'] = {
        'midtrans_order_id': 'PLV-MID-20261122-XYZ',
      };

      final order = OrderItem.fromJson(json);

      expect(order.shippingAddress, isNotNull);
      expect(order.shippingAddress!.hasFullShippingDetails, isFalse);
      expect(order.shippingAddress!.destinationLabel, 'BABAKANKARET, CIANJUR');
      expect(order.shippingAddress!.recipientName, isNull);
      expect(order.shippingAddress!.recipientPhone, isNull);
      expect(order.shippingAddress!.addressDetail, isNull);
      expect(order.midtransRedirectUrl, isNull);
    });

    test('rejects malformed or fractional monetary fields instead of converting to zero', () {
      for (final badValue in ['50000.50', 'abc', -100, null, true]) {
        final json = fullBackendOrderJson();
        json['total_amount'] = badValue;
        expect(
          () => OrderItem.fromJson(json),
          throwsA(isA<FormatException>()),
          reason: 'Expected FormatException for total_amount=$badValue',
        );
      }
    });

    test('PaymentLauncher validates only trusted HTTPS Midtrans hosts and falls back safely', () async {
      expect(
        PaymentLauncher.validateTrustedMidtransUrl(
          'https://app.sandbox.midtrans.com/snap/v4/redirection/tok-1',
        ),
        isNotNull,
      );
      expect(
        PaymentLauncher.validateTrustedMidtransUrl(
          'https://app.midtrans.com/snap/v4/redirection/tok-2',
        ),
        isNotNull,
      );

      // Untrusted / non-HTTPS URLs rejected
      expect(
        PaymentLauncher.validateTrustedMidtransUrl(
          'http://app.sandbox.midtrans.com/snap/v4/redirection/tok-1',
        ),
        isNull,
      );
      expect(
        PaymentLauncher.validateTrustedMidtransUrl(
          'https://evil.example.com/snap/v4/redirection/tok-1',
        ),
        isNull,
      );
      expect(
        PaymentLauncher.validateTrustedMidtransUrl(
          'https://app.midtrans.com.evil.com/snap',
        ),
        isNull,
      );

      final attemptedModes = <LaunchMode>[];
      final launcher = UrlPaymentLauncher(
        executor: (uri, {required mode}) async {
          attemptedModes.add(mode);
          return mode == LaunchMode.externalApplication;
        },
      );

      final result = await launcher.launchPaymentUrl(
        'https://app.sandbox.midtrans.com/snap/v4/redirection/tok-1',
      );
      expect(result.launched, isTrue);
      expect(attemptedModes, [
        LaunchMode.inAppBrowserView,
        LaunchMode.externalApplication,
      ]);

      final badResult = await launcher.launchPaymentUrl('https://phishing.test');
      expect(badResult.launched, isFalse);
      expect(badResult.errorMessage, isNotNull);
    });
  });
}
