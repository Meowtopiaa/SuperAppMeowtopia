import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/activity/activity_routes.dart';
import '../../features/auth/auth_routes.dart';
import '../../features/cat/cat_routes.dart';
import '../../features/cat_adoption/cat_adoption_routes.dart';
import '../../features/cat_hunter/cat_hunter_routes.dart';
import '../../features/cat_identification/cat_identification_routes.dart';
import '../../features/feeding_spot/feeding_spot_routes.dart';
import '../../features/home/home_routes.dart';
import '../../features/incident_report/incident_report_routes.dart';
import '../../features/profile/profile_routes.dart';
import '../../features/shell/main_navigation_shell.dart';
import '../widgets/page_transition_overlay.dart';

class AppRouter {
  static final ValueNotifier<int> transitionNotifier = ValueNotifier<int>(0);

  static void notifyPageTransition() {
    transitionNotifier.value++;
  }

  static List<NavigatorObserver> _buildObservers() => [
    PageTransitionTracker(onTransition: notifyPageTransition),
  ];

  static GoRouter createRouter({String initialLocation = '/home'}) => GoRouter(
    initialLocation: initialLocation,
    observers: _buildObservers(),
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: FilledButton(
          onPressed: () => context.go('/home'),
          child: const Text('Halaman tidak ditemukan · ke Beranda'),
        ),
      ),
    ),
    routes: [
      ...authRoutes,
      ...catRoutes,
      ...feedingFlowRoutes,
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            MainNavigationShell(navigationShell: navigationShell),
        branches: [
          // The first five branches are the app-wide navigation destinations.
          StatefulShellBranch(routes: homeRoutes, observers: _buildObservers()),
          StatefulShellBranch(
            routes: exploreRoutes,
            observers: _buildObservers(),
          ),
          StatefulShellBranch(
            routes: catIdentificationRoutes,
            observers: _buildObservers(),
          ),
          StatefulShellBranch(
            routes: activityRoutes,
            observers: _buildObservers(),
          ),
          StatefulShellBranch(
            routes: profileRoutes,
            observers: _buildObservers(),
          ),
          StatefulShellBranch(
            routes: feedingSpotRoutes,
            observers: _buildObservers(),
          ),
          StatefulShellBranch(
            routes: catHunterRoutes,
            observers: _buildObservers(),
          ),
          StatefulShellBranch(
            routes: catAdoptionRoutes,
            observers: _buildObservers(),
          ),
          StatefulShellBranch(
            routes: incidentReportRoutes,
            observers: _buildObservers(),
          ),
        ],
      ),
    ],
  );

  static final GoRouter router = createRouter();
}
