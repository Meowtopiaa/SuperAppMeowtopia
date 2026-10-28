import '../../../core/network/api_client.dart';
import 'incident_model.dart';

class IncidentService {
  final ApiClient _client = ApiClient();

  Future<List<IncidentReportModel>> getIncidents() async {
    final response = await _client.get('/incidents');
    final list = response.data['data'] as List;
    return list.map((e) => IncidentReportModel.fromJson(e)).toList();
  }

  Future<void> reportIncident({
    required String title,
    required String incidentType,
    required String urgencyLevel,
    required String description,
    required double latitude,
    required double longitude,
    String? locationNote,
    String? photoUrl,
    int? catId,
  }) async {
    await _client.post('/incidents', data: {
      'title': title,
      'incident_type': incidentType,
      'urgency_level': urgencyLevel,
      'description': description,
      'latitude': latitude,
      'longitude': longitude,
      'location_note': locationNote,
      'photo_url': photoUrl,
      'cat_id': catId,
    });
  }
}
