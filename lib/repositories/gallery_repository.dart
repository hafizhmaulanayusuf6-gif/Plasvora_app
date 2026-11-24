import '../core/network/api_client.dart';
import '../core/network/api_config.dart';
import '../models/gallery_work.dart';

abstract class GalleryRepository {
  Future<GalleryPage> fetchGallery({
    String? query,
    GalleryDifficulty? difficulty,
    String sort = 'latest',
    int page = 1,
    int perPage = 12,
  });

  Future<GalleryWork> fetchWorkDetail(int id);

  Future<GalleryPage> fetchMyWorks({
    int page = 1,
    int perPage = 12,
  });

  Future<GalleryWork> createWork({
    required String title,
    required GalleryDifficulty difficulty,
    required List<String> materials,
    List<String> tools = const [],
    required List<String> steps,
    List<String> videoLinks = const [],
    required List<String> imagePaths,
    required bool ownershipConfirmed,
  });

  Future<GalleryWork> updateWork({
    required int id,
    required String title,
    required GalleryDifficulty difficulty,
    required List<String> materials,
    List<String> tools = const [],
    required List<String> steps,
    List<String> videoLinks = const [],
    List<String> newImagePaths = const [],
    List<int> removeImageIds = const [],
  });

  Future<void> deleteWork(int id);

  Future<GalleryLikeResult> toggleLike(int id);
}

class ApiGalleryRepository implements GalleryRepository {
  final ApiClient apiClient;

  ApiGalleryRepository({required this.apiClient});

  @override
  Future<GalleryPage> fetchGallery({
    String? query,
    GalleryDifficulty? difficulty,
    String sort = 'latest',
    int page = 1,
    int perPage = 12,
  }) async {
    final params = <String, String>{
      'sort': sort,
      'page': page.toString(),
      'per_page': perPage.toString(),
    };
    if (query != null && query.trim().isNotEmpty) {
      params['q'] = query.trim();
    }
    if (difficulty != null) {
      params['difficulty'] = difficulty.apiValue;
    }

    final uri = Uri.parse(ApiConfig.gallery).replace(queryParameters: params);
    // Optional auth: send bearer token if logged in so `liked_by_me` is accurate
    final response = await apiClient.get(uri.toString(), requiresAuth: true);
    return _parsePage(response);
  }

  @override
  Future<GalleryWork> fetchWorkDetail(int id) async {
    final response = await apiClient.get(
      ApiConfig.galleryDetail(id),
      requiresAuth: true,
    );
    return _parseSingleWork(response);
  }

  @override
  Future<GalleryPage> fetchMyWorks({
    int page = 1,
    int perPage = 12,
  }) async {
    final uri = Uri.parse(ApiConfig.myGallery).replace(queryParameters: {
      'page': page.toString(),
      'per_page': perPage.toString(),
    });
    final response = await apiClient.get(uri.toString(), requiresAuth: true);
    return _parsePage(response);
  }

  @override
  Future<GalleryWork> createWork({
    required String title,
    required GalleryDifficulty difficulty,
    required List<String> materials,
    List<String> tools = const [],
    required List<String> steps,
    List<String> videoLinks = const [],
    required List<String> imagePaths,
    required bool ownershipConfirmed,
  }) async {
    final fields = <String, String>{
      'title': title.trim(),
      'difficulty': difficulty.apiValue,
      'ownership_confirmed': ownershipConfirmed ? '1' : '0',
    };

    final arrayFields = <String, List<String>>{
      'materials': materials.map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
      'steps': steps.map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
    };

    final cleanedTools = tools.map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    if (cleanedTools.isNotEmpty) {
      arrayFields['tools'] = cleanedTools;
    }

    final cleanedVideos = videoLinks.map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    if (cleanedVideos.isNotEmpty) {
      arrayFields['video_links'] = cleanedVideos;
    }

    final response = await apiClient.postMultipartForm(
      ApiConfig.gallery,
      fields: fields,
      arrayFields: arrayFields,
      fileField: 'images[]',
      filePaths: imagePaths,
      requiresAuth: true,
    );
    return _parseSingleWork(response);
  }

