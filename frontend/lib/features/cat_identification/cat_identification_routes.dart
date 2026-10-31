import 'package:go_router/go_router.dart';

import 'ui/photo_identify_page.dart';
import 'ui/question_page.dart';
import 'ui/result_page.dart';
import 'ui/scan_qr_page.dart';

final List<RouteBase> catIdentificationRoutes = [
  GoRoute(
    path: '/identify',
    builder: (context, state) => const ScanQrPage(),
    routes: [
      GoRoute(
        path: 'photo',
        builder: (context, state) => const PhotoIdentifyPage(),
      ),
      GoRoute(
        path: 'question',
        builder: (context, state) => const QuestionPage(),
      ),
      GoRoute(path: 'result', builder: (context, state) => const ResultPage()),
    ],
  ),
];
