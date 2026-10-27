import 'package:flutter/material.dart';

import '../core/widgets/app_bottom_nav.dart';
import '../viewmodels/analysis_viewmodel.dart';
import '../viewmodels/home_viewmodel.dart';
import '../viewmodels/marketplace_viewmodel.dart';
import '../viewmodels/navigation_viewmodel.dart';
import 'activity/activity_screen.dart';
import 'analysis/analysis_screen.dart';
import 'home/home_screen.dart';
import 'marketplace/marketplace_screen.dart';

class MainNavigationScreen extends StatelessWidget {
  final NavigationViewModel navigationViewModel;
  final HomeViewModel homeViewModel;
  final AnalysisViewModel analysisViewModel;
  final MarketplaceViewModel marketplaceViewModel;

  const MainNavigationScreen({
    super.key,
    required this.navigationViewModel,
    required this.homeViewModel,
    required this.analysisViewModel,
    required this.marketplaceViewModel,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: navigationViewModel,
      builder: (context, _) {
        final currentIndex = navigationViewModel.currentIndex;

        return Scaffold(
          body: IndexedStack(
            index: currentIndex,
            children: [
              HomeScreen(
                viewModel: homeViewModel,
                navigationViewModel: navigationViewModel,
              ),
              AnalysisScreen(
                viewModel: analysisViewModel,
                navigationViewModel: navigationViewModel,
              ),
              MarketplaceScreen(
                viewModel: marketplaceViewModel,
                navigationViewModel: navigationViewModel,
              ),
              const ActivityScreen(),
            ],
          ),
          bottomNavigationBar: AppBottomNav(
            currentIndex: currentIndex,
            onTabSelected: (index) => navigationViewModel.setIndex(index),
          ),
        );
      },
    );
  }
}
