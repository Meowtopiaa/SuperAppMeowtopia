import 'package:flutter/material.dart';

import '../data/incident_model.dart';
import '../data/incident_service.dart';

class IncidentProvider extends ChangeNotifier {
  final IncidentService _service = IncidentService();

  List<IncidentReportModel> _incidents = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<IncidentReportModel> get incidents => _incidents;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> fetchIncidents() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _incidents = await _service.getIncidents();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<bool> submitIncident({
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
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _service.reportIncident(
        title: title,
        incidentType: incidentType,
        urgencyLevel: urgencyLevel,
        description: description,
        latitude: latitude,
        longitude: longitude,
        locationNote: locationNote,
        photoUrl: photoUrl,
        catId: catId,
      );
      await fetchIncidents();
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }
}
