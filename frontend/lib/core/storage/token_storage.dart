import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../constants/app_constants.dart';

class TokenStorage {
  static final TokenStorage _instance = TokenStorage._internal();
  factory TokenStorage() => _instance;
  TokenStorage._internal();

  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  Future<void> saveToken(String token) async {
    await _storage.write(key: AppConstants.keyAuthToken, value: token);
  }

  Future<String?> getToken() async {
    return await _storage.read(key: AppConstants.keyAuthToken);
  }

  Future<void> deleteToken() async {
    await _storage.delete(key: AppConstants.keyAuthToken);
  }

  Future<bool> hasToken() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }
}
