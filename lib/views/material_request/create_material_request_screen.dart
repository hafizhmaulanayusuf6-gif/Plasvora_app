import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../viewmodels/material_request_viewmodel.dart';

class CreateMaterialRequestScreen extends StatefulWidget {
  final MaterialRequestViewModel viewModel;
  final String? initialCategory;

  const CreateMaterialRequestScreen({
    super.key,
    required this.viewModel,
    this.initialCategory,
  });

  @override
  State<CreateMaterialRequestScreen> createState() =>
      _CreateMaterialRequestScreenState();
}

class _CreateMaterialRequestScreenState
    extends State<CreateMaterialRequestScreen> {
  final _formKey = GlobalKey<FormState>();

  late String _selectedCategory;
  late String _selectedCondition;
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _intendedUseController = TextEditingController();

  final List<Map<String, String>> _categories = const [
    {'value': 'PET', 'label': 'PET (Polyethylene Terephthalate)'},
    {'value': 'HDPE', 'label': 'HDPE (High-Density Polyethylene)'},
    {'value': 'PP', 'label': 'PP (Polypropylene)'},
    {'value': 'LDPE', 'label': 'LDPE (Low-Density Polyethylene)'},
    {'value': 'OTHER', 'label': 'OTHER (Lainnya)'},
    {'value': 'MIXED', 'label': 'MIXED (Campuran)'},
  ];

  final List<Map<String, String>> _conditions = const [
    {'value': 'clean', 'label': 'Bersih (Bebas kotoran & siap olah)'},
    {'value': 'slightly_dirty', 'label': 'Sedikit Kotor (Perlu cuci ringan)'},
    {'value': 'dirty', 'label': 'Kotor (Perlu pembersihan menyeluruh)'},
    {'value': 'mixed', 'label': 'Campuran (Berbagai kondisi)'},
  ];

  @override
  void initState() {
    super.initState();
    // Inisialisasi kategori awal (misal dari hasil analisis plastik)
    final initial = widget.initialCategory?.toUpperCase().trim();
    if (initial != null &&
        _categories.any((c) => c['value'] == initial)) {
      _selectedCategory = initial;
    } else {
      _selectedCategory = 'PET';
    }
    _selectedCondition = 'clean';
  }

  @override
  void dispose() {
    _weightController.dispose();
    _locationController.dispose();
    _intendedUseController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    final weight = double.tryParse(_weightController.text.trim()) ?? 0.0;
    final location = _locationController.text.trim();
    final intendedUse = _intendedUseController.text.trim();

    final success = await widget.viewModel.createRequest(
      category: _selectedCategory,
      weightKg: weight,
      condition: _selectedCondition,
      location: location,
      intendedUse: intendedUse,
    );

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Permintaan kebutuhan material berhasil diajukan!'),
          backgroundColor: AppColors.primaryContainer,
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.of(context).pop(true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.viewModel.errorMessage ??
                'Gagal mengajukan permintaan. Periksa koneksi Anda.',
          ),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: Text(
          'Ajukan Kebutuhan Plastik',
          style: AppTypography.headlineSm(color: AppColors.onSurface),
        ),
        backgroundColor: AppColors.surfaceContainerLowest,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.onSurface),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: ListenableBuilder(
        listenable: widget.viewModel,
        builder: (context, _) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.secondaryContainer.withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.secondary.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.info_outline,
                          color: AppColors.primary,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Ajukan jenis plastik dan spesifikasi material yang Anda butuhkan. Sistem Smart Matching akan otomatis mencari listing material yang sesuai kriteria Anda.',
                            style: AppTypography.bodySm(
                              color: AppColors.onSurface,
                            ).copyWith(height: 1.4),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Kategori Polimer
                  Text(
                    'Kategori Polimer *',
                    style: AppTypography.labelLg(color: AppColors.onSurface),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedCategory,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: AppColors.surfaceContainerLowest,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: AppColors.outline.withValues(alpha: 0.3),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: AppColors.outline.withValues(alpha: 0.3),
                        ),
                      ),
                    ),
                    items: _categories.map((c) {
                      return DropdownMenuItem<String>(
                        value: c['value'],
                        child: Text(
                          c['label']!,
                          style: AppTypography.bodyMd(color: AppColors.onSurface),
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => _selectedCategory = val);
                      }
                    },
                  ),
                  const SizedBox(height: 18),

                  // Berat Dibutuhkan
                  Text(
                    'Jumlah Berat Dibutuhkan (kg) *',
                    style: AppTypography.labelLg(color: AppColors.onSurface),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _weightController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      hintText: 'Contoh: 15.5',
                      suffixText: 'kg',
                      filled: true,
                      fillColor: AppColors.surfaceContainerLowest,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: AppColors.outline.withValues(alpha: 0.3),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: AppColors.outline.withValues(alpha: 0.3),
                        ),
                      ),
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'Jumlah berat wajib diisi';
                      }
                      final parsed = double.tryParse(val.trim());
                      if (parsed == null || parsed <= 0.0) {
                        return 'Berat harus berupa angka lebih dari 0 kg';
                      }
                      if (parsed > 99999.0) {
                        return 'Berat maksimal 99.999 kg';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 18),

                  // Kondisi Minimum
                  Text(
                    'Kondisi Minimum yang Diterima *',
                    style: AppTypography.labelLg(color: AppColors.onSurface),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedCondition,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: AppColors.surfaceContainerLowest,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: AppColors.outline.withValues(alpha: 0.3),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: AppColors.outline.withValues(alpha: 0.3),
                        ),
                      ),
                    ),
                    items: _conditions.map((c) {
                      return DropdownMenuItem<String>(
                        value: c['value'],
                        child: Text(
                          c['label']!,
                          style: AppTypography.bodyMd(color: AppColors.onSurface),
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => _selectedCondition = val);
                      }
                    },
                  ),
                  const SizedBox(height: 18),

                  // Lokasi Kebutuhan
                  Text(
                    'Lokasi Kebutuhan (Kota / Daerah) *',
                    style: AppTypography.labelLg(color: AppColors.onSurface),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _locationController,
                    decoration: InputDecoration(
                      hintText: 'Contoh: Bandung Kulon, Jawa Barat',
                      filled: true,
                      fillColor: AppColors.surfaceContainerLowest,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: AppColors.outline.withValues(alpha: 0.3),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: AppColors.outline.withValues(alpha: 0.3),
                        ),
                      ),
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'Lokasi umum wajib diisi';
                      }
                      if (val.trim().length < 3) {
                        return 'Lokasi minimal 3 karakter';
                      }
                      if (val.trim().length > 255) {
                        return 'Lokasi maksimal 255 karakter';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 18),

                  // Tujuan Penggunaan
                  Text(
                    'Tujuan Penggunaan Material *',
                    style: AppTypography.labelLg(color: AppColors.onSurface),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _intendedUseController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText:
                          'Contoh: Bahan baku daur ulang pot tanaman dan kerajinan tangan komunitas.',
                      filled: true,
                      fillColor: AppColors.surfaceContainerLowest,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: AppColors.outline.withValues(alpha: 0.3),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: AppColors.outline.withValues(alpha: 0.3),
                        ),
                      ),
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'Tujuan penggunaan material wajib diisi';
                      }
                      if (val.trim().length < 5) {
                        return 'Tujuan penggunaan minimal 5 karakter';
                      }
                      if (val.trim().length > 500) {
                        return 'Tujuan penggunaan maksimal 500 karakter';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 28),

                  // Submit Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed:
                          widget.viewModel.isSubmitting ? null : _submitForm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryContainer,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                      child: widget.viewModel.isSubmitting
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              'Ajukan Kebutuhan Sekarang',
                              style: AppTypography.labelLg(color: Colors.white)
                                  .copyWith(fontWeight: FontWeight.w700),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

