import 'plastic_analysis.dart';

enum GalleryDifficulty {
  mudah('mudah', 'Mudah'),
  menengah('menengah', 'Menengah'),
  sulit('sulit', 'Sulit');

  final String apiValue;
  final String label;

  const GalleryDifficulty(this.apiValue, this.label);

  static GalleryDifficulty fromString(String? raw) {
    final normalized = (raw ?? '').trim().toLowerCase();
    if (normalized.contains('sulit') || normalized.contains('hard')) {
      return GalleryDifficulty.sulit;
    }
    if (normalized.contains('menengah') || normalized.contains('medium')) {
      return GalleryDifficulty.menengah;
    }
    return GalleryDifficulty.mudah;
  }
}

enum GalleryWorkStatus {
  pending('pending', 'Menunggu Verifikasi'),
  approved('approved', 'Tayang'),
  rejected('rejected', 'Ditolak');

  final String apiValue;
  final String label;

  const GalleryWorkStatus(this.apiValue, this.label);

  static GalleryWorkStatus? fromString(String? raw) {
    if (raw == null) return null;
    switch (raw.trim().toLowerCase()) {
      case 'pending':
        return GalleryWorkStatus.pending;
      case 'approved':
        return GalleryWorkStatus.approved;
      case 'rejected':
        return GalleryWorkStatus.rejected;
      default:
        return null;
    }
  }
}

class GalleryAuthor {
  final int id;
  final String name;

  const GalleryAuthor({
    required this.id,
    required this.name,
  });

  factory GalleryAuthor.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return const GalleryAuthor(id: 0, name: 'Pengguna Plasvora');
    }
    final nameStr = (json['name']?.toString() ?? '').trim();
    return GalleryAuthor(
      id: _parseInt(json['id']) ?? 0,
      name: nameStr.isNotEmpty ? nameStr : 'Pengguna Plasvora',
    );
  }
}

class GalleryImage {
  final int id;
  final String url;
  final int sortOrder;

  const GalleryImage({
    required this.id,
    required this.url,
    required this.sortOrder,
  });

  factory GalleryImage.fromJson(Map<String, dynamic> json) {
    return GalleryImage(
      id: _parseInt(json['id']) ?? 0,
      url: (json['url']?.toString() ?? '').trim(),
      sortOrder: _parseInt(json['sort_order']) ?? 0,
    );
  }
}

class GalleryWork {
  final int id;
  final String title;
  final GalleryDifficulty difficulty;
  final String? coverImageUrl;
  final List<GalleryImage> images;
  final List<String> materials;
  final List<String> tools;
  final List<String> steps;
  final List<String> videoLinks;
  final int likesCount;
  final bool likedByMe;
  final DateTime? publishedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final GalleryAuthor author;
  final int materialsCount;
  final int stepsCount;
  final GalleryWorkStatus? status;
  final String? rejectionReason;

  const GalleryWork({
    required this.id,
    required this.title,
    required this.difficulty,
    this.coverImageUrl,
    this.images = const [],
    this.materials = const [],
    this.tools = const [],
    this.steps = const [],
    this.videoLinks = const [],
    this.likesCount = 0,
    this.likedByMe = false,
    this.publishedAt,
    this.createdAt,
    this.updatedAt,
    required this.author,
    this.materialsCount = 0,
    this.stepsCount = 0,
    this.status,
    this.rejectionReason,
  });

  bool get isApproved => status == null || status == GalleryWorkStatus.approved;
  bool get isPending => status == GalleryWorkStatus.pending;
  bool get isRejected => status == GalleryWorkStatus.rejected;

  String? get effectiveCoverUrl {
    if (coverImageUrl != null && coverImageUrl!.trim().isNotEmpty) {
      return coverImageUrl!.trim();
    }
    if (images.isNotEmpty && images.first.url.isNotEmpty) {
      return images.first.url;
    }
    return null;
  }

