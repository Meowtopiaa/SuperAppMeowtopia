class FeedingSpotModel {
  final String id;
  final String name;
  final String code;
  final String qrToken;
  final String locationName;
  final String? description;
  final String? territoryId;
  final double latitude;
  final double longitude;
  final String status;
  final String bowlCondition;
  final DateTime? lastFedAt;
  final int activitiesCount;
  final int? verifiedCount14Days;
  final double? needScore;
  final String? imageUrl;
  final String imageAsset;
  final DateTime? aggregateUpdatedAt;
  final bool hasPendingReview;

  /// Client-side only distance in meters (computed locally on device via Geolocator, never sent to server).
  final double? distanceMeters;

  const FeedingSpotModel({
    required this.id,
    required this.name,
    required this.code,
    required this.qrToken,
    required this.locationName,
    this.description,
    this.territoryId,
    required this.latitude,
    required this.longitude,
    required this.status,
    required this.bowlCondition,
    this.lastFedAt,
    this.activitiesCount = 0,
    this.verifiedCount14Days,
    this.needScore,
    this.imageUrl,
    this.imageAsset = 'assets/images/figma/feeding-shelter.png',
    this.aggregateUpdatedAt,
    this.hasPendingReview = false,
    this.distanceMeters,
  });

  factory FeedingSpotModel.fromJson(Map<String, dynamic> json) {
    final aggregate = json['aggregate'] is Map<String, dynamic>
        ? json['aggregate'] as Map<String, dynamic>
        : null;
    final territory = json['territory'] is Map<String, dynamic>
        ? json['territory'] as Map<String, dynamic>
        : null;

    final rawLastFed = json['last_fed_at']?.toString() ??
        aggregate?['last_fed_at']?.toString();

    final rawVerified14d = json['verified_count_14_days'] ??
        aggregate?['total_feedings'] ??
        aggregate?['verified_count'];

    final pendingCount = (aggregate?['pending_count'] as num?)?.toInt() ?? 0;
    final hasPending = json['has_pending_review'] == true || pendingCount > 0;

    return FeedingSpotModel(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      code: (json['code'] ?? '').toString(),
      qrToken: (json['qr_token'] ?? 'MTP1.S.${json['code'] ?? ''}').toString(),
      locationName: (json['location_name'] ??
              territory?['name'] ??
              json['description'] ??
              'Area Kampus Telkom University')
          .toString(),
      description: json['description']?.toString(),
      territoryId: json['territory_id']?.toString(),
      latitude: (json['latitude'] != null)
          ? double.tryParse(json['latitude'].toString()) ?? 0.0
          : 0.0,
      longitude: (json['longitude'] != null)
          ? double.tryParse(json['longitude'].toString()) ?? 0.0
          : 0.0,
      status: (json['status'] ?? 'ACTIVE').toString().toLowerCase(),
      bowlCondition: (json['bowl_condition'] ?? 'unknown').toString(),
      lastFedAt: rawLastFed != null ? DateTime.tryParse(rawLastFed) : null,
      activitiesCount: (json['activities_count'] as num?)?.toInt() ??
          (rawVerified14d as num?)?.toInt() ??
          0,
      verifiedCount14Days: (rawVerified14d as num?)?.toInt(),
      needScore: (aggregate?['need_score'] as num?)?.toDouble(),
      imageUrl: json['image_url']?.toString(),
      aggregateUpdatedAt: DateTime.tryParse(
        json['aggregate_updated_at']?.toString() ?? '',
      ),
      hasPendingReview: hasPending,
    );
  }

  FeedingSpotModel copyWith({
    double? distanceMeters,
    DateTime? lastFedAt,
    int? verifiedCount14Days,
    String? status,
    bool? hasPendingReview,
  }) {
    return FeedingSpotModel(
      id: id,
      name: name,
      code: code,
      qrToken: qrToken,
      locationName: locationName,
      description: description,
      territoryId: territoryId,
      latitude: latitude,
      longitude: longitude,
      status: status ?? this.status,
      bowlCondition: bowlCondition,
      lastFedAt: lastFedAt ?? this.lastFedAt,
      activitiesCount: activitiesCount,
      verifiedCount14Days: verifiedCount14Days ?? this.verifiedCount14Days,
      needScore: needScore,
      imageUrl: imageUrl,
      imageAsset: imageAsset,
      aggregateUpdatedAt: aggregateUpdatedAt,
      hasPendingReview: hasPendingReview ?? this.hasPendingReview,
      distanceMeters: distanceMeters ?? this.distanceMeters,
    );
  }

  bool get isActive => status.toLowerCase() == 'active';
  bool get hasLowActivity =>
      verifiedCount14Days != null && verifiedCount14Days! < 7;
  String get activityLabel => verifiedCount14Days == null
      ? 'Data belum tersedia'
      : hasLowActivity
      ? 'Jarang tercatat'
      : 'Rutin tercatat';

  /// AFS-02 & MEOW-25 requirement: Fallback "Belum ada catatan"
  String get lastFedSentence {
    if (lastFedAt == null) {
      return 'Belum ada catatan';
    }
    final diff = DateTime.now().difference(lastFedAt!);
    if (diff.inMinutes < 1) {
      return 'Terakhir tercatat diberi makan baru saja';
    }
    if (diff.inMinutes < 60) {
      return 'Terakhir tercatat diberi makan ${diff.inMinutes} menit lalu';
    }
    if (diff.inHours < 24) {
      return 'Terakhir tercatat diberi makan ${diff.inHours} jam lalu';
    }
    return 'Terakhir tercatat diberi makan ${diff.inDays} hari lalu';
  }

  String? get distanceLabel {
    if (distanceMeters == null) return null;
    if (distanceMeters! < 1000) {
      return '${distanceMeters!.round()} m dari lokasimu';
    }
    return '${(distanceMeters! / 1000).toStringAsFixed(1)} km dari lokasimu';
  }
}
