import 'package:flutter/foundation.dart';

import '../core/network/api_client.dart';
import '../models/order_item.dart';
import '../repositories/order_repository.dart';

class OrderViewModel extends ChangeNotifier {
  final OrderRepository orderRepository;

  OrderViewModel({required this.orderRepository});

  // Buyer list state
  List<OrderItem> _buyerOrders = [];
  List<OrderItem> get buyerOrders => List.unmodifiable(_buyerOrders);
  int _buyerPage = 1;
  bool _buyerHasMore = false;
  bool get buyerHasMore => _buyerHasMore;
  String? _buyerStatusFilter;
  String? get buyerStatusFilter => _buyerStatusFilter;
  bool _isLoadingBuyerList = false;
  bool get isLoadingBuyerList => _isLoadingBuyerList;
  String? _buyerListError;
  String? get buyerListError => _buyerListError;

  // Seller list state
  List<OrderItem> _sellerOrders = [];
  List<OrderItem> get sellerOrders => List.unmodifiable(_sellerOrders);
  int _sellerPage = 1;
  bool _sellerHasMore = false;
  bool get sellerHasMore => _sellerHasMore;
  String? _sellerStatusFilter;
  String? get sellerStatusFilter => _sellerStatusFilter;
  bool _isLoadingSellerList = false;
  bool get isLoadingSellerList => _isLoadingSellerList;
  String? _sellerListError;
  String? get sellerListError => _sellerListError;

  // Detail state
  int? _selectedOrderId;
  int? get selectedOrderId => _selectedOrderId;
  OrderItem? _currentOrder;
  OrderItem? get currentOrder => _currentOrder;
  bool _isLoadingDetail = false;
  bool get isLoadingDetail => _isLoadingDetail;
  String? _detailError;
  String? get detailError => _detailError;

  // Operation-specific loading states (tidak saling memblokir UI unrelated)
  bool _isCreatingOrder = false;
  bool get isCreatingOrder => _isCreatingOrder;

  bool _isCancellingOrder = false;
  bool get isCancellingOrder => _isCancellingOrder;

  bool _isRefreshingPayment = false;
  bool get isRefreshingPayment => _isRefreshingPayment;

  bool _isRetryingPayment = false;
  bool get isRetryingPayment => _isRetryingPayment;

  bool _isSubmittingShipment = false;
  bool get isSubmittingShipment => _isSubmittingShipment;

  bool _isConfirmingDelivery = false;
  bool get isConfirmingDelivery => _isConfirmingDelivery;

  // Pending payment navigation tracking untuk sinkronisasi saat app resume
  int? _pendingPaymentOrderId;
  int? get pendingPaymentOrderId => _pendingPaymentOrderId;

  // Reconciliation recovery info dari kegagalan Snap timeout (504)
  int? _reconciliationOrderId;
  int? get reconciliationOrderId => _reconciliationOrderId;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  Map<String, String> _fieldErrors = const {};
  Map<String, String> get fieldErrors => Map.unmodifiable(_fieldErrors);

  /// Versi generasi sesi: dinaikkan pada clearUserData() sehingga respons async
  /// akun lama yang selesai setelah logout tidak pernah bisa menimpa state akun baru.
  int _sessionVersion = 0;

  void markPendingPaymentReturn(int orderId) {
    _pendingPaymentOrderId = orderId;
    notifyListeners();
  }

  void clearPendingPaymentReturn() {
    if (_pendingPaymentOrderId == null) return;
    _pendingPaymentOrderId = null;
    notifyListeners();
  }

  void setCurrentOrderPreview(OrderItem order, {bool notify = true}) {
    _selectedOrderId = order.id;
    _currentOrder = order;
    _detailError = null;
    if (notify) {
      notifyListeners();
    }
  }

  void clearErrors() {
    if (_errorMessage == null &&
        _fieldErrors.isEmpty &&
        _reconciliationOrderId == null) {
      return;
    }
    _errorMessage = null;
    _fieldErrors = const {};
    _reconciliationOrderId = null;
    notifyListeners();
  }

