import 'package:flutter/foundation.dart';

class NavigationViewModel extends ChangeNotifier {
  static const int homeIndex = 0;
  static const int galleryIndex = 1;
  static const int analysisIndex = 2;
  static const int marketplaceIndex = 3;
  static const int profileIndex = 4;

  int _currentIndex = homeIndex;

  int get currentIndex => _currentIndex;

  void setIndex(int index) {
    if (_currentIndex != index) {
      _currentIndex = index;
      notifyListeners();
    }
  }

  void goToHome() => setIndex(homeIndex);
  void goToAnalysis() => setIndex(analysisIndex);
  void goToMarketplace() => setIndex(marketplaceIndex);
  void goToGallery() => setIndex(galleryIndex);
  void goToProfile() => setIndex(profileIndex);
  void goToActivity() => setIndex(profileIndex);
}
