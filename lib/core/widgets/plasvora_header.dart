import 'package:flutter/material.dart';

import '../constants/app_assets.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

class PlasvoraHeader extends StatelessWidget implements PreferredSizeWidget {
  final String? customTitle;
  final bool showBack;
  final VoidCallback? onBack;
  final VoidCallback? onAvatarTap;

  const PlasvoraHeader({
    super.key,
    this.customTitle,
    this.showBack = false,
    this.onBack,
    this.onAvatarTap,
  });

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.88),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Row(
            children: [
              if (showBack) ...[
                IconButton(
                  icon: const Icon(
                    Icons.arrow_back,
                    color: AppColors.onSurface,
                  ),
                  onPressed: onBack ?? () => Navigator.of(context).pop(),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 40,
                    minHeight: 40,
                  ),
                ),
                const SizedBox(width: 4),
              ],
              Image.asset(
                AppAssets.logo,
                height: 32,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) =>
                    const Icon(Icons.eco, color: AppColors.primary, size: 28),
              ),
              const SizedBox(width: 10),
              if (customTitle != null) ...[
                Expanded(
                  child: Text(
                    customTitle!,
                    style: AppTypography.headlineSm(color: AppColors.onSurface),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ] else ...[
                Text(
                  'PLASVORA',
                  style: AppTypography.headlineSm(
                    color: AppColors.primary,
                  ).copyWith(fontWeight: FontWeight.w800, letterSpacing: -0.5),
                ),
                const Spacer(),
              ],
              // Notifications action
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Material(
                    color: Colors.transparent,
                    shape: const CircleBorder(),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Belum ada notifikasi baru.'),
                            behavior: SnackBarBehavior.floating,
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                      child: const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Icon(
                          Icons.notifications_outlined,
                          color: AppColors.secondary,
                          size: 24,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: AppColors.primaryContainer,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.surface,
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 6),
              // User avatar
              GestureDetector(
                onTap: onAvatarTap,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: Image.asset(
                    AppAssets.avatar,
                    width: 34,
                    height: 34,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      width: 34,
                      height: 34,
                      color: AppColors.secondaryContainer,
                      child: const Icon(
                        Icons.person,
                        size: 20,
                        color: AppColors.primary,
                      ),
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
}
