import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:plasvora/core/network/api_client.dart';
import 'package:plasvora/core/theme/app_theme.dart';
import 'package:plasvora/models/plastic_analysis.dart';
import 'package:plasvora/repositories/analysis_repository.dart';
import 'package:plasvora/viewmodels/analysis_viewmodel.dart';
import 'package:plasvora/viewmodels/navigation_viewmodel.dart';
import 'package:plasvora/views/analysis/analysis_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Test helper: minimal valid JPEG bytes (1x1 pixel)
// ─────────────────────────────────────────────────────────────────────────────
final _minimalJpegBytes = base64Decode(
  '/9j/4AAQSkZJRgABAQEASABIAAD/2wBDAP//////////////////////////////////////////////////////////////////////////////////////wgALCAABAAEBAREA/8QAFBABAAAAAAAAAAAAAAAAAAAAAP/aAAgBAQABPxA=',
);

File _createTempJpgFile() {
  final tmp = File('${Directory.systemTemp.path}/test_plastic.jpg');
  tmp.writeAsBytesSync(_minimalJpegBytes);
  return tmp;
}

// ─────────────────────────────────────────────────────────────────────────────
// Mock HTTP client factory
// ─────────────────────────────────────────────────────────────────────────────
ApiClient _mockClient(
  int statusCode,
  Map<String, dynamic> body, {
  String? token,
}) {
  final bodyBytes = utf8.encode(jsonEncode(body));
  final mockHttp = MockClient((_) async => http.Response.bytes(
        bodyBytes,
        statusCode,
        headers: {'Content-Type': 'application/json; charset=utf-8'},
      ));

  final tokenStorage = InMemoryAuthTokenStorage();
  if (token != null) {
    tokenStorage.saveToken(token);
  }

  return ApiClient(client: mockHttp, tokenStorage: tokenStorage);
}

