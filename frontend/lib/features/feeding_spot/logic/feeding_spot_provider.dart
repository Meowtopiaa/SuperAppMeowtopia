import 'package:flutter/material.dart';
import '../data/feeding_spot_model.dart';
import '../data/feeding_spot_service.dart';

class FeedingSpotProvider extends ChangeNotifier {
  final FeedingSpotService _service = FeedingSpotService();

  List<FeedingSpotModel> _spots = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<FeedingSpotModel> get spots => _spots;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> fetchSpots() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _spots = await _service.getSpots();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<bool> submitFeeding({
    required int spotId,
    required String qrToken,
    required String foodType,
    String? photoProofUrl,
    String? notes,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _service.recordFeeding(
        spotId: spotId,
        qrToken: qrToken,
        foodType: foodType,
        photoProofUrl: photoProofUrl,
        notes: notes,
      );
      await fetchSpots();
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