  GalleryWork copyWith({
    int? id,
    String? title,
    GalleryDifficulty? difficulty,
    String? coverImageUrl,
    List<GalleryImage>? images,
    List<String>? materials,
    List<String>? tools,
    List<String>? steps,
    List<String>? videoLinks,
    int? likesCount,
    bool? likedByMe,
    DateTime? publishedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
    GalleryAuthor? author,
    int? materialsCount,
    int? stepsCount,
    GalleryWorkStatus? status,
    String? rejectionReason,
    bool clearRejectionReason = false,
  }) {
    return GalleryWork(
      id: id ?? this.id,
      title: title ?? this.title,
      difficulty: difficulty ?? this.difficulty,
      coverImageUrl: coverImageUrl ?? this.coverImageUrl,
      images: images ?? this.images,
      materials: materials ?? this.materials,
      tools: tools ?? this.tools,
      steps: steps ?? this.steps,
      videoLinks: videoLinks ?? this.videoLinks,
      likesCount: likesCount ?? this.likesCount,
      likedByMe: likedByMe ?? this.likedByMe,
      publishedAt: publishedAt ?? this.publishedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      author: author ?? this.author,
      materialsCount: materialsCount ?? this.materialsCount,
      stepsCount: stepsCount ?? this.stepsCount,
      status: status ?? this.status,
      rejectionReason: clearRejectionReason
          ? null
          : (rejectionReason ?? this.rejectionReason),
    );
  }

  factory GalleryWork.fromJson(Map<String, dynamic> json) {
    final rawImages = json['images'];
    final parsedImages = <GalleryImage>[];
    if (rawImages is List) {
      for (final item in rawImages) {
        if (item is Map<String, dynamic>) {
          parsedImages.add(GalleryImage.fromJson(item));
        } else if (item is Map) {
          parsedImages.add(
            GalleryImage.fromJson(Map<String, dynamic>.from(item)),
          );
        }
      }
      parsedImages.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    }

    final materials = _parseStringList(json['materials']);
    final tools = _parseStringList(json['tools']);
    final steps = _parseStringList(json['steps']);
    final videoLinks = _parseStringList(json['video_links']);

    final rawCover = json['cover_image_url']?.toString().trim();
    final cover = (rawCover != null && rawCover.isNotEmpty)
        ? rawCover
        : (parsedImages.isNotEmpty ? parsedImages.first.url : null);

    final rawAuthor = json['author'];
    final authorMap = rawAuthor is Map<String, dynamic>
        ? rawAuthor
        : (rawAuthor is Map ? Map<String, dynamic>.from(rawAuthor) : null);

    final rawRejection = json['rejection_reason']?.toString().trim();

    return GalleryWork(
      id: _parseInt(json['id']) ?? 0,
      title: (json['title']?.toString() ?? '').trim(),
      difficulty: GalleryDifficulty.fromString(json['difficulty']?.toString()),
      coverImageUrl: cover,
      images: parsedImages,
      materials: materials,
      tools: tools,
      steps: steps,
      videoLinks: videoLinks,
      likesCount: _parseInt(json['likes_count']) ?? 0,
      likedByMe: _parseBool(json['liked_by_me']),
      publishedAt: _parseDate(json['published_at']),
      createdAt: _parseDate(json['created_at']),
      updatedAt: _parseDate(json['updated_at']),
      author: GalleryAuthor.fromJson(authorMap),
      materialsCount: _parseInt(json['materials_count']) ?? materials.length,
      stepsCount: _parseInt(json['steps_count']) ?? steps.length,
      status: GalleryWorkStatus.fromString(json['status']?.toString()),
      rejectionReason:
          (rawRejection != null && rawRejection.isNotEmpty) ? rawRejection : null,
    );
  }
}

class GalleryPage {
  final List<GalleryWork> items;
  final int currentPage;
  final int lastPage;
  final int perPage;
  final int total;

  const GalleryPage({
    required this.items,
    required this.currentPage,
    required this.lastPage,
    required this.perPage,
    required this.total,
  });

  bool get hasMore => currentPage < lastPage;
}

class GalleryLikeResult {
  final bool liked;
  final int likesCount;

  const GalleryLikeResult({
    required this.liked,
    required this.likesCount,
  });

  factory GalleryLikeResult.fromJson(Map<String, dynamic> json) {
    return GalleryLikeResult(
      liked: _parseBool(json['liked']),
      likesCount: _parseInt(json['likes_count']) ?? 0,
    );
  }
}

/// Draft used to prefill `CreateGalleryWorkScreen` (e.g., from an AI UpcyclingIdea).
///
/// Intentionally does NOT carry any image path — users must always upload photos
/// of their own finished creation.
class GalleryWorkDraft {
  final String title;
  final GalleryDifficulty difficulty;
  final List<String> materials;
  final List<String> tools;
  final List<String> steps;
  final List<String> videoLinks;