void main() {
  // ───────────────────────────────────────────────────────────────────────────
  // 1. Repository mapping — AI Vision response (is_demo_result: false)
  // ───────────────────────────────────────────────────────────────────────────
  group('ApiAnalysisRepository — AI Vision response', () {
    test('maps Gemini structured recommendations correctly', () async {
      const backendAiResponse = {
        'success': true,
        'message': 'Analisis plastik berhasil dilakukan dengan Gemini AI.',
        'data': {
          'id': '42',
          'user_id': 1,
          'declared_category': 'HDPE',
          'estimated_category': 'HDPE',
          'weight_kg': '2.50',
          'condition': 'clean',
          'input_image_path': 'analyses/test.jpg',
          'is_demo_result': false,
          'recommendations': {
            'estimated_category': 'HDPE',
            'material_title': 'Tutup Botol HDPE Biru',
            'polymer_code': 'Tipe #2 (HDPE)',
            'melting_point': '130° - 145° C',
            'avoided_emission': '~1.8 kg CO₂/kg',
            'qualitative_note': 'Teridentifikasi sebagai tutup botol polietilena berdensitas tinggi.',
            'is_ai_generated': true,
            'ideas': [
              {
                'id': 'idea_1',
                'title': 'Tatakan Gelas Warna-warni',
                'difficulty': 'Tingkat Mudah',
                'description': 'Dileburkan dan dicetak menjadi tatakan gelas unik.',
                'tools': 'Oven, cetakan silikon',
                'steps': 'Cacah, tuang ke cetakan, panggang 140°C.',
                'safety_notes': 'Gunakan sarung tangan.',
              },
            ],
          },
          'created_at': '2026-10-29T01:00:00.000000Z',
          'updated_at': '2026-10-29T01:00:00.000000Z',
        },
      };

      final repo = ApiAnalysisRepository(
        apiClient: _mockClient(201, backendAiResponse, token: 'test_token'),
      );

      final tmpFile = _createTempJpgFile();
      try {
        final input = PlasticAnalysisInput(
          imagePath: tmpFile.path,
          isCameraOrGallery: true,
          polymerCategory: 'HDPE',
          weightKg: 2.5,
          condition: 'clean',
        );

        final result = await repo.analyzePlastic(input);

        expect(result.polymerCategory, equals('HDPE'));
        expect(result.materialTitle, equals('Tutup Botol HDPE Biru'));
        expect(result.polymerCode, equals('Tipe #2 (HDPE)'));
        expect(result.meltingPoint, equals('130° - 145° C'));
        expect(result.avoidedEmission, equals('~1.8 kg CO₂/kg'));
        expect(result.qualitativeNote, contains('polietilena'));
        expect(result.isSimulated, isFalse);
        expect(result.ideas.length, equals(1));
        expect(result.ideas.first.title, equals('Tatakan Gelas Warna-warni'));
        expect(result.ideas.first.difficulty, equals('Tingkat Mudah'));
      } finally {
        if (tmpFile.existsSync()) tmpFile.deleteSync();
      }
    });
  });

  // ───────────────────────────────────────────────────────────────────────────
  // 2. Repository mapping — Rule-based response (is_demo_result: true)
  // ───────────────────────────────────────────────────────────────────────────
  group('ApiAnalysisRepository — Rule-based fallback response', () {
    test('maps rule-based List recommendations correctly', () async {
      const backendRuleResponse = {
        'success': true,
        'message': 'Analysis completed. Results are rule-based recommendations, not AI.',
        'data': {
          'id': '10',
          'user_id': 1,
          'declared_category': 'PET',
          'estimated_category': 'PET',
          'weight_kg': '1.00',
          'condition': 'clean',
          'input_image_path': null,
          'is_demo_result': true,
          'recommendations': [
            {
              'id': 'idea_1',
              'type': 'craft',
              'title': 'Kerajinan Botol Kreatif',
              'difficulty': 'Tingkat Mudah',
              'description': 'Botol PET dapat diubah menjadi pot tanaman.',
            },
            {
              'id': 'idea_2',
              'type': 'recycle',
              'title': 'Daur Ulang di Bank Sampah',
              'difficulty': 'Tingkat Mudah',
              'description': 'PET adalah plastik yang paling mudah didaur ulang.',
            },
          ],
          'created_at': '2026-10-29T01:00:00.000000Z',
          'updated_at': '2026-10-29T01:00:00.000000Z',
        },
      };

      final repo = ApiAnalysisRepository(
        apiClient: _mockClient(201, backendRuleResponse, token: 'test_token'),
      );

      final input = PlasticAnalysisInput(
        imagePath: null,
        isCameraOrGallery: false,
        polymerCategory: 'PET',
        weightKg: 1.0,
        condition: 'clean',
      );

      final result = await repo.analyzePlastic(input);

      expect(result.polymerCategory, equals('PET'));
      expect(result.materialTitle, contains('PET'));
      expect(result.isSimulated, isTrue);
      expect(result.ideas.length, equals(2));
      expect(result.ideas.first.title, equals('Kerajinan Botol Kreatif'));
    });
  });

  // ───────────────────────────────────────────────────────────────────────────
  // 3. Error handling — server error 500
  // ───────────────────────────────────────────────────────────────────────────
  group('ApiAnalysisRepository — Error handling', () {
    test('throws ApiException on server error 500', () async {
      final repo = ApiAnalysisRepository(
        apiClient: _mockClient(500, {
          'success': false,
          'message': 'Layanan AI belum dikonfigurasi pada server.',
        }, token: 'test_token'),
      );

      final tmpFile = _createTempJpgFile();
      try {
        final input = PlasticAnalysisInput(
          imagePath: tmpFile.path,
          isCameraOrGallery: true,
          polymerCategory: 'PET',
          weightKg: 1.0,
          condition: 'clean',
        );

        expect(
          () async => repo.analyzePlastic(input),
          throwsA(
            isA<ApiException>().having(
              (e) => e.message,
              'message',
              contains('Layanan AI belum dikonfigurasi'),
            ),
          ),
        );
      } finally {
        if (tmpFile.existsSync()) tmpFile.deleteSync();
      }
    });

    test('throws ApiException with rate limit message on 429', () async {
      final repo = ApiAnalysisRepository(
        apiClient: _mockClient(429, {
          'success': false,
          'message': 'Batas permintaan Gemini API tercapai. Coba beberapa saat lagi.',
        }, token: 'test_token'),
      );

      final tmpFile = _createTempJpgFile();
      try {
        final input = PlasticAnalysisInput(
          imagePath: tmpFile.path,
          isCameraOrGallery: true,
          polymerCategory: 'PET',
          weightKg: 1.0,
          condition: 'clean',
        );

        expect(
          () async => repo.analyzePlastic(input),
          throwsA(isA<ApiException>()),
        );
      } finally {
        if (tmpFile.existsSync()) tmpFile.deleteSync();
      }
    });

    test('throws ApiException on invalid response structure', () async {
      final repo = ApiAnalysisRepository(
        apiClient: _mockClient(200, {
          'success': true,
          'message': 'OK',
          // 'data' intentionally missing
        }, token: 'test_token'),
      );

      final input = PlasticAnalysisInput(
        imagePath: null,
        isCameraOrGallery: false,
        polymerCategory: 'PP',
        weightKg: 0.5,
        condition: 'clean',
      );

      expect(
        () async => repo.analyzePlastic(input),
        throwsA(isA<ApiException>()),
      );
    });
  });

  // ───────────────────────────────────────────────────────────────────────────
  // 4. MockAnalysisRepository sanity check
  // ───────────────────────────────────────────────────────────────────────────
  group('MockAnalysisRepository', () {
    test('returns simulated result for any input', () async {
      final repo = MockAnalysisRepository();
      final input = PlasticAnalysisInput(
        imagePath: null,
        isCameraOrGallery: false,
        polymerCategory: 'LDPE',
        weightKg: 3.0,
        condition: 'dirty',
      );

      final result = await repo.analyzePlastic(input);
      expect(result.isSimulated, isTrue);
      expect(result.polymerCategory, equals('LDPE'));
      expect(result.ideas.isNotEmpty, isTrue);
    });

    test('returns default HDPE/PP result when no category given', () async {
      final repo = MockAnalysisRepository();
      final input = PlasticAnalysisInput(
        imagePath: null,
        isCameraOrGallery: false,
        condition: 'clean',
      );

      final result = await repo.analyzePlastic(input);
      expect(result.isSimulated, isTrue);
      expect(result.materialTitle, contains('Tutup Botol'));
    });
  });

  // ───────────────────────────────────────────────────────────────────────────
  // 5. BUG-02 — Plastic category contract (Flutter -> Laravel canonical values)
  // ───────────────────────────────────────────────────────────────────────────
  group('BUG-02 — PlasticCategory contract & payload verification', () {
    test('every selectable option maps to canonical Laravel enum and never numeric codes', () {
      const expectedBackendAllowlist = {
        'PET',
        'HDPE',
        'PP',
        'LDPE',
        'OTHER',
        'MIXED',
      };

      final selectableValues = PlasticCategory.selectableOptions
          .map((o) => o.apiValue)
          .toSet();

      expect(selectableValues, equals(expectedBackendAllowlist));
      for (final option in PlasticCategory.selectableOptions) {
        expect(RegExp(r'^[1-7]$').hasMatch(option.apiValue), isFalse);
      }

      // Normalization behavior
      expect(PlasticCategory.normalizeForApi(' pet '), equals('PET'));
      expect(PlasticCategory.normalizeForApi('mixed'), equals('MIXED'));
      expect(PlasticCategory.normalizeForApi(null), isNull);
      expect(PlasticCategory.normalizeForApi(''), isNull);
      for (final legacyNumeric in ['1', '2', '3', '4', '5', '6', '7']) {
        expect(PlasticCategory.normalizeForApi(legacyNumeric), isNull);
      }
      expect(PlasticCategory.normalizeForApi('INVALID'), isNull);
    });

    test('JSON and multipart requests send exact canonical declared_category and omit null/unsupported values', () async {
      final capturedJsonBodies = <Map<String, dynamic>>[];
      String? capturedMultipartBody;

      final mockHttp = MockClient((request) async {
        final contentType = request.headers['content-type'] ?? '';
        String echoedCategory = 'PET';

        if (contentType.contains('multipart/form-data')) {
          final decodedMultipart = utf8.decode(
            request.bodyBytes,
            allowMalformed: true,
          );
          capturedMultipartBody = decodedMultipart;
          final match = RegExp(
            r'name="declared_category"\r?\n\r?\n([A-Z]+)',
          ).firstMatch(decodedMultipart);
          if (match != null) {
            echoedCategory = match.group(1)!;
          }
        } else {
          final decoded = jsonDecode(request.body) as Map<String, dynamic>;
          capturedJsonBodies.add(decoded);
          echoedCategory =
              decoded['declared_category']?.toString() ?? 'OTHER';
        }

        final bodyBytes = utf8.encode(jsonEncode({
          'success': true,
          'data': {
            'id': '99',
            'declared_category': echoedCategory,
            'estimated_category': echoedCategory,
            'is_demo_result': !contentType.contains('multipart/form-data'),
            'recommendations': [],
          },
        }));
        return http.Response.bytes(
          bodyBytes,
          201,
          headers: {'Content-Type': 'application/json; charset=utf-8'},
        );
      });

      final tokenStorage = InMemoryAuthTokenStorage();
      await tokenStorage.saveToken('test_token');
      final repo = ApiAnalysisRepository(
        apiClient: ApiClient(client: mockHttp, tokenStorage: tokenStorage),
      );

      // Every selectable option produces exact canonical value in JSON payload
      for (final option in PlasticCategory.selectableOptions) {
        final result = await repo.analyzePlastic(
          PlasticAnalysisInput(
            imagePath: null,
            polymerCategory: option.apiValue,
            weightKg: 1.5,
            condition: 'clean',
          ),
        );
        expect(capturedJsonBodies.last['declared_category'], option.apiValue);
        expect(result.polymerCategory, option.apiValue);
      }

      // Null and unsupported/numeric values omit declared_category completely
      for (final badValue in [null, '', '1', '3', '7', 'UNKNOWN']) {
        await repo.analyzePlastic(
          PlasticAnalysisInput(
            imagePath: null,
            polymerCategory: badValue,
            weightKg: 1.0,
            condition: 'clean',
          ),
        );
        expect(
          capturedJsonBodies.last.containsKey('declared_category'),
          isFalse,
          reason: 'Expected "$badValue" to omit declared_category',
        );
      }

      // Multipart upload sends canonical declared_category
      final tmpFile = _createTempJpgFile();
      try {
        await repo.analyzePlastic(
          PlasticAnalysisInput(
            imagePath: tmpFile.path,
            isCameraOrGallery: true,
            polymerCategory: PlasticCategory.mixed,
            weightKg: 2.0,
            condition: 'clean',
          ),
        );
        expect(capturedMultipartBody, contains('name="declared_category"'));
        expect(capturedMultipartBody, contains('MIXED'));
      } finally {
        if (tmpFile.existsSync()) tmpFile.deleteSync();
      }
    });

    testWidgets(
      'AnalysisScreen dropdown stores canonical API values (never numeric 1..7) and handles unsupported ViewModel state safely',
      (tester) async {
        final capturedInputs = <PlasticAnalysisInput>[];
        final fakeRepo = _CapturingAnalysisRepository(capturedInputs);
        final vm = AnalysisViewModel(analysisRepository: fakeRepo);

        // Unsupported/numeric value passed programmatically is normalized to null
        vm.setPolymer('3');
        expect(vm.polymerCategory, isNull);

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.lightTheme,
            home: AnalysisScreen(
              viewModel: vm,
              navigationViewModel: NavigationViewModel(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final dropdownFinder = find.byType(DropdownButton<String>);
        expect(dropdownFinder, findsOneWidget);

        // Verify dropdown items expose all 6 canonical backend categories + null
        final dropdown = tester.widget<DropdownButton<String>>(dropdownFinder);
        final itemValues = dropdown.items!.map((i) => i.value).toList();
        expect(
          itemValues,
          equals([null, 'PET', 'HDPE', 'LDPE', 'PP', 'MIXED', 'OTHER']),
        );

        // Select 'PP' via UI dropdown interaction
        await tester.ensureVisible(dropdownFinder);
        await tester.tap(dropdownFinder);
        await tester.pumpAndSettle();
        await tester.tap(
          find.text('PP (#5) - Sedotan, Kotak Makanan Microwave').last,
        );
        await tester.pumpAndSettle();

        expect(vm.polymerCategory, equals('PP'));

        // Submit analysis and verify canonical category reaches repository
        final result = await vm.submitAnalysis();
        expect(result, isNotNull);
        expect(capturedInputs.single.polymerCategory, equals('PP'));
      },
    );
  });
}

class _CapturingAnalysisRepository implements AnalysisRepository {
  final List<PlasticAnalysisInput> captured;

  _CapturingAnalysisRepository(this.captured);

  @override
  Future<PlasticAnalysisResult> analyzePlastic(
    PlasticAnalysisInput input,
  ) async {
    captured.add(input);
    return PlasticAnalysisResult(
      id: '1',
      localAsset: 'assets/images/hasil_analisis_caps.png',
      materialTitle: 'Material ${input.polymerCategory ?? "OTHER"}',
      polymerCategory: input.polymerCategory ?? 'OTHER',
      polymerCode: 'Tipe #5',
      meltingPoint: '160° - 170° C',
      avoidedEmission: '~1.7 kg CO₂/kg',
      qualitativeNote: 'Test result',
      ideas: const [],
      isSimulated: true,
    );
  }
}
