import 'dart:async';
import 'package:flutter/foundation.dart';
import '../core/network/api_client.dart';
import '../models/user_profile.dart';
import '../repositories/auth_repository.dart';

enum AuthState { initial, loading, authenticated, unauthenticated, error, connectionError }

class AuthViewModel extends ChangeNotifier {
  final AuthRepository authRepository;

  AuthState _state = AuthState.initial;
  AuthState get state => _state;

  UserProfile? _currentUser;
  UserProfile? get currentUser => _currentUser;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  bool get isAuthenticated => _state == AuthState.authenticated;
  bool get isLoading => _state == AuthState.loading;
  bool get hasConnectionError => _state == AuthState.connectionError;

  bool _isRestoring = false;
  Future<void>? _activeRestoreFuture;

  AuthViewModel({required this.authRepository}) {
    checkAuthSession();
  }

  /// Memulihkan dan memvalidasi sesi autentikasi dengan proteksi race condition.
  /// Menjamin restore session hanya berjalan sekali secara simultan.
  Future<void> checkAuthSession() async {
    if (_isRestoring && _activeRestoreFuture != null) {
      return _activeRestoreFuture;
    }

    _isRestoring = true;
    _state = AuthState.loading;
    _errorMessage = null;
    notifyListeners();

    final completer = Completer<void>();
    _activeRestoreFuture = completer.future;

    try {
      final user = await authRepository.getCurrentUser();
      if (user != null) {
        _currentUser = user;
        _state = AuthState.authenticated;
      } else {
        _currentUser = null;
        _state = AuthState.unauthenticated;
      }
    } on ApiException catch (e) {
      if (e.statusCode == 401) {
        // HTTP 401 Unauthorized: Sesi tidak sah / token dicabut
        _currentUser = null;
        _state = AuthState.unauthenticated;
      } else if (e.statusCode == 403) {
        // HTTP 403 Forbidden: Hak akses ditolak, tetapi token TETAP DIPERTAHANKAN
        // Jangan logout otomatis.
        _errorMessage = e.message.isNotEmpty
            ? e.message
            : 'Akses ke akun Anda dibatasi oleh server (403 Forbidden).';
        _state = AuthState.error;
      } else {
        // HTTP 500, 503, dll: Error server, token tetap aman
        _errorMessage = e.message;
        _state = AuthState.connectionError;
      }
    } catch (e) {
      // Socket exception, network timeout: token tetap aman
      _errorMessage = e.toString().replaceFirst('ApiException: ', '');
      _state = AuthState.connectionError;
    } finally {
      _isRestoring = false;
      _activeRestoreFuture = null;
      completer.complete();
      notifyListeners();
    }
  }

  Future<void> retryCheckAuthSession() => checkAuthSession();

  Future<bool> login(String email, String password) async {
    _state = AuthState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final user = await authRepository.login(email: email, password: password);
      _currentUser = user;
      _state = AuthState.authenticated;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('ApiException: ', '');
      _state = AuthState.error;
      notifyListeners();
      return false;
    }
  }

  Future<bool> register({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
  }) async {
    _state = AuthState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final user = await authRepository.register(
        name: name,
        email: email,
        password: password,
        passwordConfirmation: passwordConfirmation,
      );
      _currentUser = user;
      _state = AuthState.authenticated;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('ApiException: ', '');
      _state = AuthState.error;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    _state = AuthState.loading;
    notifyListeners();

    try {
      await authRepository.logout();
    } finally {
      _currentUser = null;
      _state = AuthState.unauthenticated;
      notifyListeners();
    }
  }
}

