import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:plasvora/core/network/api_client.dart';
import 'package:plasvora/models/shipping_destination.dart';
import 'package:plasvora/models/user_address.dart';
import 'package:plasvora/repositories/address_repository.dart';
import 'package:plasvora/repositories/material_repository.dart';
import 'package:plasvora/repositories/shipping_repository.dart';
import 'package:plasvora/viewmodels/address_viewmodel.dart';
import 'package:plasvora/viewmodels/marketplace_viewmodel.dart';

ApiClient _buildTestApiClient(MockClientHandler handler) {
  final storage = InMemoryAuthTokenStorage();
  storage.saveToken('test-sanctum-token');
  return ApiClient(client: MockClient(handler), tokenStorage: storage);
}

void main() {
  group('Stage 2 Batch 3 — Models', () {
    test('ShippingDestination parses backend DTO accurately', () {
      final dest = ShippingDestination.fromJson({
        'destination_id': 4949,
        'label': 'BRAGA, SUMUR BANDUNG, BANDUNG, JAWA BARAT, 40111',
        'province_name': 'JAWA BARAT',
        'city_name': 'BANDUNG',
        'district_name': 'SUMUR BANDUNG',
        'subdistrict_name': 'BRAGA',
        'postal_code': '40111',
      });

      expect(dest.destinationId, 4949);
      expect(dest.label, 'BRAGA, SUMUR BANDUNG, BANDUNG, JAWA BARAT, 40111');
      expect(dest.provinceName, 'JAWA BARAT');
      expect(dest.cityName, 'BANDUNG');
      expect(dest.districtName, 'SUMUR BANDUNG');
      expect(dest.subdistrictName, 'BRAGA');
      expect(dest.postalCode, '40111');
    });

    test('UserAddress parses snake_case JSON and serializes request without user_id', () {
      final address = UserAddress.fromJson({
        'id': 7,
        'label': 'Gudang',
        'recipient_name': 'Budi Santoso',
        'recipient_phone': '6281234567890',
        'destination_id': 6157,
        'destination_label': 'BABAKANKARET, CIANJUR',
        'address_detail': 'Jl. Raya Cianjur No. 12',
        'postal_code': '43211',
        'delivery_note': '   ',
        'is_default': 1,
        'created_at': '2026-11-22T00:00:00Z',
        'updated_at': '2026-11-22T00:05:00Z',
      });

      expect(address.id, 7);
      expect(address.label, 'Gudang');
      expect(address.recipientName, 'Budi Santoso');
      expect(address.recipientPhone, '6281234567890');
      expect(address.destinationId, 6157);
      expect(address.deliveryNote, isNull);
      expect(address.isDefault, isTrue);

      final payload = address.toRequestJson();
      expect(payload.containsKey('user_id'), isFalse);
      expect(payload.containsKey('id'), isFalse);
      expect(payload['destination_id'], 6157);
      expect(payload['address_detail'], 'Jl. Raya Cianjur No. 12');
    });

    test('ShippingCostOption & ShippingEstimateResult parse costs and nullable ETD safely', () {
      final result = ShippingEstimateResult.fromJson({
        'listing': {
          'id': 15,
          'name': 'Botol PET 2kg',
          'weight_kg': '2.00',
          'weight_grams': 2000,
          'origin_destination_id': 4949,
          'origin_label': 'BRAGA, SUMUR BANDUNG, BANDUNG',
        },
        'destination': {
          'address_id': 7,
          'label': 'Rumah',
          'destination_id': 6157,
          'destination_label': 'BABAKANKARET, CIANJUR',
        },
        'options': [
          {
            'courier_code': 'JNE',
            'courier_name': 'Jalur Nugraha Ekakurir (JNE)',
            'service': 'REG',
            'description': 'Layanan Reguler',
            'cost': 18000,
            'etd': '2-3 day',
          },
          {
            'courier_code': 'jnt',
            'courier_name': 'J&T Express',
            'service': 'EZ',
            'description': 'Reguler',
            'cost': '16000',
            'etd': '-',
          },
          {
            'courier_code': 'jne',
            'courier_name': 'JNE',
            'service': 'JTR',
            'description': '',
            'cost': 45000.0,
            'etd': null,
          },
        ],
      }, message: 'Estimasi ongkos kirim berhasil diambil.');

      expect(result.listing.weightGrams, 2000);
      expect(result.destination.destinationId, 6157);
      expect(result.options.length, 3);
      expect(result.options[0].courierCode, 'jne');
      expect(result.options[0].cost, 18000);
      expect(result.options[0].etd, '2-3 day');
      expect(result.options[1].cost, 16000);
      expect(result.options[1].etd, isNull);
      expect(result.options[2].description, isNull);
      expect(result.options[2].etd, isNull);
    });
  });

  group('Stage 2 Batch 3 — ApiAddressRepository', () {
    test('lists, creates, updates, deletes addresses and propagates ApiException', () async {
      late http.Request lastRequest;

      final client = _buildTestApiClient((request) async {
        lastRequest = request;

        if (request.method == 'GET' && request.url.path.endsWith('/addresses')) {
          return http.Response(
            jsonEncode({
              'success': true,
              'message': 'Daftar alamat berhasil diambil.',
              'data': [
                {
                  'id': 1,
                  'label': 'Rumah',
                  'recipient_name': 'Budi',
                  'recipient_phone': '6281234567890',
                  'destination_id': 6157,
                  'destination_label': 'BABAKANKARET, CIANJUR',
                  'address_detail': 'Jl. Cianjur 1',
                  'postal_code': '43211',
                  'delivery_note': null,
                  'is_default': true,
                },
              ],
            }),
            200,
          );
        }

        if (request.method == 'POST' && request.url.path.endsWith('/addresses')) {
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          expect(body.containsKey('user_id'), isFalse);
          expect(body['recipient_phone'], '081234567890');
          return http.Response(
            jsonEncode({
              'success': true,
              'message': 'Alamat berhasil ditambahkan.',
              'data': {
                'id': 2,
                'label': body['label'] ?? 'Rumah',
                'recipient_name': body['recipient_name'],
                'recipient_phone': '6281234567890',
                'destination_id': body['destination_id'],
                'destination_label': body['destination_label'],
                'address_detail': body['address_detail'],
                'postal_code': body['postal_code'],
                'delivery_note': body['delivery_note'],
                'is_default': true,
              },
            }),
            201,
          );
        }

        if (request.method == 'PATCH' && request.url.path.endsWith('/addresses/2')) {
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          expect(body['label'], 'Kantor');
          return http.Response(
            jsonEncode({
              'success': true,
              'message': 'Alamat berhasil diperbarui.',
              'data': {
                'id': 2,
                'label': 'Kantor',
                'recipient_name': 'Budi',
                'recipient_phone': '6281234567890',
                'destination_id': 6157,
                'destination_label': 'BABAKANKARET, CIANJUR',
                'address_detail': 'Jl. Kantor 2',
                'is_default': true,
              },
            }),
            200,
          );
        }

        if (request.method == 'DELETE' && request.url.path.endsWith('/addresses/2')) {
          return http.Response(
            jsonEncode({'success': true, 'message': 'Alamat berhasil dihapus.', 'data': null}),
            200,
          );
        }

        return http.Response(
          jsonEncode({'success': false, 'message': 'Alamat tidak ditemukan.'}),
          404,
        );
      });

      final repo = ApiAddressRepository(apiClient: client);

      final list = await repo.getAddresses();
      expect(list.length, 1);
      expect(lastRequest.headers['Authorization'], 'Bearer test-sanctum-token');

      final created = await repo.createAddress(
        label: 'Gudang',
        recipientName: 'Budi',
        recipientPhone: '081234567890',
        destinationId: 6157,
        destinationLabel: 'BABAKANKARET, CIANJUR',
        addressDetail: 'Jl. Gudang 1',
      );
      expect(created.id, 2);

      final updated = await repo.updateAddress(id: 2, label: 'Kantor');
      expect(updated.label, 'Kantor');

      await repo.deleteAddress(2);

      await expectLater(
        () => repo.deleteAddress(999),
        throwsA(isA<ApiException>().having((e) => e.statusCode, 'statusCode', 404)),
      );
    });
  });

  group('Stage 2 Batch 3 — ApiShippingRepository', () {
    test('searches destinations and posts strictly {listing_id, address_id} for estimate', () async {
      final client = _buildTestApiClient((request) async {
        if (request.method == 'GET' &&
            request.url.path.endsWith('/shipping/destinations')) {
          expect(request.url.queryParameters['search'], 'braga');
          expect(request.url.queryParameters['limit'], '5');
          expect(request.url.queryParameters['offset'], '0');
          return http.Response(
            jsonEncode({
              'success': true,
              'message': 'Daftar lokasi pengiriman berhasil diambil.',
              'data': [
                {
                  'destination_id': 4949,
                  'label': 'BRAGA, SUMUR BANDUNG, BANDUNG, JAWA BARAT, 40111',
                  'province_name': 'JAWA BARAT',
                  'city_name': 'BANDUNG',
                  'district_name': 'SUMUR BANDUNG',
                  'subdistrict_name': 'BRAGA',
                  'postal_code': '40111',
                },
              ],
            }),
            200,
          );
        }

        if (request.method == 'POST' &&
            request.url.path.endsWith('/shipping/estimate')) {
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          // Pastikan HANYA listing_id dan address_id yang dikirim dari Flutter
          expect(body.keys.toSet(), {'listing_id', 'address_id'});
          expect(body['listing_id'], 10);
          expect(body['address_id'], 20);

          return http.Response(
            jsonEncode({
              'success': true,
              'message': 'Belum ada layanan pengiriman yang tersedia untuk rute dan berat material ini.',
              'data': {
                'listing': {
                  'id': 10,
                  'name': 'PET 50kg',
                  'weight_kg': 50.0,
                  'weight_grams': 50000,
                  'origin_destination_id': 4949,
                  'origin_label': 'BRAGA, BANDUNG',
                },
                'destination': {
                  'address_id': 20,
                  'label': 'Gudang',
                  'destination_id': 6157,
                  'destination_label': 'BABAKANKARET, CIANJUR',
                },
                'options': [],
              },
            }),
            200,
          );
        }

        return http.Response(
          jsonEncode({'success': false, 'message': 'Timeout upstream.'}),
          504,
        );
      });

      final repo = ApiShippingRepository(apiClient: client);

      final destinations = await repo.searchDestinations(query: 'braga', limit: 5);
      expect(destinations.length, 1);
      expect(destinations.first.destinationId, 4949);

      final emptyEstimate = await repo.estimateShipping(listingId: 10, addressId: 20);
      expect(emptyEstimate.options, isEmpty);
      expect(emptyEstimate.listing.weightGrams, 50000);
    });

    test('propagates ApiException status code on shipping error', () async {
      final client = _buildTestApiClient((_) async {
        return http.Response(
          jsonEncode({
            'success': false,
            'message': 'Penjual belum mengatur lokasi asal pengiriman untuk material ini.',
          }),
          422,
        );
      });

      final repo = ApiShippingRepository(apiClient: client);

      await expectLater(
        () => repo.estimateShipping(listingId: 10, addressId: 20),
        throwsA(isA<ApiException>().having((e) => e.statusCode, 'statusCode', 422)),
      );
    });
  });

  group('Stage 2 Batch 3 — AddressViewModel', () {
    test('loads, creates, updates, deletes, and refreshes authoritative default address', () async {
      final mockRepo = MockAddressRepository();
      final vm = AddressViewModel(addressRepository: mockRepo);

      expect(vm.addresses, isEmpty);
      expect(vm.defaultAddress, isNull);
      expect(vm.isLoading, isFalse);

      await vm.loadAddresses();
      expect(vm.addresses, isEmpty);

      final first = await vm.createAddress(
        label: 'Rumah',
        recipientName: 'Budi',
        recipientPhone: '081234567890',
        destinationId: 6157,
        destinationLabel: 'BABAKANKARET, CIANJUR',
        addressDetail: 'Jl. Pertama No. 1',
      );
      expect(first, isNotNull);
      expect(vm.addresses.length, 1);
      expect(vm.defaultAddress?.id, first!.id);
      expect(vm.selectedAddress?.id, first.id);

      final second = await vm.createAddress(
        label: 'Kantor',
        recipientName: 'Budi',
        recipientPhone: '081234567890',
        destinationId: 4949,
        destinationLabel: 'BRAGA, BANDUNG',
        addressDetail: 'Jl. Kedua No. 2',
        isDefault: true,
      );
      expect(second, isNotNull);
      expect(vm.defaultAddress?.id, second!.id);

      final updated = await vm.updateAddress(id: first.id, isDefault: true);
      expect(updated, isNotNull);
      expect(vm.defaultAddress?.id, first.id);

      final deleted = await vm.deleteAddress(first.id);
      expect(deleted, isTrue);
      expect(vm.addresses.length, 1);
      expect(vm.defaultAddress?.id, second.id);
    });

    test('sets Indonesian errorMessage when repository throws ApiException', () async {
      final failingClient = _buildTestApiClient((_) async {
        return http.Response(
          jsonEncode({
            'success': false,
            'message': 'Validation failed',
            'errors': {
              'recipient_phone': ['Format nomor telepon penerima tidak valid.'],
            },
          }),
          422,
        );
      });

      final vm = AddressViewModel(
        addressRepository: ApiAddressRepository(apiClient: failingClient),
      );

      final result = await vm.createAddress(
        recipientName: 'Budi',
        recipientPhone: '123',
        destinationId: 6157,
        destinationLabel: 'CIANJUR',
        addressDetail: 'Jl. Uji 1',
      );

      expect(result, isNull);
      expect(vm.errorMessage, 'Format nomor telepon penerima tidak valid.');
      expect(vm.isSaving, isFalse);
    });

    test('successful mutation still returns success when post-mutation refresh fails and clears deleted selection', () async {
      var failGetAddresses = false;

      final client = _buildTestApiClient((request) async {
        if (request.method == 'GET' && request.url.path.endsWith('/addresses')) {
          if (failGetAddresses) {
            return http.Response(
              jsonEncode({'success': false, 'message': 'Server sibuk sementara.'}),
              503,
            );
          }
          return http.Response(
            jsonEncode({
              'success': true,
              'data': [
                {
                  'id': 1,
                  'label': 'Rumah',
                  'recipient_name': 'Budi',
                  'recipient_phone': '6281234567890',
                  'destination_id': 6157,
                  'destination_label': 'BABAKANKARET, CIANJUR',
                  'address_detail': 'Jl. Pertama 1',
                  'is_default': true,
                },
              ],
            }),
            200,
          );
        }

        if (request.method == 'POST' && request.url.path.endsWith('/addresses')) {
          return http.Response(
            jsonEncode({
              'success': true,
              'data': {
                'id': 2,
                'label': 'Kantor',
                'recipient_name': 'Budi',
                'recipient_phone': '6281234567890',
                'destination_id': 4949,
                'destination_label': 'BRAGA, BANDUNG',
                'address_detail': 'Jl. Kedua 2',
                'is_default': true,
              },
            }),
            201,
          );
        }

        if (request.method == 'PATCH' && request.url.path.endsWith('/addresses/2')) {
          return http.Response(
            jsonEncode({
              'success': true,
              'data': {
                'id': 2,
                'label': 'Workshop',
                'recipient_name': 'Budi',
                'recipient_phone': '6281234567890',
                'destination_id': 4949,
                'destination_label': 'BRAGA, BANDUNG',
                'address_detail': 'Jl. Kedua 2',
                'is_default': true,
              },
            }),
            200,
          );
        }

        if (request.method == 'DELETE' && request.url.path.endsWith('/addresses/2')) {
          return http.Response(
            jsonEncode({'success': true, 'message': 'Alamat berhasil dihapus.', 'data': null}),
            200,
          );
        }

        return http.Response(jsonEncode({'success': false}), 404);
      });

      final vm = AddressViewModel(
        addressRepository: ApiAddressRepository(apiClient: client),
      );
      await vm.loadAddresses();
      expect(vm.addresses.length, 1);

      // Paksa GET refresh gagal setelah mutasi sukses
      failGetAddresses = true;

      final created = await vm.createAddress(
        label: 'Kantor',
        recipientName: 'Budi',
        recipientPhone: '081234567890',
        destinationId: 4949,
        destinationLabel: 'BRAGA, BANDUNG',
        addressDetail: 'Jl. Kedua 2',
        isDefault: true,
      );
      expect(created, isNotNull);
      expect(created!.id, 2);
      expect(vm.selectedAddress?.id, 2);
      expect(vm.errorMessage, isNotNull);

      final updated = await vm.updateAddress(id: 2, label: 'Workshop');
      expect(updated, isNotNull);
      expect(updated!.label, 'Workshop');

      final deleted = await vm.deleteAddress(2);
      expect(deleted, isTrue);
      expect(vm.addresses.any((a) => a.id == 2), isFalse);
      expect(vm.selectedAddress?.id, isNot(2));
      expect(vm.isSaving, isFalse);
    });
  });

  group('Stage 2 Batch 3 — MaterialRepository & MarketplaceViewModel Origin + Update', () {
    test('createMaterial allows both absent, includes valid pair, and throws ArgumentError on invalid pair before HTTP', () async {
      final capturedBodies = <Map<String, dynamic>>[];

      final client = _buildTestApiClient((request) async {
        if (request.method == 'GET') {
          return http.Response(
            jsonEncode({'success': true, 'data': []}),
            200,
          );
        }

        final body = jsonDecode(request.body) as Map<String, dynamic>;
        capturedBodies.add(body);
        return http.Response(
          jsonEncode({
            'success': true,
            'message': 'Material listing created successfully',
            'data': {
              'id': 50,
              'owner_id': 1,
              'name': body['name'],
              'category': body['category'],
              'weight_kg': body['weight_kg'],
              'condition': body['condition'],
              'price': body['price'],
              'is_free': body['is_free'],
              'general_location': body['general_location'],
              'origin_destination_id': body['origin_destination_id'],
              'origin_label': body['origin_label'],
              'description': body['description'],
              'status': 'available',
              'created_at': '2026-11-22T00:00:00Z',
            },
          }),
          201,
        );
      });

      final repo = ApiMaterialRepository(apiClient: client);
      final vm = MarketplaceViewModel(materialRepository: repo);

      // 1. Keduanya valid -> keduanya dikirim
      final okWithOrigin = await vm.createListing(
        name: 'Lot PET Braga',
        category: 'PET',
        weightKg: 3.5,
        condition: 'clean',
        price: 20000,
        isFree: false,
        generalLocation: 'Bandung',
        description: 'Hasil analisis AI',
        originDestinationId: 4949,
        originLabel: 'BRAGA, SUMUR BANDUNG, BANDUNG',
      );
      expect(okWithOrigin, isTrue);
      expect(capturedBodies.length, 1);
      expect(capturedBodies.last['origin_destination_id'], 4949);
      expect(capturedBodies.last['origin_label'], 'BRAGA, SUMUR BANDUNG, BANDUNG');

      // 2. Keduanya absen -> tetap diizinkan (kompatibilitas pemanggil lama)
      final okLegacy = await vm.createListing(
        name: 'Lot Tanpa Origin',
        category: 'Lainnya',
        weightKg: 2.0,
        condition: 'light',
        price: 0,
        isFree: true,
        generalLocation: 'Bandung',
        description: 'Legacy',
      );
      expect(okLegacy, isTrue);
      expect(capturedBodies.length, 2);
      expect(capturedBodies.last.containsKey('origin_destination_id'), isFalse);
      expect(capturedBodies.last.containsKey('origin_label'), isFalse);
      expect(capturedBodies.last['category'], 'OTHER');
      expect(capturedBodies.last['condition'], 'slightly_dirty');

      // 3. ID tanpa label -> ArgumentError sebelum HTTP dikirim
      await expectLater(
        () => vm.createListing(
          name: 'Half Pair ID',
          category: 'PET',
          weightKg: 1.0,
          condition: 'clean',
          price: 0,
          isFree: true,
          generalLocation: 'Bandung',
          description: '',
          originDestinationId: 4949,
        ),
        throwsArgumentError,
      );

      // 4. Label tanpa ID -> ArgumentError sebelum HTTP dikirim
      await expectLater(
        () => vm.createListing(
          name: 'Half Pair Label',
          category: 'PET',
          weightKg: 1.0,
          condition: 'clean',
          price: 0,
          isFree: true,
          generalLocation: 'Bandung',
          description: '',
          originLabel: 'BRAGA, BANDUNG',
        ),
        throwsArgumentError,
      );

      // 5. ID dengan label whitespace-only -> ArgumentError sebelum HTTP dikirim
      await expectLater(
        () => repo.createMaterial(
          name: 'Whitespace Label',
          category: 'PET',
          weightKg: 1.0,
          condition: 'clean',
          price: 0,
          isFree: true,
          generalLocation: 'Bandung',
          description: '',
          originDestinationId: 4949,
          originLabel: '   ',
        ),
        throwsArgumentError,
      );

      // Pastikan TIDAK ADA request HTTP baru yang terkirim untuk 3 kasus invalid di atas
      expect(capturedBodies.length, 2);
    });

    test('updateMaterial enforces clearOrigin rules, omits untouched origin, and rejects conflicts before HTTP', () async {
      final patchBodies = <Map<String, dynamic>>[];

      final client = _buildTestApiClient((request) async {
        if (request.method == 'GET') {
          return http.Response(jsonEncode({'success': true, 'data': []}), 200);
        }
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        patchBodies.add(body);
        return http.Response(
          jsonEncode({
            'success': true,
            'data': {
              'id': 50,
              'owner_id': 1,
              'name': body['name'] ?? 'Lot PET',
              'category': 'PET',
              'weight_kg': 4.0,
              'condition': 'clean',
              'price': 25000,
              'is_free': false,
              'general_location': 'Bandung',
              'origin_destination_id': body.containsKey('origin_destination_id')
                  ? body['origin_destination_id']
                  : 4949,
              'origin_label': body.containsKey('origin_label')
                  ? body['origin_label']
                  : 'BRAGA, BANDUNG',
              'description': 'Desc',
              'status': 'available',
              'created_at': '2026-11-22T00:00:00Z',
            },
          }),
          200,
        );
      });

      final repo = ApiMaterialRepository(apiClient: client);

      // Omitted origin -> tidak mengirim key origin (mempertahankan nilai lama)
      final preserved = await repo.updateMaterial(id: 50, name: 'Nama Baru');
      expect(preserved.originDestinationId, 4949);
      expect(patchBodies.last.containsKey('origin_destination_id'), isFalse);
      expect(patchBodies.last.containsKey('origin_label'), isFalse);

      // clearOrigin: true -> mengirim keduanya sebagai null bersamaan
      final cleared = await repo.updateMaterial(id: 50, clearOrigin: true);
      expect(cleared.originDestinationId, isNull);
      expect(cleared.originLabel, isNull);
      expect(patchBodies.last.containsKey('origin_destination_id'), isTrue);
      expect(patchBodies.last['origin_destination_id'], isNull);
      expect(patchBodies.last.containsKey('origin_label'), isTrue);
      expect(patchBodies.last['origin_label'], isNull);

      // Konflik clearOrigin: true + origin baru -> ArgumentError sebelum HTTP
      await expectLater(
        () => repo.updateMaterial(
          id: 50,
          clearOrigin: true,
          originDestinationId: 4949,
          originLabel: 'BRAGA, BANDUNG',
        ),
        throwsArgumentError,
      );

      // Half-pair pada update -> ArgumentError sebelum HTTP
      await expectLater(
        () => repo.updateMaterial(
          id: 50,
          originDestinationId: 4949,
        ),
        throwsArgumentError,
      );

      expect(patchBodies.length, 2);
    });

    test('updateListing uses JSON PATCH without image and multipart POST _method=PATCH with image', () async {
      final recordedMutations = <http.BaseRequest>[];
      late Map<String, dynamic> patchBody;

      final mockClient = MockClient.streaming((request, bodyStream) async {
        if (request.method == 'GET') {
          return http.StreamedResponse(
            Stream.value(utf8.encode(jsonEncode({'success': true, 'data': []}))),
            200,
          );
        }

        recordedMutations.add(request);
        final bodyBytes = await bodyStream.toBytes();
        final bodyStr = utf8.decode(bodyBytes, allowMalformed: true);

        if (request.method == 'PATCH') {
          patchBody = jsonDecode(bodyStr) as Map<String, dynamic>;
          return http.StreamedResponse(
            Stream.value(utf8.encode(jsonEncode({
              'success': true,
              'message': 'Material listing updated successfully',
              'data': {
                'id': 50,
                'owner_id': 1,
                'name': 'Lot PET Diperbarui',
                'category': 'PET',
                'weight_kg': 4.0,
                'condition': 'clean',
                'price': 25000,
                'is_free': false,
                'general_location': 'Bandung',
                'origin_destination_id': 4949,
                'origin_label': 'BRAGA, SUMUR BANDUNG, BANDUNG',
                'description': 'Deskripsi baru',
                'status': 'available',
                'created_at': '2026-11-22T00:00:00Z',
              },
            }))),
            200,
          );
        }

        // Multipart replacement image -> POST dengan _method=PATCH
        expect(request.method, 'POST');
        expect(bodyStr, contains('name="_method"'));
        expect(bodyStr, contains('PATCH'));
        expect(bodyStr, contains('name="image"'));

        return http.StreamedResponse(
          Stream.value(utf8.encode(jsonEncode({
            'success': true,
            'message': 'Material listing updated successfully',
            'data': {
              'id': 50,
              'owner_id': 1,
              'name': 'Lot PET Foto Baru',
              'category': 'PET',
              'weight_kg': 4.0,
              'condition': 'clean',
              'price': 25000,
              'is_free': false,
              'general_location': 'Bandung',
              'origin_destination_id': 4949,
              'origin_label': 'BRAGA, SUMUR BANDUNG, BANDUNG',
              'description': 'Deskripsi baru',
              'image_url': 'https://storage.plasvora.test/storage/materials/new.jpg',
              'status': 'available',
              'created_at': '2026-11-22T00:00:00Z',
            },
          }))),
          200,
        );
      });

      final storage = InMemoryAuthTokenStorage();
      await storage.saveToken('test-sanctum-token');
      final apiClient = ApiClient(client: mockClient, tokenStorage: storage);
      final repo = ApiMaterialRepository(apiClient: apiClient);
      final vm = MarketplaceViewModel(materialRepository: repo);

      // 1. Update tanpa gambar -> JSON PATCH
      final updatedNoImg = await vm.updateListing(
        id: 50,
        name: 'Lot PET Diperbarui',
        originDestinationId: 4949,
        originLabel: 'BRAGA, SUMUR BANDUNG, BANDUNG',
      );
      expect(updatedNoImg, isNotNull);
      expect(updatedNoImg!.name, 'Lot PET Diperbarui');
      expect(patchBody['origin_destination_id'], 4949);
      expect(patchBody['origin_label'], 'BRAGA, SUMUR BANDUNG, BANDUNG');

      // 2. Update dengan gambar pengganti -> Multipart POST + _method=PATCH
      final tempFile = File('${Directory.systemTemp.path}/plasvora_stage2_test_img.jpg');
      await tempFile.writeAsBytes([0xFF, 0xD8, 0xFF, 0xE0]);
      try {
        final updatedWithImg = await vm.updateListing(
          id: 50,
          name: 'Lot PET Foto Baru',
          imagePath: tempFile.path,
        );
        expect(updatedWithImg, isNotNull);
        expect(
          updatedWithImg!.imageUrl,
          'https://storage.plasvora.test/storage/materials/new.jpg',
        );
      } finally {
        if (await tempFile.exists()) {
          await tempFile.delete();
        }
      }

      expect(recordedMutations.length, 2);
    });
  });
}
