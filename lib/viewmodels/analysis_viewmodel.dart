import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

import '../core/network/api_client.dart';
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

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  PlasticAnalysisResult? _analysisResult;
  PlasticAnalysisResult? get analysisResult => _analysisResult;

  int _sessionVersion = 0;
  bool _disposed = false;

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  void _safeNotifyListeners() {
    if (!_disposed) {
      notifyListeners();
    }
  }

  void clearUserData() {
    _sessionVersion++;
    final hadState =
        _imagePath != null ||
        _hasImage ||
        _polymerCategory != null ||
        _weightKg != 0.0 ||
        _condition != 'clean' ||
        _notes.isNotEmpty ||
        _isLoading ||
        _isSuccess ||
        _errorMessage != null ||
        _analysisResult != null;

    _imagePath = null;
    _hasImage = false;
    _polymerCategory = null;
    _weightKg = 0.0;
    _condition = 'clean';
    _notes = '';
    _isLoading = false;
    _isSuccess = false;
    _errorMessage = null;
    _analysisResult = null;

    if (hadState) {
      _safeNotifyListeners();
    }
  }

  Future<void> pickImageFromCamera() async {
    final version = _sessionVersion;
    try {
      final XFile? file = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1080,
        maxHeight: 1080,
        imageQuality: 85,
      );
      if (version != _sessionVersion || _disposed) return;
      if (file != null) {
        _imagePath = file.path;
        _hasImage = true;
      }
    } catch (_) {
      // Ignore or handle permission denial
    }
    if (version == _sessionVersion) {
      _safeNotifyListeners();
    }
  }

  Future<void> pickImageFromGallery() async {
    final version = _sessionVersion;
    try {
      final XFile? file = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1080,
        maxHeight: 1080,
        imageQuality: 85,
      );
      if (version != _sessionVersion || _disposed) return;
      if (file != null) {
        _imagePath = file.path;
        _hasImage = true;
      }
    } catch (_) {
      // Ignore or handle permission denial
    }
    if (version == _sessionVersion) {
      _safeNotifyListeners();
    }
  }

  void resetImage() {
    _imagePath = null;
    _hasImage = false;
    _safeNotifyListeners();
  }

  void setPolymer(String? val) {
    _polymerCategory = PlasticCategory.normalizeForApi(val);
    _safeNotifyListeners();
  }

  void setWeight(double val) {
    _weightKg = val < 0 ? 0.0 : val;
    _safeNotifyListeners();
  }

  void addWeightPreset(double delta) {
    _weightKg = double.parse((_weightKg + delta).toStringAsFixed(1));
    _safeNotifyListeners();
  }

  void setCondition(String val) {
    _condition = val;
    _safeNotifyListeners();
  }

  void setNotes(String val) {
    _notes = val;
    _safeNotifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    _safeNotifyListeners();
  }

  Future<PlasticAnalysisResult?> submitAnalysis() async {
    final version = _sessionVersion;
    _isLoading = true;
    _isSuccess = false;
    _errorMessage = null;
    _safeNotifyListeners();

    try {
      final input = PlasticAnalysisInput(
        imagePath: _imagePath,
        isCameraOrGallery: _imagePath != null,
        polymerCategory: _polymerCategory,
        weightKg: _weightKg > 0 ? _weightKg : 1.0,
        condition: _condition,
        notes: _notes,
      );

      final result = await analysisRepository.analyzePlastic(input);
      if (version != _sessionVersion || _disposed) return null;
      _analysisResult = result;
      _isSuccess = true;
      return result;
    } catch (e) {
      if (version != _sessionVersion || _disposed) return null;
      if (e is ApiException) {
        _errorMessage = e.message;
      } else {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      }
      return null;
    } finally {
      if (version == _sessionVersion && !_disposed) {
        _isLoading = false;
        _safeNotifyListeners();
      }
    }
  }
}
