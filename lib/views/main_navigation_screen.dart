import 'package:flutter/material.dart';

import '../core/widgets/app_bottom_nav.dart';
import '../repositories/shipping_repository.dart';
import '../viewmodels/activity_viewmodel.dart';
import '../viewmodels/address_viewmodel.dart';
import '../viewmodels/analysis_viewmodel.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../viewmodels/home_viewmodel.dart';
import '../viewmodels/marketplace_viewmodel.dart';
import '../viewmodels/matching_viewmodel.dart';
import '../viewmodels/material_request_viewmodel.dart';
import '../viewmodels/navigation_viewmodel.dart';
import '../viewmodels/order_viewmodel.dart';
import 'activity/activity_screen.dart';
import 'analysis/analysis_screen.dart';
import 'home/home_screen.dart';
import 'marketplace/marketplace_screen.dart';

class MainNavigationScreen extends StatelessWidget {
  final NavigationViewModel navigationViewModel;
  final HomeViewModel homeViewModel;
  final AnalysisViewModel analysisViewModel;
  final MarketplaceViewModel marketplaceViewModel;
  final AuthViewModel? authViewModel;
  final ActivityViewModel? activityViewModel;
  final MaterialRequestViewModel? materialRequestViewModel;
  final MatchingViewModel? matchingViewModel;
  final AddressViewModel? addressViewModel;
  final ShippingRepository? shippingRepository;
  final OrderViewModel? orderViewModel;

  const MainNavigationScreen({
    super.key,
    required this.navigationViewModel,
    required this.homeViewModel,
    required this.analysisViewModel,
    required this.marketplaceViewModel,
    this.authViewModel,
    this.activityViewModel,
    this.materialRequestViewModel,
    this.matchingViewModel,
    this.addressViewModel,
    this.shippingRepository,
    this.orderViewModel,
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
                authViewModel: authViewModel,
                addressViewModel: addressViewModel,
                shippingRepository: shippingRepository,
                orderViewModel: orderViewModel,
              ),
              AnalysisScreen(
                viewModel: analysisViewModel,
                navigationViewModel: navigationViewModel,
                marketplaceViewModel: marketplaceViewModel,
                shippingRepository: shippingRepository,
              ),
              MarketplaceScreen(
                viewModel: marketplaceViewModel,
                navigationViewModel: navigationViewModel,
                authViewModel: authViewModel,
                materialRequestViewModel: materialRequestViewModel,
                matchingViewModel: matchingViewModel,
                addressViewModel: addressViewModel,
                shippingRepository: shippingRepository,
                orderViewModel: orderViewModel,
              ),
              ActivityScreen(
                viewModel: activityViewModel,
                marketplaceViewModel: marketplaceViewModel,
                navigationViewModel: navigationViewModel,
                shippingRepository: shippingRepository,
                orderViewModel: orderViewModel,
                authViewModel: authViewModel,
              ),
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
