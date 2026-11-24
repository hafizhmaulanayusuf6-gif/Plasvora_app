import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/video_link_validator.dart';
import '../../core/widgets/simple_page_app_bar.dart';
import '../../models/gallery_work.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/gallery_viewmodel.dart';
import 'gallery_widgets.dart';
import 'my_gallery_works_screen.dart';

class CreateGalleryWorkScreen extends StatefulWidget {
  final GalleryViewModel viewModel;
  final AuthViewModel? authViewModel;
  final GalleryWork? existingWork;
  final GalleryWorkDraft? initialDraft;

  /// Optional test seam for picking image file paths without platform channels.
  final Future<List<String>> Function(int remainingSlots)? imagePickerOverride;

  const CreateGalleryWorkScreen({
    super.key,
    required this.viewModel,
    this.authViewModel,
    this.existingWork,
    this.initialDraft,
    this.imagePickerOverride,
  });

  @override
  State<CreateGalleryWorkScreen> createState() =>
      _CreateGalleryWorkScreenState();
}

class _CreateGalleryWorkScreenState extends State<CreateGalleryWorkScreen> {
  static const int _maxImages = 5;
  static const int _maxListItems = 30;
  static const int _maxVideoLinks = 3;

  final ImagePicker _picker = ImagePicker();
  final TextEditingController _titleController = TextEditingController();

  late GalleryDifficulty _difficulty;
  late List<TextEditingController> _materialControllers;
  late List<TextEditingController> _toolControllers;
  late List<TextEditingController> _stepControllers;
  late List<TextEditingController> _videoControllers;

  late List<GalleryImage> _existingImages;
  final List<int> _removedImageIds = [];
  final List<String> _newImagePaths = [];

  bool _ownershipConfirmed = false;
  bool _hasUnsavedChanges = false;
  bool _isSubmitted = false;
  bool _isSubmittingLocal = false;

  // Client-side validation error strings
  String? _imagesError;
  String? _titleError;
  String? _materialsError;
  String? _stepsError;
  String? _ownershipError;
  final Map<int, String> _videoLinkErrors = {};

  bool get _isEdit => widget.existingWork != null;

  int get _totalImageCount => _existingImages.length + _newImagePaths.length;

  bool get _hasValidRequiredFields {
    if (_totalImageCount < 1 || _totalImageCount > _maxImages) {
      return false;
    }

    final title = _titleController.text.trim();
    if (title.length < 3 || title.length > 120) {
      return false;
    }

    final hasMaterial =
        _materialControllers.any((c) => c.text.trim().isNotEmpty);
    if (!hasMaterial) return false;

    final hasStep = _stepControllers.any((c) => c.text.trim().isNotEmpty);
    if (!hasStep) return false;

    for (final c in _videoControllers) {
      final raw = c.text.trim();
      if (raw.isNotEmpty && !VideoLinkValidator.isValid(raw)) {
        return false;
      }
    }

    return true;
  }

  bool get _canSubmit =>
      _hasValidRequiredFields && (_isEdit || _ownershipConfirmed);

  @override
  void initState() {
    super.initState();
    widget.viewModel.clearSubmitErrors();

    final work = widget.existingWork;
    final draft = widget.initialDraft;

    if (work != null) {
      _titleController.text = work.title;
      _difficulty = work.difficulty;
      _materialControllers = _initControllers(work.materials, minOne: true);
      _toolControllers = _initControllers(work.tools, minOne: false);
      _stepControllers = _initControllers(work.steps, minOne: true);
      _videoControllers = _initControllers(work.videoLinks, minOne: false);
      _existingImages = List<GalleryImage>.from(work.images);
      _ownershipConfirmed = true;
    } else if (draft != null) {
      _titleController.text = draft.title;
      _difficulty = draft.difficulty;
      _materialControllers = _initControllers(draft.materials, minOne: true);
      _toolControllers = _initControllers(draft.tools, minOne: false);
      _stepControllers = _initControllers(draft.steps, minOne: true);
      _videoControllers = _initControllers(draft.videoLinks, minOne: false);
      // Never prefill photos from AI analysis
      _existingImages = [];
      _hasUnsavedChanges = true;
    } else {
      _difficulty = GalleryDifficulty.mudah;
      _materialControllers = [TextEditingController()];
      _toolControllers = [];
      _stepControllers = [TextEditingController()];
      _videoControllers = [];
      _existingImages = [];
    }

    _titleController.addListener(_markDirty);
  }

