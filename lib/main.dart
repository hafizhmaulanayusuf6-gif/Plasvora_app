import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'core/network/api_client.dart';
import 'core/theme/app_colors.dart';
import 'core/theme/app_theme.dart';
import 'repositories/activity_repository.dart';
import 'repositories/analysis_repository.dart';
import 'repositories/auth_repository.dart';
import 'repositories/material_repository.dart';
import 'repositories/transaction_repository.dart';
import 'viewmodels/activity_viewmodel.dart';
import 'viewmodels/analysis_viewmodel.dart';
import 'viewmodels/auth_viewmodel.dart';
import 'viewmodels/home_viewmodel.dart';
import 'viewmodels/marketplace_viewmodel.dart';
import 'viewmodels/matching_viewmodel.dart';
import 'viewmodels/material_request_viewmodel.dart';
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

  final TransactionRepository transactionRepository = useApiRepository
      ? ApiTransactionRepository(apiClient: apiClient)
      : MockTransactionRepository();

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
  final materialRequestViewModel = MaterialRequestViewModel(
    transactionRepository: transactionRepository,
  );
  final matchingViewModel = MatchingViewModel(
    transactionRepository: transactionRepository,
  );

  runApp(
    PlasvoraApp(
      navigationViewModel: navigationViewModel,
      homeViewModel: homeViewModel,
      analysisViewModel: analysisViewModel,
      marketplaceViewModel: marketplaceViewModel,
      authViewModel: authViewModel,
      activityViewModel: activityViewModel,
      materialRequestViewModel: materialRequestViewModel,
      matchingViewModel: matchingViewModel,
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
  final MaterialRequestViewModel? materialRequestViewModel;
  final MatchingViewModel? matchingViewModel;

  const PlasvoraApp({
    super.key,
    required this.navigationViewModel,
    required this.homeViewModel,
    required this.analysisViewModel,
    required this.marketplaceViewModel,
    this.authViewModel,
    this.activityViewModel,
    this.materialRequestViewModel,
    this.matchingViewModel,
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
        materialRequestViewModel: materialRequestViewModel,
        matchingViewModel: matchingViewModel,
      );
    }

    return ListenableBuilder(
      listenable: authViewModel!,
      builder: (context, _) {
        final state = authViewModel!.state;

        // 1. Sedang memverifikasi sesi token saat aplikasi pertama kali dibuka
        if (state == AuthState.initial ||
            (state == AuthState.loading && authViewModel!.currentUser == null)) {
          return const Scaffold(
            backgroundColor: AppColors.background,
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: AppColors.primary),
                  SizedBox(height: 16),
                  Text(
                    'Memulihkan sesi Plasvora...',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        // 2. Gangguan koneksi ke backend (token tetap disimpan, tidak memaksa logout)
        if (state == AuthState.connectionError) {
          return Scaffold(
            backgroundColor: AppColors.background,
            body: SafeArea(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.primaryContainer.withValues(alpha: 0.3),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.wifi_off_rounded,
                          size: 48,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Koneksi Terganggu',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        authViewModel!.errorMessage ??
                            'Gagal terhubung ke server backend. Sesi login Anda tersimpan aman di perangkat.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.onSurfaceVariant,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 32),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: () => authViewModel!.retryCheckAuthSession(),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Coba Lagi',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: () => authViewModel!.logout(),
                        child: const Text(
                          'Masuk dengan Akun Lain',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.onSurfaceVariant,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }

        // 3. Hak akses dibatasi / ditolak (HTTP 403 Forbidden)
        if (state == AuthState.error) {
          return Scaffold(
            backgroundColor: AppColors.background,
            body: SafeArea(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.errorContainer.withValues(alpha: 0.5),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.lock_person_rounded,
                          size: 48,
                          color: AppColors.error,
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Akses Dibatasi',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.error,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        authViewModel!.errorMessage ??
                            'Akun Anda tidak memiliki izin untuk mengakses layanan ini (403 Forbidden).',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.onSurfaceVariant,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 32),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: () => authViewModel!.retryCheckAuthSession(),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Coba Lagi',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: () => authViewModel!.logout(),
                        child: const Text(
                          'Keluar dari Akun Ini',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.error,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }

        // 4. Berhasil terautentikasi (sesi valid)
        if (authViewModel!.isAuthenticated) {
          return MainNavigationScreen(
            navigationViewModel: navigationViewModel,
            homeViewModel: homeViewModel,
            analysisViewModel: analysisViewModel,
            marketplaceViewModel: marketplaceViewModel,
            authViewModel: authViewModel,
            activityViewModel: activityViewModel,
            materialRequestViewModel: materialRequestViewModel,
            matchingViewModel: matchingViewModel,
          );
        }

        // 4. Belum login atau sesi telah dicabut / kadaluwarsa (401)
        return LoginScreen(
          authViewModel: authViewModel!,
        );
      },
    );
  }
}
