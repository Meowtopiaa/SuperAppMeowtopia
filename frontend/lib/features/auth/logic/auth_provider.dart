import 'package:flutter/material.dart';

import '../../../core/storage/token_storage.dart';
import '../data/auth_service.dart';
import '../data/user_model.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final TokenStorage _tokenStorage = TokenStorage();

  UserModel? _user;
  bool _isLoading = false;
  String? _errorMessage;

  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _user != null;

  Future<bool> checkAuthStatus() async {
    final hasToken = await _tokenStorage.hasToken();
    if (!hasToken) return false;

    try {
      _user = await _authService.getProfile();
      notifyListeners();
      return true;
    } catch (e) {
      await _tokenStorage.deleteToken();
      _user = null;
      notifyListeners();
      return false;
    }
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _authService.login(email, password);
      final token = result['token'] as String;
      _user = result['user'] as UserModel;

      await _tokenStorage.saveToken(token);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> register({
    required String name,
    required String email,
    required String password,
    String? studentId,
    String? phone,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _authService.register(
        name: name,
        email: email,
        password: password,
        studentId: studentId,
        phone: phone,
      );
      final token = result['token'] as String;
      _user = result['user'] as UserModel;

      await _tokenStorage.saveToken(token);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    try {
      await _authService.logout();
    } catch (_) {}
    await _tokenStorage.deleteToken();
    _user = null;
    notifyListeners();
  }
}
