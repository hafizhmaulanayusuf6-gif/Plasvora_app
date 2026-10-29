import 'package:flutter/foundation.dart';
import '../models/user_profile.dart';
import '../repositories/auth_repository.dart';

enum AuthState { initial, loading, authenticated, unauthenticated, error }

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

  AuthViewModel({required this.authRepository}) {
    checkAuthSession();
  }

  Future<void> checkAuthSession() async {
    _state = AuthState.loading;
    notifyListeners();

    try {
      final user = await authRepository.getCurrentUser();
      if (user != null) {
        _currentUser = user;
        _state = AuthState.authenticated;
      } else {
        _currentUser = null;
        _state = AuthState.unauthenticated;
      }
    } catch (_) {
      _currentUser = null;
      _state = AuthState.unauthenticated;
    } finally {
      notifyListeners();
    }
  }

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

    await authRepository.logout();
    _currentUser = null;
    _state = AuthState.unauthenticated;
    notifyListeners();
  }
}