  @override
  Future<GalleryWork> updateWork({
    required int id,
    required String title,
    required GalleryDifficulty difficulty,
    required List<String> materials,
    List<String> tools = const [],
    required List<String> steps,
    List<String> videoLinks = const [],
    List<String> newImagePaths = const [],
    List<int> removeImageIds = const [],
  }) async {
    final cleanedMaterials =
        materials.map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    final cleanedTools =
        tools.map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    final cleanedSteps =
        steps.map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    final cleanedVideos =
        videoLinks.map((e) => e.trim()).where((e) => e.isNotEmpty).toList();

    final fields = <String, String>{
      '_method': 'PATCH',
      'title': title.trim(),
      'difficulty': difficulty.apiValue,
      if (cleanedTools.isEmpty) 'clear_tools': '1',
      if (cleanedVideos.isEmpty) 'clear_video_links': '1',
    };

    final arrayFields = <String, List<String>>{
      'materials': cleanedMaterials,
      'steps': cleanedSteps,
      if (cleanedTools.isNotEmpty) 'tools': cleanedTools,
      if (cleanedVideos.isNotEmpty) 'video_links': cleanedVideos,
      if (removeImageIds.isNotEmpty)
        'remove_image_ids': removeImageIds.map((e) => e.toString()).toList(),
    };

    final response = await apiClient.postMultipartForm(
      ApiConfig.galleryDetail(id),
      fields: fields,
      arrayFields: arrayFields,
      fileField: 'images[]',
      filePaths: newImagePaths,
      requiresAuth: true,
    );
    return _parseSingleWork(response);
  }

  @override
  Future<void> deleteWork(int id) async {
    await apiClient.delete(ApiConfig.galleryDetail(id), requiresAuth: true);
  }

  @override
  Future<GalleryLikeResult> toggleLike(int id) async {
    final response = await apiClient.post(
      ApiConfig.galleryLike(id),
      requiresAuth: true,
    );
    if (response is Map<String, dynamic> && response['data'] is Map) {
      return GalleryLikeResult.fromJson(
        Map<String, dynamic>.from(response['data'] as Map),
      );
    }
    throw ApiException('Format respons like tidak valid.');
  }

  GalleryPage _parsePage(dynamic response) {
    if (response is! Map) {
      throw ApiException('Format respons galeri tidak valid.');
    }
    final map = Map<String, dynamic>.from(response);
    final rawData = map['data'];
    final items = <GalleryWork>[];
    if (rawData is List) {
      for (final item in rawData) {
        if (item is Map<String, dynamic>) {
          items.add(GalleryWork.fromJson(item));
        } else if (item is Map) {
          items.add(GalleryWork.fromJson(Map<String, dynamic>.from(item)));
        }
      }
    }

    final rawMeta = map['meta'] is Map
        ? Map<String, dynamic>.from(map['meta'] as Map)
        : <String, dynamic>{};

    return GalleryPage(
      items: items,
      currentPage: _asInt(rawMeta['current_page'], 1),
      lastPage: _asInt(rawMeta['last_page'], 1),
      perPage: _asInt(rawMeta['per_page'], 12),
      total: _asInt(rawMeta['total'], items.length),
    );
  }

  GalleryWork _parseSingleWork(dynamic response) {
    if (response is Map && response['data'] is Map) {
      return GalleryWork.fromJson(
        Map<String, dynamic>.from(response['data'] as Map),
      );
    }
    throw ApiException('Format respons detail karya tidak valid.');
  }

  int _asInt(dynamic value, int fallback) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? fallback;
    return fallback;
  }
}

/// Realistic in-memory repository for offline/demo mode and widget/unit tests.
class MockGalleryRepository implements GalleryRepository {
  final List<GalleryWork> _works;
  int _nextId;
  int _nextImageId;
  int currentUserId;
  String currentUserName;

  MockGalleryRepository({
    List<GalleryWork>? initialWorks,
    this.currentUserId = 1,
    this.currentUserName = 'Rina Kartika',
  })  : _works = List<GalleryWork>.from(initialWorks ?? _defaultWorks()),
        _nextId = 100,
        _nextImageId = 1000;

