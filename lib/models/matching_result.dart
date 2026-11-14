import 'material_listing.dart';
import 'material_request_item.dart';

/// Item kecocokan listing material untuk sebuah Material Request
class MaterialRequestMatchItem {
  final MaterialListing listing;
  final List<String> matchReasons;
  final Map<String, String> matchReasonsDetail;
  final int matchScore;
  final String scoreExplanation;

  MaterialRequestMatchItem({
    required this.listing,
    required this.matchReasons,
    required this.matchReasonsDetail,
    required this.matchScore,
    required this.scoreExplanation,
  });

  factory MaterialRequestMatchItem.fromJson(Map<String, dynamic> json) {
    final listingJson = json['listing'] as Map<String, dynamic>? ?? {};
    final reasons = (json['match_reasons'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        [];
    final reasonsDetailRaw =
        json['match_reasons_detail'] as Map<String, dynamic>? ?? {};
    final Map<String, String> reasonsDetail = reasonsDetailRaw.map(
      (key, value) => MapEntry(key, value.toString()),
    );

    return MaterialRequestMatchItem(
      listing: MaterialListing.fromJson(listingJson),
      matchReasons: reasons,
      matchReasonsDetail: reasonsDetail,
      matchScore: json['match_score'] is int
          ? json['match_score'] as int
          : (int.tryParse(json['match_score']?.toString() ?? '0') ?? 0),
      scoreExplanation: json['score_explanation'] as String? ?? '',
    );
  }
}

/// Respons hasil Smart Matching untuk Material Request
class MaterialRequestMatchingResponse {
  final MaterialRequestItem request;
  final List<MaterialRequestMatchItem> matches;
  final int total;
  final String note;

  MaterialRequestMatchingResponse({
    required this.request,
    required this.matches,
    required this.total,
    required this.note,
  });

  factory MaterialRequestMatchingResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? json;
    final reqJson = data['request'] as Map<String, dynamic>? ?? {};
    final matchesList = (data['matches'] as List<dynamic>?)
            ?.map((item) =>
                MaterialRequestMatchItem.fromJson(item as Map<String, dynamic>))
            .toList() ??
        [];

    return MaterialRequestMatchingResponse(
      request: MaterialRequestItem.fromJson(reqJson),
      matches: matchesList,
      total: data['total'] is int
          ? data['total'] as int
          : matchesList.length,
      note: data['note'] as String? ??
          'Hasil matching berbasis aturan, bukan kecerdasan buatan.',
    );
  }
}

/// Item kecocokan permintaan kebutuhan untuk sebuah Material Listing
class MaterialListingMatchItem {
  final MaterialRequestItem request;
  final List<String> matchReasons;
  final Map<String, String> matchReasonsDetail;
  final int matchScore;
  final String scoreExplanation;

  MaterialListingMatchItem({
    required this.request,
    required this.matchReasons,
    required this.matchReasonsDetail,
    required this.matchScore,
    required this.scoreExplanation,
  });

  factory MaterialListingMatchItem.fromJson(Map<String, dynamic> json) {
    final reqJson = json['request'] as Map<String, dynamic>? ?? {};
    final reasons = (json['match_reasons'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        [];
    final reasonsDetailRaw =
        json['match_reasons_detail'] as Map<String, dynamic>? ?? {};
    final Map<String, String> reasonsDetail = reasonsDetailRaw.map(
      (key, value) => MapEntry(key, value.toString()),
    );

    return MaterialListingMatchItem(
      request: MaterialRequestItem.fromJson(reqJson),
      matchReasons: reasons,
      matchReasonsDetail: reasonsDetail,
      matchScore: json['match_score'] is int
          ? json['match_score'] as int
          : (int.tryParse(json['match_score']?.toString() ?? '0') ?? 0),
      scoreExplanation: json['score_explanation'] as String? ?? '',
    );
  }
}

/// Respons hasil Smart Matching untuk Material Listing
class MaterialListingMatchingResponse {
  final MaterialListing listing;
  final List<MaterialListingMatchItem> matches;
  final int total;
  final String note;

  MaterialListingMatchingResponse({
    required this.listing,
    required this.matches,
    required this.total,
    required this.note,
  });

  factory MaterialListingMatchingResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? json;
    final listingJson = data['listing'] as Map<String, dynamic>? ?? {};
    final matchesList = (data['matches'] as List<dynamic>?)
            ?.map((item) =>
                MaterialListingMatchItem.fromJson(item as Map<String, dynamic>))
            .toList() ??
        [];

    return MaterialListingMatchingResponse(
      listing: MaterialListing.fromJson(listingJson),
      matches: matchesList,
      total: data['total'] is int
          ? data['total'] as int
          : matchesList.length,
      note: data['note'] as String? ??
          'Hasil matching berbasis aturan, bukan kecerdasan buatan.',
    );
  }
}

