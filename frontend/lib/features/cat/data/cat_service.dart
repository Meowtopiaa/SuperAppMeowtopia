import '../../../core/network/api_client.dart';
import 'cat_model.dart';

class CatService {
  final ApiClient _client = ApiClient();

  Future<List<CatModel>> getCats({String? adoptionStatus, String? search}) async {
    final response = await _client.get('/cats', queryParameters: {
      if (adoptionStatus != null) 'adoption_status': adoptionStatus,
      if (search != null) 'search': search,
    });

    final list = response.data['data'] as List;
    return list.map((e) => CatModel.fromJson(e)).toList();
  }

  Future<CatModel> getCatDetail(int id) async {
    final response = await _client.get('/cats/$id');
    return CatModel.fromJson(response.data['data']);
  }

  Future<CatModel> findByQr(String token) async {
    final response = await _client.get('/cats/qr/$token');
    return CatModel.fromJson(response.data['data']);
  }
}
