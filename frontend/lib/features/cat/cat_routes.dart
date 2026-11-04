import 'package:go_router/go_router.dart';

import 'ui/cat_detail_page.dart';
import 'ui/cat_qr_page.dart';

final List<RouteBase> catRoutes = [
  GoRoute(
    path: '/cats/:id',
    builder: (context, state) {
      final id = int.tryParse(state.pathParameters['id'] ?? '0') ?? 0;
      return CatDetailPage(catId: id);
    },
  ),
  GoRoute(
    path: '/cats/qr/:token',
    builder: (context, state) {
      final token = state.pathParameters['token'] ?? '';
      return CatQrPage(qrToken: token);
    },
  ),
];
