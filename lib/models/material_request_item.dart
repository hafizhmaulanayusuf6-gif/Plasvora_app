class MaterialRequestItem {
  final int id;
  final int requesterId;
  final String materialCategory;
  final double requestedWeightKg;
  final String minimumCondition;
  final String generalLocation;
  final String intendedUse;
  final String status; // active, fulfilled, cancelled
  final String? requesterName;
  final DateTime createdAt;

  MaterialRequestItem({
    required this.id,
    required this.requesterId,
    required this.materialCategory,
    required this.requestedWeightKg,
    required this.minimumCondition,
    required this.generalLocation,
    required this.intendedUse,
    required this.status,
    this.requesterName,
    required this.createdAt,
  });

  factory MaterialRequestItem.fromJson(Map<String, dynamic> json) {
    String? reqName;
    if (json['requester'] is Map<String, dynamic>) {
      reqName = json['requester']['name'] as String?;
    }

    return MaterialRequestItem(
      id: json['id'] is int
          ? json['id'] as int
          : (int.tryParse(json['id']?.toString() ?? '0') ?? 0),
      requesterId: json['requester_id'] is int
          ? json['requester_id'] as int
          : (int.tryParse(json['requester_id']?.toString() ?? '0') ?? 0),
      materialCategory: json['material_category'] as String? ?? 'PET',
      requestedWeightKg: json['requested_weight_kg'] is num
          ? (json['requested_weight_kg'] as num).toDouble()
          : (double.tryParse(json['requested_weight_kg']?.toString() ?? '0') ??
              0.0),
      minimumCondition: json['minimum_condition'] as String? ?? 'clean',
      generalLocation: json['general_location'] as String? ?? '',
      intendedUse: json['intended_use'] as String? ?? '',
      status: json['status'] as String? ?? 'active',
      requesterName: reqName,
      createdAt:
          DateTime.tryParse(json['created_at'] as String? ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'requester_id': requesterId,
      'material_category': materialCategory,
      'requested_weight_kg': requestedWeightKg,
      'minimum_condition': minimumCondition,
      'general_location': generalLocation,
      'intended_use': intendedUse,
      'status': status,
      'created_at': createdAt.toIso8601String(),
    };
  }

  String get categoryLabel {
    switch (materialCategory) {
      case 'OTHER':
        return 'Lainnya';
      case 'MIXED':
        return 'Campuran';
      default:
        return materialCategory;
    }
  }

  String get conditionLabel {
    switch (minimumCondition) {
      case 'clean':
        return 'Bersih';
      case 'slightly_dirty':
        return 'Sedikit Kotor';
      case 'dirty':
        return 'Kotor';
      case 'mixed':
        return 'Campuran';
      default:
        return minimumCondition;
    }
  }

  String get statusLabel {
    switch (status) {
      case 'active':
        return 'Aktif';
      case 'fulfilled':
        return 'Terpenuhi';
      case 'cancelled':
        return 'Dibatalkan';
      default:
        return status;
    }
  }

  String get formattedWeight {
    final isWhole = requestedWeightKg.truncateToDouble() == requestedWeightKg;
    return '${isWhole ? requestedWeightKg.toInt() : requestedWeightKg.toStringAsFixed(1)} kg';
  }

  MaterialRequestItem copyWith({
    int? id,
    int? requesterId,
    String? materialCategory,
    double? requestedWeightKg,
    String? minimumCondition,
    String? generalLocation,
    String? intendedUse,
    String? status,
    String? requesterName,
    DateTime? createdAt,
  }) {
    return MaterialRequestItem(
      id: id ?? this.id,
      requesterId: requesterId ?? this.requesterId,
      materialCategory: materialCategory ?? this.materialCategory,
      requestedWeightKg: requestedWeightKg ?? this.requestedWeightKg,
      minimumCondition: minimumCondition ?? this.minimumCondition,
      generalLocation: generalLocation ?? this.generalLocation,
      intendedUse: intendedUse ?? this.intendedUse,
      status: status ?? this.status,
      requesterName: requesterName ?? this.requesterName,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
