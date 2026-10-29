import 'package:flutter/foundation.dart';
import '../models/impact_summary.dart';
import '../models/material_listing.dart';
import '../repositories/material_repository.dart';

class HomeViewModel extends ChangeNotifier {
  final MaterialRepository materialRepository;

  HomeViewModel({required this.materialRepository}) {
    loadHomeData();
  }

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  List<MaterialListing> _recentListings = [];
  List<MaterialListing> get recentListings => _recentListings;

  ImpactSummary? _impactSummary;
  ImpactSummary? get impactSummary => _impactSummary;

  // Fallback metrics jika backend impact data belum terkoneksi
  double get registeredKg => _impactSummary?.listedWeightKg ?? 18.4;
  double get handedOverKg => _impactSummary?.handedOverWeightKg ?? 12.0;
  double get processedKg => _impactSummary?.confirmedWeightKg ?? 9.5;

  Future<void> loadHomeData() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final items = await materialRepository.getMaterials();
      _recentListings = items.take(3).toList();
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('ApiException: ', '');
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
