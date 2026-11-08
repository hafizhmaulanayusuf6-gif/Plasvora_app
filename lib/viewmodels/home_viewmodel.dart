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

  bool _isImpactLoading = false;
  bool get isImpactLoading => _isImpactLoading;

  String? _impactErrorMessage;
  String? get impactErrorMessage => _impactErrorMessage;

  bool get hasImpactData => _impactSummary != null;

  // Real data getters dari backend (tanpa angka palsu fallback!)
  // Mengembalikan null jika data belum selesai dimuat atau terjadi error
  double? get registeredKg => _impactSummary?.listedWeightKg;
  double? get handedOverKg => _impactSummary?.handedOverWeightKg;
  double? get processedKg => _impactSummary?.confirmedWeightKg;

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

    // Ambil impact summary secara terpisah agar kegagalannya tidak membatalkan recent listings
    await loadImpactSummary();
  }

  Future<void> loadImpactSummary() async {
    _isImpactLoading = true;
    _impactErrorMessage = null;
    notifyListeners();

    try {
      _impactSummary = await materialRepository.getImpactSummary();
    } catch (e) {
      _impactErrorMessage = e.toString().replaceFirst('ApiException: ', '');
      _impactSummary = null;
    } finally {
      _isImpactLoading = false;
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
