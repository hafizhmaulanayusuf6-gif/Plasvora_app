/// Model representasi komponen fisik dalam objek material (Multi-Component)
class MaterialComponent {
  final String id;
  final String partName; // e.g. 'Badan botol', 'Tutup botol'
  final String materialType; // e.g. 'PET', 'uncertain', 'HDPE', 'PP'
  final String? resinCode; // e.g. '#1', null
  final String confidence; // 'high', 'medium', 'low', 'uncertain'
  final String identificationBasis; // 'visual_estimate', 'resin_code_visible', etc.
  final List<String> candidateMaterials; // e.g. ['HDPE (#2)', 'PP (#5)']
  final String verificationNote; // e.g. 'Periksa kode resin di bawah botol'
  final String? meltingPoint; // e.g. '250° - 260° C'

  const MaterialComponent({
    required this.id,
    required this.partName,
    required this.materialType,
    this.resinCode,
    this.confidence = 'medium',
    this.identificationBasis = 'visual_estimate',
    this.candidateMaterials = const [],
    required this.verificationNote,
    this.meltingPoint,
  });

  bool get isUncertain =>
      confidence == 'low' ||
      confidence == 'uncertain' ||
      materialType.toLowerCase() == 'uncertain' ||
      candidateMaterials.isNotEmpty;
}

/// Models for plastic scanning, AI estimation result, and upcycling ideas.
class UpcyclingIdea {
  final String id;
  final String title;
  final String difficulty; // Tingkat Mudah, Tingkat Menengah, etc.
  final String description;
  final String imageAsset;
  final List<String> componentIds; // Komponen yang dipakai ide ini
  final String suitableQuantity; // single_item, small_batch, bulk
  final String scale; // household, community, industrial
  final String? whyItFits;
  final String? tools;
  final String? steps;
  final String? safetyNotes;

  const UpcyclingIdea({
    required this.id,
    required this.title,
    required this.difficulty,
    required this.description,
    required this.imageAsset,
    this.componentIds = const [],
    this.suitableQuantity = 'single_item',
    this.scale = 'household',
    this.whyItFits,
    this.tools,
    this.steps,
    this.safetyNotes,
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
  final String? objectName;
  final String? objectDescription;
  final String? identificationSummary;
  final List<MaterialComponent> components;
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
    this.objectName,
    this.objectDescription,
    this.identificationSummary,
    this.components = const [],
    required this.materialTitle,
    required this.polymerCategory,
    required this.polymerCode,
    required this.meltingPoint,
    required this.avoidedEmission,
    required this.qualitativeNote,
    required this.ideas,
    this.isSimulated = true,
  });

  bool get isMultiComponent => components.length > 1;
}
