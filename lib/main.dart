import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'core/network/api_client.dart';
import 'core/theme/app_theme.dart';
import 'repositories/activity_repository.dart';
import 'repositories/analysis_repository.dart';
import 'repositories/auth_repository.dart';
import 'repositories/material_repository.dart';
import 'viewmodels/activity_viewmodel.dart';
import 'viewmodels/analysis_viewmodel.dart';
import 'viewmodels/auth_viewmodel.dart';
import 'viewmodels/home_viewmodel.dart';
import 'viewmodels/marketplace_viewmodel.dart';
import 'viewmodels/navigation_viewmodel.dart';
import 'views/auth/login_screen.dart';
import 'views/main_navigation_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  // Mode konfigurasi: aktifkan integrasi API backend secara default
  const useApiRepository = bool.fromEnvironment('USE_API', defaultValue: true);

  final apiClient = await ApiClient.create();
  final MaterialRepository materialRepository = useApiRepository
      ? ApiMaterialRepository(apiClient: apiClient)
      : MockMaterialRepository();

  final AnalysisRepository analysisRepository = useApiRepository
      ? ApiAnalysisRepository(apiClient: apiClient)
      : MockAnalysisRepository();

  final authRepository = ApiAuthRepository(apiClient: apiClient);

  final ActivityRepository activityRepository = useApiRepository
      ? ApiActivityRepository(apiClient: apiClient)
      : MockActivityRepository();

  final navigationViewModel = NavigationViewModel();
  final authViewModel = AuthViewModel(authRepository: authRepository);
  final homeViewModel = HomeViewModel(materialRepository: materialRepository);
  final analysisViewModel = AnalysisViewModel(
    analysisRepository: analysisRepository,
  );
  final marketplaceViewModel = MarketplaceViewModel(
    materialRepository: materialRepository,
  );
  final activityViewModel = ActivityViewModel(
    activityRepository: activityRepository,
  );

  runApp(
    PlasvoraApp(
      navigationViewModel: navigationViewModel,
      homeViewModel: homeViewModel,
      analysisViewModel: analysisViewModel,
      marketplaceViewModel: marketplaceViewModel,
      authViewModel: authViewModel,
      activityViewModel: activityViewModel,
    ),
  );
}

class PlasvoraApp extends StatelessWidget {
  final NavigationViewModel navigationViewModel;
  final HomeViewModel homeViewModel;
  final AnalysisViewModel analysisViewModel;
  final MarketplaceViewModel marketplaceViewModel;
  final AuthViewModel? authViewModel;
  final ActivityViewModel? activityViewModel;

  const PlasvoraApp({
    super.key,
    required this.navigationViewModel,
    required this.homeViewModel,
    required this.analysisViewModel,
    required this.marketplaceViewModel,
    this.authViewModel,
    this.activityViewModel,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PLASVORA',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: _buildHome(),
    );
  }

  Widget _buildHome() {
    if (authViewModel == null) {
      return MainNavigationScreen(
        navigationViewModel: navigationViewModel,
        homeViewModel: homeViewModel,
        analysisViewModel: analysisViewModel,
        marketplaceViewModel: marketplaceViewModel,
        authViewModel: authViewModel,
        activityViewModel: activityViewModel,
      );
    }

    return ListenableBuilder(
      listenable: authViewModel!,
      builder: (context, _) {
        if (authViewModel!.isLoading && authViewModel!.state == AuthState.initial) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (authViewModel!.isAuthenticated) {
          return MainNavigationScreen(
            navigationViewModel: navigationViewModel,
            homeViewModel: homeViewModel,
            analysisViewModel: analysisViewModel,
            marketplaceViewModel: marketplaceViewModel,
            authViewModel: authViewModel,
            activityViewModel: activityViewModel,
          );
        }

        return LoginScreen(
          authViewModel: authViewModel!,
        );
      },
    );
  }
}
