import '../core/network/api_client.dart';
import '../core/network/api_config.dart';
import '../models/activity_item.dart';

abstract class ActivityRepository {
  Future<List<ActivityItem>> getActivities();
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
}

class MockActivityRepository implements ActivityRepository {
  @override
  Future<List<ActivityItem>> getActivities() async {
    return [];
  }
}