  /// Membersihkan seluruh cache transaksi pengguna saat logout atau sesi 401 dicabut.
  void clearUserData() {
    _sessionVersion++;
    final hadState =
        _buyerOrders.isNotEmpty ||
        _sellerOrders.isNotEmpty ||
        _currentOrder != null ||
        _selectedOrderId != null ||
        _pendingPaymentOrderId != null ||
        _reconciliationOrderId != null ||
        _buyerStatusFilter != null ||
        _sellerStatusFilter != null ||
        _isLoadingBuyerList ||
        _isLoadingSellerList ||
        _isLoadingDetail ||
        _isCreatingOrder ||
        _isCancellingOrder ||
        _isRefreshingPayment ||
        _isRetryingPayment ||
        _isSubmittingShipment ||
        _isConfirmingDelivery ||
        _errorMessage != null ||
        _buyerListError != null ||
        _sellerListError != null ||
        _detailError != null ||
        _fieldErrors.isNotEmpty;

    _buyerOrders = [];
    _buyerPage = 1;
    _buyerHasMore = false;
    _buyerStatusFilter = null;
    _isLoadingBuyerList = false;
    _buyerListError = null;

    _sellerOrders = [];
    _sellerPage = 1;
    _sellerHasMore = false;
    _sellerStatusFilter = null;
    _isLoadingSellerList = false;
    _sellerListError = null;

    _selectedOrderId = null;
    _currentOrder = null;
    _isLoadingDetail = false;
    _detailError = null;

    _isCreatingOrder = false;
    _isCancellingOrder = false;
    _isRefreshingPayment = false;
    _isRetryingPayment = false;
    _isSubmittingShipment = false;
    _isConfirmingDelivery = false;

    _pendingPaymentOrderId = null;
    _reconciliationOrderId = null;
    _errorMessage = null;
    _fieldErrors = const {};

    if (hadState) {
      notifyListeners();
    }
  }

  Future<void> loadBuyerOrders({
    String? status,
    bool loadMore = false,
  }) async {
    if (_isLoadingBuyerList) return;
    if (loadMore && !_buyerHasMore) return;

    final version = _sessionVersion;
    final nextPage = loadMore ? _buyerPage + 1 : 1;
    if (!loadMore) {
      _buyerStatusFilter = status;
    }
    _isLoadingBuyerList = true;
    _buyerListError = null;
    notifyListeners();

    try {
      final result = await orderRepository.getOrders(
        role: 'buyer',
        status: _buyerStatusFilter,
        page: nextPage,
      );
      if (version != _sessionVersion) return;

      _buyerOrders = loadMore
          ? _mergeUniqueOrders(_buyerOrders, result.items)
          : result.items;
      _buyerPage = result.currentPage;
      _buyerHasMore = result.hasMore;
    } catch (e) {
      if (version != _sessionVersion) return;
      _buyerListError = _extractErrorMessage(
        e,
        fallback: 'Gagal memuat daftar pembelian Anda.',
      );
    } finally {
      if (version == _sessionVersion) {
        _isLoadingBuyerList = false;
        notifyListeners();
      }
    }
  }

  Future<void> loadSellerOrders({
    String? status,
    bool loadMore = false,
  }) async {
    if (_isLoadingSellerList) return;
    if (loadMore && !_sellerHasMore) return;

    final version = _sessionVersion;
    final nextPage = loadMore ? _sellerPage + 1 : 1;
    if (!loadMore) {
      _sellerStatusFilter = status;
    }
    _isLoadingSellerList = true;
    _sellerListError = null;
    notifyListeners();

    try {
      final result = await orderRepository.getOrders(
        role: 'seller',
        status: _sellerStatusFilter,
        page: nextPage,
      );
      if (version != _sessionVersion) return;

      _sellerOrders = loadMore
          ? _mergeUniqueOrders(_sellerOrders, result.items)
          : result.items;
      _sellerPage = result.currentPage;
      _sellerHasMore = result.hasMore;
    } catch (e) {
      if (version != _sessionVersion) return;
      _sellerListError = _extractErrorMessage(
        e,
        fallback: 'Gagal memuat daftar pesanan masuk.',
      );
    } finally {
      if (version == _sessionVersion) {
        _isLoadingSellerList = false;
        notifyListeners();
      }
    }
  }

