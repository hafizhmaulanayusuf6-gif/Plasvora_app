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
        customTitle: 'Hasil Pemindaian Ai',
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
              _buildIdentificationCard(),
              const SizedBox(height: 14),
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

  /// 2. Identification Result Card
  Widget _buildIdentificationCard() {
    final result = widget.result;

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
        children: [
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
                      'ESTIMASI KATEGORI MATERIAL',
                      style:
                          AppTypography.labelSm(
                            color: AppColors.onSurfaceVariant,
                          ).copyWith(
                            letterSpacing: 0.6,
                            fontWeight: FontWeight.w700,
                            fontSize: 10,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      result.materialTitle,
                      style: AppTypography.headlineMd(
                        color: AppColors.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceContainerHigh,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            result.polymerCategory,
                            style: AppTypography.labelSm(
                              color: AppColors.primary,
                            ).copyWith(fontWeight: FontWeight.w700),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          result.polymerCode,
                          style: AppTypography.bodySm(
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              TextButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Anda dapat mengubah kategori pada form input sebelumnya.',
                      ),
                      behavior: SnackBarBehavior.floating,
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
                icon: const Icon(
                  Icons.edit,
                  size: 14,
                  color: AppColors.primary,
                ),
                label: Text(
                  'Verifikasi',
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
              ),
            ],
          ),
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
                    result.qualitativeNote,
                    style: AppTypography.bodySm(
                      color: AppColors.onSurfaceVariant,
                    ).copyWith(fontSize: 11.5, height: 1.35),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 3. Quick Polymer Specification Metrics
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
                      'Titik Leleh',
                      style: AppTypography.labelSm(
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  result.meltingPoint,
                  style: AppTypography.headlineSm(color: AppColors.onSurface),
                ),
                const SizedBox(height: 2),
                Text(
                  'Aman dilebur bertahap',
                  style: AppTypography.bodySm(color: AppColors.onSurfaceVariant)
                      .copyWith(fontSize: 11),
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
                  style: AppTypography.headlineSm(color: AppColors.primary),
                ),
                const SizedBox(height: 2),
                Text(
                  'Potensi nilai sirkular',
                  style: AppTypography.bodySm(color: AppColors.onSurfaceVariant)
                      .copyWith(fontSize: 11),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// 4. Upcycling Recommendations Section
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
                  'Rekomendasi Ide Upcycling',
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

  Widget _buildIdeaCard(UpcyclingIdea idea) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
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
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.asset(
              idea.imageAsset,
              width: 76,
              height: 76,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                width: 76,
                height: 76,
                color: AppColors.surfaceContainer,
                child: const Icon(Icons.handyman, color: AppColors.secondary),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: idea.difficulty.contains('Mudah')
                        ? AppColors.tertiaryFixed
                        : AppColors.surfaceContainer,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    idea.difficulty,
                    style: AppTypography.labelSm(
                      color: idea.difficulty.contains('Mudah')
                          ? AppColors.onTertiaryFixed
                          : AppColors.primary,
                    ).copyWith(fontWeight: FontWeight.w700, fontSize: 10),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  idea.title,
                  style: AppTypography.labelLg(color: AppColors.onSurface),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  idea.description,
                  style: AppTypography.bodySm(color: AppColors.onSurfaceVariant)
                      .copyWith(fontSize: 11),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Container(
            width: 32,
            height: 32,
            decoration: const BoxDecoration(
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
