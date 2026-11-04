import 'package:go_router/go_router.dart';

import 'ui/explore_page.dart';
import 'ui/home_page.dart';

final List<RouteBase> homeRoutes = [
  GoRoute(path: '/home', builder: (context, state) => const HomePage()),
];

final List<RouteBase> exploreRoutes = [
  GoRoute(path: '/explore', builder: (context, state) => const ExplorePage()),
];
