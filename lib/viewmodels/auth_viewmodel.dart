import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../core/network/api_client.dart';
import '../models/user_profile.dart';
import '../repositories/auth_repository.dart';

enum AuthState { initial, loading, authenticated, unauthenticated, error, connectionError }

class AuthViewModel extends ChangeNotifier {
  final AuthRepository authRepository;
  final VoidCallback? onSessionCleared;

  AuthState _state = AuthState.initial;
  AuthState get state => _state;

  UserProfile? _currentUser;
  UserProfile? get currentUser => _currentUser;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  bool get isAuthenticated => _state == AuthState.authenticated;
  bool get isLoading => _state == AuthState.loading;
  bool get isRestoringSession => _isRestoring;
  bool get hasConnectionError => _state == AuthState.connectionError;

  bool _isUpdatingProfile = false;
  bool get isUpdatingProfile => _isUpdatingProfile;

  bool _isRestoring = false;
  bool _isSubmitting = false;
  bool _isLoggingOut = false;
  bool _disposed = false;
  Future<void>? _activeRestoreFuture;

  AuthViewModel({
    required this.authRepository,
    this.onSessionCleared,
  }) {
    checkAuthSession();
  }

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

  /// Memulihkan dan memvalidasi sesi autentikasi dengan proteksi race condition.
  /// Menjamin restore session hanya berjalan sekali secara simultan.
  Future<void> checkAuthSession() async {
    if (_isRestoring && _activeRestoreFuture != null) {
      return _activeRestoreFuture;
    }

    _isRestoring = true;
    _state = AuthState.loading;
    _errorMessage = null;
    _safeNotifyListeners();

    final completer = Completer<void>();
    _activeRestoreFuture = completer.future;

    try {
      final user = await authRepository.getCurrentUser();
      if (_disposed) return;
      if (user != null) {
        _currentUser = user;
        _state = AuthState.authenticated;
      } else {
        _currentUser = null;
        _state = AuthState.unauthenticated;
        onSessionCleared?.call();
      }
    } on ApiException catch (e) {
      if (_disposed) return;
      if (e.statusCode == 401) {
        // HTTP 401 Unauthorized: Sesi tidak sah / token dicabut
        _currentUser = null;
        _state = AuthState.unauthenticated;
        onSessionCleared?.call();
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
      if (_disposed) return;
      // Socket exception, network timeout: token tetap aman
      _errorMessage = e.toString().replaceFirst('ApiException: ', '');
      _state = AuthState.connectionError;
    } finally {
      _isRestoring = false;
      _activeRestoreFuture = null;
      if (!completer.isCompleted) {
        completer.complete();
      }
      _safeNotifyListeners();
    }
  }

  Future<void> retryCheckAuthSession() => checkAuthSession();

  Future<bool> login(String email, String password) async {
    if (_isSubmitting) return false;

    _isSubmitting = true;
    _state = AuthState.loading;
    _errorMessage = null;
    _safeNotifyListeners();

    try {
      final user = await authRepository.login(email: email, password: password);
      if (_disposed) return false;
      _currentUser = user;
      _state = AuthState.authenticated;
      _safeNotifyListeners();
      return true;
    } on ApiException catch (e) {
      if (_disposed) return false;
      _applyAuthOperationFailure(e);
      return false;
    } catch (e) {
      if (_disposed) return false;
      _errorMessage = _formatUnexpectedAuthError(e);
      _state = AuthState.unauthenticated;
      _safeNotifyListeners();
      return false;
    } finally {
      _isSubmitting = false;
    }
  }

  Future<bool> register({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
    String? phone,
  }) async {
    if (_isSubmitting) return false;

    _isSubmitting = true;
    _state = AuthState.loading;
    _errorMessage = null;
    _safeNotifyListeners();

    try {
      final user = await authRepository.register(
        name: name,
        email: email,
        password: password,
        passwordConfirmation: passwordConfirmation,
        phone: phone,
      );
      if (_disposed) return false;
      _currentUser = user;
      _state = AuthState.authenticated;
      _safeNotifyListeners();
      return true;
    } on ApiException catch (e) {
      if (_disposed) return false;
      _applyAuthOperationFailure(e);
      return false;
    } catch (e) {
      if (_disposed) return false;
      _errorMessage = _formatUnexpectedAuthError(e);
      _state = AuthState.unauthenticated;
      _safeNotifyListeners();
      return false;
    } finally {
      _isSubmitting = false;
    }
  }

  /// Keep AuthState.error strictly for genuine HTTP 403 Forbidden;
  /// credential, validation, server, and network failures stay unauthenticated
  /// so LoginScreen / RegisterScreen remain mounted for retry.
  void _applyAuthOperationFailure(ApiException e) {
    if (e.statusCode == 403) {
      _errorMessage = e.message.isNotEmpty
          ? e.message
          : 'Akses ke akun Anda dibatasi oleh server (403 Forbidden).';
      _state = AuthState.error;
    } else {
      _errorMessage = _extractApiErrorMessage(e);
      _state = AuthState.unauthenticated;
    }
    _safeNotifyListeners();
  }

  String _extractApiErrorMessage(ApiException e) {
    final errors = e.errors;
    if (errors != null) {
      for (final value in errors.values) {
        if (value is List && value.isNotEmpty) {
          final first = value.first.toString().trim();
          if (first.isNotEmpty) return first;
        } else if (value is String && value.trim().isNotEmpty) {
          return value.trim();
        }
      }
    }
    return e.message.isNotEmpty
        ? e.message
        : 'Terjadi kesalahan saat memproses autentikasi.';
  }

  String _formatUnexpectedAuthError(Object e) {
    if (e is SocketException) {
      return 'Tidak dapat terhubung ke server. Periksa koneksi internet Anda.';
    }
    if (e is TimeoutException) {
      return 'Koneksi ke server habis waktu. Silakan coba lagi.';
    }
    return e
        .toString()
        .replaceFirst('ApiException: ', '')
        .replaceFirst('Exception: ', '');
  }

  Future<bool> updateProfile({
    String? name,
    String? phone,
    bool? whatsappPublic,
  }) async {
    if (_isUpdatingProfile) return false;

    _isUpdatingProfile = true;
    _errorMessage = null;
    _safeNotifyListeners();

    try {
      final updatedUser = await authRepository.updateProfile(
        name: name,
        phone: phone,
        whatsappPublic: whatsappPublic,
      );
      if (_disposed) return false;
      _currentUser = updatedUser;
      return true;
    } on ApiException catch (e) {
      if (_disposed) return false;
      final phoneErrors = e.errors?['phone'];
      final privacyErrors = e.errors?['whatsapp_public'];
      if (phoneErrors is List && phoneErrors.isNotEmpty) {
        _errorMessage = phoneErrors.first.toString();
      } else if (privacyErrors is List && privacyErrors.isNotEmpty) {
        _errorMessage = privacyErrors.first.toString();
      } else {
        _errorMessage = e.message;
      }
      return false;
    } catch (e) {
      if (_disposed) return false;
      _errorMessage = e.toString().replaceFirst('ApiException: ', '');
      return false;
    } finally {
      _isUpdatingProfile = false;
      _safeNotifyListeners();
    }
  }

  Future<void> logout() async {
    if (_isLoggingOut) return;

    _isLoggingOut = true;
    _state = AuthState.loading;
    _safeNotifyListeners();

    try {
      onSessionCleared?.call();
      await authRepository.logout();
    } finally {
      onSessionCleared?.call();
      _currentUser = null;
      _errorMessage = null;
      _state = AuthState.unauthenticated;
      _isLoggingOut = false;
      _safeNotifyListeners();
    }
  }
}

