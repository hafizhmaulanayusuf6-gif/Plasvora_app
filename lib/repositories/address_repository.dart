import '../core/network/api_client.dart';
import '../core/network/api_config.dart';
import '../models/user_address.dart';

abstract class AddressRepository {
  Future<List<UserAddress>> getAddresses();

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
  });

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
  });

  Future<void> deleteAddress(int id);
}

class ApiAddressRepository implements AddressRepository {
  final ApiClient apiClient;

  ApiAddressRepository({required this.apiClient});

  @override
  Future<List<UserAddress>> getAddresses() async {
    final response = await apiClient.get(
      ApiConfig.addresses,
      requiresAuth: true,
    );

    if (response is Map<String, dynamic> && response['data'] is List) {
      return (response['data'] as List)
          .whereType<Map<String, dynamic>>()
          .map(UserAddress.fromJson)
          .toList();
    }

    throw ApiException('Format respons daftar alamat tidak valid.');
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
  }) async {
    final body = <String, dynamic>{
      'recipient_name': recipientName.trim(),
      'recipient_phone': recipientPhone.trim(),
      'destination_id': destinationId,
      'destination_label': destinationLabel.trim(),
      'address_detail': addressDetail.trim(),
    };

    if (label != null && label.trim().isNotEmpty) {
      body['label'] = label.trim();
    }
    if (postalCode != null) {
      final trimmed = postalCode.trim();
      body['postal_code'] = trimmed.isNotEmpty ? trimmed : null;
    }
    if (deliveryNote != null) {
      final trimmed = deliveryNote.trim();
      body['delivery_note'] = trimmed.isNotEmpty ? trimmed : null;
    }
    if (isDefault != null) {
      body['is_default'] = isDefault;
    }

    final response = await apiClient.post(
      ApiConfig.addresses,
      body: body,
      requiresAuth: true,
    );

    if (response is Map<String, dynamic> &&
        response['data'] is Map<String, dynamic>) {
      return UserAddress.fromJson(response['data'] as Map<String, dynamic>);
    }

    throw ApiException('Format respons penambahan alamat tidak valid.');
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
  }) async {
    final body = <String, dynamic>{};

    if (label != null) {
      final trimmed = label.trim();
      body['label'] = trimmed.isNotEmpty ? trimmed : null;
    }
    if (recipientName != null) {
      body['recipient_name'] = recipientName.trim();
    }
    if (recipientPhone != null) {
      body['recipient_phone'] = recipientPhone.trim();
    }
    if (destinationId != null) {
      body['destination_id'] = destinationId;
    }
    if (destinationLabel != null) {
      body['destination_label'] = destinationLabel.trim();
    }
    if (addressDetail != null) {
      body['address_detail'] = addressDetail.trim();
    }
    if (postalCode != null) {
      final trimmed = postalCode.trim();
      body['postal_code'] = trimmed.isNotEmpty ? trimmed : null;
    }
    if (deliveryNote != null) {
      final trimmed = deliveryNote.trim();
      body['delivery_note'] = trimmed.isNotEmpty ? trimmed : null;
    }
    if (isDefault != null) {
      body['is_default'] = isDefault;
    }

    final response = await apiClient.patch(
      ApiConfig.addressDetail(id),
      body: body,
      requiresAuth: true,
    );

    if (response is Map<String, dynamic> &&
        response['data'] is Map<String, dynamic>) {
      return UserAddress.fromJson(response['data'] as Map<String, dynamic>);
    }

    throw ApiException('Format respons pembaruan alamat tidak valid.');
  }

  @override
  Future<void> deleteAddress(int id) async {
    await apiClient.delete(
      ApiConfig.addressDetail(id),
      requiresAuth: true,
    );
  }
}

/// Mock repository deterministik untuk fallback offline / pengujian.
class MockAddressRepository implements AddressRepository {
  final List<UserAddress> _items;
  int _nextId = 100;

  MockAddressRepository({List<UserAddress>? initialItems})
      : _items = List<UserAddress>.from(initialItems ?? const []);

  @override
  Future<List<UserAddress>> getAddresses() async {
    final sorted = List<UserAddress>.from(_items)
      ..sort((a, b) {
        if (a.isDefault != b.isDefault) return a.isDefault ? -1 : 1;
        return b.id.compareTo(a.id);
      });
    return sorted;
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
  }) async {
    final shouldBeDefault = _items.isEmpty || (isDefault ?? false);
    if (shouldBeDefault) {
      for (var i = 0; i < _items.length; i++) {
        _items[i] = _items[i].copyWith(isDefault: false);
      }
    }

    final created = UserAddress(
      id: _nextId++,
      label: (label != null && label.trim().isNotEmpty) ? label.trim() : 'Rumah',
      recipientName: recipientName.trim(),
      recipientPhone: recipientPhone.trim(),
      destinationId: destinationId,
      destinationLabel: destinationLabel.trim(),
      addressDetail: addressDetail.trim(),
      postalCode: postalCode,
      deliveryNote: deliveryNote,
      isDefault: shouldBeDefault,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    _items.insert(0, created);
    return created;
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
  }) async {
    final idx = _items.indexWhere((a) => a.id == id);
    if (idx == -1) {
      throw ApiException('Alamat tidak ditemukan.', statusCode: 404);
    }

    var nextDefault = isDefault ?? _items[idx].isDefault;
    if (isDefault == true) {
      for (var i = 0; i < _items.length; i++) {
        if (i != idx) _items[i] = _items[i].copyWith(isDefault: false);
      }
    } else if (isDefault == false && _items[idx].isDefault) {
      final otherIdx = _items.indexWhere((a) => a.id != id);
      if (otherIdx != -1) {
        _items[otherIdx] = _items[otherIdx].copyWith(isDefault: true);
      } else {
        nextDefault = true;
      }
    }

    final updated = _items[idx].copyWith(
      label: label ?? _items[idx].label,
      recipientName: recipientName ?? _items[idx].recipientName,
      recipientPhone: recipientPhone ?? _items[idx].recipientPhone,
      destinationId: destinationId ?? _items[idx].destinationId,
      destinationLabel: destinationLabel ?? _items[idx].destinationLabel,
      addressDetail: addressDetail ?? _items[idx].addressDetail,
      postalCode: postalCode ?? _items[idx].postalCode,
      deliveryNote: deliveryNote ?? _items[idx].deliveryNote,
      isDefault: nextDefault,
      updatedAt: DateTime.now(),
    );
    _items[idx] = updated;
    return updated;
  }

  @override
  Future<void> deleteAddress(int id) async {
    final idx = _items.indexWhere((a) => a.id == id);
    if (idx == -1) {
      throw ApiException('Alamat tidak ditemukan.', statusCode: 404);
    }
    final wasDefault = _items[idx].isDefault;
    _items.removeAt(idx);
    if (wasDefault && _items.isNotEmpty) {
      _items[0] = _items[0].copyWith(isDefault: true);
    }
  }
}
