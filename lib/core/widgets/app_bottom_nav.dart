import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../../viewmodels/navigation_viewmodel.dart';

class AppBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTabSelected;

  const AppBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTabSelected,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surface.withValues(alpha: 0.88),
            border: const Border(
              top: BorderSide(color: Color(0x30BFC9C2), width: 1),
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0F20312A),
                blurRadius: 16,
                offset: Offset(0, -4),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 64),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildNavItem(
                        index: NavigationViewModel.homeIndex,
                        icon: Icons.home_outlined,
                        activeIcon: Icons.home,
                        label: 'Beranda',
                      ),
                    ),
                    Expanded(
                      child: _buildNavItem(
                        index: NavigationViewModel.analysisIndex,
                        icon: Icons.document_scanner_outlined,
                        activeIcon: Icons.document_scanner,
                        label: 'Analisis',
                      ),
                    ),
                    Expanded(
                      child: _buildNavItem(
                        index: NavigationViewModel.marketplaceIndex,
                        icon: Icons.storefront_outlined,
                        activeIcon: Icons.storefront,
                        label: 'Marketplace',
                      ),
                    ),
                    Expanded(
                      child: _buildNavItem(
                        index: NavigationViewModel.galleryIndex,
                        icon: Icons.auto_awesome_mosaic_outlined,
                        activeIcon: Icons.auto_awesome_mosaic,
                        label: 'Galeri',
                      ),
                    ),
                    Expanded(
                      child: _buildNavItem(
                        index: NavigationViewModel.profileIndex,
                        icon: Icons.person_outline,
                        activeIcon: Icons.person,
                        label: 'Profil',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required IconData activeIcon,
    required String label,
  }) {
    final bool isActive = currentIndex == index;

    return Semantics(
      button: true,
      selected: isActive,
      label: label,
      child: InkWell(
        onTap: () => onTabSelected(index),
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: isActive
                      ? AppColors.secondaryContainer
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Icon(
                  isActive ? activeIcon : icon,
                  size: 21,
                  color: isActive
                      ? AppColors.primaryContainer
                      : AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 2),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  maxLines: 1,
                  softWrap: false,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.labelSm(
                    color: isActive
                        ? AppColors.primaryContainer
                        : AppColors.textSecondary,
                  ).copyWith(
                    fontSize: 10.5,
                    fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
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
