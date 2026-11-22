/// Model alamat pengiriman pembeli yang dipetakan dari Laravel UserAddress.
class UserAddress {
  final int id;
  final String label;
  final String recipientName;
  final String recipientPhone;
  final int destinationId;
  final String destinationLabel;
  final String addressDetail;
  final String? postalCode;
  final String? deliveryNote;
  final bool isDefault;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const UserAddress({
    required this.id,
    required this.label,
    required this.recipientName,
    required this.recipientPhone,
    required this.destinationId,
    required this.destinationLabel,
    required this.addressDetail,
    this.postalCode,
    this.deliveryNote,
    this.isDefault = false,
    this.createdAt,
    this.updatedAt,
  });

  factory UserAddress.fromJson(Map<String, dynamic> json) {
    final rawDefault = json['is_default'];
    final isDefault = rawDefault is bool
        ? rawDefault
        : (rawDefault?.toString() == '1' || rawDefault?.toString() == 'true');

    return UserAddress(
      id: json['id'] is int
          ? json['id'] as int
          : (int.tryParse(json['id']?.toString() ?? '0') ?? 0),
      label: json['label']?.toString().trim().isNotEmpty == true
          ? json['label'].toString().trim()
          : 'Rumah',
      recipientName: json['recipient_name']?.toString() ?? '',
      recipientPhone: json['recipient_phone']?.toString() ?? '',
      destinationId: json['destination_id'] is int
          ? json['destination_id'] as int
          : (int.tryParse(json['destination_id']?.toString() ?? '0') ?? 0),
      destinationLabel: json['destination_label']?.toString() ?? '',
      addressDetail: json['address_detail']?.toString() ?? '',
      postalCode: _nullableString(json['postal_code']),
      deliveryNote: _nullableString(json['delivery_note']),
      isDefault: isDefault,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString())
          : null,
    );
  }

  /// Payload untuk POST /api/addresses (tanpa user_id maupun id).
  Map<String, dynamic> toRequestJson() {
    return {
      'label': label.trim().isNotEmpty ? label.trim() : 'Rumah',
      'recipient_name': recipientName.trim(),
      'recipient_phone': recipientPhone.trim(),
      'destination_id': destinationId,
      'destination_label': destinationLabel.trim(),
      'address_detail': addressDetail.trim(),
      'postal_code': _nullableString(postalCode),
      'delivery_note': _nullableString(deliveryNote),
      'is_default': isDefault,
    };
  }

  UserAddress copyWith({
    int? id,
    String? label,
    String? recipientName,
    String? recipientPhone,
    int? destinationId,
    String? destinationLabel,
    String? addressDetail,
    String? postalCode,
    String? deliveryNote,
    bool? isDefault,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserAddress(
      id: id ?? this.id,
      label: label ?? this.label,
      recipientName: recipientName ?? this.recipientName,
      recipientPhone: recipientPhone ?? this.recipientPhone,
      destinationId: destinationId ?? this.destinationId,
      destinationLabel: destinationLabel ?? this.destinationLabel,
      addressDetail: addressDetail ?? this.addressDetail,
      postalCode: postalCode ?? this.postalCode,
      deliveryNote: deliveryNote ?? this.deliveryNote,
      isDefault: isDefault ?? this.isDefault,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  static String? _nullableString(dynamic value) {
    if (value == null) return null;
    final trimmed = value.toString().trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}
