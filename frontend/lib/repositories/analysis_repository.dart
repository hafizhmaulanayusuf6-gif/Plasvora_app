import '../core/constants/app_assets.dart';
import '../models/plastic_analysis.dart';

abstract class AnalysisRepository {
  Future<PlasticAnalysisResult> analyzePlastic(PlasticAnalysisInput input);
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
