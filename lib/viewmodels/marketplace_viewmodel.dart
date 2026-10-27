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

  List<MaterialListing> _listings = [];
  List<MaterialListing> get listings => _listings;

  Future<void> loadListings() async {
    _isLoading = true;
    notifyListeners();

    try {
      final items = await materialRepository.getMaterials(
        category: _selectedCategory,
        query: _searchQuery,
      );
      _listings = items;
    } catch (_) {
      // Fallback
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
    final index = _listings.indexWhere((item) => item.id == id);
    if (index != -1) {
      final item = _listings[index];
      _listings[index] = item.copyWith(isFavorited: !item.isFavorited);
      notifyListeners();
    }
  }
}
