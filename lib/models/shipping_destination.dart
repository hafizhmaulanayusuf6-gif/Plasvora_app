/// Model hasil pencarian destinasi dan estimasi ongkos kirim domestik (Stage 2).
class ShippingDestination {
  final int destinationId;
  final String label;
  final String? provinceName;
  final String? cityName;
  final String? districtName;
  final String? subdistrictName;
  final String? postalCode;

  const ShippingDestination({
    required this.destinationId,
    required this.label,
    this.provinceName,
    this.cityName,
    this.districtName,
    this.subdistrictName,
    this.postalCode,
  });

  factory ShippingDestination.fromJson(Map<String, dynamic> json) {
    final rawId = json['destination_id'] ?? json['id'];
    return ShippingDestination(
      destinationId: _parseInt(rawId),
      label: json['label']?.toString().trim() ?? '',
      provinceName: _nullableString(json['province_name']),
      cityName: _nullableString(json['city_name']),
      districtName: _nullableString(json['district_name']),
      subdistrictName: _nullableString(json['subdistrict_name']),
      postalCode: _nullableString(json['postal_code'] ?? json['zip_code']),
    );
  }
}

class ShippingCostOption {
  final String courierCode;
  final String courierName;
  final String service;
  final String? description;
  final int cost;
  final String? etd;

  const ShippingCostOption({
    required this.courierCode,
    required this.courierName,
    required this.service,
    this.description,
    required this.cost,
    this.etd,
  });

  factory ShippingCostOption.fromJson(Map<String, dynamic> json) {
    return ShippingCostOption(
      courierCode: json['courier_code']?.toString().trim().toLowerCase() ?? '',
      courierName: json['courier_name']?.toString().trim() ?? '',
      service: json['service']?.toString().trim() ?? '',
      description: _nullableString(json['description']),
      cost: _parseInt(json['cost']),
      etd: _normalizeEtd(json['etd']),
    );
  }
}

class ShippingEstimateListingSummary {
  final int id;
  final String name;
  final double weightKg;
  final int weightGrams;
  final int originDestinationId;
  final String? originLabel;

  const ShippingEstimateListingSummary({
    required this.id,
    required this.name,
    required this.weightKg,
    required this.weightGrams,
    required this.originDestinationId,
    this.originLabel,
  });

  factory ShippingEstimateListingSummary.fromJson(Map<String, dynamic> json) {
    return ShippingEstimateListingSummary(
      id: _parseInt(json['id']),
      name: json['name']?.toString() ?? '',
      weightKg: _parseDouble(json['weight_kg']),
      weightGrams: _parseInt(json['weight_grams']),
      originDestinationId: _parseInt(json['origin_destination_id']),
      originLabel: _nullableString(json['origin_label']),
    );
  }
}

class ShippingEstimateDestinationSummary {
  final int addressId;
  final String label;
  final int destinationId;
  final String destinationLabel;

  const ShippingEstimateDestinationSummary({
    required this.addressId,
    required this.label,
    required this.destinationId,
    required this.destinationLabel,
  });

  factory ShippingEstimateDestinationSummary.fromJson(
    Map<String, dynamic> json,
  ) {
    return ShippingEstimateDestinationSummary(
      addressId: _parseInt(json['address_id']),
      label: json['label']?.toString() ?? '',
      destinationId: _parseInt(json['destination_id']),
      destinationLabel: json['destination_label']?.toString() ?? '',
    );
  }
}

class ShippingEstimateResult {
  final ShippingEstimateListingSummary listing;
  final ShippingEstimateDestinationSummary destination;
  final List<ShippingCostOption> options;
  final String? message;

  const ShippingEstimateResult({
    required this.listing,
    required this.destination,
    required this.options,
    this.message,
  });

  factory ShippingEstimateResult.fromJson(
    Map<String, dynamic> data, {
    String? message,
  }) {
    final rawListing = data['listing'] is Map<String, dynamic>
        ? data['listing'] as Map<String, dynamic>
        : const <String, dynamic>{};
    final rawDestination = data['destination'] is Map<String, dynamic>
        ? data['destination'] as Map<String, dynamic>
        : const <String, dynamic>{};
    final rawOptions = data['options'] is List ? data['options'] as List : const [];

    return ShippingEstimateResult(
      listing: ShippingEstimateListingSummary.fromJson(rawListing),
      destination: ShippingEstimateDestinationSummary.fromJson(rawDestination),
      options: rawOptions
          .whereType<Map<String, dynamic>>()
          .map(ShippingCostOption.fromJson)
          .toList(),
      message: _nullableString(message),
    );
  }
}

int _parseInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.round();
  if (value is String) {
    final trimmed = value.trim();
    return int.tryParse(trimmed) ?? (double.tryParse(trimmed)?.round() ?? 0);
  }
  return 0;
}

double _parseDouble(dynamic value) {
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value.trim()) ?? 0.0;
  return 0.0;
}

String? _nullableString(dynamic value) {
  if (value == null) return null;
  final trimmed = value.toString().trim();
  return trimmed.isEmpty ? null : trimmed;
}

String? _normalizeEtd(dynamic value) {
  final str = _nullableString(value);
  if (str == null) return null;
  if (RegExp(r'^[\-\s]+$').hasMatch(str)) return null;
  return str;
}
