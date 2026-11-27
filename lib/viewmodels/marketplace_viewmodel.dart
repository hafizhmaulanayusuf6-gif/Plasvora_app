import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/material_listing.dart';
import '../repositories/material_repository.dart';

class MarketplaceViewModel extends ChangeNotifier {
  final MaterialRepository materialRepository;
  Timer? _searchDebounce;
  int _sessionVersion = 0;
  bool _disposed = false;

  MarketplaceViewModel({required this.materialRepository}) {
    loadListings();
  }

  @override
  void dispose() {
    _disposed = true;
    _searchDebounce?.cancel();
    super.dispose();
  }

  void _safeNotifyListeners() {
    if (!_disposed) {
      notifyListeners();
    }
  }

  void clearUserData() {
    _sessionVersion++;
    _searchDebounce?.cancel();
    materialRepository.clearUserData();

    final hadUserFilters =
        _selectedCategory != 'Semua' ||
        _selectedCondition != 'Semua' ||
        _minWeight != null ||
        _maxWeight != null ||
        (_locationFilter != null && _locationFilter!.trim().isNotEmpty) ||
        _searchQuery.isNotEmpty;
    final hadFavorite = _listings.any((item) => item.isFavorited);
    final hadState =
        hadUserFilters ||
        hadFavorite ||
        _isLoading ||
        _isSaving ||
        _errorMessage != null;

    if (hadUserFilters) {
      _listings = [];
    } else if (hadFavorite) {
      _listings = _listings
          .map((item) => item.isFavorited ? item.copyWith(isFavorited: false) : item)
          .toList();
    }

    _selectedCategory = 'Semua';
    _selectedCondition = 'Semua';
    _minWeight = null;
    _maxWeight = null;
    _locationFilter = null;
    _searchQuery = '';
    _isLoading = false;
    _isSaving = false;
    _errorMessage = null;

    if (hadState) {
      _safeNotifyListeners();
    }
  }

  final List<String> categories = const [
    'Semua',
    'PET',
    'HDPE',
    'PP',
    'LDPE',
    'Lainnya',
  ];

  final List<String> conditions = const [
    'Semua',
    'clean',
    'slightly_dirty',
    'dirty',
    'mixed',
  ];

  String _selectedCategory = 'Semua';
  String get selectedCategory => _selectedCategory;

  String _selectedCondition = 'Semua';
  String get selectedCondition => _selectedCondition;

  double? _minWeight;
  double? get minWeight => _minWeight;

  double? _maxWeight;
  double? get maxWeight => _maxWeight;

  String? _locationFilter;
  String? get locationFilter => _locationFilter;

  String _searchQuery = '';
  String get searchQuery => _searchQuery;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isSaving = false;
  bool get isSaving => _isSaving;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  List<MaterialListing> _listings = [];
  List<MaterialListing> get listings => _listings;

  bool get hasActiveAdvancedFilters =>
      _selectedCondition != 'Semua' ||
      _minWeight != null ||
      _maxWeight != null ||
      (_locationFilter != null && _locationFilter!.trim().isNotEmpty);

  int get activeFilterCount {
    int count = 0;
    if (_selectedCategory != 'Semua') count++;
    if (_selectedCondition != 'Semua') count++;
    if (_minWeight != null && _minWeight! > 0) count++;
    if (_maxWeight != null && _maxWeight! > 0) count++;
    if (_locationFilter != null && _locationFilter!.trim().isNotEmpty) count++;
    return count;
  }

  Future<void> loadListings() async {
    final sessionVersion = _sessionVersion;
    _isLoading = true;
    _errorMessage = null;
    _safeNotifyListeners();

    try {
      // BUG-09: Petakan label UI 'Semua' -> null dan 'Lainnya' -> 'OTHER' saat memfilter API
      final categoryQuery = _selectedCategory == 'Semua'
          ? null
          : (_selectedCategory == 'Lainnya' ? 'OTHER' : _selectedCategory);
      final conditionQuery = _selectedCondition == 'Semua' ? null : _selectedCondition;

      final items = await materialRepository.getMaterials(
        category: categoryQuery,
        query: _searchQuery,
        condition: conditionQuery,
        minWeight: _minWeight,
        maxWeight: _maxWeight,
        location: _locationFilter,
      );
      if (sessionVersion != _sessionVersion || _disposed) return;
      _listings = items;
    } catch (e) {
      if (sessionVersion != _sessionVersion || _disposed) return;
      _errorMessage = e.toString().replaceFirst('ApiException: ', '');
      _listings = [];
    } finally {
      if (sessionVersion == _sessionVersion && !_disposed) {
        _isLoading = false;
        _safeNotifyListeners();
      }
    }
  }

  void selectCategory(String category) {
    if (_selectedCategory != category) {
      _selectedCategory = category;
      loadListings();
    }
  }

