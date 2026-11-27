import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../viewmodels/navigation_viewmodel.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

class AppBottomNav extends StatelessWidget {
  static const Color _analysisAccentColor = Color(0xFF0D3B2E);
  static const Key analysisBadgeKey = Key('bottom_nav_analysis_badge');
  static const double analysisBadgeDiameter = 56.0;
  static const double _sharedIconAreaHeight = 56.0;
  static const double _sharedLabelAreaHeight = 16.0;
  static const Duration _tintDuration = Duration(milliseconds: 200);
  static const Duration _pillDuration = Duration(milliseconds: 220);
  static const Duration _pressDuration = Duration(milliseconds: 110);

  static Key slotKey(int index) => Key('bottom_nav_slot_$index');
  static Key iconKey(int index) => Key('bottom_nav_icon_$index');

  final int currentIndex;
  final ValueChanged<int> onTabSelected;

  const AppBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTabSelected,
  });

  void _handleSelect(int index) {
    if (currentIndex != index) {
      HapticFeedback.selectionClick();
    }
    onTabSelected(index);
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final tintDuration = reduceMotion ? Duration.zero : _tintDuration;
    final pillDuration = reduceMotion ? Duration.zero : _pillDuration;
    final pressDuration = reduceMotion ? Duration.zero : _pressDuration;

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
            child: LayoutBuilder(
              builder: (context, constraints) {
                final slotWidth = constraints.maxWidth / 5;
                final pillHorizontalPadding = slotWidth < 74 ? 12.0 : 14.0;

                return Padding(
                  padding: const EdgeInsets.only(top: 4, bottom: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        flex: 1,
                        child: _NormalNavItem(
                          key: slotKey(NavigationViewModel.homeIndex),
                          iconKey: iconKey(NavigationViewModel.homeIndex),
                          icon: Icons.home_outlined,
                          activeIcon: Icons.home,
                          label: 'Beranda',
                          isActive:
                              currentIndex == NavigationViewModel.homeIndex,
                          pillHorizontalPadding: pillHorizontalPadding,
                          tintDuration: tintDuration,
                          pillDuration: pillDuration,
                          pressDuration: pressDuration,
                          reduceMotion: reduceMotion,
                          onTap: () =>
                              _handleSelect(NavigationViewModel.homeIndex),
                        ),
                      ),
                      Expanded(
                        flex: 1,
                        child: _NormalNavItem(
                          key: slotKey(NavigationViewModel.galleryIndex),
                          iconKey: iconKey(NavigationViewModel.galleryIndex),
                          icon: Icons.auto_awesome_mosaic_outlined,
                          activeIcon: Icons.auto_awesome_mosaic,
                          label: 'Galeri',
                          isActive:
                              currentIndex == NavigationViewModel.galleryIndex,
                          pillHorizontalPadding: pillHorizontalPadding,
                          tintDuration: tintDuration,
                          pillDuration: pillDuration,
                          pressDuration: pressDuration,
                          reduceMotion: reduceMotion,
                          onTap: () =>
                              _handleSelect(NavigationViewModel.galleryIndex),
                        ),
                      ),
                      Expanded(
                        flex: 1,
                        child: _AnalysisNavItem(
                          key: slotKey(NavigationViewModel.analysisIndex),
                          iconKey: iconKey(NavigationViewModel.analysisIndex),
                          isActive:
                              currentIndex == NavigationViewModel.analysisIndex,
                          tintDuration: tintDuration,
                          pillDuration: pillDuration,
                          pressDuration: pressDuration,
                          reduceMotion: reduceMotion,
                          onTap: () =>
                              _handleSelect(NavigationViewModel.analysisIndex),
                        ),
                      ),
                      Expanded(
                        flex: 1,
                        child: _NormalNavItem(
                          key: slotKey(NavigationViewModel.marketplaceIndex),
                          iconKey:
                              iconKey(NavigationViewModel.marketplaceIndex),
                          icon: Icons.storefront_outlined,
                          activeIcon: Icons.storefront,
                          label: 'Marketplace',
                          isActive: currentIndex ==
                              NavigationViewModel.marketplaceIndex,
                          pillHorizontalPadding: pillHorizontalPadding,
                          tintDuration: tintDuration,
                          pillDuration: pillDuration,
                          pressDuration: pressDuration,
                          reduceMotion: reduceMotion,
                          onTap: () => _handleSelect(
                            NavigationViewModel.marketplaceIndex,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 1,
                        child: _NormalNavItem(
                          key: slotKey(NavigationViewModel.profileIndex),
                          iconKey: iconKey(NavigationViewModel.profileIndex),
                          icon: Icons.person_outline,
                          activeIcon: Icons.person,
                          label: 'Profil',
                          isActive:
                              currentIndex == NavigationViewModel.profileIndex,
                          pillHorizontalPadding: pillHorizontalPadding,
                          tintDuration: tintDuration,
                          pillDuration: pillDuration,
                          pressDuration: pressDuration,
                          reduceMotion: reduceMotion,
                          onTap: () =>
                              _handleSelect(NavigationViewModel.profileIndex),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _NormalNavItem extends StatefulWidget {
  final Key iconKey;
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isActive;
  final double pillHorizontalPadding;
  final Duration tintDuration;
  final Duration pillDuration;
  final Duration pressDuration;
  final bool reduceMotion;
  final VoidCallback onTap;

  const _NormalNavItem({
    super.key,
    required this.iconKey,
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isActive,
    required this.pillHorizontalPadding,
    required this.tintDuration,
    required this.pillDuration,
    required this.pressDuration,
    required this.reduceMotion,
    required this.onTap,
  });

  @override
  State<_NormalNavItem> createState() => _NormalNavItemState();
}

class _NormalNavItemState extends State<_NormalNavItem> {
  bool _isPressed = false;

  void _setPressed(bool value) {
    if (_isPressed != value && mounted) {
      setState(() => _isPressed = value);
    }
  }

  @override
  Widget build(BuildContext context) {
    final targetColor = widget.isActive
        ? AppColors.primaryContainer
        : AppColors.textSecondary;
    final targetScale = widget.reduceMotion
        ? 1.0
        : (_isPressed ? 0.94 : (widget.isActive ? 1.06 : 1.0));

    return Semantics(
      button: true,
      selected: widget.isActive,
      label: widget.label,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: widget.onTap,
          onHighlightChanged: _setPressed,
          borderRadius: BorderRadius.circular(14),
          splashColor: AppColors.secondaryContainer.withValues(alpha: 0.45),
          highlightColor: AppColors.secondaryContainer.withValues(alpha: 0.2),
          child: ExcludeSemantics(
            child: SizedBox(
              width: double.infinity,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(
                      height: AppBottomNav._sharedIconAreaHeight,
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: AnimatedContainer(
                            duration: widget.pillDuration,
                            curve: Curves.easeOutCubic,
                            padding: EdgeInsets.symmetric(
                              horizontal: widget.isActive
                                  ? widget.pillHorizontalPadding
                                  : 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: widget.isActive
                                  ? AppColors.secondaryContainer
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: AnimatedScale(
                              scale: targetScale,
                              duration: _isPressed
                                  ? widget.pressDuration
                                  : widget.tintDuration,
                              curve: Curves.easeOutCubic,
                              child: TweenAnimationBuilder<Color?>(
                                tween: ColorTween(end: targetColor),
                                duration: widget.tintDuration,
                                curve: Curves.easeOutCubic,
                                builder: (context, color, _) => Icon(
                                  widget.isActive
                                      ? widget.activeIcon
                                      : widget.icon,
                                  key: widget.iconKey,
                                  size: 21,
                                  color: color ?? targetColor,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 3),
                    SizedBox(
                      height: AppBottomNav._sharedLabelAreaHeight,
                      child: Center(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: AnimatedDefaultTextStyle(
                            duration: widget.tintDuration,
                            curve: Curves.easeOutCubic,
                            style: AppTypography.labelSm(
                              color: targetColor,
                            ).copyWith(
                              fontSize: 10.5,
                              fontWeight: widget.isActive
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                            ),
                            child: Text(
                              widget.label,
                              maxLines: 1,
                              softWrap: false,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
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
}

class _AnalysisNavItem extends StatefulWidget {
  final Key iconKey;
  final bool isActive;
  final Duration tintDuration;
  final Duration pillDuration;
  final Duration pressDuration;
  final bool reduceMotion;
  final VoidCallback onTap;

  const _AnalysisNavItem({
    super.key,
    required this.iconKey,
    required this.isActive,
    required this.tintDuration,
    required this.pillDuration,
    required this.pressDuration,
    required this.reduceMotion,
    required this.onTap,
  });

  @override
  State<_AnalysisNavItem> createState() => _AnalysisNavItemState();
}

class _AnalysisNavItemState extends State<_AnalysisNavItem> {
  bool _isPressed = false;

  void _setPressed(bool value) {
    if (_isPressed != value && mounted) {
      setState(() => _isPressed = value);
    }
  }

  @override
  Widget build(BuildContext context) {
    final targetScale = widget.reduceMotion
        ? 1.0
        : (_isPressed ? 0.97 : (widget.isActive ? 1.04 : 1.0));

    return Semantics(
      button: true,
      selected: widget.isActive,
      label: 'Analisis',
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: widget.onTap,
          onHighlightChanged: _setPressed,
          borderRadius: BorderRadius.circular(18),
          splashColor: AppColors.secondaryContainer.withValues(alpha: 0.45),
          highlightColor: AppColors.secondaryContainer.withValues(alpha: 0.2),
          child: ExcludeSemantics(
            child: SizedBox(
              width: double.infinity,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(
                      height: AppBottomNav._sharedIconAreaHeight,
                      child: Center(
                        child: AnimatedScale(
                          scale: targetScale,
                          duration: _isPressed
                              ? widget.pressDuration
                              : widget.tintDuration,
                          curve: Curves.easeOutCubic,
                          child: AnimatedContainer(
                            key: AppBottomNav.analysisBadgeKey,
                            duration: widget.pillDuration,
                            curve: Curves.easeOutCubic,
                            width: AppBottomNav.analysisBadgeDiameter,
                            height: AppBottomNav.analysisBadgeDiameter,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: AppBottomNav._analysisAccentColor,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: widget.isActive
                                    ? AppColors.primaryFixed
                                    : Colors.transparent,
                                width: 2.0,
                              ),
                              boxShadow: widget.isActive
                                  ? const [
                                      BoxShadow(
                                        color: Color(0x330D3B2E),
                                        blurRadius: 10,
                                        offset: Offset(0, 3),
                                      ),
                                    ]
                                  : const [
                                      BoxShadow(
                                        color: Color(0x240D3B2E),
                                        blurRadius: 7,
                                        offset: Offset(0, 2),
                                      ),
                                    ],
                            ),
                            child: AnimatedSwitcher(
                              key: widget.iconKey,
                              duration: widget.tintDuration,
                              switchInCurve: Curves.easeOutCubic,
                              switchOutCurve: Curves.easeInCubic,
                              child: Icon(
                                widget.isActive
                                    ? Icons.document_scanner
                                    : Icons.document_scanner_outlined,
                                key: ValueKey<bool>(widget.isActive),
                                size: 26,
                                color: AppColors.onPrimary,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 3),
                    SizedBox(
                      height: AppBottomNav._sharedLabelAreaHeight,
                      child: Center(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: AnimatedDefaultTextStyle(
                            duration: widget.tintDuration,
                            curve: Curves.easeOutCubic,
                            style: AppTypography.labelSm(
                              color: widget.isActive
                                  ? AppBottomNav._analysisAccentColor
                                  : AppColors.primaryContainer,
                            ).copyWith(
                              fontSize: 10.5,
                              fontWeight: widget.isActive
                                  ? FontWeight.w700
                                  : FontWeight.w600,
                            ),
                            child: const Text(
                              'Analisis',
                              maxLines: 1,
                              softWrap: false,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
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
}
