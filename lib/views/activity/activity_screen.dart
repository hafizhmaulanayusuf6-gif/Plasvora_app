import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/plasvora_header.dart';
import '../../viewmodels/activity_viewmodel.dart';

class ActivityScreen extends StatelessWidget {
  final ActivityViewModel? viewModel;

  const ActivityScreen({super.key, this.viewModel});

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
            onRefresh: () => viewModel!.loadActivities(),
            color: AppColors.primary,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
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
                  const SizedBox(height: 12),
                  _buildContent(context),
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

  Widget _buildContent(BuildContext context) {
    if (viewModel!.isLoading) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 40),
        alignment: Alignment.center,
        child: Column(
          children: [
            const CircularProgressIndicator(color: AppColors.primary),
            const SizedBox(height: 12),
            Text(
              'Memuat riwayat aktivitas...',
              style: AppTypography.bodySm(color: AppColors.onSurfaceVariant),
            ),
          ],
        ),
      );
    }

    if (viewModel!.errorMessage != null) {
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
              'Gagal Memuat Aktivitas',
              style: AppTypography.labelLg(color: const Color(0xFFC62828)),
            ),
            const SizedBox(height: 4),
            Text(
              viewModel!.errorMessage!,
              textAlign: TextAlign.center,
              style: AppTypography.bodySm(color: AppColors.onSurfaceVariant),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () => viewModel!.loadActivities(),
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

    if (viewModel!.isEmpty) {
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
              Icons.inbox_outlined,
              size: 48,
              color: AppColors.outline.withValues(alpha: 0.7),
            ),
            const SizedBox(height: 12),
            Text(
              'Belum Ada Aktivitas',
              style: AppTypography.labelLg(color: AppColors.onSurface),
            ),
            const SizedBox(height: 6),
            Text(
              'Aktivitas penawaran material, kebutuhan, dan serah terima Anda akan tercatat di sini secara otomatis.',
              textAlign: TextAlign.center,
              style: AppTypography.bodySm(color: AppColors.onSurfaceVariant),
            ),
            const SizedBox(height: 14),
            OutlinedButton.icon(
              onPressed: () => viewModel!.loadActivities(),
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('Perbarui Data'),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: viewModel!.activities.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final item = viewModel!.activities[index];
        return _buildActivityItem(
          title: item.action,
          partner: item.description,
          status: item.statusLabel,
          statusColor: item.statusColor,
          statusBg: item.statusBg,
          date: item.formattedDate,
          icon: item.icon,
        );
      },
    );
  }

  Widget _buildActivityItem({
    required String title,
    required String partner,
    required String status,
    required Color statusColor,
    required Color statusBg,
    required String date,
    required IconData icon,
  }) {
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
              color: statusBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: statusColor, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.labelLg(color: AppColors.onSurface),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  partner,
                  style: AppTypography.bodySm(color: AppColors.onSurfaceVariant)
                      .copyWith(fontSize: 11),
                ),
                const SizedBox(height: 2),
                Text(
                  date,
                  style: AppTypography.labelSm(color: AppColors.outline)
                      .copyWith(fontSize: 10),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: statusBg,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              status,
              style: AppTypography.labelSm(color: statusColor)
                  .copyWith(fontWeight: FontWeight.w700, fontSize: 10),
            ),
          ),
        ],
      ),
    );
  }
}
