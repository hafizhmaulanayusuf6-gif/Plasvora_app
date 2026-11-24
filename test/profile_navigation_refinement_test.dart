import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:plasvora/core/theme/app_theme.dart';
import 'package:plasvora/core/utils/display_formatters.dart';
import 'package:plasvora/core/widgets/app_bottom_nav.dart';
import 'package:plasvora/core/widgets/plasvora_header.dart';
import 'package:plasvora/core/widgets/simple_page_app_bar.dart';
import 'package:plasvora/models/order_item.dart';
import 'package:plasvora/models/user_profile.dart';
import 'package:plasvora/repositories/address_repository.dart';
import 'package:plasvora/repositories/analysis_repository.dart';
import 'package:plasvora/repositories/auth_repository.dart';
import 'package:plasvora/repositories/material_repository.dart';
import 'package:plasvora/repositories/order_repository.dart';
import 'package:plasvora/repositories/shipping_repository.dart';
import 'package:plasvora/viewmodels/address_viewmodel.dart';
import 'package:plasvora/viewmodels/analysis_viewmodel.dart';
import 'package:plasvora/viewmodels/auth_viewmodel.dart';
import 'package:plasvora/viewmodels/home_viewmodel.dart';
import 'package:plasvora/viewmodels/marketplace_viewmodel.dart';
import 'package:plasvora/viewmodels/navigation_viewmodel.dart';
import 'package:plasvora/viewmodels/order_viewmodel.dart';
import 'package:plasvora/views/activity/activity_screen.dart';
import 'package:plasvora/views/auth/login_screen.dart';
import 'package:plasvora/views/home/home_screen.dart';
import 'package:plasvora/views/main_navigation_screen.dart';
import 'package:plasvora/views/profile/profile_screen.dart';

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

class _EmptyOrderRepo implements OrderRepository {
  @override
  Future<OrderListPage> getOrders({
    required String role,
    String? status,
    int page = 1,
    int perPage = 15,
  }) async =>
      const OrderListPage(
        items: [],
        currentPage: 1,
        lastPage: 1,
        perPage: 15,
        total: 0,
      );

  @override
  Future<OrderItem> getOrderDetail(int orderId) => throw UnimplementedError();

  @override
  Future<OrderItem> createOrder({
    required int listingId,
    required int addressId,
    required String courierCode,
    required String courierService,
    String? buyerNote,
    required String idempotencyKey,
  }) =>
      throw UnimplementedError();

  @override
  Future<OrderItem> cancelOrder(int orderId, {String? reason}) =>
      throw UnimplementedError();

  @override
  Future<OrderItem> retryPayment(int orderId) => throw UnimplementedError();

  @override
  Future<OrderRefreshResult> refreshPaymentStatus(int orderId) =>
      throw UnimplementedError();

  @override
  Future<OrderItem> shipOrder({
    required int orderId,
    required String trackingNumber,
    String? shipmentNotes,
  }) =>
      throw UnimplementedError();

  @override
  Future<OrderItem> confirmDelivery(int orderId) => throw UnimplementedError();
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

  group('DisplayFormatters Unit Tests', () {
    test('deduplicateLocationLabel removes adjacent duplicate segments case-insensitively', () {
      expect(
        DisplayFormatters.deduplicateLocationLabel(
          'BOJONGHERANG, CIANJUR, CIANJUR, JAWA BARAT',
        ),
        'BOJONGHERANG, CIANJUR, JAWA BARAT',
      );
      expect(
        DisplayFormatters.deduplicateLocationLabel('Bandung, bandung, Jawa Barat'),
        'Bandung, Jawa Barat',
      );
      expect(DisplayFormatters.deduplicateLocationLabel(null), '');
      expect(DisplayFormatters.deduplicateLocationLabel('   '), '');
    });

    test('formatIndonesianEtd localizes ETD and provides safe Indonesian fallback', () {
      expect(
        DisplayFormatters.formatIndonesianEtd('2-3 day'),
        'Estimasi 2-3 hari',
      );
      expect(
        DisplayFormatters.formatIndonesianEtd('3 days'),
        'Estimasi 3 hari',
      );
      expect(
        DisplayFormatters.formatIndonesianEtd('1-2'),
        'Estimasi 1-2 hari',
      );
      expect(
        DisplayFormatters.formatIndonesianEtd(null),
        'Estimasi belum tersedia',
      );
      expect(
        DisplayFormatters.formatIndonesianEtd(' - '),
        'Estimasi belum tersedia',
      );
    });

    test('parseMinEtdDays extracts minimum day count safely', () {
      expect(DisplayFormatters.parseMinEtdDays('2-3 day'), 2);
      expect(DisplayFormatters.parseMinEtdDays('1 hari'), 1);
      expect(DisplayFormatters.parseMinEtdDays(null), isNull);
    });

    test('formatShortCourierTitle shortens verbose courier names for display only', () {
      expect(
        DisplayFormatters.formatShortCourierTitle(
          courierName: 'Jalur Nugraha Ekakurir (JNE)',
          courierCode: 'jne',
          service: 'REG',
        ),
        'JNE REG',
      );
      expect(
        DisplayFormatters.formatShortCourierTitle(
          courierName: 'POS Indonesia',
          courierCode: 'pos',
          service: 'Pos Reguler',
        ),
        'Pos Indonesia (Pos Reguler)',
      );
    });
  });

