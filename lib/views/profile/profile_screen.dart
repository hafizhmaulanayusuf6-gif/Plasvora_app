import 'package:flutter/material.dart';

import '../../core/constants/app_assets.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/phone_utils.dart';
import '../../core/widgets/simple_page_app_bar.dart';
import '../../repositories/shipping_repository.dart';
import '../../viewmodels/activity_viewmodel.dart';
import '../../viewmodels/address_viewmodel.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/gallery_viewmodel.dart';
import '../../viewmodels/marketplace_viewmodel.dart';
import '../../viewmodels/navigation_viewmodel.dart';
import '../../viewmodels/order_viewmodel.dart';
import '../activity/activity_screen.dart';
import '../address/address_list_screen.dart';
import '../auth/login_screen.dart';
import '../gallery/my_gallery_works_screen.dart';
import '../orders/order_list_screen.dart';
import 'edit_profile_screen.dart';

/// Tab root kelima (Profil) yang memusatkan identitas akun, pesanan, karya galeri,
/// aktivitas, alamat pengiriman, privasi WhatsApp, dan keluar dari akun.
class ProfileScreen extends StatefulWidget {
  final AuthViewModel? authViewModel;
  final ActivityViewModel? activityViewModel;
  final OrderViewModel? orderViewModel;
  final AddressViewModel? addressViewModel;
  final ShippingRepository? shippingRepository;
  final MarketplaceViewModel? marketplaceViewModel;
  final NavigationViewModel? navigationViewModel;
  final GalleryViewModel? galleryViewModel;

  const ProfileScreen({
    super.key,
    this.authViewModel,
    this.activityViewModel,
    this.orderViewModel,
    this.addressViewModel,
    this.shippingRepository,
    this.marketplaceViewModel,
    this.navigationViewModel,
    this.galleryViewModel,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isNavigating = false;
  bool _isLoggingOut = false;

  Future<void> _pushOnce(Widget page) async {
    if (_isNavigating || _isLoggingOut) return;
    _isNavigating = true;
    try {
      await Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => page),
      );
    } finally {
      _isNavigating = false;
    }
  }

