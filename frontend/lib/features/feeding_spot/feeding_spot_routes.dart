import 'package:go_router/go_router.dart';

import 'ui/capture_evidence_page.dart';
import 'ui/feeding_history_page.dart';
import 'ui/feeding_spot_detail_page.dart';
import 'ui/feeding_spot_list_page.dart';
import 'ui/feeding_submission_page.dart';
import 'ui/record_feeding_page.dart';
import 'ui/scan_spot_page.dart';

final List<RouteBase> feedingSpotRoutes = [
  GoRoute(
    path: '/feeding',
    builder: (context, state) => const FeedingSpotListPage(),
  ),
];

final List<RouteBase> feedingFlowRoutes = [
  GoRoute(
    path: '/feeding/history',
    builder: (context, state) => const FeedingHistoryPage(),
  ),
  GoRoute(
    path: '/feeding/spot/:id',
    builder: (context, state) => FeedingSpotDetailPage(
      spotId: state.pathParameters['id'] ?? '',
    ),
  ),
  GoRoute(
    path: '/feeding/spots/:id',
    builder: (context, state) => FeedingSpotDetailPage(
      spotId: state.pathParameters['id'] ?? '',
    ),
  ),
  GoRoute(
    path: '/feeding/scan',
    builder: (context, state) => ScanSpotPage(
      expectedSpotId: state.uri.queryParameters['spot_id'],
    ),
  ),
  GoRoute(
    path: '/feeding/camera',
    builder: (context, state) => const CaptureEvidencePage(),
  ),
  GoRoute(
    path: '/feeding/record',
    builder: (context, state) => const RecordFeedingPage(),
  ),
  GoRoute(
    path: '/feeding/submission/:id',
    builder: (context, state) =>
        FeedingSubmissionPage(submissionId: state.pathParameters['id']!),
  ),
];
