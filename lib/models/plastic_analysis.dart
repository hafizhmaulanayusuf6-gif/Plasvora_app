/// Models for plastic scanning, AI estimation result, and upcycling ideas.
class UpcyclingIdea {
  final String id;
  final String title;
  final String difficulty; // Tingkat Mudah, Tingkat Menengah, etc.
  final String description;
  final String imageAsset;

  const UpcyclingIdea({
    required this.id,
    required this.title,
    required this.difficulty,
    required this.description,
    required this.imageAsset,
  });
}

class PlasticAnalysisInput {
  final String? imagePath;
  final bool isCameraOrGallery;
  final String? polymerCategory; // PET, HDPE, etc. or null
  final double? weightKg;
  final String condition; // clean, light, dirty
  final String? notes;

  const PlasticAnalysisInput({
    this.imagePath,
    this.isCameraOrGallery = false,
    this.polymerCategory,
    this.weightKg,
    this.condition = 'clean',
    this.notes,
  });
}

class PlasticAnalysisResult {
  final String id;
  final String? imagePath;
  final String localAsset;
  final String materialTitle;
  final String polymerCategory;
  final String polymerCode;
  final String meltingPoint;
  final String avoidedEmission;
  final String qualitativeNote;
  final List<UpcyclingIdea> ideas;
  final bool isSimulated;

  const PlasticAnalysisResult({
    required this.id,
    this.imagePath,
    required this.localAsset,
    required this.materialTitle,
    required this.polymerCategory,
    required this.polymerCode,
    required this.meltingPoint,
    required this.avoidedEmission,
    required this.qualitativeNote,
    required this.ideas,
    this.isSimulated = true,
  });
}