  Future<void> _handleLogout(AuthViewModel authVm) async {
    if (_isLoggingOut || _isNavigating) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Keluar dari Akun?'),
        content: Text(
          'Sesi Anda akan diakhiri dan data transaksi serta alamat lokal akan dibersihkan.',
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
            child: const Text('Keluar'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isLoggingOut = true);
    final messenger = ScaffoldMessenger.maybeOf(context);

    // Bersihkan cache user-scoped secara defensif sebelum/bersama onSessionCleared.
    widget.addressViewModel?.clearUserData();
    widget.orderViewModel?.clearUserData();
    widget.galleryViewModel?.clearUserData();

    try {
      await authVm.logout();
      if (messenger != null && messenger.mounted) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Anda telah berhasil keluar.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoggingOut = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authVm = widget.authViewModel;

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: const SimplePageAppBar(
        title: 'Profil',
        showBack: false,
        centerTitle: true,
      ),
      body: SafeArea(
        top: false,
        child: authVm == null
            ? _buildBodyContent(context, authVm: null)
            : ListenableBuilder(
                listenable: authVm,
                builder: (context, _) =>
                    _buildBodyContent(context, authVm: authVm),
              ),
      ),
    );
  }

  Widget _buildBodyContent(
    BuildContext context, {
    required AuthViewModel? authVm,
  }) {
    final isAuthenticated = authVm?.isAuthenticated ?? false;
    final user = authVm?.currentUser;

    if (authVm != null && !isAuthenticated) {
      return Center(
        child: SingleChildScrollView(
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
                  width: 64,
                  height: 64,
                  decoration: const BoxDecoration(
                    color: AppColors.secondaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.person_outline,
                    size: 32,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Masuk ke Akun Plasvora',
                  style: AppTypography.headlineSm(color: AppColors.onSurface),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Kelola pesanan, aktivitas daur ulang, dan alamat pengiriman Anda dari satu tempat.',
                  style: AppTypography.bodySm(
                    color: AppColors.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: () => _pushOnce(
                      LoginScreen(authViewModel: authVm),
                    ),
                    icon: const Icon(Icons.login, size: 18),
                    label: Text(
                      'Masuk',
                      style: AppTypography.labelLg(
                        color: Colors.white,
                      ).copyWith(fontWeight: FontWeight.w700),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryContainer,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(0, 48),
                      shape: const StadiumBorder(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final formattedPhone = PhoneUtils.formatForDisplay(user?.phone);
    final hasPhone = formattedPhone.isNotEmpty;
    final whatsappLabel = (user?.whatsappPublic ?? false) ? 'Publik' : 'Privat';

    final accountItems = <Widget>[
      if (authVm != null)
        _ProfileMenuTile(
          icon: Icons.manage_accounts_outlined,
          label: 'Edit Profil',
          onTap: () => _pushOnce(EditProfileScreen(authViewModel: authVm)),
        ),
      if (widget.orderViewModel != null)
        _ProfileMenuTile(
          icon: Icons.receipt_long_outlined,
          label: 'Pesanan Saya',
          onTap: () => _pushOnce(
            OrderListScreen(
              orderViewModel: widget.orderViewModel!,
              authViewModel: authVm,
            ),
          ),
        ),
      if (widget.galleryViewModel != null)
        _ProfileMenuTile(
          icon: Icons.auto_awesome_mosaic_outlined,
          label: 'Karya Saya',
          onTap: () => _pushOnce(
            MyGalleryWorksScreen(
              viewModel: widget.galleryViewModel!,
              authViewModel: authVm,
            ),
          ),
        ),
      _ProfileMenuTile(
        icon: Icons.history_outlined,
        label: 'Aktivitas',
        onTap: () => _pushOnce(
          ActivityScreen(
            viewModel: widget.activityViewModel,
            marketplaceViewModel: widget.marketplaceViewModel,
            navigationViewModel: widget.navigationViewModel,
            shippingRepository: widget.shippingRepository,
            orderViewModel: widget.orderViewModel,
            authViewModel: authVm,
            galleryViewModel: widget.galleryViewModel,
          ),
        ),
      ),
      if (widget.addressViewModel != null && widget.shippingRepository != null)
        _ProfileMenuTile(
          icon: Icons.location_on_outlined,
          label: 'Kelola Alamat Pengiriman',
          onTap: () => _pushOnce(
            AddressListScreen(
              addressViewModel: widget.addressViewModel!,
              shippingRepository: widget.shippingRepository!,
            ),
          ),
        ),
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. User Identity Card
          Material(
            color: AppColors.surfaceContainerLowest,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: AppColors.outlineVariant.withValues(alpha: 0.45),
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: authVm != null
                  ? () => _pushOnce(EditProfileScreen(authViewModel: authVm))
                  : null,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: Image.asset(
                        AppAssets.avatar,
                        width: 56,
                        height: 56,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => Container(
                          width: 56,
                          height: 56,
                          color: AppColors.secondaryContainer,
                          child: const Icon(
                            Icons.person,
                            size: 28,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user?.name ?? 'Pengguna Plasvora',
                            style: AppTypography.headlineSm(
                              color: AppColors.onSurface,
                            ).copyWith(fontWeight: FontWeight.w700),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            user?.email ?? 'Akun Aktif',
                            style: AppTypography.bodySm(
                              color: AppColors.onSurfaceVariant,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (hasPhone) ...[
                            const SizedBox(height: 4),
                            Text(
                              formattedPhone,
                              style: AppTypography.labelSm(
                                color: AppColors.secondary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (authVm != null) ...[
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.chevron_right,
                        size: 20,
                        color: AppColors.outline,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // 2. Account Section
          _ProfileSection(
            title: 'Akun',
            children: accountItems,
          ),

          if (authVm != null) ...[
            const SizedBox(height: 24),

            // 3. Privacy & Settings Section
            _ProfileSection(
              title: 'Privasi & Pengaturan',
              children: [
                _ProfileMenuTile(
                  icon: Icons.chat_outlined,
                  label: 'Visibilitas WhatsApp',
                  trailingText: whatsappLabel,
                  onTap: () =>
                      _pushOnce(EditProfileScreen(authViewModel: authVm)),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // 4. Logout Action
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton.icon(
                onPressed: _isLoggingOut ? null : () => _handleLogout(authVm),
                icon: _isLoggingOut
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.error,
                        ),
                      )
                    : const Icon(Icons.logout, size: 20, color: AppColors.error),
                label: Text(
                  _isLoggingOut ? 'Keluar...' : 'Keluar dari Akun',
                  style: AppTypography.labelLg(
                    color: AppColors.error,
                  ).copyWith(fontWeight: FontWeight.w600),
                ),
                style: OutlinedButton.styleFrom(
                  backgroundColor: AppColors.surfaceContainerLowest,
                  foregroundColor: AppColors.error,
                  side: BorderSide(
                    color: AppColors.error.withValues(alpha: 0.6),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ProfileSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _ProfileSection({
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) return const SizedBox.shrink();

    final separated = <Widget>[];
    for (var i = 0; i < children.length; i++) {
      separated.add(children[i]);
      if (i < children.length - 1) {
        separated.add(
          Divider(
            height: 1,
            indent: 52,
            endIndent: 16,
            color: AppColors.outlineVariant.withValues(alpha: 0.4),
          ),
        );
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            title,
            style: AppTypography.labelMd(
              color: AppColors.onSurfaceVariant,
            ),
          ),
        ),
        Material(
          color: AppColors.surfaceContainerLowest,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: AppColors.outlineVariant.withValues(alpha: 0.45),
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: separated,
          ),
        ),
      ],
    );
  }
}

class _ProfileMenuTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? trailingText;
  final VoidCallback onTap;

  const _ProfileMenuTile({
    required this.icon,
    required this.label,
    this.trailingText,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 52),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Icon(icon, size: 22, color: AppColors.onSurface),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  label,
                  style: AppTypography.bodyMd(
                    color: AppColors.onSurface,
                  ).copyWith(fontWeight: FontWeight.w500),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (trailingText != null) ...[
                const SizedBox(width: 8),
                Text(
                  trailingText!,
                  style: AppTypography.bodySm(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ],
              const SizedBox(width: 6),
              const Icon(
                Icons.arrow_forward,
                size: 18,
                color: AppColors.outline,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
