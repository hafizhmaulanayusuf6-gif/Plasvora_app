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

  Future<void> findMatchesForRequest(int requestId) async {
    _isLoading = true;
    _errorMessage = null;
    _requestMatchingResponse = null;
    notifyListeners();

    try {
      final response =
          await transactionRepository.getMatchesForRequest(requestId);
      _requestMatchingResponse = response;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('ApiException: ', '');
      _requestMatchingResponse = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> findMatchesForListing(int listingId) async {
    _isLoading = true;
    _errorMessage = null;
    _listingMatchingResponse = null;
    notifyListeners();

    try {
      final response =
          await transactionRepository.getMatchesForListing(listingId);
      _listingMatchingResponse = response;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('ApiException: ', '');
      _listingMatchingResponse = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clear() {
    _requestMatchingResponse = null;
    _listingMatchingResponse = null;
    _errorMessage = null;
    _isLoading = false;
    notifyListeners();
  }
}

