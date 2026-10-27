import 'dart:io';

import 'package:flutter/material.dart';

import '../../core/constants/app_assets.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/plasvora_header.dart';
import '../../viewmodels/analysis_viewmodel.dart';
import '../../viewmodels/navigation_viewmodel.dart';
import 'analysis_result_screen.dart';

class AnalysisScreen extends StatefulWidget {
  final AnalysisViewModel viewModel;
  final NavigationViewModel navigationViewModel;

  const AnalysisScreen({
    super.key,
    required this.viewModel,
    required this.navigationViewModel,
  });

  @override
  State<AnalysisScreen> createState() => _AnalysisScreenState();
}

class _AnalysisScreenState extends State<AnalysisScreen> {
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _weightController.text = widget.viewModel.weightKg > 0
        ? widget.viewModel.weightKg.toStringAsFixed(1)
        : '';
    _notesController.text = widget.viewModel.notes;
  }

  @override
  void dispose() {
    _weightController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const PlasvoraHeader(),
      body: ListenableBuilder(
        listenable: widget.viewModel,
        builder: (context, _) {
          return SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 32),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeaderSection(),
                  const SizedBox(height: 16),
                  _buildCaptureArea(),
                  const SizedBox(height: 24),
                  _buildFormSection(),
                  const SizedBox(height: 20),
                  _buildDisclaimerCard(),
                  const SizedBox(height: 24),
                  _buildSubmitButton(),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  /// Header with AI Model version badge
  Widget _buildHeaderSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.psychology, size: 16, color: AppColors.primary),
            const SizedBox(width: 4),
            Text(
              'COMPUTER VISION MODEL V2.4',
              style: AppTypography.labelSm(color: AppColors.primary)
                  .copyWith(fontWeight: FontWeight.w700, letterSpacing: 0.8),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          'Analisis Plastik Berbasis AI',
          style: AppTypography.headlineLgMobile(color: AppColors.onSurface),
        ),
        const SizedBox(height: 6),
        Text(
          'Unggah atau ambil foto material plastik Anda untuk mengidentifikasi polimer dan potensi pemanfaatannya.',
          style: AppTypography.bodyMd(color: AppColors.onSurfaceVariant),
        ),
      ],
    );
  }

  /// Photo capture / preview interactive dropzone
  Widget _buildCaptureArea() {
    final bool hasImage = widget.viewModel.hasImage;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A20312A),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: hasImage ? _buildPreviewView() : _buildDefaultCaptureView(),
    );
  }

  Widget _buildDefaultCaptureView() {
    return Column(
      children: [
        // Camera pulsating ring
        Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.secondaryContainer.withValues(alpha: 0.4),
                shape: BoxShape.circle,
              ),
            ),
            Container(
              width: 56,
              height: 56,
              decoration: const BoxDecoration(
                color: AppColors.secondaryContainer,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.photo_camera,
                size: 30,
                color: AppColors.primaryContainer,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          'Unggah Foto Material',
          style: AppTypography.headlineSm(color: AppColors.onSurface),
        ),
        const SizedBox(height: 4),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 280),
          child: Text(
            'Posisikan plastik di pencahayaan terang dan tampilkan label kode daur ulang jika ada.',
            textAlign: TextAlign.center,
            style: AppTypography.bodySm(color: AppColors.onSurfaceVariant),
          ),
        ),
        const SizedBox(height: 16),
        // Action buttons
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => widget.viewModel.pickImageFromCamera(),
                icon: const Icon(Icons.add_a_photo, size: 18),
                label: const Text('Ambil Foto'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryContainer,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(44),
                  shape: const StadiumBorder(),
                  textStyle: AppTypography.labelMd(color: Colors.white),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => widget.viewModel.pickImageFromGallery(),
                icon: const Icon(Icons.photo_library, size: 18),
                label: const Text('Dari Galeri'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.surfaceContainer,
                  foregroundColor: AppColors.primaryContainer,
                  minimumSize: const Size.fromHeight(44),
                  elevation: 0,
                  shape: const StadiumBorder(),
                  textStyle: AppTypography.labelMd(
                    color: AppColors.primaryContainer,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        const Divider(color: Color(0x1F707974), height: 1),
        const SizedBox(height: 12),
        // Guidelines strip
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildGuidelineItem(Icons.wb_sunny, 'Cahaya Alami'),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                '•',
                style: TextStyle(color: AppColors.outlineVariant),
              ),
            ),
            _buildGuidelineItem(Icons.center_focus_strong, 'Fokus Polimer'),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                '•',
                style: TextStyle(color: AppColors.outlineVariant),
              ),
            ),
            _buildGuidelineItem(Icons.clean_hands, 'Bebas Kotoran'),
          ],
        ),
      ],
    );
  }

  Widget _buildGuidelineItem(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: AppColors.primary),
        const SizedBox(width: 4),
        Text(
          text,
          style: AppTypography.labelSm(color: AppColors.onSurfaceVariant),
        ),
      ],
    );
  }

  Widget _buildPreviewView() {
    final imagePath = widget.viewModel.imagePath;

    return Column(
      children: [
        Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: AspectRatio(
                aspectRatio: 16 / 10,
                child: imagePath != null && File(imagePath).existsSync()
                    ? Image.file(File(imagePath), fit: BoxFit.cover)
                    : Image.asset(
                        AppAssets.bottleCapsPreview,
                        fit: BoxFit.cover,
                      ),
              ),
            ),
            Positioned(
              top: 10,
              right: 10,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => widget.viewModel.resetImage(),
                  borderRadius: BorderRadius.circular(999),
                  child: Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerLowest.withValues(
                        alpha: 0.9,
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.refresh,
                      size: 20,
                      color: AppColors.onSurface,
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 10,
              left: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.inverseSurface.withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: AppColors.primaryFixed,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Siap Dianalisis • 1080x1080px',
                      style: AppTypography.labelSm(
                        color: AppColors.inverseOnSurface,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          'Foto berhasil diambil. Anda dapat menambahkan data pendukung di bawah.',
          style: AppTypography.bodySm(color: AppColors.onSurfaceVariant),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  /// Form fields: Optional support data
  Widget _buildFormSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Data Pendukung Opsional',
              style: AppTypography.headlineSm(color: AppColors.onSurface),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainer,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                'Tingkatkan Akurasi',
                style: AppTypography.labelSm(color: AppColors.onSurfaceVariant),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Field 1: Polymer Type Dropdown
        Text(
          'Jenis Plastik (Jika Diketahui)',
          style: AppTypography.labelMd(color: AppColors.onSurface),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(14),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0620312A),
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: widget.viewModel.polymerCategory,
              isExpanded: true,
              hint: Text(
                'Belum tahu (Biarkan AI mendeteksi)',
                style: AppTypography.bodyMd(color: AppColors.outline),
              ),
              icon: const Icon(
                Icons.expand_more,
                color: AppColors.onSurfaceVariant,
              ),
              items: const [
                DropdownMenuItem(
                  value: null,
                  child: Text('Belum tahu (Biarkan AI mendeteksi)'),
                ),
                DropdownMenuItem(
                  value: '1',
                  child: Text('PET (1) - Botol Air Mineral, Kemasan Bening'),
                ),
                DropdownMenuItem(
                  value: '2',
                  child: Text('HDPE (2) - Botol Sampo, Tutup Botol Tebal'),
                ),
                DropdownMenuItem(
                  value: '3',
                  child: Text('PVC (3) - Pipa, Kabel Selang'),
                ),
                DropdownMenuItem(
                  value: '4',
                  child: Text('LDPE (4) - Kantong Kresek, Bubble Wrap'),
                ),
                DropdownMenuItem(
                  value: '5',
                  child: Text('PP (5) - Sedotan, Kotak Makanan Microwave'),
                ),
                DropdownMenuItem(
                  value: '6',
                  child: Text('PS (6) - Styrofoam, Sendok Plastik Putih'),
                ),
                DropdownMenuItem(
                  value: '7',
                  child: Text('Lainnya (7) - Campuran Multi-layer / ABS'),
                ),
              ],
              onChanged: (val) => widget.viewModel.setPolymer(val),
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Field 2: Weight input with shortcuts
        Text(
          'Estimasi Berat Material',
          style: AppTypography.labelMd(color: AppColors.onSurface),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: _weightController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          onChanged: (val) {
            final parsed = double.tryParse(val) ?? 0.0;
            widget.viewModel.setWeight(parsed);
          },
          decoration: InputDecoration(
            hintText: '0.0',
            prefixIcon: const Icon(
              Icons.scale_outlined,
              color: AppColors.secondary,
              size: 20,
            ),
            suffixIcon: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'kg',
                  style: AppTypography.labelMd(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _buildWeightShortcut('+1 kg', 1.0),
            const SizedBox(width: 8),
            _buildWeightShortcut('+5 kg', 5.0),
            const SizedBox(width: 8),
            _buildWeightShortcut('+10 kg', 10.0),
            const Spacer(),
            Text(
              'Pilih pintasan',
              style: AppTypography.bodySm(color: AppColors.onSurfaceVariant),
            ),
          ],
        ),
        const SizedBox(height: 18),
        // Field 3: Condition chips
        Text(
          'Kondisi Material Saat Ini',
          style: AppTypography.labelMd(color: AppColors.onSurface),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildConditionChip(
                conditionKey: 'clean',
                icon: Icons.verified,
                title: 'Bersih & Kering',
                subtitle: 'Grade A',
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildConditionChip(
                conditionKey: 'light',
                icon: Icons.water_drop,
                title: 'Sedikit Kotor',
                subtitle: 'Ada Debu',
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildConditionChip(
                conditionKey: 'dirty',
                icon: Icons.recycling,
                title: 'Belum Dicuci',
                subtitle: 'Residu Cair',
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        // Field 4: Notes
        Text(
          'Catatan Tambahan',
          style: AppTypography.labelMd(color: AppColors.onSurface),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: _notesController,
          maxLines: 3,
          maxLength: 200,
          onChanged: (val) => widget.viewModel.setNotes(val),
          decoration: const InputDecoration(
            hintText: 'Contoh: Tutup botol air mineral warna-warni tanpa label stiker...',
          ),
        ),
      ],
    );
  }

  Widget _buildWeightShortcut(String label, double add) {
    return InkWell(
      onTap: () {
        widget.viewModel.addWeightPreset(add);
        _weightController.text = widget.viewModel.weightKg.toStringAsFixed(1);
      },
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainer,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          style: AppTypography.labelSm(color: AppColors.primaryContainer)
              .copyWith(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget _buildConditionChip({
    required String conditionKey,
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    final bool isSelected = widget.viewModel.condition == conditionKey;

    return InkWell(
      onTap: () => widget.viewModel.setCondition(conditionKey),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.surfaceContainerHigh
              : AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(14),
          border: isSelected
              ? Border.all(color: AppColors.primaryContainer, width: 1.5)
              : null,
          boxShadow: const [
            BoxShadow(
              color: Color(0x0620312A),
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.secondaryContainer
                    : AppColors.surfaceContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 18,
                color: isSelected
                    ? AppColors.primaryContainer
                    : AppColors.secondary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              title,
              style: AppTypography.labelSm(color: AppColors.onSurface).copyWith(
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                fontSize: 11,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              subtitle,
              style: AppTypography.bodySm(color: AppColors.onSurfaceVariant)
                  .copyWith(fontSize: 10),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  /// Disclaimer verification card
  Widget _buildDisclaimerCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerHigh.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: const BoxDecoration(
              color: AppColors.surfaceContainerLowest,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.info_outline,
              size: 18,
              color: AppColors.secondary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Catatan Verifikasi AI',
                  style: AppTypography.labelMd(color: AppColors.onSurface),
                ),
                const SizedBox(height: 2),
                Text(
                  'Hasil identifikasi dari foto merupakan perkiraan otomatis. Disarankan verifikasi fisik sebelum pengolahan skala besar.',
                  style: AppTypography.bodySm(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Sticky-feel Primary Call to action
  Widget _buildSubmitButton() {
    final bool isLoading = widget.viewModel.isLoading;

    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton(
            onPressed: isLoading
                ? null
                : () async {
                    final result = await widget.viewModel.submitAnalysis();
                    if (result != null && mounted) {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => AnalysisResultScreen(
                            result: result,
                            navigationViewModel: widget.navigationViewModel,
                          ),
                        ),
                      );
                    }
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryContainer,
              foregroundColor: Colors.white,
              shape: const StadiumBorder(),
              elevation: 4,
              shadowColor: const Color(0x33205B46),
            ),
            child: isLoading
                ? const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      ),
                      SizedBox(width: 12),
                      Text('Menganalisis Polimer...'),
                    ],
                  )
                : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.auto_awesome, size: 20),
                      SizedBox(width: 8),
                      Text('Analisis Material'),
                      SizedBox(width: 6),
                      Icon(Icons.arrow_forward, size: 18),
                    ],
                  ),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.security, size: 14, color: AppColors.primary),
            const SizedBox(width: 4),
            Text(
              'Pemrosesan citra aman & tidak disebarluaskan',
              style: AppTypography.labelSm(color: AppColors.onSurfaceVariant),
            ),
          ],
        ),
      ],
    );
  }
}
