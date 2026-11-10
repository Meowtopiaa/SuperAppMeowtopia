class IncidentReportModel {
  final int id;
  final String title;
  final String incidentType;
  final String urgencyLevel;
  final String description;
  final String? photoUrl;
  final double latitude;
  final double longitude;
  final String? locationNote;
  final String status;
  final DateTime createdAt;

  IncidentReportModel({
    required this.id,
    required this.title,
    required this.incidentType,
    required this.urgencyLevel,
    required this.description,
    this.photoUrl,
    required this.latitude,
    required this.longitude,
    this.locationNote,
    required this.status,
    required this.createdAt,
  });

  factory IncidentReportModel.fromJson(Map<String, dynamic> json) {
    return IncidentReportModel(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      incidentType: json['incident_type'] ?? 'other',
      urgencyLevel: json['urgency_level'] ?? 'medium',
      description: json['description'] ?? '',
      photoUrl: json['photo_url'],
      latitude: json['latitude'] != null
          ? double.parse(json['latitude'].toString())
          : 0.0,
      longitude: json['longitude'] != null
          ? double.parse(json['longitude'].toString())
          : 0.0,
      locationNote: json['location_note'],
      status: json['status'] ?? 'reported',
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
    );
  }
}
