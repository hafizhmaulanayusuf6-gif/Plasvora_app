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

  static int _parseInt(dynamic val) {
    if (val is int) return val;
    return int.tryParse(val?.toString() ?? '0') ?? 0;
  }

  static double _parseDouble(dynamic val) {
    if (val is num) return val.toDouble();
    return double.tryParse(val?.toString() ?? '0') ?? 0.0;
  }

  factory ImpactSummary.fromJson(Map<String, dynamic> json) {
    final listed = json['materials_listed'] as Map<String, dynamic>? ?? {};
    final available = json['materials_available'] as Map<String, dynamic>? ?? {};
    final handedOver = json['materials_handed_over'] as Map<String, dynamic>? ?? {};
    final confirmed = json['materials_utilized'] as Map<String, dynamic>? ?? {};

    return ImpactSummary(
      listedCount: _parseInt(listed['count']),
      listedWeightKg: _parseDouble(listed['weight_kg']),
      availableCount: _parseInt(available['count']),
      availableWeightKg: _parseDouble(available['weight_kg']),
      handedOverCount: _parseInt(handedOver['count']),
      handedOverWeightKg: _parseDouble(handedOver['weight_kg']),
      confirmedCount: _parseInt(confirmed['count']),
      confirmedWeightKg: _parseDouble(confirmed['weight_kg']),
    );
  }
}

