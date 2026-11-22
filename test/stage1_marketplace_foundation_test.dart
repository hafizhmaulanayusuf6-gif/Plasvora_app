import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:plasvora/core/network/api_client.dart';
import 'package:plasvora/core/theme/app_theme.dart';
import 'package:plasvora/core/utils/phone_utils.dart';
import 'package:plasvora/models/material_listing.dart';
import 'package:plasvora/models/user_profile.dart';
import 'package:plasvora/repositories/auth_repository.dart';
import 'package:plasvora/viewmodels/auth_viewmodel.dart';
import 'package:plasvora/views/profile/edit_profile_screen.dart';

class _Stage11FakeAuthRepository implements AuthRepository {
  UserProfile currentUser;
  bool shouldFailUpdate = false;
  int updateCallCount = 0;

  _Stage11FakeAuthRepository({required this.currentUser});

  @override
  Future<UserProfile?> getCurrentUser() async => currentUser;

  @override
  Future<bool> isAuthenticated() async => true;

  @override
  Future<UserProfile> login({
    required String email,
    required String password,
  }) async => currentUser;

  @override
  Future<void> logout() async {}

  @override
  Future<UserProfile> register({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
    String? phone,
  }) async => currentUser;

  @override
  Future<UserProfile> updateProfile({
    String? name,
    String? phone,
    bool? whatsappPublic,
  }) async {
    updateCallCount++;
    if (shouldFailUpdate) {
      throw ApiException('Gagal menyimpan pengaturan privasi.');
    }
    final nextPhone = phone != null
        ? PhoneUtils.normalizeIndonesianPhone(phone)
        : currentUser.phone;
    final nextPublic = nextPhone == null
        ? false
        : (whatsappPublic ?? currentUser.whatsappPublic);
    currentUser = currentUser.copyWith(
      name: name ?? currentUser.name,
      phone: nextPhone,
      clearPhone: phone != null && nextPhone == null,
      whatsappPublic: nextPublic,
    );
    return currentUser;
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

  group('Stage 1 — PhoneUtils & WhatsApp Link', () {
    test('normalizes valid Indonesian phone formats to 628...', () {
      expect(PhoneUtils.normalizeIndonesianPhone('081234567890'), '6281234567890');
      expect(PhoneUtils.normalizeIndonesianPhone('0812-3456-7890'), '6281234567890');
      expect(PhoneUtils.normalizeIndonesianPhone('+62 812 3456 7890'), '6281234567890');
      expect(PhoneUtils.normalizeIndonesianPhone('6281398765432'), '6281398765432');
    });

    test('rejects invalid or empty phone values', () {
      expect(PhoneUtils.normalizeIndonesianPhone(null), isNull);
      expect(PhoneUtils.normalizeIndonesianPhone('   '), isNull);
      expect(PhoneUtils.normalizeIndonesianPhone('12345'), isNull);
      expect(PhoneUtils.normalizeIndonesianPhone('abc0812345678'), isNull);
      expect(PhoneUtils.normalizeIndonesianPhone('+14155552671'), isNull);
      expect(PhoneUtils.validateOptionalIndonesianPhone(''), isNull);
      expect(PhoneUtils.validateOptionalIndonesianPhone('12345'), isNotNull);
    });

    test('builds properly encoded wa.me URI containing material name', () {
      final uri = PhoneUtils.buildSellerWhatsAppUri(
        sellerPhone: '+62 812-3456-7890',
        materialName: 'Botol PET Bening & Bersih',
      );

      expect(uri, isNotNull);
      expect(uri!.scheme, 'https');
      expect(uri.host, 'wa.me');
      expect(uri.path, '/6281234567890');
      expect(
        uri.queryParameters['text'],
        'Halo, saya tertarik dengan material Botol PET Bening & Bersih yang Anda jual di Plasvora. Apakah masih tersedia?',
      );
      expect(
        PhoneUtils.buildSellerWhatsAppUri(
          sellerPhone: null,
          materialName: 'Botol PET',
        ),
        isNull,
      );
    });
  });

  group('Stage 1 — UserProfile & MaterialListing Lot Semantics', () {
    test('UserProfile parses optional phone safely', () {
      final legacy = UserProfile.fromJson({
        'id': 1,
        'name': 'User Lama',
        'email': 'lama@plasvora.test',
      });
      expect(legacy.phone, isNull);

      final withPhone = UserProfile.fromJson({
        'id': 2,
        'name': 'User Baru',
        'email': 'baru@plasvora.test',
        'phone': '6281234567890',
      });
      expect(withPhone.phone, '6281234567890');
    });

    test('MaterialListing parses ownerPhone, origin metadata, and calculates display-only price/kg', () {
      final listing = MaterialListing.fromJson({
        'id': 10,
        'owner_id': 7,
        'owner': {
          'id': 7,
          'name': 'Penjual Bandung',
          'phone': '6281234567890',
        },
        'name': 'Tutup Botol HDPE 5kg',
        'category': 'HDPE',
        'weight_kg': '5.00',
        'condition': 'clean',
        'price': '15000.00',
        'is_free': false,
        'general_location': 'Kota Bandung',
        'origin_destination_id': 17485,
        'origin_label': 'Braga, Sumur Bandung, Bandung',
        'description': 'Satu lot bersih',
        'created_at': '2026-11-21T08:00:00Z',
      });

      expect(listing.ownerPhone, '6281234567890');
      expect(listing.originDestinationId, 17485);
      expect(listing.originLabel, 'Braga, Sumur Bandung, Bandung');
      expect(listing.formattedPrice, 'Rp 15.000');
      expect(listing.estimatedPricePerKg, 3000.0);
      expect(listing.formattedEstimatedPricePerKg, 'Rp 3.000 / kg');
    });

    test('MaterialListing handles free listings and zero weight safely', () {
      final freeListing = MaterialListing(
        id: 11,
        name: 'Donasi PET',
        category: 'PET',
        weightKg: 4.0,
        condition: 'clean',
        price: 0,
        isFree: true,
        generalLocation: 'Bandung',
        description: '',
        createdAt: DateTime(2026, 11, 21),
      );
      expect(freeListing.estimatedPricePerKg, isNull);
      expect(freeListing.formattedEstimatedPricePerKg, isNull);

      final zeroWeight = MaterialListing(
        id: 12,
        name: 'Zero Weight Guard',
        category: 'PP',
        weightKg: 0.0,
        condition: 'clean',
        price: 10000,
        isFree: false,
        generalLocation: 'Bandung',
        description: '',
        createdAt: DateTime(2026, 11, 21),
      );
      expect(zeroWeight.estimatedPricePerKg, isNull);
      expect(zeroWeight.formattedEstimatedPricePerKg, isNull);
    });
  });

  group('Stage 1.1 — WhatsApp Contact Privacy (Model & EditProfileScreen)', () {
    test('1 & 2. UserProfile parses whatsapp_public and defaults missing/null to false', () {
      final missing = UserProfile.fromJson({
        'id': 1,
        'name': 'User Lama',
        'email': 'lama@plasvora.test',
      });
      expect(missing.whatsappPublic, isFalse);

      final explicitNull = UserProfile.fromJson({
        'id': 2,
        'name': 'User Null',
        'email': 'null@plasvora.test',
        'whatsapp_public': null,
      });
      expect(explicitNull.whatsappPublic, isFalse);

      final enabled = UserProfile.fromJson({
        'id': 3,
        'name': 'User Publik',
        'email': 'publik@plasvora.test',
        'phone': '6281234567890',
        'whatsapp_public': true,
      });
      expect(enabled.whatsappPublic, isTrue);

      final disabled = UserProfile.fromJson({
        'id': 4,
        'name': 'User Privat',
        'email': 'privat@plasvora.test',
        'phone': '6281234567890',
        'whatsapp_public': false,
      });
      expect(disabled.whatsappPublic, isFalse);
    });

    Future<void> openEditProfileScreen(
      WidgetTester tester,
      AuthViewModel authViewModel,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: EditProfileScreen(authViewModel: authViewModel),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Edit Profil'), findsOneWidget);
    }

    testWidgets('3. Profile switch displays the server state accurately', (tester) async {
      final fakeRepo = _Stage11FakeAuthRepository(
        currentUser: UserProfile(
          id: 10,
          name: 'Penjual Aktif',
          email: 'aktif@plasvora.test',
          phone: '6281234567890',
          whatsappPublic: true,
        ),
      );
      final authVm = AuthViewModel(authRepository: fakeRepo);
      await authVm.checkAuthSession();

      await openEditProfileScreen(tester, authVm);

      expect(
        find.text('Tampilkan nomor WhatsApp saya pada detail material'),
        findsOneWidget,
      );
      final switchTile = tester.widget<SwitchListTile>(
        find.byType(SwitchListTile),
      );
      expect(switchTile.value, isTrue);
    });

    testWidgets('4. Missing phone prevents enabling WhatsApp visibility', (tester) async {
      final fakeRepo = _Stage11FakeAuthRepository(
        currentUser: UserProfile(
          id: 11,
          name: 'User Tanpa HP',
          email: 'nohp@plasvora.test',
          phone: null,
          whatsappPublic: false,
        ),
      );
      final authVm = AuthViewModel(authRepository: fakeRepo);
      await authVm.checkAuthSession();

      await openEditProfileScreen(tester, authVm);

      final switchTile = tester.widget<SwitchListTile>(
        find.byType(SwitchListTile),
      );
      expect(switchTile.value, isFalse);
      expect(switchTile.onChanged, isNull);
      expect(
        find.text(
          'Simpan nomor telepon yang valid terlebih dahulu untuk mengaktifkan visibilitas WhatsApp.',
        ),
        findsOneWidget,
      );
      expect(fakeRepo.updateCallCount, 0);
    });

    testWidgets('5. Save failure restores previous switch value and shows error', (tester) async {
      final fakeRepo = _Stage11FakeAuthRepository(
        currentUser: UserProfile(
          id: 12,
          name: 'User Error',
          email: 'err@plasvora.test',
          phone: '6281234567890',
          whatsappPublic: false,
        ),
      )..shouldFailUpdate = true;

      final authVm = AuthViewModel(authRepository: fakeRepo);
      await authVm.checkAuthSession();

      await openEditProfileScreen(tester, authVm);

      await tester.ensureVisible(find.byType(SwitchListTile));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(SwitchListTile));
      await tester.pumpAndSettle();

      final switchTileAfterFail = tester.widget<SwitchListTile>(
        find.byType(SwitchListTile),
      );
      expect(switchTileAfterFail.value, isFalse);
      expect(find.text('Gagal menyimpan pengaturan privasi.'), findsOneWidget);
      expect(fakeRepo.updateCallCount, 1);
    });
  });
}
