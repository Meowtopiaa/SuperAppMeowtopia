import 'package:flutter/material.dart';

import '../data/cat_model.dart';
import '../data/cat_service.dart';

class CatProvider extends ChangeNotifier {
  final CatService _catService = CatService();

  List<CatModel> _cats = [];
  CatModel? _selectedCat;
  bool _isLoading = false;
  String? _errorMessage;

  List<CatModel> get cats => _cats;
  CatModel? get selectedCat => _selectedCat;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> fetchCats() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _cats = await _catService.getCats();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<void> fetchCatDetail(int id) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _selectedCat = await _catService.getCatDetail(id);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
    }
  }
}
