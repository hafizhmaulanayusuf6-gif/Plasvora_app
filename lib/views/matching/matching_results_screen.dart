import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../models/matching_result.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/marketplace_viewmodel.dart';
import '../../viewmodels/matching_viewmodel.dart';
import '../marketplace/material_detail_screen.dart';

class MatchingResultsScreen extends StatefulWidget {
  final MatchingViewModel matchingViewModel;
  final MarketplaceViewModel marketplaceViewModel;
  final AuthViewModel? authViewModel;
  final int? requestId;
  final int? listingId;
  final String? title;

  const MatchingResultsScreen({
    super.key,
    required this.matchingViewModel,
    required this.marketplaceViewModel,
    this.authViewModel,
    this.requestId,
    this.listingId,
    this.title,
  }) : assert(requestId != null || listingId != null,
            'Harus menyertakan requestId atau listingId');

  @override
  State<MatchingResultsScreen> createState() => _MatchingResultsScreenState();
}

class _MatchingResultsScreenState extends State<MatchingResultsScreen> {
  @override
  void initState() {
    super.initState();
    _loadMatches();
  }

  void _loadMatches() {
    if (widget.requestId != null) {
      widget.matchingViewModel.findMatchesForRequest(widget.requestId!);
    } else if (widget.listingId != null) {
      widget.matchingViewModel.findMatchesForListing(widget.listingId!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isForRequest = widget.requestId != null;

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: Text(
          widget.title ?? (isForRequest ? 'Hasil Smart Matching' : 'Permintaan Cocok'),
          style: AppTypography.headlineSm(color: AppColors.onSurface),
        ),
        backgroundColor: AppColors.surfaceContainerLowest,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.onSurface),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: ListenableBuilder(
        listenable: widget.matchingViewModel,
        builder: (context, _) {
          final vm = widget.matchingViewModel;

          if (vm.isLoading) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(
                      color: AppColors.primaryContainer,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Mencari Material yang Sesuai...',
                      style: AppTypography.headlineSm(color: AppColors.onSurface),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Algoritma backend sedang mengevaluasi kategori, berat, kondisi, dan lokasi.',
                      style: AppTypography.bodySm(color: AppColors.outline),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }

          if (vm.errorMessage != null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline,
                        size: 48, color: Colors.redAccent),
                    const SizedBox(height: 12),
                    Text(
                      'Gagal Memuat Hasil Pencocokan',
                      style: AppTypography.headlineSm(color: AppColors.onSurface),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      vm.errorMessage!,
                      style: AppTypography.bodySm(color: AppColors.outline),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _loadMatches,
                      icon: const Icon(Icons.refresh, size: 18),
                      label: const Text('Coba Lagi'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryContainer,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          if (isForRequest) {
            final res = vm.requestMatchingResponse;
            if (res == null || res.matches.isEmpty) {
              return _buildEmptyState(
                title: 'Belum Ada Material yang Cocok',
                description:
                    'Saat ini belum ada listing material aktif yang memenuhi kriteria kategori (${res?.request.categoryLabel ?? ""}) dan kebutuhan Anda.',
              );
            }
            return _buildRequestMatchesList(res);
          } else {
            final res = vm.listingMatchingResponse;
            if (res == null || res.matches.isEmpty) {
              return _buildEmptyState(
                title: 'Belum Ada Permintaan yang Cocok',
                description:
                    'Saat ini belum ada kebutuhan material aktif yang sesuai dengan spesifikasi material ini.',
              );
            }
            return _buildListingMatchesList(res);
          }
        },
      ),
    );
  }

  Widget _buildEmptyState({
    required String title,
    required String description,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.secondaryContainer.withValues(alpha: 0.3),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.search_off,
                size: 48,
                color: AppColors.secondary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: AppTypography.headlineSm(color: AppColors.onSurface),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: AppTypography.bodySm(color: AppColors.outline),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.arrow_back, size: 18),
              label: const Text('Kembali'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRequestMatchesList(MaterialRequestMatchingResponse res) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildInfoBanner(
          note: res.note,
          explanation:
              'Skor dihitung berdasarkan aturan backend: Kategori (40 poin), Berat (30 poin), Kondisi (20 poin), Lokasi (10 poin). Bukan probabilitas AI.',
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Rekomendasi Material (${res.total})',
              style: AppTypography.headlineSm(color: AppColors.onSurface),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Kebutuhan: ${res.request.categoryLabel} ${res.request.formattedWeight}',
                style: AppTypography.labelSm(color: AppColors.onSurfaceVariant),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...res.matches.map((match) => _buildMatchCard(match)),
      ],
    );
  }

  Widget _buildListingMatchesList(MaterialListingMatchingResponse res) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildInfoBanner(
          note: res.note,
          explanation:
              'Skor dihitung berdasarkan aturan backend: Kategori (40 poin), Berat (30 poin), Kondisi (20 poin), Lokasi (10 poin). Bukan probabilitas AI.',
        ),
        const SizedBox(height: 16),
        Text(
          'Permintaan Kebutuhan yang Cocok (${res.total})',
          style: AppTypography.headlineSm(color: AppColors.onSurface),
        ),
        const SizedBox(height: 12),
        ...res.matches.map((match) => _buildListingMatchCard(match)),
      ],
    );
  }

  Widget _buildInfoBanner({required String note, required String explanation}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.secondaryContainer.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.secondary.withValues(alpha: 0.25),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.bolt, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                'Smart Matching Berbasis Aturan',
                style: AppTypography.labelLg(color: AppColors.primary)
                    .copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            explanation,
            style: AppTypography.bodySm(color: AppColors.onSurface)
                .copyWith(height: 1.35, fontSize: 11.5),
          ),
        ],
      ),
    );
  }

  Widget _buildMatchCard(MaterialRequestMatchItem match) {
    final listing = match.listing;
    final score = match.matchScore;

    Color scoreColor;
    Color scoreBg;
    if (score >= 80) {
      scoreColor = const Color(0xFF15803D);
      scoreBg = const Color(0xFFDCFCE7);
    } else if (score >= 60) {
      scoreColor = const Color(0xFF0F766E);
      scoreBg = const Color(0xFFCCFBF1);
    } else {
      scoreColor = const Color(0xFFB45309);
      scoreBg = const Color(0xFFFEF3C7);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.outline.withValues(alpha: 0.2),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => MaterialDetailScreen(
                  materialId: listing.id,
                  initialMaterial: listing,
                  viewModel: widget.marketplaceViewModel,
                  authViewModel: widget.authViewModel,
                ),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top row: Score badge & Price
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: scoreBg,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.star, size: 14, color: scoreColor),
                          const SizedBox(width: 4),
                          Text(
                            'Skor Kecocokan: $score/100',
                            style: AppTypography.labelSm(color: scoreColor)
                                .copyWith(fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      listing.isFree ? 'Gratis' : listing.formattedPrice,
                      style: AppTypography.labelLg(
                        color: listing.isFree
                            ? const Color(0xFF15803D)
                            : AppColors.primaryContainer,
                      ).copyWith(fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Material title
                Text(
                  listing.name,
                  style: AppTypography.headlineSm(color: AppColors.onSurface)
                      .copyWith(fontSize: 16),
                ),
                const SizedBox(height: 8),

                // Key specifications row
                Wrap(
                  spacing: 12,
                  runSpacing: 6,
                  children: [
                    _buildSpecItem(Icons.category_outlined, listing.categoryLabel),
                    _buildSpecItem(Icons.scale_outlined, '${listing.weightKg} kg'),
                    _buildSpecItem(Icons.clean_hands_outlined, listing.conditionLabel),
                    _buildSpecItem(Icons.location_on_outlined, listing.generalLocation),
                  ],
                ),
                const SizedBox(height: 12),

                // Match reasons details
                if (match.matchReasonsDetail.isNotEmpty) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: match.matchReasonsDetail.values.map((reason) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(
                                Icons.check_circle,
                                size: 14,
                                color: Color(0xFF15803D),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  reason,
                                  style: AppTypography.bodySm(
                                    color: AppColors.onSurface,
                                  ).copyWith(fontSize: 11),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                // Bottom row: Owner info & Action button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.person_outline,
                          size: 16,
                          color: AppColors.secondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          listing.ownerName ?? 'Pemilik Material',
                          style: AppTypography.bodySm(
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Text(
                          'Lihat Detail',
                          style: AppTypography.labelSm(
                            color: AppColors.primaryContainer,
                          ).copyWith(fontWeight: FontWeight.w700),
                        ),
                        const Icon(
                          Icons.arrow_forward_ios,
                          size: 12,
                          color: AppColors.primaryContainer,
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildListingMatchCard(MaterialListingMatchItem match) {
    final req = match.request;
    final score = match.matchScore;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Skor Kecocokan: $score/100',
                  style: AppTypography.labelSm(color: const Color(0xFF15803D))
                      .copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              Text(
                req.categoryLabel,
                style: AppTypography.labelLg(color: AppColors.primaryContainer),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            req.intendedUse,
            style: AppTypography.bodyMd(color: AppColors.onSurface)
                .copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 12,
            runSpacing: 6,
            children: [
              _buildSpecItem(Icons.scale_outlined, req.formattedWeight),
              _buildSpecItem(Icons.clean_hands_outlined, 'Min. ${req.conditionLabel}'),
              _buildSpecItem(Icons.location_on_outlined, req.generalLocation),
              if (req.requesterName != null)
                _buildSpecItem(Icons.person_outline, req.requesterName!),
            ],
          ),
          if (match.matchReasonsDetail.isNotEmpty) ...[
            const SizedBox(height: 10),
            ...match.matchReasonsDetail.values.map(
              (r) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    const Icon(Icons.check, size: 14, color: Color(0xFF15803D)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        r,
                        style: AppTypography.bodySm(color: AppColors.onSurfaceVariant)
                            .copyWith(fontSize: 11),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSpecItem(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppColors.secondary),
        const SizedBox(width: 4),
        Text(
          text,
          style: AppTypography.bodySm(color: AppColors.onSurfaceVariant)
              .copyWith(fontSize: 12),
        ),
      ],
    );
  }
}

