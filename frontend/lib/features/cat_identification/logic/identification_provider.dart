import 'package:flutter/material.dart';
import '../../cat/data/cat_model.dart';
import '../data/identification_service.dart';
import '../data/question_model.dart';

class IdentificationProvider extends ChangeNotifier {
  final IdentificationService _service = IdentificationService();

  List<QuestionModel> _questions = [];
  CatModel? _matchedCat;
  double _confidence = 0.0;
  String _status = '';
  bool _isLoading = false;
  String? _errorMessage;

  List<QuestionModel> get questions => _questions;
  CatModel? get matchedCat => _matchedCat;
  double get confidence => _confidence;
  String get status => _status;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> fetchQuestions() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _questions = await _service.getQuestions();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<bool> identifyByQr(String qrToken) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final res = await _service.identifyCat(method: 'qr', qrToken: qrToken);
      _matchedCat = res['matched_cat'] as CatModel?;
      _confidence = res['confidence'] as double;
      _status = res['status'] as String;
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

  Future<bool> identifyByQuestions(Map<String, dynamic> answers) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final res = await _service.identifyCat(method: 'questionnaire', answers: answers);
      _matchedCat = res['matched_cat'] as CatModel?;
      _confidence = res['confidence'] as double;
      _status = res['status'] as String;
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
