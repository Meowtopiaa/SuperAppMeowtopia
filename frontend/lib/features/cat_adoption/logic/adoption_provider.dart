import 'package:flutter/material.dart';

import '../../cat/data/cat_model.dart';
import '../data/adoption_model.dart';
import '../data/adoption_service.dart';

class AdoptionProvider extends ChangeNotifier {
  final AdoptionService _service = AdoptionService();

  List<CatModel> _readyCats = [];
  List<AdoptionApplicationModel> _myCats = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<CatModel> get readyCats => _readyCats;
  List<AdoptionApplicationModel> get myCats => _myCats;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> fetchReadyCats() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _readyCats = await _service.getReadyCats();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<void> fetchMyCats() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _myCats = await _service.getMyCats();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<bool> submitApplication({
    required int catId,
    required String housingType,
    required bool financialReadiness,
    required bool familyPermission,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _service.submitApplication(
        catId: catId,
        housingType: housingType,
        financialReadiness: financialReadiness,
        familyPermission: familyPermission,
      );
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
