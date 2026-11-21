import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../../../core/network/api_exception.dart';
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
      return await _completeLogin(_authService.login(email, password));
    } catch (e) {
      _isLoading = false;
      _errorMessage = _messageFor(e);
      notifyListeners();
      return false;
    }
  }

  Future<bool> requestEmailOtp(String email) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _authService.requestEmailOtp(email);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = _messageFor(e);
      notifyListeners();
      return false;
    }
  }

  Future<bool> loginWithEmailOtp(String email, String otp) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      return await _completeLogin(_authService.loginWithEmailOtp(email, otp));
    } catch (e) {
      _isLoading = false;
      _errorMessage = _messageFor(e);
      notifyListeners();
      return false;
    }
  }

  Future<bool> loginWithGoogle(String idToken) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      return await _completeLogin(_authService.loginWithGoogle(idToken));
    } catch (e) {
      _isLoading = false;
      _errorMessage = _messageFor(e);
      notifyListeners();
      return false;
    }
  }

  Future<bool> verifyEmailOtp(String otp) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _authService.verifyEmailOtp(otp);
      _user = await _authService.getProfile();
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = _messageFor(e);
      notifyListeners();
      return false;
    }
  }

  Future<bool> resendEmailOtp() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _authService.resendEmailOtp();
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = _messageFor(e);
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
      await _tokenStorage.saveToken(token);
      _user = result['user'] as UserModel;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = _messageFor(e);
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

  String _messageFor(Object error) {
    if (error is DioException) {
      if (error.response == null) {
        return 'Belum bisa terhubung ke server. Periksa koneksi dan coba lagi.';
      }
      final detail = error.error;
      if (detail is ApiException && (detail.statusCode ?? 500) < 500) {
        return detail.message;
      }
      if (detail is ApiException && detail.statusCode == 503) {
        return detail.message;
      }
    }
    return 'Proses belum berhasil. Coba lagi beberapa saat.';
  }

  Future<bool> _completeLogin(Future<Map<String, dynamic>> request) async {
    final result = await request;
    final token = result['token'] as String;
    await _tokenStorage.saveToken(token);
    _user = result['user'] as UserModel;
    _isLoading = false;
    notifyListeners();
    return true;
  }
}
