import 'package:flutter/foundation.dart';

import '../models/material_listing.dart';
import '../repositories/material_repository.dart';

class HomeViewModel extends ChangeNotifier {
  final MaterialRepository materialRepository;

  HomeViewModel({required this.materialRepository}) {
    loadHomeData();
  }

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  List<MaterialListing> _recentListings = [];
  List<MaterialListing> get recentListings => _recentListings;

  // Impact metrics (Demo statistics designated clearly in UI)
  final double registeredKg = 18.4;
  final double handedOverKg = 12.0;
  final double processedKg = 9.5;

  Future<void> loadHomeData() async {
    _isLoading = true;
    notifyListeners();

    try {
      final items = await materialRepository.getMaterials();
      _recentListings = items.take(2).toList();
    } catch (_) {
      // Fallback
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> toggleFavorite(int id) async {
    await materialRepository.toggleFavorite(id);
    final index = _recentListings.indexWhere((element) => element.id == id);
    if (index != -1) {
      final item = _recentListings[index];
      _recentListings[index] = item.copyWith(isFavorited: !item.isFavorited);
      notifyListeners();
    }
  }
}
