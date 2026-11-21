/// Material listing model conforming to `api_contract.md` and Stitch Marketplace designs.
class MaterialListing {
  final int id;
  final int ownerId;
  final String? ownerName;
  final String? ownerPhone;
  final String name;
  final String category; // PET, HDPE, PP, LDPE, PVC, PS, OTHER, MIXED, Lainnya
  final double weightKg;
  final String condition; // clean, slightly_dirty, light, dirty, mixed
  final int price;
  final bool isFree;
  final String generalLocation;
  final int? originDestinationId;
  final String? originLabel;
  final double? distanceKm;
  final String description;
  final String? imageUrl;
  final String? localAsset;
  final String status; // available, reserved, completed, inactive
  final bool isFavorited;
  final DateTime createdAt;

  const MaterialListing({
    required this.id,
    this.ownerId = 1,
    this.ownerName,
    this.ownerPhone,
    required this.name,
    required this.category,
    required this.weightKg,
    required this.condition,
    required this.price,
    required this.isFree,
    required this.generalLocation,
    this.originDestinationId,
    this.originLabel,
    this.distanceKm,
    required this.description,
    this.imageUrl,
    this.localAsset,
    this.status = 'available',
    this.isFavorited = false,
    required this.createdAt,
  });

  static String formatRupiah(int amount) {
    final str = amount.abs().toString();
    final buffer = StringBuffer();
    for (int i = 0; i < str.length; i++) {
      if (i > 0 && (str.length - i) % 3 == 0) {
        buffer.write('.');
      }
      buffer.write(str[i]);
    }
    final prefix = amount < 0 ? '-Rp ' : 'Rp ';
    return '$prefix$buffer';
  }

  String get conditionLabel {
    switch (condition.toLowerCase()) {
      case 'clean':
        return 'Bersih & Kering';
      case 'slightly_dirty':
      case 'light':
        return 'Sedikit Kotor';
      case 'dirty':
        return 'Belum Dicuci';
      case 'mixed':
        return 'Campuran';
      default:
        return condition;
    }
  }

  String get categoryLabel {
    if (category.toUpperCase() == 'OTHER') {
      return 'Lainnya';
    }
    if (category.toUpperCase() == 'MIXED') {
      return 'Campuran';
    }
    return category;
  }

  String get formattedPrice {
    if (isFree || price == 0) {
      return 'Gratis';
    }
    return formatRupiah(price);
  }

  /// Estimasi harga per kg (display-only, bukan harga transaksi checkout).
  double? get estimatedPricePerKg {
    if (isFree || price <= 0 || weightKg <= 0) {
      return null;
    }
    return price / weightKg;
  }

  /// Format estimasi harga per kg untuk tampilan sekunder di detail material.
  String? get formattedEstimatedPricePerKg {
    final estimate = estimatedPricePerKg;
    if (estimate == null) return null;
    return '${formatRupiah(estimate.round())} / kg';
  }

  MaterialListing copyWith({
    int? id,
    int? ownerId,
    String? ownerName,
    String? ownerPhone,
    String? name,
    String? category,
    double? weightKg,
    String? condition,
    int? price,
    bool? isFree,
    String? generalLocation,
    int? originDestinationId,
    String? originLabel,
    double? distanceKm,
    String? description,
    String? imageUrl,
    String? localAsset,
    String? status,
    bool? isFavorited,
    DateTime? createdAt,
  }) {
    return MaterialListing(
      id: id ?? this.id,
      ownerId: ownerId ?? this.ownerId,
      ownerName: ownerName ?? this.ownerName,
      ownerPhone: ownerPhone ?? this.ownerPhone,
      name: name ?? this.name,
      category: category ?? this.category,
      weightKg: weightKg ?? this.weightKg,
      condition: condition ?? this.condition,
      price: price ?? this.price,
      isFree: isFree ?? this.isFree,
      generalLocation: generalLocation ?? this.generalLocation,
      originDestinationId: originDestinationId ?? this.originDestinationId,
      originLabel: originLabel ?? this.originLabel,
      distanceKm: distanceKm ?? this.distanceKm,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      localAsset: localAsset ?? this.localAsset,
      status: status ?? this.status,
      isFavorited: isFavorited ?? this.isFavorited,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory MaterialListing.fromJson(Map<String, dynamic> json) {
    final ownerMap = json['owner'] is Map<String, dynamic>
        ? json['owner'] as Map<String, dynamic>
        : null;
    final rawOwnerPhone = (ownerMap?['phone'] ?? json['owner_phone'])?.toString().trim();

    return MaterialListing(
      id: json['id'] is int ? json['id'] as int : (int.tryParse(json['id']?.toString() ?? '0') ?? 0),
      ownerId: json['owner_id'] is int ? json['owner_id'] as int : (int.tryParse(json['owner_id']?.toString() ?? '1') ?? 1),
      ownerName: ownerMap != null ? ownerMap['name'] as String? : json['owner_name'] as String?,
      ownerPhone: (rawOwnerPhone != null && rawOwnerPhone.isNotEmpty) ? rawOwnerPhone : null,
      name: json['name'] as String? ?? '',
      category: json['category'] as String? ?? 'OTHER',
      weightKg: json['weight_kg'] is num
          ? (json['weight_kg'] as num).toDouble()
          : (double.tryParse(json['weight_kg']?.toString() ?? '0') ?? 0.0),
      condition: json['condition'] as String? ?? 'clean',
      price: json['price'] is int
          ? json['price'] as int
          : (num.tryParse(json['price']?.toString() ?? '0')?.toInt() ?? 0),
      isFree: json['is_free'] is bool
          ? json['is_free'] as bool
          : (json['is_free']?.toString() == '1' || json['is_free']?.toString() == 'true'),
      generalLocation: json['general_location'] as String? ?? '',
      originDestinationId: json['origin_destination_id'] is int
          ? json['origin_destination_id'] as int
          : (json['origin_destination_id'] != null
              ? int.tryParse(json['origin_destination_id'].toString())
              : null),
      originLabel: json['origin_label'] as String?,
      distanceKm: json['distance_km'] is num
          ? (json['distance_km'] as num).toDouble()
          : (json['distance_km'] != null ? double.tryParse(json['distance_km'].toString()) : null),
      description: json['description'] as String? ?? '',
      imageUrl: json['image_url'] as String?,
      localAsset: json['local_asset'] as String?,
      status: json['status'] as String? ?? 'available',
      isFavorited: json['is_favorited'] as bool? ?? false,
      createdAt:
          DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'owner_id': ownerId,
      'owner_name': ownerName,
      if (ownerPhone != null) 'owner_phone': ownerPhone,
      'name': name,
      'category': category,
      'weight_kg': weightKg,
      'condition': condition,
      'price': price,
      'is_free': isFree,
      'general_location': generalLocation,
      if (originDestinationId != null) 'origin_destination_id': originDestinationId,
      if (originLabel != null) 'origin_label': originLabel,
      'distance_km': distanceKm,
      'description': description,
      'image_url': imageUrl,
      'status': status,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
