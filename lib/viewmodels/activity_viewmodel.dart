import 'package:flutter/foundation.dart';

import '../models/activity_item.dart';
import '../repositories/activity_repository.dart';

class ActivityViewModel extends ChangeNotifier {
  final ActivityRepository activityRepository;

  ActivityViewModel({required this.activityRepository}) {
    loadActivities();
  }

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  List<ActivityItem> _activities = [];
  List<ActivityItem> get activities => _activities;

  bool get isEmpty => !_isLoading && _errorMessage == null && _activities.isEmpty;

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
}

