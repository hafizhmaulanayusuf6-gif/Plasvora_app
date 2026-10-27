/// Material listing model conforming to `api_contract.md` and Stitch Marketplace designs.
class MaterialListing {
  final int id;
  final int ownerId;
  final String name;
  final String category; // PET, HDPE, PP, LDPE, PVC, PS, Lainnya
  final double weightKg;
  final String condition; // clean, light, dirty
  final int price;
  final bool isFree;
  final String generalLocation;
  final double distanceKm;
  final String description;
  final String? imageUrl;
  final String? localAsset;
  final String status; // available, requested, handed_over
  final bool isFavorited;
  final DateTime createdAt;

  const MaterialListing({
    required this.id,
    this.ownerId = 1,
    required this.name,
    required this.category,
    required this.weightKg,
    required this.condition,
    required this.price,
    required this.isFree,
    required this.generalLocation,
    this.distanceKm = 1.0,
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
      case 'light':
        return 'Sedikit Kotor';
      case 'dirty':
        return 'Belum Dicuci';
      default:
        return condition;
    }
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
      id: json['id'] as int,
      ownerId: json['owner_id'] as int? ?? 1,
      name: json['name'] as String,
      category: json['category'] as String,
      weightKg: (json['weight_kg'] as num).toDouble(),
      condition: json['condition'] as String,
      price: json['price'] as int? ?? 0,
      isFree: json['is_free'] as bool? ?? false,
      generalLocation: json['general_location'] as String,
      distanceKm: (json['distance_km'] as num?)?.toDouble() ?? 2.5,
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
