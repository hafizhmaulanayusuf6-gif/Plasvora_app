import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plasvora/core/network/api_client.dart';
import 'package:plasvora/models/activity_item.dart';
import 'package:plasvora/models/plastic_analysis.dart';
import 'package:plasvora/repositories/activity_repository.dart';
import 'package:plasvora/repositories/analysis_repository.dart';
import 'package:plasvora/viewmodels/activity_viewmodel.dart';

/// Fake activity repository for isolated testing
class FakeActivityRepository implements ActivityRepository {
  final List<ActivityItem> _activities;
  final List<Map<String, dynamic>> _analyses;
  bool shouldThrowActivities = false;
  bool shouldThrowAnalyses = false;

  FakeActivityRepository({
    List<ActivityItem>? activities,
    List<Map<String, dynamic>>? analyses,
  })  : _activities = activities ?? [],
        _analyses = analyses ?? [];

  @override
  Future<List<ActivityItem>> getActivities() async {
    if (shouldThrowActivities) {
      throw ApiException('Gagal memuat aktivitas');
    }
    return _activities;
  }

  @override
  Future<List<Map<String, dynamic>>> getAnalysisHistories() async {
    if (shouldThrowAnalyses) {
      throw ApiException('Gagal memuat riwayat analisis');
    }
    return _analyses;
  }

  @override
  Future<PlasticAnalysisResult> getAnalysisDetail(int id) async {
    final found = _analyses.firstWhere(
      (e) => e['id'] == id || e['id']?.toString() == id.toString(),
      orElse: () => throw ApiException('Analisis tidak ditemukan'),
    );
    return ApiAnalysisRepository.mapBackendDataToResult(found);
  }
}

