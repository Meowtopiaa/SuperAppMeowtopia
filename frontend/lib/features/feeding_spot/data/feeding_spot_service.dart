import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:uuid/uuid.dart';

import '../../../core/network/api_client.dart';
import 'feeding_session.dart';
import 'feeding_spot_model.dart';

class FeedingSpotService {
  final ApiClient _client = ApiClient();
  final Uuid _uuid = const Uuid();

  Future<List<FeedingSpotModel>> getSpots() async {
    final response = await _client.get('/feeding/spots');
    final list = (response.data['data'] as List?) ?? const [];
    return list
        .whereType<Map<String, dynamic>>()
        .map(FeedingSpotModel.fromJson)
        .toList();
  }

  Future<FeedingSpotModel> getSpotDetail(String id) async {
    final response = await _client.get('/feeding/spots/$id');
    final data = response.data['data'] as Map<String, dynamic>;
    return FeedingSpotModel.fromJson(data);
  }

  Future<Map<String, dynamic>> openSession({
    required String qrToken,
    String? idempotencyKey,
  }) async {
    final response = await _client.post(
      '/feeding/activities',
      data: {'qr_token': qrToken},
      headers: {'Idempotency-Key': idempotencyKey ?? _uuid.v4()},
    );
    return (response.data['data'] as Map<String, dynamic>?) ?? {};
  }

  Future<Map<String, dynamic>> confirmIntent(
    String activityId, {
    String? idempotencyKey,
  }) async {
    final response = await _client.post(
      '/feeding/activities/$activityId/intent',
      headers: {'Idempotency-Key': idempotencyKey ?? _uuid.v4()},
    );
    return (response.data['data'] as Map<String, dynamic>?) ?? {};
  }

  Future<String> uploadEvidence(
    Uint8List bytes, {
    String filename = 'feeding-proof.jpg',
  }) async {
    final formData = FormData.fromMap({
      'purpose': 'feeding_proof',
      'file': MultipartFile.fromBytes(bytes, filename: filename),
    });
    final response = await _client.post(
      '/media',
      data: formData,
      headers: {'Content-Type': 'multipart/form-data'},
    );
    final data = (response.data['data'] as Map<String, dynamic>?) ?? {};
    final mediaId = data['id']?.toString() ?? '';
    if (mediaId.isEmpty) {
      throw StateError('Gagal mengunggah bukti foto kegiatan.');
    }
    return mediaId;
  }

  Future<Map<String, dynamic>> finalizeSession({
    required String activityId,
    required List<String> mediaIds,
    required String foodType,
    required String foodAmount,
    String? notes,
    String? catId,
    String? catCode,
    String? idempotencyKey,
  }) async {
    final response = await _client.post(
      '/feeding/activities/$activityId/finalize',
      data: {
        'media_ids': mediaIds,
        'food_type': foodType,
        'food_amount': foodAmount,
        if (notes != null && notes.trim().isNotEmpty) 'notes': notes.trim(),
        if (catId != null && catId.trim().isNotEmpty) 'cat_id': catId.trim(),
        if (catCode != null && catCode.trim().isNotEmpty)
          'cat_code': catCode.trim(),
      },
      headers: {'Idempotency-Key': idempotencyKey ?? _uuid.v4()},
    );
    return (response.data['data'] as Map<String, dynamic>?) ?? {};
  }

  Future<List<FeedingSubmission>> getMyActivities(
    Map<String, FeedingSpotModel> spotsById,
  ) async {
    final response = await _client.get('/feeding/activities/mine');
    final list = (response.data['data'] as List?) ?? const [];
    return list.whereType<Map<String, dynamic>>().map((json) {
      final spotJson = json['spot'] as Map<String, dynamic>?;
      final spotId =
          json['spot_id']?.toString() ?? spotJson?['id']?.toString() ?? '';
      final fallbackSpot =
          spotsById[spotId] ??
          (spotJson != null
              ? FeedingSpotModel.fromJson(spotJson)
              : FeedingSpotModel(
                  id: spotId,
                  code: spotJson?['code']?.toString() ?? spotId,
                  qrToken: '',
                  name: spotJson?['name']?.toString() ?? 'Feeding Spot',
                  locationName:
                      spotJson?['description']?.toString() ??
                      'Kampus Telkom University',
                  latitude: -6.9740,
                  longitude: 107.6300,
                  status: 'active',
                  bowlCondition: 'unknown',
                ));
      return FeedingSubmission.fromJson(json, fallbackSpot: fallbackSpot);
    }).toList();
  }
}