  Future<OrderItem?> loadOrderDetail(int orderId) async {
    if (_isLoadingDetail && _selectedOrderId == orderId) {
      return _currentOrder;
    }

    final version = _sessionVersion;
    _selectedOrderId = orderId;
    _isLoadingDetail = true;
    _detailError = null;
    notifyListeners();

    try {
      final order = await orderRepository.getOrderDetail(orderId);
      if (version != _sessionVersion) return null;

      _syncOrderAcrossState(order);
      return order;
    } catch (e) {
      if (version != _sessionVersion) return null;
      _detailError = _extractErrorMessage(
        e,
        fallback: 'Gagal memuat detail pesanan.',
      );
      return null;
    } finally {
      if (version == _sessionVersion) {
        _isLoadingDetail = false;
        notifyListeners();
      }
    }
  }

  Future<OrderItem?> createOrder({
    required int listingId,
    required int addressId,
    required String courierCode,
    required String courierService,
    String? buyerNote,
    required String idempotencyKey,
  }) async {
    if (_isCreatingOrder) return null;

    final version = _sessionVersion;
    _isCreatingOrder = true;
    _errorMessage = null;
    _fieldErrors = const {};
    _reconciliationOrderId = null;
    notifyListeners();

    try {
      final created = await orderRepository.createOrder(
        listingId: listingId,
        addressId: addressId,
        courierCode: courierCode,
        courierService: courierService,
        buyerNote: buyerNote,
        idempotencyKey: idempotencyKey,
      );
      if (version != _sessionVersion) return null;

      _syncOrderAcrossState(created, prependBuyer: true);
      return created;
    } catch (e) {
      if (version != _sessionVersion) return null;
      _fieldErrors = _extractFieldErrors(e);
      _errorMessage = _extractErrorMessage(
        e,
        fallback: 'Gagal membuat pesanan. Silakan coba lagi.',
      );

      // Tangkap order_id jika backend mengembalikan reconciliation_required (mis. Snap timeout 504)
      if (e is ApiException && e.data != null) {
        final rawOrderId = e.data!['order_id'];
        if (rawOrderId is int) {
          _reconciliationOrderId = rawOrderId;
        } else if (rawOrderId is String) {
          _reconciliationOrderId = int.tryParse(rawOrderId);
        }
      }
      return null;
    } finally {
      if (version == _sessionVersion) {
        _isCreatingOrder = false;
        notifyListeners();
      }
    }
  }

  Future<OrderItem?> cancelOrder(int orderId, {String? reason}) async {
    if (_isCancellingOrder) return null;

    final version = _sessionVersion;
    _isCancellingOrder = true;
    _errorMessage = null;
    _fieldErrors = const {};
    notifyListeners();

    try {
      final updated = await orderRepository.cancelOrder(orderId, reason: reason);
      if (version != _sessionVersion) return null;

      _syncOrderAcrossState(updated);
      if (_pendingPaymentOrderId == orderId) {
        _pendingPaymentOrderId = null;
      }
      return updated;
    } catch (e) {
      if (version != _sessionVersion) return null;
      _syncOrderFromConflictError(e);
      _fieldErrors = _extractFieldErrors(e);
      _errorMessage = _extractErrorMessage(
        e,
        fallback: 'Gagal membatalkan pesanan.',
      );
      return null;
    } finally {
      if (version == _sessionVersion) {
        _isCancellingOrder = false;
        notifyListeners();
      }
    }
  }