void main() {
  group('Fitur A: Pre-fill Form Listing dari Hasil Analisis AI', () {
    test(
        'mapBackendDataToResult memetakan data AI Vision ke PlasticAnalysisResult dengan benar',
        () {
      final backendJson = {
        'id': 10,
        'estimated_category': 'PET',
        'declared_category': 'PET',
        'is_demo_result': false,
        'image_url': 'https://example.com/storage/analyses/foto.jpg',
        'recommendations': {
          'object_name': 'Botol Air Mineral',
          'material_title': 'Botol PET Bersih',
          'polymer_code': 'Tipe #1',
          'melting_point': '250° - 260° C',
          'avoided_emission': '~2.1 kg CO₂/kg',
          'qualitative_note': 'Dianalisis AI.',
          'object_description': 'Botol bening bekas air mineral',
          'identification_summary': 'PET dengan resin code #1',
          'recommendations': [
            {
              'id': 'idea_1',
              'title': 'Furnitur Daur Ulang',
              'difficulty': 'Tingkat Menengah',
              'description': 'Dileburkan menjadi stool.',
            },
          ],
        },
      };

      final result = ApiAnalysisRepository.mapBackendDataToResult(backendJson);

      expect(result.id, equals('10'));
      expect(result.polymerCategory, equals('PET'));
      expect(result.materialTitle, equals('Botol PET Bersih'));
      expect(result.objectName, equals('Botol Air Mineral'));
      expect(result.polymerCode, equals('Tipe #1'));
      expect(result.meltingPoint, equals('250° - 260° C'));
      expect(result.isSimulated, isFalse);
      // imagePath harus diambil dari image_url backend
      expect(result.imagePath,
          equals('https://example.com/storage/analyses/foto.jpg'));
      expect(result.ideas, isNotEmpty);
    });

    test(
        'mapBackendDataToResult untuk rule-based (is_demo_result:true) memetakan ide dari List',
        () {
      final backendJson = {
        'id': 7,
        'estimated_category': 'HDPE',
        'declared_category': 'HDPE',
        'is_demo_result': true,
        'recommendations': [
          {
            'id': 'idea_1',
            'title': 'Tas Anyaman',
            'difficulty': 'Tingkat Mudah',
            'description': 'Tutup botol HDPE dianyam menjadi tas.',
          },
        ],
      };

      final result = ApiAnalysisRepository.mapBackendDataToResult(backendJson);

      expect(result.polymerCategory, equals('HDPE'));
      expect(result.isSimulated, isTrue);
      expect(result.ideas, isNotEmpty);
    });

    test(
        'Pre-fill kategori dari polymerCategory — MIXED dipetakan ke kategori valid',
        () {
      final backendJson = {
        'id': 5,
        'estimated_category': 'MIXED',
        'declared_category': 'MIXED',
        'is_demo_result': true,
        'recommendations': <Map<String, dynamic>>[],
      };

      final result = ApiAnalysisRepository.mapBackendDataToResult(backendJson);
      expect(result.polymerCategory, equals('MIXED'));
    });

    test(
        'imagePath menggunakan localImagePath jika tersedia, tidak dari image_url backend',
        () {
      final backendJson = {
        'id': 20,
        'estimated_category': 'PP',
        'is_demo_result': false,
        'image_url': 'https://backend.example.com/foto.jpg',
        'recommendations': {
          'object_name': 'Wadah PP',
          'material_title': 'Wadah PP Bekas',
          'polymer_code': 'Tipe #5',
          'melting_point': '160° - 170° C',
          'avoided_emission': '~1.7 kg CO₂/kg',
          'qualitative_note': 'Dianalisis AI.',
        },
      };

      // Jika localImagePath diberikan, ia harus diprioritaskan
      final resultWithLocal = ApiAnalysisRepository.mapBackendDataToResult(
        backendJson,
        localImagePath: '/local/path/foto.jpg',
      );
      expect(resultWithLocal.imagePath, equals('/local/path/foto.jpg'));

      // Jika localImagePath null, gunakan image_url backend
      final resultWithBackend = ApiAnalysisRepository.mapBackendDataToResult(
        backendJson,
      );
      expect(resultWithBackend.imagePath,
          equals('https://backend.example.com/foto.jpg'));
    });
  });

  group('Fitur B: Riwayat Analisis di ActivityViewModel', () {
    test('loadAnalysisHistories memuat dan memetakan riwayat analisis', () async {
      final fakeRepo = FakeActivityRepository(
        analyses: [
          {
            'id': 1,
            'estimated_category': 'PET',
            'declared_category': 'PET',
            'is_demo_result': true,
            'recommendations': [
              {'id': 'idea_1', 'title': 'Furnitur', 'difficulty': 'Tingkat Menengah', 'description': 'Stool'}
            ],
          },
          {
            'id': 2,
            'estimated_category': 'HDPE',
            'declared_category': 'HDPE',
            'is_demo_result': true,
            'recommendations': <Map<String, dynamic>>[],
          },
        ],
      );

      final vm = ActivityViewModel(activityRepository: fakeRepo);
      // Tunggu loading selesai
      await Future.delayed(const Duration(milliseconds: 50));

      expect(vm.isLoadingAnalyses, isFalse);
      expect(vm.analyses, hasLength(2));
      expect(vm.analyses.first.polymerCategory, equals('PET'));
      expect(vm.analyses.last.polymerCategory, equals('HDPE'));
    });

    test('loadAnalysisHistories menangkap error dan mengisi analysesError', () async {
      final fakeRepo = FakeActivityRepository();
      fakeRepo.shouldThrowAnalyses = true;

      final vm = ActivityViewModel(activityRepository: fakeRepo);
      await Future.delayed(const Duration(milliseconds: 50));

      expect(vm.isLoadingAnalyses, isFalse);
      expect(vm.analyses, isEmpty);
      expect(vm.analysesError, isNotNull);
      expect(vm.analysesError, contains('Gagal memuat riwayat analisis'));
    });

    test('setTabIndex mengubah selectedTabIndex dan notifyListeners', () async {
      final fakeRepo = FakeActivityRepository();
      final vm = ActivityViewModel(activityRepository: fakeRepo);
      await Future.delayed(const Duration(milliseconds: 50));

      expect(vm.selectedTabIndex, equals(0));

      bool notified = false;
      vm.addListener(() => notified = true);
      vm.setTabIndex(1);

      expect(vm.selectedTabIndex, equals(1));
      expect(notified, isTrue);
    });

    test('setTabIndex tidak notifyListeners jika index tidak berubah', () async {
      final fakeRepo = FakeActivityRepository();
      final vm = ActivityViewModel(activityRepository: fakeRepo);
      await Future.delayed(const Duration(milliseconds: 50));

      int notifyCount = 0;
      vm.addListener(() => notifyCount++);

      vm.setTabIndex(0); // Sama dengan nilai awal
      expect(notifyCount, equals(0));
    });

    test('getAnalysisDetail mengembalikan PlasticAnalysisResult dari repository', () async {
      final fakeRepo = FakeActivityRepository(
        analyses: [
          {
            'id': 42,
            'estimated_category': 'PP',
            'declared_category': 'PP',
            'is_demo_result': true,
            'recommendations': <Map<String, dynamic>>[],
          },
        ],
      );

      final vm = ActivityViewModel(activityRepository: fakeRepo);
      await Future.delayed(const Duration(milliseconds: 50));

      final detail = await vm.getAnalysisDetail(42);
      expect(detail.id, equals('42'));
      expect(detail.polymerCategory, equals('PP'));
    });
  });

  group('ActivityItem mapping untuk plastic_analysis type', () {
    test('ActivityItem.fromJson memetakan type plastic_analysis dengan benar', () {
      final json = {
        'type': 'plastic_analysis',
        'action': 'Analisis plastik selesai',
        'description': 'Analisis AI untuk: Botol Air Mineral (2.5 kg) - Kategori: PET',
        'status': 'completed',
        'reference_id': 10,
        'timestamp': '2026-11-14T10:30:00.000000Z',
      };

      final item = ActivityItem.fromJson(json);

      expect(item.type, equals('plastic_analysis'));
      expect(item.action, equals('Analisis plastik selesai'));
      expect(item.status, equals('completed'));
      expect(item.referenceId, equals(10));
      expect(item.timestamp, isNotNull);
    });

    test('ActivityItem.icon mengembalikan document_scanner untuk plastic_analysis', () {
      const item = ActivityItem(
        type: 'plastic_analysis',
        action: 'Analisis plastik selesai',
        description: 'Test',
        status: 'completed',
        rawTimestamp: '',
      );

      expect(item.icon.codePoint,
          equals(Icons.document_scanner_outlined.codePoint));
    });

    test('ActivityItem.statusLabel mengembalikan "Selesai" untuk completed', () {
      const item = ActivityItem(
        type: 'plastic_analysis',
        action: 'Analisis',
        description: '',
        status: 'completed',
        rawTimestamp: '',
      );

      expect(item.statusLabel, equals('Selesai'));
    });
  });

  group('Penanganan error pada ActivityViewModel', () {
    test('loadActivities menangkap error dan mengisi errorMessage', () async {
      final fakeRepo = FakeActivityRepository();
      fakeRepo.shouldThrowActivities = true;

      final vm = ActivityViewModel(activityRepository: fakeRepo);
      await Future.delayed(const Duration(milliseconds: 50));

      expect(vm.isLoading, isFalse);
      expect(vm.activities, isEmpty);
      expect(vm.errorMessage, isNotNull);
      expect(vm.errorMessage, contains('Gagal memuat aktivitas'));
    });

    test('refreshAll memperbarui baik activities maupun analyses', () async {
      final fakeRepo = FakeActivityRepository(
        analyses: [
          {
            'id': 1,
            'estimated_category': 'PET',
            'is_demo_result': true,
            'recommendations': <Map<String, dynamic>>[],
          },
        ],
      );

      final vm = ActivityViewModel(activityRepository: fakeRepo);
      await Future.delayed(const Duration(milliseconds: 50));

      // Panggil refreshAll dan tunggu
      await vm.refreshAll();

      expect(vm.isLoading, isFalse);
      expect(vm.isLoadingAnalyses, isFalse);
      expect(vm.analyses, hasLength(1));
    });
  });
}
