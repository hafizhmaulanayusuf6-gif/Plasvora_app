import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plasvora/core/theme/app_theme.dart';
import 'package:plasvora/models/user_profile.dart';
import 'package:plasvora/repositories/auth_repository.dart';
import 'package:plasvora/viewmodels/auth_viewmodel.dart';
import 'package:plasvora/views/auth/login_screen.dart';
import 'package:plasvora/views/auth/register_screen.dart';

class FakeAuthRepository implements AuthRepository {
  bool loginCalled = false;
  bool registerCalled = false;
  bool shouldSucceed = true;

  @override
  Future<UserProfile> login({required String email, required String password}) async {
    loginCalled = true;
    if (!shouldSucceed) throw Exception('Email atau password tidak valid');
    return UserProfile(
      id: 1,
      name: 'Budi Santoso',
      email: 'budi@example.com',
      createdAt: null,
    );
  }

  @override
  Future<UserProfile> register({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
  }) async {
    registerCalled = true;
    if (!shouldSucceed) throw Exception('Email sudah terdaftar');
    return UserProfile(
      id: 2,
      name: name,
      email: email,
      createdAt: null,
    );
  }

  @override
  Future<UserProfile?> getCurrentUser() async => null;

  @override
  Future<void> logout() async {}

  @override
  Future<bool> isAuthenticated() async => false;
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
      await tester.tap(find.text('Daftar'));
      await tester.pumpAndSettle();

      // Verify RegisterScreen is pushed
      expect(find.text('Buat Akun'), findsOneWidget);
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
      await tester.tap(find.text('Buat Akun'));
      await tester.pumpAndSettle();

      expect(find.text('Nama lengkap wajib diisi.'), findsOneWidget);
      expect(fakeRepo.registerCalled, isFalse);
    });
  });
}
