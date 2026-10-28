import 'package:flutter/material.dart';
import '../data/cat_hunter_model.dart';
import '../data/cat_hunter_service.dart';

class CatHunterProvider extends ChangeNotifier {
  final CatHunterService _service = CatHunterService();

  List<UserCatDexModel> _dexList = [];
  List<LeaderboardEntry> _leaderboard = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<UserCatDexModel> get dexList => _dexList;
  List<LeaderboardEntry> get leaderboard => _leaderboard;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> fetchMyDex() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _dexList = await _service.getMyDex();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<void> fetchLeaderboard() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _leaderboard = await _service.getLeaderboard();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<bool> startEncounter({
    required String qrToken,
    required double latitude,
    required double longitude,
    required String condition,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _service.submitEncounter(
        catQrToken: qrToken,
        latitude: latitude,
        longitude: longitude,
        condition: condition,
      );
      await fetchMyDex();
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
