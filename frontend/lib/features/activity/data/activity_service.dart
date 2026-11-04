import '../../../core/network/api_client.dart';
import 'activity_entry.dart';

class ActivityService {
  final ApiClient _client = ApiClient();

  // This endpoint must return the authenticated user's events only.
  Future<List<ActivityEntry>> getMyActivities() async {
    final response = await _client.get('/activities/mine');
    final data = response.data['data'] as List;
    return data
        .map(
          (item) =>
              ActivityEntry.fromJson(Map<String, dynamic>.from(item as Map)),
        )
        .toList();
  }
}
