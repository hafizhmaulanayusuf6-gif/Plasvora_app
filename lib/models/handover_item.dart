class HandoverItem {
  final int id;
  final int listingId;
  final int ownerId;
  final int requesterId;
  final double requestedWeightKg;
  final double? agreedWeightKg;
  final double? actualWeightKg;
  final String status;
  final String? note;
  final String? listingName;
  final String? ownerName;
  final String? requesterName;
  final DateTime createdAt;

  HandoverItem({
    required this.id,
    required this.listingId,
    required this.ownerId,
    required this.requesterId,
    required this.requestedWeightKg,
    this.agreedWeightKg,
    this.actualWeightKg,
    required this.status,
    this.note,
    this.listingName,
    this.ownerName,
    this.requesterName,
    required this.createdAt,
  });

  factory HandoverItem.fromJson(Map<String, dynamic> json) {
    String? listName;
    if (json['listing'] is Map<String, dynamic>) {
      listName = json['listing']['name'] as String?;
    }
    String? oName;
    if (json['owner'] is Map<String, dynamic>) {
      oName = json['owner']['name'] as String?;
    }
    String? rName;
    if (json['requester'] is Map<String, dynamic>) {
      rName = json['requester']['name'] as String?;
    }

    return HandoverItem(
      id: json['id'] is int ? json['id'] as int : (int.tryParse(json['id']?.toString() ?? '0') ?? 0),
      listingId: json['listing_id'] is int
          ? json['listing_id'] as int
          : (int.tryParse(json['listing_id']?.toString() ?? '0') ?? 0),
      ownerId: json['owner_id'] is int
          ? json['owner_id'] as int
          : (int.tryParse(json['owner_id']?.toString() ?? '0') ?? 0),
      requesterId: json['requester_id'] is int
          ? json['requester_id'] as int
          : (int.tryParse(json['requester_id']?.toString() ?? '0') ?? 0),
      requestedWeightKg: json['requested_weight_kg'] is num
          ? (json['requested_weight_kg'] as num).toDouble()
          : (double.tryParse(json['requested_weight_kg']?.toString() ?? '0') ?? 0.0),
      agreedWeightKg: json['agreed_weight_kg'] is num
          ? (json['agreed_weight_kg'] as num).toDouble()
          : double.tryParse(json['agreed_weight_kg']?.toString() ?? ''),
      actualWeightKg: json['actual_weight_kg'] is num
          ? (json['actual_weight_kg'] as num).toDouble()
          : double.tryParse(json['actual_weight_kg']?.toString() ?? ''),
      status: json['status'] as String? ?? 'pending',
      note: json['note'] as String?,
      listingName: listName,
      ownerName: oName,
      requesterName: rName,
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ?? DateTime.now(),
    );
  }
}

