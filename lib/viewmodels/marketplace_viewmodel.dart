import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/material_listing.dart';
import '../repositories/material_repository.dart';

class MarketplaceViewModel extends ChangeNotifier {
  final MaterialRepository materialRepository;
  Timer? _searchDebounce;

  MarketplaceViewModel({required this.materialRepository}) {
    loadListings();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    super.dispose();
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
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

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
      _listings = items;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('ApiException: ', '');
      _listings = [];
    } finally {
      _isLoading = false;
      notifyListeners();
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
    await materialRepository.toggleFavorite(id);
    final index = _listings.indexWhere((element) => element.id == id);
    if (index != -1) {
      final item = _listings[index];
      _listings[index] = item.copyWith(isFavorited: !item.isFavorited);
      notifyListeners();
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
    _isLoading = true;
    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

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
      _listings.insert(0, newListing);
      notifyListeners();
      return true;
    } on ArgumentError {
      rethrow;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('ApiException: ', '');
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      _isSaving = false;
      notifyListeners();
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

    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

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

      final index = _listings.indexWhere((element) => element.id == id);
      if (index != -1) {
        _listings[index] = updated;
      }
      return updated;
    } on ArgumentError {
      rethrow;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('ApiException: ', '');
      return null;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }
}
