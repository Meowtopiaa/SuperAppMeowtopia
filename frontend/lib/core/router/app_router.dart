import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/auth_routes.dart';
import '../../features/cat/cat_routes.dart';
import '../../features/cat_adoption/cat_adoption_routes.dart';
import '../../features/cat_hunter/cat_hunter_routes.dart';
import '../../features/cat_identification/cat_identification_routes.dart';
import '../../features/feeding_spot/feeding_spot_routes.dart';
import '../../features/incident_report/incident_report_routes.dart';
import '../../features/shell/main_navigation_shell.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();

class AppRouter {
  static final GoRouter router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/login',
    routes: [
      // Top-level Auth Routes (Full-screen, outside shell)
      ...authRoutes,

      // Top-level Cat Details & QR routes (Full-screen)
      ...catRoutes,

      // Stateful Bottom Navigation Shell connecting the 5 features
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MainNavigationShell(navigationShell: navigationShell);
        },
        branches: [
          // Tab 1: Feeding Spot (Acumalaka)
          StatefulShellBranch(routes: feedingSpotRoutes),

          // Tab 2: Cat Hunter / Telcat (SUPER-SUB)
          StatefulShellBranch(routes: catHunterRoutes),

          // Tab 3: Cat Identification (Rekans Caps)
          StatefulShellBranch(routes: catIdentificationRoutes),

          // Tab 4: Cat Adoption (E-Nigma)
          StatefulShellBranch(routes: catAdoptionRoutes),

          // Tab 5: Incident Report (Optimind)
          StatefulShellBranch(routes: incidentReportRoutes),
        ],
      ),
    ],
  );
}
