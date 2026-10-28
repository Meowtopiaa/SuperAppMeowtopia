import 'package:go_router/go_router.dart';
import 'ui/cat_dex_page.dart';
import 'ui/cat_encounter_page.dart';
import 'ui/leaderboard_page.dart';

final List<RouteBase> catHunterRoutes = [
  GoRoute(
    path: '/hunter',
    builder: (context, state) => const CatDexPage(),
    routes: [
      GoRoute(
        path: 'encounter',
        builder: (context, state) => const CatEncounterPage(),
      ),
      GoRoute(
        path: 'leaderboard',
        builder: (context, state) => const LeaderboardPage(),
      ),
    ],
  ),
];
