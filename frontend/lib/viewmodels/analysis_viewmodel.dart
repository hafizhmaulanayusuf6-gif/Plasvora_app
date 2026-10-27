import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

import '../models/plastic_analysis.dart';
import '../repositories/analysis_repository.dart';

class AnalysisViewModel extends ChangeNotifier {
  final AnalysisRepository analysisRepository;
  final ImagePicker _picker = ImagePicker();

  AnalysisViewModel({required this.analysisRepository});

  String? _imagePath;
  String? get imagePath => _imagePath;

  bool _hasImage = false;
  bool get hasImage => _hasImage;

  String? _polymerCategory;
  String? get polymerCategory => _polymerCategory;

  double _weightKg = 0.0;
  double get weightKg => _weightKg;

  String _condition = 'clean'; // 'clean', 'light', 'dirty'
  String get condition => _condition;

  String _notes = '';
  String get notes => _notes;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isSuccess = false;
  bool get isSuccess => _isSuccess;

  PlasticAnalysisResult? _analysisResult;
  PlasticAnalysisResult? get analysisResult => _analysisResult;

  Future<void> pickImageFromCamera() async {
    try {
      final XFile? file = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1080,
        maxHeight: 1080,
        imageQuality: 85,
      );
      if (file != null) {
        _imagePath = file.path;
        _hasImage = true;
      } else {
        // Fallback to sample for testing/demonstration if user cancelled
        _hasImage = true;
      }
    } catch (_) {
      // In simulator/desktop or if camera denied, activate preview with sample
      _hasImage = true;
    }
    notifyListeners();
  }

  Future<void> pickImageFromGallery() async {
    try {
      final XFile? file = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1080,
        maxHeight: 1080,
        imageQuality: 85,
      );
      if (file != null) {
        _imagePath = file.path;
        _hasImage = true;
      } else {
        // Fallback to sample for testing/demonstration if user cancelled
        _hasImage = true;
      }
    } catch (_) {
      // In simulator/desktop or if permission denied, activate preview with sample
      _hasImage = true;
    }
    notifyListeners();
  }

  void resetImage() {
    _imagePath = null;
    _hasImage = false;
    notifyListeners();
  }

  void setPolymer(String? val) {
    _polymerCategory = val;
    notifyListeners();
  }

  void setWeight(double val) {
    _weightKg = val < 0 ? 0.0 : val;
    notifyListeners();
  }

  void addWeightPreset(double delta) {
    _weightKg = double.parse((_weightKg + delta).toStringAsFixed(1));
    notifyListeners();
  }

  void setCondition(String val) {
    _condition = val;
    notifyListeners();
  }

  void setNotes(String val) {
    _notes = val;
    notifyListeners();
  }

  Future<PlasticAnalysisResult?> submitAnalysis() async {
    _isLoading = true;
    _isSuccess = false;
    notifyListeners();

    try {
      final input = PlasticAnalysisInput(
        imagePath: _imagePath,
        isCameraOrGallery: _imagePath != null,
        polymerCategory: _polymerCategory,
        weightKg: _weightKg > 0 ? _weightKg : 5.0,
        condition: _condition,
        notes: _notes,
      );

      final result = await analysisRepository.analyzePlastic(input);
      _analysisResult = result;
      _isSuccess = true;
      return result;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
