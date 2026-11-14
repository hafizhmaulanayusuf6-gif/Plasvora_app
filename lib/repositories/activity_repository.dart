import '../core/network/api_client.dart';
import '../core/network/api_config.dart';
import '../models/activity_item.dart';
import '../models/plastic_analysis.dart';
import 'analysis_repository.dart';

abstract class ActivityRepository {
  Future<List<ActivityItem>> getActivities();
  Future<List<Map<String, dynamic>>> getAnalysisHistories();
  Future<PlasticAnalysisResult> getAnalysisDetail(int id);
}

class ApiActivityRepository implements ActivityRepository {
  final ApiClient apiClient;

  ApiActivityRepository({required this.apiClient});

  @override
  Future<List<ActivityItem>> getActivities() async {
    final response = await apiClient.get(
      ApiConfig.activities,
      requiresAuth: true,
    );

    if (response is Map<String, dynamic> && response['data'] is List) {
      return (response['data'] as List)
          .map((item) => ActivityItem.fromJson(item as Map<String, dynamic>))
          .toList();
    }

    throw ApiException('Format respons activities tidak valid');
  }

  @override
  Future<List<Map<String, dynamic>>> getAnalysisHistories() async {
    final response = await apiClient.get(
      ApiConfig.analyses,
      requiresAuth: true,
    );

    if (response is Map<String, dynamic> && response['data'] is List) {
      return (response['data'] as List).cast<Map<String, dynamic>>();
    }

    throw ApiException('Format respons riwayat analisis tidak valid');
  }

  @override
  Future<PlasticAnalysisResult> getAnalysisDetail(int id) async {
    final response = await apiClient.get(
      ApiConfig.analysisDetail(id),
      requiresAuth: true,
    );

    if (response is Map<String, dynamic> && response['data'] is Map<String, dynamic>) {
      return ApiAnalysisRepository.mapBackendDataToResult(
        response['data'] as Map<String, dynamic>,
      );
    }

    throw ApiException('Format detail analisis tidak valid');
  }
}

class MockActivityRepository implements ActivityRepository {
  final List<ActivityItem> _mockActivities;
  final List<Map<String, dynamic>> _mockAnalyses;

  MockActivityRepository({
    List<ActivityItem>? mockActivities,
    List<Map<String, dynamic>>? mockAnalyses,
  })  : _mockActivities = mockActivities ?? [],
        _mockAnalyses = mockAnalyses ?? [];

  @override
  Future<List<ActivityItem>> getActivities() async {
    return _mockActivities;
  }

  @override
  Future<List<Map<String, dynamic>>> getAnalysisHistories() async {
    return _mockAnalyses;
  }

  @override
  Future<PlasticAnalysisResult> getAnalysisDetail(int id) async {
    final found = _mockAnalyses.firstWhere(
      (element) => element['id'] == id || element['id']?.toString() == id.toString(),
      orElse: () => throw ApiException('Analisis dengan ID $id tidak ditemukan'),
    );
    return ApiAnalysisRepository.mapBackendDataToResult(found);
  }
}
