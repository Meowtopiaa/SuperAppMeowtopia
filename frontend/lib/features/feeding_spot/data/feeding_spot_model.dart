class FeedingSpotModel {
  final int id;
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
  final String? imageUrl;
  final String imageAsset;
  final DateTime? aggregateUpdatedAt;

  const FeedingSpotModel({
    required this.id,
    required this.name,
    required this.code,
    required this.qrToken,
    required this.locationName,
    required this.latitude,
    required this.longitude,
    required this.status,
    required this.bowlCondition,
    this.lastFedAt,
    this.activitiesCount = 0,
    this.verifiedCount14Days,
    this.imageUrl,
    this.imageAsset = 'assets/images/figma/feeding-shelter.png',
    this.aggregateUpdatedAt,
  });

  factory FeedingSpotModel.fromJson(Map<String, dynamic> json) {
    return FeedingSpotModel(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      code: json['code'] ?? '',
      qrToken: json['qr_token'] ?? '',
      locationName: json['location_name'] ?? '',
      latitude: (json['latitude'] != null)
          ? double.parse(json['latitude'].toString())
          : 0.0,
      longitude: (json['longitude'] != null)
          ? double.parse(json['longitude'].toString())
          : 0.0,
      status: json['status'] ?? 'active',
      bowlCondition: json['bowl_condition'] ?? 'empty',
      lastFedAt: json['last_fed_at'] != null
          ? DateTime.tryParse(json['last_fed_at'])
          : null,
      activitiesCount: json['activities_count'] ?? 0,
      verifiedCount14Days: (json['verified_count_14_days'] as num?)?.toInt(),
      imageUrl: json['image_url'],
      aggregateUpdatedAt: DateTime.tryParse(
        json['aggregate_updated_at']?.toString() ?? '',
      ),
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
}
