import '../../../core/network/api_client.dart';
import '../../cat/data/cat_model.dart';
import 'question_model.dart';

class IdentificationService {
  final ApiClient _client = ApiClient();

  Future<List<QuestionModel>> getQuestions() async {
    final response = await _client.get('/identification/questions');
    final list = response.data['data'] as List;
    return list.map((e) => QuestionModel.fromJson(e)).toList();
  }

  Future<Map<String, dynamic>> identifyCat({
    required String method,
    String? qrToken,
    String? photo,
    Map<String, dynamic>? answers,
  }) async {
    final response = await _client.post('/identification/identify', data: {
      'method': method,
      'qr_token': qrToken,
      'photo': photo,
      'answers': answers,
    });
    final data = response.data['data'];
    return {
      'confidence': (data['confidence'] as num?)?.toDouble() ?? 0.0,
      'status': data['status'] ?? 'inconclusive',
      'matched_cat': data['matched_cat'] != null ? CatModel.fromJson(data['matched_cat']) : null,
    };
  }
}
