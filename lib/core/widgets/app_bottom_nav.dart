import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

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
            child: SizedBox(
              height: 64,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildNavItem(
                    index: 0,
                    icon: Icons.home_outlined,
                    activeIcon: Icons.home,
                    label: 'Beranda',
                  ),
                  _buildNavItem(
                    index: 1,
                    icon: Icons.document_scanner_outlined,
                    activeIcon: Icons.document_scanner,
                    label: 'Analisis',
                  ),
                  _buildNavItem(
                    index: 2,
                    icon: Icons.storefront_outlined,
                    activeIcon: Icons.storefront,
                    label: 'Marketplace',
                  ),
                  _buildNavItem(
                    index: 3,
                    icon: Icons.schedule_outlined,
                    activeIcon: Icons.schedule,
                    label: 'Aktivitas',
                  ),
                ],
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

    return InkWell(
      onTap: () => onTabSelected(index),
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: isActive
                    ? AppColors.secondaryContainer
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Icon(
                isActive ? activeIcon : icon,
                size: 22,
                color: isActive
                    ? AppColors.primaryContainer
                    : AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style:
                  AppTypography.labelSm(
                    color: isActive
                        ? AppColors.primaryContainer
                        : AppColors.textSecondary,
                  ).copyWith(
                    fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
