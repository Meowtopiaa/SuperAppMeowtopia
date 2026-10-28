import '../../../core/network/api_client.dart';
import 'feeding_spot_model.dart';

class FeedingSpotService {
  final ApiClient _client = ApiClient();

  Future<List<FeedingSpotModel>> getSpots() async {
    final response = await _client.get('/feeding-spots');
    final list = response.data['data'] as List;
    return list.map((e) => FeedingSpotModel.fromJson(e)).toList();
  }

  Future<Map<String, dynamic>> recordFeeding({
    required int spotId,
    required String qrToken,
    required String foodType,
    String? photoProofUrl,
    String? notes,
  }) async {
    final response = await _client.post('/feeding-spots/record', data: {
      'feeding_spot_id': spotId,
      'qr_token': qrToken,
      'food_type': foodType,
      'photo_proof_url': photoProofUrl,
      'notes': notes,
    });
    return response.data['data'];
  }
}
