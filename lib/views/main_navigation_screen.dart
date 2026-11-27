import 'package:flutter/material.dart';

import '../core/widgets/app_bottom_nav.dart';
import '../repositories/gallery_repository.dart';
import '../repositories/shipping_repository.dart';
import '../viewmodels/activity_viewmodel.dart';
import '../viewmodels/address_viewmodel.dart';
import '../viewmodels/analysis_viewmodel.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../viewmodels/gallery_viewmodel.dart';
import '../viewmodels/home_viewmodel.dart';
import '../viewmodels/marketplace_viewmodel.dart';
import '../viewmodels/matching_viewmodel.dart';
import '../viewmodels/material_request_viewmodel.dart';
import '../viewmodels/navigation_viewmodel.dart';
import '../viewmodels/order_viewmodel.dart';
import 'analysis/analysis_screen.dart';
import 'gallery/gallery_screen.dart';
import 'home/home_screen.dart';
import 'marketplace/marketplace_screen.dart';
import 'profile/profile_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  final NavigationViewModel navigationViewModel;
  final HomeViewModel homeViewModel;
  final AnalysisViewModel analysisViewModel;
  final MarketplaceViewModel marketplaceViewModel;
  final GalleryViewModel? galleryViewModel;
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
    this.galleryViewModel,
    this.authViewModel,
    this.activityViewModel,
    this.materialRequestViewModel,
    this.matchingViewModel,
    this.addressViewModel,
    this.shippingRepository,
    this.orderViewModel,
  });

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  GalleryViewModel? _ownedGalleryViewModel;

  GalleryViewModel get _effectiveGalleryViewModel {
    final provided = widget.galleryViewModel;
    if (provided != null) return provided;
    return _ownedGalleryViewModel ??= GalleryViewModel(
      galleryRepository: MockGalleryRepository(),
    );
  }

  @override
  void dispose() {
    _ownedGalleryViewModel?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final galleryVm = _effectiveGalleryViewModel;

    return ListenableBuilder(
      listenable: widget.navigationViewModel,
      builder: (context, _) {
        final currentIndex = widget.navigationViewModel.currentIndex;

        return Scaffold(
          body: IndexedStack(
            index: currentIndex,
            children: [
              HomeScreen(
                viewModel: widget.homeViewModel,
                navigationViewModel: widget.navigationViewModel,
                authViewModel: widget.authViewModel,
                addressViewModel: widget.addressViewModel,
                shippingRepository: widget.shippingRepository,
                orderViewModel: widget.orderViewModel,
              ),
              GalleryScreen(
                viewModel: galleryVm,
                navigationViewModel: widget.navigationViewModel,
                authViewModel: widget.authViewModel,
              ),
              AnalysisScreen(
                viewModel: widget.analysisViewModel,
                navigationViewModel: widget.navigationViewModel,
                authViewModel: widget.authViewModel,
                marketplaceViewModel: widget.marketplaceViewModel,
                shippingRepository: widget.shippingRepository,
                galleryViewModel: galleryVm,
              ),
              MarketplaceScreen(
                viewModel: widget.marketplaceViewModel,
                navigationViewModel: widget.navigationViewModel,
                authViewModel: widget.authViewModel,
                materialRequestViewModel: widget.materialRequestViewModel,
                matchingViewModel: widget.matchingViewModel,
                addressViewModel: widget.addressViewModel,
                shippingRepository: widget.shippingRepository,
                orderViewModel: widget.orderViewModel,
              ),
              ProfileScreen(
                authViewModel: widget.authViewModel,
                activityViewModel: widget.activityViewModel,
                orderViewModel: widget.orderViewModel,
                addressViewModel: widget.addressViewModel,
                shippingRepository: widget.shippingRepository,
                marketplaceViewModel: widget.marketplaceViewModel,
                navigationViewModel: widget.navigationViewModel,
                galleryViewModel: galleryVm,
              ),
            ],
          ),
          bottomNavigationBar: AppBottomNav(
            currentIndex: currentIndex,
            onTabSelected: (index) => widget.navigationViewModel.setIndex(index),
          ),
        );
      },
    );
  }
}
