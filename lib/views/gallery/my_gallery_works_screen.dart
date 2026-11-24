import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/simple_page_app_bar.dart';
import '../../models/gallery_work.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/gallery_viewmodel.dart';
import 'create_gallery_work_screen.dart';
import 'gallery_detail_screen.dart';
import 'gallery_widgets.dart';

class MyGalleryWorksScreen extends StatefulWidget {
  final GalleryViewModel viewModel;
  final AuthViewModel? authViewModel;

  const MyGalleryWorksScreen({
    super.key,
    required this.viewModel,
    this.authViewModel,
  });

  @override
  State<MyGalleryWorksScreen> createState() => _MyGalleryWorksScreenState();
}

class _MyGalleryWorksScreenState extends State<MyGalleryWorksScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        widget.viewModel.loadMyWorks(refresh: true);
      }
    });
  }

  Future<void> _openCreate() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CreateGalleryWorkScreen(
          viewModel: widget.viewModel,
          authViewModel: widget.authViewModel,
        ),
      ),
    );
    if (mounted) {
      await widget.viewModel.loadMyWorks(refresh: true);
    }
  }

  Future<void> _openEdit(GalleryWork work) async {
    // Load full detail if materials/steps aren't populated in list item
    GalleryWork target = work;
    if (work.materials.isEmpty || work.steps.isEmpty) {
      final loaded =
          await widget.viewModel.loadWorkDetail(work.id, forceRefresh: true);
      if (!mounted) return;
      if (loaded != null) {
        target = loaded;
      }
    }

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CreateGalleryWorkScreen(
          viewModel: widget.viewModel,
          authViewModel: widget.authViewModel,
          existingWork: target,
        ),
      ),
    );
    if (mounted) {
      await widget.viewModel.loadMyWorks(refresh: true);
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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(error ?? 'Karya berhasil dihapus.'),
        backgroundColor: error != null ? AppColors.error : AppColors.primary,
        behavior: SnackBarBehavior.floating,
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
      appBar: SimplePageAppBar(
        title: 'Karya Saya',
        actions: [
          IconButton(
            tooltip: 'Bagikan Karya Baru',
            icon: const Icon(
              Icons.add_circle_outline_rounded,
              color: AppColors.primary,
              size: 24,
            ),
            onPressed: _openCreate,
            constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: ListenableBuilder(
          listenable: widget.viewModel,
          builder: (context, _) {
            final vm = widget.viewModel;

            if (vm.isLoadingMyWorks && vm.myWorks.isEmpty) {
              return const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              );
            }

            if (vm.myWorksError != null && vm.myWorks.isEmpty) {
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
                        const Icon(
                          Icons.wifi_off_rounded,
                          size: 36,
                          color: AppColors.primary,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Gagal Memuat Karya Anda',
                          textAlign: TextAlign.center,
                          style: AppTypography.headlineSm(
                            color: AppColors.onSurface,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          vm.myWorksError!,
                          textAlign: TextAlign.center,
                          style: AppTypography.bodySm(
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => vm.loadMyWorks(refresh: true),
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

            if (vm.myWorks.isEmpty) {
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
                        Container(
                          width: 56,
                          height: 56,
                          decoration: const BoxDecoration(
                            color: AppColors.secondaryContainer,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.auto_awesome_mosaic_outlined,
                            size: 28,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          'Belum Ada Karya',
                          textAlign: TextAlign.center,
                          style: AppTypography.headlineSm(
                            color: AppColors.onSurface,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Bagikan hasil kreasi daur ulang plastik Anda agar menginspirasi pengguna lain.',
                          textAlign: TextAlign.center,
                          style: AppTypography.bodySm(
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 18),
                        ElevatedButton.icon(
                          onPressed: _openCreate,
                          icon: const Icon(Icons.add_photo_alternate_outlined),
                          label: const Text('Bagikan Karya'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            minimumSize: const Size(180, 48),
                            shape: const StadiumBorder(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }

            return RefreshIndicator(
              color: AppColors.primary,
              onRefresh: () => vm.loadMyWorks(refresh: true),
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                itemCount: vm.myWorks.length + (vm.hasMoreMyWorks ? 1 : 0),
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  if (index >= vm.myWorks.length) {
                    return Center(
                      child: OutlinedButton(
                        onPressed:
                            vm.isLoadingMoreMyWorks ? null : vm.loadMoreMyWorks,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          side: const BorderSide(color: AppColors.primary),
                          minimumSize: const Size(180, 48),
                          shape: const StadiumBorder(),
                        ),
                        child: vm.isLoadingMoreMyWorks
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.primary,
                                ),
                              )
                            : const Text('Muat Lebih Banyak'),
                      ),
                    );
                  }

                  final work = vm.myWorks[index];
                  final isDeleting = vm.isDeleting(work.id);

                  return _MyWorkCard(
                    work: work,
                    isDeleting: isDeleting,
                    onTap: () => _openDetail(work),
                    onEdit: () => _openEdit(work),
                    onDelete: () => _confirmAndDelete(work),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }
}

class _MyWorkCard extends StatelessWidget {
  final GalleryWork work;
  final bool isDeleting;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _MyWorkCard({
    required this.work,
    required this.isDeleting,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final status = work.status;

    return Material(
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
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GalleryPhotoBox(
                    imageUrlOrPath: work.effectiveCoverUrl,
                    width: 78,
                    height: 78,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (status != null) ...[
                          ModerationStatusBadge(status: status),
                          const SizedBox(height: 6),
                        ],
                        Text(
                          work.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.labelLg(
                            color: AppColors.onSurface,
                          ).copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            DifficultyBadge(
                              difficulty: work.difficulty,
                              compact: true,
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.favorite_border_rounded,
                                  size: 14,
                                  color: AppColors.textSecondary,
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
                      ],
                    ),
                  ),
                ],
              ),
              if (work.isRejected &&
                  work.rejectionReason != null &&
                  work.rejectionReason!.isNotEmpty) ...[
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF1F2),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: AppColors.error.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    'Alasan penolakan: ${work.rejectionReason!}',
                    style: AppTypography.bodySm(color: AppColors.error),
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: isDeleting ? null : onEdit,
                      icon: const Icon(Icons.edit_outlined, size: 16),
                      label: const Text('Edit'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: const BorderSide(color: AppColors.primary),
                        minimumSize: const Size(0, 44),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: isDeleting ? null : onDelete,
                      icon: isDeleting
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.error,
                              ),
                            )
                          : const Icon(Icons.delete_outline_rounded, size: 16),
                      label: Text(isDeleting ? 'Menghapus...' : 'Hapus'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.error,
                        side: BorderSide(
                          color: AppColors.error.withValues(alpha: 0.65),
                        ),
                        minimumSize: const Size(0, 44),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
