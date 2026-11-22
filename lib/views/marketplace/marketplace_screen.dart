import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/plasvora_header.dart';
import '../../models/material_listing.dart';
import '../../models/material_request_item.dart';
import '../../repositories/shipping_repository.dart';
import '../../viewmodels/address_viewmodel.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/marketplace_viewmodel.dart';
import '../../viewmodels/matching_viewmodel.dart';
import '../../viewmodels/material_request_viewmodel.dart';
import '../../viewmodels/navigation_viewmodel.dart';
import '../../viewmodels/order_viewmodel.dart';
import '../auth/login_screen.dart';
import '../material_request/create_material_request_screen.dart';
import '../material_request/material_request_detail_screen.dart';
import '../matching/matching_results_screen.dart';
import 'create_material_listing_screen.dart';
import 'material_detail_screen.dart';

class MarketplaceScreen extends StatefulWidget {
  final MarketplaceViewModel viewModel;
  final NavigationViewModel navigationViewModel;
  final AuthViewModel? authViewModel;
  final MaterialRequestViewModel? materialRequestViewModel;
  final MatchingViewModel? matchingViewModel;
  final AddressViewModel? addressViewModel;
  final ShippingRepository? shippingRepository;
  final OrderViewModel? orderViewModel;

  const MarketplaceScreen({
    super.key,
    required this.viewModel,
    required this.navigationViewModel,
    this.authViewModel,
    this.materialRequestViewModel,
    this.matchingViewModel,
    this.addressViewModel,
    this.shippingRepository,
    this.orderViewModel,
  });

  @override
  State<MarketplaceScreen> createState() => _MarketplaceScreenState();
}

class _MarketplaceScreenState extends State<MarketplaceScreen> {
  final TextEditingController _searchController = TextEditingController();
  int _selectedMainTab = 0; // 0: Material Tersedia, 1: Kebutuhan Dicari

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _handleAvatarTap() {
    final authVm = widget.authViewModel;
    if (authVm == null || authVm.isAuthenticated) {
      widget.navigationViewModel.goToProfile();
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => LoginScreen(authViewModel: authVm),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PlasvoraHeader(onAvatarTap: _handleAvatarTap),
      floatingActionButton: _selectedMainTab == 0
          ? _buildOfferMaterialFAB(context)
          : _buildCreateRequestFAB(context),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      body: Column(
        children: [
          _buildMainTabSwitcher(),
          Expanded(
            child: _selectedMainTab == 0
                ? _buildListingsTab()
                : _buildRequestsTab(),
          ),
        ],
      ),
    );
  }

