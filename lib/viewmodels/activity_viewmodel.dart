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

  void setTabIndex(int index) {
    if (_selectedTabIndex != index) {
      _selectedTabIndex = index;
      notifyListeners();
    }
  }

  Future<void> loadActivities() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _activities = await activityRepository.getActivities();
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('ApiException: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadAnalysisHistories() async {
    _isLoadingAnalyses = true;
    _analysesError = null;
    notifyListeners();

    try {
      final rawList = await activityRepository.getAnalysisHistories();
      _analyses = rawList
          .map((data) => ApiAnalysisRepository.mapBackendDataToResult(data))
          .toList();
    } catch (e) {
      _analysesError = e.toString().replaceFirst('ApiException: ', '');
    } finally {
      _isLoadingAnalyses = false;
      notifyListeners();
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
