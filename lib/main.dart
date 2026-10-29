import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'core/network/api_client.dart';
import 'core/theme/app_theme.dart';
import 'repositories/analysis_repository.dart';
import 'repositories/auth_repository.dart';
import 'repositories/material_repository.dart';
import 'viewmodels/analysis_viewmodel.dart';
import 'viewmodels/auth_viewmodel.dart';
import 'viewmodels/home_viewmodel.dart';
import 'viewmodels/marketplace_viewmodel.dart';
import 'viewmodels/navigation_viewmodel.dart';
import 'views/auth/login_screen.dart';
import 'views/main_navigation_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  // Mode konfigurasi: gunakan API backend saat flag USE_API_REPOSITORY aktif
  // (default: false untuk backward compatibility widget test, true via environment/toggle)
  const useApiRepository = bool.fromEnvironment('USE_API', defaultValue: false);

  final apiClient = ApiClient();
  final MaterialRepository materialRepository = useApiRepository
      ? ApiMaterialRepository(apiClient: apiClient)
      : MockMaterialRepository();

  final AnalysisRepository analysisRepository = useApiRepository
      ? ApiAnalysisRepository(apiClient: apiClient)
      : MockAnalysisRepository();

  final authRepository = ApiAuthRepository(apiClient: apiClient);

  final navigationViewModel = NavigationViewModel();
  final authViewModel = AuthViewModel(authRepository: authRepository);
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
      authViewModel: authViewModel,
    ),
  );
}

class PlasvoraApp extends StatelessWidget {
  final NavigationViewModel navigationViewModel;
  final HomeViewModel homeViewModel;
  final AnalysisViewModel analysisViewModel;
  final MarketplaceViewModel marketplaceViewModel;
  final AuthViewModel? authViewModel;

  const PlasvoraApp({
    super.key,
    required this.navigationViewModel,
    required this.homeViewModel,
    required this.analysisViewModel,
    required this.marketplaceViewModel,
    this.authViewModel,
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
          );
        }

        return LoginScreen(
          authViewModel: authViewModel!,
        );
      },
    );
  }
}
