import 'package:flutter/foundation.dart';
import '../models/material_listing.dart';
import '../repositories/material_repository.dart';

class MarketplaceViewModel extends ChangeNotifier {
  final MaterialRepository materialRepository;

  MarketplaceViewModel({required this.materialRepository}) {
    loadListings();
  }

  final List<String> categories = const [
    'Semua',
    'PET',
    'HDPE',
    'PP',
    'LDPE',
    'Lainnya',
  ];

  String _selectedCategory = 'Semua';
  String get selectedCategory => _selectedCategory;

  String _searchQuery = '';
  String get searchQuery => _searchQuery;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  List<MaterialListing> _listings = [];
  List<MaterialListing> get listings => _listings;

  Future<void> loadListings() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final items = await materialRepository.getMaterials(
        category: _selectedCategory,
        query: _searchQuery,
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

  void updateSearchQuery(String query) {
    _searchQuery = query;
    loadListings();
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
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final newListing = await materialRepository.createMaterial(
        name: name,
        category: category,
        weightKg: weightKg,
        condition: condition,
        price: price,
        isFree: isFree,
        generalLocation: generalLocation,
        description: description,
      );
      _listings.insert(0, newListing);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('ApiException: ', '');
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
