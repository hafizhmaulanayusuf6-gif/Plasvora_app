import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/destination_picker_sheet.dart';
import '../../core/widgets/simple_page_app_bar.dart';
import '../../models/material_listing.dart';
import '../../models/plastic_analysis.dart';
import '../../repositories/shipping_repository.dart';
import '../../viewmodels/marketplace_viewmodel.dart';

class CreateMaterialListingScreen extends StatefulWidget {
  final MarketplaceViewModel viewModel;
  final PlasticAnalysisResult? initialAnalysis;
  final MaterialListing? existingListing;
  final ShippingRepository? shippingRepository;
  final Future<String?> Function(ImageSource source)? pickImageOverride;

  const CreateMaterialListingScreen({
    super.key,
    required this.viewModel,
    this.initialAnalysis,
    this.existingListing,
    this.shippingRepository,
    this.pickImageOverride,
  });

  @override
  State<CreateMaterialListingScreen> createState() =>
      _CreateMaterialListingScreenState();
}

class _CreateMaterialListingScreenState
    extends State<CreateMaterialListingScreen> {
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _imagePicker = ImagePicker();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _weightCtrl;
  final TextEditingController _locationCtrl = TextEditingController();
  final TextEditingController _priceCtrl = TextEditingController(text: '0');
  late final TextEditingController _descriptionCtrl;

  late String _selectedCategory;
  String _selectedCondition = 'clean';
  String? _selectedImagePath;
  String? _existingImageUrl;
  String? _existingLocalAsset;
  String? _imageError;
  bool _isFree = true;
  bool _isSubmitting = false;

  int? _originDestinationId;
  String? _originLabel;
  bool _clearOriginRequested = false;
  String? _originError;
  String? _formError;

  static const List<String> _categories = [
    'PET',
    'HDPE',
    'PP',
    'LDPE',
    'MIXED',
    'Lainnya',
  ];

  static const List<String> _conditions = [
    'clean',
    'slightly_dirty',
    'dirty',
    'mixed',
  ];

  static const Map<String, String> _conditionLabels = {
    'clean': 'Bersih',
    'slightly_dirty': 'Sedikit Kotor',
    'dirty': 'Kotor',
    'mixed': 'Campuran',
  };

  bool get _isEditMode => widget.existingListing != null;

  @override
  void initState() {
    super.initState();
    final existing = widget.existingListing;
    if (existing != null) {
      _nameCtrl = TextEditingController(text: existing.name);
      _weightCtrl = TextEditingController(
        text: _formatEditableWeight(existing.weightKg),
      );
      _locationCtrl.text = existing.generalLocation;
      _isFree = existing.isFree || existing.price == 0;
      _priceCtrl.text = _isFree ? '0' : existing.price.toString();
      _descriptionCtrl = TextEditingController(text: existing.description);

      final mappedCat = existing.category.toUpperCase() == 'OTHER'
          ? 'Lainnya'
          : existing.category;
      _selectedCategory = _categories.contains(mappedCat)
          ? mappedCat
          : 'Lainnya';

      final mappedCond = existing.condition.toLowerCase() == 'light'
          ? 'slightly_dirty'
          : existing.condition.toLowerCase();
      _selectedCondition = _conditions.contains(mappedCond)
          ? mappedCond
          : 'clean';

      _originDestinationId = existing.originDestinationId;
      _originLabel = existing.originLabel;
      _existingImageUrl = existing.imageUrl;
      _existingLocalAsset = existing.localAsset;
      return;
    }

    final analysis = widget.initialAnalysis;

    // Pre-fill dari hasil analisis jika tersedia
    _nameCtrl = TextEditingController(text: analysis?.materialTitle ?? '');
    _weightCtrl = TextEditingController(); // berat tidak diisi — user harus mengisi
    _descriptionCtrl = TextEditingController(
      text: analysis != null ? _buildDescriptionFromAnalysis(analysis) : '',
    );

    // Tentukan kategori awal
    final rawCat = analysis?.polymerCategory ?? 'PET';
    _selectedCategory = _categories.contains(rawCat) ? rawCat : 'Lainnya';

    // Jika foto analisis adalah file lokal yang masih ada, siapkan untuk preview & upload
    final analysisImg = analysis?.imagePath;
    if (analysisImg != null &&
        analysisImg.isNotEmpty &&
        !analysisImg.startsWith('http://') &&
        !analysisImg.startsWith('https://') &&
        File(analysisImg).existsSync()) {
      _selectedImagePath = analysisImg;
    }
  }

  String _formatEditableWeight(double weight) {
    if (weight == weight.truncateToDouble()) {
      return weight.toInt().toString();
    }
    return weight.toString();
  }

  Future<void> _pickOriginDestination() async {
    if (_isSubmitting || widget.viewModel.isSaving) return;

    final repo = widget.shippingRepository;
    if (repo == null) {
      setState(() {
        _originError =
            'Layanan pencarian lokasi asal belum tersedia saat ini.';
      });
      return;
    }

    final selected = await DestinationPickerSheet.show(
      context,
      shippingRepository: repo,
      title: 'Pilih Lokasi Asal Pengiriman',
    );
    if (!mounted || selected == null) return;

    setState(() {
      _originDestinationId = selected.destinationId;
      _originLabel = selected.label;
      _clearOriginRequested = false;
      _originError = null;
      _formError = null;

      // Isi lokasi umum hanya jika masih kosong — jangan timpa input manual pengguna
      if (_locationCtrl.text.trim().isEmpty) {
        final city = selected.cityName?.trim();
        _locationCtrl.text = (city != null && city.isNotEmpty)
            ? city
            : selected.label;
      }
    });
  }

  void _clearOriginSelection() {
    if (_isSubmitting || widget.viewModel.isSaving) return;
    setState(() {
      _originDestinationId = null;
      _originLabel = null;
      _clearOriginRequested = true;
      _originError = null;
      _formError = null;
    });
  }

  Future<void> _pickImage(ImageSource source) async {
    setState(() => _imageError = null);
    try {
      String? pickedPath;
      if (widget.pickImageOverride != null) {
        pickedPath = await widget.pickImageOverride!(source);
      } else {
        final picked = await _imagePicker.pickImage(
          source: source,
          imageQuality: 85,
          maxWidth: 1600,
        );
        pickedPath = picked?.path;
      }
      if (pickedPath != null && pickedPath.isNotEmpty && mounted) {
        setState(() {
          _selectedImagePath = pickedPath;
          _imageError = null;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _imageError =
              'Gagal mengakses ${source == ImageSource.camera ? 'kamera' : 'galeri'}. Periksa izin aplikasi.';
        });
      }
    }
  }

  void _showImageSourceSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceContainerLowest,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Pilih Sumber Foto Material',
                style: AppTypography.headlineSm(color: AppColors.onSurface),
              ),
              const SizedBox(height: 12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const CircleAvatar(
                  backgroundColor: AppColors.secondaryContainer,
                  child: Icon(Icons.photo_camera, color: AppColors.primary),
                ),
                title: const Text('Ambil Foto dari Kamera'),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const CircleAvatar(
                  backgroundColor: AppColors.secondaryContainer,
                  child: Icon(Icons.photo_library, color: AppColors.primary),
                ),
                title: const Text('Pilih dari Galeri'),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _pickImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _buildDescriptionFromAnalysis(PlasticAnalysisResult a) {
    final buffer = StringBuffer();
    buffer.writeln('Material hasil analisis AI Plasvora.');
    if (a.objectName != null && a.objectName!.isNotEmpty) {
      buffer.writeln('Objek terdeteksi: ${a.objectName}');
    }
    buffer.writeln('Polimer: ${a.polymerCategory} (${a.polymerCode})');
    if (a.meltingPoint.isNotEmpty) {
      buffer.writeln('Titik leleh: ${a.meltingPoint}');
    }
    if (a.objectDescription != null && a.objectDescription!.isNotEmpty) {
      buffer.writeln('Keterangan: ${a.objectDescription}');
    }
    buffer.writeln(
      '\n⚠ Data kategori dan deskripsi bersumber dari AI. Berat dan lokasi diisi sendiri oleh penjual.',
    );
    return buffer.toString().trim();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _weightCtrl.dispose();
    _locationCtrl.dispose();
    _priceCtrl.dispose();
    _descriptionCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_isSubmitting || widget.viewModel.isSaving) return;

    setState(() {
      _formError = null;
      _originError = null;
    });

    final trimmedOriginLabel = _originLabel?.trim() ?? '';
    final hasValidOriginId =
        _originDestinationId != null && _originDestinationId! > 0;
    final hasValidOriginLabel = trimmedOriginLabel.isNotEmpty;
    final hasAnyOriginField =
        _originDestinationId != null ||
        (_originLabel != null && _originLabel!.isNotEmpty);

    String? localOriginError;
    if (hasAnyOriginField && !(hasValidOriginId && hasValidOriginLabel)) {
      localOriginError =
          'Lokasi asal pengiriman tidak lengkap. Pilih lokasi valid dari daftar pencarian.';
    } else if (!_isEditMode && !(hasValidOriginId && hasValidOriginLabel)) {
      localOriginError =
          'Lokasi asal pengiriman wajib dipilih dari daftar pencarian.';
    }

    if (localOriginError != null) {
      setState(() => _originError = localOriginError);
    }

    final isFormValid = _formKey.currentState?.validate() ?? false;
    if (!isFormValid || localOriginError != null) return;

    setState(() => _isSubmitting = true);

    try {
      if (_isEditMode) {
        final existing = widget.existingListing!;
        final hadOrigin =
            existing.originDestinationId != null ||
            (existing.originLabel != null &&
                existing.originLabel!.trim().isNotEmpty);
        final shouldClearOrigin =
            _clearOriginRequested && hadOrigin && !hasValidOriginId;

        final updated = await widget.viewModel.updateListing(
          id: existing.id,
          name: _nameCtrl.text.trim(),
          category: _selectedCategory,
          weightKg: double.parse(_weightCtrl.text.trim()),
          condition: _selectedCondition,
          price: _isFree
              ? 0
              : (num.tryParse(_priceCtrl.text.trim())?.toInt() ?? 0),
          isFree: _isFree,
          generalLocation: _locationCtrl.text.trim(),
          description: _descriptionCtrl.text.trim(),
          originDestinationId: shouldClearOrigin
              ? null
              : (hasValidOriginId ? _originDestinationId : null),
          originLabel: shouldClearOrigin
              ? null
              : (hasValidOriginLabel ? trimmedOriginLabel : null),
          clearOrigin: shouldClearOrigin,
          imagePath: _selectedImagePath,
        );

        if (!mounted) return;

        if (updated != null) {
          setState(() => _isSubmitting = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Penawaran material berhasil diperbarui!'),
              behavior: SnackBarBehavior.floating,
            ),
          );
          Navigator.of(context).pop(updated);
          return;
        }

        final errMsg =
            widget.viewModel.errorMessage ??
            'Gagal memperbarui penawaran material.';
        setState(() {
          _isSubmitting = false;
          _formError = errMsg;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errMsg),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.red.shade700,
          ),
        );
        return;
      }

      final success = await widget.viewModel.createListing(
        name: _nameCtrl.text.trim(),
        category: _selectedCategory,
        weightKg: double.parse(_weightCtrl.text.trim()),
        condition: _selectedCondition,
        price: _isFree
            ? 0
            : (num.tryParse(_priceCtrl.text.trim())?.toInt() ?? 0),
        isFree: _isFree,
        generalLocation: _locationCtrl.text.trim(),
        description: _descriptionCtrl.text.trim(),
        originDestinationId: _originDestinationId,
        originLabel: trimmedOriginLabel,
        imagePath: _selectedImagePath,
      );

      if (!mounted) return;

      if (success) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Penawaran material berhasil dipublikasikan!'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.of(context).pop(true);
      } else {
        final errMsg =
            widget.viewModel.errorMessage ??
            'Gagal mempublikasikan penawaran.';
        setState(() {
          _isSubmitting = false;
          _formError = errMsg;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errMsg),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    } on ArgumentError catch (e) {
      if (!mounted) return;
      final rawMessage = e.message?.toString().trim() ?? '';
      final message = rawMessage.isNotEmpty
          ? rawMessage
          : 'Data lokasi asal pengiriman tidak valid. Silakan pilih ulang dari daftar pencarian.';
      setState(() {
        _isSubmitting = false;
        _originError = message;
        _formError = message;
      });
    } catch (_) {
      if (!mounted) return;
      const message =
          'Terjadi kendala saat menyimpan penawaran. Silakan coba lagi.';
      setState(() {
        _isSubmitting = false;
        _formError = message;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final analysis = _isEditMode ? null : widget.initialAnalysis;
    final isFromAnalysis = analysis != null;
    final isBusy = _isSubmitting || widget.viewModel.isSaving;

    final appBarTitle = _isEditMode
        ? 'Edit Listing'
        : (isFromAnalysis ? 'Jual Material Ini' : 'Tawarkan Material');

    return Scaffold(
      appBar: SimplePageAppBar(
        title: appBarTitle,
        onBack: () => Navigator.of(context).pop(),
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            20,
            16,
            20,
            20 + MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ─── Foto material (pemilihan & preview upload) ────────
                _buildPhotoSection(analysis, isBusy: isBusy),
                const SizedBox(height: 16),

                // ─── Info banner jika dari analisis ───────────────────
                if (isFromAnalysis) ...[
                  _buildPrefillBanner(),
                  const SizedBox(height: 16),
                ],

                // ─── Form ─────────────────────────────────────────────
                Text(
                  'Informasi Material',
                  style: AppTypography.headlineSm(color: AppColors.onSurface),
                ),
                const SizedBox(height: 14),

                // Nama material
                TextFormField(
                  controller: _nameCtrl,
                  enabled: !isBusy,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Nama Material *',
                    hintText: 'contoh: Tutup Botol HDPE',
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Nama material wajib diisi.';
                    }
                    if (v.trim().length < 3) {
                      return 'Nama material minimal 3 karakter.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),

                // Kategori polimer
                DropdownButtonFormField<String>(
                  initialValue: _selectedCategory,
                  decoration: const InputDecoration(
                    labelText: 'Kategori Polimer *',
                  ),
                  items: _categories
                      .map(
                        (c) => DropdownMenuItem(
                          value: c,
                          child: Text(c == 'MIXED' ? 'Campuran (MIXED)' : c),
                        ),
                      )
                      .toList(),
                  onChanged: isBusy
                      ? null
                      : (val) {
                          if (val != null) {
                            setState(() => _selectedCategory = val);
                          }
                        },
                ),
                const SizedBox(height: 12),

                // Berat — TIDAK di-prefill pada create, user harus memasukkan
                TextFormField(
                  controller: _weightCtrl,
                  enabled: !isBusy,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    labelText: 'Berat Aktual (kg) *',
                    hintText: 'contoh: 5.5',
                    helperText: isFromAnalysis
                        ? 'Masukkan berat nyata material Anda (tidak diisi otomatis)'
                        : null,
                    helperStyle: const TextStyle(
                      color: AppColors.secondary,
                      fontSize: 11,
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Berat material wajib diisi.';
                    }
                    final w = double.tryParse(v.trim());
                    if (w == null || w < 0.01) {
                      return 'Berat harus lebih dari 0 kg.';
                    }
                    if (w > 99999) return 'Berat maksimal 99999 kg.';
                    return null;
                  },
                ),
                const SizedBox(height: 12),

                // Kondisi
                DropdownButtonFormField<String>(
                  initialValue: _selectedCondition,
                  decoration: const InputDecoration(
                    labelText: 'Kondisi Material *',
                  ),
                  items: _conditions
                      .map(
                        (c) => DropdownMenuItem(
                          value: c,
                          child: Text(_conditionLabels[c] ?? c),
                        ),
                      )
                      .toList(),
                  onChanged: isBusy
                      ? null
                      : (val) {
                          if (val != null) {
                            setState(() => _selectedCondition = val);
                          }
                        },
                ),
                const SizedBox(height: 14),

                // Lokasi asal pengiriman (RajaOngkir destination selector)
                _buildOriginSelectorSection(isBusy: isBusy),
                const SizedBox(height: 12),

                // Lokasi umum (free text terpisah dari origin_destination_id/label)
                TextFormField(
                  controller: _locationCtrl,
                  enabled: !isBusy,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Lokasi Umum *',
                    hintText: 'contoh: Kota Bandung',
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Lokasi wajib diisi.';
                    }
                    if (v.trim().length < 3) {
                      return 'Lokasi minimal 3 karakter.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),

                // Gratis / berbayar
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Gratis (donasi)',
                      style: AppTypography.labelMd(color: AppColors.onSurface),
                    ),
                    Switch(
                      value: _isFree,
                      activeThumbColor: AppColors.primary,
                      onChanged: isBusy
                          ? null
                          : (val) {
                              setState(() {
                                _isFree = val;
                                if (val) _priceCtrl.text = '0';
                              });
                            },
                    ),
                  ],
                ),
                if (!_isFree) ...[
                  TextFormField(
                    controller: _priceCtrl,
                    enabled: !isBusy,
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'Harga total (satu lot) *',
                      hintText: 'contoh: 15000',
                      prefixText: 'Rp ',
                      helperText:
                          'Harga berlaku untuk seluruh berat lot material ini, bukan per kg.',
                      helperMaxLines: 2,
                    ),
                    validator: (v) {
                      if (_isFree) return null;
                      if (v == null || v.trim().isEmpty) {
                        return 'Harga total (satu lot) wajib diisi jika tidak gratis.';
                      }
                      final p = num.tryParse(v.trim());
                      if (p == null || p <= 0) {
                        return 'Harga harus lebih dari 0.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                ],

                // Deskripsi
                TextFormField(
                  controller: _descriptionCtrl,
                  enabled: !isBusy,
                  maxLines: 4,
                  textInputAction: TextInputAction.done,
                  decoration: const InputDecoration(
                    labelText: 'Deskripsi',
                    hintText: 'Informasi tambahan tentang material',
                    alignLabelWithHint: true,
                  ),
                  validator: (v) {
                    if (v != null && v.length > 2000) {
                      return 'Deskripsi maksimal 2000 karakter.';
                    }
                    return null;
                  },
                ),

                if (_formError != null) ...[
                  const SizedBox(height: 14),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.errorContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _formError!,
                      style: AppTypography.bodySm(
                        color: AppColors.onErrorContainer,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 24),

                // Tombol submit
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: isBusy ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: const StadiumBorder(),
                      elevation: 4,
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
                            _isEditMode
                                ? 'Simpan Perubahan'
                                : 'Publikasikan Penawaran',
                            style: AppTypography.labelLg(
                              color: Colors.white,
                            ).copyWith(fontWeight: FontWeight.w700),
                          ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOriginSelectorSection({required bool isBusy}) {
    final hasSelection =
        _originLabel != null && _originLabel!.trim().isNotEmpty;
    final hasAnyOrigin = _originDestinationId != null || hasSelection;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _isEditMode
              ? 'Lokasi Asal Pengiriman (Opsional)'
              : 'Lokasi Asal Pengiriman *',
          style: AppTypography.labelMd(color: AppColors.onSurface),
        ),
        const SizedBox(height: 6),
        Material(
          color: AppColors.surfaceContainerLowest,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: _originError != null
                  ? AppColors.error
                  : AppColors.outlineVariant,
              width: _originError != null ? 1.4 : 0.9,
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: isBusy ? null : _pickOriginDestination,
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
                      Icons.local_shipping_outlined,
                      size: 20,
                      color: AppColors.primaryContainer,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        hasSelection
                            ? _originLabel!
                            : 'Pilih kelurahan, kecamatan, atau kota asal',
                        style: hasSelection
                            ? AppTypography.bodyMd(color: AppColors.onSurface)
                            : AppTypography.bodyMd(color: AppColors.outline),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      hasSelection ? 'Ubah' : 'Pilih',
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
        if (_isEditMode && hasAnyOrigin)
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: isBusy ? null : _clearOriginSelection,
              style: TextButton.styleFrom(
                minimumSize: const Size(0, 48),
                foregroundColor: AppColors.error,
                padding: const EdgeInsets.symmetric(horizontal: 4),
              ),
              icon: const Icon(Icons.close, size: 18),
              label: const Text('Hapus Lokasi Asal'),
            ),
          )
        else if (_isEditMode && !hasAnyOrigin)
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 4),
            child: Text(
              'Listing lama tanpa lokasi asal tetap dapat diperbarui. Tambahkan lokasi asal agar pembeli bisa menghitung ongkir.',
              style: AppTypography.bodySm(color: AppColors.onSurfaceVariant),
            ),
          ),
        if (_originError != null) ...[
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Text(
              _originError!,
              style: AppTypography.bodySm(color: AppColors.error),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildPhotoSection(
    PlasticAnalysisResult? analysis, {
    required bool isBusy,
  }) {
    final hasLocalSelection =
        _selectedImagePath != null && _selectedImagePath!.isNotEmpty;
    final hasExistingImage =
        _isEditMode &&
        ((_existingImageUrl != null && _existingImageUrl!.trim().isNotEmpty) ||
            (_existingLocalAsset != null &&
                _existingLocalAsset!.trim().isNotEmpty));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Flexible(
              child: Text(
                'Foto Material',
                style: AppTypography.headlineSm(color: AppColors.onSurface),
              ),
            ),
            const SizedBox(width: 6),
            Text(
              '(Opsional)',
              style: AppTypography.labelSm(color: AppColors.onSurfaceVariant),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (hasLocalSelection) ...[
          Container(
            width: double.infinity,
            height: 180,
            decoration: BoxDecoration(
              color: AppColors.surfaceContainer,
              borderRadius: BorderRadius.circular(16),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.file(
                File(_selectedImagePath!),
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Container(
                  color: AppColors.surfaceContainer,
                  alignment: Alignment.center,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.broken_image_outlined,
                        size: 36,
                        color: AppColors.outline,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Gagal memuat pratinjau foto',
                        style: AppTypography.bodySm(
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: isBusy ? null : _showImageSourceSheet,
                  icon: const Icon(Icons.photo_camera_outlined, size: 18),
                  label: const Text('Ganti Foto'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primaryContainer,
                    minimumSize: const Size(0, 48),
                    side: const BorderSide(color: AppColors.primaryContainer),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: isBusy
                      ? null
                      : () => setState(() {
                            _selectedImagePath = null;
                            _imageError = null;
                          }),
                  icon: const Icon(Icons.delete_outline, size: 18),
                  label: Text(
                    hasExistingImage ? 'Batal Ganti' : 'Hapus Foto',
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    minimumSize: const Size(0, 48),
                    side: const BorderSide(color: AppColors.error),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ] else if (hasExistingImage) ...[
          _buildExistingListingPhotoPreview(),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: isBusy ? null : _showImageSourceSheet,
              icon: const Icon(Icons.photo_camera_outlined, size: 18),
              label: const Text('Ganti Foto Material'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primaryContainer,
                minimumSize: const Size(double.infinity, 48),
                side: const BorderSide(color: AppColors.primaryContainer),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ] else if (analysis != null) ...[
          _buildAnalysisPhotoPreview(analysis),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: isBusy ? null : _showImageSourceSheet,
              icon: const Icon(Icons.add_a_photo_outlined, size: 18),
              label: const Text('Unggah Foto Baru dari Kamera / Galeri'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primaryContainer,
                minimumSize: const Size(double.infinity, 48),
                side: const BorderSide(color: AppColors.primaryContainer),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ] else ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.outlineVariant.withValues(alpha: 0.7),
              ),
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.add_photo_alternate_outlined,
                  size: 36,
                  color: AppColors.primaryContainer,
                ),
                const SizedBox(height: 8),
                Text(
                  'Tambahkan foto asli material agar pembeli lebih yakin.',
                  textAlign: TextAlign.center,
                  style: AppTypography.bodySm(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: isBusy
                            ? null
                            : () => _pickImage(ImageSource.camera),
                        icon: const Icon(Icons.photo_camera, size: 18),
                        label: const Text('Ambil Foto'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryContainer,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(0, 48),
                          shape: const StadiumBorder(),
                          elevation: 0,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: isBusy
                            ? null
                            : () => _pickImage(ImageSource.gallery),
                        icon: const Icon(
                          Icons.photo_library_outlined,
                          size: 18,
                        ),
                        label: const Text('Dari Galeri'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primaryContainer,
                          minimumSize: const Size(0, 48),
                          side: const BorderSide(
                            color: AppColors.primaryContainer,
                          ),
                          shape: const StadiumBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
        if (_imageError != null) ...[
          const SizedBox(height: 8),
          Text(
            _imageError!,
            style: AppTypography.bodySm(color: AppColors.error),
          ),
        ],
      ],
    );
  }

  Widget _buildExistingListingPhotoPreview() {
    final imageUrl = _existingImageUrl?.trim();
    final localAsset = _existingLocalAsset?.trim();

    return Container(
      width: double.infinity,
      height: 180,
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (imageUrl != null &&
                (imageUrl.startsWith('http://') ||
                    imageUrl.startsWith('https://')))
              Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => _buildExistingFallback(localAsset),
              )
            else
              _buildExistingFallback(localAsset),
            Positioned(
              bottom: 10,
              left: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  'Foto Saat Ini',
                  style: AppTypography.labelSm(color: Colors.white)
                      .copyWith(fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExistingFallback(String? localAsset) {
    if (localAsset != null && localAsset.isNotEmpty) {
      return Image.asset(
        localAsset,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => const Center(
          child: Icon(Icons.recycling, size: 44, color: AppColors.secondary),
        ),
      );
    }
    return const Center(
      child: Icon(Icons.recycling, size: 44, color: AppColors.secondary),
    );
  }

  Widget _buildAnalysisPhotoPreview(PlasticAnalysisResult analysis) {
    return Container(
      width: double.infinity,
      height: 180,
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Tampilkan gambar: local file / network URL / fallback asset
            if (analysis.imagePath != null)
              _buildImage(analysis.imagePath!, analysis.localAsset)
            else
              Image.asset(analysis.localAsset, fit: BoxFit.cover),
            // Overlay badge polimer
            Positioned(
              bottom: 10,
              left: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer.withValues(alpha: 0.92),
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  '${analysis.polymerCategory} · ${analysis.polymerCode}',
                  style: AppTypography.labelSm(color: Colors.white)
                      .copyWith(fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImage(String imagePath, String fallbackAsset) {
    // Cek apakah URL network (dari backend storage)
    if (imagePath.startsWith('http://') || imagePath.startsWith('https://')) {
      return Image.network(
        imagePath,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) =>
            Image.asset(fallbackAsset, fit: BoxFit.cover),
      );
    }
    // Cek apakah file lokal
    final file = File(imagePath);
    if (file.existsSync()) {
      return Image.file(file, fit: BoxFit.cover);
    }
    return Image.asset(fallbackAsset, fit: BoxFit.cover);
  }

  Widget _buildPrefillBanner() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.auto_awesome,
            size: 18,
            color: AppColors.primary,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Data kategori, nama, dan deskripsi diisi otomatis dari hasil analisis AI. '
              'Periksa kembali dan lengkapi berat serta lokasi Anda.',
              style: AppTypography.bodySm(color: AppColors.onSurface)
                  .copyWith(height: 1.5),
            ),
          ),
        ],
      ),
    );
  }
}