  Widget _buildListingsTab() {
    return ListenableBuilder(
      listenable: widget.viewModel,
      builder: (context, _) {
        return RefreshIndicator(
          onRefresh: () => widget.viewModel.loadListings(),
          color: AppColors.primaryContainer,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSearchBar(),
                      const SizedBox(height: 12),
                      _buildDropdownFilterRow(),
                      const SizedBox(height: 12),
                      _buildPolymerChipsRow(),
                      const SizedBox(height: 14),
                    ],
                  ),
                ),
              ),
                if (widget.viewModel.isLoading)
                  const SliverFillRemaining(
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (widget.viewModel.errorMessage != null &&
                    widget.viewModel.listings.isEmpty)
                  SliverFillRemaining(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.cloud_off,
                              size: 48,
                              color: Colors.redAccent,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Gagal Memuat Material',
                              style: AppTypography.headlineSm(
                                color: AppColors.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              widget.viewModel.errorMessage!,
                              style:
                                  AppTypography.bodySm(color: AppColors.outline),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: () => widget.viewModel.loadListings(),
                              icon: const Icon(Icons.refresh, size: 18),
                              label: const Text('Coba Lagi'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                else if (widget.viewModel.listings.isEmpty)
                  SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.search_off,
                            size: 48,
                            color: AppColors.outlineVariant,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Tidak ada material ditemukan',
                            style: AppTypography.headlineSm(
                              color: AppColors.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Coba ubah filter polimer, kondisi, atau kata kunci pencarian.',
                            style: AppTypography.bodySm(color: AppColors.outline),
                          ),
                          if (widget.viewModel.hasActiveAdvancedFilters ||
                              widget.viewModel.selectedCategory != 'Semua' ||
                              widget.viewModel.searchQuery.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            TextButton.icon(
                              onPressed: () {
                                _searchController.clear();
                                widget.viewModel.resetFilters();
                              },
                              icon: const Icon(Icons.refresh, size: 16),
                              label: const Text('Reset Semua Filter'),
                            ),
                          ],
                        ],
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    sliver: SliverGrid(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 0.58,
                          ),
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final item = widget.viewModel.listings[index];
                        return _buildListingCard(context, item);
                      }, childCount: widget.viewModel.listings.length),
                    ),
                  ),
                const SliverToBoxAdapter(child: SizedBox(height: 100)),
              ],
            ),
          );
        },
      );
    }

  Widget _buildMainTabSwitcher() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 10, 20, 0),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () {
                if (_selectedMainTab != 0) {
                  setState(() => _selectedMainTab = 0);
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 9),
                decoration: BoxDecoration(
                  color: _selectedMainTab == 0
                      ? AppColors.surfaceContainerLowest
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: _selectedMainTab == 0
                      ? const [
                          BoxShadow(
                            color: Color(0x0A000000),
                            blurRadius: 4,
                            offset: Offset(0, 1),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.inventory_2_outlined,
                      size: 16,
                      color: _selectedMainTab == 0
                          ? AppColors.primaryContainer
                          : AppColors.secondary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Material Tersedia',
                      style: AppTypography.labelMd(
                        color: _selectedMainTab == 0
                            ? AppColors.primaryContainer
                            : AppColors.secondary,
                      ).copyWith(
                        fontWeight: _selectedMainTab == 0
                            ? FontWeight.w700
                            : FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () {
                if (_selectedMainTab != 1) {
                  setState(() => _selectedMainTab = 1);
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 9),
                decoration: BoxDecoration(
                  color: _selectedMainTab == 1
                      ? AppColors.surfaceContainerLowest
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: _selectedMainTab == 1
                      ? const [
                          BoxShadow(
                            color: Color(0x0A000000),
                            blurRadius: 4,
                            offset: Offset(0, 1),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.assignment_outlined,
                      size: 16,
                      color: _selectedMainTab == 1
                          ? AppColors.primaryContainer
                          : AppColors.secondary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Kebutuhan Dicari',
                      style: AppTypography.labelMd(
                        color: _selectedMainTab == 1
                            ? AppColors.primaryContainer
                            : AppColors.secondary,
                      ).copyWith(
                        fontWeight: _selectedMainTab == 1
                            ? FontWeight.w700
                            : FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRequestsTab() {
    if (widget.materialRequestViewModel == null) {
      return const Center(
        child: Text('Layanan Kebutuhan Material belum diinisialisasi.'),
      );
    }

    final reqVm = widget.materialRequestViewModel!;
    return ListenableBuilder(
      listenable: reqVm,
      builder: (context, _) {
        return RefreshIndicator(
          onRefresh: () => reqVm.loadRequests(),
          color: AppColors.primaryContainer,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.secondaryContainer
                              .withValues(alpha: 0.35),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.secondary.withValues(alpha: 0.25),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.bolt,
                              color: AppColors.primary,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Daftar kebutuhan material plastik yang dicari pengguna. Gunakan Smart Matching untuk menemukan material yang cocok.',
                                style: AppTypography.bodySm(
                                  color: AppColors.onSurface,
                                ).copyWith(fontSize: 11.5, height: 1.35),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildRequestPolymerChipsRow(reqVm),
                      const SizedBox(height: 10),
                    ],
                  ),
                ),
              ),
              if (reqVm.isLoading)
                const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (reqVm.errorMessage != null && reqVm.requests.isEmpty)
                SliverFillRemaining(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.cloud_off,
                              size: 48, color: Colors.redAccent),
                          const SizedBox(height: 12),
                          Text(
                            'Gagal Memuat Kebutuhan',
                            style: AppTypography.headlineSm(
                              color: AppColors.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            reqVm.errorMessage!,
                            style:
                                AppTypography.bodySm(color: AppColors.outline),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: () => reqVm.loadRequests(),
                            icon: const Icon(Icons.refresh, size: 18),
                            label: const Text('Coba Lagi'),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else if (reqVm.requests.isEmpty)
                SliverFillRemaining(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.assignment_outlined,
                            size: 48,
                            color: AppColors.outlineVariant,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Belum Ada Kebutuhan Material',
                            style: AppTypography.headlineSm(
                              color: AppColors.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Jadilah yang pertama mengajukan kebutuhan material plastik.',
                            style:
                                AppTypography.bodySm(color: AppColors.outline),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => CreateMaterialRequestScreen(
                                    viewModel: reqVm,
                                  ),
                                ),
                              );
                            },
                            icon: const Icon(Icons.add, size: 18),
                            label: const Text('Ajukan Kebutuhan Sekarang'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryContainer,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final req = reqVm.requests[index];
                        return _buildRequestCard(req);
                      },
                      childCount: reqVm.requests.length,
                    ),
                  ),
                ),
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRequestPolymerChipsRow(MaterialRequestViewModel reqVm) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: reqVm.categories.map((cat) {
          final isSelected = reqVm.selectedCategory == cat;
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: ChoiceChip(
              label: Text(cat),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  reqVm.selectCategory(cat);
                }
              },
              selectedColor: AppColors.primaryContainer,
              labelStyle: AppTypography.labelSm(
                color: isSelected ? Colors.white : AppColors.onSurface,
              ).copyWith(
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
              backgroundColor: AppColors.surfaceContainerLowest,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(999),
                side: BorderSide(
                  color: isSelected
                      ? AppColors.primaryContainer
                      : AppColors.outline.withValues(alpha: 0.15),
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              showCheckmark: false,
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildRequestCard(MaterialRequestItem req) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.outline.withValues(alpha: 0.2),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            if (widget.materialRequestViewModel != null &&
                widget.matchingViewModel != null) {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => MaterialRequestDetailScreen(
                    requestId: req.id,
                    initialItem: req,
                    viewModel: widget.materialRequestViewModel!,
                    matchingViewModel: widget.matchingViewModel!,
                    marketplaceViewModel: widget.viewModel,
                    authViewModel: widget.authViewModel,
                    addressViewModel: widget.addressViewModel,
                    shippingRepository: widget.shippingRepository,
                  ),
                ),
              );
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color:
                            AppColors.primaryContainer.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Polimer: ${req.categoryLabel}',
                        style: AppTypography.labelSm(
                          color: AppColors.primaryContainer,
                        ).copyWith(fontWeight: FontWeight.w700),
                      ),
                    ),
                    Text(
                      req.formattedWeight,
                      style: AppTypography.labelLg(color: AppColors.onSurface)
                          .copyWith(fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  req.intendedUse,
                  style: AppTypography.bodyMd(color: AppColors.onSurface)
                      .copyWith(fontWeight: FontWeight.w600),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 12,
                  runSpacing: 4,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.clean_hands_outlined,
                          size: 14,
                          color: AppColors.secondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Min. ${req.conditionLabel}',
                          style: AppTypography.bodySm(
                            color: AppColors.onSurfaceVariant,
                          ).copyWith(fontSize: 11.5),
                        ),
                      ],
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          size: 14,
                          color: AppColors.secondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          req.generalLocation,
                          style: AppTypography.bodySm(
                            color: AppColors.onSurfaceVariant,
                          ).copyWith(fontSize: 11.5),
                        ),
                      ],
                    ),
                    if (req.requesterName != null)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.person_outline,
                            size: 14,
                            color: AppColors.secondary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            req.requesterName!,
                            style: AppTypography.bodySm(
                              color: AppColors.onSurfaceVariant,
                            ).copyWith(fontSize: 11.5),
                          ),
                        ],
                      ),
                  ],
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  height: 40,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      if (widget.matchingViewModel != null) {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => MatchingResultsScreen(
                              matchingViewModel: widget.matchingViewModel!,
                              marketplaceViewModel: widget.viewModel,
                              authViewModel: widget.authViewModel,
                              addressViewModel: widget.addressViewModel,
                              shippingRepository: widget.shippingRepository,
                              requestId: req.id,
                              title: 'Material Cocok: ${req.categoryLabel}',
                            ),
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.bolt, size: 18, color: Colors.white),
                    label: Text(
                      'Smart Matching (Cari Material)',
                      style: AppTypography.labelMd(color: Colors.white)
                          .copyWith(fontWeight: FontWeight.w700),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryContainer,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 1,
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

  Widget _buildCreateRequestFAB(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8, right: 4),
      child: FloatingActionButton.extended(
        onPressed: () {
          if (widget.materialRequestViewModel != null) {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => CreateMaterialRequestScreen(
                  viewModel: widget.materialRequestViewModel!,
                ),
              ),
            );
          }
        },
        elevation: 4,
        highlightElevation: 6,
        backgroundColor: AppColors.primaryContainer,
        foregroundColor: Colors.white,
        shape: const StadiumBorder(),
        icon: const Icon(Icons.post_add, size: 20, color: Colors.white),
        label: Text(
          'Ajukan Kebutuhan',
          style: AppTypography.labelLg(color: Colors.white)
              .copyWith(fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

  /// 1. Integrated Search Bar with Filter button
  Widget _buildSearchBar() {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 46,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(14),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x0820312A),
                  blurRadius: 6,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (val) => widget.viewModel.updateSearchQuery(val),
              style: AppTypography.bodyMd(color: AppColors.onSurface),
              decoration: InputDecoration(
                filled: false,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                isDense: true,
                hintText: 'Cari jenis plastik, material, atau lokasi...',
                hintStyle: AppTypography.bodyMd(
                  color: AppColors.outlineVariant,
                ),
                prefixIcon: const Icon(
                  Icons.search,
                  size: 20,
                  color: AppColors.secondary,
                ),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 16),
                        onPressed: () {
                          _searchController.clear();
                          widget.viewModel.updateSearchQuery('', immediate: true);
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(14),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0820312A),
                blurRadius: 6,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () {
                _showFilterModal(context);
              },
              child: Stack(
                alignment: Alignment.center,
                children: [
                  const Icon(
                    Icons.tune,
                    size: 20,
                    color: AppColors.onSurface,
                  ),
                  if (widget.viewModel.hasActiveAdvancedFilters)
                    Positioned(
                      top: 10,
                      right: 10,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: AppColors.primaryContainer,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// 2. Interactive Filter Chips row (No fake SnackBars!)
  Widget _buildDropdownFilterRow() {
    final vm = widget.viewModel;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildFilterChipButton(
            icon: Icons.tune,
            label: 'Filter Lanjutan',
            isActive: vm.hasActiveAdvancedFilters,
            badgeCount: vm.activeFilterCount > 0 ? vm.activeFilterCount : null,
            onTap: () => _showFilterModal(context),
          ),
          const SizedBox(width: 8),
          _buildFilterChipButton(
            icon: Icons.clean_hands,
            label: vm.selectedCondition == 'Semua'
                ? 'Kondisi'
                : _formatConditionLabel(vm.selectedCondition),
            isActive: vm.selectedCondition != 'Semua',
            onTap: () => _showFilterModal(context),
          ),
          const SizedBox(width: 8),
          _buildFilterChipButton(
            icon: Icons.scale,
            label: (vm.minWeight != null || vm.maxWeight != null)
                ? '${vm.minWeight ?? 0}-${vm.maxWeight != null ? '${vm.maxWeight}kg' : 'max'}'
                : 'Rentang Berat',
            isActive: vm.minWeight != null || vm.maxWeight != null,
            onTap: () => _showFilterModal(context),
          ),
          const SizedBox(width: 8),
          _buildFilterChipButton(
            icon: Icons.location_on,
            label: (vm.locationFilter != null && vm.locationFilter!.isNotEmpty)
                ? vm.locationFilter!
                : 'Lokasi',
            isActive: vm.locationFilter != null && vm.locationFilter!.isNotEmpty,
            onTap: () => _showFilterModal(context),
          ),
          if (vm.hasActiveAdvancedFilters || vm.selectedCategory != 'Semua') ...[
            const SizedBox(width: 8),
            InkWell(
              onTap: () {
                _searchController.clear();
                vm.resetFilters();
              },
              borderRadius: BorderRadius.circular(999),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.close, size: 14, color: Colors.red.shade700),
                    const SizedBox(width: 4),
                    Text(
                      'Reset',
                      style: AppTypography.labelMd(color: Colors.red.shade700),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFilterChipButton({
    required IconData icon,
    required String label,
    required bool isActive,
    int? badgeCount,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isActive
              ? AppColors.primaryContainer.withValues(alpha: 0.12)
              : AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: isActive ? AppColors.primaryContainer : Colors.transparent,
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0620312A),
              blurRadius: 4,
              offset: Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 15,
              color: isActive ? AppColors.primaryContainer : AppColors.secondary,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: AppTypography.labelMd(
                color: isActive ? AppColors.primaryContainer : AppColors.onSurface,
              ).copyWith(fontWeight: isActive ? FontWeight.w700 : FontWeight.w500),
            ),
            if (badgeCount != null) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: const BoxDecoration(
                  color: AppColors.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '$badgeCount',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ] else ...[
              const SizedBox(width: 4),
              Icon(
                Icons.expand_more,
                size: 16,
                color: isActive ? AppColors.primaryContainer : AppColors.secondary,
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatConditionLabel(String condition) {
    switch (condition.toLowerCase()) {
      case 'clean':
        return 'Bersih';
      case 'slightly_dirty':
      case 'light':
        return 'Sedikit Kotor';
      case 'dirty':
        return 'Belum Dicuci';
      case 'mixed':
        return 'Campuran';
      default:
        return condition;
    }
  }

  /// 3. Polymer category filter chips
  Widget _buildPolymerChipsRow() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: widget.viewModel.categories.map((cat) {
          final isSelected = widget.viewModel.selectedCategory == cat;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: InkWell(
              onTap: () => widget.viewModel.selectCategory(cat),
              borderRadius: BorderRadius.circular(999),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primaryContainer
                      : AppColors.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(999),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x0620312A),
                      blurRadius: 4,
                      offset: Offset(0, 1),
                    ),
                  ],
                ),
                child: Text(
                  cat,
                  style:
                      AppTypography.labelMd(
                        color: isSelected
                            ? Colors.white
                            : AppColors.onSurfaceVariant,
                      ).copyWith(
                        fontWeight: isSelected
                            ? FontWeight.w700
                            : FontWeight.w600,
                      ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  /// 4. Listing Card in 2-Column Grid
  Widget _buildListingCard(BuildContext context, MaterialListing item) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0820312A),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => MaterialDetailScreen(
                    materialId: item.id,
                    initialMaterial: item,
                    viewModel: widget.viewModel,
                    authViewModel: widget.authViewModel,
                    matchingViewModel: widget.matchingViewModel,
                    addressViewModel: widget.addressViewModel,
                    shippingRepository: widget.shippingRepository,
                    orderViewModel: widget.orderViewModel,
                  ),
                ),
              );
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AspectRatio(
                  aspectRatio: 1,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (item.imageUrl != null &&
                          item.imageUrl!.startsWith('http'))
                        Image.network(
                          item.imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              _buildCardFallbackImage(item),
                        )
                      else
                        _buildCardFallbackImage(item),
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.secondaryContainer.withValues(
                              alpha: 0.92,
                            ),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            item.status == 'available' ? 'Tersedia' : item.status,
                            style: AppTypography.labelSm(
                              color: AppColors.onSecondaryContainer,
                            ).copyWith(fontWeight: FontWeight.w700, fontSize: 10),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: GestureDetector(
                          onTap: () => widget.viewModel.toggleFavorite(item.id),
                          child: Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: AppColors.surfaceContainerLowest.withValues(
                                alpha: 0.85,
                              ),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              item.isFavorited
                                  ? Icons.bookmark
                                  : Icons.bookmark_border,
                              size: 16,
                              color: item.isFavorited
                                  ? AppColors.primaryContainer
                                  : AppColors.secondary,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.name,
                          style:
                              AppTypography.labelLg(color: AppColors.onSurface),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${item.weightKg.toStringAsFixed(1)} kg · ${item.conditionLabel}',
                          style: AppTypography.bodySm(
                            color: AppColors.onSurfaceVariant,
                          ).copyWith(fontSize: 11),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            const Icon(
                              Icons.location_on,
                              size: 12,
                              color: AppColors.outline,
                            ),
                            const SizedBox(width: 2),
                            Expanded(
                              child: Text(
                                item.distanceKm != null
                                    ? '${item.generalLocation} · ${item.distanceKm} km'
                                    : item.generalLocation,
                                style: AppTypography.labelSm(
                                  color: AppColors.outline,
                                ).copyWith(fontSize: 10.5),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        if (item.ownerName != null && item.ownerName!.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              const Icon(
                                Icons.person_outline,
                                size: 11,
                                color: AppColors.outline,
                              ),
                              const SizedBox(width: 2),
                              Expanded(
                                child: Text(
                                  item.ownerName!,
                                  style: AppTypography.labelSm(
                                    color: AppColors.outline,
                                  ).copyWith(fontSize: 10),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                        const Spacer(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            if (item.isFree)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.secondaryContainer,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  'Gratis',
                                  style: AppTypography.labelSm(
                                    color: AppColors.onSecondaryContainer,
                                  ).copyWith(fontWeight: FontWeight.w700),
                                ),
                              )
                            else
                              Flexible(
                                child: Text(
                                  item.formattedPrice,
                                  style: AppTypography.headlineSm(
                                    color: AppColors.primaryContainer,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            Icon(
                              item.isFree
                                  ? Icons.volunteer_activism
                                  : Icons.eco,
                              size: 16,
                              color: AppColors.primaryContainer,
                            ),
                          ],
                        ),
                      ],
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

  Widget _buildCardFallbackImage(MaterialListing item) {
    if (item.localAsset != null) {
      return Image.asset(
        item.localAsset!,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Container(
          color: AppColors.surfaceContainer,
          child: const Icon(
            Icons.recycling,
            size: 36,
            color: AppColors.secondary,
          ),
        ),
      );
    }
    return Container(
      color: AppColors.surfaceContainer,
      child: const Icon(
        Icons.recycling,
        size: 36,
        color: AppColors.secondary,
      ),
    );
  }

  /// 5. Floating Action Button: "Tawarkan Material"
  Widget _buildOfferMaterialFAB(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8, right: 4),
      child: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => CreateMaterialListingScreen(
                viewModel: widget.viewModel,
                shippingRepository: widget.shippingRepository,
              ),
            ),
          );
        },
        elevation: 4,
        highlightElevation: 6,
        backgroundColor: AppColors.primaryContainer,
        foregroundColor: Colors.white,
        shape: const StadiumBorder(),
        icon: const Icon(Icons.add, size: 20, color: Colors.white),
        label: Text(
          'Tawarkan Material',
          style: AppTypography.labelLg(color: Colors.white)
              .copyWith(fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

  void _showFilterModal(BuildContext context) {
    final vm = widget.viewModel;
    String tempCategory = vm.selectedCategory;
    String tempCondition = vm.selectedCondition;
    final minWeightCtrl = TextEditingController(
      text: vm.minWeight != null ? vm.minWeight.toString() : '',
    );
    final maxWeightCtrl = TextEditingController(
      text: vm.maxWeight != null ? vm.maxWeight.toString() : '',
    );
    final locationCtrl = TextEditingController(
      text: vm.locationFilter ?? '',
    );
    String? validationError;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      backgroundColor: AppColors.surfaceContainerLowest,
      builder: (modalContext) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                top: 20,
                left: 20,
                right: 20,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Filter Lanjutan Material',
                          style:
                              AppTypography.headlineSm(color: AppColors.onSurface),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.of(modalContext).pop(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Kategori
                    Text(
                      'Kategori Polimer',
                      style: AppTypography.labelMd(color: AppColors.onSurface),
                    ),
                    const SizedBox(height: 8),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: vm.categories.map((cat) {
                          final selected = tempCategory == cat;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: FilterChip(
                              label: Text(cat),
                              selected: selected,
                              onSelected: (val) {
                                setModalState(() => tempCategory = cat);
                              },
                              selectedColor: AppColors.primaryContainer,
                              labelStyle: AppTypography.labelSm(
                                color: selected
                                    ? Colors.white
                                    : AppColors.onSurface,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Kondisi
                    Text(
                      'Kondisi Material',
                      style: AppTypography.labelMd(color: AppColors.onSurface),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildConditionChip(
                          label: 'Semua',
                          value: 'Semua',
                          selectedValue: tempCondition,
                          onSelect: (v) =>
                              setModalState(() => tempCondition = v),
                        ),
                        _buildConditionChip(
                          label: 'Bersih & Kering',
                          value: 'clean',
                          selectedValue: tempCondition,
                          onSelect: (v) =>
                              setModalState(() => tempCondition = v),
                        ),
                        _buildConditionChip(
                          label: 'Sedikit Kotor',
                          value: 'slightly_dirty',
                          selectedValue: tempCondition,
                          onSelect: (v) =>
                              setModalState(() => tempCondition = v),
                        ),
                        _buildConditionChip(
                          label: 'Belum Dicuci',
                          value: 'dirty',
                          selectedValue: tempCondition,
                          onSelect: (v) =>
                              setModalState(() => tempCondition = v),
                        ),
                        _buildConditionChip(
                          label: 'Campuran',
                          value: 'mixed',
                          selectedValue: tempCondition,
                          onSelect: (v) =>
                              setModalState(() => tempCondition = v),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Rentang Berat
                    Text(
                      'Rentang Berat (kg)',
                      style: AppTypography.labelMd(color: AppColors.onSurface),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: minWeightCtrl,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration: const InputDecoration(
                              labelText: 'Min (kg)',
                              hintText: '0',
                              isDense: true,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text('-'),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: maxWeightCtrl,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration: const InputDecoration(
                              labelText: 'Max (kg)',
                              hintText: '100',
                              isDense: true,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Lokasi
                    Text(
                      'Lokasi Wilayah',
                      style: AppTypography.labelMd(color: AppColors.onSurface),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: locationCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Cari Kota / Kabupaten',
                        hintText: 'contoh: Bandung, Jakarta...',
                        prefixIcon: Icon(Icons.location_on, size: 20),
                        isDense: true,
                      ),
                    ),
                    if (validationError != null) ...[
                      const SizedBox(height: 10),
                      Text(
                        validationError!,
                        style: AppTypography.bodySm(color: Colors.redAccent),
                      ),
                    ],
                    const SizedBox(height: 20),

                    // Action buttons: Reset & Terapkan Filter
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              minWeightCtrl.clear();
                              maxWeightCtrl.clear();
                              locationCtrl.clear();
                              setModalState(() {
                                tempCategory = 'Semua';
                                tempCondition = 'Semua';
                                validationError = null;
                              });
                              vm.resetFilters();
                              Navigator.of(modalContext).pop();
                            },
                            child: const Text('Reset'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton(
                            onPressed: () {
                              final minW = double.tryParse(
                                minWeightCtrl.text.trim(),
                              );
                              final maxW = double.tryParse(
                                maxWeightCtrl.text.trim(),
                              );

                              if (minW != null && maxW != null && minW > maxW) {
                                setModalState(() {
                                  validationError =
                                      'Berat minimum tidak boleh melebihi berat maksimum.';
                                });
                                return;
                              }

                              vm.applyAdvancedFilters(
                                category: tempCategory,
                                condition: tempCondition,
                                minWeight: minW,
                                maxWeight: maxW,
                                location: locationCtrl.text.trim().isNotEmpty
                                    ? locationCtrl.text.trim()
                                    : null,
                              );
                              Navigator.of(modalContext).pop();
                            },
                            child: const Text('Terapkan Filter'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildConditionChip({
    required String label,
    required String value,
    required String selectedValue,
    required ValueChanged<String> onSelect,
  }) {
    final selected = selectedValue == value;
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onSelect(value),
      selectedColor: AppColors.primaryContainer,
      labelStyle: AppTypography.labelSm(
        color: selected ? Colors.white : AppColors.onSurface,
      ),
    );
  }
}
