import '../../../core/network/api_client.dart';
import 'feeding_spot_model.dart';

class FeedingSpotService {
  final ApiClient _client = ApiClient();

  Future<List<FeedingSpotModel>> getSpots() async {
    final response = await _client.get('/feeding-spots');
    final list = response.data['data'] as List;
    return list.map((e) => FeedingSpotModel.fromJson(e)).toList();
  }
}
