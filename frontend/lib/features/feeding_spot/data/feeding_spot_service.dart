import 'dart:typed_data';

import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import 'feeding_session.dart';
import 'feeding_spot_model.dart';

class FeedingSpotService {
  final ApiClient _client = ApiClient();

  /// GET /api/v1/feeding/spots
  Future<List<FeedingSpotModel>> getSpots() async {
    final response = await _client.get('/feeding/spots');
    final list = response.data['data'] as List;
    return list
        .map((e) => FeedingSpotModel.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  /// GET /api/v1/feeding/spots/{id}
  Future<FeedingSpotModel> getSpotDetail(String id) async {
    final response = await _client.get('/feeding/spots/$id');
    final map = Map<String, dynamic>.from(response.data['data'] as Map);
    return FeedingSpotModel.fromJson(map);
  }

  /// POST /api/v1/feeding/activities †
  Future<Map<String, dynamic>> startSession(String qrToken) async {
    final response = await _client.post(
      '/feeding/activities',
      data: {'qr_token': qrToken},
    );
    return Map<String, dynamic>.from(response.data['data'] as Map);
  }

  /// POST /api/v1/feeding/activities/{id}/intent †
  Future<Map<String, dynamic>> confirmIntent(String activityId) async {
    final response = await _client.post('/feeding/activities/$activityId/intent');
    return Map<String, dynamic>.from(response.data['data'] as Map);
  }

  /// POST /api/v1/media † (purpose: feeding_proof)
  Future<String> uploadEvidencePhoto(Uint8List bytes, int index) async {
    final formData = FormData.fromMap({
      'purpose': 'feeding_proof',
      'file': MultipartFile.fromBytes(
        bytes,
        filename: 'feeding_proof_${DateTime.now().millisecondsSinceEpoch}_$index.jpg',
      ),
    });
    final response = await _client.post('/media', data: formData);
    final data = Map<String, dynamic>.from(response.data['data'] as Map);
    return data['id'].toString();
  }

  /// POST /api/v1/feeding/activities/{id}/finalize †
  Future<Map<String, dynamic>> finalizeSession({
    required String activityId,
    required List<String> mediaIds,
    required String foodType,
    String? foodAmount,
    String? catCode,
    String? notes,
  }) async {
    final response = await _client.post(
      '/feeding/activities/$activityId/finalize',
      data: {
        'media_ids': mediaIds,
        'food_type': foodType,
        if (foodAmount != null && foodAmount.isNotEmpty) 'food_amount': foodAmount,
        if (catCode != null && catCode.isNotEmpty) 'cat_code': catCode,
        if (notes != null && notes.isNotEmpty) 'notes': notes,
      },
    );
    return Map<String, dynamic>.from(response.data['data'] as Map);
  }

  /// GET /api/v1/feeding/activities/mine
  Future<List<FeedingSubmission>> getMyActivities() async {
    final response = await _client.get('/feeding/activities/mine');
    final list = response.data['data'] as List;
    return list
        .map((e) => FeedingSubmission.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }
}
