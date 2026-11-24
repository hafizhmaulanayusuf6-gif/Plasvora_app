import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:plasvora/core/network/api_client.dart';
import 'package:plasvora/core/theme/app_theme.dart';
import 'package:plasvora/core/utils/video_link_validator.dart';
import 'package:plasvora/core/widgets/app_bottom_nav.dart';
import 'package:plasvora/models/gallery_work.dart';
import 'package:plasvora/models/plastic_analysis.dart';
import 'package:plasvora/models/user_profile.dart';
import 'package:plasvora/repositories/analysis_repository.dart';
import 'package:plasvora/repositories/auth_repository.dart';
import 'package:plasvora/repositories/gallery_repository.dart';
import 'package:plasvora/repositories/material_repository.dart';
import 'package:plasvora/viewmodels/analysis_viewmodel.dart';
import 'package:plasvora/viewmodels/auth_viewmodel.dart';
import 'package:plasvora/viewmodels/gallery_viewmodel.dart';
import 'package:plasvora/viewmodels/home_viewmodel.dart';
import 'package:plasvora/viewmodels/marketplace_viewmodel.dart';
import 'package:plasvora/viewmodels/navigation_viewmodel.dart';
import 'package:plasvora/views/analysis/analysis_result_screen.dart';
import 'package:plasvora/views/auth/login_screen.dart';
import 'package:plasvora/views/gallery/create_gallery_work_screen.dart';
import 'package:plasvora/views/gallery/gallery_detail_screen.dart';
import 'package:plasvora/views/gallery/gallery_screen.dart';
import 'package:plasvora/views/gallery/my_gallery_works_screen.dart';
import 'package:plasvora/views/main_navigation_screen.dart';

class _StubAuthRepo implements AuthRepository {
  final UserProfile? user;
  _StubAuthRepo(this.user);

  @override
  Future<UserProfile?> getCurrentUser() async => user;
  @override
  Future<bool> isAuthenticated() async => user != null;
  @override
  Future<UserProfile> login({
    required String email,
    required String password,
  }) async =>
      user!;
  @override
  Future<void> logout() async {}
  @override
  Future<UserProfile> register({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
    String? phone,
  }) async =>
      user!;
  @override
  Future<UserProfile> updateProfile({
    String? name,
    String? phone,
    bool? whatsappPublic,
  }) async =>
      user!;
}

class _ControllableGalleryRepository implements GalleryRepository {
  final Future<GalleryPage> Function({
    String? query,
    GalleryDifficulty? difficulty,
    String sort,
    int page,
    int perPage,
  })? onFetchGallery;

  final Future<GalleryWork> Function(int id)? onFetchDetail;
  final Future<GalleryPage> Function({int page, int perPage})? onFetchMyWorks;
  final Future<GalleryWork> Function({
    required String title,
    required GalleryDifficulty difficulty,
    required List<String> materials,
    List<String> tools,
    required List<String> steps,
    List<String> videoLinks,
    required List<String> imagePaths,
    required bool ownershipConfirmed,
  })? onCreateWork;
  final Future<GalleryLikeResult> Function(int id)? onToggleLike;
  final Future<void> Function(int id)? onDeleteWork;

  _ControllableGalleryRepository({
    this.onFetchGallery,
    this.onFetchDetail,
    this.onFetchMyWorks,
    this.onCreateWork,
    this.onToggleLike,
    this.onDeleteWork,
  });

  @override
  Future<GalleryPage> fetchGallery({
    String? query,
    GalleryDifficulty? difficulty,
    String sort = 'latest',
    int page = 1,
    int perPage = 12,
  }) {
    if (onFetchGallery != null) {
      return onFetchGallery!(
        query: query,
        difficulty: difficulty,
        sort: sort,
        page: page,
        perPage: perPage,
      );
    }
    return Future.value(const GalleryPage(
      items: [],
      currentPage: 1,
      lastPage: 1,
      perPage: 12,
      total: 0,
    ));
  }

  @override
  Future<GalleryWork> fetchWorkDetail(int id) {
    if (onFetchDetail != null) return onFetchDetail!(id);
    throw ApiException('Not found', statusCode: 404);
  }

  @override
  Future<GalleryPage> fetchMyWorks({int page = 1, int perPage = 12}) {
    if (onFetchMyWorks != null) {
      return onFetchMyWorks!(page: page, perPage: perPage);
    }
    return Future.value(const GalleryPage(
      items: [],
      currentPage: 1,
      lastPage: 1,
      perPage: 12,
      total: 0,
    ));
  }

  @override
  Future<GalleryWork> createWork({
    required String title,
    required GalleryDifficulty difficulty,
    required List<String> materials,
    List<String> tools = const [],
    required List<String> steps,
    List<String> videoLinks = const [],
    required List<String> imagePaths,
    required bool ownershipConfirmed,
  }) {
    if (onCreateWork != null) {
      return onCreateWork!(
        title: title,
        difficulty: difficulty,
        materials: materials,
        tools: tools,
        steps: steps,
        videoLinks: videoLinks,
        imagePaths: imagePaths,
        ownershipConfirmed: ownershipConfirmed,
      );
    }
    throw UnimplementedError();
  }

  @override
  Future<GalleryWork> updateWork({
    required int id,
    required String title,
    required GalleryDifficulty difficulty,
    required List<String> materials,
    List<String> tools = const [],
    required List<String> steps,
    List<String> videoLinks = const [],
    List<String> newImagePaths = const [],
    List<int> removeImageIds = const [],
  }) =>
      throw UnimplementedError();

