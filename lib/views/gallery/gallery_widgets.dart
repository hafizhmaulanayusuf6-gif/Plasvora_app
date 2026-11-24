import 'dart:io';

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../models/gallery_work.dart';

const List<String> _idMonths = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'Mei',
  'Jun',
  'Jul',
  'Agu',
  'Sep',
  'Okt',
  'Nov',
  'Des',
];

String formatGalleryDate(DateTime? date) {
  if (date == null) return 'Baru saja';
  final local = date.toLocal();
  final month = _idMonths[(local.month - 1).clamp(0, 11)];
  return '${local.day} $month ${local.year}';
}

class DifficultyBadge extends StatelessWidget {
  final GalleryDifficulty difficulty;
  final bool compact;

  const DifficultyBadge({
    super.key,
    required this.difficulty,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final (Color bg, Color fg) = switch (difficulty) {
      GalleryDifficulty.mudah => (
        const Color(0xFFD1FAE5),
        const Color(0xFF065F46),
      ),
      GalleryDifficulty.menengah => (
        const Color(0xFFFEF3C7),
        const Color(0xFF92400E),
      ),
      GalleryDifficulty.sulit => (
        const Color(0xFFFFE4E6),
        const Color(0xFF9F1239),
      ),
    };

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 3 : 4,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        difficulty.label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AppTypography.labelSm(color: fg).copyWith(
          fontSize: compact ? 10.5 : 11.5,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class ModerationStatusBadge extends StatelessWidget {
  final GalleryWorkStatus status;

  const ModerationStatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final (Color bg, Color fg, IconData icon) = switch (status) {
      GalleryWorkStatus.pending => (
        const Color(0xFFFEF3C7),
        const Color(0xFF92400E),
        Icons.schedule_rounded,
      ),
      GalleryWorkStatus.approved => (
        const Color(0xFFD1FAE5),
        const Color(0xFF065F46),
        Icons.verified_rounded,
      ),
      GalleryWorkStatus.rejected => (
        const Color(0xFFFFE4E6),
        const Color(0xFF9F1239),
        Icons.error_outline_rounded,
      ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: fg),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              status.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.labelSm(color: fg).copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Safe image renderer supporting remote URLs, local file paths, and a clean
/// placeholder when an image is absent or fails to load.
class GalleryPhotoBox extends StatelessWidget {
  final String? imageUrlOrPath;
  final BoxFit fit;
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;

  const GalleryPhotoBox({
    super.key,
    required this.imageUrlOrPath,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final content = _buildImage();
    if (borderRadius != null) {
      return ClipRRect(
        borderRadius: borderRadius!,
        child: content,
      );
    }
    return content;
  }

  Widget _buildImage() {
    final source = imageUrlOrPath?.trim() ?? '';
    if (source.isEmpty) {
      return _buildPlaceholder();
    }

    if (source.startsWith('http://') || source.startsWith('https://')) {
      return Image.network(
        source,
        width: width,
        height: height,
        fit: fit,
        headers: const {'ngrok-skip-browser-warning': 'true'},
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            width: width,
            height: height,
            color: AppColors.surfaceContainer,
            alignment: Alignment.center,
            child: const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.primary,
              ),
            ),
          );
        },
        errorBuilder: (_, _, _) => _buildPlaceholder(),
      );
    }

    final file = File(source);
    if (file.existsSync()) {
      return Image.file(
        file,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (_, _, _) => _buildPlaceholder(),
      );
    }

    return _buildPlaceholder();
  }

  Widget _buildPlaceholder() {
    return Container(
      width: width,
      height: height,
      color: AppColors.surfaceContainerHigh,
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.recycling_rounded,
            size: 32,
            color: AppColors.secondary,
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              'Foto Karya',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.labelSm(color: AppColors.secondary),
            ),
          ),
        ],
      ),
    );
  }
}
