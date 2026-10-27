import 'package:flutter/material.dart';

import '../../core/constants/app_assets.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/plasvora_header.dart';
import '../../models/material_listing.dart';
import '../../viewmodels/home_viewmodel.dart';
import '../../viewmodels/navigation_viewmodel.dart';

class HomeScreen extends StatelessWidget {
  final HomeViewModel viewModel;
  final NavigationViewModel navigationViewModel;

  const HomeScreen({
    super.key,
    required this.viewModel,
    required this.navigationViewModel,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const PlasvoraHeader(),
      body: ListenableBuilder(
        listenable: viewModel,
        builder: (context, _) {
          return SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildEditorialHeroCard(),
                      const SizedBox(height: 16),
                      _buildPrimaryScanCard(),
                      const SizedBox(height: 24),
                      _buildQuickActions(context),
                      const SizedBox(height: 24),
                      _buildImpactSummary(context),
                      const SizedBox(height: 24),
                      _buildMarketplacePreview(context),
                      const SizedBox(height: 20),
                      _buildCircularTipBanner(),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  /// 1. Editorial Motivational Card
  Widget _buildEditorialHeroCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0820312A),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            Positioned(
              right: 0,
              top: 0,
              bottom: 0,
              width: 170,
              child: Opacity(
                opacity: 0.45,
                child: Image.asset(
                  AppAssets.forestHero,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      const SizedBox(),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerLowest.withValues(
                        alpha: 0.85,
                      ),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: AppColors.primaryContainer,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Sirkularitas Lokal',
                          style: AppTypography.labelSm(color: AppColors.primary)
                              .copyWith(fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 240),
                    child: Text(
                      'Beri Plastik Kesempatan Kedua',
                      style: AppTypography.headlineLgMobile(
                        color: AppColors.onSurface,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 230),
                    child: Text(
                      'Ubah limbah anorganik menjadi sumber daya bernilai untuk lingkungan lebih lestari.',
                      style: AppTypography.bodySm(
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 2. Primary Scan Action Card
  Widget _buildPrimaryScanCard() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => navigationViewModel.goToAnalysis(),
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          decoration: BoxDecoration(
            color: AppColors.primaryContainer,
            borderRadius: BorderRadius.circular(20),
            boxShadow: const [
              BoxShadow(
                color: Color(0x26205B46),
                blurRadius: 14,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned(
                right: -10,
                bottom: -20,
                child: Opacity(
                  opacity: 0.12,
                  child: const Icon(
                    Icons.document_scanner,
                    size: 130,
                    color: Colors.white,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 16,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.document_scanner,
                        color: AppColors.primaryFixed,
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'Pindai Material',
                                style: AppTypography.headlineSm(
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryFixed,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  'AI Ready',
                                  style:
                                      AppTypography.labelSm(
                                        color: AppColors.onPrimaryFixed,
                                      ).copyWith(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 10,
                                      ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Dapatkan analisis material & ide upcycling instan',
                            style: AppTypography.bodySm(
                              color: AppColors.primaryFixedDim,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 38,
                      height: 38,
                      decoration: const BoxDecoration(
                        color: AppColors.surfaceContainerLowest,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.arrow_forward,
                        color: AppColors.primaryContainer,
                        size: 20,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 3. Aksi Cepat (Quick Actions)
  Widget _buildQuickActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Aksi Cepat',
              style: AppTypography.headlineSm(color: AppColors.onSurface),
            ),
            GestureDetector(
              onTap: () => navigationViewModel.goToMarketplace(),
              child: Row(
                children: [
                  Text(
                    'Lihat semua',
                    style: AppTypography.labelMd(color: AppColors.primary),
                  ),
                  const Icon(
                    Icons.chevron_right,
                    size: 16,
                    color: AppColors.primary,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildActionTile(
                icon: Icons.auto_awesome,
                title: 'Analisis',
                desc: 'Cek jenis & ide daur ulang',
                onTap: () => navigationViewModel.goToAnalysis(),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildActionTile(
                icon: Icons.search,
                title: 'Cari Stok',
                desc: 'Eksplorasi stok terdekat',
                onTap: () => navigationViewModel.goToMarketplace(),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildActionTile(
                icon: Icons.handshake_outlined,
                title: 'Tawarkan',
                desc: 'Setor ke mitra pengolah',
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Fitur Tambah Penawaran dibuka di Marketplace!',
                      ),
                      behavior: SnackBarBehavior.floating,
                      duration: Duration(seconds: 2),
                    ),
                  );
                  navigationViewModel.goToMarketplace();
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String title,
    required String desc,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        height: 120,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(18),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0820312A),
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.secondaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                size: 20,
                color: AppColors.onSecondaryContainer,
              ),
            ),
            const Spacer(),
            Text(
              title,
              style: AppTypography.labelLg(color: AppColors.onSurface),
            ),
            const SizedBox(height: 2),
            Text(
              desc,
              style: AppTypography.bodySm(color: AppColors.onSurfaceVariant)
                  .copyWith(fontSize: 10.5, height: 1.2),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  /// 4. Jejak Kontribusi (Impact Summary)
  Widget _buildImpactSummary(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Text(
                  'Jejak Kontribusi',
                  style: AppTypography.headlineSm(color: AppColors.onSurface),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainer,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    'Demo',
                    style: AppTypography.labelSm(color: AppColors.secondary)
                        .copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainer,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Row(
                children: [
                  Text(
                    'Bulan ini',
                    style: AppTypography.labelSm(
                      color: AppColors.onSurfaceVariant,
                    ).copyWith(fontWeight: FontWeight.w600),
                  ),
                  const Icon(
                    Icons.expand_more,
                    size: 14,
                    color: AppColors.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                icon: Icons.inventory_2_outlined,
                iconColor: AppColors.secondary,
                label: 'Terdaftar',
                value: viewModel.registeredKg.toStringAsFixed(1),
                unit: 'kg',
                sublabel: 'Material terdata',
                highlightValue: false,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildStatCard(
                icon: Icons.local_shipping_outlined,
                iconColor: AppColors.primaryContainer,
                label: 'Diserahkan',
                value: viewModel.handedOverKg.toStringAsFixed(1),
                unit: 'kg',
                sublabel: 'Terkirim mitra',
                highlightValue: true,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildStatCard(
                icon: Icons.recycling,
                iconColor: AppColors.primary,
                label: 'Dikelola',
                value: viewModel.processedKg.toStringAsFixed(1),
                unit: 'kg',
                sublabel: 'Telah diolah',
                highlightValue: true,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    required String unit,
    required String sublabel,
    required bool highlightValue,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0820312A),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: iconColor),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  label,
                  style: AppTypography.labelSm(color: iconColor)
                      .copyWith(fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: value,
                  style: AppTypography.headlineMd(
                    color: highlightValue
                        ? AppColors.primaryContainer
                        : AppColors.onSurface,
                  ).copyWith(fontWeight: FontWeight.w700),
                ),
                TextSpan(
                  text: ' $unit',
                  style: AppTypography.bodySm(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            sublabel,
            style: AppTypography.labelSm(color: AppColors.onSurfaceVariant)
                .copyWith(fontSize: 10),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  /// 5. Pasar Terkini (Marketplace Preview)
  Widget _buildMarketplacePreview(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pasar Terkini',
                  style: AppTypography.headlineSm(color: AppColors.onSurface),
                ),
                Text(
                  'Material siap pakai di sekitarmu',
                  style: AppTypography.bodySm(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            GestureDetector(
              onTap: () => navigationViewModel.goToMarketplace(),
              child: Row(
                children: [
                  Text(
                    'Lihat semua',
                    style: AppTypography.labelMd(color: AppColors.primary),
                  ),
                  const Icon(
                    Icons.chevron_right,
                    size: 16,
                    color: AppColors.primary,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (viewModel.isLoading)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(24.0),
              child: CircularProgressIndicator(),
            ),
          )
        else
          Row(
            children: viewModel.recentListings.map((item) {
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    right: item == viewModel.recentListings.first ? 6 : 0,
                    left: item == viewModel.recentListings.last ? 6 : 0,
                  ),
                  child: _buildListingCard(context, item),
                ),
              );
            }).toList(),
          ),
      ],
    );
  }

  Widget _buildListingCard(BuildContext context, MaterialListing item) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A20312A),
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
                      onTap: () => viewModel.toggleFavorite(item.id),
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
                              ? Icons.favorite
                              : Icons.favorite_border,
                          size: 16,
                          color: item.isFavorited
                              ? AppColors.error
                              : AppColors.secondary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: AppTypography.labelLg(color: AppColors.onSurface),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Text(
                        '${item.weightKg.toStringAsFixed(0)} kg',
                        style: AppTypography.bodySm(
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '•',
                        style: AppTypography.bodySm(
                          color: AppColors.outlineVariant,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          item.condition == 'clean' ? 'Bersih' : 'Siap Olah',
                          style: AppTypography.bodySm(
                            color: AppColors.primaryContainer,
                          ).copyWith(fontWeight: FontWeight.w600),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
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
                          '${item.generalLocation} • ${item.distanceKm} km',
                          style: AppTypography.bodySm(
                            color: AppColors.textSecondary,
                          ).copyWith(fontSize: 10.5),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
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
                            style: AppTypography.labelMd(
                              color: AppColors.primary,
                            ).copyWith(fontWeight: FontWeight.w700),
                          ),
                        )
                      else
                        Text(
                          item.formattedPrice,
                          style: AppTypography.labelLg(color: AppColors.primary)
                              .copyWith(fontWeight: FontWeight.w700),
                        ),
                      Icon(
                        item.isFree ? Icons.volunteer_activism : Icons.eco,
                        size: 18,
                        color: AppColors.primaryContainer,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 6. Circular Tip Banner
  Widget _buildCircularTipBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(
              color: AppColors.surfaceContainerLowest,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.lightbulb_outline,
              size: 20,
              color: AppColors.primaryContainer,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: AppTypography.bodySm(color: AppColors.onSurface),
                children: [
                  TextSpan(
                    text: 'Tips Sirkular: ',
                    style: AppTypography.bodySm(color: AppColors.primary)
                        .copyWith(fontWeight: FontWeight.w700),
                  ),
                  const TextSpan(
                    text: 'Bersihkan residu cairan pada botol PET sebelum dipilah agar bernilai tukar lebih tinggi.',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
