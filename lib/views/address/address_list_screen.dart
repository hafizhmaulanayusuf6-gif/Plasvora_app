import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/display_formatters.dart';
import '../../core/utils/phone_utils.dart';
import '../../core/widgets/simple_page_app_bar.dart';
import '../../models/user_address.dart';
import '../../repositories/shipping_repository.dart';
import '../../viewmodels/address_viewmodel.dart';
import 'address_form_screen.dart';

/// Buku alamat pengiriman pembeli.
/// Dapat dibuka dari Profil Akun (kelola alamat) atau dari Detail Material (pilih alamat tujuan).
class AddressListScreen extends StatefulWidget {
  final AddressViewModel addressViewModel;
  final ShippingRepository shippingRepository;
  final bool selectionMode;

  const AddressListScreen({
    super.key,
    required this.addressViewModel,
    required this.shippingRepository,
    this.selectionMode = false,
  });

  @override
  State<AddressListScreen> createState() => _AddressListScreenState();
}

class _AddressListScreenState extends State<AddressListScreen> {
  @override
  void initState() {
    super.initState();
    if (widget.addressViewModel.addresses.isEmpty &&
        !widget.addressViewModel.isLoading) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          widget.addressViewModel.loadAddresses();
        }
      });
    }
  }

  Future<void> _openForm({UserAddress? existing}) async {
    await Navigator.of(context).push<UserAddress?>(
      MaterialPageRoute(
        builder: (_) => AddressFormScreen(
          addressViewModel: widget.addressViewModel,
          shippingRepository: widget.shippingRepository,
          existingAddress: existing,
        ),
      ),
    );
  }

  Future<void> _setAsDefault(UserAddress address) async {
    if (widget.addressViewModel.isSaving) return;
    final updated = await widget.addressViewModel.updateAddress(
      id: address.id,
      isDefault: true,
    );
    if (!mounted) return;
    if (updated != null) {
      final warning = widget.addressViewModel.errorMessage;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            warning ?? 'Alamat "${address.label}" dijadikan alamat utama.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.addressViewModel.errorMessage ??
                'Gagal mengubah alamat utama.',
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _confirmDelete(UserAddress address) async {
    if (widget.addressViewModel.isSaving) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Hapus Alamat?'),
        content: Text(
          'Alamat "${address.label}" (${address.recipientName}) akan dihapus dari daftar alamat pengiriman Anda.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final deleted = await widget.addressViewModel.deleteAddress(address.id);
    if (!mounted) return;

    if (deleted) {
      final warning = widget.addressViewModel.errorMessage;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(warning ?? 'Alamat pengiriman berhasil dihapus.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.addressViewModel.errorMessage ??
                'Gagal menghapus alamat pengiriman.',
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void _selectForEstimator(UserAddress address) {
    widget.addressViewModel.selectAddress(address.id);
    Navigator.of(context).pop(address);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: SimplePageAppBar(
        title: widget.selectionMode
            ? 'Pilih Alamat Tujuan'
            : 'Alamat Pengiriman',
        onBack: () => Navigator.of(context).pop(),
      ),
      body: SafeArea(
        top: false,
        child: ListenableBuilder(
          listenable: widget.addressViewModel,
          builder: (context, _) {
            final vm = widget.addressViewModel;

            if (vm.isLoading && vm.addresses.isEmpty) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(
                      color: AppColors.primaryContainer,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Memuat daftar alamat...',
                      style: AppTypography.bodyMd(
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              );
            }

            if (vm.errorMessage != null && vm.addresses.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 44,
                        color: AppColors.error,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Gagal Memuat Alamat',
                        style: AppTypography.headlineSm(
                          color: AppColors.onSurface,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        vm.errorMessage!,
                        textAlign: TextAlign.center,
                        style: AppTypography.bodyMd(
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 18),
                      SizedBox(
                        height: 48,
                        child: ElevatedButton.icon(
                          onPressed: vm.loadAddresses,
                          icon: const Icon(Icons.refresh, size: 18),
                          label: const Text('Coba Lagi'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryContainer,
                            foregroundColor: Colors.white,
                            shape: const StadiumBorder(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            if (vm.addresses.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 68,
                        height: 68,
                        decoration: const BoxDecoration(
                          color: AppColors.secondaryContainer,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.location_on_outlined,
                          size: 34,
                          color: AppColors.primaryContainer,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Belum Ada Alamat Pengiriman',
                        textAlign: TextAlign.center,
                        style: AppTypography.headlineSm(
                          color: AppColors.onSurface,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Simpan alamat tujuan agar Anda dapat mengecek estimasi ongkos kirim dengan cepat.',
                        textAlign: TextAlign.center,
                        style: AppTypography.bodyMd(
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton.icon(
                          onPressed: () => _openForm(),
                          icon: const Icon(Icons.add_location_alt_outlined),
                          label: Text(
                            'Tambah Alamat',
                            style: AppTypography.labelLg(
                              color: Colors.white,
                            ).copyWith(fontWeight: FontWeight.w700),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryContainer,
                            foregroundColor: Colors.white,
                            shape: const StadiumBorder(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            return Column(
              children: [
                if (vm.isSaving)
                  const LinearProgressIndicator(
                    minHeight: 2,
                    color: AppColors.primaryContainer,
                  ),
                if (vm.errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.errorContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              vm.errorMessage!,
                              style: AppTypography.bodySm(
                                color: AppColors.onErrorContainer,
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: vm.loadAddresses,
                            child: const Text('Muat Ulang'),
                          ),
                        ],
                      ),
                    ),
                  ),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: vm.loadAddresses,
                    color: AppColors.primaryContainer,
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                      itemCount: vm.addresses.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final address = vm.addresses[index];
                        final isSelected =
                            widget.selectionMode &&
                            vm.selectedAddress?.id == address.id;
                        return _buildAddressCard(
                          address,
                          isSelected: isSelected,
                          isBusy: vm.isSaving,
                        );
                      },
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                  child: SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: vm.isSaving ? null : () => _openForm(),
                      icon: const Icon(Icons.add, size: 20),
                      label: Text(
                        'Tambah Alamat',
                        style: AppTypography.labelLg(
                          color: Colors.white,
                        ).copyWith(fontWeight: FontWeight.w700),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryContainer,
                        foregroundColor: Colors.white,
                        shape: const StadiumBorder(),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildAddressCard(
    UserAddress address, {
    required bool isSelected,
    required bool isBusy,
  }) {
    final hasPostal =
        address.postalCode != null && address.postalCode!.trim().isNotEmpty;
    final hasNote =
        address.deliveryNote != null && address.deliveryNote!.trim().isNotEmpty;

    return Material(
      color: AppColors.surfaceContainerLowest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isSelected
              ? AppColors.primaryContainer
              : AppColors.outlineVariant.withValues(alpha: 0.7),
          width: isSelected ? 1.6 : 0.9,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: widget.selectionMode
            ? () => _selectForEstimator(address)
            : null,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: label + badges
              Wrap(
                spacing: 8,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    address.label,
                    style: AppTypography.labelLg(
                      color: AppColors.onSurface,
                    ).copyWith(fontWeight: FontWeight.w700),
                  ),
                  if (address.isDefault)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.secondaryContainer,
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Text(
                        'Alamat Utama',
                        style: AppTypography.labelSm(
                          color: AppColors.primary,
                        ).copyWith(fontWeight: FontWeight.w700),
                      ),
                    ),
                  if (isSelected)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primaryContainer,
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Text(
                        'Dipilih',
                        style: AppTypography.labelSm(
                          color: Colors.white,
                        ).copyWith(fontWeight: FontWeight.w700),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),

              // Recipient
              Text(
                '${address.recipientName} · ${PhoneUtils.formatForDisplay(address.recipientPhone)}',
                style: AppTypography.bodyMd(
                  color: AppColors.onSurface,
                ).copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),

              // Destination label
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 2),
                    child: Icon(
                      Icons.location_on_outlined,
                      size: 15,
                      color: AppColors.primaryContainer,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      DisplayFormatters.deduplicateLocationLabel(
                        address.destinationLabel,
                      ),
                      style: AppTypography.bodySm(
                        color: AppColors.secondary,
                      ).copyWith(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),

              // Full address detail
              Text(
                hasPostal
                    ? '${address.addressDetail} (${address.postalCode})'
                    : address.addressDetail,
                style: AppTypography.bodyMd(color: AppColors.onSurfaceVariant),
              ),
              if (hasNote) ...[
                const SizedBox(height: 4),
                Text(
                  'Catatan: ${address.deliveryNote}',
                  style: AppTypography.bodySm(color: AppColors.outline),
                ),
              ],
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 6),

              // Actions
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  if (widget.selectionMode)
                    TextButton.icon(
                      onPressed: isBusy
                          ? null
                          : () => _selectForEstimator(address),
                      style: TextButton.styleFrom(
                        minimumSize: const Size(0, 48),
                        foregroundColor: AppColors.primaryContainer,
                      ),
                      icon: const Icon(Icons.check_circle_outline, size: 18),
                      label: const Text('Pilih Alamat'),
                    ),
                  TextButton.icon(
                    onPressed: isBusy
                        ? null
                        : () => _openForm(existing: address),
                    style: TextButton.styleFrom(
                      minimumSize: const Size(0, 48),
                      foregroundColor: AppColors.onSurface,
                    ),
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    label: const Text('Edit'),
                  ),
                  if (!address.isDefault)
                    TextButton.icon(
                      onPressed: isBusy ? null : () => _setAsDefault(address),
                      style: TextButton.styleFrom(
                        minimumSize: const Size(0, 48),
                        foregroundColor: AppColors.primaryContainer,
                      ),
                      icon: const Icon(Icons.star_outline, size: 18),
                      label: const Text('Jadikan Utama'),
                    ),
                  TextButton.icon(
                    onPressed: isBusy ? null : () => _confirmDelete(address),
                    style: TextButton.styleFrom(
                      minimumSize: const Size(0, 48),
                      foregroundColor: AppColors.error,
                    ),
                    icon: const Icon(Icons.delete_outline, size: 18),
                    label: const Text('Hapus'),
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
