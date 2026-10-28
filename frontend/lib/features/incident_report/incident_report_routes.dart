import 'package:go_router/go_router.dart';
import 'ui/incident_list_page.dart';
import 'ui/create_incident_page.dart';

final List<RouteBase> incidentReportRoutes = [
  GoRoute(
    path: '/incidents',
    builder: (context, state) => const IncidentListPage(),
    routes: [
      GoRoute(
        path: 'create',
        builder: (context, state) => const CreateIncidentPage(),
      ),
    ],
  ),
];
