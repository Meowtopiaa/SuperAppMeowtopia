import '../../../core/network/api_client.dart';
import '../../cat/data/cat_model.dart';
import 'adoption_model.dart';

class AdoptionService {
  final ApiClient _client = ApiClient();

  Future<List<CatModel>> getReadyCats() async {
    final response = await _client.get('/adoption/catalog');
    final list = response.data['data'] as List;
    return list.map((e) => CatModel.fromJson(e)).toList();
  }

  Future<List<AdoptionApplicationModel>> getMyCats() async {
    final response = await _client.get('/adoption/my-cats');
    final list = response.data['data'] as List;
    return list.map((e) => AdoptionApplicationModel.fromJson(e)).toList();
  }

  Future<void> submitApplication({
    required int catId,
    required String housingType,
    required bool financialReadiness,
    required bool familyPermission,
    Map<String, dynamic>? commitmentAnswers,
  }) async {
    await _client.post(
      '/adoption/apply',
      data: {
        'cat_id': catId,
        'housing_type': housingType,
        'financial_readiness': financialReadiness,
        'family_permission': familyPermission,
        'commitment_answers': commitmentAnswers,
      },
    );
  }
}
