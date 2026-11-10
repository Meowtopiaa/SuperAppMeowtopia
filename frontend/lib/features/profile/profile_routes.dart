import 'package:go_router/go_router.dart';

import 'ui/profile_page.dart';

final List<RouteBase> profileRoutes = [
  GoRoute(path: '/profile', builder: (context, state) => const ProfilePage()),
];
