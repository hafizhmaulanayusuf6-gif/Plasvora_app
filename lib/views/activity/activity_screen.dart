import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/plasvora_header.dart';

class ActivityScreen extends StatelessWidget {
  const ActivityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const PlasvoraHeader(customTitle: 'Jejak Aktivitas'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
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
            ),
            const SizedBox(height: 20),
            Text(
              'Riwayat Transaksi & Serah Terima',
              style: AppTypography.headlineSm(color: AppColors.onSurface),
            ),
            const SizedBox(height: 12),
            _buildActivityItem(
              title: 'Penyerahan 5 kg Tutup Botol HDPE',
              partner: 'Mitra: Komunitas Daur Ulang Cianjur',
              status: 'Dikonfirmasi Dimanfaatkan',
              statusColor: AppColors.primaryContainer,
              statusBg: AppColors.secondaryContainer,
              date: 'Hari ini · 11:20 WIB',
              icon: Icons.check_circle_outline,
            ),
            const SizedBox(height: 10),
            _buildActivityItem(
              title: 'Pengiriman 8 kg Serpihan PET',
              partner: 'Mitra: Workshop Kreasi Plastik',
              status: 'Dalam Pengiriman',
              statusColor: AppColors.secondary,
              statusBg: AppColors.surfaceContainer,
              date: 'Kemarin · 14:45 WIB',
              icon: Icons.local_shipping_outlined,
            ),
            const SizedBox(height: 10),
            _buildActivityItem(
              title: 'Penawaran 12 kg Jerigen HDPE',
              partner: 'Status: Terdaftar di Marketplace',
              status: 'Tersedia',
              statusColor: AppColors.primary,
              statusBg: AppColors.tertiaryFixed,
              date: '25 Okt 2026',
              icon: Icons.storefront_outlined,
            ),
          ],
        ),
      ),
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
