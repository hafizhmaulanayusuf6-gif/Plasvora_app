import 'package:flutter/foundation.dart';

import '../models/activity_item.dart';
import '../models/plastic_analysis.dart';
import '../repositories/activity_repository.dart';
import '../repositories/analysis_repository.dart';

class ActivityViewModel extends ChangeNotifier {
  final ActivityRepository activityRepository;

  ActivityViewModel({required this.activityRepository}) {
    loadActivities();
    loadAnalysisHistories();
  }

  // ─── Timeline Aktivitas ─────────────────────────────────────────────
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  List<ActivityItem> _activities = [];
  List<ActivityItem> get activities => _activities;

  bool get isEmpty => !_isLoading && _errorMessage == null && _activities.isEmpty;

  // ─── Riwayat Analisis Plastik ───────────────────────────────────────
  bool _isLoadingAnalyses = false;
  bool get isLoadingAnalyses => _isLoadingAnalyses;

  String? _analysesError;
  String? get analysesError => _analysesError;

  List<PlasticAnalysisResult> _analyses = [];
  List<PlasticAnalysisResult> get analyses => _analyses;

  bool get isAnalysesEmpty =>
      !_isLoadingAnalyses && _analysesError == null && _analyses.isEmpty;

  // ─── Tab Switcher (0: Jejak Aktivitas, 1: Riwayat Analisis) ────────
  int _selectedTabIndex = 0;
  int get selectedTabIndex => _selectedTabIndex;

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
    final hadState =
        _activities.isNotEmpty ||
        _analyses.isNotEmpty ||
        _isLoading ||
        _isLoadingAnalyses ||
        _errorMessage != null ||
        _analysesError != null ||
        _selectedTabIndex != 0;

    _activities = [];
    _analyses = [];
    _isLoading = false;
    _isLoadingAnalyses = false;
    _errorMessage = null;
    _analysesError = null;
    _selectedTabIndex = 0;

    if (hadState) {
      _safeNotifyListeners();
    }
  }

  void setTabIndex(int index) {
    if (_selectedTabIndex != index) {
      _selectedTabIndex = index;
      _safeNotifyListeners();
    }
  }

  Future<void> loadActivities() async {
    final version = _sessionVersion;
    _isLoading = true;
    _errorMessage = null;
    _safeNotifyListeners();

    try {
      final fetched = await activityRepository.getActivities();
      if (version != _sessionVersion || _disposed) return;
      _activities = fetched;
    } catch (e) {
      if (version != _sessionVersion || _disposed) return;
      _errorMessage = e.toString().replaceFirst('ApiException: ', '');
    } finally {
      if (version == _sessionVersion && !_disposed) {
        _isLoading = false;
        _safeNotifyListeners();
      }
    }
  }

  Future<void> loadAnalysisHistories() async {
    final version = _sessionVersion;
    _isLoadingAnalyses = true;
    _analysesError = null;
    _safeNotifyListeners();

    try {
      final rawList = await activityRepository.getAnalysisHistories();
      if (version != _sessionVersion || _disposed) return;
      _analyses = rawList
          .map((data) => ApiAnalysisRepository.mapBackendDataToResult(data))
          .toList();
    } catch (e) {
      if (version != _sessionVersion || _disposed) return;
      _analysesError = e.toString().replaceFirst('ApiException: ', '');
    } finally {
      if (version == _sessionVersion && !_disposed) {
        _isLoadingAnalyses = false;
        _safeNotifyListeners();
      }
    }
  }

  Future<PlasticAnalysisResult> getAnalysisDetail(int id) async {
    return await activityRepository.getAnalysisDetail(id);
  }

  Future<void> refreshAll() async {
    await Future.wait([
      loadActivities(),
      loadAnalysisHistories(),
    ]);
  }
}
