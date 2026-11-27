import 'package:flutter/foundation.dart';
import '../models/matching_result.dart';
import '../repositories/transaction_repository.dart';

class MatchingViewModel extends ChangeNotifier {
  final TransactionRepository transactionRepository;

  MatchingViewModel({required this.transactionRepository});

  MaterialRequestMatchingResponse? _requestMatchingResponse;
  MaterialRequestMatchingResponse? get requestMatchingResponse =>
      _requestMatchingResponse;

  MaterialListingMatchingResponse? _listingMatchingResponse;
  MaterialListingMatchingResponse? get listingMatchingResponse =>
      _listingMatchingResponse;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  int _sessionVersion = 0;
  bool _disposed = false;

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  void _safeNotifyListeners() {
    if (!_disposed) {
      notifyListeners();
    }
  }

  Future<void> findMatchesForRequest(int requestId) async {
    final version = _sessionVersion;
    _isLoading = true;
    _errorMessage = null;
    _requestMatchingResponse = null;
    _safeNotifyListeners();

    try {
      final response =
          await transactionRepository.getMatchesForRequest(requestId);
      if (version != _sessionVersion || _disposed) return;
      _requestMatchingResponse = response;
    } catch (e) {
      if (version != _sessionVersion || _disposed) return;
      _errorMessage = e.toString().replaceFirst('ApiException: ', '');
      _requestMatchingResponse = null;
    } finally {
      if (version == _sessionVersion && !_disposed) {
        _isLoading = false;
        _safeNotifyListeners();
      }
    }
  }

  Future<void> findMatchesForListing(int listingId) async {
    final version = _sessionVersion;
    _isLoading = true;
    _errorMessage = null;
    _listingMatchingResponse = null;
    _safeNotifyListeners();

    try {
      final response =
          await transactionRepository.getMatchesForListing(listingId);
      if (version != _sessionVersion || _disposed) return;
      _listingMatchingResponse = response;
    } catch (e) {
      if (version != _sessionVersion || _disposed) return;
      _errorMessage = e.toString().replaceFirst('ApiException: ', '');
      _listingMatchingResponse = null;
    } finally {
      if (version == _sessionVersion && !_disposed) {
        _isLoading = false;
        _safeNotifyListeners();
      }
    }
  }

  void clear() {
    _sessionVersion++;
    final hadState =
        _requestMatchingResponse != null ||
        _listingMatchingResponse != null ||
        _errorMessage != null ||
        _isLoading;

    _requestMatchingResponse = null;
    _listingMatchingResponse = null;
    _errorMessage = null;
    _isLoading = false;

    if (hadState) {
      _safeNotifyListeners();
    }
  }

  void clearUserData() => clear();
}

