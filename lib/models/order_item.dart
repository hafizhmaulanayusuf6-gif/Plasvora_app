import 'material_listing.dart';

/// Snapshot immutable material pada saat checkout.
class OrderListingSnapshot {
  final int id;
  final String name;
  final String category;
  final double weightKg;
  final String? imageUrl;
  final int? originDestinationId;
  final String? originLabel;

  const OrderListingSnapshot({
    required this.id,
    required this.name,
    required this.category,
    required this.weightKg,
    this.imageUrl,
    this.originDestinationId,
    this.originLabel,
  });

  String get categoryLabel {
    final upper = category.toUpperCase();
    if (upper == 'OTHER') return 'Lainnya';
    if (upper == 'MIXED') return 'Campuran';
    return category;
  }

  factory OrderListingSnapshot.fromOrderJson(Map<String, dynamic> json) {
    final listingMap = json['listing'] is Map<String, dynamic>
        ? json['listing'] as Map<String, dynamic>
        : null;
    final originMap = json['origin'] is Map<String, dynamic>
        ? json['origin'] as Map<String, dynamic>
        : null;

    return OrderListingSnapshot(
      id: _parseOptionalInt(listingMap?['id'] ?? json['listing_id']) ?? 0,
      name: _nullableString(
            listingMap?['name'] ?? json['listing_name_snapshot'],
          ) ??
          'Material',
      category: _nullableString(
            listingMap?['category'] ?? json['listing_category_snapshot'],
          ) ??
          'OTHER',
      weightKg: _parseDouble(
        listingMap?['weight_kg'] ?? json['listing_weight_kg_snapshot'],
      ),
      imageUrl: _nullableString(
        listingMap?['image_url'] ?? json['listing_image_url_snapshot'],
      ),
      originDestinationId: _parseOptionalInt(
        originMap?['destination_id'] ?? json['origin_destination_id_snapshot'],
      ),
      originLabel: _nullableString(
        originMap?['label'] ?? json['origin_label_snapshot'],
      ),
    );
  }
}

/// Snapshot alamat pengiriman pembeli.
/// Pada sisi penjual sebelum pembayaran terverifikasi, field PII (nama, telepon, detail alamat, kode pos, catatan)
/// sengaja tidak dikembalikan backend dan akan bernilai null.
class OrderAddressSnapshot {
  final String? recipientName;
  final String? recipientPhone;
  final int? destinationId;
  final String? destinationLabel;
  final String? addressDetail;
  final String? postalCode;
  final String? deliveryNote;

  const OrderAddressSnapshot({
    this.recipientName,
    this.recipientPhone,
    this.destinationId,
    this.destinationLabel,
    this.addressDetail,
    this.postalCode,
    this.deliveryNote,
  });

  /// True jika backend menyertakan detail alamat lengkap (bukan versi ter-redaksi sebelum bayar).
  bool get hasFullShippingDetails =>
      (recipientName != null && recipientName!.isNotEmpty) ||
      (recipientPhone != null && recipientPhone!.isNotEmpty) ||
      (addressDetail != null && addressDetail!.isNotEmpty);

  static OrderAddressSnapshot? fromOrderJson(Map<String, dynamic> json) {
    final addrMap = json['shipping_address'] is Map<String, dynamic>
        ? json['shipping_address'] as Map<String, dynamic>
        : null;

    final hasFlatFields =
        json.containsKey('destination_label_snapshot') ||
        json.containsKey('address_detail_snapshot') ||
        json.containsKey('recipient_name_snapshot');

    if (addrMap == null && !hasFlatFields) {
      return null;
    }

    return OrderAddressSnapshot(
      recipientName: _nullableString(
        addrMap?['recipient_name'] ?? json['recipient_name_snapshot'],
      ),
      recipientPhone: _nullableString(
        addrMap?['recipient_phone'] ?? json['recipient_phone_snapshot'],
      ),
      destinationId: _parseOptionalInt(
        addrMap?['destination_id'] ?? json['destination_id_snapshot'],
      ),
      destinationLabel: _nullableString(
        addrMap?['destination_label'] ?? json['destination_label_snapshot'],
      ),
      addressDetail: _nullableString(
        addrMap?['address_detail'] ?? json['address_detail_snapshot'],
      ),
      postalCode: _nullableString(
        addrMap?['postal_code'] ?? json['postal_code_snapshot'],
      ),
      deliveryNote: _nullableString(
        addrMap?['delivery_note'] ?? json['delivery_note_snapshot'],
      ),
    );
  }
}

class OrderStatusHistoryItem {
  final int id;
  final String? fromStatus;
  final String toStatus;
  final String actorType;
  final String source;
  final String? reason;
  final DateTime? createdAt;