  Future<OrderItem?> retryPayment(int orderId) async {
    if (_isRetryingPayment) return null;

    final version = _sessionVersion;
    _isRetryingPayment = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final updated = await orderRepository.retryPayment(orderId);
      if (version != _sessionVersion) return null;

      _syncOrderAcrossState(updated);
      return updated;
    } catch (e) {
      if (version != _sessionVersion) return null;
      _syncOrderFromConflictError(e);
      _errorMessage = _extractErrorMessage(
        e,
        fallback: 'Gagal menyiapkan ulang sesi pembayaran.',
      );
      return null;
    } finally {
      if (version == _sessionVersion) {
        _isRetryingPayment = false;
        notifyListeners();
      }
    }
  }

  Future<OrderRefreshResult?> refreshPaymentStatus(int orderId) async {
    if (_isRefreshingPayment) return null;

    final version = _sessionVersion;
    _isRefreshingPayment = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await orderRepository.refreshPaymentStatus(orderId);
      if (version != _sessionVersion) return null;

      _syncOrderAcrossState(result.order);
      if (_pendingPaymentOrderId == orderId && !result.order.isPendingPayment) {
        _pendingPaymentOrderId = null;
      }
      return result;
    } catch (e) {
      if (version != _sessionVersion) return null;
      _errorMessage = _extractErrorMessage(
        e,
        fallback: 'Gagal memeriksa status pembayaran dari server.',
      );
      return null;
    } finally {
      if (version == _sessionVersion) {
        _isRefreshingPayment = false;
        notifyListeners();
      }
    }
  }

  Future<OrderItem?> shipOrder({
    required int orderId,
    required String trackingNumber,
    String? shipmentNotes,
  }) async {
    if (_isSubmittingShipment) return null;

    final version = _sessionVersion;
    _isSubmittingShipment = true;
    _errorMessage = null;
    _fieldErrors = const {};
    notifyListeners();

    try {
      final updated = await orderRepository.shipOrder(
        orderId: orderId,
        trackingNumber: trackingNumber,
        shipmentNotes: shipmentNotes,
      );
      if (version != _sessionVersion) return null;

      _syncOrderAcrossState(updated);
      return updated;
    } catch (e) {
      if (version != _sessionVersion) return null;
      _fieldErrors = _extractFieldErrors(e);
      _errorMessage = _extractErrorMessage(
        e,
        fallback: 'Gagal menyimpan nomor resi pengiriman.',
      );
      return null;
    } finally {
      if (version == _sessionVersion) {
        _isSubmittingShipment = false;
        notifyListeners();
      }
    }
  }

  Future<OrderItem?> confirmDelivery(int orderId) async {
    if (_isConfirmingDelivery) return null;

    final version = _sessionVersion;
    _isConfirmingDelivery = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final updated = await orderRepository.confirmDelivery(orderId);
      if (version != _sessionVersion) return null;

      _syncOrderAcrossState(updated);
      return updated;
    } catch (e) {
      if (version != _sessionVersion) return null;
      _errorMessage = _extractErrorMessage(
        e,
        fallback: 'Gagal mengonfirmasi penerimaan pesanan.',
      );
      return null;
    } finally {
      if (version == _sessionVersion) {
        _isConfirmingDelivery = false;
        notifyListeners();
      }
    }
  }

  void _syncOrderAcrossState(OrderItem order, {bool prependBuyer = false}) {
    _selectedOrderId = order.id;
    _currentOrder = order;

    final buyerIdx = _buyerOrders.indexWhere((o) => o.id == order.id);
    if (buyerIdx != -1) {
      final updatedList = List<OrderItem>.from(_buyerOrders);
      updatedList[buyerIdx] = order;
      _buyerOrders = updatedList;
    } else if (prependBuyer) {
      _buyerOrders = [order, ..._buyerOrders];
    }

    final sellerIdx = _sellerOrders.indexWhere((o) => o.id == order.id);
    if (sellerIdx != -1) {
      final updatedList = List<OrderItem>.from(_sellerOrders);
      updatedList[sellerIdx] = order;
      _sellerOrders = updatedList;
    }
  }

  void _syncOrderFromConflictError(Object error) {
    if (error is ApiException && error.data != null) {
      final rawOrder = error.data!['order'];
      if (rawOrder is Map<String, dynamic>) {
        try {
          _syncOrderAcrossState(OrderItem.fromJson(rawOrder));
        } catch (_) {}
      }
    }
  }

  List<OrderItem> _mergeUniqueOrders(
    List<OrderItem> existing,
    List<OrderItem> incoming,
  ) {
    final map = <int, OrderItem>{for (final item in existing) item.id: item};
    for (final item in incoming) {
      map[item.id] = item;
    }
    return map.values.toList();
  }

  Map<String, String> _extractFieldErrors(Object error) {
    if (error is ApiException && error.errors != null) {
      final mapped = <String, String>{};
      error.errors!.forEach((key, value) {
        if (value is List && value.isNotEmpty) {
          final first = value.first?.toString().trim() ?? '';
          if (first.isNotEmpty) mapped[key] = first;
        } else if (value != null) {
          final text = value.toString().trim();
          if (text.isNotEmpty) mapped[key] = text;
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
