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
      final objectName = recs['object_name']?.toString() ?? recs['detected_object']?.toString() ?? 'Sampah Plastik';
      final objectDesc = recs['object_description']?.toString() ?? objectName;
      final identSummary = recs['identification_summary']?.toString() ?? recs['qualitative_note']?.toString();
      final materialTitle = recs['material_title']?.toString() ?? objectName;
      final polymerCode = recs['polymer_code']?.toString() ?? 'Tipe $estimatedCat';
      final meltingPoint = recs['melting_point']?.toString() ?? '130° - 260° C';
      final avoidedEmission = recs['avoided_emission']?.toString() ?? '~1.8 kg CO₂/kg (Estimasi)';
      final qualitativeNote = recs['qualitative_note']?.toString() ?? identSummary ?? 'Dianalisis oleh Gemini AI.';

      // Parse komponen material (Multi-Component)
      final components = <MaterialComponent>[];
      final rawComponents = recs['components'];
      if (rawComponents is List) {
        for (var i = 0; i < rawComponents.length; i++) {
          final comp = rawComponents[i];
          if (comp is Map) {
            final candidates = <String>[];
            final rawCandidates = comp['candidate_materials'];
            if (rawCandidates is List) {
              for (var c in rawCandidates) {
                if (c != null) candidates.add(c.toString());
              }
            }
            components.add(
              MaterialComponent(
                id: comp['id']?.toString() ?? 'component_${i + 1}',
                partName: comp['part_name']?.toString() ?? 'Bagian ${i + 1}',
                materialType: comp['material_type']?.toString() ?? 'uncertain',
                resinCode: comp['resin_code']?.toString(),
                confidence: comp['confidence']?.toString() ?? 'medium',
                identificationBasis: comp['identification_basis']?.toString() ?? 'visual_estimate',
                candidateMaterials: candidates,
                verificationNote: comp['verification_note']?.toString() ?? 'Periksa kode daur ulang segitiga.',
                meltingPoint: comp['melting_point']?.toString(),
              ),
            );
          }
        }
      }

      // Jika belum ada komponen di respons AI, buat 1 komponen default
      if (components.isEmpty) {
        components.add(
          MaterialComponent(
            id: 'component_main',
            partName: objectName,
            materialType: estimatedCat,
            resinCode: polymerCode,
            confidence: 'medium',
            identificationBasis: 'visual_estimate',
            verificationNote: 'Periksa kode daur ulang segitiga pada fisik benda.',
            meltingPoint: meltingPoint,
          ),
        );
      }

      // Parse ide upcycling
      final rawIdeas = recs['recommendations'] ?? recs['ideas'];
      final ideas = <UpcyclingIdea>[];

      if (rawIdeas is List) {
        for (var i = 0; i < rawIdeas.length; i++) {
          final item = rawIdeas[i];
          if (item is Map) {
            final asset = _resolveIdeaAsset(i);
            final compIds = <String>[];
            final rawCompIds = item['component_ids'];
            if (rawCompIds is List) {
              for (var c in rawCompIds) {
                if (c != null) compIds.add(c.toString());
              }
            }
            if (compIds.isEmpty && components.isNotEmpty) {
              compIds.add(components.first.id);
            }

            ideas.add(
              UpcyclingIdea(
                id: item['id']?.toString() ?? 'idea_${i + 1}',
                title: item['title']?.toString() ?? 'Upcycling Kreatif',
                difficulty: item['difficulty']?.toString() ?? 'Tingkat Menengah',
                description: item['description']?.toString() ?? '',
                imageAsset: asset,
                componentIds: compIds,
                suitableQuantity: item['suitable_quantity']?.toString() ?? 'single_item',
                scale: item['scale']?.toString() ?? 'household',
                whyItFits: item['why_it_fits']?.toString(),
                tools: item['tools']?.toString(),
                steps: item['steps']?.toString(),
                safetyNotes: item['safety_notes']?.toString(),
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
        objectName: objectName,
        objectDescription: objectDesc,
        identificationSummary: identSummary,
        components: components,
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

    // Jika pengguna memilih kategori polimer secara eksplisit (misal test input deklaratif)
    if (input.polymerCategory != null && input.polymerCategory!.isNotEmpty) {
      String title = 'Material Plastik ${input.polymerCategory}';
      String code = 'Tipe #${input.polymerCategory}';
      String melting = '130° - 260° C';
      String emission = '~1.8 kg CO₂/kg (Estimasi)';
      switch (input.polymerCategory) {
        case 'PET':
        case '1':
          title = 'Botol Plastik PET Bening';
          code = 'Tipe #1';
          melting = '250° - 260° C';
          emission = '~2.1 kg CO₂/kg (Estimasi)';
          break;
        case 'HDPE':
        case '2':
          title = 'Tutup Botol & Jerigen HDPE';
          code = 'Tipe #2';
          melting = '130° - 145° C';
          emission = '~1.8 kg CO₂/kg (Estimasi)';
          break;
        case 'PP':
        case '5':
          title = 'Wadah Kemasan PP';
          code = 'Tipe #5';
          melting = '160° - 170° C';
          emission = '~1.7 kg CO₂/kg (Estimasi)';
          break;
        case 'LDPE':
        case '4':
          title = 'Plastik Film LDPE';
          code = 'Tipe #4';
          melting = '105° - 115° C';
          emission = '~1.5 kg CO₂/kg (Estimasi)';
          break;
      }
      return PlasticAnalysisResult(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        imagePath: input.imagePath,
        localAsset: AppAssets.hasilAnalisisCaps,
        objectName: title,
        objectDescription: 'Material plastik kategori ${input.polymerCategory}.',
        identificationSummary: 'Material didefinisikan sebagai ${input.polymerCategory}.',
        components: [
          MaterialComponent(
            id: 'component_main',
            partName: title,
            materialType: input.polymerCategory!,
            resinCode: code,
            confidence: 'high',
            identificationBasis: 'user_declared',
            verificationNote: 'Kategori ditentukan dari input deklaratif pengguna.',
            meltingPoint: melting,
          ),
        ],
        materialTitle: title,
        polymerCategory: input.polymerCategory!,
        polymerCode: code,
        meltingPoint: melting,
        avoidedEmission: emission,
        qualitativeNote: 'Kategori material sesuai pilihan pengguna.',
        ideas: const [
          UpcyclingIdea(
            id: 'idea_1',
            title: 'Wadah Penyimpanan Praktis',
            difficulty: 'Tingkat Mudah',
            description: 'Dapat dialihfungsikan menjadi wadah serbaguna.',
            imageAsset: AppAssets.ideaStool,
          ),
        ],
        isSimulated: true,
      );
    }

    final notesLower = (input.notes ?? '').toLowerCase();

    // Skenario 1: Hanya tutup botol
    if (notesLower.contains('tutup botol saja') || notesLower.contains('hanya tutup')) {
      const compCap = MaterialComponent(
        id: 'component_cap',
        partName: 'Tutup botol',
        materialType: 'uncertain',
        resinCode: null,
        confidence: 'low',
        identificationBasis: 'visual_estimate',
        candidateMaterials: ['HDPE (#2)', 'PP (#5)'],
        verificationNote: 'Periksa kode daur ulang timbul pada bagian dalam tutup botol.',
        meltingPoint: '130° - 165° C',
      );

      return PlasticAnalysisResult(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        imagePath: input.imagePath,
        localAsset: AppAssets.hasilAnalisisCaps,
        objectName: 'Tutup Botol Plastik',
        objectDescription: 'Satu buah tutup botol plastik kaku berulir.',
        identificationSummary: 'Hanya satu buah tutup botol plastik yang tampak pada foto.',
        components: const [compCap],
        materialTitle: 'Tutup Botol Plastik (HDPE/PP)',
        polymerCategory: 'HDPE / PP',
        polymerCode: 'Tipe #2 / #5',
        meltingPoint: '130° - 165° C',
        avoidedEmission: '~1.8 kg CO₂/kg (Estimasi)',
        qualitativeNote: 'Teridentifikasi satu komponen tutup botol plastik kaku. Polimer umumnya HDPE atau PP.',
        ideas: const [
          UpcyclingIdea(
            id: 'idea_1',
            title: 'Tatakan Gelas & Coaster Meja',
            difficulty: 'Tingkat Mudah',
            description: 'Disusun dan direkatkan menjadi alas cangkir tahan panas.',
            imageAsset: AppAssets.ideaAccessories,
            componentIds: ['component_cap'],
            suitableQuantity: 'single_item',
            scale: 'household',
            whyItFits: 'Bentuk bundar dan ketahanan panas sedang sangat cocok untuk alas cangkir.',
            tools: 'Lem perekat, alas gabus',
            steps: '1. Bersihkan tutup botol. 2. Rekatkan pada alas datar. 3. Biarkan kering.',
            safetyNotes: 'Gunakan lem di ruangan dengan ventilasi baik.',
          ),
          UpcyclingIdea(
            id: 'idea_2',
            title: 'Aksesori Gantungan Kunci Edukasi',
            difficulty: 'Tingkat Mudah',
            description: 'Diberi lubang kecil dan ring gantungan untuk suvenir ramah lingkungan.',
            imageAsset: AppAssets.ideaAccessories,
            componentIds: ['component_cap'],
            suitableQuantity: 'single_item',
            scale: 'household',
            whyItFits: 'Ukuran kecil dan ringan membuatnya ideal sebagai gantungan kunci.',
            tools: 'Bor tangan mini/jarum pemanas, ring kunci',
            steps: '1. Lubangi tepi tutup botol. 2. Pasang ring gantungan. 3. Hias permukaan.',
            safetyNotes: 'Hati-hati saat melubangi plastik kaku.',
          ),
        ],
        isSimulated: true,
      );
    }

    // Skenario 2: Badan botol tanpa tutup
    if (notesLower.contains('tanpa tutup')) {
      const compBody = MaterialComponent(
        id: 'component_body',
        partName: 'Badan botol',
        materialType: 'PET',
        resinCode: '#1',
        confidence: 'medium',
        identificationBasis: 'visual_estimate',
        candidateMaterials: [],
        verificationNote: 'Periksa simbol segitiga angka 1 (PET) pada bagian bawah botol.',
        meltingPoint: '250° - 260° C',
      );

      return PlasticAnalysisResult(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        imagePath: input.imagePath,
        localAsset: AppAssets.hasilAnalisisCaps,
        objectName: 'Badan Botol Plastik Tanpa Tutup',
        objectDescription: 'Badan botol plastik transparan bening dengan leher terbuka.',
        identificationSummary: 'Badan botol teridentifikasi tanpa komponen tutup.',
        components: const [compBody],
        materialTitle: 'Botol Plastik PET Bening',
        polymerCategory: 'PET',
        polymerCode: 'Tipe #1',
        meltingPoint: '250° - 260° C',
        avoidedEmission: '~2.1 kg CO₂/kg (Estimasi)',
        qualitativeNote: 'Botol plastik minuman bening pada umumnya berbahan Polyethylene Terephthalate (PET).',
        ideas: const [
          UpcyclingIdea(
            id: 'idea_1',
            title: 'Pot Tanaman Hidroponik Sederhana',
            difficulty: 'Tingkat Mudah',
            description: 'Potong botol menjadi 2 bagian, balikkan bagian leher sebagai corong penyerap air.',
            imageAsset: AppAssets.ideaStool,
            componentIds: ['component_body'],
            suitableQuantity: 'single_item',
            scale: 'household',
            whyItFits: 'Bentuk silinder kedap air sangat ideal untuk menampung air dan media tanam.',
            tools: 'Gunting/cutter, sumbu kain flanel',
            steps: '1. Potong botol menjadi dua. 2. Masukkan sumbu kain. 3. Masukkan tanah dan benih.',
            safetyNotes: 'Hati-hati saat memotong tepi plastik dengan gunting.',
          ),
          UpcyclingIdea(
            id: 'idea_2',
            title: 'Corong Tuang Multiguna',
            difficulty: 'Tingkat Mudah',
            description: 'Memotong leher botol untuk alat bantu menuang cairan atau butiran.',
            imageAsset: AppAssets.ideaMosaic,
            componentIds: ['component_body'],
            suitableQuantity: 'single_item',
            scale: 'household',
            whyItFits: 'Bentuk kerucut leher botol berfungsi sempurna sebagai corong tuang.',
            tools: 'Gunting, amplas',
            steps: '1. Potong leher botol setinggi 8 cm. 2. Amplas tepian kasar hingga halus.',
            safetyNotes: 'Pastikan tepi yang dipotong tidak tajam.',
          ),
        ],
        isSimulated: true,
      );
    }

    // Skenario Utama (Default): Botol air mineral transparan + tutup biru
    const compBody = MaterialComponent(
      id: 'component_body',
      partName: 'Badan botol',
      materialType: 'PET',
      resinCode: '#1',
      confidence: 'medium',
      identificationBasis: 'visual_estimate',
      candidateMaterials: [],
      verificationNote: 'Periksa simbol daur ulang segitiga angka 1 (PET) pada bagian bawah botol.',
      meltingPoint: '250° - 260° C',
    );

    const compCap = MaterialComponent(
      id: 'component_cap',
      partName: 'Tutup botol',
      materialType: 'uncertain',
      resinCode: null,
      confidence: 'low',
      identificationBasis: 'visual_estimate',
      candidateMaterials: ['HDPE (#2)', 'PP (#5)'],
      verificationNote: 'Periksa kode daur ulang timbul pada bagian dalam tutup botol.',
      meltingPoint: '130° - 165° C',
    );

    return PlasticAnalysisResult(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      imagePath: input.imagePath,
      localAsset: AppAssets.hasilAnalisisCaps,
      objectName: 'Botol Air Mineral Plastik',
      objectDescription: 'Botol plastik transparan bening dengan tutup ulir berwarna biru.',
      identificationSummary: 'Objek terdiri dari 2 komponen terpisah: badan botol (PET) dan tutup botol (HDPE/PP).',
      components: const [compBody, compCap],
      materialTitle: 'Tutup Botol & Botol Air Mineral (Multi-Komponen: PET & HDPE/PP)',
      polymerCategory: 'MIXED',
      polymerCode: 'Badan: Tipe #1 | Tutup: Tipe #2/#5',
      meltingPoint: 'Badan: 250°-260°C | Tutup: 130°-165°C',
      avoidedEmission: '~2.0 kg CO₂/kg (Estimasi)',
      qualitativeNote: 'Objek teridentifikasi memiliki 2 komponen dengan karakteristik polimer berbeda. Badan botol berkarakteristik PET (#1), sedangkan tutup botol berbahan termoplastik kaku (HDPE #2 atau PP #5). Disarankan memisahkan tutup dan badan sebelum pengolahan daur ulang.',
      ideas: const [
        UpcyclingIdea(
          id: 'idea_1',
          title: 'Pot Tanaman Mandiri & Hidroponik',
          difficulty: 'Tingkat Mudah',
          description: 'Mengubah badan botol menjadi sistem pot siram mandiri dengan sumbu kain flanel.',
          imageAsset: AppAssets.ideaStool,
          componentIds: ['component_body'],
          suitableQuantity: 'single_item',
          scale: 'household',
          whyItFits: 'Bentuk rongga silinder botol PET bening memudahkan pengamatan cadangan air dan pertumbuhan akar.',
          tools: 'Gunting/cutter, sumbu kain flanel, media tanam',
          steps: '1. Potong botol menjadi 2 bagian. 2. Balikkan bagian atas ke dalam wadah bawah. 3. Pasang sumbu kain. 4. Masukkan media tanam.',
          safetyNotes: 'Gunakan gunting secara hati-hati saat memotong tepi plastik kaku.',
        ),
        UpcyclingIdea(
          id: 'idea_2',
          title: 'Wadah Sortir & Pengorganisir Meja',
          difficulty: 'Tingkat Mudah',
          description: 'Memotong badan botol setinggi 10 cm untuk tempat pulpen, klip, atau kabel.',
          imageAsset: AppAssets.ideaMosaic,
          componentIds: ['component_body'],
          suitableQuantity: 'single_item',
          scale: 'household',
          whyItFits: 'Dinding botol bening memudahkan melihat isi barang kecil di atas meja kerja.',
          tools: 'Gunting, amplas halus',
          steps: '1. Potong bagian dasar botol setinggi 10 cm. 2. Haluskan pinggiran dengan amplas halus. 3. Bersihkan dan letakkan di meja.',
          safetyNotes: 'Pastikan pinggiran potongan plastik sudah dihaluskan agar tidak melukai jari.',
        ),
        UpcyclingIdea(
          id: 'idea_3',
          title: 'Tatakan Gelas & Aksesori Meja',
          difficulty: 'Tingkat Mudah',
          description: 'Memanfaatkan tutup botol kaku sebagai alas pelindung benturan atau tatakan cangkir.',
          imageAsset: AppAssets.ideaAccessories,
          componentIds: ['component_cap'],
          suitableQuantity: 'single_item',
          scale: 'household',
          whyItFits: 'Karakteristik polimer HDPE/PP pada tutup botol tahan terhadap benturan dan panas sedang cangkir.',
          tools: 'Perekat dua sisi atau lem serbaguna',
          steps: '1. Bersihkan sisa minuman pada tutup botol. 2. Pasang pada bagian bawah benda atau buat tatakan sederhana.',
          safetyNotes: 'Gunakan perekat secukupnya di ruangan terbuka.',
        ),
      ],
      isSimulated: true,
    );
  }
}
