import 'package:flutter/material.dart';

import '../../core/constants/app_assets.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/phone_utils.dart';
import '../../core/widgets/simple_page_app_bar.dart';
import '../../viewmodels/auth_viewmodel.dart';

/// Halaman Edit Profil & Privasi WhatsApp (dimigrasikan dari modal profil lama).
class EditProfileScreen extends StatefulWidget {
  final AuthViewModel authViewModel;

  const EditProfileScreen({
    super.key,
    required this.authViewModel,
  });

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final GlobalKey<FormState> _phoneFormKey = GlobalKey<FormState>();
  late final TextEditingController _phoneController;
  late bool _whatsappPublic;
  bool _isTogglingVisibility = false;
  String? _localError;
  String? _localSuccess;

  @override
  void initState() {
    super.initState();
    _phoneController = TextEditingController(
      text: widget.authViewModel.currentUser?.phone ?? '',
    );
    _whatsappPublic = widget.authViewModel.currentUser?.whatsappPublic ?? false;
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _handleSavePhone() async {
    if (widget.authViewModel.isUpdatingProfile) return;
    if (!_phoneFormKey.currentState!.validate()) return;

    setState(() {
      _localError = null;
      _localSuccess = null;
    });

    final ok = await widget.authViewModel.updateProfile(
      phone: _phoneController.text.trim(),
    );
    if (!mounted) return;

    if (ok) {
      final refreshed = widget.authViewModel.currentUser;
      setState(() {
        _whatsappPublic = refreshed?.whatsappPublic ?? false;
        _localSuccess = refreshed?.phone != null
            ? 'Nomor telepon berhasil disimpan.'
            : 'Nomor telepon dihapus dan visibilitas WhatsApp dinonaktifkan.';
      });
    } else {
      setState(() {
        _localError =
            widget.authViewModel.errorMessage ??
            'Gagal memperbarui nomor telepon.';
      });
    }
  }

  Future<void> _handleToggleWhatsApp(bool newValue) async {
    if (_isTogglingVisibility || widget.authViewModel.isUpdatingProfile) return;

    final previousValue = _whatsappPublic;
    setState(() {
      _whatsappPublic = newValue;
      _isTogglingVisibility = true;
      _localError = null;
      _localSuccess = null;
    });

    final ok = await widget.authViewModel.updateProfile(
      whatsappPublic: newValue,
    );
    if (!mounted) return;

    setState(() {
      _isTogglingVisibility = false;
      if (ok) {
        _whatsappPublic =
            widget.authViewModel.currentUser?.whatsappPublic ?? newValue;
        _localSuccess = _whatsappPublic
            ? 'Nomor WhatsApp kini ditampilkan pada detail material.'
            : 'Nomor WhatsApp disembunyikan dari detail material.';
      } else {
        _whatsappPublic = previousValue;
        _localError =
            widget.authViewModel.errorMessage ??
            'Gagal menyimpan pengaturan privasi WhatsApp.';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: const SimplePageAppBar(title: 'Edit Profil'),
      body: SafeArea(
        top: false,
        child: ListenableBuilder(
          listenable: widget.authViewModel,
          builder: (context, _) {
            final user = widget.authViewModel.currentUser;
            final isSaving = widget.authViewModel.isUpdatingProfile;
            final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
            final hasSavedValidPhone =
                PhoneUtils.normalizeIndonesianPhone(user?.phone) != null;
            final canToggleSwitch =
                !isSaving &&
                !_isTogglingVisibility &&
                (hasSavedValidPhone || _whatsappPublic);

            return SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(20, 16, 20, 24 + bottomInset),
              child: Form(
                key: _phoneFormKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Identitas akun
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerLowest,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppColors.outlineVariant.withValues(alpha: 0.45),
                        ),
                      ),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(999),
                            child: Image.asset(
                              AppAssets.avatar,
                              width: 52,
                              height: 52,
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) => Container(
                                width: 52,
                                height: 52,
                                color: AppColors.secondaryContainer,
                                child: const Icon(
                                  Icons.person,
                                  size: 26,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  user?.name ?? 'Pengguna Plasvora',
                                  style: AppTypography.headlineSm(
                                    color: AppColors.onSurface,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  user?.email ?? '',
                                  style: AppTypography.bodySm(
                                    color: AppColors.onSurfaceVariant,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Kontak WhatsApp / Telepon
                    Text(
                      'Kontak Akun',
                      style: AppTypography.labelMd(
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
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
                              Flexible(
                                child: Text(
                                  'Nomor WhatsApp / Telepon',
                                  style: AppTypography.labelLg(
                                    color: AppColors.onSurface,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '(Opsional)',
                                style: AppTypography.labelSm(
                                  color: AppColors.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            textInputAction: TextInputAction.done,
                            decoration: InputDecoration(
                              hintText: 'Contoh: 081234567890',
                              prefixIcon: const Icon(
                                Icons.phone_outlined,
                                size: 20,
                                color: AppColors.onSurfaceVariant,
                              ),
                              filled: true,
                              fillColor: AppColors.surface,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 14,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: AppColors.outlineVariant,
                                  width: 0.8,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: AppColors.outlineVariant,
                                  width: 0.8,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: AppColors.primaryContainer,
                                  width: 1.5,
                                ),
                              ),
                            ),
                            validator: PhoneUtils.validateOptionalIndonesianPhone,
                            onChanged: (_) {
                              if (_localError != null || _localSuccess != null) {
                                setState(() {
                                  _localError = null;
                                  _localSuccess = null;
                                });
                              }
                            },
                          ),
                          const SizedBox(height: 8),
                          Text(
                            hasSavedValidPhone
                                ? 'Tersimpan: ${PhoneUtils.formatForDisplay(user!.phone)}'
                                : 'Tambahkan nomor telepon untuk mengaktifkan kontak WhatsApp.',
                            style: AppTypography.labelSm(
                              color: AppColors.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: ElevatedButton.icon(
                              icon: (isSaving && !_isTogglingVisibility)
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Icon(Icons.save_outlined, size: 18),
                              label: Text(
                                (isSaving && !_isTogglingVisibility)
                                    ? 'Menyimpan...'
                                    : 'Simpan Nomor',
                                style: AppTypography.labelMd(
                                  color: Colors.white,
                                ).copyWith(fontWeight: FontWeight.w600),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primaryContainer,
                                foregroundColor: Colors.white,
                                minimumSize: const Size(0, 48),
                                shape: const StadiumBorder(),
                              ),
                              onPressed: isSaving ? null : _handleSavePhone,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Privasi WhatsApp
                    Text(
                      'Privasi Kontak',
                      style: AppTypography.labelMd(
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
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
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SwitchListTile.adaptive(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            activeTrackColor: AppColors.primaryContainer,
                            title: Text(
                              'Tampilkan nomor WhatsApp saya pada detail material',
                              style: AppTypography.labelLg(
                                color: AppColors.onSurface,
                              ),
                            ),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                'Jika diaktifkan, pengguna lain dapat melihat nomor WhatsApp Anda dan menghubungi Anda melalui halaman detail material.',
                                style: AppTypography.bodySm(
                                  color: AppColors.onSurfaceVariant,
                                ),
                              ),
                            ),
                            value: _whatsappPublic,
                            onChanged:
                                !canToggleSwitch ? null : _handleToggleWhatsApp,
                          ),
                          if (!hasSavedValidPhone)
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(
                                    Icons.info_outline,
                                    size: 16,
                                    color: AppColors.onSurfaceVariant,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Simpan nomor telepon yang valid terlebih dahulu untuk mengaktifkan visibilitas WhatsApp.',
                                      style: AppTypography.labelSm(
                                        color: AppColors.onSurfaceVariant,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          if (_isTogglingVisibility)
                            const Padding(
                              padding: EdgeInsets.fromLTRB(16, 0, 16, 12),
                              child: LinearProgressIndicator(
                                minHeight: 2,
                                color: AppColors.primaryContainer,
                              ),
                            ),
                        ],
                      ),
                    ),

                    if (_localError != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.errorContainer,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _localError!,
                          style: AppTypography.bodySm(
                            color: AppColors.onErrorContainer,
                          ),
                        ),
                      ),
                    ],
                    if (_localSuccess != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.secondaryContainer.withValues(
                            alpha: 0.45,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _localSuccess!,
                          style: AppTypography.bodySm(
                            color: AppColors.primary,
                          ).copyWith(fontWeight: FontWeight.w600),
                        ),
                      ),
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
}
