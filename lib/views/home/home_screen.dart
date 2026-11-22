import 'package:flutter/material.dart';

import '../../core/constants/app_assets.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/phone_utils.dart';
import '../../core/widgets/plasvora_header.dart';
import '../../models/material_listing.dart';
import '../../repositories/shipping_repository.dart';
import '../../viewmodels/address_viewmodel.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/home_viewmodel.dart';
import '../../viewmodels/navigation_viewmodel.dart';
import '../../viewmodels/order_viewmodel.dart';
import '../address/address_list_screen.dart';
import '../auth/login_screen.dart';
import '../orders/order_list_screen.dart';

class HomeScreen extends StatelessWidget {
  final HomeViewModel viewModel;
  final NavigationViewModel navigationViewModel;
  final AuthViewModel? authViewModel;
  final AddressViewModel? addressViewModel;
  final ShippingRepository? shippingRepository;
  final OrderViewModel? orderViewModel;

  const HomeScreen({
    super.key,
    required this.viewModel,
    required this.navigationViewModel,
    this.authViewModel,
    this.addressViewModel,
    this.shippingRepository,
    this.orderViewModel,
  });

  void _showAuthModal(BuildContext hostContext) {
    final authVm = authViewModel;
    if (authVm == null) return;

    if (authVm.isAuthenticated) {
      showModalBottomSheet<void>(
        context: hostContext,
        isScrollControlled: true,
        backgroundColor: AppColors.surfaceContainerLowest,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (sheetBuilderContext) {
          return _ProfileAccountSheet(
            authViewModel: authVm,
            hasOrders: orderViewModel != null,
            hasAddressBook:
                addressViewModel != null && shippingRepository != null,
            onOpenOrdersAfterClose: (routeCompleted) =>
                _openOrdersAfterModalClose(
                  hostContext: hostContext,
                  routeCompleted: routeCompleted,
                ),
            onOpenAddressesAfterClose: (routeCompleted) =>
                _openAddressesAfterModalClose(
                  hostContext: hostContext,
                  routeCompleted: routeCompleted,
                ),
            onLogoutAfterClose: (routeCompleted) => _logoutAfterModalClose(
              hostContext: hostContext,
              authVm: authVm,
              routeCompleted: routeCompleted,
            ),
          );
        },
      );
    } else {
      Navigator.of(hostContext).push(
        MaterialPageRoute(
          builder: (_) => LoginScreen(
            authViewModel: authVm,
          ),
        ),
      );
    }
  }

  Future<void> _openOrdersAfterModalClose({
    required BuildContext hostContext,
    required Future<dynamic>? routeCompleted,
  }) async {
    final orderVm = orderViewModel;
    if (orderVm == null) return;

    final navigator = Navigator.of(hostContext);
    if (routeCompleted != null) {
      await routeCompleted;
    }
    if (!navigator.mounted) return;

    navigator.push(
      MaterialPageRoute(
        builder: (_) => OrderListScreen(
          orderViewModel: orderVm,
          authViewModel: authViewModel,
        ),
      ),
    );
  }

  Future<void> _openAddressesAfterModalClose({
    required BuildContext hostContext,
    required Future<dynamic>? routeCompleted,
  }) async {
    final addressVm = addressViewModel;
    final shippingRepo = shippingRepository;
    if (addressVm == null || shippingRepo == null) return;

    final navigator = Navigator.of(hostContext);
    if (routeCompleted != null) {
      await routeCompleted;
    }
    if (!navigator.mounted) return;

    navigator.push(
      MaterialPageRoute(
        builder: (_) => AddressListScreen(
          addressViewModel: addressVm,
          shippingRepository: shippingRepo,
        ),
      ),
    );
  }

