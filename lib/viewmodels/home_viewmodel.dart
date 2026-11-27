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

  int _sessionVersion = 0;
  bool _disposed = false;

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  void _safeNotifyListeners() {
    if (!_disposed) {
      notifyListeners();
    }
  }

  void clearUserData() {
    _sessionVersion++;
    final hadFavorite = _recentListings.any((item) => item.isFavorited);
    final hadState =
        hadFavorite ||
        _isLoading ||
        _isImpactLoading ||
        _errorMessage != null ||
        _impactErrorMessage != null;

    if (hadFavorite) {
      _recentListings = _recentListings
          .map((item) => item.isFavorited ? item.copyWith(isFavorited: false) : item)
          .toList();
    }
    _isLoading = false;
    _isImpactLoading = false;
    _errorMessage = null;
    _impactErrorMessage = null;

    if (hadState) {
      _safeNotifyListeners();
    }
  }

  bool get hasImpactData => _impactSummary != null;

  // Real data getters dari backend (tanpa angka palsu fallback!)
  // Mengembalikan null jika data belum selesai dimuat atau terjadi error
  double? get registeredKg => _impactSummary?.listedWeightKg;
  double? get handedOverKg => _impactSummary?.handedOverWeightKg;
  double? get processedKg => _impactSummary?.confirmedWeightKg;

  Future<void> loadHomeData() async {
    final version = _sessionVersion;
    _isLoading = true;
    _errorMessage = null;
    _safeNotifyListeners();

    try {
      final items = await materialRepository.getMaterials();
      if (version != _sessionVersion || _disposed) return;
      _recentListings = items.take(3).toList();
    } catch (e) {
      if (version != _sessionVersion || _disposed) return;
      _errorMessage = e.toString().replaceFirst('ApiException: ', '');
    } finally {
      if (version == _sessionVersion && !_disposed) {
        _isLoading = false;
        _safeNotifyListeners();
      }
    }

    if (version != _sessionVersion || _disposed) return;
    // Ambil impact summary secara terpisah agar kegagalannya tidak membatalkan recent listings
    await loadImpactSummary();
  }

  Future<void> loadImpactSummary() async {
    final version = _sessionVersion;
    _isImpactLoading = true;
    _impactErrorMessage = null;
    _safeNotifyListeners();

    try {
      final summary = await materialRepository.getImpactSummary();
      if (version != _sessionVersion || _disposed) return;
      _impactSummary = summary;
    } catch (e) {
      if (version != _sessionVersion || _disposed) return;
      _impactErrorMessage = e.toString().replaceFirst('ApiException: ', '');
      _impactSummary = null;
    } finally {
      if (version == _sessionVersion && !_disposed) {
        _isImpactLoading = false;
        _safeNotifyListeners();
      }
    }
  }

  Future<void> toggleFavorite(int id) async {
    final version = _sessionVersion;
    await materialRepository.toggleFavorite(id);
    if (version != _sessionVersion || _disposed) return;
    final index = _recentListings.indexWhere((element) => element.id == id);
    if (index != -1) {
      final item = _recentListings[index];
      _recentListings[index] = item.copyWith(isFavorited: !item.isFavorited);
      _safeNotifyListeners();
    }
  }
}
