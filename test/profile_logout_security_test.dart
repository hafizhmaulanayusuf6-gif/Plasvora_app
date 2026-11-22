import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:plasvora/core/network/api_client.dart';
import 'package:plasvora/core/widgets/plasvora_header.dart';
import 'package:plasvora/main.dart';
import 'package:plasvora/models/user_address.dart';
import 'package:plasvora/repositories/address_repository.dart';
import 'package:plasvora/repositories/analysis_repository.dart';
import 'package:plasvora/repositories/auth_repository.dart';
import 'package:plasvora/repositories/material_repository.dart';
import 'package:plasvora/repositories/shipping_repository.dart';
import 'package:plasvora/viewmodels/address_viewmodel.dart';
import 'package:plasvora/viewmodels/analysis_viewmodel.dart';
import 'package:plasvora/viewmodels/auth_viewmodel.dart';
import 'package:plasvora/viewmodels/home_viewmodel.dart';
import 'package:plasvora/viewmodels/marketplace_viewmodel.dart';
import 'package:plasvora/viewmodels/navigation_viewmodel.dart';
import 'package:plasvora/views/address/address_list_screen.dart';
import 'package:plasvora/views/auth/login_screen.dart';
import 'package:plasvora/views/home/home_screen.dart';
import 'package:plasvora/views/main_navigation_screen.dart';
import 'package:plasvora/views/profile/edit_profile_screen.dart';
import 'package:plasvora/views/profile/profile_screen.dart';

class _MultiAccountFakeAddressRepository implements AddressRepository {
  final InMemoryAuthTokenStorage tokenStorage;
  final Map<String, List<UserAddress>> addressesByToken;
  int getCallCount = 0;

  _MultiAccountFakeAddressRepository({
    required this.tokenStorage,
    required this.addressesByToken,
  });

  @override
  Future<List<UserAddress>> getAddresses() async {
    getCallCount++;
    final token = await tokenStorage.getToken();
    if (token == null) return const [];
    return List<UserAddress>.from(addressesByToken[token] ?? const []);
  }

