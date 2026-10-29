class ImpactSummary {
  final int listedCount;
  final double listedWeightKg;
  final int availableCount;
  final double availableWeightKg;
  final int handedOverCount;
  final double handedOverWeightKg;
  final int confirmedCount;
  final double confirmedWeightKg;

  ImpactSummary({
    required this.listedCount,
    required this.listedWeightKg,
    required this.availableCount,
    required this.availableWeightKg,
    required this.handedOverCount,
    required this.handedOverWeightKg,
    required this.confirmedCount,
    required this.confirmedWeightKg,
  });

  factory ImpactSummary.fromJson(Map<String, dynamic> json) {
    final listed = json['materials_listed'] as Map<String, dynamic>? ?? {};
    final available = json['materials_available'] as Map<String, dynamic>? ?? {};
    final handedOver = json['materials_handed_over'] as Map<String, dynamic>? ?? {};
    final confirmed = json['materials_utilized'] as Map<String, dynamic>? ?? {};

    return ImpactSummary(
      listedCount: listed['count'] as int? ?? 0,
      listedWeightKg: (listed['weight_kg'] as num?)?.toDouble() ?? 0.0,
      availableCount: available['count'] as int? ?? 0,
      availableWeightKg: (available['weight_kg'] as num?)?.toDouble() ?? 0.0,
      handedOverCount: handedOver['count'] as int? ?? 0,
      handedOverWeightKg: (handedOver['weight_kg'] as num?)?.toDouble() ?? 0.0,
      confirmedCount: confirmed['count'] as int? ?? 0,
      confirmedWeightKg: (confirmed['weight_kg'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

