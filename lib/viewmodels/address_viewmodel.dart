import 'package:flutter/foundation.dart';

import '../core/network/api_client.dart';
import '../models/user_address.dart';
import '../repositories/address_repository.dart';

class AddressViewModel extends ChangeNotifier {
  final AddressRepository addressRepository;

  AddressViewModel({required this.addressRepository});

  List<UserAddress> _addresses = [];
  List<UserAddress> get addresses => List.unmodifiable(_addresses);

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isSaving = false;
  bool get isSaving => _isSaving;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  Map<String, String> _fieldErrors = const {};
  Map<String, String> get fieldErrors => Map.unmodifiable(_fieldErrors);

  int? _selectedAddressId;
  int _stateVersion = 0;

  /// Alamat utama otoritatif dari respons backend.
  UserAddress? get defaultAddress {
    for (final address in _addresses) {
      if (address.isDefault) return address;
    }
    return null;
  }

  /// Alamat yang dipilih untuk estimasi ongkir (fallback ke default address lalu alamat pertama).
  UserAddress? get selectedAddress {
    if (_selectedAddressId != null) {
      for (final address in _addresses) {
        if (address.id == _selectedAddressId) return address;
      }
    }
    return defaultAddress ?? (_addresses.isNotEmpty ? _addresses.first : null);
  }

  void selectAddress(int? addressId) {
    if (_selectedAddressId == addressId) return;
    _selectedAddressId = addressId;
    notifyListeners();
  }

  void clearError() {
    if (_errorMessage == null && _fieldErrors.isEmpty) return;
    _errorMessage = null;
    _fieldErrors = const {};
    notifyListeners();
  }

  /// Membersihkan seluruh data alamat pengguna yang tersimpan di memori saat logout
  /// atau pergantian sesi. Menaikkan [_stateVersion] agar respons async akun lama
  /// tidak dapat memulihkan data setelah sesi dibersihkan.
  void clearUserData() {
    _stateVersion++;
    final hadUserState =
        _addresses.isNotEmpty ||
        _selectedAddressId != null ||
        _isLoading ||
        _isSaving ||
        _errorMessage != null ||
        _fieldErrors.isNotEmpty;
    _addresses = [];
    _selectedAddressId = null;
    _isLoading = false;
    _isSaving = false;
    _errorMessage = null;
    _fieldErrors = const {};
    if (hadUserState) {
      notifyListeners();
    }
  }