  group('Navigation Restructuring & ProfileScreen Refinement Tests', () {
    testWidgets('AppBottomNav displays 5 tabs including Galeri and Profil', (tester) async {
      final navVm = NavigationViewModel();
      final authVm = AuthViewModel(
        authRepository: _StubAuthRepo(
          UserProfile(
            id: 1,
            name: 'Rina Lestari',
            email: 'rina@plasvora.test',
            phone: '6281234567890',
            whatsappPublic: true,
          ),
        ),
      );
      await authVm.checkAuthSession();

      final materialRepo = MockMaterialRepository(simulateDelay: false);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: MainNavigationScreen(
            navigationViewModel: navVm,
            homeViewModel: HomeViewModel(materialRepository: materialRepo),
            analysisViewModel: AnalysisViewModel(
              analysisRepository: MockAnalysisRepository(),
            ),
            marketplaceViewModel: MarketplaceViewModel(
              materialRepository: materialRepo,
            ),
            authViewModel: authVm,
            addressViewModel: AddressViewModel(
              addressRepository: MockAddressRepository(),
            ),
            shippingRepository: MockShippingRepository(),
            orderViewModel: OrderViewModel(orderRepository: _EmptyOrderRepo()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 5 tab utama di AppBottomNav: Beranda, Analisis, Marketplace, Galeri, Profil
      final bottomNav = find.byType(AppBottomNav);
      expect(bottomNav, findsOneWidget);
      expect(find.descendant(of: bottomNav, matching: find.text('Beranda')), findsOneWidget);
      expect(find.descendant(of: bottomNav, matching: find.text('Analisis')), findsOneWidget);
      expect(find.descendant(of: bottomNav, matching: find.text('Marketplace')), findsOneWidget);
      expect(find.descendant(of: bottomNav, matching: find.text('Galeri')), findsOneWidget);
      expect(find.descendant(of: bottomNav, matching: find.text('Profil')), findsOneWidget);
      expect(find.descendant(of: bottomNav, matching: find.text('Aktivitas')), findsNothing);

      // Tap avatar di HomeScreen header saat authenticated -> berpindah ke tab Profil (index 4)
      final homeHeader = find.descendant(
        of: find.byType(HomeScreen),
        matching: find.byType(PlasvoraHeader),
      );
      final avatar = find.descendant(
        of: homeHeader,
        matching: find.byWidgetPredicate(
          (w) => w is GestureDetector && w.child is ClipRRect,
        ),
      );
      await tester.tap(avatar);
      await tester.pumpAndSettle();

      expect(navVm.currentIndex, NavigationViewModel.profileIndex);
      expect(find.byType(ProfileScreen), findsOneWidget);
      expect(find.text('Rina Lestari'), findsOneWidget);
      expect(find.text('rina@plasvora.test'), findsOneWidget);
      expect(find.text('+6281234567890'), findsOneWidget);
      expect(find.text('Edit Profil'), findsOneWidget);
      expect(find.text('Pesanan Saya'), findsOneWidget);
      expect(find.text('Karya Saya'), findsOneWidget);
      expect(find.text('Aktivitas'), findsOneWidget);
      expect(find.text('Kelola Alamat Pengiriman'), findsOneWidget);
      expect(find.text('Visibilitas WhatsApp'), findsOneWidget);
      expect(find.text('Publik'), findsOneWidget);

      // Profil -> Aktivitas membuka ActivityScreen dengan SimplePageAppBar lalu kembali ke Profil
      await tester.ensureVisible(find.text('Aktivitas'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Aktivitas'));
      await tester.pumpAndSettle();

      expect(find.byType(ActivityScreen), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(ActivityScreen),
          matching: find.byType(SimplePageAppBar),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byType(ActivityScreen),
          matching: find.byType(PlasvoraHeader),
        ),
        findsNothing,
      );

      final backBtn = find.descendant(
        of: find.byType(ActivityScreen),
        matching: find.widgetWithIcon(IconButton, Icons.arrow_back),
      );
      await tester.tap(backBtn);
      await tester.pumpAndSettle();

      expect(find.byType(ActivityScreen), findsNothing);
      expect(find.byType(ProfileScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Tapping PlasvoraHeader avatar when unauthenticated pushes LoginScreen', (tester) async {
      final navVm = NavigationViewModel();
      final authVm = AuthViewModel(authRepository: _StubAuthRepo(null));
      await authVm.checkAuthSession();

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: HomeScreen(
            viewModel: HomeViewModel(
              materialRepository: MockMaterialRepository(simulateDelay: false),
            ),
            navigationViewModel: navVm,
            authViewModel: authVm,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final avatar = find.descendant(
        of: find.byType(PlasvoraHeader),
        matching: find.byWidgetPredicate(
          (w) => w is GestureDetector && w.child is ClipRRect,
        ),
      );
      await tester.tap(avatar);
      await tester.pumpAndSettle();

      expect(find.byType(LoginScreen), findsOneWidget);
      expect(navVm.currentIndex, 0);
      expect(tester.takeException(), isNull);
    });

    testWidgets('ProfileScreen renders without overflow on 360dp viewport with 1.3x text scaling', (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final authVm = AuthViewModel(
        authRepository: _StubAuthRepo(
          UserProfile(
            id: 2,
            name: 'Nama Pengguna Yang Sangat Panjang Sekali Untuk Pengujian',
            email: 'pengguna.panjang@plasvora.example.com',
            phone: '6281234567890',
            whatsappPublic: false,
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
          home: ProfileScreen(
            authViewModel: authVm,
            addressViewModel: AddressViewModel(
              addressRepository: MockAddressRepository(),
            ),
            shippingRepository: MockShippingRepository(),
            orderViewModel: OrderViewModel(orderRepository: _EmptyOrderRepo()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Profil'), findsOneWidget);
      expect(find.text('Privat'), findsOneWidget);
    });
  });
}
