/// Material listing model conforming to `api_contract.md` and Stitch Marketplace designs.
class MaterialListing {
  final int id;
  final int ownerId;
  final String? ownerName;
  final String name;
  final String category; // PET, HDPE, PP, LDPE, PVC, PS, OTHER, MIXED, Lainnya
  final double weightKg;
  final String condition; // clean, slightly_dirty, light, dirty, mixed
  final int price;
  final bool isFree;
  final String generalLocation;
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
    required this.name,
    required this.category,
    required this.weightKg,
    required this.condition,
    required this.price,
    required this.isFree,
    required this.generalLocation,
    this.distanceKm,
    required this.description,
    this.imageUrl,
    this.localAsset,
    this.status = 'available',
    this.isFavorited = false,
    required this.createdAt,
  });

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
    // format as Rp XX.XXX
    final str = price.toString();
    final buffer = StringBuffer();
    for (int i = 0; i < str.length; i++) {
      if (i > 0 && (str.length - i) % 3 == 0) {
        buffer.write('.');
      }
      buffer.write(str[i]);
    }
    return 'Rp $buffer';
  }

  MaterialListing copyWith({
    int? id,
    int? ownerId,
    String? ownerName,
    String? name,
    String? category,
    double? weightKg,
    String? condition,
    int? price,
    bool? isFree,
    String? generalLocation,
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
      name: name ?? this.name,
      category: category ?? this.category,
      weightKg: weightKg ?? this.weightKg,
      condition: condition ?? this.condition,
      price: price ?? this.price,
      isFree: isFree ?? this.isFree,
      generalLocation: generalLocation ?? this.generalLocation,
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
    return MaterialListing(
      id: json['id'] is int ? json['id'] as int : (int.tryParse(json['id']?.toString() ?? '0') ?? 0),
      ownerId: json['owner_id'] is int ? json['owner_id'] as int : (int.tryParse(json['owner_id']?.toString() ?? '1') ?? 1),
      ownerName: json['owner'] is Map<String, dynamic> ? json['owner']['name'] as String? : json['owner_name'] as String?,
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
      'name': name,
      'category': category,
      'weight_kg': weightKg,
      'condition': condition,
      'price': price,
      'is_free': isFree,
      'general_location': generalLocation,
      'distance_km': distanceKm,
      'description': description,
      'image_url': imageUrl,
      'status': status,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