  List<TextEditingController> _initControllers(
    List<String> values, {
    required bool minOne,
  }) {
    if (values.isEmpty) {
      return minOne ? [TextEditingController()] : [];
    }
    return values.map((v) => TextEditingController(text: v)).toList();
  }

  void _markDirty() {
    if (!_hasUnsavedChanges) {
      _hasUnsavedChanges = true;
    }
  }

  @override
  void dispose() {
    _titleController.removeListener(_markDirty);
    _titleController.dispose();
    for (final c in _materialControllers) {
      c.dispose();
    }
    for (final c in _toolControllers) {
      c.dispose();
    }
    for (final c in _stepControllers) {
      c.dispose();
    }
    for (final c in _videoControllers) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _handleBackAttempt() async {
    if (!_hasUnsavedChanges || _isSubmitted) {
      Navigator.of(context).pop();
      return;
    }

    final shouldLeave = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Batalkan Perubahan?'),
        content: Text(
          'Perubahan yang belum disimpan akan hilang jika Anda keluar dari halaman ini.',
          style: AppTypography.bodySm(color: AppColors.onSurfaceVariant),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(false),
            child: const Text('Lanjutkan Mengisi'),
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

    if (shouldLeave == true && mounted) {
      setState(() => _isSubmitted = true);
      Navigator.of(context).pop();
    }
  }

  Future<void> _pickImages() async {
    final remaining = _maxImages - _totalImageCount;
    if (remaining <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Maksimal 5 foto karya sudah tercapai.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (widget.imagePickerOverride != null) {
      final picked = await widget.imagePickerOverride!(remaining);
      if (!mounted || picked.isEmpty) return;
      setState(() {
        _newImagePaths.addAll(picked.take(remaining));
        _imagesError = null;
        _hasUnsavedChanges = true;
      });
      return;
    }

    final source = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(
                  Icons.photo_library_outlined,
                  color: AppColors.primary,
                ),
                title: const Text('Pilih dari Galeri'),
                subtitle: Text('Dapat memilih hingga $remaining foto'),
                onTap: () => Navigator.of(sheetCtx).pop('gallery'),
              ),
              ListTile(
                leading: const Icon(
                  Icons.photo_camera_outlined,
                  color: AppColors.primary,
                ),
                title: const Text('Ambil Foto dengan Kamera'),
                onTap: () => Navigator.of(sheetCtx).pop('camera'),
              ),
            ],
          ),
        ),
      ),
    );

    if (source == null || !mounted) return;

    try {
      if (source == 'camera') {
        final file = await _picker.pickImage(
          source: ImageSource.camera,
          maxWidth: 1600,
          imageQuality: 85,
        );
        if (file != null && mounted) {
          setState(() {
            _newImagePaths.add(file.path);
            _imagesError = null;
            _hasUnsavedChanges = true;
          });
        }
      } else {
        final files = await _picker.pickMultiImage(
          maxWidth: 1600,
          imageQuality: 85,
          limit: remaining > 1 ? remaining : null,
        );
        if (files.isNotEmpty && mounted) {
          setState(() {
            _newImagePaths.addAll(files.take(remaining).map((f) => f.path));
            _imagesError = null;
            _hasUnsavedChanges = true;
          });
        }
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gagal membuka pemilih foto. Periksa izin perangkat.'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _removeExistingImage(GalleryImage img) {
    if (_totalImageCount <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Karya harus memiliki minimal 1 foto. Tambahkan foto baru terlebih dahulu sebelum menghapus foto terakhir.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    setState(() {
      _existingImages.removeWhere((e) => e.id == img.id);
      if (!_removedImageIds.contains(img.id)) {
        _removedImageIds.add(img.id);
      }
      _hasUnsavedChanges = true;
    });
  }

  void _removeNewImage(int index) {
    setState(() {
      _newImagePaths.removeAt(index);
      _hasUnsavedChanges = true;
    });
  }

  void _addMaterial() {
    if (_materialControllers.length >= _maxListItems) return;
    setState(() {
      _materialControllers.add(TextEditingController());
      _hasUnsavedChanges = true;
    });
  }

  void _removeMaterial(int index) {
    if (_materialControllers.length <= 1) {
      setState(() {
        _materialControllers.first.clear();
        _hasUnsavedChanges = true;
      });
      return;
    }
    setState(() {
      final ctrl = _materialControllers.removeAt(index);
      ctrl.dispose();
      _hasUnsavedChanges = true;
    });
  }

  void _addTool() {
    if (_toolControllers.length >= _maxListItems) return;
    setState(() {
      _toolControllers.add(TextEditingController());
      _hasUnsavedChanges = true;
    });
  }

  void _removeTool(int index) {
    setState(() {
      final ctrl = _toolControllers.removeAt(index);
      ctrl.dispose();
      _hasUnsavedChanges = true;
    });
  }

  void _addStep() {
    if (_stepControllers.length >= _maxListItems) return;
    setState(() {
      _stepControllers.add(TextEditingController());
      _hasUnsavedChanges = true;
    });
  }

  void _removeStep(int index) {
    if (_stepControllers.length <= 1) {
      setState(() {
        _stepControllers.first.clear();
        _hasUnsavedChanges = true;
      });
      return;
    }
    setState(() {
      final ctrl = _stepControllers.removeAt(index);
      ctrl.dispose();
      _hasUnsavedChanges = true;
    });
  }

  void _moveStep(int index, int delta) {
    final target = index + delta;
    if (target < 0 || target >= _stepControllers.length) return;
    setState(() {
      final item = _stepControllers.removeAt(index);
      _stepControllers.insert(target, item);
      _hasUnsavedChanges = true;
    });
  }

  void _addVideoLink() {
    if (_videoControllers.length >= _maxVideoLinks) return;
    setState(() {
      _videoControllers.add(TextEditingController());
      _hasUnsavedChanges = true;
    });
  }

  void _removeVideoLink(int index) {
    setState(() {
      final ctrl = _videoControllers.removeAt(index);
      ctrl.dispose();
      _videoLinkErrors.clear();
      _hasUnsavedChanges = true;
    });
  }

  bool _validateForm() {
    String? imagesErr;
    String? titleErr;
    String? materialsErr;
    String? stepsErr;
    String? ownershipErr;
    final videoErrors = <int, String>{};

    if (_totalImageCount < 1) {
      imagesErr = 'Minimal 1 foto karya wajib diunggah.';
    } else if (_totalImageCount > _maxImages) {
      imagesErr = 'Maksimal 5 foto karya.';
    }

    final title = _titleController.text.trim();
    if (title.isEmpty) {
      titleErr = 'Nama karya wajib diisi.';
    } else if (title.length < 3) {
      titleErr = 'Nama karya minimal 3 karakter.';
    } else if (title.length > 120) {
      titleErr = 'Nama karya maksimal 120 karakter.';
    }

    final materials = _materialControllers
        .map((c) => c.text.trim())
        .where((s) => s.isNotEmpty)
        .toList();
    if (materials.isEmpty) {
      materialsErr = 'Minimal satu bahan wajib diisi.';
    }

    final steps = _stepControllers
        .map((c) => c.text.trim())
        .where((s) => s.isNotEmpty)
        .toList();
    if (steps.isEmpty) {
      stepsErr = 'Minimal satu langkah pembuatan wajib diisi.';
    }

    for (var i = 0; i < _videoControllers.length; i++) {
      final raw = _videoControllers[i].text.trim();
      if (raw.isEmpty) continue;
      final err = VideoLinkValidator.validate(raw);
      if (err != null) {
        videoErrors[i] = err;
      }
    }

    if (!_isEdit && !_ownershipConfirmed) {
      ownershipErr = 'Anda wajib menyetujui pernyataan kepemilikan karya.';
    }

    setState(() {
      _imagesError = imagesErr;
      _titleError = titleErr;
      _materialsError = materialsErr;
      _stepsError = stepsErr;
      _ownershipError = ownershipErr;
      _videoLinkErrors
        ..clear()
        ..addAll(videoErrors);
    });

    return imagesErr == null &&
        titleErr == null &&
        materialsErr == null &&
        stepsErr == null &&
        ownershipErr == null &&
        videoErrors.isEmpty;
  }

  Future<void> _submit() async {
    if (_isSubmittingLocal || widget.viewModel.isSubmitting) return;
    if (!_validateForm()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Periksa kembali data karya yang masih belum lengkap.'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isSubmittingLocal = true);

    final materials = _materialControllers
        .map((c) => c.text.trim())
        .where((s) => s.isNotEmpty)
        .toList();
    final tools = _toolControllers
        .map((c) => c.text.trim())
        .where((s) => s.isNotEmpty)
        .toList();
    final steps = _stepControllers
        .map((c) => c.text.trim())
        .where((s) => s.isNotEmpty)
        .toList();
    final videoLinks = _videoControllers
        .map((c) => c.text.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    try {
      if (_isEdit) {
        final updated = await widget.viewModel.updateWork(
          id: widget.existingWork!.id,
          title: _titleController.text.trim(),
          difficulty: _difficulty,
          materials: materials,
          tools: tools,
          steps: steps,
          videoLinks: videoLinks,
          newImagePaths: List<String>.from(_newImagePaths),
          removeImageIds: List<int>.from(_removedImageIds),
        );

        if (!mounted) return;
        if (updated != null) {
          _isSubmitted = true;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Perubahan karya berhasil disimpan.'),
              behavior: SnackBarBehavior.floating,
            ),
          );
          Navigator.of(context).pop(true);
        }
      } else {
        final created = await widget.viewModel.createWork(
          title: _titleController.text.trim(),
          difficulty: _difficulty,
          materials: materials,
          tools: tools,
          steps: steps,
          videoLinks: videoLinks,
          imagePaths: List<String>.from(_newImagePaths),
          ownershipConfirmed: _ownershipConfirmed,
        );

        if (!mounted) return;
        if (created != null) {
          _isSubmitted = true;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Karya berhasil diposting dan sekarang tampil di Galeri!',
              ),
              behavior: SnackBarBehavior.floating,
            ),
          );
          await Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => MyGalleryWorksScreen(
                viewModel: widget.viewModel,
                authViewModel: widget.authViewModel,
              ),
            ),
          );
        }
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmittingLocal = false);
      }
    }
  }

  String? _backendError(Map<String, String> fieldErrors, String prefix) {
    if (fieldErrors.containsKey(prefix)) return fieldErrors[prefix];
    for (final entry in fieldErrors.entries) {
      if (entry.key.startsWith('$prefix.')) return entry.value;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_hasUnsavedChanges || _isSubmitted,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          _handleBackAttempt();
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.surface,
        appBar: SimplePageAppBar(
          title: _isEdit ? 'Edit Karya' : 'Bagikan Karya',
          onBack: _handleBackAttempt,
        ),
        body: SafeArea(
          top: false,
          child: ListenableBuilder(
            listenable: widget.viewModel,
            builder: (context, _) {
              final vm = widget.viewModel;
              final fieldErrors = vm.fieldErrors;
              final isBusy = _isSubmittingLocal || vm.isSubmitting;

              final imgErr = _imagesError ?? _backendError(fieldErrors, 'images');
              final titleErr =
                  _titleError ?? _backendError(fieldErrors, 'title');
              final matErr =
                  _materialsError ?? _backendError(fieldErrors, 'materials');
              final toolErr = _backendError(fieldErrors, 'tools');
              final stepErr =
                  _stepsError ?? _backendError(fieldErrors, 'steps');
              final videoGeneralErr = _backendError(fieldErrors, 'video_links');
              final ownerErr = _ownershipError ??
                  _backendError(fieldErrors, 'ownership_confirmed');

              return SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (vm.submitError != null) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF1F2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.error.withValues(alpha: 0.4),
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.error_outline_rounded,
                              size: 20,
                              color: AppColors.error,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                vm.submitError!,
                                style: AppTypography.bodySm(
                                  color: AppColors.error,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    if (widget.initialDraft != null && !_isEdit) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: AppColors.secondaryContainer.withValues(
                            alpha: 0.5,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.25),
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.auto_awesome_outlined,
                              size: 18,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Draf terisi dari ide daur ulang AI. Unggah foto karya jadi buatan Anda sendiri dan sesuaikan langkahnya.',
                                style: AppTypography.bodySm(
                                  color: AppColors.onSurface,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    // 1. Photos
                    _FormSectionCard(
                      title: 'Foto Karya *',
                      subtitle:
                          'Unggah 1–5 foto hasil karya jadi (JPG, PNG, WebP, maks. 4 MB). Foto pertama menjadi sampul.',
                      errorText: imgErr,
                      child: _buildPhotosSection(),
                    ),
                    const SizedBox(height: 16),

                    // 2. Title
                    _FormSectionCard(
                      title: 'Nama Karya *',
                      errorText: titleErr,
                      child: TextField(
                        controller: _titleController,
                        maxLength: 120,
                        decoration: _inputDecoration(
                          'Contoh: Pot Hidroponik Mini dari Botol PET',
                        ),
                        onChanged: (_) {
                          setState(() {
                            _hasUnsavedChanges = true;
                            _titleError = null;
                          });
                        },
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 3. Difficulty
                    _FormSectionCard(
                      title: 'Tingkat Kesulitan *',
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: GalleryDifficulty.values.map((diff) {
                          final selected = _difficulty == diff;
                          return ChoiceChip(
                            label: Text(diff.label),
                            selected: selected,
                            onSelected: (_) {
                              setState(() {
                                _difficulty = diff;
                                _hasUnsavedChanges = true;
                              });
                            },
                            selectedColor: AppColors.primary,
                            backgroundColor: AppColors.surfaceContainerLow,
                            checkmarkColor: Colors.white,
                            labelStyle: AppTypography.labelMd(
                              color:
                                  selected ? Colors.white : AppColors.onSurface,
                            ),
                            shape: const StadiumBorder(),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 4. Materials (required, min 1)
                    _FormSectionCard(
                      title: 'Bahan *',
                      subtitle: 'Sebutkan bahan plastik dan pendukung yang dipakai.',
                      errorText: matErr,
                      child: _buildDynamicTextList(
                        controllers: _materialControllers,
                        hintPrefix: 'Contoh: Botol plastik PET 1,5L',
                        addLabel: 'Tambah Bahan',
                        onAdd: _addMaterial,
                        onRemove: _removeMaterial,
                        allowEmpty: false,
                        maxLength: 100,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 5. Tools (optional)
                    _FormSectionCard(
                      title: 'Alat (Opsional)',
                      subtitle: 'Tambahkan alat kerja jika diperlukan.',
                      errorText: toolErr,
                      child: _buildDynamicTextList(
                        controllers: _toolControllers,
                        hintPrefix: 'Contoh: Gunting / Cutter',
                        addLabel: 'Tambah Alat',
                        onAdd: _addTool,
                        onRemove: _removeTool,
                        allowEmpty: true,
                        maxLength: 100,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 6. Ordered Steps (required, min 1)
                    _FormSectionCard(
                      title: 'Langkah-Langkah *',
                      subtitle:
                          'Tulis urutan pengerjaan secara jelas. Anda dapat mengubah urutan langkah.',
                      errorText: stepErr,
                      child: _buildStepsList(),
                    ),
                    const SizedBox(height: 16),

                    // 7. Video Links (optional, max 3)
                    _FormSectionCard(
                      title: 'Tautan Video Tutorial (Opsional)',
                      subtitle:
                          'Maksimal 3 tautan HTTPS dari YouTube, TikTok, atau Instagram.',
                      errorText: videoGeneralErr,
                      child: _buildVideoLinksList(fieldErrors),
                    ),
                    const SizedBox(height: 16),

                    // 8. Ownership Confirmation
                    if (!_isEdit) ...[
                      _buildOwnershipSection(ownerErr),
                      const SizedBox(height: 24),
                    ] else
                      const SizedBox(height: 8),

                    // Primary Submit Button
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: (isBusy || !_canSubmit) ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor:
                              AppColors.primary.withValues(alpha: 0.35),
                          disabledForegroundColor:
                              Colors.white.withValues(alpha: 0.85),
                          minimumSize: const Size(double.infinity, 52),
                          shape: const StadiumBorder(),
                        ),
                        child: isBusy
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                _isEdit ? 'Simpan Perubahan' : 'Posting',
                                style: AppTypography.labelLg(
                                  color: Colors.white,
                                ).copyWith(fontWeight: FontWeight.w700),
                              ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildPhotosSection() {
    final tiles = <Widget>[];
    var visualIndex = 0;

    for (final img in _existingImages) {
      final isCover = visualIndex == 0;
      visualIndex++;
      tiles.add(
        _PhotoPreviewTile(
          imageUrlOrPath: img.url,
          isCover: isCover,
          onRemove: () => _removeExistingImage(img),
        ),
      );
    }

    for (var i = 0; i < _newImagePaths.length; i++) {
      final isCover = visualIndex == 0;
      visualIndex++;
      final idx = i;
      tiles.add(
        _PhotoPreviewTile(
          imageUrlOrPath: _newImagePaths[idx],
          isCover: isCover,
          onRemove: () => _removeNewImage(idx),
        ),
      );
    }

    if (_totalImageCount < _maxImages) {
      tiles.add(
        InkWell(
          onTap: _pickImages,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.45),
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.add_a_photo_outlined,
                  color: AppColors.primary,
                  size: 24,
                ),
                const SizedBox(height: 4),
                Text(
                  'Tambah Foto',
                  textAlign: TextAlign.center,
                  style: AppTypography.labelSm(color: AppColors.primary),
                ),
                Text(
                  '$_totalImageCount/$_maxImages',
                  style: AppTypography.labelSm(
                    color: AppColors.onSurfaceVariant,
                  ).copyWith(fontSize: 10),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: tiles,
    );
  }

  Widget _buildDynamicTextList({
    required List<TextEditingController> controllers,
    required String hintPrefix,
    required String addLabel,
    required VoidCallback onAdd,
    required ValueChanged<int> onRemove,
    required bool allowEmpty,
    required int maxLength,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...List.generate(controllers.length, (index) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controllers[index],
                    maxLength: maxLength,
                    decoration: _inputDecoration(
                      index == 0 ? hintPrefix : 'Item ${index + 1}',
                    ).copyWith(counterText: ''),
                    onChanged: (_) {
                      setState(() {
                        _markDirty();
                        if (!allowEmpty) {
                          _materialsError = null;
                        }
                      });
                    },
                  ),
                ),
                if (allowEmpty || controllers.length > 1)
                  IconButton(
                    tooltip: 'Hapus item',
                    onPressed: () => onRemove(index),
                    icon: const Icon(
                      Icons.close_rounded,
                      color: AppColors.textSecondary,
                      size: 20,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 44,
                      minHeight: 44,
                    ),
                  ),
              ],
            ),
          );
        }),
        if (controllers.length < _maxListItems)
          TextButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add_rounded, size: 18),
            label: Text(addLabel),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            ),
          ),
      ],
    );
  }

  Widget _buildStepsList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...List.generate(_stepControllers.length, (index) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.secondaryContainer,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          'Langkah ${index + 1}',
                          style: AppTypography.labelSm(
                            color: AppColors.primary,
                          ).copyWith(fontWeight: FontWeight.w700),
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        tooltip: 'Naikkan langkah',
                        onPressed:
                            index > 0 ? () => _moveStep(index, -1) : null,
                        icon: const Icon(Icons.arrow_upward_rounded, size: 18),
                        constraints: const BoxConstraints(
                          minWidth: 36,
                          minHeight: 36,
                        ),
                      ),
                      IconButton(
                        tooltip: 'Turunkan langkah',
                        onPressed: index < _stepControllers.length - 1
                            ? () => _moveStep(index, 1)
                            : null,
                        icon:
                            const Icon(Icons.arrow_downward_rounded, size: 18),
                        constraints: const BoxConstraints(
                          minWidth: 36,
                          minHeight: 36,
                        ),
                      ),
                      if (_stepControllers.length > 1)
                        IconButton(
                          tooltip: 'Hapus langkah',
                          onPressed: () => _removeStep(index),
                          icon: const Icon(
                            Icons.delete_outline_rounded,
                            size: 18,
                            color: AppColors.error,
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 36,
                            minHeight: 36,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _stepControllers[index],
                    maxLines: 3,
                    minLines: 2,
                    maxLength: 1000,
                    decoration: _inputDecoration(
                      'Jelaskan langkah ${index + 1} secara ringkas dan jelas...',
                    ).copyWith(counterText: ''),
                    onChanged: (_) {
                      setState(() {
                        _markDirty();
                        _stepsError = null;
                      });
                    },
                  ),
                ],
              ),
            ),
          );
        }),
        if (_stepControllers.length < _maxListItems)
          TextButton.icon(
            onPressed: _addStep,
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('Tambah Langkah'),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            ),
          ),
      ],
    );
  }

  Widget _buildVideoLinksList(Map<String, String> fieldErrors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...List.generate(_videoControllers.length, (index) {
          final err =
              _videoLinkErrors[index] ?? fieldErrors['video_links.$index'];
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _videoControllers[index],
                        keyboardType: TextInputType.url,
                        decoration: _inputDecoration(
                          'https://www.youtube.com/watch?v=...',
                        ),
                        onChanged: (_) {
                          setState(() {
                            _markDirty();
                            _videoLinkErrors.remove(index);
                          });
                        },
                      ),
                    ),
                    IconButton(
                      tooltip: 'Hapus tautan video',
                      onPressed: () => _removeVideoLink(index),
                      icon: const Icon(
                        Icons.close_rounded,
                        color: AppColors.textSecondary,
                        size: 20,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 44,
                        minHeight: 44,
                      ),
                    ),
                  ],
                ),
                if (err != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    err,
                    style: AppTypography.bodySm(color: AppColors.error),
                  ),
                ],
              ],
            ),
          );
        }),
        if (_videoControllers.length < _maxVideoLinks)
          TextButton.icon(
            onPressed: _addVideoLink,
            icon: const Icon(Icons.add_link_rounded, size: 18),
            label: Text(
              'Tambah Tautan Video (${_videoControllers.length}/$_maxVideoLinks)',
            ),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            ),
          ),
      ],
    );
  }

  Widget _buildOwnershipSection(String? ownerErr) {
    if (_isEdit) {
      return const SizedBox.shrink();
    }

    final showOwnershipValidation = !_ownershipConfirmed;
    final highlightError =
        ownerErr != null || (_hasValidRequiredFields && !_ownershipConfirmed);
    final validationMessage = ownerErr ??
        (showOwnershipValidation
            ? 'Anda wajib menyetujui pernyataan kepemilikan karya.'
            : null);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: highlightError
              ? AppColors.error
              : AppColors.outlineVariant.withValues(alpha: 0.45),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CheckboxListTile(
            value: _ownershipConfirmed,
            onChanged: (value) {
              setState(() {
                _ownershipConfirmed = value ?? false;
                _ownershipError = _ownershipConfirmed
                    ? null
                    : 'Anda wajib menyetujui pernyataan kepemilikan karya.';
                _hasUnsavedChanges = true;
              });
            },
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            activeColor: AppColors.primary,
            title: Text(
              'Saya menyatakan bahwa karya dan foto ini adalah milik saya sendiri serta aman dibagikan ke komunitas Plasvora.',
              style: AppTypography.bodySm(color: AppColors.onSurface).copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          if (validationMessage != null) ...[
            const SizedBox(height: 4),
            Text(
              validationMessage,
              style: AppTypography.bodySm(
                color: highlightError
                    ? AppColors.error
                    : AppColors.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: AppTypography.bodySm(color: AppColors.textSecondary),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: AppColors.outlineVariant.withValues(alpha: 0.7),
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: AppColors.outlineVariant.withValues(alpha: 0.7),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
    );
  }
}

class _FormSectionCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String? errorText;
  final Widget child;

  const _FormSectionCard({
    required this.title,
    this.subtitle,
    this.errorText,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: errorText != null
              ? AppColors.error.withValues(alpha: 0.7)
              : AppColors.outlineVariant.withValues(alpha: 0.45),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTypography.labelLg(color: AppColors.onSurface).copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle!,
              style: AppTypography.bodySm(color: AppColors.onSurfaceVariant),
            ),
          ],
          const SizedBox(height: 12),
          child,
          if (errorText != null) ...[
            const SizedBox(height: 8),
            Text(
              errorText!,
              style: AppTypography.bodySm(color: AppColors.error),
            ),
          ],
        ],
      ),
    );
  }
}

class _PhotoPreviewTile extends StatelessWidget {
  final String imageUrlOrPath;
  final bool isCover;
  final VoidCallback onRemove;

  const _PhotoPreviewTile({
    required this.imageUrlOrPath,
    required this.isCover,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 96,
      height: 96,
      child: Stack(
        fit: StackFit.expand,
        children: [
          GalleryPhotoBox(
            imageUrlOrPath: imageUrlOrPath,
            width: 96,
            height: 96,
            borderRadius: BorderRadius.circular(12),
          ),
          if (isCover)
            Positioned(
              left: 6,
              bottom: 6,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.92),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Sampul',
                  style: AppTypography.labelSm(color: Colors.white).copyWith(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          Positioned(
            top: 4,
            right: 4,
            child: Semantics(
              button: true,
              label: 'Hapus foto',
              child: Material(
                color: Colors.black.withValues(alpha: 0.65),
                shape: const CircleBorder(),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: onRemove,
                  child: const Padding(
                    padding: EdgeInsets.all(5),
                    child: Icon(
                      Icons.close_rounded,
                      size: 16,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
