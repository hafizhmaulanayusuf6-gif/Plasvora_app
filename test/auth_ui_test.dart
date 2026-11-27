import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plasvora/core/network/api_client.dart';
import 'package:plasvora/core/theme/app_theme.dart';
import 'package:plasvora/main.dart';
import 'package:plasvora/models/user_profile.dart';
import 'package:plasvora/repositories/analysis_repository.dart';
import 'package:plasvora/repositories/auth_repository.dart';
import 'package:plasvora/repositories/material_repository.dart';
import 'package:plasvora/viewmodels/analysis_viewmodel.dart';
import 'package:plasvora/viewmodels/auth_viewmodel.dart';
import 'package:plasvora/viewmodels/home_viewmodel.dart';
import 'package:plasvora/viewmodels/marketplace_viewmodel.dart';
import 'package:plasvora/viewmodels/navigation_viewmodel.dart';
import 'package:plasvora/views/auth/login_screen.dart';
import 'package:plasvora/views/auth/register_screen.dart';
import 'package:plasvora/views/main_navigation_screen.dart';

class FakeAuthRepository implements AuthRepository {
  bool loginCalled = false;
  bool registerCalled = false;
  bool shouldSucceed = true;
  Object? loginError;
  Object? registerError;
  Object? currentUserError;
  UserProfile? restoredUser;

  @override
  Future<UserProfile> login({required String email, required String password}) async {
    loginCalled = true;
    if (loginError != null) throw loginError!;
    if (!shouldSucceed) throw Exception('Email atau password tidak valid');
    return UserProfile(
      id: 1,
      name: 'Budi Santoso',
      email: email,
      createdAt: null,
    );
  }

  @override
  Future<UserProfile> register({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
    String? phone,
  }) async {
    registerCalled = true;
    if (registerError != null) throw registerError!;
    if (!shouldSucceed) throw Exception('Email sudah terdaftar');
    return UserProfile(
      id: 2,
      name: name,
      email: email,
      phone: phone,
      createdAt: null,
    );
  }

  @override
  Future<UserProfile> updateProfile({
    String? name,
    String? phone,
    bool? whatsappPublic,
  }) async {
    if (!shouldSucceed) throw Exception('Gagal memperbarui profil');
    return UserProfile(
      id: 1,
      name: name ?? 'Budi Santoso',
      email: 'budi@example.com',
      phone: phone,
      whatsappPublic: whatsappPublic ?? false,
      createdAt: null,
    );
  }

  @override
  Future<UserProfile?> getCurrentUser() async {
    if (currentUserError != null) throw currentUserError!;
    return restoredUser;
  }

  @override
  Future<void> logout() async {}

  @override
  Future<bool> isAuthenticated() async => restoredUser != null;
}

Widget _buildTestPlasvoraApp(AuthViewModel authViewModel) {
  final materialRepo = MockMaterialRepository();
  return PlasvoraApp(
    navigationViewModel: NavigationViewModel(),
    homeViewModel: HomeViewModel(materialRepository: materialRepo),
    analysisViewModel: AnalysisViewModel(
      analysisRepository: MockAnalysisRepository(),
    ),
    marketplaceViewModel: MarketplaceViewModel(
      materialRepository: materialRepo,
    ),
    authViewModel: authViewModel,
  );
}

