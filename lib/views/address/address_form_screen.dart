import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/phone_utils.dart';
import '../../core/widgets/destination_picker_sheet.dart';
import '../../core/widgets/plasvora_header.dart';
import '../../models/user_address.dart';
import '../../repositories/shipping_repository.dart';
import '../../viewmodels/address_viewmodel.dart';

/// Form reusable untuk membuat dan memperbarui alamat pengiriman pembeli.
class AddressFormScreen extends StatefulWidget {
  final AddressViewModel addressViewModel;
  final ShippingRepository shippingRepository;
  final UserAddress? existingAddress;

  const AddressFormScreen({
    super.key,
    required this.addressViewModel,
    required this.shippingRepository,
    this.existingAddress,
  });

  @override
  State<AddressFormScreen> createState() => _AddressFormScreenState();
}

class _AddressFormScreenState extends State<AddressFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _labelCtrl;
  late final TextEditingController _recipientNameCtrl;
  late final TextEditingController _recipientPhoneCtrl;
  late final TextEditingController _addressDetailCtrl;
  late final TextEditingController _postalCodeCtrl;
  late final TextEditingController _deliveryNoteCtrl;

  int? _destinationId;
  String? _destinationLabel;
  String? _lastAutofilledPostalCode;
  bool _isDefault = false;
  bool _isSubmitting = false;

  String? _destinationError;
  String? _generalError;
  Map<String, String> _serverFieldErrors = const {};

  bool get _isEditMode => widget.existingAddress != null;

  @override
  void initState() {
    super.initState();
    final existing = widget.existingAddress;
    _labelCtrl = TextEditingController(
      text: existing != null ? existing.label : 'Rumah',
    );
    _recipientNameCtrl = TextEditingController(
      text: existing?.recipientName ?? '',
    );
    _recipientPhoneCtrl = TextEditingController(
      text: existing?.recipientPhone ?? '',
    );
    _addressDetailCtrl = TextEditingController(
      text: existing?.addressDetail ?? '',
    );
    _postalCodeCtrl = TextEditingController(
      text: existing?.postalCode ?? '',
    );
    _deliveryNoteCtrl = TextEditingController(
      text: existing?.deliveryNote ?? '',
    );

    if (existing != null) {
      _destinationId = existing.destinationId > 0 ? existing.destinationId : null;
      _destinationLabel = existing.destinationLabel.trim().isNotEmpty
          ? existing.destinationLabel.trim()
          : null;
      _isDefault = existing.isDefault;
    }
  }

  @override
  void dispose() {
    _labelCtrl.dispose();
    _recipientNameCtrl.dispose();
    _recipientPhoneCtrl.dispose();
    _addressDetailCtrl.dispose();
    _postalCodeCtrl.dispose();
    _deliveryNoteCtrl.dispose();
    super.dispose();
  }

  void _clearServerFieldError(String field) {
    if (!_serverFieldErrors.containsKey(field) && _generalError == null) return;
    setState(() {
      if (_serverFieldErrors.containsKey(field)) {
        final next = Map<String, String>.from(_serverFieldErrors);
        next.remove(field);
        _serverFieldErrors = next;
      }
      _generalError = null;
    });
  }

  Future<void> _pickDestination() async {
    if (_isSubmitting || widget.addressViewModel.isSaving) return;

    final selected = await DestinationPickerSheet.show(
      context,
      shippingRepository: widget.shippingRepository,
      title: 'Pilih Wilayah Tujuan',
    );
    if (!mounted || selected == null) return;

    setState(() {
      _destinationId = selected.destinationId;
      _destinationLabel = selected.label;
      _destinationError = null;
      _generalError = null;
      if (_serverFieldErrors.containsKey('destination_id') ||
          _serverFieldErrors.containsKey('destination_label')) {
        final next = Map<String, String>.from(_serverFieldErrors);
        next.remove('destination_id');
        next.remove('destination_label');
        _serverFieldErrors = next;
      }

      final pickedPostal = selected.postalCode?.trim() ?? '';
      final currentPostal = _postalCodeCtrl.text.trim();
      if (pickedPostal.isNotEmpty &&
          (currentPostal.isEmpty || currentPostal == _lastAutofilledPostalCode)) {
        _postalCodeCtrl.text = pickedPostal;
        _lastAutofilledPostalCode = pickedPostal;
      }
    });
  }

  Future<void> _submit() async {
    if (_isSubmitting || widget.addressViewModel.isSaving) return;

    setState(() {
      _generalError = null;
      _serverFieldErrors = const {};
    });

    final hasValidDestination =
        _destinationId != null &&
        _destinationId! > 0 &&
        _destinationLabel != null &&
        _destinationLabel!.trim().isNotEmpty;

    setState(() {
      _destinationError = hasValidDestination
          ? null
          : 'Wilayah tujuan wajib dipilih dari daftar pencarian.';
    });

    final formValid = _formKey.currentState?.validate() ?? false;
    if (!formValid || !hasValidDestination) {
      return;
    }

    setState(() => _isSubmitting = true);

    final labelText = _labelCtrl.text.trim().isNotEmpty
        ? _labelCtrl.text.trim()
        : 'Rumah';
    final recipientName = _recipientNameCtrl.text.trim();
    final recipientPhone = _recipientPhoneCtrl.text.trim();
    final addressDetail = _addressDetailCtrl.text.trim();
    final postalCode = _postalCodeCtrl.text.trim();
    final deliveryNote = _deliveryNoteCtrl.text.trim();

    UserAddress? saved;
    if (_isEditMode) {
      saved = await widget.addressViewModel.updateAddress(
        id: widget.existingAddress!.id,
        label: labelText,
        recipientName: recipientName,
        recipientPhone: recipientPhone,
        destinationId: _destinationId!,
        destinationLabel: _destinationLabel!.trim(),
        addressDetail: addressDetail,
        postalCode: postalCode,
        deliveryNote: deliveryNote,
        isDefault: _isDefault,
      );
    } else {
      saved = await widget.addressViewModel.createAddress(
        label: labelText,
        recipientName: recipientName,
        recipientPhone: recipientPhone,
        destinationId: _destinationId!,
        destinationLabel: _destinationLabel!.trim(),
        addressDetail: addressDetail,
        postalCode: postalCode.isNotEmpty ? postalCode : null,
        deliveryNote: deliveryNote.isNotEmpty ? deliveryNote : null,
        isDefault: _isDefault,
      );
    }

    if (!mounted) return;

    if (saved != null) {
      final warning = widget.addressViewModel.errorMessage;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            warning ??
                (_isEditMode
                    ? 'Alamat pengiriman berhasil diperbarui.'
                    : 'Alamat pengiriman berhasil disimpan.'),
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.of(context).pop(saved);
      return;
    }

    final fieldErrors = widget.addressViewModel.fieldErrors;
    final destServerError =
        fieldErrors['destination_id'] ?? fieldErrors['destination_label'];
    setState(() {
      _isSubmitting = false;
      _serverFieldErrors = fieldErrors;
      if (destServerError != null) {
        _destinationError = destServerError;
      }
      _generalError =
          widget.addressViewModel.errorMessage ??
          (_isEditMode
              ? 'Gagal memperbarui alamat pengiriman.'
              : 'Gagal menyimpan alamat pengiriman.');
    });
  }

  @override
  Widget build(BuildContext context) {
    final isBusy = _isSubmitting || widget.addressViewModel.isSaving;

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: PlasvoraHeader(
        customTitle: _isEditMode ? 'Edit Alamat' : 'Tambah Alamat',
        showBack: true,
        onBack: () => Navigator.of(context).pop(),
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            20,
            16,
            20,
            24 + MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Detail Penerima & Alamat',
                  style: AppTypography.headlineSm(color: AppColors.onSurface),
                ),
                const SizedBox(height: 14),

                // 1. Label alamat
                TextFormField(
                  controller: _labelCtrl,
                  enabled: !isBusy,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    labelText: 'Label Alamat',
                    hintText: 'Contoh: Rumah, Kantor, Gudang',
                    errorText: _serverFieldErrors['label'],
                  ),
                  onChanged: (_) => _clearServerFieldError('label'),
                  validator: (v) {
                    if (v != null && v.trim().length > 60) {
                      return 'Label alamat maksimal 60 karakter.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),

                // 2. Nama penerima
                TextFormField(
                  controller: _recipientNameCtrl,
                  enabled: !isBusy,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    labelText: 'Nama Penerima *',
                    hintText: 'Nama lengkap penerima',
                    errorText: _serverFieldErrors['recipient_name'],
                  ),
                  onChanged: (_) => _clearServerFieldError('recipient_name'),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Nama penerima wajib diisi.';
                    }
                    if (v.trim().length > 120) {
                      return 'Nama penerima maksimal 120 karakter.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),

                // 3. Nomor telepon penerima
                TextFormField(
                  controller: _recipientPhoneCtrl,
                  enabled: !isBusy,
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    labelText: 'Nomor Telepon Penerima *',
                    hintText: 'Contoh: 081234567890',
                    errorText: _serverFieldErrors['recipient_phone'],
                  ),
                  onChanged: (_) => _clearServerFieldError('recipient_phone'),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Nomor telepon penerima wajib diisi.';
                    }
                    if (PhoneUtils.normalizeIndonesianPhone(v) == null) {
                      return 'Format nomor tidak valid. Contoh: 081234567890 atau +6281234567890.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),

                // 4. Wilayah tujuan (via DestinationPickerSheet)
                Text(
                  'Wilayah Tujuan *',
                  style: AppTypography.labelMd(color: AppColors.onSurface),
                ),
                const SizedBox(height: 6),
                Material(
                  color: AppColors.surfaceContainerLowest,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: _destinationError != null
                          ? AppColors.error
                          : AppColors.outlineVariant,
                      width: _destinationError != null ? 1.4 : 0.9,
                    ),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: isBusy ? null : _pickDestination,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(minHeight: 56),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.location_on_outlined,
                              size: 20,
                              color: AppColors.primaryContainer,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _destinationLabel ??
                                    'Pilih kelurahan, kecamatan, atau kota',
                                style: _destinationLabel != null
                                    ? AppTypography.bodyMd(
                                        color: AppColors.onSurface,
                                      )
                                    : AppTypography.bodyMd(
                                        color: AppColors.outline,
                                      ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _destinationLabel != null ? 'Ubah' : 'Pilih',
                              style: AppTypography.labelMd(
                                color: AppColors.primaryContainer,
                              ).copyWith(fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                if (_destinationError != null) ...[
                  const SizedBox(height: 6),
                  Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: Text(
                      _destinationError!,
                      style: AppTypography.bodySm(color: AppColors.error),
                    ),
                  ),
                ],
                const SizedBox(height: 12),

                // 5. Alamat lengkap
                TextFormField(
                  controller: _addressDetailCtrl,
                  enabled: !isBusy,
                  minLines: 3,
                  maxLines: 5,
                  textInputAction: TextInputAction.newline,
                  decoration: InputDecoration(
                    labelText: 'Alamat Lengkap *',
                    hintText:
                        'Nama jalan, nomor rumah, RT/RW, kelurahan, atau patokan.',
                    alignLabelWithHint: true,
                    errorText: _serverFieldErrors['address_detail'],
                  ),
                  onChanged: (_) => _clearServerFieldError('address_detail'),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Alamat lengkap wajib diisi.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),

                // 6. Kode pos
                TextFormField(
                  controller: _postalCodeCtrl,
                  enabled: !isBusy,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    labelText: 'Kode Pos (Opsional)',
                    hintText: 'Contoh: 40111',
                    errorText: _serverFieldErrors['postal_code'],
                  ),
                  onChanged: (_) => _clearServerFieldError('postal_code'),
                  validator: (v) {
                    if (v != null && v.trim().length > 20) {
                      return 'Kode pos maksimal 20 karakter.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),

                // 7. Catatan pengiriman
                TextFormField(
                  controller: _deliveryNoteCtrl,
                  enabled: !isBusy,
                  maxLines: 2,
                  textInputAction: TextInputAction.done,
                  decoration: InputDecoration(
                    labelText: 'Catatan Pengiriman (Opsional)',
                    hintText: 'Contoh: Rumah pagar hijau, dekat pos satpam',
                    alignLabelWithHint: true,
                    errorText: _serverFieldErrors['delivery_note'],
                  ),
                  onChanged: (_) => _clearServerFieldError('delivery_note'),
                  validator: (v) {
                    if (v != null && v.trim().length > 255) {
                      return 'Catatan pengiriman maksimal 255 karakter.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),

                // 8. Jadikan alamat utama
                Material(
                  color: AppColors.surfaceContainerLowest,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: BorderSide(
                      color: AppColors.outlineVariant.withValues(alpha: 0.7),
                    ),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: SwitchListTile.adaptive(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 4,
                    ),
                    activeTrackColor: AppColors.primaryContainer,
                    title: Text(
                      'Jadikan alamat utama',
                      style: AppTypography.labelLg(color: AppColors.onSurface),
                    ),
                    subtitle: Text(
                      'Dipilih otomatis sebagai tujuan utama saat mengecek ongkos kirim.',
                      style: AppTypography.bodySm(
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                    value: _isDefault,
                    onChanged: isBusy
                        ? null
                        : (val) => setState(() => _isDefault = val),
                  ),
                ),

                if (_generalError != null) ...[
                  const SizedBox(height: 14),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.errorContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _generalError!,
                      style: AppTypography.bodySm(
                        color: AppColors.onErrorContainer,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 22),

                // Submit CTA
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: isBusy ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryContainer,
                      foregroundColor: Colors.white,
                      shape: const StadiumBorder(),
                      elevation: 2,
                    ),
                    child: isBusy
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            _isEditMode ? 'Simpan Perubahan' : 'Simpan Alamat',
                            style: AppTypography.labelLg(
                              color: Colors.white,
                            ).copyWith(fontWeight: FontWeight.w700),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
