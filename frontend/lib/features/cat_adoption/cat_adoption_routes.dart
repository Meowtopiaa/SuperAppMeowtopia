import 'package:go_router/go_router.dart';
import 'ui/adoption_catalog_page.dart';
import 'ui/adoption_form_page.dart';
import 'ui/my_cats_page.dart';

final List<RouteBase> catAdoptionRoutes = [
  GoRoute(
    path: '/adoption',
    builder: (context, state) => const AdoptionCatalogPage(),
    routes: [
      GoRoute(
        path: 'apply',
        builder: (context, state) {
          final catId = int.tryParse(state.uri.queryParameters['cat_id'] ?? '0') ?? 0;
          final catName = state.uri.queryParameters['name'] ?? 'Kucing Kampus';
          return AdoptionFormPage(catId: catId, catName: catName);
        },
      ),
      GoRoute(
        path: 'my-cats',
        builder: (context, state) => const MyCatsPage(),
      ),
    ],
  ),
];
