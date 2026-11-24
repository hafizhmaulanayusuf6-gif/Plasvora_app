import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/video_link_validator.dart';
import '../../core/widgets/simple_page_app_bar.dart';
import '../../models/gallery_work.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/gallery_viewmodel.dart';
import '../auth/login_screen.dart';
import 'create_gallery_work_screen.dart';
import 'gallery_widgets.dart';

class GalleryDetailScreen extends StatefulWidget {
  final int workId;
  final GalleryWork? initialWork;
  final GalleryViewModel viewModel;
  final AuthViewModel? authViewModel;
  final Future<bool> Function(Uri uri)? urlLauncher;

  const GalleryDetailScreen({
    super.key,
    required this.workId,
    this.initialWork,
    required this.viewModel,
    this.authViewModel,
    this.urlLauncher,
  });

  @override
  State<GalleryDetailScreen> createState() => _GalleryDetailScreenState();
}

class _GalleryDetailScreenState extends State<GalleryDetailScreen> {
  final PageController _pageController = PageController();
  int _currentImageIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        widget.viewModel.loadWorkDetail(widget.workId, forceRefresh: true);
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  bool _isAuthor(GalleryWork work) {
    final userId = widget.authViewModel?.currentUser?.id;
    return userId != null && userId == work.author.id;
  }

