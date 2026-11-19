import 'package:go_router/go_router.dart';

import 'ui/adoption_catalog_page.dart';
import 'ui/adoption_detail_page.dart';
import 'ui/adoption_followup_page.dart';
import 'ui/adoption_form_page.dart';
import 'ui/adoption_issue_report_page.dart';
import 'ui/adoption_pickup_page.dart';
import 'ui/adoption_return_page.dart';
import 'ui/my_cats_page.dart';

/// Daftar route untuk modul Cat Adoption (E-Nigma)
final List<RouteBase> catAdoptionRoutes = [
  GoRoute(
    path: '/adoption',
    builder: (context, state) => const AdoptionCatalogPage(),
    routes: [
      // Form Kelayakan Adopter (ADP-01..03)
      GoRoute(
        path: 'apply',
        builder: (context, state) {
          final catId =
              int.tryParse(state.uri.queryParameters['cat_id'] ?? '');
          final catName = state.uri.queryParameters['name'];
          final appId =
              int.tryParse(state.uri.queryParameters['app_id'] ?? '');
          return AdoptionFormPage(
            catId: catId,
            catName: catName,
            existingApplicationId: appId,
          );
        },
      ),

      // Detail Status Pengajuan (ADP-03..04)
      GoRoute(
        path: 'detail/:id',
        builder: (context, state) {
          final id = int.tryParse(state.pathParameters['id'] ?? '0') ?? 0;
          return AdoptionDetailPage(applicationId: id);
        },
      ),

      // Pengambilan Kucing (ADP-06..07)
      GoRoute(
        path: 'pickup',
        builder: (context, state) {
          final appId =
              int.tryParse(state.uri.queryParameters['app_id'] ?? '0') ?? 0;
          final catId =
              int.tryParse(state.uri.queryParameters['cat_id'] ?? '0') ?? 0;
          return AdoptionPickupPage(
            applicationId: appId,
            catId: catId,
          );
        },
      ),

      // Kucing Saya - Adopsi Aktif (ADP-08)
      GoRoute(
        path: 'my-cats',
        builder: (context, state) => const MyCatsPage(),
      ),

      // Follow-up 2-Mingguan (ADP-09..10)
      GoRoute(
        path: 'followup',
        builder: (context, state) {
          final adoptionId =
              int.tryParse(state.uri.queryParameters['adoption_id'] ?? '0') ?? 0;
          final cycle =
              int.tryParse(state.uri.queryParameters['cycle'] ?? '1') ?? 1;
          final catName =
              state.uri.queryParameters['cat_name'] ?? 'Kucing Saya';
          return AdoptionFollowupPage(
            adoptionId: adoptionId,
            cycleNumber: cycle,
            catName: catName,
          );
        },
      ),

      // Pengembalian Kucing (ADP-11..12 & OQ-08)
      GoRoute(
        path: 'return',
        builder: (context, state) {
          final adoptionId =
              int.tryParse(state.uri.queryParameters['adoption_id'] ?? '0') ?? 0;
          final catName =
              state.uri.queryParameters['name'] ?? 'Kucing Saya';
          return AdoptionReturnPage(
            adoptionId: adoptionId,
            catName: catName,
          );
        },
      ),

      // Laporan Kendala (ADP-13)
      GoRoute(
        path: 'issue',
        builder: (context, state) {
          final adoptionId =
              int.tryParse(state.uri.queryParameters['adoption_id'] ?? '0') ?? 0;
          final catId =
              int.tryParse(state.uri.queryParameters['cat_id'] ?? '0') ?? 0;
          final catName =
              state.uri.queryParameters['name'] ?? 'Kucing Saya';
          return AdoptionIssueReportPage(
            adoptionId: adoptionId,
            catId: catId,
            catName: catName,
          );
        },
      ),
    ],
  ),
];