  void updateSearchQuery(String query, {bool immediate = false}) {
    _searchQuery = query;
    _searchDebounce?.cancel();

    if (immediate || query.trim().isEmpty) {
      loadListings();
    } else {
      _searchDebounce = Timer(const Duration(milliseconds: 400), () {
        loadListings();
      });
    }
  }

  void applyAdvancedFilters({
    String? category,
    String? condition,
    double? minWeight,
    double? maxWeight,
    String? location,
  }) {
    if (category != null) _selectedCategory = category;
    if (condition != null) _selectedCondition = condition;
    _minWeight = minWeight;
    _maxWeight = maxWeight;
    _locationFilter = location;
    loadListings();
  }

  void resetFilters() {
    _selectedCategory = 'Semua';
    _selectedCondition = 'Semua';
    _minWeight = null;
    _maxWeight = null;
    _locationFilter = null;
    _searchQuery = '';
    _searchDebounce?.cancel();
    loadListings();
  }

  Future<MaterialListing> getMaterialDetail(int id) async {
    return await materialRepository.getMaterialDetail(id);
  }

  Future<void> toggleFavorite(int id) async {
    final sessionVersion = _sessionVersion;
    await materialRepository.toggleFavorite(id);
    if (sessionVersion != _sessionVersion || _disposed) return;
    final index = _listings.indexWhere((element) => element.id == id);
    if (index != -1) {
      final item = _listings[index];
      _listings[index] = item.copyWith(isFavorited: !item.isFavorited);
      _safeNotifyListeners();
    }
  }

  Future<bool> createListing({
    required String name,
    required String category,
    required double weightKg,
    required String condition,
    required int price,
    required bool isFree,
    required String generalLocation,
    required String description,
    int? originDestinationId,
    String? originLabel,
    String? imagePath,
  }) async {
    final sessionVersion = _sessionVersion;
    _isLoading = true;
    _isSaving = true;
    _errorMessage = null;
    _safeNotifyListeners();

    try {
      // BUG-09: Normalisasi kategori 'Lainnya' -> 'OTHER'
      final normalizedCategory = category.trim() == 'Lainnya' ? 'OTHER' : category.trim();

      // BUG-10: Normalisasi kondisi 'light' -> 'slightly_dirty'
      final normalizedCondition = condition.trim() == 'light' ? 'slightly_dirty' : condition.trim();

      final newListing = await materialRepository.createMaterial(
        name: name,
        category: normalizedCategory,
        weightKg: weightKg,
        condition: normalizedCondition,
        price: price,
        isFree: isFree,
        generalLocation: generalLocation,
        description: description,
        originDestinationId: originDestinationId,
        originLabel: originLabel,
        imagePath: imagePath,
      );
      if (sessionVersion != _sessionVersion || _disposed) return false;
      _listings.insert(0, newListing);
      _safeNotifyListeners();
      return true;
    } on ArgumentError {
      rethrow;
    } catch (e) {
      if (sessionVersion != _sessionVersion || _disposed) return false;
      _errorMessage = e.toString().replaceFirst('ApiException: ', '');
      _safeNotifyListeners();
      return false;
    } finally {
      if (sessionVersion == _sessionVersion && !_disposed) {
        _isLoading = false;
        _isSaving = false;
        _safeNotifyListeners();
      }
    }
  }

  Future<MaterialListing?> updateListing({
    required int id,
    String? name,
    String? category,
    double? weightKg,
    String? condition,
    int? price,
    bool? isFree,
    String? generalLocation,
    String? description,
    int? originDestinationId,
    String? originLabel,
    bool clearOrigin = false,
    String? imagePath,
  }) async {
    if (_isSaving) return null;

    final sessionVersion = _sessionVersion;
    _isSaving = true;
    _errorMessage = null;
    _safeNotifyListeners();

    try {
      final normalizedCategory = category == null
          ? null
          : (category.trim() == 'Lainnya' ? 'OTHER' : category.trim());
      final normalizedCondition = condition == null
          ? null
          : (condition.trim() == 'light' ? 'slightly_dirty' : condition.trim());

      final updated = await materialRepository.updateMaterial(
        id: id,
        name: name,
        category: normalizedCategory,
        weightKg: weightKg,
        condition: normalizedCondition,
        price: price,
        isFree: isFree,
        generalLocation: generalLocation,
        description: description,
        originDestinationId: originDestinationId,
        originLabel: originLabel,
        clearOrigin: clearOrigin,
        imagePath: imagePath,
      );
      if (sessionVersion != _sessionVersion || _disposed) return null;

      final index = _listings.indexWhere((element) => element.id == id);
      if (index != -1) {
        _listings[index] = updated;
      }
      return updated;
    } on ArgumentError {
      rethrow;
    } catch (e) {
      if (sessionVersion != _sessionVersion || _disposed) return null;
      _errorMessage = e.toString().replaceFirst('ApiException: ', '');
      return null;
    } finally {
      if (sessionVersion == _sessionVersion && !_disposed) {
        _isSaving = false;
        _safeNotifyListeners();
      }
    }
  }
}
