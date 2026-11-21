import '../../../core/network/api_client.dart';
import 'user_model.dart';

class AuthService {
  final ApiClient _client = ApiClient();

  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await _client.post(
      '/auth/login',
      data: {'email': email, 'password': password},
    );

    final data = response.data['data'];
    return {'token': data['token'], 'user': UserModel.fromJson(data['user'])};
  }

  Future<void> requestEmailOtp(String email) async {
    await _client.post('/auth/email/otp/request', data: {'email': email});
  }

  Future<Map<String, dynamic>> loginWithEmailOtp(
      String email, String otp) async {
    final response = await _client.post(
      '/auth/email/otp/login',
      data: {'email': email, 'otp': otp},
    );
    final data = response.data['data'];
    return {'token': data['token'], 'user': UserModel.fromJson(data['user'])};
  }

  Future<Map<String, dynamic>> loginWithGoogle(String idToken) async {
    final response = await _client.post(
      '/auth/google',
      data: {'id_token': idToken},
    );
    final data = response.data['data'];
    return {'token': data['token'], 'user': UserModel.fromJson(data['user'])};
  }

  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    String? studentId,
    String? phone,
  }) async {
    final response = await _client.post(
      '/auth/register',
      data: {
        'name': name,
        'email': email,
        'password': password,
        'identity_number': studentId,
        'phone': phone,
      },
    );

    final data = response.data['data'];
    return {'token': data['token'], 'user': UserModel.fromJson(data['user'])};
  }

  Future<UserModel> getProfile() async {
    final response = await _client.get('/me');
    return UserModel.fromJson(response.data['data']);
  }

  Future<void> verifyEmailOtp(String otp) async {
    await _client.post('/auth/email/otp/verify', data: {'otp': otp});
  }

  Future<void> resendEmailOtp() async {
    await _client.post('/auth/email/otp/resend');
  }

  Future<void> logout() async {
    await _client.post('/auth/logout');
  }
}
