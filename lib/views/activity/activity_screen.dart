import 'dart:io';

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/plasvora_header.dart';
import '../../models/activity_item.dart';
import '../../models/plastic_analysis.dart';
import '../../viewmodels/activity_viewmodel.dart';
import '../../viewmodels/marketplace_viewmodel.dart';
import '../../viewmodels/navigation_viewmodel.dart';
import '../analysis/analysis_result_screen.dart';

class ActivityScreen extends StatelessWidget {
  final ActivityViewModel? viewModel;
  final MarketplaceViewModel? marketplaceViewModel;
  final NavigationViewModel? navigationViewModel;

  const ActivityScreen({
    super.key,
    this.viewModel,
    this.marketplaceViewModel,
    this.navigationViewModel,
  });

  @override
  Widget build(BuildContext context) {
    if (viewModel == null) {
      return Scaffold(
        appBar: const PlasvoraHeader(customTitle: 'Jejak Aktivitas'),
        body: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInfoBanner(),
              const SizedBox(height: 20),
              Text(
                'Riwayat Transaksi & Serah Terima',
                style: AppTypography.headlineSm(color: AppColors.onSurface),
              ),
              const SizedBox(height: 24),
              Center(
                child: Text(
                  'Modul aktivitas belum terhubung.',
                  style: AppTypography.bodySm(color: AppColors.onSurfaceVariant),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListenableBuilder(
      listenable: viewModel!,
      builder: (context, _) {
        return Scaffold(
          appBar: const PlasvoraHeader(customTitle: 'Jejak Aktivitas'),
          body: RefreshIndicator(
            onRefresh: () => viewModel!.refreshAll(),
            color: AppColors.primary,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoBanner(),
                  const SizedBox(height: 16),
                  _buildTabSwitcher(context),
                  const SizedBox(height: 16),
                  if (viewModel!.selectedTabIndex == 0)
                    _buildActivitiesContent(context)
                  else
                    _buildAnalysisHistoryContent(context),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0820312A),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.verified,
                color: AppColors.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Verified Material Journey',
                style: AppTypography.labelLg(color: AppColors.primary),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Pencatatan siklus material dari penawaran hingga konfirmasi penyerahan dan pemanfaatan nyata.',
            style: AppTypography.bodySm(
              color: AppColors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabSwitcher(BuildContext context) {
    final vm = viewModel!;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          _buildTabButton(
            context: context,
            label: 'Semua Jejak',
            icon: Icons.timeline_outlined,
            index: 0,
            selected: vm.selectedTabIndex == 0,
            onTap: () => vm.setTabIndex(0),
          ),
          _buildTabButton(
            context: context,
            label: 'Riwayat Analisis',
            icon: Icons.document_scanner_outlined,
            index: 1,
            selected: vm.selectedTabIndex == 1,
            onTap: () => vm.setTabIndex(1),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton({
    required BuildContext context,
    required String label,
    required IconData icon,
    required int index,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? AppColors.surfaceContainerLowest : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: selected
                ? [
                    const BoxShadow(
                      color: Color(0x1220312A),
                      blurRadius: 4,
                      offset: Offset(0, 1),
                    )
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: selected ? AppColors.primary : AppColors.onSurfaceVariant,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: selected
                    ? AppTypography.labelMd(color: AppColors.primary)
                        .copyWith(fontWeight: FontWeight.w700)
                    : AppTypography.labelMd(color: AppColors.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Tab 0: Semua Jejak Aktivitas ─────────────────────────────────────

  Widget _buildActivitiesContent(BuildContext context) {
    final vm = viewModel!;

    if (vm.isLoading) {
      return _buildLoadingState('Memuat riwayat aktivitas...');
    }

    if (vm.errorMessage != null) {
      return _buildErrorState(
        vm.errorMessage!,
        onRetry: () => vm.loadActivities(),
      );
    }

    if (vm.isEmpty) {
      return _buildEmptyState(
        icon: Icons.inbox_outlined,
        title: 'Belum Ada Aktivitas',
        subtitle: 'Aktivitas penawaran material, kebutuhan, dan serah terima Anda akan tercatat di sini secara otomatis.',
        onRefresh: () => vm.loadActivities(),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: vm.activities.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final item = vm.activities[index];
        return _buildActivityItem(item: item);
      },
    );
  }

  Widget _buildActivityItem({required ActivityItem item}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0620312A),
            blurRadius: 6,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: item.statusBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(item.icon, color: item.statusColor, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.action,
                  style: AppTypography.labelLg(color: AppColors.onSurface),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  item.description,
                  style: AppTypography.bodySm(color: AppColors.onSurfaceVariant)
                      .copyWith(fontSize: 11),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  item.formattedDate,
                  style: AppTypography.labelSm(color: AppColors.outline)
                      .copyWith(fontSize: 10),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: item.statusBg,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              item.statusLabel,
              style: AppTypography.labelSm(color: item.statusColor)
                  .copyWith(fontWeight: FontWeight.w700, fontSize: 10),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Tab 1: Riwayat Analisis Plastik ─────────────────────────────────

  Widget _buildAnalysisHistoryContent(BuildContext context) {
    final vm = viewModel!;

    if (vm.isLoadingAnalyses) {
      return _buildLoadingState('Memuat riwayat analisis...');
    }

    if (vm.analysesError != null) {
      return _buildErrorState(
        vm.analysesError!,
        onRetry: () => vm.loadAnalysisHistories(),
      );
    }

    if (vm.isAnalysesEmpty) {
      return _buildEmptyState(
        icon: Icons.document_scanner_outlined,
        title: 'Belum Ada Riwayat Analisis',
        subtitle: 'Hasil analisis plastik AI akan tersimpan di sini. Gunakan fitur Analisis untuk mulai memindai plastik.',
        onRefresh: () => vm.loadAnalysisHistories(),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: vm.analyses.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final analysis = vm.analyses[index];
        return _buildAnalysisHistoryCard(context, analysis);
      },
    );
  }

  Widget _buildAnalysisHistoryCard(
      BuildContext context, PlasticAnalysisResult analysis) {
    final canNavigate = navigationViewModel != null;
    return GestureDetector(
      onTap: canNavigate
          ? () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => AnalysisResultScreen(
                    result: analysis,
                    navigationViewModel: navigationViewModel!,
                    marketplaceViewModel: marketplaceViewModel,
                  ),
                ),
              );
            }
          : null,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0620312A),
              blurRadius: 6,
              offset: Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          children: [
            // Thumbnail foto
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(
                width: 56,
                height: 56,
                child: analysis.imagePath != null
                    ? _buildThumbnailImage(analysis.imagePath!, analysis.localAsset)
                    : Image.asset(analysis.localAsset, fit: BoxFit.cover),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    analysis.materialTitle,
                    style: AppTypography.labelLg(color: AppColors.onSurface),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  if (analysis.objectName != null)
                    Text(
                      analysis.objectName!,
                      style: AppTypography.bodySm(
                              color: AppColors.onSurfaceVariant)
                          .copyWith(fontSize: 11),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F5E9),
                          borderRadius: BorderRadius.circular(99),
                        ),
                        child: Text(
                          analysis.polymerCategory,
                          style:
                              AppTypography.labelSm(color: AppColors.primary)
                                  .copyWith(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 10),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        analysis.polymerCode,
                        style: AppTypography.labelSm(
                                color: AppColors.onSurfaceVariant)
                            .copyWith(fontSize: 10),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Icon(
                  Icons.chevron_right,
                  color: AppColors.outline,
                  size: 20,
                ),
                const SizedBox(height: 4),
                if (analysis.isSimulated)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF3E0),
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Text(
                      'Rule-based',
                      style: AppTypography.labelSm(color: const Color(0xFFE65100))
                          .copyWith(fontSize: 9),
                    ),
                  )
                else
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E9),
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Text(
                      'AI Vision',
                      style: AppTypography.labelSm(color: AppColors.primary)
                          .copyWith(fontSize: 9),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThumbnailImage(String imagePath, String fallbackAsset) {
    if (imagePath.startsWith('http://') || imagePath.startsWith('https://')) {
      return Image.network(
        imagePath,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) =>
            Image.asset(fallbackAsset, fit: BoxFit.cover),
      );
    }
    final file = File(imagePath);
    if (file.existsSync()) {
      return Image.file(file, fit: BoxFit.cover);
    }
    return Image.asset(fallbackAsset, fit: BoxFit.cover);
  }

  // ─── State Helpers ─────────────────────────────────────────────────────

  Widget _buildLoadingState(String message) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40),
      alignment: Alignment.center,
      child: Column(
        children: [
          const CircularProgressIndicator(color: AppColors.primary),
          const SizedBox(height: 12),
          Text(
            message,
            style: AppTypography.bodySm(color: AppColors.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String message, {required VoidCallback onRetry}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFEBEE),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFFCDD2)),
      ),
      child: Column(
        children: [
          const Icon(Icons.error_outline, color: Color(0xFFC62828), size: 36),
          const SizedBox(height: 8),
          Text(
            'Gagal Memuat Data',
            style: AppTypography.labelLg(color: const Color(0xFFC62828)),
          ),
          const SizedBox(height: 4),
          Text(
            message,
            textAlign: TextAlign.center,
            style: AppTypography.bodySm(color: AppColors.onSurfaceVariant),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('Coba Lagi'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onRefresh,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outline.withValues(alpha: 0.15)),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            size: 48,
            color: AppColors.outline.withValues(alpha: 0.7),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: AppTypography.labelLg(color: AppColors.onSurface),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: AppTypography.bodySm(color: AppColors.onSurfaceVariant),
          ),
          const SizedBox(height: 14),
          OutlinedButton.icon(
            onPressed: onRefresh,
            icon: const Icon(Icons.refresh, size: 16),
            label: const Text('Perbarui Data'),
          ),
        ],
      ),
    );
  }
}
