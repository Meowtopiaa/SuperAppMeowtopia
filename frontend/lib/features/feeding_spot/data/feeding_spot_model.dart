import '../../../core/utils/date_labels.dart';

class FeedingSpotModel {
  final String id;
  final String name;
  final String code;
  final String qrToken;
  final String locationName;
  final double latitude;
  final double longitude;
  final String status;
  final String bowlCondition;
  final DateTime? lastFedAt;
  final int activitiesCount;
  final int? verifiedCount14Days;
  final int? pendingCount14Days;
  final bool isAggregateStale;
  final String? imageUrl;
  final String imageAsset;
  final DateTime? aggregateUpdatedAt;
  final double? distanceMeters;

  const FeedingSpotModel({
    required this.id,
    required this.name,
    required this.code,
    required this.qrToken,
    required this.locationName,
    required this.latitude,
    required this.longitude,
    required this.status,
    this.bowlCondition = 'unknown',
    this.lastFedAt,
    this.activitiesCount = 0,
    this.verifiedCount14Days,
    this.pendingCount14Days,
    this.isAggregateStale = false,
    this.imageUrl,
    this.imageAsset = 'assets/images/figma/feeding-shelter.png',
    this.aggregateUpdatedAt,
    this.distanceMeters,
  });

  FeedingSpotModel copyWith({
    double? distanceMeters,
    DateTime? lastFedAt,
    int? verifiedCount14Days,
  }) {
    return FeedingSpotModel(
      id: id,
      name: name,
      code: code,
      qrToken: qrToken,
      locationName: locationName,
      latitude: latitude,
      longitude: longitude,
      status: status,
      bowlCondition: bowlCondition,
      lastFedAt: lastFedAt ?? this.lastFedAt,
      activitiesCount: activitiesCount,
      verifiedCount14Days: verifiedCount14Days ?? this.verifiedCount14Days,
      pendingCount14Days: pendingCount14Days,
      isAggregateStale: isAggregateStale,
      imageUrl: imageUrl,
      imageAsset: imageAsset,
      aggregateUpdatedAt: aggregateUpdatedAt,
      distanceMeters: distanceMeters ?? this.distanceMeters,
    );
  }

  factory FeedingSpotModel.fromJson(Map<String, dynamic> json) {
    final agg = json['aggregate'] is Map
        ? Map<String, dynamic>.from(json['aggregate'] as Map)
        : null;

    final verifiedCount = agg != null
        ? (agg['verified_count'] as num?)?.toInt()
        : (json['verified_count_14_days'] as num?)?.toInt();

    final pendingCount = agg != null
        ? (agg['pending_count'] as num?)?.toInt()
        : null;

    final computedAtStr = agg != null
        ? agg['computed_at']?.toString()
        : json['aggregate_updated_at']?.toString();

    return FeedingSpotModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      code: json['code']?.toString() ?? '',
      qrToken: json['qr_payload']?.toString() ?? json['qr_token']?.toString() ?? '',
      locationName: json['description']?.toString() ??
          json['location_name']?.toString() ??
          'Area Kampus Telkom University',
      latitude: (json['latitude'] != null)
          ? double.tryParse(json['latitude'].toString()) ?? 0.0
          : 0.0,
      longitude: (json['longitude'] != null)
          ? double.tryParse(json['longitude'].toString()) ?? 0.0
          : 0.0,
      status: json['status']?.toString() ?? 'ACTIVE',
      bowlCondition: json['bowl_condition']?.toString() ?? 'unknown',
      lastFedAt: json['last_fed_at'] != null
          ? DateTime.tryParse(json['last_fed_at'].toString())
          : null,
      activitiesCount: (json['activities_count'] as num?)?.toInt() ?? 0,
      verifiedCount14Days: verifiedCount,
      pendingCount14Days: pendingCount,
      isAggregateStale: agg?['is_stale'] == true,
      imageUrl: json['image_url']?.toString(),
      aggregateUpdatedAt:
          computedAtStr != null ? DateTime.tryParse(computedAtStr) : null,
    );
  }

  bool get isActive => status.toLowerCase() == 'active';
  bool get hasLowActivity =>
      verifiedCount14Days != null && verifiedCount14Days! < 7;

  String get activityLabel => verifiedCount14Days == null
      ? 'Data belum tersedia'
      : isAggregateStale
      ? 'Data agregat usang'
      : hasLowActivity
      ? 'Jarang tercatat'
      : 'Rutin tercatat';

  /// Formatted text per AFS-02: e.g. "Terakhir tercatat diberi makan 1 jam lalu"
  String get lastFedSentence => lastFedAt == null
      ? 'Belum ada catatan diberi makan'
      : 'Terakhir tercatat diberi makan ${relativeTime(lastFedAt)}';

  String? get distanceLabel {
    if (distanceMeters == null) return null;
    if (distanceMeters! < 1000) {
      return '${distanceMeters!.round()} m';
    }
    return '${(distanceMeters! / 1000).toStringAsFixed(1)} km';
  }
}
