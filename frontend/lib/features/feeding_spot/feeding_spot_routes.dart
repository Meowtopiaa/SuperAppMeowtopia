import 'package:go_router/go_router.dart';
import 'ui/feeding_spot_list_page.dart';
import 'ui/record_feeding_page.dart';

final List<RouteBase> feedingSpotRoutes = [
  GoRoute(
    path: '/feeding',
    builder: (context, state) => const FeedingSpotListPage(),
    routes: [
      GoRoute(
        path: 'record',
        builder: (context, state) {
          final spotId = int.tryParse(state.uri.queryParameters['spot_id'] ?? '');
          final token = state.uri.queryParameters['token'];
          return RecordFeedingPage(spotId: spotId, initialToken: token);
        },
      ),
    ],
  ),
];