  static List<GalleryWork> _defaultWorks() {
    final now = DateTime.now();
    return [
      GalleryWork(
        id: 1,
        title: 'Pot Hidroponik Mini dari Botol PET',
        difficulty: GalleryDifficulty.mudah,
        materials: const [
          'Botol plastik PET 1,5 liter bekas',
          'Kain flanel bekas untuk sumbu',
          'Media tanam sekam bakar',
        ],
        tools: const ['Cutter', 'Gunting', 'Spidol'],
        steps: const [
          'Cuci botol hingga bersih lalu lepas label.',
          'Potong botol menjadi dua bagian dan balik bagian atasnya.',
          'Pasang sumbu kain flanel melalui lubang tutup botol.',
          'Isi air di bawah dan media tanam di bagian atas.',
        ],
        videoLinks: const ['https://www.youtube.com/watch?v=dQw4w9WgXcQ'],
        likesCount: 12,
        likedByMe: false,
        publishedAt: now.subtract(const Duration(days: 1)),
        createdAt: now.subtract(const Duration(days: 1)),
        author: const GalleryAuthor(id: 2, name: 'Budi Santoso'),
        materialsCount: 3,
        stepsCount: 4,
        status: GalleryWorkStatus.approved,
      ),
      GalleryWork(
        id: 2,
        title: 'Lampu Hias Gantung Bunga Botol Bekas',
        difficulty: GalleryDifficulty.menengah,
        materials: const [
          '3 botol plastik PET bening',
          'Lampu LED USB hangat',
          'Kawat tipis',
        ],
        tools: const ['Gunting', 'Lem tembak', 'Cat akrilik'],
        steps: const [
          'Potong bagian bawah botol membentuk kelopak bunga.',
          'Haluskan tepi potongan dan warnai dengan cat akrilik tipis.',
          'Rangkai kelopak mengelilingi kabel lampu LED.',
        ],
        videoLinks: const [],
        likesCount: 25,
        likedByMe: true,
        publishedAt: now.subtract(const Duration(days: 2)),
        createdAt: now.subtract(const Duration(days: 2)),
        author: const GalleryAuthor(id: 1, name: 'Rina Kartika'),
        materialsCount: 3,
        stepsCount: 3,
        status: GalleryWorkStatus.approved,
      ),
      GalleryWork(
        id: 3,
        title: 'Dompet Anyaman Kemasan Sachet Kopi',
        difficulty: GalleryDifficulty.sulit,
        materials: const ['20 lembar kemasan sachet kopi bersih', 'Resleting 18 cm'],
        tools: const ['Gunting', 'Penggaris', 'Jarum dan benang nilon'],
        steps: const [
          'Potong dan lipat setiap sachet menjadi strip selebar 2 cm.',
          'Anyam strip membentuk lembaran kokoh.',
          'Jahit tepian dan pasang resleting dengan rapi.',
        ],
        videoLinks: const ['https://youtu.be/dQw4w9WgXcQ'],
        likesCount: 8,
        likedByMe: false,
        publishedAt: now.subtract(const Duration(days: 3)),
        createdAt: now.subtract(const Duration(days: 3)),
        author: const GalleryAuthor(id: 3, name: 'Dedi Prasetyo'),
        materialsCount: 2,
        stepsCount: 3,
        status: GalleryWorkStatus.approved,
      ),
    ];
  }

  @override
  Future<GalleryPage> fetchGallery({
    String? query,
    GalleryDifficulty? difficulty,
    String sort = 'latest',
    int page = 1,
    int perPage = 12,
  }) async {
    var list = _works.where((w) => w.status == GalleryWorkStatus.approved).toList();

    if (query != null && query.trim().isNotEmpty) {
      final q = query.trim().toLowerCase();
      list = list.where((w) => w.title.toLowerCase().contains(q)).toList();
    }

    if (difficulty != null) {
      list = list.where((w) => w.difficulty == difficulty).toList();
    }

    if (sort == 'popular') {
      list.sort((a, b) => b.likesCount.compareTo(a.likesCount));
    } else {
      list.sort((a, b) {
        final aDate = a.publishedAt ?? a.createdAt ?? DateTime(2000);
        final bDate = b.publishedAt ?? b.createdAt ?? DateTime(2000);
        return bDate.compareTo(aDate);
      });
    }

    return _paginate(list, page: page, perPage: perPage);
  }

  @override
  Future<GalleryWork> fetchWorkDetail(int id) async {
    final idx = _works.indexWhere((w) => w.id == id);
    if (idx == -1) {
      throw ApiException('Karya galeri tidak ditemukan.', statusCode: 404);
    }
    final work = _works[idx];
    if (work.status != GalleryWorkStatus.approved &&
        work.author.id != currentUserId) {
      throw ApiException('Karya galeri tidak ditemukan.', statusCode: 404);
    }
    return work;
  }

  @override
  Future<GalleryPage> fetchMyWorks({int page = 1, int perPage = 12}) async {
    final list = _works.where((w) => w.author.id == currentUserId).toList()
      ..sort((a, b) => b.id.compareTo(a.id));
    return _paginate(list, page: page, perPage: perPage);
  }

