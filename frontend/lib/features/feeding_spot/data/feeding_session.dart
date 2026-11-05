import 'dart:typed_data';

import 'feeding_spot_model.dart';

enum FeedingStatus { underReview, verified, rejected }

class FeedingEvidence {
  const FeedingEvidence({
    required this.bytes,
    required this.capturedAt,
    this.isExample = false,
    this.mediaId,
    this.remoteUrl,
  });

  final Uint8List bytes;
  final DateTime capturedAt;
  final bool isExample;
  final String? mediaId;
  final String? remoteUrl;
}

class FeedingSession {
  FeedingSession({
    required this.id,
    required this.spot,
    required this.startedAt,
    required this.expiresAt,
    this.intentDeadlineAt,
  });

  final String id;
  final FeedingSpotModel spot;
  final DateTime startedAt;
  final DateTime expiresAt;
  final DateTime? intentDeadlineAt;
  final List<FeedingEvidence> evidence = [];
  String foodType = 'dry_food';
  String quantity = '2 genggam (perkiraan 120 g)';
  String notes = '';
  String? catCode;

  bool get isExpired => !DateTime.now().isBefore(expiresAt);
  bool get canSubmit =>
      !isExpired && evidence.isNotEmpty && evidence.length <= 3;
}

class FeedingSubmission {
  const FeedingSubmission({
    required this.id,
    required this.spot,
    required this.createdAt,
    required this.status,
    required this.foodType,
    required this.quantity,
    this.rewardStatus = 'PENDING',
    this.rewardCapped = false,
    this.evidence = const [],
    this.notes = '',
    this.potentialPoints,
    this.creditedPoints = 0,
    this.reason,
  });

  final String id;
  final FeedingSpotModel spot;
  final DateTime createdAt;
  final FeedingStatus status;
  final String rewardStatus; // PENDING, CREDITED, NOT_ELIGIBLE, FAILED, REVERSED
  final bool rewardCapped;
  final String foodType;
  final String quantity;
  final List<FeedingEvidence> evidence;
  FeedingEvidence? get photo => evidence.isEmpty ? null : evidence.first;
  final String notes;
  final int? potentialPoints;
  final int creditedPoints;
  final String? reason;

  String get statusLabel => switch (status) {
    FeedingStatus.underReview => 'Menunggu pemeriksaan',
    FeedingStatus.verified => 'Terverifikasi',
    FeedingStatus.rejected => 'Perlu diperbaiki',
  };

  String get rewardStatusLabel => switch (rewardStatus.toUpperCase()) {
    'CREDITED' => '+$creditedPoints poin dikreditkan',
    'NOT_ELIGIBLE' => rewardCapped
        ? 'Kuota reward harian (3x) terpenuhi'
        : 'Tidak memenuhi syarat poin',
    'FAILED' => 'Poin tertunda (gangguan layanan)',
    'REVERSED' => 'Poin dibatalkan (koreksi)',
    _ => 'Poin menunggu verifikasi',
  };

  String get foodLabel => switch (foodType) {
    'wet_food' => 'Wet Food (Pakan Basah)',
    'water' => 'Air Minum Bersih',
    _ => 'Dry Food (Pakan Kering)',
  };

  factory FeedingSubmission.fromJson(
    Map<String, dynamic> json, {
    FeedingSpotModel? fallbackSpot,
  }) {
    final statusRaw = (json['status']?.toString() ?? 'UNDER_REVIEW').toUpperCase();
    final status = switch (statusRaw) {
      'VERIFIED' => FeedingStatus.verified,
      'REJECTED' => FeedingStatus.rejected,
      _ => FeedingStatus.underReview,
    };

    final spotMap = json['spot'] is Map
        ? Map<String, dynamic>.from(json['spot'] as Map)
        : null;
    final spot = spotMap != null
        ? FeedingSpotModel.fromJson(spotMap)
        : (fallbackSpot ??
            const FeedingSpotModel(
              id: '0',
              name: 'Titik Makan Kampus',
              code: 'SPOT',
              qrToken: '',
              locationName: 'Kampus',
              latitude: 0,
              longitude: 0,
              status: 'ACTIVE',
            ));

    final reviewMap = json['review'] is Map
        ? Map<String, dynamic>.from(json['review'] as Map)
        : null;

    return FeedingSubmission(
      id: (json['id'] ?? json['activity_id'] ?? '').toString(),
      spot: spot,
      createdAt: DateTime.tryParse(
            (json['finalized_at'] ?? json['scanned_at'] ?? '').toString(),
          ) ??
          DateTime.now(),
      status: status,
      rewardStatus: (json['reward_status'] ?? 'PENDING').toString(),
      rewardCapped: json['reward_capped'] == true,
      foodType: (json['food_type'] ?? 'dry_food').toString(),
      quantity: (json['food_amount'] ?? '1 porsi').toString(),
      notes: (json['notes'] ?? '').toString(),
      potentialPoints: (json['potential_points'] as num?)?.toInt(),
      creditedPoints: (json['points_awarded'] as num?)?.toInt() ?? 0,
      reason: reviewMap?['reason']?.toString(),
    );
  }
}