  const OrderStatusHistoryItem({
    required this.id,
    this.fromStatus,
    required this.toStatus,
    required this.actorType,
    required this.source,
    this.reason,
    this.createdAt,
  });

  String get toStatusLabel => OrderItem.labelForStatus(toStatus);

  factory OrderStatusHistoryItem.fromJson(Map<String, dynamic> json) {
    return OrderStatusHistoryItem(
      id: _parseOptionalInt(json['id']) ?? 0,
      fromStatus: _nullableString(json['from_status']),
      toStatus: _nullableString(json['to_status']) ?? '',
      actorType: _nullableString(json['actor_type']) ?? 'system',
      source: _nullableString(json['source']) ?? '',
      reason: _nullableString(json['reason']),
      createdAt: _parseDateTime(json['created_at']),
    );
  }
}

/// Model pesanan transaksi Stage 3 yang kompatibel dengan kontrak JSON Laravel `OrderController`.
class OrderItem {
  static const String statusPendingPayment = 'pending_payment';
  static const String statusPaid = 'paid';
  static const String statusShipped = 'shipped';
  static const String statusCompleted = 'completed';
  static const String statusCancelled = 'cancelled';
  static const String statusExpired = 'expired';

  static const String paymentUnpaid = 'unpaid';
  static const String paymentPending = 'pending';
  static const String paymentPaid = 'paid';
  static const String paymentFailed = 'failed';
  static const String paymentExpired = 'expired';
  static const String paymentCancelled = 'cancelled';
  static const String paymentRefunded = 'refunded';

  final int id;
  final String orderNumber;
  final String? role; // 'buyer' atau 'seller' dari backend
  final int buyerId;
  final String? buyerName;
  final int sellerId;
  final String? sellerName;
  final int listingId;
  final String status;
  final String paymentStatus;

  final OrderListingSnapshot listing;
  final OrderAddressSnapshot? shippingAddress;

  final int itemPrice;
  final int shippingCost;
  final int platformFee;
  final int totalAmount;
  final String currency;

  final String courierCode;
  final String courierName;
  final String courierService;
  final String? courierDescription;
  final String? estimatedEtd;
  final String? trackingNumber;
  final String? shipmentNotes;
  final String? buyerNote;

  final String? midtransOrderId;
  final String? midtransSnapToken;
  final String? midtransRedirectUrl;
  final String? midtransPaymentType;
  final String? midtransTransactionStatus;

  final String? cancellationReason;
  final String? cancelledBy;

  final DateTime? createdAt;
  final DateTime? paymentExpiresAt;
  final DateTime? paidAt;
  final DateTime? shippedAt;
  final DateTime? deliveredAt;
  final DateTime? completedAt;
  final DateTime? cancelledAt;

  final List<OrderStatusHistoryItem> statusHistories;

  const OrderItem({
    required this.id,
    required this.orderNumber,
    this.role,
    required this.buyerId,
    this.buyerName,
    required this.sellerId,
    this.sellerName,
    required this.listingId,
    required this.status,
    required this.paymentStatus,
    required this.listing,
    this.shippingAddress,
    required this.itemPrice,
    required this.shippingCost,
    required this.platformFee,
    required this.totalAmount,
    this.currency = 'IDR',
    required this.courierCode,
    required this.courierName,
    required this.courierService,
    this.courierDescription,
    this.estimatedEtd,
    this.trackingNumber,
    this.shipmentNotes,
    this.buyerNote,
    this.midtransOrderId,
    this.midtransSnapToken,
    this.midtransRedirectUrl,
    this.midtransPaymentType,
    this.midtransTransactionStatus,
    this.cancellationReason,
    this.cancelledBy,
    this.createdAt,
    this.paymentExpiresAt,
    this.paidAt,
    this.shippedAt,
    this.deliveredAt,
    this.completedAt,
    this.cancelledAt,
    this.statusHistories = const [],
  });

  // Convenience getters matching flat snapshot names
  String get listingNameSnapshot => listing.name;
  String get listingCategorySnapshot => listing.category;
  double get listingWeightKgSnapshot => listing.weightKg;
  String? get listingImageUrlSnapshot => listing.imageUrl;
  String? get originLabelSnapshot => listing.originLabel;

  String? get recipientNameSnapshot => shippingAddress?.recipientName;
  String? get recipientPhoneSnapshot => shippingAddress?.recipientPhone;
  String? get destinationLabelSnapshot => shippingAddress?.destinationLabel;
  String? get addressDetailSnapshot => shippingAddress?.addressDetail;
  String? get postalCodeSnapshot => shippingAddress?.postalCode;
  String? get deliveryNoteSnapshot => shippingAddress?.deliveryNote;

  bool isBuyerForUser(int? userId) {
    if (userId != null && buyerId > 0) return buyerId == userId;
    return role == 'buyer';
  }