  @override
  Future<UserAddress> createAddress({
    String? label,
    required String recipientName,
    required String recipientPhone,
    required int destinationId,
    required String destinationLabel,
    required String addressDetail,
    String? postalCode,
    String? deliveryNote,
    bool? isDefault,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<UserAddress> updateAddress({
    required int id,
    String? label,
    String? recipientName,
    String? recipientPhone,
    int? destinationId,
    String? destinationLabel,
    String? addressDetail,
    String? postalCode,
    String? deliveryNote,
    bool? isDefault,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<void> deleteAddress(int id) {
    throw UnimplementedError();
  }
}

class _SessionHarness {
  final InMemoryAuthTokenStorage tokenStorage;
  final AuthViewModel authViewModel;
  final AddressViewModel addressViewModel;
  final NavigationViewModel navigationViewModel;
  final HomeViewModel homeViewModel;
  final AnalysisViewModel analysisViewModel;
  final MarketplaceViewModel marketplaceViewModel;
  final ShippingRepository shippingRepository;

  _SessionHarness({
    required this.tokenStorage,
    required this.authViewModel,
    required this.addressViewModel,
    required this.navigationViewModel,
    required this.homeViewModel,
    required this.analysisViewModel,
    required this.marketplaceViewModel,
    required this.shippingRepository,
  });

  Widget buildApp() {
    return PlasvoraApp(
      navigationViewModel: navigationViewModel,
      homeViewModel: homeViewModel,
      analysisViewModel: analysisViewModel,
      marketplaceViewModel: marketplaceViewModel,
      authViewModel: authViewModel,
      addressViewModel: addressViewModel,
      shippingRepository: shippingRepository,
    );
  }
}

Future<void> _openProfileTab(
  WidgetTester tester,
  NavigationViewModel navVm,
) async {
  if (navVm.currentIndex != 3) {
    final homeHeader = find.descendant(
      of: find.byType(HomeScreen),
      matching: find.byType(PlasvoraHeader),
    );
    final avatarFinder = find.descendant(
      of: homeHeader,
      matching: find.byWidgetPredicate(
        (widget) => widget is GestureDetector && widget.child is ClipRRect,
      ),
    );
    expect(avatarFinder, findsOneWidget);
    await tester.tap(avatarFinder);
    await tester.pumpAndSettle();
  }
  expect(navVm.currentIndex, 3);
  expect(find.byType(ProfileScreen), findsOneWidget);
}

Future<void> _scrollAndTap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
}

_SessionHarness _createHarness({
  required InMemoryAuthTokenStorage tokenStorage,
  required MockClientHandler httpHandler,
  required AddressRepository addressRepository,
}) {
  final apiClient = ApiClient(
    client: MockClient(httpHandler),
    tokenStorage: tokenStorage,
  );
  final authRepository = ApiAuthRepository(apiClient: apiClient);
  final materialRepository = MockMaterialRepository(simulateDelay: false);
  final analysisRepository = MockAnalysisRepository();
  final shippingRepository = MockShippingRepository();
  final addressViewModel = AddressViewModel(
    addressRepository: addressRepository,
  );
  final authViewModel = AuthViewModel(
    authRepository: authRepository,
    onSessionCleared: addressViewModel.clearUserData,
  );

  return _SessionHarness(
    tokenStorage: tokenStorage,
    authViewModel: authViewModel,
    addressViewModel: addressViewModel,
    navigationViewModel: NavigationViewModel(),
    homeViewModel: HomeViewModel(materialRepository: materialRepository),
    analysisViewModel: AnalysisViewModel(
      analysisRepository: analysisRepository,
    ),
    marketplaceViewModel: MarketplaceViewModel(
      materialRepository: materialRepository,
    ),
    shippingRepository: shippingRepository,
  );
}

Map<String, dynamic> _userJson({
  required int id,
  required String name,
  required String email,
  String? phone,
  bool whatsappPublic = false,
}) {
  return {
    'id': id,
    'name': name,
    'email': email,
    'phone': phone,
    'whatsapp_public': whatsappPublic,
  };
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

  group('Profile Logout Lifecycle & User Session Security', () {
    testWidgets(
      'Test A — EditProfileScreen opens, closes, and reopens cleanly without disposed controller or framework errors',
      (tester) async {
        final storage = InMemoryAuthTokenStorage();
        await storage.saveToken('token-user-a');

        final harness = _createHarness(
          tokenStorage: storage,
          addressRepository: MockAddressRepository(),
          httpHandler: (request) async {
            if (request.url.path.endsWith('/api/me')) {
              return http.Response(
                jsonEncode({
                  'success': true,
                  'data': _userJson(
                    id: 1,
                    name: 'Pengguna A',
                    email: 'a@plasvora.test',
                    phone: '6281234567890',
                  ),
                }),
                200,
              );
            }
            return http.Response(jsonEncode({'success': true}), 200);
          },
        );

        await tester.pumpWidget(harness.buildApp());
        await tester.pumpAndSettle();

        // 1. Navigasi ke tab Profil melalui avatar header lalu buka Edit Profil
        await _openProfileTab(tester, harness.navigationViewModel);
        expect(find.text('Pengguna A'), findsOneWidget);
        await _scrollAndTap(tester, find.text('Edit Profil'));
        await tester.pumpAndSettle();
        expect(find.byType(EditProfileScreen), findsOneWidget);

        await tester.enterText(find.byType(TextFormField), '081299998888');
        await tester.pump();

        // 2. Kembali ke ProfileScreen melalui tombol back aktual SimplePageAppBar
        final backButton = find.descendant(
          of: find.byType(EditProfileScreen),
          matching: find.widgetWithIcon(IconButton, Icons.arrow_back),
        );
        expect(backButton, findsOneWidget);
        await tester.tap(backButton);
        await tester.pumpAndSettle();
        expect(find.byType(EditProfileScreen), findsNothing);
        expect(tester.takeException(), isNull);

        // 3. Buka kembali Edit Profil — controller baru dibuat bersih dari state server
        await _scrollAndTap(tester, find.text('Edit Profil'));
        await tester.pumpAndSettle();
        expect(find.byType(EditProfileScreen), findsOneWidget);
        expect(find.text('6281234567890'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'Test B — Kelola Alamat Pengiriman pushes AddressListScreen and returns cleanly to ProfileScreen',
      (tester) async {
        final storage = InMemoryAuthTokenStorage();
        await storage.saveToken('token-user-a');

        final addressRepo = _MultiAccountFakeAddressRepository(
          tokenStorage: storage,
          addressesByToken: {
            'token-user-a': const [
              UserAddress(
                id: 101,
                label: 'Rumah A',
                recipientName: 'Penerima A',
                recipientPhone: '6281234567890',
                destinationId: 4949,
                destinationLabel: 'BRAGA, SUMUR BANDUNG, BANDUNG',
                addressDetail: 'Jl. Braga No. 1',
                isDefault: true,
              ),
            ],
          },
        );

        final harness = _createHarness(
          tokenStorage: storage,
          addressRepository: addressRepo,
          httpHandler: (request) async {
            if (request.url.path.endsWith('/api/me')) {
              return http.Response(
                jsonEncode({
                  'success': true,
                  'data': _userJson(
                    id: 1,
                    name: 'Pengguna A',
                    email: 'a@plasvora.test',
                  ),
                }),
                200,
              );
            }
            return http.Response(jsonEncode({'success': true}), 200);
          },
        );

        await tester.pumpWidget(harness.buildApp());
        await tester.pumpAndSettle();

        await _openProfileTab(tester, harness.navigationViewModel);
        await _scrollAndTap(tester, find.text('Kelola Alamat Pengiriman'));
        await tester.pumpAndSettle();

        expect(find.byType(AddressListScreen), findsOneWidget);
        expect(find.text('Rumah A'), findsOneWidget);
        expect(tester.takeException(), isNull);

        // Kembali ke ProfileScreen via tombol back aktual di SimplePageAppBar AddressListScreen
        final backButton = find.descendant(
          of: find.byType(AddressListScreen),
          matching: find.widgetWithIcon(IconButton, Icons.arrow_back),
        );
        expect(backButton, findsOneWidget);
        await tester.tap(backButton);
        await tester.pumpAndSettle();
        expect(find.byType(AddressListScreen), findsNothing);
        expect(find.byType(ProfileScreen), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'Test C — Logout asks confirmation before switching PlasvoraApp to LoginScreen and clears local token',
      (tester) async {
        final storage = InMemoryAuthTokenStorage();
        await storage.saveToken('token-user-a');

        String? logoutAuthHeader;
        int logoutRequestCount = 0;

        final harness = _createHarness(
          tokenStorage: storage,
          addressRepository: MockAddressRepository(),
          httpHandler: (request) async {
            if (request.url.path.endsWith('/api/me')) {
              return http.Response(
                jsonEncode({
                  'success': true,
                  'data': _userJson(
                    id: 1,
                    name: 'Pengguna A',
                    email: 'a@plasvora.test',
                  ),
                }),
                200,
              );
            }
            if (request.url.path.endsWith('/api/logout')) {
              logoutRequestCount++;
              logoutAuthHeader = request.headers['Authorization'];
              return http.Response(
                jsonEncode({'success': true, 'message': 'Logged out'}),
                200,
              );
            }
            return http.Response(jsonEncode({'success': true}), 200);
          },
        );

        await tester.pumpWidget(harness.buildApp());
        await tester.pumpAndSettle();
        expect(find.byType(MainNavigationScreen), findsOneWidget);

        await _openProfileTab(tester, harness.navigationViewModel);
        await _scrollAndTap(tester, find.text('Keluar dari Akun'));
        await tester.pumpAndSettle();

        // Dialog konfirmasi harus muncul sebelum logout dijalankan
        expect(find.text('Keluar dari Akun?'), findsOneWidget);
        expect(logoutRequestCount, 0);
        expect(find.byType(MainNavigationScreen), findsOneWidget);
        expect(find.byType(LoginScreen), findsNothing);

        // Konfirmasi keluar
        await tester.tap(find.text('Keluar'));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.byType(MainNavigationScreen), findsNothing);
        expect(find.byType(LoginScreen), findsOneWidget);
        expect(logoutRequestCount, 1);
        expect(logoutAuthHeader, 'Bearer token-user-a');
        expect(await storage.getToken(), isNull);
        expect(harness.authViewModel.state, AuthState.unauthenticated);
        expect(harness.authViewModel.currentUser, isNull);
      },
    );

    testWidgets(
      'Test D — User A address cache is completely cleared on logout and never leaks to User B',
      (tester) async {
        final storage = InMemoryAuthTokenStorage();
        await storage.saveToken('token-user-a');

        final addressRepo = _MultiAccountFakeAddressRepository(
          tokenStorage: storage,
          addressesByToken: {
            'token-user-a': const [
              UserAddress(
                id: 101,
                label: 'Rumah Rahasia A',
                recipientName: 'Rahasia User A',
                recipientPhone: '6281111111111',
                destinationId: 4949,
                destinationLabel: 'BRAGA, SUMUR BANDUNG, BANDUNG',
                addressDetail: 'Jl. Privat User A No. 99',
                isDefault: true,
              ),
            ],
            'token-user-b': const [
              UserAddress(
                id: 202,
                label: 'Gudang User B',
                recipientName: 'Penerima User B',
                recipientPhone: '6282222222222',
                destinationId: 6157,
                destinationLabel: 'BABAKANKARET, CIANJUR',
                addressDetail: 'Jl. Gudang User B No. 7',
                isDefault: true,
              ),
            ],
          },
        );

        final harness = _createHarness(
          tokenStorage: storage,
          addressRepository: addressRepo,
          httpHandler: (request) async {
            if (request.url.path.endsWith('/api/me')) {
              final auth = request.headers['Authorization'];
              if (auth == 'Bearer token-user-a') {
                return http.Response(
                  jsonEncode({
                    'success': true,
                    'data': _userJson(
                      id: 1,
                      name: 'User A',
                      email: 'a@plasvora.test',
                    ),
                  }),
                  200,
                );
              }
              return http.Response(
                jsonEncode({'message': 'Unauthenticated'}),
                401,
              );
            }
            if (request.url.path.endsWith('/api/logout')) {
              return http.Response(jsonEncode({'success': true}), 200);
            }
            if (request.url.path.endsWith('/api/login')) {
              return http.Response(
                jsonEncode({
                  'success': true,
                  'data': {
                    'token': 'token-user-b',
                    'user': _userJson(
                      id: 2,
                      name: 'User B',
                      email: 'b@plasvora.test',
                    ),
                  },
                }),
                200,
              );
            }
            return http.Response(jsonEncode({'success': true}), 200);
          },
        );

        await tester.pumpWidget(harness.buildApp());
        await tester.pumpAndSettle();

        // 1. User A memuat dan memilih alamat miliknya
        await harness.addressViewModel.loadAddresses();
        expect(harness.addressViewModel.addresses.length, 1);
        expect(
          harness.addressViewModel.selectedAddress?.addressDetail,
          'Jl. Privat User A No. 99',
        );

        // 2. User A keluar melalui tab Profil
        await _openProfileTab(tester, harness.navigationViewModel);
        await _scrollAndTap(tester, find.text('Keluar dari Akun'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Keluar'));
        await tester.pumpAndSettle();

        expect(find.byType(LoginScreen), findsOneWidget);
        expect(harness.addressViewModel.addresses, isEmpty);
        expect(harness.addressViewModel.selectedAddress, isNull);
        expect(harness.addressViewModel.defaultAddress, isNull);

        // 3. User B masuk pada proses & AddressViewModel yang sama
        final loggedIn = await harness.authViewModel.login(
          'b@plasvora.test',
          'password123',
        );
        expect(loggedIn, isTrue);
        await tester.pumpAndSettle();

        expect(find.byType(MainNavigationScreen), findsOneWidget);
        // Sebelum memuat alamat B, tidak boleh ada sisa alamat A
        expect(harness.addressViewModel.addresses, isEmpty);

        // 4. User B membuka Buku Alamat dari tab Profil dan hanya melihat alamat User B
        await _openProfileTab(tester, harness.navigationViewModel);
        await _scrollAndTap(tester, find.text('Kelola Alamat Pengiriman'));
        await tester.pumpAndSettle();

        expect(find.byType(AddressListScreen), findsOneWidget);
        expect(find.text('Gudang User B'), findsOneWidget);
        expect(find.text('Jl. Gudang User B No. 7'), findsOneWidget);
        expect(find.text('Rumah Rahasia A'), findsNothing);
        expect(find.text('Jl. Privat User A No. 99'), findsNothing);
        expect(harness.addressViewModel.addresses.length, 1);
        expect(harness.addressViewModel.addresses.first.id, 202);
      },
    );

    testWidgets(
      'Test E — Failed remote logout still deletes local token immediately and transitions to LoginScreen',
      (tester) async {
        final storage = InMemoryAuthTokenStorage();
        await storage.saveToken('token-offline-logout');

        bool tokenWasAlreadyDeletedBeforeRemoteFinish = false;

        final harness = _createHarness(
          tokenStorage: storage,
          addressRepository: MockAddressRepository(),
          httpHandler: (request) async {
            if (request.url.path.endsWith('/api/me')) {
              return http.Response(
                jsonEncode({
                  'success': true,
                  'data': _userJson(
                    id: 9,
                    name: 'User Offline',
                    email: 'offline@plasvora.test',
                  ),
                }),
                200,
              );
            }
            if (request.url.path.endsWith('/api/logout')) {
              // Pastikan token lokal SUDAH dihapus sebelum panggilan jaringan selesai/gagal
              tokenWasAlreadyDeletedBeforeRemoteFinish =
                  (await storage.getToken()) == null;
              throw const SocketException('Backend unreachable');
            }
            return http.Response(jsonEncode({'success': true}), 200);
          },
        );

        await tester.pumpWidget(harness.buildApp());
        await tester.pumpAndSettle();
        expect(find.byType(MainNavigationScreen), findsOneWidget);

        await _openProfileTab(tester, harness.navigationViewModel);
        await _scrollAndTap(tester, find.text('Keluar dari Akun'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Keluar'));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(tokenWasAlreadyDeletedBeforeRemoteFinish, isTrue);
        expect(await storage.getToken(), isNull);
        expect(harness.authViewModel.state, AuthState.unauthenticated);
        expect(harness.authViewModel.currentUser, isNull);
        expect(find.byType(LoginScreen), findsOneWidget);
      },
    );

    test(
      'AddressViewModel.clearUserData invalidates stale in-flight loadAddresses response',
      () async {
        final staleCompleter = Completer<List<UserAddress>>();
        final staleRepo = _StaleLoadAddressRepository(staleCompleter);
        final addressVm = AddressViewModel(addressRepository: staleRepo);

        final loadFuture = addressVm.loadAddresses();
        expect(addressVm.isLoading, isTrue);

        // Logout memanggil clearUserData sementara request User A masih berjalan
        addressVm.clearUserData();
        expect(addressVm.addresses, isEmpty);
        expect(addressVm.isLoading, isFalse);

        // Request lama User A baru tiba setelah logout — wajib diabaikan
        staleCompleter.complete(const [
          UserAddress(
            id: 999,
            label: 'Stale User A',
            recipientName: 'Stale',
            recipientPhone: '6281234567890',
            destinationId: 4949,
            destinationLabel: 'BANDUNG',
            addressDetail: 'Jl. Stale No. 1',
            isDefault: true,
          ),
        ]);
        await loadFuture;

        expect(addressVm.addresses, isEmpty);
        expect(addressVm.selectedAddress, isNull);
      },
    );
  });
}

class _StaleLoadAddressRepository implements AddressRepository {
  final Completer<List<UserAddress>> completer;

  _StaleLoadAddressRepository(this.completer);

  @override
  Future<List<UserAddress>> getAddresses() => completer.future;

  @override
  Future<UserAddress> createAddress({
    String? label,
    required String recipientName,
    required String recipientPhone,
    required int destinationId,
    required String destinationLabel,
    required String addressDetail,
    String? postalCode,
    String? deliveryNote,
    bool? isDefault,
  }) =>
      throw UnimplementedError();

  @override
  Future<UserAddress> updateAddress({
    required int id,
    String? label,
    String? recipientName,
    String? recipientPhone,
    int? destinationId,
    String? destinationLabel,
    String? addressDetail,
    String? postalCode,
    String? deliveryNote,
    bool? isDefault,
  }) =>
      throw UnimplementedError();

  @override
  Future<void> deleteAddress(int id) => throw UnimplementedError();
}
