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
        'student_id': studentId,
        'phone': phone,
      },
    );

    final data = response.data['data'];
    return {'token': data['token'], 'user': UserModel.fromJson(data['user'])};
  }

  Future<UserModel> getProfile() async {
    final response = await _client.get('/auth/profile');
    return UserModel.fromJson(response.data['data']);
  }

  Future<void> logout() async {
    await _client.post('/auth/logout');
  }
}