  Future<void> _logoutAfterModalClose({
    required BuildContext hostContext,
    required AuthViewModel authVm,
    required Future<dynamic>? routeCompleted,
  }) async {
    final messenger = ScaffoldMessenger.maybeOf(hostContext);

    if (routeCompleted != null) {
      await routeCompleted;
    }

    // Bersihkan cache alamat dan transaksi pengguna sebelum sesi berpindah akun.
    addressViewModel?.clearUserData();
    orderViewModel?.clearUserData();
    await authVm.logout();

    if (messenger != null && messenger.mounted) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text(
            'Anda telah berhasil keluar.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PlasvoraHeader(
        onAvatarTap: () => _showAuthModal(context),
      ),
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
              top: -18,
              bottom: 0,
              width: 170,
              child: Opacity(
                opacity: 0.45,
                child: Image.asset(
                  AppAssets.forestHero,
                  fit: BoxFit.cover,
                  alignment: Alignment.bottomRight,
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
                GestureDetector(
                  onTap: viewModel.impactErrorMessage != null
                      ? () => viewModel.loadImpactSummary()
                      : null,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: viewModel.impactErrorMessage != null
                          ? const Color(0xFFFFEBEE)
                          : AppColors.surfaceContainer,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      viewModel.isImpactLoading
                          ? 'Memuat...'
                          : (viewModel.impactErrorMessage != null
                              ? 'Coba lagi'
                              : (viewModel.hasImpactData ? 'Aktual' : 'Data')),
                      style: AppTypography.labelSm(
                        color: viewModel.impactErrorMessage != null
                            ? Colors.red.shade700
                            : (viewModel.hasImpactData
                                ? AppColors.primary
                                : AppColors.secondary),
                      ).copyWith(fontWeight: FontWeight.w600),
                    ),
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
                value: viewModel.registeredKg != null
                    ? viewModel.registeredKg!.toStringAsFixed(1)
                    : (viewModel.isImpactLoading ? '...' : '-'),
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
                value: viewModel.handedOverKg != null
                    ? viewModel.handedOverKg!.toStringAsFixed(1)
                    : (viewModel.isImpactLoading ? '...' : '-'),
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
                value: viewModel.processedKg != null
                    ? viewModel.processedKg!.toStringAsFixed(1)
                    : (viewModel.isImpactLoading ? '...' : '-'),
                unit: 'kg',
                sublabel: 'Telah diolah',
                highlightValue: true,
              ),
            ),
          ],
        ),
        if (viewModel.impactErrorMessage != null) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.info_outline, size: 14, color: Colors.red.shade400),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Gagal memuat jejak dampak (${viewModel.impactErrorMessage}). Ketuk badge di atas untuk mencoba lagi.',
                  style: AppTypography.bodySm(color: Colors.red.shade700)
                      .copyWith(fontSize: 11),
                ),
              ),
            ],
          ),
        ],
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

class _ProfileAccountSheet extends StatefulWidget {
  final AuthViewModel authViewModel;
  final bool hasOrders;
  final bool hasAddressBook;
  final Future<void> Function(Future<dynamic>? routeCompleted)
      onOpenOrdersAfterClose;
  final Future<void> Function(Future<dynamic>? routeCompleted)
      onOpenAddressesAfterClose;
  final Future<void> Function(Future<dynamic>? routeCompleted)
      onLogoutAfterClose;

  const _ProfileAccountSheet({
    required this.authViewModel,
    required this.hasOrders,
    required this.hasAddressBook,
    required this.onOpenOrdersAfterClose,
    required this.onOpenAddressesAfterClose,
    required this.onLogoutAfterClose,
  });

  @override
  State<_ProfileAccountSheet> createState() => _ProfileAccountSheetState();
}

class _ProfileAccountSheetState extends State<_ProfileAccountSheet> {
  final GlobalKey<FormState> _phoneFormKey = GlobalKey<FormState>();
  late final TextEditingController _phoneController;
  late bool _whatsappPublic;
  bool _isTogglingVisibility = false;
  bool _isClosingAction = false;
  String? _localError;
  String? _localSuccess;