  bool isSellerForUser(int? userId) {
    if (userId != null && sellerId > 0) return sellerId == userId;
    return role == 'seller';
  }

  bool get isPendingPayment => status == statusPendingPayment;
  bool get isPaid => status == statusPaid;
  bool get isShipped => status == statusShipped;
  bool get isCompleted => status == statusCompleted;
  bool get isCancelled => status == statusCancelled;
  bool get isExpired => status == statusExpired;

  String get statusLabel => labelForStatus(status);
  String get paymentStatusLabel => labelForPaymentStatus(paymentStatus);

  String get sellerCardHint {
    switch (status) {
      case statusPendingPayment:
        return 'Menunggu Pembayaran Pembeli';
      case statusPaid:
        return 'Pesanan Siap Dikirim';
      case statusShipped:
        return 'Dalam Pengiriman';
      case statusCompleted:
        return 'Pesanan Selesai';
      case statusCancelled:
        return 'Pesanan Dibatalkan';
      case statusExpired:
        return 'Pembayaran Kedaluwarsa';
      default:
        return statusLabel;
    }
  }

  String get formattedItemPrice => MaterialListing.formatRupiah(itemPrice);
  String get formattedShippingCost => MaterialListing.formatRupiah(shippingCost);
  String get formattedPlatformFee => MaterialListing.formatRupiah(platformFee);
  String get formattedTotalAmount => MaterialListing.formatRupiah(totalAmount);

  String get courierSummary {
    final name = courierName.isNotEmpty ? courierName : courierCode.toUpperCase();
    return courierService.isNotEmpty ? '$name - $courierService' : name;
  }

  static String labelForStatus(String status) {
    switch (status) {
      case statusPendingPayment:
        return 'Menunggu Pembayaran';
      case statusPaid:
        return 'Sudah Dibayar';
      case statusShipped:
        return 'Sedang Dikirim';
      case statusCompleted:
        return 'Selesai';
      case statusCancelled:
        return 'Dibatalkan';
      case statusExpired:
        return 'Kedaluwarsa';
      default:
        return status.isNotEmpty ? status : 'Tidak Diketahui';
    }
  }

  static String labelForPaymentStatus(String paymentStatus) {
    switch (paymentStatus) {
      case paymentUnpaid:
        return 'Belum Dibayar';
      case paymentPending:
        return 'Menunggu Konfirmasi';
      case paymentPaid:
        return 'Lunas';
      case paymentFailed:
        return 'Gagal';
      case paymentExpired:
        return 'Kedaluwarsa';
      case paymentCancelled:
        return 'Dibatalkan';
      case paymentRefunded:
        return 'Dana Dikembalikan';
      default:
        return paymentStatus.isNotEmpty ? paymentStatus : 'Tidak Diketahui';
    }
  }

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    final id = _parseOptionalInt(json['id']);
    if (id == null || id <= 0) {
      throw const FormatException('ID pesanan tidak valid.');
    }

    final buyerMap = json['buyer'] is Map<String, dynamic>
        ? json['buyer'] as Map<String, dynamic>
        : null;
    final sellerMap = json['seller'] is Map<String, dynamic>
        ? json['seller'] as Map<String, dynamic>
        : null;
    final courierMap = json['courier'] is Map<String, dynamic>
        ? json['courier'] as Map<String, dynamic>
        : null;
    final paymentMap = json['payment'] is Map<String, dynamic>
        ? json['payment'] as Map<String, dynamic>
        : null;

    final listingSnapshot = OrderListingSnapshot.fromOrderJson(json);

    // Nominal uang wajib valid (integer atau numeric string Rupiah utuh); jangan ubah data korup jadi 0.
    final itemPrice = _parseStrictRupiahInt(
      json['item_price'],
      fieldName: 'item_price',
    );
    final shippingCost = _parseStrictRupiahInt(
      json['shipping_cost'],
      fieldName: 'shipping_cost',
    );
    final platformFee = json.containsKey('platform_fee') && json['platform_fee'] != null
        ? _parseStrictRupiahInt(json['platform_fee'], fieldName: 'platform_fee')
        : 0;
    final totalAmount = _parseStrictRupiahInt(
      json['total_amount'],
      fieldName: 'total_amount',
    );

    final rawHistories = json['status_histories'] is List
        ? json['status_histories'] as List
        : const [];

