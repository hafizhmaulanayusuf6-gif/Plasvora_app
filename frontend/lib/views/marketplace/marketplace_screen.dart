import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/plasvora_header.dart';
import '../../models/material_listing.dart';
import '../../viewmodels/marketplace_viewmodel.dart';
import '../../viewmodels/navigation_viewmodel.dart';

class MarketplaceScreen extends StatefulWidget {
  final MarketplaceViewModel viewModel;
  final NavigationViewModel navigationViewModel;

  const MarketplaceScreen({
    super.key,
    required this.viewModel,
    required this.navigationViewModel,
  });

  @override
  State<MarketplaceScreen> createState() => _MarketplaceScreenState();
}

class _MarketplaceScreenState extends State<MarketplaceScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const PlasvoraHeader(),
      floatingActionButton: _buildOfferMaterialFAB(context),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      body: ListenableBuilder(
        listenable: widget.viewModel,
        builder: (context, _) {
          return CustomScrollView(
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
                          'Coba ganti filter polimer atau kata kunci pencarian.',
                          style: AppTypography.bodySm(color: AppColors.outline),
                        ),
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
          );
        },
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
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(999),
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
                          widget.viewModel.updateSearchQuery('');
                        },
                      )
                    : null,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
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
            shape: BoxShape.circle,
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
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: () {
                _showFilterModal(context);
              },
              child: const Icon(
                Icons.tune,
                size: 20,
                color: AppColors.onSurface,
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// 2. Dropdown Filter Chips row
  Widget _buildDropdownFilterRow() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildDropdownChip('Jenis Material'),
          const SizedBox(width: 8),
          _buildDropdownChip('Kondisi'),
          const SizedBox(width: 8),
          _buildDropdownChip('Berat'),
          const SizedBox(width: 8),
          _buildDropdownChip('Jarak'),
        ],
      ),
    );
  }

  Widget _buildDropdownChip(String label) {
    return InkWell(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Filter $label diterapkan.'),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 1),
          ),
        );
      },
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(999),
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
            Text(
              label,
              style: AppTypography.labelMd(color: AppColors.onSurface),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.expand_more, size: 16, color: AppColors.secondary),
          ],
        ),
      ),
    );
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 1,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (item.localAsset != null)
                    Image.asset(
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
                    )
                  else
                    Container(
                      color: AppColors.surfaceContainer,
                      child: const Icon(
                        Icons.recycling,
                        size: 36,
                        color: AppColors.secondary,
                      ),
                    ),
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
                        'Tersedia',
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
                      style: AppTypography.labelLg(color: AppColors.onSurface),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${item.weightKg.toStringAsFixed(0)} kg · ${item.conditionLabel}',
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
                            '${item.generalLocation} · ${item.distanceKm} km',
                            style: AppTypography.labelSm(
                              color: AppColors.outline,
                            ).copyWith(fontSize: 10.5),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
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
                          item.isFree ? Icons.volunteer_activism : Icons.eco,
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
    );
  }

  /// 5. Floating Action Button: "Tawarkan Material"
  Widget _buildOfferMaterialFAB(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8, right: 4),
      child: FloatingActionButton.extended(
        onPressed: () {
          _showOfferMaterialBottomSheet(context);
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
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      backgroundColor: AppColors.surfaceContainerLowest,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Filter Lanjutan',
                    style: AppTypography.headlineSm(color: AppColors.onSurface),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Radius Jarak Maksimal',
                style: AppTypography.labelMd(color: AppColors.onSurface),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _buildModalFilterChip('< 5 km', true),
                  const SizedBox(width: 8),
                  _buildModalFilterChip('< 10 km', false),
                  const SizedBox(width: 8),
                  _buildModalFilterChip('Semua Wilayah', false),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Terapkan Filter'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildModalFilterChip(String text, bool active) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: active ? AppColors.primaryContainer : AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: AppTypography.labelSm(
          color: active ? Colors.white : AppColors.onSurface,
        ),
      ),
    );
  }

  void _showOfferMaterialBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      backgroundColor: AppColors.surfaceContainerLowest,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            top: 20,
            left: 20,
            right: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Tawarkan Material Plastik',
                style: AppTypography.headlineSm(color: AppColors.onSurface),
              ),
              const SizedBox(height: 6),
              Text(
                'Hubungkan material Anda ke pengrajin atau bank sampah terdekat.',
                style: AppTypography.bodySm(color: AppColors.onSurfaceVariant),
              ),
              const SizedBox(height: 16),
              const TextField(
                decoration: InputDecoration(
                  labelText: 'Nama Material (contoh: Tutup Botol HDPE)',
                ),
              ),
              const SizedBox(height: 12),
              const TextField(
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: 'Berat Estimasi (kg)'),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Penawaran berhasil disimpan! (Mock Data)',
                        ),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  child: const Text('Publikasikan Penawaran'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
