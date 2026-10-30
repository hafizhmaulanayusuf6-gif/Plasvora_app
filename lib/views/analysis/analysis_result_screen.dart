import 'dart:io';

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/plasvora_header.dart';
import '../../models/plastic_analysis.dart';
import '../../viewmodels/navigation_viewmodel.dart';

class AnalysisResultScreen extends StatefulWidget {
  final PlasticAnalysisResult result;
  final NavigationViewModel navigationViewModel;

  const AnalysisResultScreen({
    super.key,
    required this.result,
    required this.navigationViewModel,
  });

  @override
  State<AnalysisResultScreen> createState() => _AnalysisResultScreenState();
}

class _AnalysisResultScreenState extends State<AnalysisResultScreen> {
  bool _isSaved = false;
  bool _isSearchingPartners = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PlasvoraHeader(
        customTitle: 'Hasil Analisis',
        showBack: true,
        onBack: () => Navigator.of(context).pop(),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 32),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildCapturedPreview(),
              const SizedBox(height: 16),
              _buildDetectedObjectCard(),
              const SizedBox(height: 16),
              _buildComponentsSection(),
              const SizedBox(height: 16),
              _buildPolymerMetrics(),
              const SizedBox(height: 20),
              _buildUpcyclingRecommendations(),
              const SizedBox(height: 24),
              _buildActionButtons(context),
            ],
          ),
        ),
      ),
    );
  }

  /// 1. Captured Photo Preview
  Widget _buildCapturedPreview() {
    final result = widget.result;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
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
        child: AspectRatio(
          aspectRatio: 16 / 10,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (result.imagePath != null &&
                  File(result.imagePath!).existsSync())
                Image.file(File(result.imagePath!), fit: BoxFit.cover)
              else
                Image.asset(result.localAsset, fit: BoxFit.cover),
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLowest.withValues(
                      alpha: 0.92,
                    ),
                    borderRadius: BorderRadius.circular(999),
                    boxShadow: const [
                      BoxShadow(color: Color(0x0A000000), blurRadius: 4),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.photo_camera,
                        size: 15,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Foto Analisis',
                        style: AppTypography.labelSm(color: AppColors.onSurface)
                            .copyWith(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                bottom: 12,
                left: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.inverseSurface.withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.auto_awesome,
                        size: 14,
                        color: AppColors.primaryFixed,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        'AI Vision v2.4',
                        style: AppTypography.labelSm(
                          color: AppColors.surfaceBright,
                        ).copyWith(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 2. Detected Object Overview Card
  Widget _buildDetectedObjectCard() {
    final result = widget.result;
    final objectName = result.objectName ?? result.materialTitle;
    final objectDesc = result.objectDescription ?? '';
    final summary = result.identificationSummary ?? result.qualitativeNote;
    final hasDiscrepancy = summary.toLowerCase().contains('catatan') &&
        (summary.toLowerCase().contains('tidak tampak') ||
            summary.toLowerCase().contains('verifikasi') ||
            summary.toLowerCase().contains('beda') ||
            summary.toLowerCase().contains('ketidak'));

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A20312A),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // AI Vision badge vs Simulasi
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: result.isSimulated
                  ? AppColors.surfaceContainerLow
                  : AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: result.isSimulated
                    ? AppColors.outline.withValues(alpha: 0.2)
                    : AppColors.primary.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  result.isSimulated ? Icons.tune : Icons.auto_awesome,
                  size: 15,
                  color: result.isSimulated
                      ? AppColors.onSurfaceVariant
                      : AppColors.primary,
                ),
                const SizedBox(width: 6),
                Text(
                  result.isSimulated
                      ? 'Mode Simulasi / Aturan Cepat'
                      : 'Dianalisis oleh Gemini AI Vision (Multi-Komponen)',
                  style: AppTypography.labelSm(
                    color: result.isSimulated
                        ? AppColors.onSurfaceVariant
                        : AppColors.primary,
                  ).copyWith(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: const BoxDecoration(
                  color: AppColors.secondaryContainer,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.recycling,
                  size: 26,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'OBJEK TERDETEKSI',
                      style: AppTypography.labelSm(
                        color: AppColors.onSurfaceVariant,
                      ).copyWith(
                        letterSpacing: 0.6,
                        fontWeight: FontWeight.w700,
                        fontSize: 10,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      objectName,
                      style: AppTypography.headlineMd(
                        color: AppColors.onSurface,
                      ),
                    ),
                    if (objectDesc.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        objectDesc,
                        style: AppTypography.bodySm(
                          color: AppColors.onSurfaceVariant,
                        ).copyWith(fontSize: 12),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          if (hasDiscrepancy) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFBEB),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFFF59E0B).withValues(alpha: 0.4),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.warning_amber_rounded,
                    size: 18,
                    color: Color(0xFFD97706),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Perhatian: Catatan & Foto Perlu Verifikasi',
                          style: AppTypography.labelSm(
                            color: const Color(0xFF92400E),
                          ).copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          summary,
                          style: AppTypography.bodySm(
                            color: const Color(0xFF78350F),
                          ).copyWith(fontSize: 11.5, height: 1.35),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ] else if (summary.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.info_outline,
                    size: 18,
                    color: AppColors.tertiaryContainer,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      summary,
                      style: AppTypography.bodySm(
                        color: AppColors.onSurfaceVariant,
                      ).copyWith(fontSize: 11.5, height: 1.35),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// 3. Multi-Component Material Section
  Widget _buildComponentsSection() {
    final components = widget.result.components;
    if (components.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.layers_outlined,
                  size: 19,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 6),
                Text(
                  'Komponen Material',
                  style: AppTypography.headlineSm(color: AppColors.onSurface),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.secondaryContainer,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                '${components.length} Bagian',
                style: AppTypography.labelSm(
                  color: AppColors.onSecondaryContainer,
                ).copyWith(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Setiap bagian fisik objek dipisahkan untuk menjaga kemurnian dan keamanan daur ulang:',
          style: AppTypography.bodySm(color: AppColors.onSurfaceVariant)
              .copyWith(fontSize: 11.5),
        ),
        const SizedBox(height: 10),
        ...components.map((comp) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _buildComponentCard(comp),
            )),
      ],
    );
  }

  Widget _buildComponentCard(MaterialComponent comp) {
    Color confidenceBg;
    Color confidenceText;
    String confidenceLabel;

    switch (comp.confidence.toLowerCase()) {
      case 'high':
        confidenceBg = const Color(0xFFD1FAE5);
        confidenceText = const Color(0xFF065F46);
        confidenceLabel = 'Tingkat Yakin';
        break;
      case 'low':
      case 'uncertain':
        confidenceBg = const Color(0xFFFEF3C7);
        confidenceText = const Color(0xFF92400E);
        confidenceLabel = 'Perlu Verifikasi';
        break;
      default:
        confidenceBg = AppColors.surfaceContainerHigh;
        confidenceText = AppColors.primary;
        confidenceLabel = 'Dugaan Visual';
        break;
    }

    final isCap = comp.partName.toLowerCase().contains('tutup');
    final isBody = comp.partName.toLowerCase().contains('badan');
    final isLabel = comp.partName.toLowerCase().contains('label');

    IconData partIcon = Icons.view_in_ar;
    if (isCap) partIcon = Icons.radio_button_checked;
    if (isBody) partIcon = Icons.local_drink;
    if (isLabel) partIcon = Icons.bookmark_border;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: comp.isUncertain
              ? const Color(0xFFF59E0B).withValues(alpha: 0.3)
              : AppColors.outline.withValues(alpha: 0.15),
          width: 1,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0620312A),
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
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.secondaryContainer.withValues(alpha: 0.6),
                  shape: BoxShape.circle,
                ),
                child: Icon(partIcon, size: 20, color: AppColors.primary),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      comp.partName,
                      style: AppTypography.labelLg(color: AppColors.onSurface)
                          .copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 1.5,
                          ),
                          decoration: BoxDecoration(
                            color: confidenceBg,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            confidenceLabel,
                            style: AppTypography.labelSm(color: confidenceText)
                                .copyWith(
                              fontWeight: FontWeight.w700,
                              fontSize: 9.5,
                            ),
                          ),
                        ),
                        if (comp.resinCode != null &&
                            comp.resinCode!.isNotEmpty) ...[
                          const SizedBox(width: 6),
                          Text(
                            'Resin ${comp.resinCode}',
                            style: AppTypography.bodySm(
                              color: AppColors.onSurfaceVariant,
                            ).copyWith(fontSize: 11, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              TextButton.icon(
                onPressed: () => _showComponentVerificationDialog(comp),
                icon: const Icon(Icons.help_outline, size: 14, color: AppColors.primary),
                label: Text(
                  'Cara Cek',
                  style: AppTypography.labelSm(color: AppColors.primary),
                ),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Baris Polimer & Kandidat
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Material Dugaan: ',
                      style: AppTypography.labelSm(color: AppColors.onSurfaceVariant)
                          .copyWith(fontSize: 11),
                    ),
                    Text(
                      comp.isUncertain
                          ? 'Perlu Dipastikan (Belum Pasti)'
                          : '${comp.materialType} ${comp.resinCode != null ? "(${comp.resinCode})" : ""}',
                      style: AppTypography.labelSm(
                        color: comp.isUncertain
                            ? const Color(0xFFD97706)
                            : AppColors.primary,
                      ).copyWith(fontWeight: FontWeight.w700, fontSize: 11.5),
                    ),
                  ],
                ),
                if (comp.candidateMaterials.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: comp.candidateMaterials
                        .map(
                          (candidate) => Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: AppColors.outline.withValues(alpha: 0.2),
                              ),
                            ),
                            child: Text(
                              'Kandidat: $candidate',
                              style: AppTypography.labelSm(
                                color: AppColors.onSurface,
                              ).copyWith(fontSize: 10.5, fontWeight: FontWeight.w600),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ],
                if (comp.meltingPoint != null && comp.meltingPoint!.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(
                        Icons.thermostat_outlined,
                        size: 14,
                        color: AppColors.onSurfaceVariant,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Titik leleh komponen: ${comp.meltingPoint}',
                        style: AppTypography.bodySm(
                          color: AppColors.onSurfaceVariant,
                        ).copyWith(fontSize: 11),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Catatan verifikasi fisik
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.search,
                size: 15,
                color: AppColors.primary,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  comp.verificationNote,
                  style: AppTypography.bodySm(color: AppColors.onSurfaceVariant)
                      .copyWith(fontSize: 11, fontStyle: FontStyle.italic),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showComponentVerificationDialog(MaterialComponent comp) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Verifikasi Fisik: ${comp.partName}',
                    style: AppTypography.headlineSm(color: AppColors.onSurface),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.secondaryContainer.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.tips_and_updates, color: AppColors.primary),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        comp.verificationNote,
                        style: AppTypography.bodySm(color: AppColors.onSurface)
                            .copyWith(height: 1.4),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Panduan Identifikasi Manual:',
                style: AppTypography.labelLg(color: AppColors.onSurface),
              ),
              const SizedBox(height: 6),
              Text(
                '• Badan botol: Cari logo segitiga angka 1 (PET) yang tercetak timbul di dasar botol.\n'
                '• Tutup botol: Balik tutup botol dan cari angka 2 (HDPE) atau 5 (PP) di lingkaran dalam.\n'
                '• Pisahkan kedua komponen sebelum disetorkan ke bank sampah.',
                style: AppTypography.bodySm(color: AppColors.onSurfaceVariant)
                    .copyWith(height: 1.45),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Saya Mengerti'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// 4. Quick Polymer Specification Metrics
  Widget _buildPolymerMetrics() {
    final result = widget.result;

    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(18),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x0620312A),
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
                    const Icon(
                      Icons.thermostat_outlined,
                      size: 18,
                      color: AppColors.onSurfaceVariant,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Karakter Titik Leleh',
                      style: AppTypography.labelSm(
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  result.isMultiComponent
                      ? 'Multi-Komponen'
                      : result.meltingPoint,
                  style: AppTypography.headlineSm(color: AppColors.onSurface)
                      .copyWith(fontSize: 14),
                ),
                const SizedBox(height: 2),
                Text(
                  result.isMultiComponent
                      ? 'Cek rincian pada setiap komponen'
                      : 'Karakteristik termal polimer',
                  style: AppTypography.bodySm(color: AppColors.onSurfaceVariant)
                      .copyWith(fontSize: 10.5),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(18),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x0620312A),
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
                    const Icon(
                      Icons.eco_outlined,
                      size: 18,
                      color: AppColors.onSurfaceVariant,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Emisi Terhindar',
                      style: AppTypography.labelSm(
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  result.avoidedEmission,
                  style: AppTypography.headlineSm(color: AppColors.primary)
                      .copyWith(fontSize: 14),
                ),
                const SizedBox(height: 2),
                Text(
                  'Estimasi potensi nilai sirkular',
                  style: AppTypography.bodySm(color: AppColors.onSurfaceVariant)
                      .copyWith(fontSize: 10.5),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// 5. Upcycling Recommendations Section
  Widget _buildUpcyclingRecommendations() {
    final ideas = widget.result.ideas;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.auto_awesome_motion,
                  size: 20,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 6),
                Text(
                  'Rekomendasi Upcycling',
                  style: AppTypography.headlineSm(color: AppColors.onSurface),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.secondaryContainer,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                '${ideas.length} Pilihan',
                style: AppTypography.labelSm(
                  color: AppColors.onSecondaryContainer,
                ).copyWith(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Ide realistis berbasis komponen material, jumlah bahan, dan skala pengolahan:',
          style: AppTypography.bodySm(color: AppColors.onSurfaceVariant)
              .copyWith(fontSize: 11.5),
        ),
        const SizedBox(height: 12),
        ...ideas.map(
          (idea) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _buildIdeaCard(idea),
          ),
        ),
      ],
    );
  }

  IconData _getCategoryIcon(String title, String difficulty) {
    final t = title.toLowerCase();
    if (t.contains('furnitur') || t.contains('meja') || t.contains('kursi')) {
      return Icons.chair_outlined;
    }
    if (t.contains('aksesoris') || t.contains('gantungan') || t.contains('coaster') || t.contains('anting')) {
      return Icons.interests_outlined;
    }
    if (t.contains('pot') || t.contains('tanaman') || t.contains('taman') || t.contains('kebun')) {
      return Icons.eco_outlined;
    }
    if (t.contains('panel') || t.contains('mozaik') || t.contains('ubin') || t.contains('lantai')) {
      return Icons.grid_view_outlined;
    }
    if (t.contains('wadah') || t.contains('kotak') || t.contains('organizer')) {
      return Icons.inventory_2_outlined;
    }
    return Icons.recycling_outlined;
  }

  String _getEstimateTime(String difficulty) {
    final d = difficulty.toLowerCase();
    if (d.contains('mudah') || d.contains('easy')) {
      return '~30-45 mnt';
    }
    if (d.contains('sulit') || d.contains('hard')) {
      return '~3-6 jam';
    }
    return '~1-2 jam';
  }

  Widget _buildIdeaCard(UpcyclingIdea idea) {
    // Resolve nama komponen yang dipakai ide
    String componentTag = '';
    if (idea.componentIds.isNotEmpty) {
      final matchedNames = <String>[];
      for (final cid in idea.componentIds) {
        final comp = widget.result.components.firstWhere(
          (c) => c.id == cid,
          orElse: () => MaterialComponent(
            id: cid,
            partName: cid.contains('cap')
                ? 'Tutup botol'
                : (cid.contains('body') ? 'Badan botol' : 'Material'),
            materialType: '',
            verificationNote: '',
          ),
        );
        matchedNames.add(comp.partName);
      }
      componentTag = matchedNames.join(', ');
    }

    String quantityLabel;
    switch (idea.suitableQuantity) {
      case 'small_batch':
        quantityLabel = 'Kumpulan Kecil';
        break;
      case 'bulk':
        quantityLabel = 'Jumlah Besar';
        break;
      default:
        quantityLabel = '1 Benda Bekas';
        break;
    }

    String scaleLabel;
    switch (idea.scale) {
      case 'community':
        scaleLabel = 'Komunitas';
        break;
      case 'industrial':
        scaleLabel = 'Industri';
        break;
      default:
        scaleLabel = 'Rumah Tangga';
        break;
    }

    final catIcon = _getCategoryIcon(idea.title, idea.difficulty);
    final estTime = _getEstimateTime(idea.difficulty);

    return InkWell(
      onTap: () => _showIdeaDetailSheet(idea, componentTag, quantityLabel, scaleLabel),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.outline.withValues(alpha: 0.15),
            width: 1,
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0620312A),
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Icon kategori Stitch style
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: AppColors.secondaryContainer.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                catIcon,
                size: 22,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 12),
            // Text info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          idea.title,
                          style: AppTypography.labelLg(color: AppColors.onSurface)
                              .copyWith(fontWeight: FontWeight.w700),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.secondaryContainer,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          idea.difficulty,
                          style: AppTypography.labelSm(
                            color: AppColors.primary,
                          ).copyWith(fontWeight: FontWeight.w700, fontSize: 10),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      const Icon(
                        Icons.schedule,
                        size: 13,
                        color: AppColors.secondary,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        estTime,
                        style: AppTypography.bodySm(color: AppColors.onSurfaceVariant)
                            .copyWith(fontSize: 11, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(width: 10),
                      const Icon(
                        Icons.trending_up,
                        size: 13,
                        color: AppColors.secondary,
                      ),
                      const SizedBox(width: 3),
                      Flexible(
                        child: Text(
                          componentTag.isNotEmpty ? componentTag : scaleLabel,
                          style: AppTypography.bodySm(color: AppColors.onSurfaceVariant)
                              .copyWith(fontSize: 11, fontWeight: FontWeight.w500),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Stitch arrow button
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLow,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.arrow_forward,
                size: 16,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showIdeaDetailSheet(
    UpcyclingIdea idea,
    String componentTag,
    String quantityLabel,
    String scaleLabel,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.75,
          maxChildSize: 0.92,
          minChildSize: 0.5,
          expand: false,
          builder: (context, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          idea.title,
                          style: AppTypography.headlineSm(
                            color: AppColors.onSurface,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      if (componentTag.isNotEmpty)
                        Chip(
                          label: Text('Bagian: $componentTag'),
                          backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                          labelStyle: AppTypography.labelSm(color: AppColors.primary),
                          padding: EdgeInsets.zero,
                        ),
                      Chip(
                        label: Text(quantityLabel),
                        backgroundColor: AppColors.surfaceContainerHigh,
                        labelStyle: AppTypography.labelSm(color: AppColors.onSurface),
                        padding: EdgeInsets.zero,
                      ),
                      Chip(
                        label: Text(scaleLabel),
                        backgroundColor: AppColors.surfaceContainerHigh,
                        labelStyle: AppTypography.labelSm(color: AppColors.onSurface),
                        padding: EdgeInsets.zero,
                      ),
                      Chip(
                        label: Text(idea.difficulty),
                        backgroundColor: AppColors.secondaryContainer,
                        labelStyle: AppTypography.labelSm(color: AppColors.primary),
                        padding: EdgeInsets.zero,
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    idea.description,
                    style: AppTypography.bodyMd(color: AppColors.onSurfaceVariant)
                        .copyWith(height: 1.4),
                  ),
                  if (idea.whyItFits != null && idea.whyItFits!.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text(
                      'Mengapa Cocok untuk Material Ini?',
                      style: AppTypography.labelLg(color: AppColors.onSurface),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      idea.whyItFits!,
                      style: AppTypography.bodySm(color: AppColors.onSurfaceVariant)
                          .copyWith(height: 1.4),
                    ),
                  ],
                  if (idea.tools != null && idea.tools!.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text(
                      'Alat & Bahan Pendukung:',
                      style: AppTypography.labelLg(color: AppColors.onSurface),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      idea.tools!,
                      style: AppTypography.bodySm(color: AppColors.onSurfaceVariant),
                    ),
                  ],
                  if (idea.steps != null && idea.steps!.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text(
                      'Langkah-Langkah Pengerjaan:',
                      style: AppTypography.labelLg(color: AppColors.onSurface),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      idea.steps!,
                      style: AppTypography.bodySm(color: AppColors.onSurfaceVariant)
                          .copyWith(height: 1.45),
                    ),
                  ],
                  if (idea.safetyNotes != null && idea.safetyNotes!.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFFF59E0B).withValues(alpha: 0.4),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.shield_outlined,
                            size: 18,
                            color: Color(0xFFD97706),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Keselamatan: ${idea.safetyNotes!}',
                              style: AppTypography.bodySm(
                                color: const Color(0xFF92400E),
                              ).copyWith(fontSize: 11.5, height: 1.35),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Tutup'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  /// 5. Action Buttons
  Widget _buildActionButtons(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: () {
              setState(() => _isSearchingPartners = true);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Menemukan 12 Mitra & Pengrajin di sekitarmu!'),
                  behavior: SnackBarBehavior.floating,
                  duration: Duration(seconds: 2),
                ),
              );
              // Navigate to Marketplace tab
              Navigator.of(context).pop();
              widget.navigationViewModel.goToMarketplace();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: const StadiumBorder(),
              elevation: 4,
              shadowColor: const Color(0x33004330),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.location_on, size: 20),
                const SizedBox(width: 8),
                Text(
                  _isSearchingPartners
                      ? 'Membuka Marketplace...'
                      : 'Cari Penerima Material',
                  style: AppTypography.labelLg(color: Colors.white),
                ),
                const SizedBox(width: 6),
                const Icon(Icons.arrow_forward, size: 18),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: OutlinedButton.icon(
            onPressed: () {
              setState(() => _isSaved = !_isSaved);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    _isSaved
                        ? 'Berhasil disimpan ke Riwayat & Ide!'
                        : 'Dihapus dari simpanan.',
                  ),
                  behavior: SnackBarBehavior.floating,
                  duration: const Duration(seconds: 2),
                ),
              );
            },
            icon: Icon(
              _isSaved ? Icons.bookmark : Icons.bookmark_border,
              size: 20,
              color: _isSaved ? AppColors.secondary : AppColors.primary,
            ),
            label: Text(
              _isSaved ? 'Tersimpan di Riwayat' : 'Simpan ke Riwayat & Ide',
              style: AppTypography.labelLg(
                color: _isSaved ? AppColors.secondary : AppColors.primary,
              ),
            ),
            style: OutlinedButton.styleFrom(
              backgroundColor: AppColors.surfaceContainerLowest,
              side: const BorderSide(color: Color(0x20707974)),
              shape: const StadiumBorder(),
            ),
          ),
        ),
      ],
    );
  }
}
