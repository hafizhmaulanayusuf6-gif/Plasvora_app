import 'package:flutter/foundation.dart';

class NavigationViewModel extends ChangeNotifier {
  int _currentIndex = 0;

  int get currentIndex => _currentIndex;

  void setIndex(int index) {
    if (_currentIndex != index) {
      _currentIndex = index;
      notifyListeners();
    }
  }

  void goToHome() => setIndex(0);
  void goToAnalysis() => setIndex(1);
  void goToMarketplace() => setIndex(2);
  void goToActivity() => setIndex(3);
}
