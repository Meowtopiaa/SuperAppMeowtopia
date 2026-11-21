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
    this.feedingRecordRef,
    this.intentDeadlineAt,
    this.finalizeDeadlineAt,
  });
  final String id;
  final String? feedingRecordRef;
  final FeedingSpotModel spot;
  final DateTime startedAt;
  final DateTime expiresAt;
  final DateTime? intentDeadlineAt;
  final DateTime? finalizeDeadlineAt;
  final List<FeedingEvidence> evidence = [];
  String foodType = 'dry_food';
  String quantity = '2 genggam (perkiraan 120 g)';
  String notes = '';
  String? catId;
  String? catCode;

  Duration get remainingIntentTime {
    final deadline = intentDeadlineAt ?? startedAt.add(const Duration(minutes: 15));
    final diff = deadline.difference(DateTime.now());
    return diff.isNegative ? Duration.zero : diff;
  }

  Duration get remainingFinalizeTime {
    final deadline = finalizeDeadlineAt ?? expiresAt;
    final diff = deadline.difference(DateTime.now());
    return diff.isNegative ? Duration.zero : diff;
  }

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
    this.feedingRecordRef,
    this.rewardStatus = 'PENDING',
    this.rewardCapped = false,
    this.evidence = const [],
    this.notes = '',
    this.catId,
    this.potentialPoints,
    this.creditedPoints = 0,
    this.reason,
  });
  final String id;
  final String? feedingRecordRef;
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
  final String? catId;
  final int? potentialPoints;
  final int creditedPoints;
  final String? reason;

  factory FeedingSubmission.fromJson(
    Map<String, dynamic> json, {
    FeedingSpotModel? fallbackSpot,
    List<FeedingEvidence>? localEvidence,
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
    final potential = (json['potential_points'] as num?)?.toInt();

    return FeedingSubmission(
      id: (json['id'] ?? json['activity_id'] ?? '').toString(),
      feedingRecordRef: json['feeding_record_ref']?.toString(),
      spot: spot,
      createdAt: DateTime.tryParse(
            (json['submitted_at'] ?? json['scanned_at'] ?? '').toString(),
          ) ??
          DateTime.now(),
      status: parsedStatus,
      rewardStatus: (json['reward_status'] ?? 'PENDING').toString(),
      rewardCapped: json['reward_capped'] == true,
      foodType: (json['food_type'] ?? 'dry_food').toString(),
      quantity: (json['food_amount'] ?? '1 mangkuk').toString(),
      evidence: localEvidence ?? const [],
      notes: (json['notes'] ?? '').toString(),
      catId: json['cat_id']?.toString(),
      potentialPoints: potential ?? (points > 0 ? points : 10),
      creditedPoints: points,
      reason: json['rejection_reason']?.toString(),
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
      return 'Poin dikreditkan';
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
