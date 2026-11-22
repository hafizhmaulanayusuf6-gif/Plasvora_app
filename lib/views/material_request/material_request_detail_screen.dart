import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../models/material_request_item.dart';
import '../../repositories/shipping_repository.dart';
import '../../viewmodels/address_viewmodel.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/marketplace_viewmodel.dart';
import '../../viewmodels/matching_viewmodel.dart';
import '../../viewmodels/material_request_viewmodel.dart';
import '../matching/matching_results_screen.dart';

class MaterialRequestDetailScreen extends StatefulWidget {
  final int requestId;
  final MaterialRequestItem? initialItem;
  final MaterialRequestViewModel viewModel;
  final MatchingViewModel matchingViewModel;
  final MarketplaceViewModel marketplaceViewModel;
  final AuthViewModel? authViewModel;
  final AddressViewModel? addressViewModel;
  final ShippingRepository? shippingRepository;

  const MaterialRequestDetailScreen({
    super.key,
    required this.requestId,
    this.initialItem,
    required this.viewModel,
    required this.matchingViewModel,
    required this.marketplaceViewModel,
    this.authViewModel,
    this.addressViewModel,
    this.shippingRepository,
  });

  @override
  State<MaterialRequestDetailScreen> createState() =>
      _MaterialRequestDetailScreenState();
}

class _MaterialRequestDetailScreenState
    extends State<MaterialRequestDetailScreen> {
  late MaterialRequestItem? _item;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _item = widget.initialItem;
    _fetchDetail();
  }

  Future<void> _fetchDetail() async {
    setState(() {
      _isLoading = _item == null;
      _errorMessage = null;
    });

    try {
      final detail = await widget.viewModel.getDetail(widget.requestId);
      if (mounted) {
        setState(() {
          _item = detail;
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

  Future<void> _confirmCancel() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Batalkan Kebutuhan Material?'),
        content: const Text(
          'Permintaan kebutuhan ini akan ditandai dibatalkan dan tidak lagi dicarikan kecocokan oleh sistem.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
            child: const Text('Ya, Batalkan'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      final success = await widget.viewModel.cancelRequest(widget.requestId);
      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Permintaan kebutuhan material telah dibatalkan.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.of(context).pop(true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.viewModel.errorMessage ?? 'Gagal membatalkan permintaan.',
            ),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: Text(
          'Detail Kebutuhan Plastik',
          style: AppTypography.headlineSm(color: AppColors.onSurface),
        ),
        backgroundColor: AppColors.surfaceContainerLowest,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.onSurface),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          if (_item != null &&
              widget.viewModel.isOwner(_item!) &&
              _item!.status == 'active')
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
              tooltip: 'Batalkan Permintaan',
              onPressed: _confirmCancel,
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

    if (_errorMessage != null && _item == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
              const SizedBox(height: 12),
              Text(
                'Gagal Memuat Kebutuhan',
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

    final item = _item!;
    return RefreshIndicator(
      onRefresh: _fetchDetail,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status and Category row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primaryContainer.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppColors.primaryContainer.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Text(
                    'Polimer: ${item.categoryLabel}',
                    style: AppTypography.labelMd(
                      color: AppColors.primaryContainer,
                    ).copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: item.status == 'active'
                        ? const Color(0xFFDCFCE7)
                        : const Color(0xFFFEE2E2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    item.statusLabel,
                    style: AppTypography.labelSm(
                      color: item.status == 'active'
                          ? const Color(0xFF15803D)
                          : const Color(0xFFB91C1C),
                    ).copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Card specification
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.outline.withValues(alpha: 0.2),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Spesifikasi Kebutuhan',
                    style: AppTypography.headlineSm(color: AppColors.onSurface)
                        .copyWith(fontSize: 16),
                  ),
                  const SizedBox(height: 14),
                  _buildDetailRow(
                    Icons.scale_outlined,
                    'Berat Dibutuhkan',
                    item.formattedWeight,
                  ),
                  const Divider(height: 20),
                  _buildDetailRow(
                    Icons.clean_hands_outlined,
                    'Kondisi Minimum',
                    item.conditionLabel,
                  ),
                  const Divider(height: 20),
                  _buildDetailRow(
                    Icons.location_on_outlined,
                    'Lokasi Kebutuhan',
                    item.generalLocation,
                  ),
                  const Divider(height: 20),
                  _buildDetailRow(
                    Icons.person_outline,
                    'Pemohon',
                    item.requesterName ?? 'Pengguna Plasvora',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Intended use card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.outline.withValues(alpha: 0.2),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tujuan Penggunaan',
                    style: AppTypography.headlineSm(color: AppColors.onSurface)
                        .copyWith(fontSize: 16),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    item.intendedUse,
                    style: AppTypography.bodyMd(color: AppColors.onSurface)
                        .copyWith(height: 1.45),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Smart Matching Button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => MatchingResultsScreen(
                        matchingViewModel: widget.matchingViewModel,
                        marketplaceViewModel: widget.marketplaceViewModel,
                        authViewModel: widget.authViewModel,
                        addressViewModel: widget.addressViewModel,
                        shippingRepository: widget.shippingRepository,
                        requestId: item.id,
                        title: 'Material Cocok untuk ${item.categoryLabel}',
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.bolt, color: Colors.white),
                label: Text(
                  'Cari Material yang Cocok (Smart Matching)',
                  style: AppTypography.labelLg(color: Colors.white)
                      .copyWith(fontWeight: FontWeight.w700),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryContainer,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 3,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.secondary),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: AppTypography.bodySm(color: AppColors.onSurfaceVariant),
          ),
        ),
        Text(
          value,
          style: AppTypography.labelMd(color: AppColors.onSurface)
              .copyWith(fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}

