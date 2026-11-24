import 'package:flutter/foundation.dart';

import '../core/network/api_client.dart';
import '../models/gallery_work.dart';
import '../repositories/gallery_repository.dart';

class GalleryViewModel extends ChangeNotifier {
  final GalleryRepository galleryRepository;

  GalleryViewModel({required this.galleryRepository});

  // ─── Public Feed State ────────────────────────────────────────────
  List<GalleryWork> _works = [];
  bool _isLoadingFeed = false;
  bool _isLoadingMoreFeed = false;
  bool _hasLoadedFeed = false;
  String? _feedError;
  int _feedPage = 1;
  int _feedLastPage = 1;
  String _searchQuery = '';
  GalleryDifficulty? _selectedDifficulty;
  String _sortBy = 'latest';
  int _feedRequestVersion = 0;

  List<GalleryWork> get works => List.unmodifiable(_works);
  bool get isLoadingFeed => _isLoadingFeed;
  bool get isLoadingMoreFeed => _isLoadingMoreFeed;
  bool get hasLoadedFeed => _hasLoadedFeed;
  String? get feedError => _feedError;
  bool get hasMoreFeed => _feedPage < _feedLastPage;
  String get searchQuery => _searchQuery;
  GalleryDifficulty? get selectedDifficulty => _selectedDifficulty;
  String get sortBy => _sortBy;
  bool get hasActiveFilters =>
      _searchQuery.trim().isNotEmpty || _selectedDifficulty != null;

  // ─── Detail Cache State ───────────────────────────────────────────
  final Map<int, GalleryWork> _detailCache = {};
  final Set<int> _loadingDetailIds = {};
  final Map<int, String> _detailErrors = {};
  final Map<int, int> _detailStatusCodes = {};
  final Map<int, int> _detailRequestVersions = {};

  GalleryWork? getCachedDetail(int id) => _detailCache[id];
  bool isLoadingDetail(int id) => _loadingDetailIds.contains(id);
  String? getDetailError(int id) => _detailErrors[id];
  int? getDetailStatusCode(int id) => _detailStatusCodes[id];

  // ─── My Works State ───────────────────────────────────────────────
  List<GalleryWork> _myWorks = [];
  bool _isLoadingMyWorks = false;
  bool _isLoadingMoreMyWorks = false;
  bool _hasLoadedMyWorks = false;
  String? _myWorksError;
  int _myWorksPage = 1;
  int _myWorksLastPage = 1;
  int _myWorksRequestVersion = 0;

  List<GalleryWork> get myWorks => List.unmodifiable(_myWorks);
  bool get isLoadingMyWorks => _isLoadingMyWorks;
  bool get isLoadingMoreMyWorks => _isLoadingMoreMyWorks;
  bool get hasLoadedMyWorks => _hasLoadedMyWorks;
  String? get myWorksError => _myWorksError;
  bool get hasMoreMyWorks => _myWorksPage < _myWorksLastPage;

  // ─── Mutation / Action Guards ─────────────────────────────────────
  bool _isSubmitting = false;
  String? _submitError;
  Map<String, String> _fieldErrors = {};
  final Set<int> _likingWorkIds = {};
  final Set<int> _deletingWorkIds = {};

  bool get isSubmitting => _isSubmitting;
  String? get submitError => _submitError;
  Map<String, String> get fieldErrors => Map.unmodifiable(_fieldErrors);
  bool isLiking(int id) => _likingWorkIds.contains(id);
  bool isDeleting(int id) => _deletingWorkIds.contains(id);

  // ─── Public Feed Operations ───────────────────────────────────────

  Future<void> loadFeed({bool refresh = false}) async {
    if (_isLoadingFeed && !refresh) return;

    final requestVersion = ++_feedRequestVersion;
    _isLoadingFeed = true;
    _feedError = null;
    notifyListeners();

    try {
      final result = await galleryRepository.fetchGallery(
        query: _searchQuery,
        difficulty: _selectedDifficulty,
        sort: _sortBy,
        page: 1,
      );

      if (requestVersion != _feedRequestVersion) return;

      _works = result.items;
      _feedPage = result.currentPage;
      _feedLastPage = result.lastPage;
      _hasLoadedFeed = true;
      _feedError = null;
    } on ApiException catch (e) {
      if (requestVersion != _feedRequestVersion) return;
      _feedError = e.message;
    } catch (_) {
      if (requestVersion != _feedRequestVersion) return;
      _feedError = 'Gagal memuat Galeri Karya. Silakan coba lagi.';
    } finally {
      if (requestVersion == _feedRequestVersion) {
        _isLoadingFeed = false;
        notifyListeners();
      }
    }
  }