  const GalleryWorkDraft({
    this.title = '',
    this.difficulty = GalleryDifficulty.mudah,
    this.materials = const [],
    this.tools = const [],
    this.steps = const [],
    this.videoLinks = const [],
  });

  factory GalleryWorkDraft.fromUpcyclingIdea(
    UpcyclingIdea idea,
    PlasticAnalysisResult result,
  ) {
    final difficulty = GalleryDifficulty.fromString(idea.difficulty);

    // Build materials from matched PlasticAnalysisResult components
    final materials = <String>[];
    final seenMaterials = <String>{};

    void addMaterial(String text) {
      final cleaned = text.trim();
      if (cleaned.isEmpty) return;
      final key = cleaned.toLowerCase();
      if (seenMaterials.add(key)) {
        materials.add(cleaned);
      }
    }

    if (result.components.isNotEmpty) {
      final matched = idea.componentIds.isNotEmpty
          ? result.components
              .where((c) => idea.componentIds.contains(c.id))
              .toList()
          : result.components;

      final source = matched.isNotEmpty ? matched : result.components;
      for (final comp in source) {
        final hasType = comp.materialType.trim().isNotEmpty &&
            comp.materialType.trim().toLowerCase() != 'uncertain';
        final label = hasType
            ? '${comp.partName} (${comp.materialType.trim()})'
            : comp.partName;
        addMaterial(label);
      }
    } else {
      final fallback = (result.objectName ?? result.materialTitle).trim();
      if (fallback.isNotEmpty) {
        addMaterial(fallback);
      }
    }

    // Conservatively split comma/semicolon/newline tools string
    final tools = _splitTools(idea.tools);

    // Conservatively split numbered or newline-separated steps
    final steps = _splitSteps(idea.steps);

    return GalleryWorkDraft(
      title: idea.title.trim(),
      difficulty: difficulty,
      materials: materials,
      tools: tools,
      steps: steps,
      videoLinks: const [],
    );
  }

  static List<String> _splitTools(String? raw) {
    if (raw == null || raw.trim().isEmpty) return const [];
    final parts = raw.split(RegExp(r'[,;\n]+'));
    final out = <String>[];
    for (final p in parts) {
      final cleaned = p
          .replaceFirst(RegExp(r'^[\s\-•*]+'), '')
          .trim();
      if (cleaned.isNotEmpty) {
        out.add(cleaned);
      }
    }
    return out;
  }

  static List<String> _splitSteps(String? raw) {
    if (raw == null || raw.trim().isEmpty) return const [];
    final text = raw.trim();

    // Case 1: Inline or multiline numbered steps like "1. ... 2. ..." or "1) ... 2) ..."
    final numberedMatches = RegExp(r'(?:^|\s)(\d+[\.\)])\s+').allMatches(text);
    if (numberedMatches.length >= 2) {
      final splitParts = text.split(RegExp(r'(?:^|\s+)\d+[\.\)]\s+'));
      final out = splitParts
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();
      if (out.isNotEmpty) return out;
    }

    // Case 2: Newline-separated lines
    if (text.contains('\n')) {
      final out = text
          .split('\n')
          .map(
            (line) => line
                .replaceFirst(RegExp(r'^\s*(?:\d+[\.\)]|[-•*])\s*'), '')
                .trim(),
          )
          .where((s) => s.isNotEmpty)
          .toList();
      if (out.isNotEmpty) return out;
    }

    // Fallback: single conservative step (strip single leading "1. " if present)
    final single = text.replaceFirst(RegExp(r'^\s*\d+[\.\)]\s+'), '').trim();
    return single.isNotEmpty ? [single] : const [];
  }
}

int? _parseInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value.trim());
  return null;
}

bool _parseBool(dynamic value) {
  if (value is bool) return value;
  if (value is int) return value != 0;
  if (value is String) {
    final v = value.trim().toLowerCase();
    return v == 'true' || v == '1' || v == 'yes';
  }
  return false;
}

DateTime? _parseDate(dynamic value) {
  if (value is String && value.trim().isNotEmpty) {
    return DateTime.tryParse(value.trim());
  }
  return null;
}

List<String> _parseStringList(dynamic value) {
  if (value is! List) return const [];
  return value
      .map((e) => e?.toString().trim() ?? '')
      .where((e) => e.isNotEmpty)
      .toList();
}
