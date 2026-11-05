import 'dart:typed_data';

import 'feeding_spot_model.dart';

enum FeedingStatus { underReview, verified, rejected }

class FeedingEvidence {
  const FeedingEvidence({
    required this.bytes,
    required this.capturedAt,
    this.isExample = false,
    this.mediaId,
  });
  final Uint8List bytes;
  final DateTime capturedAt;
  final bool isExample;
  final String? mediaId;
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
  final String rewardStatus;
  final bool rewardCapped;
  final String foodType;
  final String quantity;
  final List<FeedingEvidence> evidence;
  FeedingEvidence? get photo => evidence.isEmpty ? null : evidence.first;
  final String notes;
  final int? potentialPoints;
  final int creditedPoints;
  final String? reason;

  factory FeedingSubmission.fromJson(
    Map<String, dynamic> json, {
    FeedingSpotModel? fallbackSpot,
  }) {
    final rawStatus = (json['status'] ?? 'UNDER_REVIEW').toString().toUpperCase();
    final parsedStatus = switch (rawStatus) {
      'VERIFIED' => FeedingStatus.verified,
      'REJECTED' => FeedingStatus.rejected,
      _ => FeedingStatus.underReview,
    };

    final spotJson = json['spot'] is Map<String, dynamic>
        ? json['spot'] as Map<String, dynamic>
        : null;

    final spot = spotJson != null
        ? FeedingSpotModel.fromJson(spotJson)
        : (fallbackSpot ??
            const FeedingSpotModel(
              id: '',
              name: 'Spot Pakan Kampus',
              code: 'SPOT',
              qrToken: '',
              locationName: 'Kampus Telkom University',
              latitude: -6.9740,
              longitude: 107.6300,
              status: 'active',
              bowlCondition: 'unknown',
            ));

    final points = (json['points_awarded'] as num?)?.toInt() ?? 0;

    return FeedingSubmission(
      id: (json['id'] ?? json['activity_id'] ?? '').toString(),
      spot: spot,
      createdAt: DateTime.tryParse(
            (json['submitted_at'] ?? json['scanned_at'] ?? '').toString(),
          ) ??
          DateTime.now(),
      status: parsedStatus,
      rewardStatus: (json['reward_status'] ?? 'NONE').toString(),
      rewardCapped: json['reward_capped'] == true,
      foodType: (json['food_type'] ?? 'dry_food').toString(),
      quantity: (json['food_amount'] ?? '1 mangkuk').toString(),
      notes: (json['notes'] ?? '').toString(),
      potentialPoints: points > 0 ? points : 10,
      creditedPoints: points,
    );
  }

  String get statusLabel => switch (status) {
    FeedingStatus.underReview => 'Menunggu pemeriksaan',
    FeedingStatus.verified => 'Terverifikasi',
    FeedingStatus.rejected => 'Perlu diperbaiki',
  };

  /// AFS-08: Status kegiatan dan status reward ditampilkan terpisah.
  String get rewardStatusLabel {
    if (rewardStatus.toUpperCase() == 'CREDITED' && creditedPoints > 0) {
      return '+$creditedPoints poin dikreditkan';
    }
    if (rewardCapped || (rewardStatus.toUpperCase() == 'CREDITED' && creditedPoints == 0)) {
      return 'Tanpa poin (batas harian tercapai)';
    }
    if (rewardStatus.toUpperCase() == 'PENDING') {
      return 'Menunggu verifikasi poin';
    }
    if (rewardStatus.toUpperCase() == 'REVERSED') {
      return 'Poin dibatalkan';
    }
    return 'Tidak berpoin';
  }

  String get foodLabel => switch (foodType) {
    'wet_food' => 'Wet Food (Pakan Basah)',
    'water' => 'Air Minum Bersih',
    _ => 'Dry Food (Pakan Kering)',
  };
}