  @override
  Future<GalleryWork> createWork({
    required String title,
    required GalleryDifficulty difficulty,
    required List<String> materials,
    List<String> tools = const [],
    required List<String> steps,
    List<String> videoLinks = const [],
    required List<String> imagePaths,
    required bool ownershipConfirmed,
  }) async {
    final id = _nextId++;
    final images = <GalleryImage>[];
    for (var i = 0; i < imagePaths.length; i++) {
      images.add(GalleryImage(
        id: _nextImageId++,
        url: imagePaths[i],
        sortOrder: i,
      ));
    }
    final now = DateTime.now();
    final work = GalleryWork(
      id: id,
      title: title.trim(),
      difficulty: difficulty,
      coverImageUrl: images.isNotEmpty ? images.first.url : null,
      images: images,
      materials: List<String>.from(materials),
      tools: List<String>.from(tools),
      steps: List<String>.from(steps),
      videoLinks: List<String>.from(videoLinks),
      likesCount: 0,
      likedByMe: false,
      publishedAt: now,
      createdAt: now,
      updatedAt: now,
      author: GalleryAuthor(id: currentUserId, name: currentUserName),
      materialsCount: materials.length,
      stepsCount: steps.length,
      status: GalleryWorkStatus.approved,
    );
    _works.insert(0, work);
    return work;
  }

  @override
  Future<GalleryWork> updateWork({
    required int id,
    required String title,
    required GalleryDifficulty difficulty,
    required List<String> materials,
    List<String> tools = const [],
    required List<String> steps,
    List<String> videoLinks = const [],
    List<String> newImagePaths = const [],
    List<int> removeImageIds = const [],
  }) async {
    final idx = _works.indexWhere((w) => w.id == id);
    if (idx == -1) {
      throw ApiException('Karya galeri tidak ditemukan.', statusCode: 404);
    }
    final current = _works[idx];
    final keptImages = current.images
        .where((img) => !removeImageIds.contains(img.id))
        .toList();
    final updatedImages = <GalleryImage>[];
    for (var i = 0; i < keptImages.length; i++) {
      updatedImages.add(GalleryImage(
        id: keptImages[i].id,
        url: keptImages[i].url,
        sortOrder: i,
      ));
    }
    for (final path in newImagePaths) {
      updatedImages.add(GalleryImage(
        id: _nextImageId++,
        url: path,
        sortOrder: updatedImages.length,
      ));
    }

    final updated = current.copyWith(
      title: title.trim(),
      difficulty: difficulty,
      coverImageUrl: updatedImages.isNotEmpty ? updatedImages.first.url : null,
      images: updatedImages,
      materials: List<String>.from(materials),
      tools: List<String>.from(tools),
      steps: List<String>.from(steps),
      videoLinks: List<String>.from(videoLinks),
      materialsCount: materials.length,
      stepsCount: steps.length,
      publishedAt: current.isApproved
          ? (current.publishedAt ?? DateTime.now())
          : current.publishedAt,
      updatedAt: DateTime.now(),
    );
    _works[idx] = updated;
    return updated;
  }

  @override
  Future<void> deleteWork(int id) async {
    _works.removeWhere((w) => w.id == id);
  }

  @override
  Future<GalleryLikeResult> toggleLike(int id) async {
    final idx = _works.indexWhere((w) => w.id == id);
    if (idx == -1) {
      throw ApiException('Karya galeri tidak ditemukan.', statusCode: 404);
    }
    final current = _works[idx];
    final nextLiked = !current.likedByMe;
    final nextCount =
        nextLiked ? current.likesCount + 1 : (current.likesCount - 1).clamp(0, 1 << 30);
    _works[idx] = current.copyWith(
      likedByMe: nextLiked,
      likesCount: nextCount,
    );
    return GalleryLikeResult(liked: nextLiked, likesCount: nextCount);
  }

  GalleryPage _paginate(
    List<GalleryWork> list, {
    required int page,
    required int perPage,
  }) {
    final safePerPage = perPage < 1 ? 12 : perPage;
    final total = list.length;
    final lastPage = total == 0 ? 1 : ((total + safePerPage - 1) ~/ safePerPage);
    final safePage = page < 1 ? 1 : page;
    final start = (safePage - 1) * safePerPage;
    final items = start >= total
        ? <GalleryWork>[]
        : list.sublist(start, (start + safePerPage).clamp(0, total));

    return GalleryPage(
      items: items,
      currentPage: safePage,
      lastPage: lastPage,
      perPage: safePerPage,
      total: total,
    );
  }
}