  Future<void> loadAddresses() async {
    if (_isLoading) return;

    final requestVersion = ++_stateVersion;
    _isLoading = true;
    _errorMessage = null;
    _fieldErrors = const {};
    notifyListeners();

    try {
      final fetched = await addressRepository.getAddresses();
      // Abaikan hasil load usang jika ada mutasi lebih baru atau clearUserData
      if (requestVersion == _stateVersion) {
        _addresses = fetched;
        _syncSelectedAddress();
      }
    } catch (e) {
      if (requestVersion == _stateVersion) {
        _errorMessage = _extractErrorMessage(
          e,
          fallback: 'Gagal memuat daftar alamat pengiriman.',
        );
      }
    } finally {
      if (requestVersion == _stateVersion) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  Future<UserAddress?> createAddress({
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
    if (_isSaving) return null;

    _isSaving = true;
    _errorMessage = null;
    _fieldErrors = const {};
    notifyListeners();

    UserAddress created;
    try {
      created = await addressRepository.createAddress(
        label: label,
        recipientName: recipientName,
        recipientPhone: recipientPhone,
        destinationId: destinationId,
        destinationLabel: destinationLabel,
        addressDetail: addressDetail,
        postalCode: postalCode,
        deliveryNote: deliveryNote,
        isDefault: isDefault,
      );
    } catch (e) {
      _fieldErrors = _extractFieldErrors(e);
      _errorMessage = _extractErrorMessage(
        e,
        fallback: 'Gagal menambahkan alamat pengiriman.',
      );
      _isSaving = false;
      notifyListeners();
      return null;
    }

    // Mutasi berhasil di backend; refresh daftar dipisahkan agar kegagalan refresh tidak melaporkan mutasi gagal
    final mutationVersion = ++_stateVersion;
    _selectedAddressId = created.id;
    try {
      final refreshed = await addressRepository.getAddresses();
      if (mutationVersion == _stateVersion) {
        _addresses = refreshed;
        _syncSelectedAddress();
      }
    } catch (_) {
      if (mutationVersion == _stateVersion) {
        final updatedList = List<UserAddress>.from(_addresses);
        if (created.isDefault) {
          for (var i = 0; i < updatedList.length; i++) {
            updatedList[i] = updatedList[i].copyWith(isDefault: false);
          }
        }
        updatedList.removeWhere((a) => a.id == created.id);
        updatedList.insert(0, created);
        _addresses = updatedList;
        _syncSelectedAddress();
        _errorMessage =
            'Alamat berhasil disimpan, namun gagal menyegarkan daftar terbaru.';
      }
    } finally {
      if (mutationVersion == _stateVersion) {
        _isSaving = false;
        notifyListeners();
      }
    }

    return created;
  }

  Future<UserAddress?> updateAddress({
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
    if (_isSaving) return null;

    _isSaving = true;
    _errorMessage = null;
    _fieldErrors = const {};
    notifyListeners();

    UserAddress updated;
    try {
      updated = await addressRepository.updateAddress(
        id: id,
        label: label,
        recipientName: recipientName,
        recipientPhone: recipientPhone,
        destinationId: destinationId,
        destinationLabel: destinationLabel,
        addressDetail: addressDetail,
        postalCode: postalCode,
        deliveryNote: deliveryNote,
        isDefault: isDefault,
      );
    } catch (e) {
      _fieldErrors = _extractFieldErrors(e);
      _errorMessage = _extractErrorMessage(
        e,
        fallback: 'Gagal memperbarui alamat pengiriman.',
      );
      _isSaving = false;
      notifyListeners();
      return null;
    }

    // Mutasi berhasil di backend; refresh daftar dipisahkan agar kegagalan refresh tidak melaporkan mutasi gagal
    final mutationVersion = ++_stateVersion;
    try {
      final refreshed = await addressRepository.getAddresses();
      if (mutationVersion == _stateVersion) {
        _addresses = refreshed;
        _syncSelectedAddress();
      }
    } catch (_) {
      if (mutationVersion == _stateVersion) {
        final updatedList = List<UserAddress>.from(_addresses);
        if (updated.isDefault) {
          for (var i = 0; i < updatedList.length; i++) {
            if (updatedList[i].id != updated.id) {
              updatedList[i] = updatedList[i].copyWith(isDefault: false);
            }
          }
        }
        final idx = updatedList.indexWhere((a) => a.id == updated.id);
        if (idx != -1) {
          updatedList[idx] = updated;
        } else {
          updatedList.insert(0, updated);
        }
        _addresses = updatedList;
        _syncSelectedAddress();
        _errorMessage =
            'Alamat berhasil diperbarui, namun gagal menyegarkan daftar terbaru.';
      }
    } finally {
      if (mutationVersion == _stateVersion) {
        _isSaving = false;
        notifyListeners();
      }
    }

    return updated;
  }

  Future<bool> deleteAddress(int id) async {
    if (_isSaving) return false;

    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await addressRepository.deleteAddress(id);
    } catch (e) {
      _errorMessage = _extractErrorMessage(
        e,
        fallback: 'Gagal menghapus alamat pengiriman.',
      );
      _isSaving = false;
      notifyListeners();
      return false;
    }

    // Mutasi hapus berhasil di backend; selalu hapus referensi lokal lalu refresh otoritatif dari backend
    final mutationVersion = ++_stateVersion;
    if (_selectedAddressId == id) {
      _selectedAddressId = null;
    }
    try {
      final refreshed = await addressRepository.getAddresses();
      if (mutationVersion == _stateVersion) {
        _addresses = refreshed;
        _syncSelectedAddress();
      }
    } catch (_) {
      if (mutationVersion == _stateVersion) {
        _addresses = _addresses.where((a) => a.id != id).toList();
        _syncSelectedAddress();
        _errorMessage =
            'Alamat berhasil dihapus, namun gagal menyegarkan daftar terbaru.';
      }
    } finally {
      if (mutationVersion == _stateVersion) {
        _isSaving = false;
        notifyListeners();
      }
    }

    return true;
  }

  void _syncSelectedAddress() {
    if (_selectedAddressId != null &&
        !_addresses.any((a) => a.id == _selectedAddressId)) {
      _selectedAddressId = null;
    }
  }

  Map<String, String> _extractFieldErrors(Object error) {
    if (error is ApiException && error.errors != null) {
      final mapped = <String, String>{};
      error.errors!.forEach((key, value) {
        if (value is List && value.isNotEmpty) {
          final first = value.first?.toString().trim() ?? '';
          if (first.isNotEmpty) {
            mapped[key] = first;
          }
        } else if (value != null) {
          final text = value.toString().trim();
          if (text.isNotEmpty) {
            mapped[key] = text;
          }
        }
      });
      return mapped;
    }
    return const {};
  }

  String _extractErrorMessage(Object error, {required String fallback}) {
    if (error is ApiException) {
      final errors = error.errors;
      if (errors != null) {
        for (final entry in errors.values) {
          if (entry is List && entry.isNotEmpty) {
            return entry.first.toString();
          }
        }
      }
      if (error.message.trim().isNotEmpty) {
        return error.message;
      }
    }
    final text = error.toString().replaceFirst('ApiException: ', '').trim();
    return text.isNotEmpty ? text : fallback;
  }
}
