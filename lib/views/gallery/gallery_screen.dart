import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/plasvora_header.dart';
import '../../models/gallery_work.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/gallery_viewmodel.dart';
import '../../viewmodels/navigation_viewmodel.dart';
import '../auth/login_screen.dart';
import 'create_gallery_work_screen.dart';
import 'gallery_detail_screen.dart';
import 'gallery_widgets.dart';

class GalleryScreen extends StatefulWidget {
  final GalleryViewModel viewModel;
  final NavigationViewModel navigationViewModel;
  final AuthViewModel? authViewModel;

  const GalleryScreen({
    super.key,
    required this.viewModel,
    required this.navigationViewModel,
    this.authViewModel,
  });

  @override
  State<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _searchController.text = widget.viewModel.searchQuery;
    if (!widget.viewModel.hasLoadedFeed && !widget.viewModel.isLoadingFeed) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          widget.viewModel.loadFeed();
        }
      });
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _handleAvatarTap() {
    final authVm = widget.authViewModel;
    if (authVm == null || authVm.isAuthenticated) {
      widget.navigationViewModel.goToProfile();
    } else {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => LoginScreen(authViewModel: authVm),
        ),
      );
    }
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      if (mounted) {
        widget.viewModel.setSearchQuery(value);
      }
    });
    setState(() {});
  }

  void _handleShareWorkTap() {
    final authVm = widget.authViewModel;
    if (authVm != null && !authVm.isAuthenticated) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Masuk terlebih dahulu untuk membagikan karya.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => LoginScreen(authViewModel: authVm),
        ),
      );
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CreateGalleryWorkScreen(
          viewModel: widget.viewModel,
          authViewModel: widget.authViewModel,
        ),
      ),
    );
  }

  void _openDetail(GalleryWork work) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => GalleryDetailScreen(
          workId: work.id,
          initialWork: work,
          viewModel: widget.viewModel,
          authViewModel: widget.authViewModel,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: PlasvoraHeader(onAvatarTap: _handleAvatarTap),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: null,
        onPressed: _handleShareWorkTap,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 3,
        icon: const Icon(Icons.add_photo_alternate_outlined, size: 20),
        label: Text(
          'Bagikan Karya',
          style: AppTypography.labelLg(color: Colors.white),
        ),
      ),
      body: SafeArea(
        top: false,
        child: ListenableBuilder(
          listenable: widget.viewModel,
          builder: (context, _) {
            final vm = widget.viewModel;

            return RefreshIndicator(
              color: AppColors.primary,
              onRefresh: () => vm.loadFeed(refresh: true),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final textScale =
                      MediaQuery.textScalerOf(context).scale(1.0).clamp(1.0, 2.0);
                  final gridPadding = 20.0;
                  final gridSpacing = 12.0;
                  final tileWidth =
                      ((constraints.maxWidth - (gridPadding * 2) - gridSpacing) /
                              2)
                          .clamp(120.0, 320.0);
                  // Image uses 4:3 aspect + responsive text block height
                  final imageHeight = tileWidth * 0.78;
                  final infoHeight = 96.0 * textScale;
                  final cardExtent = imageHeight + infoHeight;

                  return CustomScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: [
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                          child: _buildHeaderAndControls(vm),
                        ),
                      ),
                      ..._buildFeedBodySlivers(vm, cardExtent: cardExtent),
                      const SliverToBoxAdapter(
                        child: SizedBox(height: 92),
                      ),
                    ],
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeaderAndControls(GalleryViewModel vm) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Galeri Karya',
          style: AppTypography.headlineLgMobile(color: AppColors.onSurface),
        ),
        const SizedBox(height: 4),
        Text(
          'Inspirasi kreasi daur ulang plastik dari komunitas Plasvora.',
          style: AppTypography.bodySm(color: AppColors.onSurfaceVariant),
        ),
        const SizedBox(height: 14),
        // Search field
        TextField(
          controller: _searchController,
          onChanged: _onSearchChanged,
          onSubmitted: (v) {
            _debounce?.cancel();
            vm.setSearchQuery(v);
          },
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            hintText: 'Cari karya daur ulang...',
            hintStyle: AppTypography.bodyMd(color: AppColors.textSecondary),
            prefixIcon: const Icon(
              Icons.search_rounded,
              color: AppColors.secondary,
              size: 22,
            ),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    tooltip: 'Hapus pencarian',
                    icon: const Icon(
                      Icons.close_rounded,
                      size: 20,
                      color: AppColors.textSecondary,
                    ),
                    onPressed: () {
                      _debounce?.cancel();
                      _searchController.clear();
                      setState(() {});
                      vm.setSearchQuery('');
                    },
                  )
                : null,
            filled: true,
            fillColor: AppColors.surfaceContainerLowest,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                color: AppColors.outlineVariant.withValues(alpha: 0.6),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                color: AppColors.outlineVariant.withValues(alpha: 0.6),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(
                color: AppColors.primary,
                width: 1.5,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Difficulty filter chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _DifficultyFilterChip(
                label: 'Semua',
                selected: vm.selectedDifficulty == null,
                onTap: () => vm.setDifficulty(null),
              ),
              const SizedBox(width: 8),
              ...GalleryDifficulty.values.map(
                (diff) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _DifficultyFilterChip(
                    label: diff.label,
                    selected: vm.selectedDifficulty == diff,
                    onTap: () => vm.setDifficulty(diff),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        // Sort row
        Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              'Urutkan:',
              style: AppTypography.labelMd(color: AppColors.onSurfaceVariant),
            ),
            _SortPill(
              label: 'Terbaru',
              selected: vm.sortBy == 'latest',
              onTap: () => vm.setSortBy('latest'),
            ),
            _SortPill(
              label: 'Terpopuler',
              selected: vm.sortBy == 'popular',
              onTap: () => vm.setSortBy('popular'),
            ),
          ],
        ),
      ],
    );
  }

  List<Widget> _buildFeedBodySlivers(
    GalleryViewModel vm, {
    required double cardExtent,
  }) {
    if (vm.isLoadingFeed && vm.works.isEmpty) {
      return [
        const SliverFillRemaining(
          hasScrollBody: false,
          child: Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          ),
        ),
      ];
    }

    if (vm.feedError != null && vm.works.isEmpty) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: _GalleryMessageCard(
                icon: Icons.wifi_off_rounded,
                title: 'Gagal Memuat Galeri',
                message: vm.feedError!,
                actionLabel: 'Coba Lagi',
                onAction: () => vm.loadFeed(refresh: true),
              ),
            ),
          ),
        ),
      ];
    }

    if (vm.works.isEmpty) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: vm.hasActiveFilters
                  ? _GalleryMessageCard(
                      icon: Icons.search_off_rounded,
                      title: 'Karya Tidak Ditemukan',
                      message:
                          'Tidak ada karya yang sesuai dengan pencarian atau filter tingkat kesulitan ini.',
                      actionLabel: 'Reset Filter',
                      onAction: () {
                        _searchController.clear();
                        setState(() {});
                        vm.clearFilters();
                      },
                    )
                  : _GalleryMessageCard(
                      icon: Icons.auto_awesome_mosaic_outlined,
                      title: 'Belum Ada Karya di Galeri',
                      message:
                          'Jadilah yang pertama membagikan hasil karya daur ulang plastik Anda kepada komunitas.',
                      actionLabel: 'Bagikan Karya',
                      onAction: _handleShareWorkTap,
                    ),
            ),
          ),
        ),
      ];
    }

    return [
      if (vm.isLoadingFeed)
        const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            child: LinearProgressIndicator(
              color: AppColors.primary,
              backgroundColor: AppColors.secondaryContainer,
            ),
          ),
        ),
      SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        sliver: SliverGrid(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            mainAxisExtent: cardExtent,
          ),
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final work = vm.works[index];
              return _GalleryWorkCard(
                work: work,
                onTap: () => _openDetail(work),
              );
            },
            childCount: vm.works.length,
          ),
        ),
      ),
      if (vm.hasMoreFeed)
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Center(
              child: OutlinedButton(
                onPressed: vm.isLoadingMoreFeed ? null : vm.loadMoreFeed,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary),
                  minimumSize: const Size(180, 48),
                  shape: const StadiumBorder(),
                ),
                child: vm.isLoadingMoreFeed
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.primary,
                        ),
                      )
                    : Text(
                        'Muat Lebih Banyak',
                        style: AppTypography.labelLg(color: AppColors.primary),
                      ),
              ),
            ),
          ),
        ),
    ];
  }
}

