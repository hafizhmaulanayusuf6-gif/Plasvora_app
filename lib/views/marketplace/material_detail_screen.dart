import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/phone_utils.dart';
import '../../models/material_listing.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/marketplace_viewmodel.dart';
import '../../viewmodels/matching_viewmodel.dart';
import '../matching/matching_results_screen.dart';

class MaterialDetailScreen extends StatefulWidget {
  final int materialId;
  final MaterialListing? initialMaterial;
  final MarketplaceViewModel viewModel;
  final AuthViewModel? authViewModel;
  final MatchingViewModel? matchingViewModel;

  const MaterialDetailScreen({
    super.key,
    required this.materialId,
    this.initialMaterial,
    required this.viewModel,
    this.authViewModel,
    this.matchingViewModel,
  });

  @override
  State<MaterialDetailScreen> createState() => _MaterialDetailScreenState();
}

class _MaterialDetailScreenState extends State<MaterialDetailScreen> {
  late MaterialListing? _material;
  bool _isLoading = false;
  bool _isLaunchingWhatsApp = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _material = widget.initialMaterial;
    _fetchDetail();
  }

  Future<void> _fetchDetail() async {
    setState(() {
      _isLoading = _material == null;
      _errorMessage = null;
    });

    try {
      final detail = await widget.viewModel.getMaterialDetail(widget.materialId);
      if (mounted) {
        setState(() {
          _material = detail;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceFirst('ApiException: ', '');
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _openSellerWhatsApp(Uri uri) async {
    if (_isLaunchingWhatsApp) return;
    setState(() => _isLaunchingWhatsApp = true);

    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Tidak dapat membuka WhatsApp. Pastikan aplikasi WhatsApp atau browser terpasang.',
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Gagal membuka WhatsApp. Silakan coba lagi beberapa saat.',
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLaunchingWhatsApp = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: Text(
          'Detail Material',
          style: AppTypography.headlineSm(color: AppColors.onSurface),
        ),
        backgroundColor: AppColors.surfaceContainerLowest,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.onSurface),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          if (_material != null)
            IconButton(
              icon: Icon(
                _material!.isFavorited ? Icons.bookmark : Icons.bookmark_border,
                color: _material!.isFavorited
                    ? AppColors.primaryContainer
                    : AppColors.secondary,
              ),
              onPressed: () async {
                await widget.viewModel.toggleFavorite(_material!.id);
                setState(() {
                  _material = _material!.copyWith(
                    isFavorited: !_material!.isFavorited,
                  );
                });
              },
            ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null && _material == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
              const SizedBox(height: 12),
              Text(
                'Gagal Memuat Detail Material',
                style: AppTypography.headlineSm(color: AppColors.onSurface),
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage!,
                style: AppTypography.bodySm(color: AppColors.outline),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _fetchDetail,
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Coba Lagi'),
              ),
            ],
          ),
        ),
      );
    }

    final item = _material!;
    return RefreshIndicator(
      onRefresh: _fetchDetail,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          // 1. Gambar Material
          _buildImageBanner(item),

          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 2. Kategori Badge & Jarak
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
                        item.categoryLabel,
                        style: AppTypography.labelSm(
                          color: AppColors.primaryContainer,
                        ).copyWith(fontWeight: FontWeight.w700),
                      ),
                    ),
                    if (item.distanceKm != null)
                      Row(
                        children: [
                          const Icon(
                            Icons.near_me,
                            size: 14,
                            color: AppColors.secondary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${item.distanceKm!.toStringAsFixed(1)} km',
                            style: AppTypography.bodySm(
                              color: AppColors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
                const SizedBox(height: 12),

                // 3. Nama Material
                Text(
                  item.name,
                  style: AppTypography.headlineSm(color: AppColors.onSurface),
                ),
                const SizedBox(height: 8),

                // 4. Harga Total (Satu Lot) / Gratis Badge + Estimasi per kg (display-only)
                if (item.isFree || item.price == 0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.secondaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Gratis',
                      style: AppTypography.labelMd(
                        color: AppColors.onSecondaryContainer,
                      ).copyWith(fontWeight: FontWeight.w700),
                    ),
                  )
                else
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            item.formattedPrice,
                            style: AppTypography.headlineMd(
                              color: AppColors.primaryContainer,
                            ).copyWith(fontWeight: FontWeight.w800),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceContainer,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'Harga total (satu lot)',
                              style: AppTypography.labelSm(
                                color: AppColors.onSurfaceVariant,
                              ).copyWith(fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                      if (item.formattedEstimatedPricePerKg != null) ...[
                        const SizedBox(height: 6),
                        Text(
                          'Estimasi ~${item.formattedEstimatedPricePerKg} (perkiraan saja)',
                          style: AppTypography.bodySm(
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ),
                const SizedBox(height: 20),

                const Divider(),
                const SizedBox(height: 16),

                // 5. Spesifikasi Grid
                Text(
                  'Spesifikasi Material',
                  style: AppTypography.headlineSm(color: AppColors.onSurface),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildSpecCard(
                        icon: Icons.scale,
                        label: 'Berat Material',
                        value: '${item.weightKg.toStringAsFixed(1)} kg',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildSpecCard(
                        icon: Icons.clean_hands,
                        label: 'Kondisi',
                        value: item.conditionLabel,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildSpecCard(
                        icon: Icons.location_on,
                        label: 'Lokasi Umum',
                        value: item.generalLocation.isNotEmpty
                            ? item.generalLocation
                            : '-',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildSpecCard(
                        icon: Icons.person,
                        label: 'Pemilik',
                        value: item.ownerName ?? 'Pengguna #${item.ownerId}',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                const Divider(),
                const SizedBox(height: 16),

                // 6. Deskripsi
                Text(
                  'Deskripsi Material',
                  style: AppTypography.headlineSm(color: AppColors.onSurface),
                ),
                const SizedBox(height: 8),
                Text(
                  item.description.isNotEmpty
                      ? item.description
                      : 'Tidak ada deskripsi tambahan dari pemilik.',
                  style: AppTypography.bodyMd(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 24),

                // 7. Tombol Hubungi Penjual via WhatsApp (hanya jika bukan pemilik & nomor valid)
                Builder(
                  builder: (context) {
                    final currentUserId = widget.authViewModel?.currentUser?.id;
                    final isOwnListing =
                        currentUserId != null && currentUserId == item.ownerId;
                    final whatsappUri = isOwnListing
                        ? null
                        : PhoneUtils.buildSellerWhatsAppUri(
                            sellerPhone: item.ownerPhone,
                            materialName: item.name,
                          );
                    if (whatsappUri == null) {
                      return const SizedBox.shrink();
                    }
                    return Column(
                      children: [
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: _isLaunchingWhatsApp
                                ? null
                                : () => _openSellerWhatsApp(whatsappUri),
                            icon: _isLaunchingWhatsApp
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Color(0xFF146C3A),
                                    ),
                                  )
                                : const Icon(
                                    Icons.chat_outlined,
                                    size: 20,
                                    color: Color(0xFF146C3A),
                                  ),
                            label: Text(
                              'Hubungi Penjual via WhatsApp',
                              textAlign: TextAlign.center,
                              softWrap: true,
                              style: AppTypography.labelMd(
                                color: const Color(0xFF146C3A),
                              ).copyWith(fontWeight: FontWeight.w700),
                            ),
                            style: OutlinedButton.styleFrom(
                              backgroundColor: const Color(0xFFE7F6EC),
                              foregroundColor: const Color(0xFF146C3A),
                              minimumSize: const Size(double.infinity, 48),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              side: const BorderSide(
                                color: Color(0xFF25D366),
                                width: 1.2,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                    );
                  },
                ),

                // 8. Tombol Smart Matching untuk mencari kebutuhan yang cocok
                if (widget.matchingViewModel != null) ...[
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => MatchingResultsScreen(
                              matchingViewModel: widget.matchingViewModel!,
                              marketplaceViewModel: widget.viewModel,
                              authViewModel: widget.authViewModel,
                              listingId: item.id,
                              title: 'Kebutuhan Cocok untuk ${item.categoryLabel}',
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.bolt,
                          color: AppColors.primaryContainer),
                      label: Text(
                        'Cari Kebutuhan Cocok (Smart Matching)',
                        textAlign: TextAlign.center,
                        softWrap: true,
                        style: AppTypography.labelMd(
                          color: AppColors.primaryContainer,
                        ).copyWith(fontWeight: FontWeight.w700),
                      ),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 48),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        side:
                            const BorderSide(color: AppColors.primaryContainer),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageBanner(MaterialListing item) {
    return Container(
      width: double.infinity,
      height: 240,
      color: AppColors.surfaceContainer,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (item.imageUrl != null && item.imageUrl!.startsWith('http'))
            Image.network(
              item.imageUrl!,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) =>
                  _buildFallbackAsset(item),
            )
          else
            _buildFallbackAsset(item),
        ],
      ),
    );
  }

  Widget _buildFallbackAsset(MaterialListing item) {
    if (item.localAsset != null) {
      return Image.asset(
        item.localAsset!,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) =>
            _buildDefaultPlaceholder(),
      );
    }
    return _buildDefaultPlaceholder();
  }

  Widget _buildDefaultPlaceholder() {
    return Container(
      color: AppColors.surfaceContainer,
      child: const Center(
        child: Icon(
          Icons.recycling,
          size: 64,
          color: AppColors.secondary,
        ),
      ),
    );
  }

  Widget _buildSpecCard({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.surfaceContainer),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: AppColors.primaryContainer),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  style: AppTypography.labelSm(color: AppColors.outline),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: AppTypography.labelLg(color: AppColors.onSurface).copyWith(
              fontWeight: FontWeight.w700,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