  @override
  void initState() {
    super.initState();
    _phoneController = TextEditingController(
      text: widget.authViewModel.currentUser?.phone ?? '',
    );
    _whatsappPublic = widget.authViewModel.currentUser?.whatsappPublic ?? false;
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _handleSavePhone() async {
    if (_isClosingAction || widget.authViewModel.isUpdatingProfile) return;
    if (!_phoneFormKey.currentState!.validate()) return;

    setState(() {
      _localError = null;
      _localSuccess = null;
    });

    final ok = await widget.authViewModel.updateProfile(
      phone: _phoneController.text.trim(),
    );
    if (!mounted) return;

    if (ok) {
      final refreshed = widget.authViewModel.currentUser;
      setState(() {
        _whatsappPublic = refreshed?.whatsappPublic ?? false;
        _localSuccess = refreshed?.phone != null
            ? 'Nomor telepon berhasil disimpan.'
            : 'Nomor telepon dihapus dan visibilitas WhatsApp dinonaktifkan.';
      });
    } else {
      setState(() {
        _localError =
            widget.authViewModel.errorMessage ??
            'Gagal memperbarui nomor telepon.';
      });
    }
  }

  Future<void> _handleToggleWhatsApp(bool newValue) async {
    if (_isTogglingVisibility ||
        _isClosingAction ||
        widget.authViewModel.isUpdatingProfile) {
      return;
    }

    final previousValue = _whatsappPublic;
    setState(() {
      _whatsappPublic = newValue;
      _isTogglingVisibility = true;
      _localError = null;
      _localSuccess = null;
    });

    final ok = await widget.authViewModel.updateProfile(
      whatsappPublic: newValue,
    );
    if (!mounted) return;

    setState(() {
      _isTogglingVisibility = false;
      if (ok) {
        _whatsappPublic =
            widget.authViewModel.currentUser?.whatsappPublic ?? newValue;
        _localSuccess = _whatsappPublic
            ? 'Nomor WhatsApp kini ditampilkan pada detail material.'
            : 'Nomor WhatsApp disembunyikan dari detail material.';
      } else {
        _whatsappPublic = previousValue;
        _localError =
            widget.authViewModel.errorMessage ??
            'Gagal menyimpan pengaturan privasi WhatsApp.';
      }
    });
  }

  void _handleOpenOrders(BuildContext sheetContext) {
    if (_isClosingAction || widget.authViewModel.isUpdatingProfile) return;

    setState(() => _isClosingAction = true);
    final activeRoute = ModalRoute.of(sheetContext);
    final routeCompleted = activeRoute?.completed;
    Navigator.of(sheetContext).pop();
    widget.onOpenOrdersAfterClose(routeCompleted);
  }

  void _handleOpenAddresses(BuildContext sheetContext) {
    if (_isClosingAction || widget.authViewModel.isUpdatingProfile) return;

    setState(() => _isClosingAction = true);
    final activeRoute = ModalRoute.of(sheetContext);
    final routeCompleted = activeRoute?.completed;
    Navigator.of(sheetContext).pop();
    widget.onOpenAddressesAfterClose(routeCompleted);
  }

  void _handleLogout(BuildContext sheetContext) {
    if (_isClosingAction || widget.authViewModel.isUpdatingProfile) return;

    setState(() => _isClosingAction = true);
    final activeRoute = ModalRoute.of(sheetContext);
    final routeCompleted = activeRoute?.completed;
    Navigator.of(sheetContext).pop();
    widget.onLogoutAfterClose(routeCompleted);
  }

  @override
  Widget build(BuildContext sheetContext) {
    return ListenableBuilder(
      listenable: widget.authViewModel,
      builder: (listenableContext, _) {
        final user = widget.authViewModel.currentUser;
        final isSaving = widget.authViewModel.isUpdatingProfile;
        final isBusy = isSaving || _isClosingAction;
        final bottomInset = MediaQuery.of(listenableContext).viewInsets.bottom;
        final hasSavedValidPhone =
            PhoneUtils.normalizeIndonesianPhone(user?.phone) != null;
        final canToggleSwitch =
            !isBusy &&
            !_isTogglingVisibility &&
            (hasSavedValidPhone || _whatsappPublic);

        return SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(24, 20, 24, 20 + bottomInset),
            child: Form(
              key: _phoneFormKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Profil Akun',
                    style: AppTypography.headlineSm(color: AppColors.primary),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    user?.name ?? 'Pengguna Plasvora',
                    style: AppTypography.labelLg(color: AppColors.onSurface),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    user?.email ?? '',
                    style: AppTypography.bodySm(
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Divider(height: 1),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          'Nomor WhatsApp / Telepon',
                          style: AppTypography.labelMd(
                            color: AppColors.onSurface,
                          ).copyWith(fontWeight: FontWeight.w600),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '(Opsional)',
                        style: AppTypography.labelSm(
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    textInputAction: TextInputAction.done,
                    decoration: InputDecoration(
                      hintText: 'Contoh: 081234567890',
                      prefixIcon: const Icon(
                        Icons.phone_outlined,
                        size: 20,
                        color: AppColors.onSurfaceVariant,
                      ),
                      filled: true,
                      fillColor: AppColors.surface,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 14,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: AppColors.outlineVariant,
                          width: 0.8,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: AppColors.outlineVariant,
                          width: 0.8,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: AppColors.primaryContainer,
                          width: 1.5,
                        ),
                      ),
                    ),
                    validator: PhoneUtils.validateOptionalIndonesianPhone,
                    onChanged: (_) {
                      if (_localError != null || _localSuccess != null) {
                        setState(() {
                          _localError = null;
                          _localSuccess = null;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 6),
                  Text(
                    hasSavedValidPhone
                        ? 'Tersimpan: ${PhoneUtils.formatForDisplay(user!.phone)}'
                        : 'Tambahkan nomor telepon untuk mengaktifkan kontak WhatsApp.',
                    style: AppTypography.labelSm(
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      icon: (isSaving && !_isTogglingVisibility)
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.save_outlined, size: 18),
                      label: Text(
                        (isSaving && !_isTogglingVisibility)
                            ? 'Menyimpan...'
                            : 'Simpan Nomor',
                        style: AppTypography.labelMd(
                          color: Colors.white,
                        ).copyWith(fontWeight: FontWeight.w600),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryContainer,
                        foregroundColor: Colors.white,
                        shape: const StadiumBorder(),
                      ),
                      onPressed: isBusy ? null : _handleSavePhone,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Pengaturan Privasi WhatsApp
                  Material(
                    color: AppColors.surface,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                      side: BorderSide(
                        color: AppColors.outlineVariant.withValues(alpha: 0.6),
                      ),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SwitchListTile.adaptive(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 6,
                          ),
                          activeTrackColor: AppColors.primaryContainer,
                          title: Text(
                            'Tampilkan nomor WhatsApp saya pada detail material',
                            style: AppTypography.labelMd(
                              color: AppColors.onSurface,
                            ).copyWith(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              'Jika diaktifkan, pengguna lain dapat melihat nomor WhatsApp Anda dan menghubungi Anda melalui halaman detail material.',
                              style: AppTypography.bodySm(
                                color: AppColors.onSurfaceVariant,
                              ),
                            ),
                          ),
                          value: _whatsappPublic,
                          onChanged:
                              !canToggleSwitch ? null : _handleToggleWhatsApp,
                        ),
                        if (!hasSavedValidPhone)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(
                                  Icons.info_outline,
                                  size: 16,
                                  color: AppColors.onSurfaceVariant,
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    'Simpan nomor telepon yang valid terlebih dahulu untuk mengaktifkan visibilitas WhatsApp.',
                                    style: AppTypography.labelSm(
                                      color: AppColors.onSurfaceVariant,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        if (_isTogglingVisibility)
                          const Padding(
                            padding: EdgeInsets.fromLTRB(14, 0, 14, 10),
                            child: LinearProgressIndicator(
                              minHeight: 2,
                              color: AppColors.primaryContainer,
                            ),
                          ),
                      ],
                    ),
                  ),

                  if (_localError != null) ...[
                    const SizedBox(height: 10),
                    Text(
                      _localError!,
                      style: AppTypography.bodySm(color: AppColors.error),
                    ),
                  ],
                  if (_localSuccess != null) ...[
                    const SizedBox(height: 10),
                    Text(
                      _localSuccess!,
                      style: AppTypography.bodySm(
                        color: AppColors.primary,
                      ).copyWith(fontWeight: FontWeight.w600),
                    ),
                  ],
                  if (widget.hasOrders) ...[
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: OutlinedButton.icon(
                        icon: const Icon(
                          Icons.receipt_long_outlined,
                          color: AppColors.primaryContainer,
                        ),
                        label: Text(
                          'Pesanan Saya',
                          style: AppTypography.labelMd(
                            color: AppColors.primaryContainer,
                          ).copyWith(fontWeight: FontWeight.w600),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(
                            color: AppColors.primaryContainer,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: isBusy
                            ? null
                            : () => _handleOpenOrders(listenableContext),
                      ),
                    ),
                  ],
                  if (widget.hasAddressBook) ...[
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: OutlinedButton.icon(
                        icon: const Icon(
                          Icons.location_on_outlined,
                          color: AppColors.primaryContainer,
                        ),
                        label: Text(
                          'Kelola Alamat Pengiriman',
                          style: AppTypography.labelMd(
                            color: AppColors.primaryContainer,
                          ).copyWith(fontWeight: FontWeight.w600),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(
                            color: AppColors.primaryContainer,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: isBusy
                            ? null
                            : () => _handleOpenAddresses(listenableContext),
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.logout, color: Colors.red),
                      label: const Text(
                        'Keluar dari Akun',
                        style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.red),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: isBusy
                          ? null
                          : () => _handleLogout(listenableContext),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