  Future<void> loadMoreFeed() async {
    if (_isLoadingFeed || _isLoadingMoreFeed || !hasMoreFeed) return;

    final requestVersion = _feedRequestVersion;
    _isLoadingMoreFeed = true;
    notifyListeners();

    try {
      final result = await galleryRepository.fetchGallery(
        query: _searchQuery,
        difficulty: _selectedDifficulty,
        sort: _sortBy,
        page: _feedPage + 1,
      );

      if (requestVersion != _feedRequestVersion) return;

      final existingIds = _works.map((e) => e.id).toSet();
      final appended =
          result.items.where((e) => !existingIds.contains(e.id)).toList();
      _works = [..._works, ...appended];
      _feedPage = result.currentPage;
      _feedLastPage = result.lastPage;
    } on ApiException catch (e) {
      if (requestVersion != _feedRequestVersion) return;
      _feedError = e.message;
    } catch (_) {
      if (requestVersion != _feedRequestVersion) return;
      _feedError = 'Gagal memuat halaman berikutnya.';
    } finally {
      if (requestVersion == _feedRequestVersion) {
        _isLoadingMoreFeed = false;
        notifyListeners();
      }
    }
  }

  Future<void> setSearchQuery(String query) async {
    final normalized = query.trim();
    if (_searchQuery == normalized && _hasLoadedFeed) return;
    _searchQuery = normalized;
    _feedPage = 1;
    _feedLastPage = 1;
    await loadFeed(refresh: true);
  }

  Future<void> setDifficulty(GalleryDifficulty? difficulty) async {
    if (_selectedDifficulty == difficulty && _hasLoadedFeed) return;
    _selectedDifficulty = difficulty;
    _feedPage = 1;
    _feedLastPage = 1;
    await loadFeed(refresh: true);
  }

  Future<void> setSortBy(String sort) async {
    final normalized = sort == 'popular' ? 'popular' : 'latest';
    if (_sortBy == normalized && _hasLoadedFeed) return;
    _sortBy = normalized;
    _feedPage = 1;
    _feedLastPage = 1;
    await loadFeed(refresh: true);
  }

  Future<void> clearFilters() async {
    _searchQuery = '';
    _selectedDifficulty = null;
    _feedPage = 1;
    _feedLastPage = 1;
    await loadFeed(refresh: true);
  }

  // ─── Detail Operations ────────────────────────────────────────────

  Future<GalleryWork?> loadWorkDetail(int id, {bool forceRefresh = false}) async {
    if (!forceRefresh && _loadingDetailIds.contains(id)) {
      return _detailCache[id];
    }

    final version = (_detailRequestVersions[id] ?? 0) + 1;
    _detailRequestVersions[id] = version;
    _loadingDetailIds.add(id);
    _detailErrors.remove(id);
    _detailStatusCodes.remove(id);
    notifyListeners();

    try {
      final detail = await galleryRepository.fetchWorkDetail(id);
      if (_detailRequestVersions[id] != version) return null;

      _detailCache[id] = detail;
      _syncWorkAcrossLists(detail);
      return detail;
    } on ApiException catch (e) {
      if (_detailRequestVersions[id] != version) return null;
      _detailErrors[id] = e.message;
      if (e.statusCode != null) {
        _detailStatusCodes[id] = e.statusCode!;
      }
      return null;
    } catch (_) {
      if (_detailRequestVersions[id] != version) return null;
      _detailErrors[id] = 'Gagal memuat detail karya.';
      return null;
    } finally {
      if (_detailRequestVersions[id] == version) {
        _loadingDetailIds.remove(id);
        notifyListeners();
      }
    }
  }

  // ─── My Works Operations ──────────────────────────────────────────

  Future<void> loadMyWorks({bool refresh = false}) async {
    if (_isLoadingMyWorks && !refresh) return;

    final requestVersion = ++_myWorksRequestVersion;
    _isLoadingMyWorks = true;
    _myWorksError = null;
    notifyListeners();

    try {
      final result = await galleryRepository.fetchMyWorks(page: 1);
      if (requestVersion != _myWorksRequestVersion) return;

      _myWorks = result.items;
      _myWorksPage = result.currentPage;
      _myWorksLastPage = result.lastPage;
      _hasLoadedMyWorks = true;
      _myWorksError = null;
    } on ApiException catch (e) {
      if (requestVersion != _myWorksRequestVersion) return;
      _myWorksError = e.message;
    } catch (_) {
      if (requestVersion != _myWorksRequestVersion) return;
      _myWorksError = 'Gagal memuat daftar karya Anda.';
    } finally {
      if (requestVersion == _myWorksRequestVersion) {
        _isLoadingMyWorks = false;
        notifyListeners();
      }
    }
  }

