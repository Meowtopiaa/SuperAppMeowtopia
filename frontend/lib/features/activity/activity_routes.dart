import 'package:go_router/go_router.dart';

import 'ui/activity_page.dart';

final List<RouteBase> activityRoutes = [
  GoRoute(path: '/activity', builder: (context, state) => const ActivityPage()),
];