  @override
  Future<void> deleteWork(int id) {
    if (onDeleteWork != null) return onDeleteWork!(id);
    return Future.value();
  }

  @override
  Future<GalleryLikeResult> toggleLike(int id) {
    if (onToggleLike != null) return onToggleLike!(id);
    return Future.value(const GalleryLikeResult(liked: true, likesCount: 1));
  }
}

void main() {
  late bool previousAllowRuntimeFetching;

  setUpAll(() {
    previousAllowRuntimeFetching = GoogleFonts.config.allowRuntimeFetching;
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  tearDownAll(() {
    GoogleFonts.config.allowRuntimeFetching = previousAllowRuntimeFetching;
  });

  group('VideoLinkValidator Unit Tests', () {
    test('accepts allowed HTTPS video hosts and true subdomains', () {
      const allowed = [
        'https://youtube.com/watch?v=abc',
        'https://www.youtube.com/watch?v=abc',
        'https://m.youtube.com/shorts/xyz',
        'https://youtu.be/abc123',
        'https://tiktok.com/@plasvora/video/123',
        'https://vm.tiktok.com/ZM12345/',
        'https://instagram.com/reel/abc/',
        'https://www.instagram.com/p/xyz/',
      ];
      for (final url in allowed) {
        expect(VideoLinkValidator.isValid(url), isTrue, reason: url);
      }
      expect(
        VideoLinkValidator.extractDisplayHost('https://www.youtube.com/watch?v=1'),
        'youtube.com',
      );
      expect(
        VideoLinkValidator.extractDisplayHost('https://vm.tiktok.com/ZM123/'),
        'vm.tiktok.com',
      );
    });

    test('rejects non-HTTPS, spoofed hosts, credentials, and plain text', () {
      const rejected = [
        '',
        '   ',
        'http://youtube.com/watch?v=abc',
        'https://evilyoutube.com/watch?v=abc',
        'https://youtube.com.evil.com/watch?v=abc',
        'https://evil.com/?u=youtube.com',
        'https://user@youtube.com/watch?v=abc',
        'https://user:pass@youtu.be/abc',
        'https://vimeo.com/123456',
        'bukan tautan video',
        'https://youtube.com/watch?v=abc extra',
      ];
      for (final url in rejected) {
        expect(VideoLinkValidator.isValid(url), isFalse, reason: url);
        expect(VideoLinkValidator.validate(url), isNotNull, reason: url);
      }
    });
  });

  group('GalleryWork Model & UpcyclingIdea Draft Parsing', () {
    test('GalleryWork.fromJson parses full and defensive edge payloads safely', () {
      final work = GalleryWork.fromJson({
        'id': '42',
        'title': 'Pot Hidroponik PET',
        'difficulty': 'menengah',
        'cover_image_url': null,
        'images': [
          {'id': '2', 'url': 'https://example.com/2.jpg', 'sort_order': 1},
          {'id': '1', 'url': 'https://example.com/1.jpg', 'sort_order': 0},
        ],
        'materials': ['Botol PET', '  ', 'Kain Flanel'],
        'tools': null,
        'steps': ['Langkah 1', 'Langkah 2'],
        'video_links': ['https://youtu.be/abc'],
        'likes_count': '7',
        'liked_by_me': 1,
        'author': {'id': '9', 'name': 'Budi'},
        'status': 'rejected',
        'rejection_reason': 'Foto terlalu gelap',
      });

      expect(work.id, 42);
      expect(work.difficulty, GalleryDifficulty.menengah);
      expect(work.images.first.id, 1);
      expect(work.effectiveCoverUrl, 'https://example.com/1.jpg');
      expect(work.materials, ['Botol PET', 'Kain Flanel']);
      expect(work.tools, isEmpty);
      expect(work.likesCount, 7);
      expect(work.likedByMe, isTrue);
      expect(work.status, GalleryWorkStatus.rejected);
      expect(work.rejectionReason, 'Foto terlalu gelap');
      expect(work.author.name, 'Budi');
      expect(GalleryWorkStatus.approved.label, 'Tayang');
      expect(GalleryWorkStatus.rejected.label, 'Ditolak');
    });

    test('GalleryWorkDraft.fromUpcyclingIdea maps fields conservatively without photos', () {
      const result = PlasticAnalysisResult(
        id: 'an-1',
        imagePath: '/tmp/raw_trash_photo.jpg',
        localAsset: 'assets/images/logo.png',
        objectName: 'Botol Air Mineral',
        components: [
          MaterialComponent(
            id: 'body',
            partName: 'Badan botol',
            materialType: 'PET',
            verificationNote: 'Cek kode #1',
          ),
          MaterialComponent(
            id: 'cap',
            partName: 'Tutup botol',
            materialType: 'uncertain',
            verificationNote: 'Cek tutup',
          ),
        ],
        materialTitle: 'Botol PET',
        polymerCategory: 'PET',
        polymerCode: '#1',
        meltingPoint: '250 C',
        avoidedEmission: '0.5 kg CO2',
        qualitativeNote: 'Bersih',
        ideas: [],
      );

      const idea = UpcyclingIdea(
        id: 'idea-1',
        title: 'Pot Hidroponik Sumbu Mini',
        difficulty: 'Tingkat Mudah',
        description: 'Pot tanaman sederhana',
        imageAsset: 'assets/images/logo.png',
        componentIds: ['body'],
        tools: 'Gunting, cutter; sumbu kain flanel',
        steps:
            '1. Potong botol menjadi 2 bagian. 2. Balikkan bagian atas ke wadah bawah. 3. Pasang sumbu flanel.',
      );

      final draft = GalleryWorkDraft.fromUpcyclingIdea(idea, result);

      expect(draft.title, 'Pot Hidroponik Sumbu Mini');
      expect(draft.difficulty, GalleryDifficulty.mudah);
      expect(draft.materials, ['Badan botol (PET)']);
      expect(draft.tools, ['Gunting', 'cutter', 'sumbu kain flanel']);
      expect(draft.steps.length, 3);
      expect(draft.steps[0], 'Potong botol menjadi 2 bagian.');
      expect(draft.steps[1], 'Balikkan bagian atas ke wadah bawah.');
      expect(draft.steps[2], 'Pasang sumbu flanel.');
      expect(draft.videoLinks, isEmpty);
    });
  });

  group('ApiGalleryRepository HTTP & Multipart Contract Tests', () {
    test('fetchGallery passes filters and parses pagination meta', () async {
      Uri? capturedUri;
      String? capturedAuth;
      final storage = InMemoryAuthTokenStorage();
      await storage.saveToken('tok-123');

      final client = ApiClient(
        tokenStorage: storage,
        client: MockClient((request) async {
          capturedUri = request.url;
          capturedAuth = request.headers['Authorization'];
          return http.Response(
            jsonEncode({
              'success': true,
              'data': [
                {
                  'id': 10,
                  'title': 'Pot PET',
                  'difficulty': 'mudah',
                  'likes_count': 3,
                  'liked_by_me': true,
                  'author': {'id': 2, 'name': 'Siti'},
                  'materials_count': 2,
                  'steps_count': 3,
                },
              ],
              'meta': {
                'current_page': 2,
                'last_page': 3,
                'per_page': 12,
                'total': 25,
              },
            }),
            200,
          );
        }),
      );

      final repo = ApiGalleryRepository(apiClient: client);
      final page = await repo.fetchGallery(
        query: 'Pot',
        difficulty: GalleryDifficulty.mudah,
        sort: 'popular',
        page: 2,
      );

      expect(capturedAuth, 'Bearer tok-123');
      expect(capturedUri?.queryParameters['q'], 'Pot');
      expect(capturedUri?.queryParameters['difficulty'], 'mudah');
      expect(capturedUri?.queryParameters['sort'], 'popular');
      expect(capturedUri?.queryParameters['page'], '2');
      expect(page.items.length, 1);
      expect(page.hasMore, isTrue);
      expect(page.total, 25);
    });

    test('createWork sends multipart fields & files and surfaces 422 errors', () async {
      final tempFile = File('${Directory.systemTemp.path}/plasvora_test_img.jpg');
      await tempFile.writeAsBytes([0xFF, 0xD8, 0xFF, 0xD9]);
      addTearDown(() async {
        if (await tempFile.exists()) await tempFile.delete();
      });

      String? capturedBody;
      final storage = InMemoryAuthTokenStorage();
      await storage.saveToken('tok-create');

      final client = ApiClient(
        tokenStorage: storage,
        client: MockClient((request) async {
          capturedBody = latin1.decode(request.bodyBytes);
          return http.Response(
            jsonEncode({
              'success': false,
              'message': 'Data tidak valid.',
              'errors': {
                'title': ['Nama karya minimal 3 karakter.'],
              },
            }),
            422,
          );
        }),
      );

      final repo = ApiGalleryRepository(apiClient: client);
      await expectLater(
        () => repo.createWork(
          title: 'AB',
          difficulty: GalleryDifficulty.mudah,
          materials: ['Botol PET'],
          steps: ['Cuci botol.'],
          imagePaths: [tempFile.path],
          ownershipConfirmed: true,
        ),
        throwsA(
          isA<ApiException>()
              .having((e) => e.statusCode, 'statusCode', 422)
              .having(
                (e) => e.errors?['title'],
                'title error',
                ['Nama karya minimal 3 karakter.'],
              ),
        ),
      );

      expect(capturedBody, contains('name="materials[0]"'));
      expect(capturedBody, contains('name="steps[0]"'));
      expect(capturedBody, contains('name="ownership_confirmed"'));
      expect(capturedBody, contains('name="images[]"'));
    });

    test('updateWork sends _method=PATCH, clear flags, and remove_image_ids', () async {
      String? capturedBody;
      final client = ApiClient(
        tokenStorage: InMemoryAuthTokenStorage(),
        client: MockClient((request) async {
          capturedBody = latin1.decode(request.bodyBytes);
          return http.Response(
            jsonEncode({
              'success': true,
              'data': {
                'id': 5,
                'title': 'Judul Revisi',
                'difficulty': 'sulit',
                'materials': ['Botol PET'],
                'tools': [],
                'steps': ['Langkah 1'],
                'video_links': [],
                'images': [
                  {'id': 20, 'url': 'https://example.com/20.jpg', 'sort_order': 0},
                ],
                'likes_count': 0,
                'liked_by_me': false,
                'status': 'approved',
                'published_at': '2026-11-23T10:00:00Z',
                'author': {'id': 1, 'name': 'Rina'},
              },
            }),
            200,
          );
        }),
      );

      final repo = ApiGalleryRepository(apiClient: client);
      final updated = await repo.updateWork(
        id: 5,
        title: 'Judul Revisi',
        difficulty: GalleryDifficulty.sulit,
        materials: ['Botol PET'],
        tools: const [],
        steps: ['Langkah 1'],
        videoLinks: const [],
        removeImageIds: const [19],
      );

      expect(capturedBody, contains('name="_method"'));
      expect(capturedBody, contains('PATCH'));
      expect(capturedBody, contains('name="clear_tools"'));
      expect(capturedBody, contains('name="clear_video_links"'));
      expect(capturedBody, contains('name="remove_image_ids[0]"'));
      expect(updated.status, GalleryWorkStatus.approved);
    });

    test('handles 401 and network exceptions cleanly', () async {
      final unauthClient = ApiClient(
        tokenStorage: InMemoryAuthTokenStorage(),
        client: MockClient(
          (_) async => http.Response(
            jsonEncode({'message': 'Unauthenticated'}),
            401,
          ),
        ),
      );
      final unauthRepo = ApiGalleryRepository(apiClient: unauthClient);
      await expectLater(
        () => unauthRepo.fetchMyWorks(),
        throwsA(isA<ApiException>().having((e) => e.statusCode, '401', 401)),
      );

      final offlineClient = ApiClient(
        tokenStorage: InMemoryAuthTokenStorage(),
        client: MockClient((_) async => throw const SocketException('offline')),
      );
      final offlineRepo = ApiGalleryRepository(apiClient: offlineClient);
      await expectLater(
        () => offlineRepo.fetchGallery(),
        throwsA(isA<ApiException>()),
      );
    });
  });

  group('GalleryViewModel State, Optimistic Like, Stale Guard & Logout Isolation', () {
    test('pagination appends items and filter change resets to page 1', () async {
      final requestedPages = <int>[];
      final repo = _ControllableGalleryRepository(
        onFetchGallery: ({
          String? query,
          GalleryDifficulty? difficulty,
          String sort = 'latest',
          int page = 1,
          int perPage = 12,
        }) async {
          requestedPages.add(page);
          return GalleryPage(
            items: [
              GalleryWork(
                id: page * 10,
                title: 'Karya Halaman $page',
                difficulty: difficulty ?? GalleryDifficulty.mudah,
                author: const GalleryAuthor(id: 1, name: 'Rina'),
                status: GalleryWorkStatus.approved,
              ),
            ],
            currentPage: page,
            lastPage: 2,
            perPage: perPage,
            total: 2,
          );
        },
      );

      final vm = GalleryViewModel(galleryRepository: repo);
      await vm.loadFeed();
      expect(vm.works.length, 1);
      expect(vm.hasMoreFeed, isTrue);

      await vm.loadMoreFeed();
      expect(vm.works.length, 2);
      expect(vm.hasMoreFeed, isFalse);

      await vm.setDifficulty(GalleryDifficulty.sulit);
      expect(requestedPages, [1, 2, 1]);
      expect(vm.works.length, 1);
      expect(vm.works.first.difficulty, GalleryDifficulty.sulit);
    });

    test('optimistic like updates immediately and rolls back on failure', () async {
      final completer = Completer<GalleryLikeResult>();
      final initialWork = GalleryWork(
        id: 7,
        title: 'Lampu PET',
        difficulty: GalleryDifficulty.mudah,
        likesCount: 5,
        likedByMe: false,
        author: const GalleryAuthor(id: 2, name: 'Budi'),
        status: GalleryWorkStatus.approved,
      );

      final repo = _ControllableGalleryRepository(
        onFetchGallery: ({
          String? query,
          GalleryDifficulty? difficulty,
          String sort = 'latest',
          int page = 1,
          int perPage = 12,
        }) async {
          return GalleryPage(
            items: [initialWork],
            currentPage: 1,
            lastPage: 1,
            perPage: 12,
            total: 1,
          );
        },
        onToggleLike: (_) => completer.future,
      );

      final vm = GalleryViewModel(galleryRepository: repo);
      await vm.loadFeed();

      final toggleFuture = vm.toggleLike(7);
      // Optimistic state applied immediately before future settles
      expect(vm.works.first.likedByMe, isTrue);
      expect(vm.works.first.likesCount, 6);

      completer.completeError(ApiException('Server error', statusCode: 500));
      final err = await toggleFuture;

      expect(err, 'Server error');
      expect(vm.works.first.likedByMe, isFalse);
      expect(vm.works.first.likesCount, 5);
    });

    test('stale response guard ignores older out-of-order search result', () async {
      final firstSearch = Completer<GalleryPage>();
      final secondSearch = Completer<GalleryPage>();
      var callCount = 0;

      final repo = _ControllableGalleryRepository(
        onFetchGallery: ({
          String? query,
          GalleryDifficulty? difficulty,
          String sort = 'latest',
          int page = 1,
          int perPage = 12,
        }) {
          callCount++;
          return callCount == 1 ? firstSearch.future : secondSearch.future;
        },
      );

      final vm = GalleryViewModel(galleryRepository: repo);
      final f1 = vm.setSearchQuery('pertama');
      final f2 = vm.setSearchQuery('kedua');

      secondSearch.complete(GalleryPage(
        items: [
          GalleryWork(
            id: 2,
            title: 'Hasil Kedua',
            difficulty: GalleryDifficulty.mudah,
            author: const GalleryAuthor(id: 1, name: 'A'),
          ),
        ],
        currentPage: 1,
        lastPage: 1,
        perPage: 12,
        total: 1,
      ));
      await f2;

      firstSearch.complete(GalleryPage(
        items: [
          GalleryWork(
            id: 1,
            title: 'Hasil Stale Pertama',
            difficulty: GalleryDifficulty.mudah,
            author: const GalleryAuthor(id: 1, name: 'A'),
          ),
        ],
        currentPage: 1,
        lastPage: 1,
        perPage: 12,
        total: 1,
      ));
      await f1;

      expect(vm.works.length, 1);
      expect(vm.works.first.title, 'Hasil Kedua');
    });

    test('clearUserData wipes myWorks, detailCache, likedByMe, and stale loads', () async {
      final staleMyWorks = Completer<GalleryPage>();
      final repo = _ControllableGalleryRepository(
        onFetchGallery: ({
          String? query,
          GalleryDifficulty? difficulty,
          String sort = 'latest',
          int page = 1,
          int perPage = 12,
        }) async {
          return GalleryPage(
            items: [
              GalleryWork(
                id: 1,
                title: 'Publik',
                difficulty: GalleryDifficulty.mudah,
                likedByMe: true,
                likesCount: 3,
                author: const GalleryAuthor(id: 2, name: 'Budi'),
              ),
            ],
            currentPage: 1,
            lastPage: 1,
            perPage: 12,
            total: 1,
          );
        },
        onFetchMyWorks: ({int page = 1, int perPage = 12}) =>
            staleMyWorks.future,
      );

      final vm = GalleryViewModel(galleryRepository: repo);
      await vm.loadFeed();
      expect(vm.works.first.likedByMe, isTrue);

      final myFuture = vm.loadMyWorks();
      vm.clearUserData();

      expect(vm.works.first.likedByMe, isFalse);
      expect(vm.myWorks, isEmpty);

      staleMyWorks.complete(GalleryPage(
        items: [
          GalleryWork(
            id: 99,
            title: 'Rahasia User A',
            difficulty: GalleryDifficulty.mudah,
            author: const GalleryAuthor(id: 1, name: 'User A'),
            status: GalleryWorkStatus.pending,
          ),
        ],
        currentPage: 1,
        lastPage: 1,
        perPage: 12,
        total: 1,
      ));
      await myFuture;

      expect(vm.myWorks, isEmpty);
    });

    test('createWork immediately publishes and refreshes loaded public Gallery feed once',
        () async {
      final stored = <GalleryWork>[
        GalleryWork(
          id: 1,
          title: 'Karya Lama',
          difficulty: GalleryDifficulty.mudah,
          author: const GalleryAuthor(id: 2, name: 'Budi'),
          status: GalleryWorkStatus.approved,
          publishedAt: DateTime(2026, 11, 22),
        ),
      ];
      var fetchGalleryCalls = 0;

      final repo = _ControllableGalleryRepository(
        onFetchGallery: ({
          String? query,
          GalleryDifficulty? difficulty,
          String sort = 'latest',
          int page = 1,
          int perPage = 12,
        }) async {
          fetchGalleryCalls++;
          return GalleryPage(
            items: List<GalleryWork>.from(stored),
            currentPage: 1,
            lastPage: 1,
            perPage: perPage,
            total: stored.length,
          );
        },
        onCreateWork: ({
          required String title,
          required GalleryDifficulty difficulty,
          required List<String> materials,
          List<String> tools = const [],
          required List<String> steps,
          List<String> videoLinks = const [],
          required List<String> imagePaths,
          required bool ownershipConfirmed,
        }) async {
          final created = GalleryWork(
            id: 200,
            title: title,
            difficulty: difficulty,
            materials: materials,
            steps: steps,
            author: const GalleryAuthor(id: 1, name: 'Rina'),
            status: GalleryWorkStatus.approved,
            publishedAt: DateTime(2026, 11, 23),
          );
          stored.insert(0, created);
          return created;
        },
      );

      final vm = GalleryViewModel(galleryRepository: repo);
      await vm.loadFeed();
      expect(fetchGalleryCalls, 1);
      expect(vm.works.length, 1);

      final created = await vm.createWork(
        title: 'Botol Semprot Tanaman',
        difficulty: GalleryDifficulty.mudah,
        materials: const ['Botol PET'],
        steps: const ['Pasang kepala semprot.'],
        imagePaths: const ['fake/cover.jpg'],
        ownershipConfirmed: true,
      );

      expect(created, isNotNull);
      expect(created!.status, GalleryWorkStatus.approved);
      // Refreshed exactly once without duplicate calls
      expect(fetchGalleryCalls, 2);
      expect(vm.works.first.id, 200);
      expect(vm.works.first.title, 'Botol Semprot Tanaman');
      expect(vm.myWorks.first.id, 200);
    });
  });

  group('Gallery Screens & Integration Widget Tests', () {
    testWidgets('GalleryScreen filters, sorts, and guards guest Bagikan Karya CTA',
        (tester) async {
      final galleryVm = GalleryViewModel(
        galleryRepository: MockGalleryRepository(),
      );
      final navVm = NavigationViewModel();
      final guestAuthVm = AuthViewModel(authRepository: _StubAuthRepo(null));
      await guestAuthVm.checkAuthSession();

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: GalleryScreen(
            viewModel: galleryVm,
            navigationViewModel: navVm,
            authViewModel: guestAuthVm,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Pot Hidroponik Mini dari Botol PET'), findsOneWidget);
      expect(find.text('Dompet Anyaman Kemasan Sachet Kopi'), findsOneWidget);

      // Filter by Sulit
      await tester.tap(find.widgetWithText(ChoiceChip, 'Sulit'));
      await tester.pumpAndSettle();
      expect(find.text('Dompet Anyaman Kemasan Sachet Kopi'), findsOneWidget);
      expect(find.text('Pot Hidroponik Mini dari Botol PET'), findsNothing);

      // Reset to Semua and sort by Terpopuler
      await tester.tap(find.widgetWithText(ChoiceChip, 'Semua'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Terpopuler'));
      await tester.pumpAndSettle();
      expect(galleryVm.sortBy, 'popular');

      // Guest tap Bagikan Karya -> opens LoginScreen
      await tester.tap(find.text('Bagikan Karya'));
      await tester.pumpAndSettle();
      expect(find.byType(LoginScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
        'GalleryDetailScreen hides empty Alat/Video, shows Video notice + author status & rejection',
        (tester) async {
      Uri? launchedUri;
      final authorWork = GalleryWork(
        id: 55,
        title: 'Tas Anyaman Plastik',
        difficulty: GalleryDifficulty.sulit,
        materials: const ['20 bungkus sachet kopi'],
        tools: const [], // empty -> section must be hidden
        steps: const ['Lipat strip plastik.', 'Anyam menjadi pola kotak.'],
        videoLinks: const ['https://youtu.be/dQw4w9WgXcQ'],
        likesCount: 4,
        likedByMe: false,
        author: const GalleryAuthor(id: 1, name: 'Rina Kartika'),
        status: GalleryWorkStatus.rejected,
        rejectionReason: 'Foto hasil akhir kurang terang.',
      );

      final galleryVm = GalleryViewModel(
        galleryRepository: MockGalleryRepository(
          initialWorks: [authorWork],
          currentUserId: 1,
        ),
      );
      final authVm = AuthViewModel(
        authRepository: _StubAuthRepo(
          UserProfile(
            id: 1,
            name: 'Rina Kartika',
            email: 'rina@plasvora.test',
          ),
        ),
      );
      await authVm.checkAuthSession();

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: GalleryDetailScreen(
            workId: 55,
            initialWork: authorWork,
            viewModel: galleryVm,
            authViewModel: authVm,
            urlLauncher: (uri) async {
              launchedUri = uri;
              return true;
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Tas Anyaman Plastik'), findsOneWidget);
      expect(find.text('Ditolak'), findsOneWidget);
      expect(
        find.textContaining('Foto hasil akhir kurang terang.'),
        findsOneWidget,
      );
      expect(find.text('Edit Karya'), findsOneWidget);
      expect(find.text('Bahan'), findsOneWidget);
      expect(find.text('Alat'), findsNothing); // hidden when empty
      expect(find.text('Langkah-Langkah'), findsOneWidget);
      expect(find.text('Video Tutorial'), findsOneWidget);
      expect(
        find.text('Tautan video dibuka di aplikasi eksternal.'),
        findsOneWidget,
      );

      // Tap video link -> confirmation dialog -> launches external URL
      await tester.ensureVisible(find.textContaining('Tonton Tutorial 1'));
      await tester.pumpAndSettle();
      await tester.tap(find.textContaining('Tonton Tutorial 1'));
      await tester.pumpAndSettle();

      expect(find.text('Buka di Aplikasi Eksternal?'), findsOneWidget);
      await tester.tap(find.text('Buka'));
      await tester.pumpAndSettle();
      expect(launchedUri.toString(), 'https://youtu.be/dQw4w9WgXcQ');
      expect(tester.takeException(), isNull);
    });

    testWidgets(
        'CreateGalleryWorkScreen enforces ownership declaration, uses Posting CTA, publishes immediately with Tayang badge',
        (tester) async {
      final galleryVm = GalleryViewModel(
        galleryRepository: MockGalleryRepository(initialWorks: []),
      );
      final authVm = AuthViewModel(
        authRepository: _StubAuthRepo(
          UserProfile(
            id: 1,
            name: 'Rina Kartika',
            email: 'rina@plasvora.test',
          ),
        ),
      );
      await authVm.checkAuthSession();

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: CreateGalleryWorkScreen(
            viewModel: galleryVm,
            authViewModel: authVm,
            imagePickerOverride: (_) async => ['fake/local/cover.jpg'],
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Ownership declaration checkbox is visible with exact wording & no moderation copy
      expect(
        find.text(
          'Saya menyatakan bahwa karya dan foto ini adalah milik saya sendiri serta aman dibagikan ke komunitas Plasvora.',
        ),
        findsOneWidget,
      );
      expect(
        find.text(
          'Karya baru akan ditinjau terlebih dahulu sebelum tampil di Galeri publik.',
        ),
        findsNothing,
      );
      expect(find.text('Kirim untuk Diverifikasi'), findsNothing);
      expect(find.text('Posting'), findsOneWidget);

      final postingBtnFinder = find.widgetWithText(ElevatedButton, 'Posting');
      expect(tester.widget<ElevatedButton>(postingBtnFinder).onPressed, isNull);

      // Add a photo via test seam -> Sampul badge appears
      await tester.ensureVisible(find.text('Tambah Foto'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Tambah Foto'));
      await tester.pumpAndSettle();
      expect(find.text('Sampul'), findsOneWidget);

      // Fill required fields, leaving ownership checkbox unchecked
      final textFields = find.byType(TextField);
      await tester.ensureVisible(textFields.at(0));
      await tester.pumpAndSettle();
      await tester.enterText(textFields.at(0), 'Tempat Pensil Botol PET');

      await tester.ensureVisible(textFields.at(1));
      await tester.pumpAndSettle();
      await tester.enterText(textFields.at(1), 'Botol PET 600ml');

      await tester.ensureVisible(textFields.at(2));
      await tester.pumpAndSettle();
      await tester.enterText(textFields.at(2), 'Potong botol dan rapikan tepinya.');
      await tester.pumpAndSettle();

      // Unchecked declaration prevents posting and shows validation message
      await tester.ensureVisible(postingBtnFinder);
      await tester.pumpAndSettle();
      expect(
        find.text('Anda wajib menyetujui pernyataan kepemilikan karya.'),
        findsOneWidget,
      );
      expect(tester.widget<ElevatedButton>(postingBtnFinder).onPressed, isNull);

      // Check ownership declaration -> validation message clears and Posting enables
      await tester.ensureVisible(find.byType(CheckboxListTile));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(CheckboxListTile));
      await tester.pumpAndSettle();
      expect(
        find.text('Anda wajib menyetujui pernyataan kepemilikan karya.'),
        findsNothing,
      );
      expect(
        tester.widget<ElevatedButton>(postingBtnFinder).onPressed,
        isNotNull,
      );

      // Submit work -> shows immediate publication SnackBar and Tayang badge in MyGalleryWorksScreen
      await tester.ensureVisible(postingBtnFinder);
      await tester.pumpAndSettle();
      await tester.tap(postingBtnFinder);
      await tester.pumpAndSettle();

      expect(
        find.text('Karya berhasil diposting dan sekarang tampil di Galeri!'),
        findsOneWidget,
      );
      expect(find.byType(MyGalleryWorksScreen), findsOneWidget);
      expect(find.text('Tempat Pensil Botol PET'), findsOneWidget);
      expect(find.text('Tayang'), findsOneWidget);
      expect(find.text('Menunggu Verifikasi'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
        'CreateGalleryWorkScreen prevents duplicate submission during loading and surfaces API errors',
        (tester) async {
      final completer = Completer<GalleryWork>();
      var createCalls = 0;

      final repo = _ControllableGalleryRepository(
        onCreateWork: ({
          required String title,
          required GalleryDifficulty difficulty,
          required List<String> materials,
          List<String> tools = const [],
          required List<String> steps,
          List<String> videoLinks = const [],
          required List<String> imagePaths,
          required bool ownershipConfirmed,
        }) {
          createCalls++;
          return completer.future;
        },
      );

      final galleryVm = GalleryViewModel(galleryRepository: repo);
      final authVm = AuthViewModel(
        authRepository: _StubAuthRepo(
          UserProfile(
            id: 1,
            name: 'Rina Kartika',
            email: 'rina@plasvora.test',
          ),
        ),
      );
      await authVm.checkAuthSession();

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: CreateGalleryWorkScreen(
            viewModel: galleryVm,
            authViewModel: authVm,
            imagePickerOverride: (_) async => ['fake/local/cover.jpg'],
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Tambah Foto'));
      await tester.pumpAndSettle();

      final textFields = find.byType(TextField);
      await tester.ensureVisible(textFields.at(0));
      await tester.pumpAndSettle();
      await tester.enterText(textFields.at(0), 'Pot Gantung Botol');

      await tester.ensureVisible(textFields.at(1));
      await tester.pumpAndSettle();
      await tester.enterText(textFields.at(1), 'Botol PET 1L');

      await tester.ensureVisible(textFields.at(2));
      await tester.pumpAndSettle();
      await tester.enterText(textFields.at(2), 'Potong dan lubangi sisi botol.');

      await tester.ensureVisible(find.byType(CheckboxListTile));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(CheckboxListTile));
      await tester.pumpAndSettle();

      final postingBtnFinder = find.widgetWithText(ElevatedButton, 'Posting');
      await tester.ensureVisible(postingBtnFinder);
      await tester.pumpAndSettle();

      // Tap once -> enters loading state
      await tester.tap(postingBtnFinder);
      await tester.pump();
      expect(createCalls, 1);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Tapping again while busy does NOT trigger a duplicate API call
      final busyBtnFinder = find.byType(ElevatedButton);
      expect(tester.widget<ElevatedButton>(busyBtnFinder).onPressed, isNull);
      await tester.tap(busyBtnFinder, warnIfMissed: false);
      await tester.pump();
      expect(createCalls, 1);

      // Simulate API error -> displays friendly error message in UI
      completer.completeError(
        ApiException('Server sedang sibuk. Silakan coba lagi.', statusCode: 500),
      );
      await tester.pumpAndSettle();

      expect(
        find.text('Server sedang sibuk. Silakan coba lagi.'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets(
        'MyGalleryWorksScreen shows Tayang for approved, preserves rejected badge, and supports Edit & Delete',
        (tester) async {
      final approvedWork = GalleryWork(
        id: 10,
        title: 'Botol Semprot Tanaman',
        difficulty: GalleryDifficulty.mudah,
        images: const [
          GalleryImage(id: 1, url: 'https://example.com/1.jpg', sortOrder: 0),
        ],
        materials: const ['Botol PET'],
        steps: const ['Pasang nozzle semprot.'],
        likesCount: 3,
        author: const GalleryAuthor(id: 1, name: 'Rina Kartika'),
        status: GalleryWorkStatus.approved,
      );
      final rejectedWork = GalleryWork(
        id: 11,
        title: 'Karya Legacy Ditolak',
        difficulty: GalleryDifficulty.menengah,
        images: const [
          GalleryImage(id: 2, url: 'https://example.com/2.jpg', sortOrder: 0),
        ],
        materials: const ['Botol HDPE'],
        steps: const ['Potong rapi.'],
        likesCount: 0,
        author: const GalleryAuthor(id: 1, name: 'Rina Kartika'),
        status: GalleryWorkStatus.rejected,
        rejectionReason: 'Foto kurang jelas.',
      );

      final galleryVm = GalleryViewModel(
        galleryRepository: MockGalleryRepository(
          initialWorks: [approvedWork, rejectedWork],
          currentUserId: 1,
        ),
      );
      final authVm = AuthViewModel(
        authRepository: _StubAuthRepo(
          UserProfile(
            id: 1,
            name: 'Rina Kartika',
            email: 'rina@plasvora.test',
          ),
        ),
      );
      await authVm.checkAuthSession();

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: MyGalleryWorksScreen(
            viewModel: galleryVm,
            authViewModel: authVm,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Persisted statuses render accurately: Tayang for approved, Ditolak for rejected
      expect(find.text('Botol Semprot Tanaman'), findsOneWidget);
      expect(find.text('Tayang'), findsOneWidget);
      expect(find.text('Karya Legacy Ditolak'), findsOneWidget);
      expect(find.text('Ditolak'), findsOneWidget);
      expect(find.text('Menunggu Verifikasi'), findsNothing);

      // Edit button opens CreateGalleryWorkScreen without re-review moderation banner
      await tester.tap(find.text('Edit').first);
      await tester.pumpAndSettle();
      expect(find.byType(CreateGalleryWorkScreen), findsOneWidget);
      expect(find.text('Simpan Perubahan'), findsOneWidget);
      expect(find.textContaining('Menunggu Verifikasi'), findsNothing);

      // Pop back to MyGalleryWorksScreen
      Navigator.of(tester.element(find.byType(CreateGalleryWorkScreen))).pop();
      await tester.pumpAndSettle();

      // Delete button opens confirmation dialog and deletes work cleanly
      await tester.tap(find.text('Hapus').first);
      await tester.pumpAndSettle();
      expect(find.text('Hapus Karya?'), findsOneWidget);
      await tester.tap(find.widgetWithText(ElevatedButton, 'Hapus'));
      await tester.pumpAndSettle();

      expect(find.text('Karya berhasil dihapus.'), findsOneWidget);
      expect(galleryVm.myWorks.length, 1);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
        'AnalysisResultScreen Bagikan ke Galeri prefills CreateGalleryWorkScreen without photo',
        (tester) async {
      final galleryVm = GalleryViewModel(
        galleryRepository: MockGalleryRepository(),
      );
      final navVm = NavigationViewModel();
      final authVm = AuthViewModel(
        authRepository: _StubAuthRepo(
          UserProfile(
            id: 1,
            name: 'Rina Kartika',
            email: 'rina@plasvora.test',
          ),
        ),
      );
      await authVm.checkAuthSession();

      const result = PlasticAnalysisResult(
        id: 'an-99',
        localAsset: 'assets/images/logo.png',
        objectName: 'Botol Minuman PET',
        components: [
          MaterialComponent(
            id: 'body',
            partName: 'Badan botol',
            materialType: 'PET',
            verificationNote: 'Cek kode #1',
          ),
        ],
        materialTitle: 'Botol PET',
        polymerCategory: 'PET',
        polymerCode: '#1',
        meltingPoint: '250 C',
        avoidedEmission: '0.4 kg CO2',
        qualitativeNote: 'Bersih',
        ideas: [
          UpcyclingIdea(
            id: 'i1',
            title: 'Pot Gantung Botol PET',
            difficulty: 'Tingkat Mudah',
            description: 'Pot gantung hemat ruang',
            imageAsset: 'assets/images/logo.png',
            componentIds: ['body'],
            tools: 'Gunting, tali rafia',
            steps: '1. Lubangi sisi botol. 2. Pasang tali gantung.',
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: AnalysisResultScreen(
            result: result,
            navigationViewModel: navVm,
            authViewModel: authVm,
            galleryViewModel: galleryVm,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final shareBtn = find.text('Bagikan ke Galeri');
      await tester.ensureVisible(shareBtn);
      await tester.pumpAndSettle();
      await tester.tap(shareBtn);
      await tester.pumpAndSettle();

      expect(find.byType(CreateGalleryWorkScreen), findsOneWidget);
      expect(find.text('Pot Gantung Botol PET'), findsOneWidget);
      expect(find.text('Badan botol (PET)'), findsOneWidget);
      // Zero photos prefilled!
      expect(find.text('0/5'), findsOneWidget);
      expect(find.text('Sampul'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
        '5-tab navigation & GalleryScreen render with zero overflow on 360dp and 1.3x text scale',
        (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final navVm = NavigationViewModel();
      final materialRepo = MockMaterialRepository(simulateDelay: false);
      final galleryVm = GalleryViewModel(
        galleryRepository: MockGalleryRepository(),
      );
      final authVm = AuthViewModel(
        authRepository: _StubAuthRepo(
          UserProfile(
            id: 1,
            name: 'Rina Kartika',
            email: 'rina@plasvora.test',
          ),
        ),
      );
      await authVm.checkAuthSession();

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: const TextScaler.linear(1.3),
            ),
            child: child!,
          ),
          home: MainNavigationScreen(
            navigationViewModel: navVm,
            homeViewModel: HomeViewModel(materialRepository: materialRepo),
            analysisViewModel: AnalysisViewModel(
              analysisRepository: MockAnalysisRepository(),
            ),
            marketplaceViewModel: MarketplaceViewModel(
              materialRepository: materialRepo,
            ),
            galleryViewModel: galleryVm,
            authViewModel: authVm,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(AppBottomNav), findsOneWidget);
      await tester.tap(
        find.descendant(
          of: find.byType(AppBottomNav),
          matching: find.text('Galeri'),
        ),
      );
      await tester.pumpAndSettle();

      expect(navVm.currentIndex, NavigationViewModel.galleryIndex);
      expect(find.byType(GalleryScreen), findsOneWidget);
      expect(find.text('Galeri Karya'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