  Future<void> loadMoreMyWorks() async {
    if (_isLoadingMyWorks || _isLoadingMoreMyWorks || !hasMoreMyWorks) return;

    final requestVersion = _myWorksRequestVersion;
    _isLoadingMoreMyWorks = true;
    notifyListeners();

    try {
      final result = await galleryRepository.fetchMyWorks(
        page: _myWorksPage + 1,
      );
      if (requestVersion != _myWorksRequestVersion) return;

      final existingIds = _myWorks.map((e) => e.id).toSet();
      final appended =
          result.items.where((e) => !existingIds.contains(e.id)).toList();
      _myWorks = [..._myWorks, ...appended];
      _myWorksPage = result.currentPage;
      _myWorksLastPage = result.lastPage;
    } on ApiException catch (e) {
      if (requestVersion != _myWorksRequestVersion) return;
      _myWorksError = e.message;
    } catch (_) {
      if (requestVersion != _myWorksRequestVersion) return;
      _myWorksError = 'Gagal memuat karya berikutnya.';
    } finally {
      if (requestVersion == _myWorksRequestVersion) {
        _isLoadingMoreMyWorks = false;
        notifyListeners();
      }
    }
  }

  // ─── Create / Update / Delete ─────────────────────────────────────

  void clearSubmitErrors() {
    _submitError = null;
    _fieldErrors = {};
    notifyListeners();
  }