    return OrderItem(
      id: id,
      orderNumber: _nullableString(json['order_number']) ?? '#$id',
      role: _nullableString(json['role']),
      buyerId: _parseOptionalInt(buyerMap?['id'] ?? json['buyer_id']) ?? 0,
      buyerName: _nullableString(buyerMap?['name'] ?? json['buyer_name']),
      sellerId: _parseOptionalInt(sellerMap?['id'] ?? json['seller_id']) ?? 0,
      sellerName: _nullableString(sellerMap?['name'] ?? json['seller_name']),
      listingId: listingSnapshot.id > 0
          ? listingSnapshot.id
          : (_parseOptionalInt(json['listing_id']) ?? 0),
      status: _nullableString(json['status']) ?? statusPendingPayment,
      paymentStatus: _nullableString(json['payment_status']) ?? paymentUnpaid,
      listing: listingSnapshot,
      shippingAddress: OrderAddressSnapshot.fromOrderJson(json),
      itemPrice: itemPrice,
      shippingCost: shippingCost,
      platformFee: platformFee,
      totalAmount: totalAmount,
      currency: _nullableString(json['currency']) ?? 'IDR',
      courierCode: _nullableString(
            courierMap?['code'] ?? json['courier_code'],
          ) ??
          '',
      courierName: _nullableString(
            courierMap?['name'] ?? json['courier_name'],
          ) ??
          '',
      courierService: _nullableString(
            courierMap?['service'] ?? json['courier_service'],
          ) ??
          '',
      courierDescription: _nullableString(
        courierMap?['description'] ?? json['courier_description'],
      ),
      estimatedEtd: _nullableString(
        courierMap?['etd'] ?? json['estimated_etd'],
      ),
      trackingNumber: _nullableString(json['tracking_number']),
      shipmentNotes: _nullableString(json['shipment_notes']),
      buyerNote: _nullableString(json['buyer_note']),
      midtransOrderId: _nullableString(
        paymentMap?['midtrans_order_id'] ?? json['midtrans_order_id'],
      ),
      midtransSnapToken: _nullableString(
        paymentMap?['snap_token'] ?? json['midtrans_snap_token'],
      ),
      midtransRedirectUrl: _nullableString(
        paymentMap?['redirect_url'] ?? json['midtrans_redirect_url'],
      ),
      midtransPaymentType: _nullableString(
        paymentMap?['payment_type'] ?? json['midtrans_payment_type'],
      ),
      midtransTransactionStatus: _nullableString(
        paymentMap?['transaction_status'] ?? json['midtrans_transaction_status'],
      ),
      cancellationReason: _nullableString(json['cancellation_reason']),
      cancelledBy: _nullableString(json['cancelled_by']),
      createdAt: _parseDateTime(json['created_at']),
      paymentExpiresAt: _parseDateTime(
        json['payment_expires_at'] ?? paymentMap?['expires_at'],
      ),
      paidAt: _parseDateTime(json['paid_at']),
      shippedAt: _parseDateTime(json['shipped_at']),
      deliveredAt: _parseDateTime(json['delivered_at']),
      completedAt: _parseDateTime(json['completed_at']),
      cancelledAt: _parseDateTime(json['cancelled_at']),
      statusHistories: rawHistories
          .whereType<Map<String, dynamic>>()
          .map(OrderStatusHistoryItem.fromJson)
          .toList(),
    );
  }
}

class OrderListPage {
  final List<OrderItem> items;
  final int currentPage;
  final int lastPage;
  final int perPage;
  final int total;

  const OrderListPage({
    required this.items,
    required this.currentPage,
    required this.lastPage,
    required this.perPage,
    required this.total,
  });

  bool get hasMore => currentPage < lastPage;
}

int _parseStrictRupiahInt(dynamic value, {required String fieldName}) {
  if (value is int) {
    if (value < 0) {
      throw FormatException('Nilai $fieldName tidak boleh negatif.');
    }
    return value;
  }
  if (value is String) {
    final trimmed = value.trim();
    final match = RegExp(r'^(\d+)(?:\.(\d+))?$').firstMatch(trimmed);
    if (match == null) {
      throw FormatException('Format nominal $fieldName tidak valid: $value');
    }
    final fraction = match.group(2);
    if (fraction != null && !RegExp(r'^0+$').hasMatch(fraction)) {
      throw FormatException('Nominal $fieldName tidak boleh pecahan: $value');
    }
    final parsed = int.tryParse(match.group(1)!);
    if (parsed == null || parsed < 0) {
      throw FormatException('Nominal $fieldName di luar rentang integer.');
    }
    return parsed;
  }
  throw FormatException('Tipe nominal $fieldName tidak valid: $value');
}

int? _parseOptionalInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is String) return int.tryParse(value.trim());
  return null;
}

double _parseDouble(dynamic value) {
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value.trim()) ?? 0.0;
  return 0.0;
}

String? _nullableString(dynamic value) {
  if (value == null || value is Map || value is List || value is bool) {
    return null;
  }
  final trimmed = value.toString().trim();
  return trimmed.isEmpty ? null : trimmed;
}

DateTime? _parseDateTime(dynamic value) {
  if (value is! String || value.trim().isEmpty) return null;
  return DateTime.tryParse(value.trim());
}
