import '../../../core/network/api_client.dart';
import 'cat_hunter_model.dart';

class CatHunterService {
  final ApiClient _client = ApiClient();

  Future<List<UserCatDexModel>> getMyDex() async {
    final response = await _client.get('/cat-hunter/my-dex');
    final list = response.data['data'] as List;
    return list.map((e) => UserCatDexModel.fromJson(e)).toList();
  }

  Future<List<LeaderboardEntry>> getLeaderboard() async {
    final response = await _client.get('/cat-hunter/leaderboard');
    final list = response.data['data'] as List;
    return list.map((e) => LeaderboardEntry.fromJson(e)).toList();
  }

  Future<Map<String, dynamic>> submitEncounter({
    required String catQrToken,
    required double latitude,
    required double longitude,
    required String condition,
  }) async {
    final response = await _client.post('/cat-hunter/encounter', data: {
      'cat_qr_token': catQrToken,
      'latitude': latitude,
      'longitude': longitude,
      'condition': condition,
    });
    return response.data['data'];
  }
}