  Future<GalleryWork?> createWork({
    required String title,
    required GalleryDifficulty difficulty,
    required List<String> materials,
    List<String> tools = const [],
    required List<String> steps,
    List<String> videoLinks = const [],
    required List<String> imagePaths,
    required bool ownershipConfirmed,
  }) async {
    if (_isSubmitting) return null;

    _isSubmitting = true;
    _submitError = null;
    _fieldErrors = {};
    notifyListeners();

    try {
      final created = await galleryRepository.createWork(
        title: title,
        difficulty: difficulty,
        materials: materials,
        tools: tools,
        steps: steps,
        videoLinks: videoLinks,
        imagePaths: imagePaths,
        ownershipConfirmed: ownershipConfirmed,
      );
      _detailCache[created.id] = created;
      _myWorks = [created, ..._myWorks.where((w) => w.id != created.id)];
      _hasLoadedMyWorks = true;
      if (created.isApproved && _hasLoadedFeed) {
        await loadFeed(refresh: true);
      }
      return created;
    } on ApiException catch (e) {
      _submitError = e.message;
      _fieldErrors = _extractFieldErrors(e.errors);
      return null;
    } catch (_) {
      _submitError = 'Gagal mengirim karya. Silakan coba lagi.';
      return null;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  Future<GalleryWork?> updateWork({
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
    if (_isSubmitting) return null;

    _isSubmitting = true;
    _submitError = null;
    _fieldErrors = {};
    notifyListeners();

    try {
      final updated = await galleryRepository.updateWork(
        id: id,
        title: title,
        difficulty: difficulty,
        materials: materials,
        tools: tools,
        steps: steps,
        videoLinks: videoLinks,
        newImagePaths: newImagePaths,
        removeImageIds: removeImageIds,
      );
      _detailCache[updated.id] = updated;
      if (updated.isApproved) {
        _syncWorkAcrossLists(updated);
      } else {
        _works = _works.where((w) => w.id != updated.id).toList();
      }
      _myWorks = [
        updated,
        ..._myWorks.where((w) => w.id != updated.id),
      ];
      return updated;
    } on ApiException catch (e) {
      _submitError = e.message;
      _fieldErrors = _extractFieldErrors(e.errors);
      return null;
    } catch (_) {
      _submitError = 'Gagal memperbarui karya. Silakan coba lagi.';
      return null;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  Future<String?> deleteWork(int id) async {
    if (_deletingWorkIds.contains(id)) return null;

    _deletingWorkIds.add(id);
    notifyListeners();

    try {
      await galleryRepository.deleteWork(id);
      _works = _works.where((w) => w.id != id).toList();
      _myWorks = _myWorks.where((w) => w.id != id).toList();
      _detailCache.remove(id);
      return null;
    } on ApiException catch (e) {
      return e.message;
    } catch (_) {
      return 'Gagal menghapus karya. Silakan coba lagi.';
    } finally {
      _deletingWorkIds.remove(id);
      notifyListeners();
    }
  }

  // ─── Optimistic Like Toggle with Rollback ─────────────────────────

  /// Toggles like optimistically across feed, detail cache, and myWorks.
  /// Returns an error message on failure (after rolling back), or `null` on success.
  Future<String?> toggleLike(int id) async {
    if (_likingWorkIds.contains(id)) return null;

    final current = _findWork(id);
    if (current == null) return null;

    final previousLiked = current.likedByMe;
    final previousCount = current.likesCount;

    final optimisticLiked = !previousLiked;
    final optimisticCount = optimisticLiked
        ? previousCount + 1
        : (previousCount - 1).clamp(0, 1 << 30);

    _likingWorkIds.add(id);
    _applyLikeUpdate(id, liked: optimisticLiked, likesCount: optimisticCount);
    notifyListeners();

    try {
      final result = await galleryRepository.toggleLike(id);
      _applyLikeUpdate(
        id,
        liked: result.liked,
        likesCount: result.likesCount,
      );
      return null;
    } on ApiException catch (e) {
      _applyLikeUpdate(
        id,
        liked: previousLiked,
        likesCount: previousCount,
      );
      return e.message;
    } catch (_) {
      _applyLikeUpdate(
        id,
        liked: previousLiked,
        likesCount: previousCount,
      );
      return 'Gagal memperbarui status suka. Silakan coba lagi.';
    } finally {
      _likingWorkIds.remove(id);
      notifyListeners();
    }
  }

  // ─── Session Isolation on Logout ──────────────────────────────────

  void clearUserData() {
    _myWorksRequestVersion++;
    _myWorks = [];
    _isLoadingMyWorks = false;
    _isLoadingMoreMyWorks = false;
    _hasLoadedMyWorks = false;
    _myWorksError = null;
    _myWorksPage = 1;
    _myWorksLastPage = 1;

    _detailRequestVersions.clear();
    _detailCache.clear();
    _loadingDetailIds.clear();
    _detailErrors.clear();
    _detailStatusCodes.clear();

    _isSubmitting = false;
    _submitError = null;
    _fieldErrors = {};
    _likingWorkIds.clear();
    _deletingWorkIds.clear();

    // Strip user-specific likedByMe flags from public feed items so a subsequent
    // account never sees the previous user's liked state.
    _works = _works.map((w) => w.copyWith(likedByMe: false)).toList();

    notifyListeners();
  }

  // ─── Internal Helpers ─────────────────────────────────────────────

  GalleryWork? _findWork(int id) {
    if (_detailCache.containsKey(id)) return _detailCache[id];
    for (final w in _works) {
      if (w.id == id) return w;
    }
    for (final w in _myWorks) {
      if (w.id == id) return w;
    }
    return null;
  }

  void _syncWorkAcrossLists(GalleryWork detail) {
    final feedIdx = _works.indexWhere((w) => w.id == detail.id);
    if (feedIdx != -1) {
      _works = List<GalleryWork>.from(_works)..[feedIdx] = detail;
    }
    final myIdx = _myWorks.indexWhere((w) => w.id == detail.id);
    if (myIdx != -1) {
      _myWorks = List<GalleryWork>.from(_myWorks)..[myIdx] = detail;
    }
  }

  void _applyLikeUpdate(
    int id, {
    required bool liked,
    required int likesCount,
  }) {
    if (_detailCache.containsKey(id)) {
      _detailCache[id] = _detailCache[id]!.copyWith(
        likedByMe: liked,
        likesCount: likesCount,
      );
    }
    final feedIdx = _works.indexWhere((w) => w.id == id);
    if (feedIdx != -1) {
      _works = List<GalleryWork>.from(_works)
        ..[feedIdx] = _works[feedIdx].copyWith(
          likedByMe: liked,
          likesCount: likesCount,
        );
    }
    final myIdx = _myWorks.indexWhere((w) => w.id == id);
    if (myIdx != -1) {
      _myWorks = List<GalleryWork>.from(_myWorks)
        ..[myIdx] = _myWorks[myIdx].copyWith(
          likedByMe: liked,
          likesCount: likesCount,
        );
    }
  }

  Map<String, String> _extractFieldErrors(Map<String, dynamic>? raw) {
    if (raw == null || raw.isEmpty) return {};
    final mapped = <String, String>{};
    for (final entry in raw.entries) {
      final val = entry.value;
      String? msg;
      if (val is List && val.isNotEmpty) {
        msg = val.first?.toString();
      } else if (val is String && val.trim().isNotEmpty) {
        msg = val.trim();
      }
      if (msg != null && msg.isNotEmpty) {
        mapped[entry.key] = msg;
      }
    }
    return mapped;
  }
}
