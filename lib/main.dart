import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'core/theme/app_theme.dart';
import 'repositories/analysis_repository.dart';
import 'repositories/material_repository.dart';
import 'viewmodels/analysis_viewmodel.dart';
import 'viewmodels/home_viewmodel.dart';
import 'viewmodels/marketplace_viewmodel.dart';
import 'viewmodels/navigation_viewmodel.dart';
import 'views/main_navigation_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  final materialRepository = MockMaterialRepository();
  final analysisRepository = MockAnalysisRepository();

  final navigationViewModel = NavigationViewModel();
  final homeViewModel = HomeViewModel(materialRepository: materialRepository);
  final analysisViewModel = AnalysisViewModel(
    analysisRepository: analysisRepository,
  );
  final marketplaceViewModel = MarketplaceViewModel(
    materialRepository: materialRepository,
  );

  runApp(
    PlasvoraApp(
      navigationViewModel: navigationViewModel,
      homeViewModel: homeViewModel,
      analysisViewModel: analysisViewModel,
      marketplaceViewModel: marketplaceViewModel,
    ),
  );
}

class PlasvoraApp extends StatelessWidget {
  final NavigationViewModel navigationViewModel;
  final HomeViewModel homeViewModel;
  final AnalysisViewModel analysisViewModel;
  final MarketplaceViewModel marketplaceViewModel;

  const PlasvoraApp({
    super.key,
    required this.navigationViewModel,
    required this.homeViewModel,
    required this.analysisViewModel,
    required this.marketplaceViewModel,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PLASVORA',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: MainNavigationScreen(
        navigationViewModel: navigationViewModel,
        homeViewModel: homeViewModel,
        analysisViewModel: analysisViewModel,
        marketplaceViewModel: marketplaceViewModel,
      ),
    );
  }
}
