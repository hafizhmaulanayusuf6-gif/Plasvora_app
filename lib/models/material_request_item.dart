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
      id: json['id'] as int,
      requesterId: json['requester_id'] as int? ?? 0,
      materialCategory: json['material_category'] as String? ?? 'PET',
      requestedWeightKg: (json['requested_weight_kg'] as num?)?.toDouble() ?? 0.0,
      minimumCondition: json['minimum_condition'] as String? ?? 'clean',
      generalLocation: json['general_location'] as String? ?? '',
      intendedUse: json['intended_use'] as String? ?? '',
      status: json['status'] as String? ?? 'active',
      requesterName: reqName,
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ?? DateTime.now(),
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
}

