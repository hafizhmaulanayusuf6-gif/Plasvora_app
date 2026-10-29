import '../core/constants/app_assets.dart';
import '../core/network/api_client.dart';
import '../core/network/api_config.dart';
import '../models/plastic_analysis.dart';

abstract class AnalysisRepository {
  Future<PlasticAnalysisResult> analyzePlastic(PlasticAnalysisInput input);
}

class ApiAnalysisRepository implements AnalysisRepository {
  final ApiClient apiClient;

  ApiAnalysisRepository({required this.apiClient});

  @override
  Future<PlasticAnalysisResult> analyzePlastic(PlasticAnalysisInput input) async {
    final fields = <String, String>{};
    if (input.polymerCategory != null && input.polymerCategory!.isNotEmpty) {
      fields['declared_category'] = input.polymerCategory!;
    }
    if (input.weightKg != null && input.weightKg! > 0) {
      fields['weight_kg'] = input.weightKg.toString();
    }
    fields['condition'] = input.condition;
    if (input.notes != null && input.notes!.isNotEmpty) {
      fields['notes'] = input.notes!;
    }

    final hasImage = input.imagePath != null && input.imagePath!.isNotEmpty;

    dynamic response;
    if (hasImage) {
      response = await apiClient.postMultipart(
        ApiConfig.analyses,
        fields: fields,
        fileField: 'image',
        filePath: input.imagePath,
        requiresAuth: true,
      );
    } else {
      // Jika hanya estimasi deklaratif tanpa file gambar
      final bodyMap = <String, dynamic>{
        'condition': input.condition,
        'weight_kg': input.weightKg ?? 1.0,
      };
      if (input.polymerCategory != null && input.polymerCategory!.isNotEmpty) {
        bodyMap['declared_category'] = input.polymerCategory;
      }
      if (input.notes != null && input.notes!.isNotEmpty) {
        bodyMap['notes'] = input.notes;
      }

      response = await apiClient.post(
        ApiConfig.analyses,
        body: bodyMap,
        requiresAuth: true,
      );
    }

    if (response is Map<String, dynamic> && response['data'] != null) {
      final data = response['data'] as Map<String, dynamic>;
      return _mapBackendDataToResult(data, input);
    }

    throw ApiException('Format respons analisis tidak valid dari server.');
  }