class _DifficultyFilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _DifficultyFilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: AppColors.primary,
      backgroundColor: AppColors.surfaceContainerLowest,
      checkmarkColor: Colors.white,
      labelStyle: AppTypography.labelMd(
        color: selected ? Colors.white : AppColors.onSurface,
      ),
      side: BorderSide(
        color: selected
            ? AppColors.primary
            : AppColors.outlineVariant.withValues(alpha: 0.7),
      ),
      shape: const StadiumBorder(),
      materialTapTargetSize: MaterialTapTargetSize.padded,
    );
  }
}

class _SortPill extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _SortPill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? AppColors.secondaryContainer
          : AppColors.surfaceContainerLowest,
      shape: StadiumBorder(
        side: BorderSide(
          color: selected
              ? AppColors.primary
              : AppColors.outlineVariant.withValues(alpha: 0.6),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Text(
            label,
            style: AppTypography.labelMd(
              color: selected ? AppColors.primary : AppColors.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}

class _GalleryWorkCard extends StatelessWidget {
  final GalleryWork work;
  final VoidCallback onTap;

  const _GalleryWorkCard({
    required this.work,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '${work.title}, oleh ${work.author.name}, tingkat ${work.difficulty.label}, ${work.likesCount} suka',
      child: Material(
        color: AppColors.surfaceContainerLowest,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: AppColors.outlineVariant.withValues(alpha: 0.45),
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 5,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    GalleryPhotoBox(
                      imageUrlOrPath: work.effectiveCoverUrl,
                      fit: BoxFit.cover,
                    ),
                    Positioned(
                      top: 8,
                      left: 8,
                      child: DifficultyBadge(
                        difficulty: work.difficulty,
                        compact: true,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                flex: 4,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        work.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.labelLg(
                          color: AppColors.onSurface,
                        ).copyWith(fontSize: 13, height: 1.25),
                      ),
                      const Spacer(),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              work.author.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.bodySm(
                                color: AppColors.onSurfaceVariant,
                              ).copyWith(fontSize: 11.5),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Icon(
                            work.likedByMe
                                ? Icons.favorite_rounded
                                : Icons.favorite_border_rounded,
                            size: 15,
                            color: work.likedByMe
                                ? AppColors.error
                                : AppColors.textSecondary,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            '${work.likesCount}',
                            style: AppTypography.labelSm(
                              color: AppColors.onSurfaceVariant,
                            ),
                          ),
                        ],
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
}

class _GalleryMessageCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String actionLabel;
  final VoidCallback onAction;

  const _GalleryMessageCard({
    required this.icon,
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.45),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: const BoxDecoration(
              color: AppColors.secondaryContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 28, color: AppColors.primary),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            textAlign: TextAlign.center,
            style: AppTypography.headlineSm(color: AppColors.onSurface),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: AppTypography.bodySm(color: AppColors.onSurfaceVariant),
          ),
          const SizedBox(height: 18),
          ElevatedButton(
            onPressed: onAction,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              minimumSize: const Size(160, 48),
              shape: const StadiumBorder(),
            ),
            child: Text(
              actionLabel,
              style: AppTypography.labelLg(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
