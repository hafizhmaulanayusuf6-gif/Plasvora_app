import 'package:flutter/foundation.dart';
import '../core/network/api_client.dart';
import '../models/material_request_item.dart';
import '../repositories/transaction_repository.dart';

class MaterialRequestViewModel extends ChangeNotifier {
  final TransactionRepository transactionRepository;
  int? currentUserId;

  MaterialRequestViewModel({
    required this.transactionRepository,
    this.currentUserId,
  }) {
    loadRequests();
  }

  final List<String> categories = const [
    'Semua',
    'PET',
    'HDPE',
    'PP',
    'LDPE',
    'Lainnya',
    'Campuran',
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

  String? _locationFilter;
  String? get locationFilter => _locationFilter;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isSubmitting = false;
  bool get isSubmitting => _isSubmitting;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  List<MaterialRequestItem> _requests = [];
  List<MaterialRequestItem> get requests => _requests;

  bool get hasActiveFilters =>
      _selectedCategory != 'Semua' ||
      _selectedCondition != 'Semua' ||
      (_locationFilter != null && _locationFilter!.trim().isNotEmpty);

  Future<void> loadRequests() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final categoryQuery = _mapCategoryForBackend(_selectedCategory);
      final conditionQuery =
          _selectedCondition == 'Semua' ? null : _selectedCondition;

      final items = await transactionRepository.getMaterialRequests(
        category: categoryQuery,
        condition: conditionQuery,
        location: _locationFilter,
      );
      _requests = items;
    } catch (e) {
      _errorMessage = _formatError(e);
      _requests = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void selectCategory(String category) {
    if (_selectedCategory != category) {
      _selectedCategory = category;
      loadRequests();
    }
  }

  void applyFilters({
    String? category,
    String? condition,
    String? location,
  }) {
    if (category != null) _selectedCategory = category;
    if (condition != null) _selectedCondition = condition;
    _locationFilter = location;
    loadRequests();
  }

  void resetFilters() {
    _selectedCategory = 'Semua';
    _selectedCondition = 'Semua';
    _locationFilter = null;
    loadRequests();
  }

  /// Validasi input sebelum dikirim ke backend
  String? validateForm({
    required String category,
    required double weightKg,
    required String condition,
    required String location,
    required String intendedUse,
  }) {
    final validCategories = ['PET', 'HDPE', 'PP', 'LDPE', 'OTHER', 'MIXED'];
    final normalizedCategory = _mapCategoryForBackend(category);
    if (!validCategories.contains(normalizedCategory)) {
      return 'Kategori material tidak valid. Pilih dari: PET, HDPE, PP, LDPE, Lainnya, Campuran.';
    }

    if (weightKg <= 0.0) {
      return 'Berat yang dibutuhkan harus lebih besar dari 0 kg.';
    }
    if (weightKg > 99999.0) {
      return 'Berat maksimal adalah 99.999 kg.';
    }

    final validConditions = ['clean', 'slightly_dirty', 'dirty', 'mixed'];
    if (!validConditions.contains(condition)) {
      return 'Kondisi material tidak valid.';
    }

    if (location.trim().length < 3) {
      return 'Lokasi umum minimal 3 karakter.';
    }
    if (location.trim().length > 255) {
      return 'Lokasi umum maksimal 255 karakter.';
    }

    if (intendedUse.trim().length < 5) {
      return 'Tujuan penggunaan material minimal 5 karakter.';
    }
    if (intendedUse.trim().length > 500) {
      return 'Tujuan penggunaan maksimal 500 karakter.';
    }

    return null;
  }

  Future<bool> createRequest({
    required String category,
    required double weightKg,
    required String condition,
    required String location,
    required String intendedUse,
  }) async {
    final validation = validateForm(
      category: category,
      weightKg: weightKg,
      condition: condition,
      location: location,
      intendedUse: intendedUse,
    );

    if (validation != null) {
      _errorMessage = validation;
      notifyListeners();
      return false;
    }

    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final normalizedCategory = _mapCategoryForBackend(category)!;
      final newItem = await transactionRepository.createMaterialRequest(
        materialCategory: normalizedCategory,
        requestedWeightKg: weightKg,
        minimumCondition: condition,
        generalLocation: location.trim(),
        intendedUse: intendedUse.trim(),
      );

      _requests.insert(0, newItem);
      _isSubmitting = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = _formatError(e);
      _isSubmitting = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateRequest({
    required int id,
    String? category,
    double? weightKg,
    String? condition,
    String? location,
    String? intendedUse,
  }) async {
    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final normalizedCategory =
          category != null ? _mapCategoryForBackend(category) : null;
      final updated = await transactionRepository.updateMaterialRequest(
        id: id,
        materialCategory: normalizedCategory,
        requestedWeightKg: weightKg,
        minimumCondition: condition,
        generalLocation: location?.trim(),
        intendedUse: intendedUse?.trim(),
      );

      final index = _requests.indexWhere((r) => r.id == id);
      if (index != -1) {
        _requests[index] = updated;
      }
      _isSubmitting = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = _formatError(e);
      _isSubmitting = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> cancelRequest(int id) async {
    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await transactionRepository.cancelMaterialRequest(id);
      _requests.removeWhere((r) => r.id == id);
      _isSubmitting = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = _formatError(e);
      _isSubmitting = false;
      notifyListeners();
      return false;
    }
  }

  Future<MaterialRequestItem> getDetail(int id) async {
    return await transactionRepository.getMaterialRequestDetail(id);
  }

  bool isOwner(MaterialRequestItem item) {
    if (currentUserId == null) return false;
    return item.requesterId == currentUserId;
  }

  String? _mapCategoryForBackend(String category) {
    if (category == 'Semua') return null;
    if (category == 'Lainnya') return 'OTHER';
    if (category == 'Campuran') return 'MIXED';
    return category;
  }

  String _formatError(dynamic e) {
    if (e is ApiException) {
      if (e.statusCode != null) {
        return '${e.message} (Status: ${e.statusCode})';
      }
      return e.message;
    }
    return e
        .toString()
        .replaceFirst('ApiException: ', '')
        .replaceFirst('Exception: ', '');
  }
}

