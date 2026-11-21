import 'dart:io';

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/plasvora_header.dart';
import '../../models/plastic_analysis.dart';
import '../../viewmodels/marketplace_viewmodel.dart';
import '../../viewmodels/navigation_viewmodel.dart';
import '../marketplace/create_material_listing_screen.dart';

class AnalysisResultScreen extends StatefulWidget {
  final PlasticAnalysisResult result;
  final NavigationViewModel navigationViewModel;
  final MarketplaceViewModel? marketplaceViewModel;

  const AnalysisResultScreen({
    super.key,
    required this.result,
    required this.navigationViewModel,
    this.marketplaceViewModel,
  });

  @override
  State<AnalysisResultScreen> createState() => _AnalysisResultScreenState();
}

class _AnalysisResultScreenState extends State<AnalysisResultScreen> {
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
                left: 12,
                right: 12,
                child: Align(
                  alignment: Alignment.topRight,
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
                        Flexible(
                          child: Text(
                            'Foto Analisis',
                            softWrap: true,
                            style: AppTypography.labelSm(
                              color: AppColors.onSurface,
                            ).copyWith(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 12,
                left: 12,
                right: 12,
                child: Align(
                  alignment: Alignment.bottomLeft,
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
                        Flexible(
                          child: Text(
                            'AI Vision v2.4',
                            softWrap: true,
                            style: AppTypography.labelSm(
                              color: AppColors.surfaceBright,
                            ).copyWith(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 1),
                  child: Icon(
                    result.isSimulated ? Icons.tune : Icons.auto_awesome,
                    size: 15,
                    color: result.isSimulated
                        ? AppColors.onSurfaceVariant
                        : AppColors.primary,
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    result.isSimulated
                        ? 'Mode Simulasi / Aturan Cepat'
                        : 'Dianalisis oleh Gemini AI Vision (Multi-Komponen)',
                    softWrap: true,
                    style: AppTypography.labelSm(
                      color: result.isSimulated
                          ? AppColors.onSurfaceVariant
                          : AppColors.primary,
                    ).copyWith(fontWeight: FontWeight.w600),
                  ),
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
                      softWrap: true,
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
                      softWrap: true,
                      style: AppTypography.headlineMd(
                        color: AppColors.onSurface,
                      ),
                    ),
                    if (objectDesc.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        objectDesc,
                        softWrap: true,
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
              width: double.infinity,
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
                          softWrap: true,
                          style: AppTypography.labelSm(
                            color: const Color(0xFF92400E),
                          ).copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          summary,
                          softWrap: true,
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
              width: double.infinity,
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
                      softWrap: true,
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
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 2),
                    child: Icon(
                      Icons.layers_outlined,
                      size: 19,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Komponen Material',
                      softWrap: true,
                      style: AppTypography.headlineSm(
                        color: AppColors.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
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
          softWrap: true,
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

    final hasResinCode =
        comp.resinCode != null && comp.resinCode!.trim().isNotEmpty;

    return Container(
      width: double.infinity,
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
          LayoutBuilder(
            builder: (context, constraints) {
              final textScale = MediaQuery.textScalerOf(context).scale(1.0);
              final stackAction =
                  constraints.maxWidth < 230 || textScale > 1.35;

              final checkButton = TextButton.icon(
                onPressed: () => _showComponentVerificationDialog(comp),
                icon: const Icon(
                  Icons.help_outline,
                  size: 14,
                  color: AppColors.primary,
                ),
                label: Text(
                  'Cara Cek',
                  style: AppTypography.labelSm(color: AppColors.primary),
                ),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              );

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: AppColors.secondaryContainer.withValues(
                            alpha: 0.6,
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          partIcon,
                          size: 20,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          comp.partName,
                          softWrap: true,
                          style: AppTypography.labelLg(
                            color: AppColors.onSurface,
                          ).copyWith(fontWeight: FontWeight.w700),
                        ),
                      ),
                      if (!stackAction) ...[
                        const SizedBox(width: 6),
                        checkButton,
                      ],
                    ],
                  ),
                  if (stackAction) ...[
                    const SizedBox(height: 6),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: checkButton,
                    ),
                  ],
                ],
              );
            },
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: confidenceBg,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  confidenceLabel,
                  softWrap: true,
                  style: AppTypography.labelSm(color: confidenceText).copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 9.5,
                  ),
                ),
              ),
              if (hasResinCode)
                Text(
                  'Resin ${comp.resinCode}',
                  softWrap: true,
                  style: AppTypography.bodySm(
                    color: AppColors.onSurfaceVariant,
                  ).copyWith(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    height: 1.35,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          // Baris Polimer & Kandidat
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: 'Material Dugaan: ',
                        style: AppTypography.labelSm(
                          color: AppColors.onSurfaceVariant,
                        ).copyWith(fontSize: 11),
                      ),
                      TextSpan(
                        text: comp.isUncertain
                            ? 'Perlu Dipastikan (Belum Pasti)'
                            : '${comp.materialType}${hasResinCode ? " (${comp.resinCode})" : ""}',
                        style: AppTypography.labelSm(
                          color: comp.isUncertain
                              ? const Color(0xFFD97706)
                              : AppColors.primary,
                        ).copyWith(
                          fontWeight: FontWeight.w700,
                          fontSize: 11.5,
                        ),
                      ),
                    ],
                  ),
                  softWrap: true,
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
                              softWrap: true,
                              style: AppTypography.labelSm(
                                color: AppColors.onSurface,
                              ).copyWith(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ],
                if (comp.meltingPoint != null &&
                    comp.meltingPoint!.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(top: 1.5),
                        child: Icon(
                          Icons.thermostat_outlined,
                          size: 14,
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          'Titik leleh komponen: ${comp.meltingPoint}',
                          softWrap: true,
                          style: AppTypography.bodySm(
                            color: AppColors.onSurfaceVariant,
                          ).copyWith(fontSize: 11),
                        ),
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
              const Padding(
                padding: EdgeInsets.only(top: 1),
                child: Icon(
                  Icons.search,
                  size: 15,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  comp.verificationNote,
                  softWrap: true,
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
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          'Verifikasi Fisik: ${comp.partName}',
                          softWrap: true,
                          style: AppTypography.headlineSm(
                            color: AppColors.onSurface,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.secondaryContainer.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.tips_and_updates,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          comp.verificationNote,
                          softWrap: true,
                          style: AppTypography.bodySm(
                            color: AppColors.onSurface,
                          ).copyWith(height: 1.4),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Panduan Identifikasi Manual:',
                  softWrap: true,
                  style: AppTypography.labelLg(color: AppColors.onSurface),
                ),
                const SizedBox(height: 6),
                Text(
                  '• Badan botol: Cari logo segitiga angka 1 (PET) yang tercetak timbul di dasar botol.\n'
                  '• Tutup botol: Balik tutup botol dan cari angka 2 (HDPE) atau 5 (PP) di lingkaran dalam.\n'
                  '• Pisahkan kedua komponen sebelum disetorkan ke bank sampah.',
                  softWrap: true,
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
          ),
        );
      },
    );
  }

  /// 4. Quick Polymer Specification Metrics
  Widget _buildPolymerMetrics() {
    final result = widget.result;

    final meltingCard = Container(
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.thermostat_outlined,
                size: 18,
                color: AppColors.onSurfaceVariant,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  'Karakter Titik Leleh',
                  softWrap: true,
                  style: AppTypography.labelSm(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            result.isMultiComponent
                ? 'Multi-Komponen'
                : result.meltingPoint,
            softWrap: true,
            style: AppTypography.headlineSm(color: AppColors.onSurface)
                .copyWith(fontSize: 14),
          ),
          const SizedBox(height: 2),
          Text(
            result.isMultiComponent
                ? 'Cek rincian pada setiap komponen'
                : 'Karakteristik termal polimer',
            softWrap: true,
            style: AppTypography.bodySm(color: AppColors.onSurfaceVariant)
                .copyWith(fontSize: 10.5),
          ),
        ],
      ),
    );

    final emissionCard = Container(
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.eco_outlined,
                size: 18,
                color: AppColors.onSurfaceVariant,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  'Emisi Terhindar',
                  softWrap: true,
                  style: AppTypography.labelSm(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            result.avoidedEmission,
            softWrap: true,
            style: AppTypography.headlineSm(color: AppColors.primary)
                .copyWith(fontSize: 14),
          ),
          const SizedBox(height: 2),
          Text(
            'Estimasi potensi nilai sirkular',
            softWrap: true,
            style: AppTypography.bodySm(color: AppColors.onSurfaceVariant)
                .copyWith(fontSize: 10.5),
          ),
        ],
      ),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final textScale = MediaQuery.textScalerOf(context).scale(1.0);
        final stackMetrics = constraints.maxWidth < 260 ||
            (constraints.maxWidth < 340 && textScale > 1.3);

        if (stackMetrics) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              meltingCard,
              const SizedBox(height: 10),
              emissionCard,
            ],
          );
        }

        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: meltingCard),
              const SizedBox(width: 10),
              Expanded(child: emissionCard),
            ],
          ),
        );
      },
    );
  }

  /// 5. Upcycling Recommendations Section
  Widget _buildUpcyclingRecommendations() {
    final ideas = widget.result.ideas;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 2),
                    child: Icon(
                      Icons.auto_awesome_motion,
                      size: 20,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Rekomendasi Upcycling',
                      softWrap: true,
                      style: AppTypography.headlineSm(
                        color: AppColors.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
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
          softWrap: true,
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
                  Text(
                    idea.title,
                    softWrap: true,
                    style: AppTypography.labelLg(color: AppColors.onSurface)
                        .copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
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
                          softWrap: true,
                          style: AppTypography.labelSm(
                            color: AppColors.primary,
                          ).copyWith(
                            fontWeight: FontWeight.w700,
                            fontSize: 10,
                          ),
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.schedule,
                            size: 13,
                            color: AppColors.secondary,
                          ),
                          const SizedBox(width: 3),
                          Flexible(
                            child: Text(
                              estTime,
                              softWrap: true,
                              style: AppTypography.bodySm(
                                color: AppColors.onSurfaceVariant,
                              ).copyWith(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.trending_up,
                            size: 13,
                            color: AppColors.secondary,
                          ),
                          const SizedBox(width: 3),
                          Flexible(
                            child: Text(
                              componentTag.isNotEmpty
                                  ? componentTag
                                  : scaleLabel,
                              softWrap: true,
                              style: AppTypography.bodySm(
                                color: AppColors.onSurfaceVariant,
                              ).copyWith(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            idea.title,
                            softWrap: true,
                            style: AppTypography.headlineSm(
                              color: AppColors.onSurface,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
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
                          label: Text(
                            'Bagian: $componentTag',
                            softWrap: true,
                          ),
                          backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                          labelStyle: AppTypography.labelSm(color: AppColors.primary),
                          padding: EdgeInsets.zero,
                        ),
                      Chip(
                        label: Text(quantityLabel, softWrap: true),
                        backgroundColor: AppColors.surfaceContainerHigh,
                        labelStyle: AppTypography.labelSm(color: AppColors.onSurface),
                        padding: EdgeInsets.zero,
                      ),
                      Chip(
                        label: Text(scaleLabel, softWrap: true),
                        backgroundColor: AppColors.surfaceContainerHigh,
                        labelStyle: AppTypography.labelSm(color: AppColors.onSurface),
                        padding: EdgeInsets.zero,
                      ),
                      Chip(
                        label: Text(idea.difficulty, softWrap: true),
                        backgroundColor: AppColors.secondaryContainer,
                        labelStyle: AppTypography.labelSm(color: AppColors.primary),
                        padding: EdgeInsets.zero,
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    idea.description,
                    softWrap: true,
                    style: AppTypography.bodyMd(color: AppColors.onSurfaceVariant)
                        .copyWith(height: 1.4),
                  ),
                  if (idea.whyItFits != null && idea.whyItFits!.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text(
                      'Mengapa Cocok untuk Material Ini?',
                      softWrap: true,
                      style: AppTypography.labelLg(color: AppColors.onSurface),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      idea.whyItFits!,
                      softWrap: true,
                      style: AppTypography.bodySm(color: AppColors.onSurfaceVariant)
                          .copyWith(height: 1.4),
                    ),
                  ],
                  if (idea.tools != null && idea.tools!.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text(
                      'Alat & Bahan Pendukung:',
                      softWrap: true,
                      style: AppTypography.labelLg(color: AppColors.onSurface),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      idea.tools!,
                      softWrap: true,
                      style: AppTypography.bodySm(color: AppColors.onSurfaceVariant),
                    ),
                  ],
                  if (idea.steps != null && idea.steps!.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text(
                      'Langkah-Langkah Pengerjaan:',
                      softWrap: true,
                      style: AppTypography.labelLg(color: AppColors.onSurface),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      idea.steps!,
                      softWrap: true,
                      style: AppTypography.bodySm(color: AppColors.onSurfaceVariant)
                          .copyWith(height: 1.45),
                    ),
                  ],
                  if (idea.safetyNotes != null && idea.safetyNotes!.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
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
                              softWrap: true,
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
    final canSell = widget.marketplaceViewModel != null;
    return Column(
      children: [
        // ─── Tombol Utama: Jual Material Ini ───────────────────────
        if (canSell)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => CreateMaterialListingScreen(
                      viewModel: widget.marketplaceViewModel!,
                      initialAnalysis: widget.result,
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.sell_outlined, size: 20),
              label: Text(
                'Jual Material Ini',
                textAlign: TextAlign.center,
                softWrap: true,
                style: AppTypography.labelLg(color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 52),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                shape: const StadiumBorder(),
                elevation: 4,
                shadowColor: const Color(0x33004330),
              ),
            ),
          ),
        if (canSell) const SizedBox(height: 10),

        // ─── Tombol Sekunder: Cari Penerima di Marketplace ─────────
        SizedBox(
          width: double.infinity,
          child: canSell
              ? OutlinedButton.icon(
                  onPressed: () {
                    setState(() => _isSearchingPartners = true);
                    Navigator.of(context).pop();
                    widget.navigationViewModel.goToMarketplace();
                  },
                  icon: const Icon(
                    Icons.location_on,
                    size: 20,
                    color: AppColors.primary,
                  ),
                  label: Text(
                    _isSearchingPartners
                        ? 'Membuka Marketplace...'
                        : 'Cari Penerima Material di Marketplace',
                    textAlign: TextAlign.center,
                    softWrap: true,
                    style: AppTypography.labelMd(color: AppColors.primary)
                        .copyWith(fontWeight: FontWeight.w600),
                  ),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 48),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    side: BorderSide(
                        color: AppColors.primary.withValues(alpha: 0.5)),
                    shape: const StadiumBorder(),
                  ),
                )
              : ElevatedButton.icon(
                  onPressed: () {
                    setState(() => _isSearchingPartners = true);
                    Navigator.of(context).pop();
                    widget.navigationViewModel.goToMarketplace();
                  },
                  icon: const Icon(
                    Icons.location_on,
                    size: 20,
                    color: Colors.white,
                  ),
                  label: Text(
                    _isSearchingPartners
                        ? 'Membuka Marketplace...'
                        : 'Cari Penerima Material di Marketplace',
                    textAlign: TextAlign.center,
                    softWrap: true,
                    style: AppTypography.labelLg(color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 52),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    shape: const StadiumBorder(),
                    elevation: 4,
                  ),
                ),
        ),
        const SizedBox(height: 10),

        // ─── Tombol Tersier: Ajukan Kebutuhan ──────────────────────
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () {
              Navigator.of(context).pop();
              widget.navigationViewModel.goToMarketplace();
            },
            icon: const Icon(
              Icons.post_add,
              size: 18,
              color: AppColors.primary,
            ),
            label: Text(
              'Cari / Ajukan Kebutuhan (${widget.result.polymerCategory}) di Marketplace',
              textAlign: TextAlign.center,
              softWrap: true,
              style: AppTypography.labelMd(color: AppColors.primary)
                  .copyWith(fontWeight: FontWeight.w600),
            ),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              side: BorderSide(
                  color: AppColors.primary.withValues(alpha: 0.5)),
              shape: const StadiumBorder(),
            ),
          ),
        ),
        const SizedBox(height: 10),

        // ─── Info: analisis tersimpan ───────────────────────────────
        Container(
          width: double.infinity,
          constraints: const BoxConstraints(minHeight: 48),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: AppColors.outline.withValues(alpha: 0.2),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.check_circle_outline,
                size: 18,
                color: AppColors.primary,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  'Analisis tersimpan otomatis di sistem',
                  textAlign: TextAlign.center,
                  softWrap: true,
                  style: AppTypography.labelMd(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