  PlasticAnalysisResult _mapBackendDataToResult(
    Map<String, dynamic> data,
    PlasticAnalysisInput input,
  ) {
    final isDemo = data['is_demo_result'] == true;
    final id = data['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString();
    final estimatedCat = data['estimated_category']?.toString() ??
        data['declared_category']?.toString() ??
        input.polymerCategory ??
        'PET';

    final recs = data['recommendations'];

    // Jika hasil dari Gemini Vision (recommendations berupa Map AI)
    if (recs is Map<String, dynamic>) {
      final materialTitle = recs['material_title']?.toString() ?? 'Material Plastik $estimatedCat';
      final polymerCode = recs['polymer_code']?.toString() ?? 'Tipe $estimatedCat';
      final meltingPoint = recs['melting_point']?.toString() ?? '130° - 260° C';
      final avoidedEmission = recs['avoided_emission']?.toString() ?? '~1.8 kg CO₂/kg';
      final qualitativeNote = recs['qualitative_note']?.toString() ?? 'Dianalisis oleh Gemini AI.';

      final rawIdeas = recs['ideas'];
      final ideas = <UpcyclingIdea>[];

      if (rawIdeas is List) {
        for (var i = 0; i < rawIdeas.length; i++) {
          final item = rawIdeas[i];
          if (item is Map) {
            final asset = _resolveIdeaAsset(i);
            ideas.add(
              UpcyclingIdea(
                id: item['id']?.toString() ?? 'idea_${i + 1}',
                title: item['title']?.toString() ?? 'Upcycling Kreatif',
                difficulty: item['difficulty']?.toString() ?? 'Tingkat Menengah',
                description: item['description']?.toString() ?? '',
                imageAsset: asset,
              ),
            );
          }
        }
      }

      if (ideas.isEmpty) {
        ideas.addAll(_defaultIdeas());
      }

      return PlasticAnalysisResult(
        id: id,
        imagePath: input.imagePath,
        localAsset: AppAssets.hasilAnalisisCaps,
        materialTitle: materialTitle,
        polymerCategory: estimatedCat,
        polymerCode: polymerCode,
        meltingPoint: meltingPoint,
        avoidedEmission: avoidedEmission,
        qualitativeNote: qualitativeNote,
        ideas: ideas,
        isSimulated: isDemo,
      );
    }

    // Jika rekomendasi rule-based (berupa List rekomendasi)
    final ideas = <UpcyclingIdea>[];
    if (recs is List) {
      for (var i = 0; i < recs.length; i++) {
        final item = recs[i];
        if (item is Map) {
          ideas.add(
            UpcyclingIdea(
              id: item['id']?.toString() ?? 'idea_${i + 1}',
              title: item['title']?.toString() ?? 'Rekomendasi Plastik',
              difficulty: item['difficulty']?.toString() ?? 'Tingkat Menengah',
              description: item['description']?.toString() ?? '',
              imageAsset: _resolveIdeaAsset(i),
            ),
          );
        }
      }
    }

    if (ideas.isEmpty) {
      ideas.addAll(_defaultIdeas());
    }

    return _mapCategoryToDefaultResult(
      id: id,
      category: estimatedCat,
      input: input,
      isDemo: isDemo,
      ideas: ideas,
    );
  }

  String _resolveIdeaAsset(int index) {
    if (index % 3 == 0) return AppAssets.ideaStool;
    if (index % 3 == 1) return AppAssets.ideaAccessories;
    return AppAssets.ideaMosaic;
  }

  List<UpcyclingIdea> _defaultIdeas() {
    return const [
      UpcyclingIdea(
        id: 'idea_1',
        title: 'Furnitur Ramah Lingkungan',
        difficulty: 'Tingkat Menengah',
        description: 'Dileburkan menjadi tatakan meja, stool, atau ubin komposit.',
        imageAsset: AppAssets.ideaStool,
      ),
      UpcyclingIdea(
        id: 'idea_2',
        title: 'Aksesori & Gantungan Kunci',
        difficulty: 'Tingkat Mudah',
        description: 'Dipotong atau dicetak manual menjadi gantungan kunci dan kancing.',
        imageAsset: AppAssets.ideaAccessories,
      ),
    ];
  }

  PlasticAnalysisResult _mapCategoryToDefaultResult({
    required String id,
    required String category,
    required PlasticAnalysisInput input,
    required bool isDemo,
    required List<UpcyclingIdea> ideas,
  }) {
    String title = 'Material Plastik $category';
    String polymerCode = 'Tipe #1';
    String meltingPoint = '250° - 260° C';
    String emission = '~2.1 kg CO₂/kg';

    switch (category) {
      case 'PET':
        title = 'Botol Plastik PET Bening';
        polymerCode = 'Tipe #1';
        meltingPoint = '250° - 260° C';
        emission = '~2.1 kg CO₂/kg';
        break;
      case 'HDPE':
        title = 'Tutup Botol & Jerigen HDPE';
        polymerCode = 'Tipe #2';
        meltingPoint = '130° - 145° C';
        emission = '~1.8 kg CO₂/kg';
        break;
      case 'PP':
        title = 'Wadah Kemasan Makanan PP';
        polymerCode = 'Tipe #5';
        meltingPoint = '160° - 170° C';
        emission = '~1.7 kg CO₂/kg';
        break;
      case 'LDPE':
        title = 'Plastik Film LDPE';
        polymerCode = 'Tipe #4';
        meltingPoint = '105° - 115° C';
        emission = '~1.5 kg CO₂/kg';
        break;
      default:
        title = 'Campuran Sampah Plastik';
        polymerCode = 'Tipe #7 (Other)';
        meltingPoint = '120° - 250° C';
        emission = '~1.6 kg CO₂/kg';
        break;
    }

    return PlasticAnalysisResult(
      id: id,
      imagePath: input.imagePath,
      localAsset: AppAssets.hasilAnalisisCaps,
      materialTitle: title,
      polymerCategory: category,
      polymerCode: polymerCode,
      meltingPoint: meltingPoint,
      avoidedEmission: emission,
      qualitativeNote: isDemo
          ? 'Rekomendasi berbasis aturan backend. Bukan model computer vision AI.'
          : 'Hasil analisis tercatat di sistem backend.',
      ideas: ideas,
      isSimulated: isDemo,
    );
  }
}

class MockAnalysisRepository implements AnalysisRepository {
  @override
  Future<PlasticAnalysisResult> analyzePlastic(
    PlasticAnalysisInput input,
  ) async {
    // Simulate AI inference delay
    await Future.delayed(const Duration(milliseconds: 1200));

    // Adapt category based on user selection if provided, otherwise default to model estimate
    String title = 'Tutup Botol Plastik';
    String polymerCategory = 'HDPE / PP';
    String polymerCode = 'Tipe #2 & #5';
    String meltingPoint = '130° - 165° C';
    String emission = '~1.8 kg CO₂/kg';

    if (input.polymerCategory != null && input.polymerCategory!.isNotEmpty) {
      switch (input.polymerCategory) {
        case 'PET':
        case '1':
          title = 'Botol Plastik PET Bening';
          polymerCategory = 'PET';
          polymerCode = 'Tipe #1';
          meltingPoint = '250° - 260° C';
          emission = '~2.1 kg CO₂/kg';
          break;
        case 'PP':
        case '5':
          title = 'Wadah Kemasan PP';
          polymerCategory = 'PP';
          polymerCode = 'Tipe #5';
          meltingPoint = '160° - 170° C';
          emission = '~1.7 kg CO₂/kg';
          break;
        case 'LDPE':
        case '4':
          title = 'Plastik Film LDPE';
          polymerCategory = 'LDPE';
          polymerCode = 'Tipe #4';
          meltingPoint = '105° - 115° C';
          emission = '~1.5 kg CO₂/kg';
          break;
        default:
          break;
      }
    }

    return PlasticAnalysisResult(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      imagePath: input.imagePath,
      localAsset: AppAssets.hasilAnalisisCaps,
      materialTitle: title,
      polymerCategory: polymerCategory,
      polymerCode: polymerCode,
      meltingPoint: meltingPoint,
      avoidedEmission: emission,
      qualitativeNote: 'Identifikasi awal berbasis visual. Akurasi dapat dipengaruhi oleh pencahayaan dan campuran bahan. Pastikan memeriksa kode daur ulang segitiga angka pada fisik benda.',
      ideas: const [
        UpcyclingIdea(
          id: 'idea_1',
          title: 'Furnitur Ramah Lingkungan',
          difficulty: 'Tingkat Menengah',
          description: 'Dileburkan menjadi tatakan meja, stool, atau ubin komposit tahan cuaca.',
          imageAsset: AppAssets.ideaStool,
        ),
        UpcyclingIdea(
          id: 'idea_2',
          title: 'Aksesori & Gantungan Kunci',
          difficulty: 'Tingkat Mudah',
          description: 'Dipotong atau dicetak manual menjadi gantungan kunci, coaster, dan kancing.',
          imageAsset: AppAssets.ideaAccessories,
        ),
        UpcyclingIdea(
          id: 'idea_3',
          title: 'Dekorasi & Panel Mozaik',
          difficulty: 'Tingkat Menengah',
          description: 'Penyusunan gradasi warna tutup botol untuk karya seni mural daur ulang.',
          imageAsset: AppAssets.ideaMosaic,
        ),
      ],
      isSimulated: true,
    );
  }
}
