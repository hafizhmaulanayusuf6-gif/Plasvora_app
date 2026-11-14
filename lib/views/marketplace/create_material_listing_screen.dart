import 'dart:io';

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/plasvora_header.dart';
import '../../models/plastic_analysis.dart';
import '../../viewmodels/marketplace_viewmodel.dart';

class CreateMaterialListingScreen extends StatefulWidget {
  final MarketplaceViewModel viewModel;
  final PlasticAnalysisResult? initialAnalysis;

  const CreateMaterialListingScreen({
    super.key,
    required this.viewModel,
    this.initialAnalysis,
  });

  @override
  State<CreateMaterialListingScreen> createState() =>
      _CreateMaterialListingScreenState();
}

class _CreateMaterialListingScreenState
    extends State<CreateMaterialListingScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _weightCtrl;
  final TextEditingController _locationCtrl = TextEditingController();
  final TextEditingController _priceCtrl = TextEditingController(text: '0');
  late final TextEditingController _descriptionCtrl;

  late String _selectedCategory;
  String _selectedCondition = 'clean';
  bool _isFree = true;
  bool _isSubmitting = false;

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

  @override
  void initState() {
    super.initState();
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
    buffer.writeln('\n⚠ Data kategori dan deskripsi bersumber dari AI. Berat dan lokasi diisi sendiri oleh penjual.');
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
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    final success = await widget.viewModel.createListing(
      name: _nameCtrl.text.trim(),
      category: _selectedCategory,
      weightKg: double.parse(_weightCtrl.text.trim()),
      condition: _selectedCondition,
      price: _isFree ? 0 : (num.tryParse(_priceCtrl.text.trim())?.toInt() ?? 0),
      isFree: _isFree,
      generalLocation: _locationCtrl.text.trim(),
      description: _descriptionCtrl.text.trim(),
    );

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Penawaran material berhasil dipublikasikan!'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.of(context).pop(true);
    } else {
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.viewModel.errorMessage ?? 'Gagal mempublikasikan penawaran.',
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red.shade700,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final analysis = widget.initialAnalysis;
    final isFromAnalysis = analysis != null;

    return Scaffold(
      appBar: PlasvoraHeader(
        customTitle: isFromAnalysis ? 'Jual Material Ini' : 'Tawarkan Material',
        showBack: true,
        onBack: () => Navigator.of(context).pop(),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ─── Foto preview analisis ─────────────────────────────
              if (isFromAnalysis) ...[
                _buildAnalysisPhotoPreview(analysis),
                const SizedBox(height: 16),
              ],

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
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Nama Material *',
                  hintText: 'contoh: Tutup Botol HDPE',
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Nama material wajib diisi.';
                  if (v.trim().length < 3) return 'Nama material minimal 3 karakter.';
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
                    .map((c) => DropdownMenuItem(
                          value: c,
                          child: Text(c == 'MIXED' ? 'Campuran (MIXED)' : c),
                        ))
                    .toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedCategory = val);
                },
              ),
              const SizedBox(height: 12),

              // Berat — TIDAK di-prefill, user harus memasukkan
              TextFormField(
                controller: _weightCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
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
                  if (v == null || v.trim().isEmpty) return 'Berat material wajib diisi.';
                  final w = double.tryParse(v.trim());
                  if (w == null || w < 0.01) return 'Berat harus lebih dari 0 kg.';
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
                    .map((c) => DropdownMenuItem(
                          value: c,
                          child: Text(_conditionLabels[c] ?? c),
                        ))
                    .toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedCondition = val);
                },
              ),
              const SizedBox(height: 12),

              // Lokasi — tidak di-prefill, user harus memasukkan
              TextFormField(
                controller: _locationCtrl,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Lokasi Umum *',
                  hintText: 'contoh: Kota Bandung',
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Lokasi wajib diisi.';
                  if (v.trim().length < 3) return 'Lokasi minimal 3 karakter.';
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
                    onChanged: (val) {
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
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Harga (Rp) *',
                    hintText: 'contoh: 15000',
                  ),
                  validator: (v) {
                    if (_isFree) return null;
                    if (v == null || v.trim().isEmpty) return 'Harga wajib diisi jika tidak gratis.';
                    final p = num.tryParse(v.trim());
                    if (p == null || p <= 0) return 'Harga harus lebih dari 0.';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
              ],

              // Deskripsi
              TextFormField(
                controller: _descriptionCtrl,
                maxLines: 4,
                textInputAction: TextInputAction.done,
                decoration: const InputDecoration(
                  labelText: 'Deskripsi',
                  hintText: 'Informasi tambahan tentang material',
                  alignLabelWithHint: true,
                ),
                validator: (v) {
                  if (v != null && v.length > 2000) return 'Deskripsi maksimal 2000 karakter.';
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Tombol submit
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: const StadiumBorder(),
                    elevation: 4,
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          'Publikasikan Penawaran',
                          style: AppTypography.labelLg(color: Colors.white)
                              .copyWith(fontWeight: FontWeight.w700),
                        ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
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
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