  Future<void> _handleLikeTap(GalleryWork work) async {
    final authVm = widget.authViewModel;
    if (authVm != null && !authVm.isAuthenticated) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Masuk terlebih dahulu untuk menyukai karya.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      await Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => LoginScreen(authViewModel: authVm)),
      );
      return;
    }

    if (!work.isApproved) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Hanya karya yang sedang tayang yang dapat disukai.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final error = await widget.viewModel.toggleLike(work.id);
    if (error != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _openVideoLink(String rawUrl) async {
    if (!VideoLinkValidator.isValid(rawUrl)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tautan video tidak valid atau tidak didukung.'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final uri = Uri.parse(rawUrl.trim());
    final host = VideoLinkValidator.extractDisplayHost(rawUrl);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Buka di Aplikasi Eksternal?'),
        content: Text(
          'Tautan video tutorial ini akan dibuka di aplikasi luar ($host).',
          style: AppTypography.bodySm(color: AppColors.onSurfaceVariant),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(dialogCtx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              minimumSize: const Size(0, 44),
            ),
            child: const Text('Buka'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    bool launched = false;
    try {
      if (widget.urlLauncher != null) {
        launched = await widget.urlLauncher!(uri);
      } else {
        launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {
      launched = false;
    }

    if (!launched && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tidak dapat membuka tautan video di perangkat ini.'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _openEdit(GalleryWork work) async {
    final updated = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => CreateGalleryWorkScreen(
          viewModel: widget.viewModel,
          authViewModel: widget.authViewModel,
          existingWork: work,
        ),
      ),
    );
    if (updated == true && mounted) {
      await widget.viewModel.loadWorkDetail(work.id, forceRefresh: true);
    }
  }

  Future<void> _confirmAndDelete(GalleryWork work) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Hapus Karya?'),
        content: Text(
          'Karya "${work.title}" dan seluruh fotonya akan dihapus secara permanen.',
          style: AppTypography.bodySm(color: AppColors.onSurfaceVariant),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(dialogCtx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              minimumSize: const Size(0, 44),
            ),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final error = await widget.viewModel.deleteWork(work.id);
    if (!mounted) return;
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Karya galeri berhasil dihapus.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
    Navigator.of(context).pop(true);
  }

  void _openFullscreenViewer(List<String> urls, int initialIndex) {
    Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => _FullscreenGalleryPhotoViewer(
          imageUrls: urls,
          initialIndex: initialIndex,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: const SimplePageAppBar(title: 'Detail Karya'),
      body: SafeArea(
        top: false,
        child: ListenableBuilder(
          listenable: widget.viewModel,
          builder: (context, _) {
            final vm = widget.viewModel;
            final work = vm.getCachedDetail(widget.workId) ?? widget.initialWork;
            final isLoading = vm.isLoadingDetail(widget.workId);
            final error = vm.getDetailError(widget.workId);
            final statusCode = vm.getDetailStatusCode(widget.workId);

            if (work == null && isLoading) {
              return const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              );
            }

            if (work == null && error != null) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Container(
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
                        Icon(
                          statusCode == 404
                              ? Icons.search_off_rounded
                              : Icons.error_outline_rounded,
                          size: 40,
                          color: AppColors.primary,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          statusCode == 404
                              ? 'Karya Tidak Ditemukan'
                              : 'Gagal Memuat Detail',
                          textAlign: TextAlign.center,
                          style: AppTypography.headlineSm(
                            color: AppColors.onSurface,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          error,
                          textAlign: TextAlign.center,
                          style: AppTypography.bodySm(
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 16),
                        if (statusCode != 404)
                          ElevatedButton(
                            onPressed: () => vm.loadWorkDetail(
                              widget.workId,
                              forceRefresh: true,
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              minimumSize: const Size(140, 48),
                              shape: const StadiumBorder(),
                            ),
                            child: const Text('Coba Lagi'),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            }

            if (work == null) {
              return const SizedBox.shrink();
            }

            final isAuthor = _isAuthor(work);
            final imageUrls = work.images.isNotEmpty
                ? work.images.map((i) => i.url).where((u) => u.isNotEmpty).toList()
                : (work.effectiveCoverUrl != null
                    ? [work.effectiveCoverUrl!]
                    : <String>[]);

            return RefreshIndicator(
              color: AppColors.primary,
              onRefresh: () => vm.loadWorkDetail(work.id, forceRefresh: true),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (isLoading)
                      const Padding(
                        padding: EdgeInsets.only(bottom: 12),
                        child: LinearProgressIndicator(
                          color: AppColors.primary,
                          backgroundColor: AppColors.secondaryContainer,
                        ),
                      ),

                    // Author moderation status banner
                    if (isAuthor && work.status != null) ...[
                      _buildAuthorStatusBanner(work),
                      const SizedBox(height: 14),
                    ],

                    // Photo Carousel
                    _buildPhotoCarousel(imageUrls),
                    const SizedBox(height: 16),

                    // Title + Meta + Like
                    _buildSummaryCard(work, vm),
                    const SizedBox(height: 16),

                    // Author Edit / Delete actions
                    if (isAuthor) ...[
                      _buildAuthorActions(work, vm),
                      const SizedBox(height: 16),
                    ],

                    // Bahan (Materials)
                    _buildBulletSection(
                      title: 'Bahan',
                      icon: Icons.inventory_2_outlined,
                      items: work.materials,
                      emptyFallback: 'Daftar bahan belum tersedia.',
                    ),

                    // Alat (Tools — hidden if empty)
                    if (work.tools.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      _buildBulletSection(
                        title: 'Alat',
                        icon: Icons.build_outlined,
                        items: work.tools,
                      ),
                    ],

                    // Langkah-Langkah (Numbered Steps)
                    const SizedBox(height: 16),
                    _buildStepsSection(work.steps),

                    // Video Tutorial (hidden if empty)
                    if (work.videoLinks.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      _buildVideoLinksSection(work.videoLinks),
                    ],
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildAuthorStatusBanner(GalleryWork work) {
    final status = work.status!;
    final (Color bg, Color borderColor, String description) = switch (status) {
      GalleryWorkStatus.pending => (
        const Color(0xFFFFFBEB),
        const Color(0xFFF59E0B),
        'Karya ini masih berstatus menunggu verifikasi.',
      ),
      GalleryWorkStatus.approved => (
        const Color(0xFFECFDF5),
        AppColors.primary,
        'Karya Anda sedang tayang di Galeri publik.',
      ),
      GalleryWorkStatus.rejected => (
        const Color(0xFFFFF1F2),
        AppColors.error,
        'Karya ini tidak ditayangkan di Galeri publik.',
      ),
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor.withValues(alpha: 0.45)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ModerationStatusBadge(status: status),
          const SizedBox(height: 8),
          Text(
            description,
            style: AppTypography.bodySm(color: AppColors.onSurface),
          ),
          if (work.isRejected &&
              work.rejectionReason != null &&
              work.rejectionReason!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: AppColors.error.withValues(alpha: 0.25),
                ),
              ),
              child: Text(
                'Alasan penolakan: ${work.rejectionReason!}',
                style: AppTypography.bodySm(color: AppColors.error).copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPhotoCarousel(List<String> imageUrls) {
    if (imageUrls.isEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: const AspectRatio(
          aspectRatio: 4 / 3,
          child: GalleryPhotoBox(imageUrlOrPath: null),
        ),
      );
    }

    final safeIndex = _currentImageIndex.clamp(0, imageUrls.length - 1);

    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: AspectRatio(
            aspectRatio: 4 / 3,
            child: Stack(
              children: [
                PageView.builder(
                  controller: _pageController,
                  itemCount: imageUrls.length,
                  onPageChanged: (index) {
                    setState(() => _currentImageIndex = index);
                  },
                  itemBuilder: (context, index) {
                    return GestureDetector(
                      onTap: () => _openFullscreenViewer(imageUrls, index),
                      child: GalleryPhotoBox(
                        imageUrlOrPath: imageUrls[index],
                        fit: BoxFit.cover,
                      ),
                    );
                  },
                ),
                Positioned(
                  right: 12,
                  bottom: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.inverseSurface.withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.zoom_in_rounded,
                          size: 14,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${safeIndex + 1}/${imageUrls.length}',
                          style: AppTypography.labelSm(color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (imageUrls.length > 1) ...[
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(imageUrls.length, (index) {
              final active = index == safeIndex;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: active ? 20 : 7,
                height: 7,
                decoration: BoxDecoration(
                  color: active
                      ? AppColors.primary
                      : AppColors.outlineVariant,
                  borderRadius: BorderRadius.circular(999),
                ),
              );
            }),
          ),
        ],
      ],
    );
  }

  Widget _buildSummaryCard(GalleryWork work, GalleryViewModel vm) {
    final displayDate = formatGalleryDate(work.publishedAt ?? work.createdAt);
    final isLiking = vm.isLiking(work.id);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.45),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              DifficultyBadge(difficulty: work.difficulty),
              Text(
                displayDate,
                style: AppTypography.bodySm(color: AppColors.onSurfaceVariant),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            work.title,
            style: AppTypography.headlineLgMobile(color: AppColors.onSurface),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: const BoxDecoration(
                  color: AppColors.secondaryContainer,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.person_rounded,
                  size: 18,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      work.author.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.labelLg(color: AppColors.onSurface),
                    ),
                    Text(
                      'Pembuat Karya',
                      style: AppTypography.labelSm(
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Semantics(
                button: true,
                label: work.likedByMe
                    ? 'Batalkan suka, ${work.likesCount} suka'
                    : 'Sukai karya, ${work.likesCount} suka',
                child: OutlinedButton.icon(
                  onPressed: isLiking ? null : () => _handleLikeTap(work),
                  icon: Icon(
                    work.likedByMe
                        ? Icons.favorite_rounded
                        : Icons.favorite_border_rounded,
                    size: 18,
                    color: work.likedByMe
                        ? AppColors.error
                        : AppColors.onSurfaceVariant,
                  ),
                  label: Text(
                    '${work.likesCount}',
                    style: AppTypography.labelLg(
                      color: work.likedByMe
                          ? AppColors.error
                          : AppColors.onSurface,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(72, 48),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    backgroundColor: work.likedByMe
                        ? const Color(0xFFFFF1F2)
                        : AppColors.surfaceContainerLowest,
                    side: BorderSide(
                      color: work.likedByMe
                          ? AppColors.error.withValues(alpha: 0.5)
                          : AppColors.outlineVariant,
                    ),
                    shape: const StadiumBorder(),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAuthorActions(GalleryWork work, GalleryViewModel vm) {
    final isDeleting = vm.isDeleting(work.id);

    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: isDeleting ? null : () => _openEdit(work),
            icon: const Icon(Icons.edit_outlined, size: 18),
            label: const Text('Edit Karya'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              backgroundColor: AppColors.surfaceContainerLowest,
              side: const BorderSide(color: AppColors.primary),
              minimumSize: const Size(0, 48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: isDeleting ? null : () => _confirmAndDelete(work),
            icon: isDeleting
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.error,
                    ),
                  )
                : const Icon(Icons.delete_outline_rounded, size: 18),
            label: Text(isDeleting ? 'Menghapus...' : 'Hapus'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.error,
              backgroundColor: AppColors.surfaceContainerLowest,
              side: BorderSide(color: AppColors.error.withValues(alpha: 0.65)),
              minimumSize: const Size(0, 48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBulletSection({
    required String title,
    required IconData icon,
    required List<String> items,
    String? emptyFallback,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.45),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: AppColors.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: AppTypography.headlineSm(color: AppColors.onSurface),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (items.isEmpty && emptyFallback != null)
            Text(
              emptyFallback,
              style: AppTypography.bodySm(color: AppColors.onSurfaceVariant),
            )
          else
            ...items.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      margin: const EdgeInsets.only(top: 7, right: 10),
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        item,
                        style: AppTypography.bodyMd(color: AppColors.onSurface),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStepsSection(List<String> steps) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.45),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.format_list_numbered_rounded,
                size: 20,
                color: AppColors.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Langkah-Langkah',
                  style: AppTypography.headlineSm(color: AppColors.onSurface),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (steps.isEmpty)
            Text(
              'Langkah pembuatan belum tersedia.',
              style: AppTypography.bodySm(color: AppColors.onSurfaceVariant),
            )
          else
            ...List.generate(steps.length, (index) {
              return Padding(
                padding: EdgeInsets.only(
                  bottom: index == steps.length - 1 ? 0 : 12,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 26,
                      height: 26,
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(
                        color: AppColors.secondaryContainer,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '${index + 1}',
                        style: AppTypography.labelMd(color: AppColors.primary),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          steps[index],
                          style: AppTypography.bodyMd(
                            color: AppColors.onSurface,
                          ).copyWith(height: 1.45),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildVideoLinksSection(List<String> videoLinks) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.45),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.play_circle_outline_rounded,
                size: 20,
                color: AppColors.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Video Tutorial',
                  style: AppTypography.headlineSm(color: AppColors.onSurface),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Tautan video dibuka di aplikasi eksternal.',
            style: AppTypography.bodySm(color: AppColors.onSurfaceVariant),
          ),
          const SizedBox(height: 12),
          ...List.generate(videoLinks.length, (index) {
            final link = videoLinks[index];
            final host = VideoLinkValidator.extractDisplayHost(link);
            return Padding(
              padding: EdgeInsets.only(
                bottom: index == videoLinks.length - 1 ? 0 : 8,
              ),
              child: Material(
                color: AppColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(12),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () => _openVideoLink(link),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 52),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.ondemand_video_rounded,
                            size: 20,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Tonton Tutorial ${index + 1} ($host)',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTypography.labelLg(
                                    color: AppColors.primary,
                                  ),
                                ),
                                Text(
                                  link,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTypography.bodySm(
                                    color: AppColors.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(
                            Icons.open_in_new_rounded,
                            size: 18,
                            color: AppColors.primary,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _FullscreenGalleryPhotoViewer extends StatefulWidget {
  final List<String> imageUrls;
  final int initialIndex;

  const _FullscreenGalleryPhotoViewer({
    required this.imageUrls,
    required this.initialIndex,
  });

  @override
  State<_FullscreenGalleryPhotoViewer> createState() =>
      _FullscreenGalleryPhotoViewerState();
}

class _FullscreenGalleryPhotoViewerState
    extends State<_FullscreenGalleryPhotoViewer> {
  late final PageController _controller;
  late int _index;

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex;
    _controller = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(
          'Foto ${_index + 1} dari ${widget.imageUrls.length}',
          style: AppTypography.headlineSm(color: Colors.white),
        ),
      ),
      body: PageView.builder(
        controller: _controller,
        itemCount: widget.imageUrls.length,
        onPageChanged: (i) => setState(() => _index = i),
        itemBuilder: (context, index) {
          return Center(
            child: InteractiveViewer(
              minScale: 1.0,
              maxScale: 4.0,
              child: GalleryPhotoBox(
                imageUrlOrPath: widget.imageUrls[index],
                fit: BoxFit.contain,
              ),
            ),
          );
        },
      ),
    );
  }
}
