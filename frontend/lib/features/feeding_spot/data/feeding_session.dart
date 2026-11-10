import 'dart:typed_data';

import 'feeding_spot_model.dart';

enum FeedingStatus { underReview, verified, rejected }

class FeedingEvidence {
  const FeedingEvidence({
    required this.bytes,
    required this.capturedAt,
    this.isExample = false,
  });
  final Uint8List bytes;
  final DateTime capturedAt;
  final bool isExample;
}

class FeedingSession {
  FeedingSession({
    required this.id,
    required this.spot,
    required this.startedAt,
    required this.expiresAt,
  });
  final String id;
  final FeedingSpotModel spot;
  final DateTime startedAt;
  final DateTime expiresAt;
  final List<FeedingEvidence> evidence = [];
  String foodType = 'dry_food';
  String quantity = '2 genggam (perkiraan 120 g)';
  String notes = '';
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
  String get foodLabel => switch (foodType) {
    'wet_food' => 'Wet Food (Pakan Basah)',
    'water' => 'Air Minum Bersih',
    _ => 'Dry Food (Pakan Kering)',
  };
}
