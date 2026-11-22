import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// AppBar ringan dan fokus untuk halaman internal (Checkout, Pesanan, Detail, Aktivitas, Alamat, Edit Profil)
/// serta heading bersih untuk tab root Profil.
class SimplePageAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool showBack;
  final VoidCallback? onBack;
  final List<Widget>? actions;
  final bool centerTitle;

  const SimplePageAppBar({
    super.key,
    required this.title,
    this.showBack = true,
    this.onBack,
    this.actions,
    this.centerTitle = false,
  });

  @override
  Size get preferredSize => const Size.fromHeight(56);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
          bottom: BorderSide(
            color: AppColors.outlineVariant.withValues(alpha: 0.45),
            width: 0.8,
          ),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: 56,
          child: Padding(
            padding: EdgeInsets.only(
              left: showBack ? 8 : 20,
              right: (actions != null && actions!.isNotEmpty) ? 8 : 20,
            ),
            child: Row(
              children: [
                if (showBack)
                  IconButton(
                    tooltip: 'Kembali',
                    icon: const Icon(
                      Icons.arrow_back,
                      color: AppColors.onSurface,
                      size: 22,
                    ),
                    onPressed: onBack ?? () => Navigator.of(context).maybePop(),
                    constraints: const BoxConstraints(
                      minWidth: 48,
                      minHeight: 48,
                    ),
                  ),
                if (showBack) const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    title,
                    textAlign: centerTitle ? TextAlign.center : TextAlign.start,
                    style: AppTypography.headlineSm(
                      color: AppColors.onSurface,
                    ).copyWith(fontWeight: FontWeight.w700),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (actions != null && actions!.isNotEmpty) ...actions!,
              ],
            ),
          ),
        ),
      ),
    );
  }
}
