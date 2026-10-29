import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:plasvora/core/network/api_client.dart';
import 'package:plasvora/models/plastic_analysis.dart';
import 'package:plasvora/repositories/analysis_repository.dart';

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
}