void main() {
  group('Auth UI & Flow Tests (Stitch Design)', () {
    testWidgets('LoginScreen renders elements faithfully and navigates to RegisterScreen',
        (tester) async {
      final fakeRepo = FakeAuthRepository();
      final authViewModel = AuthViewModel(authRepository: fakeRepo);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: LoginScreen(authViewModel: authViewModel),
        ),
      );

      // Verify Brand & Headers
      expect(find.text('PLASVORA'), findsOneWidget);
      expect(find.text('Selamat Datang Kembali'), findsOneWidget);
      expect(find.text('Masuk ke akun Plasvora kamu.'), findsOneWidget);

      // Verify Input Fields
      expect(find.text('Email'), findsOneWidget);
      expect(find.text('Kata Sandi'), findsOneWidget);
      expect(find.text('Masuk'), findsOneWidget);
      expect(find.text('Daftar'), findsOneWidget);

      // Tap on 'Daftar' to trigger navigation
      await tester.ensureVisible(find.text('Daftar'));
      await tester.tap(find.text('Daftar'));
      await tester.pumpAndSettle();

      // Verify RegisterScreen is pushed
      expect(find.widgetWithText(ElevatedButton, 'Buat Akun'), findsOneWidget);
      expect(find.text('Nama Lengkap'), findsOneWidget);
      expect(find.text('Konfirmasi Kata Sandi'), findsOneWidget);
      expect(find.text('Saya menyetujui Ketentuan Layanan & Kebijakan Privasi'), findsOneWidget);
    });

    testWidgets('Login validation blocks empty submit', (tester) async {
      final fakeRepo = FakeAuthRepository();
      final authViewModel = AuthViewModel(authRepository: fakeRepo);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: LoginScreen(authViewModel: authViewModel),
        ),
      );

      await tester.tap(find.text('Masuk'));
      await tester.pumpAndSettle();

      expect(find.text('Email wajib diisi.'), findsOneWidget);
      expect(fakeRepo.loginCalled, isFalse);
    });

    testWidgets('Register form validation requires name, valid email, and matching password',
        (tester) async {
      final fakeRepo = FakeAuthRepository();
      final authViewModel = AuthViewModel(authRepository: fakeRepo);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: RegisterScreen(authViewModel: authViewModel),
        ),
      );

      // Tap Buat Akun without inputs
      final buttonFinder = find.widgetWithText(ElevatedButton, 'Buat Akun');
      await tester.ensureVisible(buttonFinder);
      await tester.tap(buttonFinder);
      await tester.pumpAndSettle();

      expect(find.text('Nama lengkap wajib diisi.'), findsOneWidget);
      expect(fakeRepo.registerCalled, isFalse);
    });
  });

  group('BUG-01 Auth Error Routing & Recovery Tests (PlasvoraApp)', () {
    testWidgets(
      'Scenario A: failed login keeps LoginScreen visible, shows error, and allows retry to succeed',
      (tester) async {
        final fakeRepo = FakeAuthRepository()
          ..loginError = ApiException(
            'Email atau kata sandi salah.',
            statusCode: 401,
          );
        final authViewModel = AuthViewModel(authRepository: fakeRepo);

        await tester.pumpWidget(_buildTestPlasvoraApp(authViewModel));
        await tester.pumpAndSettle();

        expect(find.byType(LoginScreen), findsOneWidget);

        await tester.enterText(
          find.byType(TextFormField).at(0),
          'budi@plasvora.id',
        );
        await tester.enterText(
          find.byType(TextFormField).at(1),
          'wrong-password',
        );
        await tester.tap(find.widgetWithText(ElevatedButton, 'Masuk'));
        await tester.pumpAndSettle();

        // Must stay on LoginScreen and NOT show the 403 page
        expect(find.byType(LoginScreen), findsOneWidget);
        expect(find.text('Akses Dibatasi'), findsNothing);
        expect(find.text('Email atau kata sandi salah.'), findsOneWidget);
        expect(authViewModel.state, AuthState.unauthenticated);
        expect(authViewModel.isLoading, isFalse);

        // Correct password and retry -> transitions cleanly to MainNavigationScreen
        fakeRepo.loginError = null;
        await tester.enterText(
          find.byType(TextFormField).at(1),
          'correct-password',
        );
        await tester.tap(find.widgetWithText(ElevatedButton, 'Masuk'));
        await tester.pumpAndSettle();

        expect(authViewModel.state, AuthState.authenticated);
        expect(find.byType(MainNavigationScreen), findsOneWidget);
        expect(find.byType(LoginScreen), findsNothing);
      },
    );

    testWidgets(
      'Scenario B: failed registration keeps RegisterScreen visible, shows validation error, and keeps LoginScreen beneath',
      (tester) async {
        final fakeRepo = FakeAuthRepository()
          ..registerError = ApiException(
            'Validasi gagal.',
            statusCode: 422,
            errors: {
              'email': ['Email sudah terdaftar di Plasvora.'],
            },
          );
        final authViewModel = AuthViewModel(authRepository: fakeRepo);

        await tester.pumpWidget(_buildTestPlasvoraApp(authViewModel));
        await tester.pumpAndSettle();

        await tester.ensureVisible(find.text('Daftar'));
        await tester.tap(find.text('Daftar'));
        await tester.pumpAndSettle();
        expect(find.byType(RegisterScreen), findsOneWidget);

        await tester.enterText(find.byType(TextFormField).at(0), 'Siti Aminah');
        await tester.enterText(
          find.byType(TextFormField).at(1),
          'siti@plasvora.id',
        );
        await tester.enterText(find.byType(TextFormField).at(3), 'password123');
        await tester.enterText(find.byType(TextFormField).at(4), 'password123');

        final submitBtn = find.widgetWithText(ElevatedButton, 'Buat Akun');
        await tester.ensureVisible(submitBtn);
        await tester.tap(submitBtn);
        await tester.pumpAndSettle();

        // RegisterScreen stays mounted and shows exact server error
        expect(find.byType(RegisterScreen), findsOneWidget);
        expect(find.text('Akses Dibatasi'), findsNothing);
        expect(find.text('Email sudah terdaftar di Plasvora.'), findsOneWidget);
        expect(authViewModel.state, AuthState.unauthenticated);
        expect(authViewModel.isLoading, isFalse);

        // Retry with updated email -> succeeds and lands on MainNavigationScreen
        fakeRepo.registerError = null;
        await tester.enterText(
          find.byType(TextFormField).at(1),
          'siti.baru@plasvora.id',
        );
        await tester.ensureVisible(submitBtn);
        await tester.tap(submitBtn);
        await tester.pumpAndSettle();

        expect(authViewModel.state, AuthState.authenticated);
        expect(find.byType(MainNavigationScreen), findsOneWidget);
        expect(find.byType(RegisterScreen), findsNothing);
      },
    );

    testWidgets(
      'Scenario D: genuine HTTP 403 Forbidden still routes to Akses Dibatasi screen',
      (tester) async {
        // 1. Session restore 403
        final restoreRepo = FakeAuthRepository()
          ..currentUserError = ApiException(
            'Akun Anda dibatasi sementara.',
            statusCode: 403,
          );
        final restoreVm = AuthViewModel(authRepository: restoreRepo);

        await tester.pumpWidget(_buildTestPlasvoraApp(restoreVm));
        await tester.pumpAndSettle();

        expect(restoreVm.state, AuthState.error);
        expect(find.text('Akses Dibatasi'), findsOneWidget);
        expect(find.text('Akun Anda dibatasi sementara.'), findsOneWidget);

        // 2. Explicit 403 on login is NOT silently downgraded to normal login failure
        final login403Repo = FakeAuthRepository()
          ..loginError = ApiException(
            'Akun dibekukan oleh administrator.',
            statusCode: 403,
          );
        final login403Vm = AuthViewModel(authRepository: login403Repo);

        await tester.pumpWidget(_buildTestPlasvoraApp(login403Vm));
        await tester.pumpAndSettle();

        await tester.enterText(
          find.byType(TextFormField).at(0),
          'blocked@plasvora.id',
        );
        await tester.enterText(
          find.byType(TextFormField).at(1),
          'password123',
        );
        await tester.tap(find.widgetWithText(ElevatedButton, 'Masuk'));
        await tester.pumpAndSettle();

        expect(login403Vm.state, AuthState.error);
        expect(find.text('Akses Dibatasi'), findsOneWidget);
        expect(find.text('Akun dibekukan oleh administrator.'), findsOneWidget);
      },
    );

    testWidgets(
      'Scenario E: network failure on login stays on LoginScreen with meaningful error and recovers on retry',
      (tester) async {
        final fakeRepo = FakeAuthRepository()
          ..loginError = const SocketException('Failed host lookup');
        final authViewModel = AuthViewModel(authRepository: fakeRepo);

        await tester.pumpWidget(_buildTestPlasvoraApp(authViewModel));
        await tester.pumpAndSettle();

        await tester.enterText(
          find.byType(TextFormField).at(0),
          'budi@plasvora.id',
        );
        await tester.enterText(
          find.byType(TextFormField).at(1),
          'password123',
        );
        await tester.tap(find.widgetWithText(ElevatedButton, 'Masuk'));
        await tester.pumpAndSettle();

        expect(find.byType(LoginScreen), findsOneWidget);
        expect(find.text('Akses Dibatasi'), findsNothing);
        expect(find.text('Koneksi Terganggu'), findsNothing);
        expect(
          find.text(
            'Tidak dapat terhubung ke server. Periksa koneksi internet Anda.',
          ),
          findsOneWidget,
        );
        expect(authViewModel.state, AuthState.unauthenticated);
        expect(authViewModel.isLoading, isFalse);

        // Retry after network recovers
        fakeRepo.loginError = null;
        await tester.tap(find.widgetWithText(ElevatedButton, 'Masuk'));
        await tester.pumpAndSettle();

        expect(authViewModel.state, AuthState.authenticated);
        expect(find.byType(MainNavigationScreen), findsOneWidget);
      },
    );
  });
}
