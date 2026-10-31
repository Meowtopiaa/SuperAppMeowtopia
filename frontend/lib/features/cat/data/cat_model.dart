class CatModel {
  final int id;
  final String name;
  final String qrCodeToken;
  final String gender;
  final String breed;
  final String? primaryColor;
  final String? pattern;
  final bool sterilizationStatus;
  final String healthStatus;
  final String adoptionStatus;
  final String? description;
  final String? primaryPhotoUrl;
  final double? lastSeenLat;
  final double? lastSeenLng;
  final String? lastSeenLocationName;

  CatModel({
    required this.id,
    required this.name,
    required this.qrCodeToken,
    required this.gender,
    required this.breed,
    this.primaryColor,
    this.pattern,
    this.sterilizationStatus = false,
    this.healthStatus = 'healthy',
    this.adoptionStatus = 'available',
    this.description,
    this.primaryPhotoUrl,
    this.lastSeenLat,
    this.lastSeenLng,
    this.lastSeenLocationName,
  });

  factory CatModel.fromJson(Map<String, dynamic> json) {
    return CatModel(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      qrCodeToken: json['qr_code_token'] ?? '',
      gender: json['gender'] ?? 'male',
      breed: json['breed'] ?? 'Domestik',
      primaryColor: json['primary_color'],
      pattern: json['pattern'],
      sterilizationStatus: json['sterilization_status'] ?? false,
      healthStatus: json['health_status'] ?? 'healthy',
      adoptionStatus: json['adoption_status'] ?? 'available',
      description: json['description'],
      primaryPhotoUrl: json['primary_photo_url'],
      lastSeenLat: json['last_seen_lat'] != null
          ? double.tryParse(json['last_seen_lat'].toString())
          : null,
      lastSeenLng: json['last_seen_lng'] != null
          ? double.tryParse(json['last_seen_lng'].toString())
          : null,
      lastSeenLocationName: json['last_seen_location_name'],
    );
  }
}
