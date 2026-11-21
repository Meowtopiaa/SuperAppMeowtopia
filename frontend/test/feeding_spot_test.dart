import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:meowtopia/core/scanner/qr_parser.dart';
import 'package:meowtopia/core/widgets/loading_indicator.dart';
import 'package:meowtopia/core/widgets/page_transition_overlay.dart';
import 'package:meowtopia/core/widgets/walking_cat_loader.dart';
import 'package:meowtopia/features/feeding_spot/data/feeding_spot_model.dart';
import 'package:meowtopia/features/feeding_spot/logic/feeding_spot_provider.dart';

void main() {
  group('QR Parser Unit Tests (MEOW-27 & MEOW-28)', () {
    test('parseQr mengenali MTP1.S.<token> sebagai QR Spot', () {
      final res = parseQr('MTP1.S.TOKEN_SPOT_TULT_01_ABC123');
      expect(res.kind, QrKind.spot);
      expect(res.value, 'TOKEN_SPOT_TULT_01_ABC123');
    });

    test('parseQr mengenali MTP1.C.<token> sebagai QR Kucing', () {
      final res = parseQr('MTP1.C.TOKEN_CAT_01_XYZ789');
      expect(res.kind, QrKind.cat);
      expect(res.value, 'TOKEN_CAT_01_XYZ789');
    });

    test('parseQr memetakan teks lain / kode manual sebagai QrKind.unknown', () {
      final manual = parseQr('SPOT-TULT-01');
      expect(manual.kind, QrKind.unknown);
      expect(manual.value, 'SPOT-TULT-01');

      final invalid = parseQr('https://example.com');
      expect(invalid.kind, QrKind.unknown);
    });
  });

  group('Telkom University 38-Location Denah Mapping Tests (MEOW-26)', () {
    test('Memiliki tepat 38 lokasi resmi sesuai denah Telkom University', () {
      expect(TelkomCampusLocation.all.length, 38);
      expect(TelkomCampusLocation.all.first.number, 1);
      expect(
        TelkomCampusLocation.all.first.name,
        'Telkom University Landmark Tower (TULT)',
      );
      expect(TelkomCampusLocation.all.last.number, 38);
      expect(TelkomCampusLocation.all.last.name, 'Jogging Track');
    });

    test('Resolusi lokasi spot sesuai denah berdasarkan kode dan koordinat', () {
      final tult = TelkomCampusLocation.resolve(
        -6.96930,
        107.62815,
        code: 'SPOT-TULT-01',
      );
      expect(tult.number, 1);
      expect(tult.name, 'Telkom University Landmark Tower (TULT)');

      final gku = TelkomCampusLocation.resolve(
        -6.97195,
        107.62955,
        code: 'SPOT-GKU-01',
      );
      expect(gku.number, 7);
      expect(gku.name, 'Gedung Tokong Nanas (Gd. Kuliah Umum-GKU)');

      final msu = TelkomCampusLocation.resolve(-6.97525, 107.63165);
      expect(msu.number, 37);
      expect(msu.name, 'Masjid Syamsul Ulum');
    });

    test('FeedingSpotModel.fromJson memetakan location_name, image_url, status_reason, dan is_stale', () {
      final model = FeedingSpotModel.fromJson({
        'id': '01JAFS00000000000000000101',
        'code': 'SPOT-GKU-01',
        'name': 'Spot Pakan GKU Gazebo',
        'location_number': 7,
        'location_name': 'Gedung Tokong Nanas (Gd. Kuliah Umum-GKU)',
        'latitude': -6.97195,
        'longitude': 107.62955,
        'status': 'TEMPORARILY_UNAVAILABLE',
        'status_reason': 'Pembersihan wadah pakan',
        'image_url': 'http://127.0.0.1:8000/api/v1/feeding/spots/01JAFS00000000000000000101/photo',
        'has_pending_review': true,
        'aggregate': {
          'verified_count': 5,
          'pending_count': 1,
          'is_stale': false,
        },
      });

      expect(model.code, 'SPOT-GKU-01');
      expect(model.locationNumber, 7);
      expect(model.locationName, 'Gedung Tokong Nanas (Gd. Kuliah Umum-GKU)');
      expect(model.statusReason, 'Pembersihan wadah pakan');
      expect(model.imageUrl, isNotNull);
      expect(model.hasPendingReview, isTrue);
      expect(model.isStale, isFalse);
    });
  });

  group('FeedingSpotProvider QR & Manual Code Scenarios (MEOW-27 & MEOW-28)', () {
    test('Menolak QR kucing dengan pesan QR_WRONG_TYPE', () async {
      final provider = FeedingSpotProvider(isDemo: true);
      expect(
        () => provider.openSession('MTP1.C.CAT_TOKEN_123'),
        throwsA(
          predicate((e) => e.toString().contains('QR_WRONG_TYPE')),
        ),
      );
    });

    test('Membuka sesi dengan QR Spot valid maupun kode manual SPOT-TULT-01', () async {
      final provider = FeedingSpotProvider(isDemo: true);
      final session = await provider.openSession('SPOT-TULT-01');
      expect(session.spot.code, 'SPOT-TULT-01');
      expect(
        session.spot.locationName,
        'Telkom University Landmark Tower (TULT)',
      );
    });
  });

  group('WalkingCatLoader 2.5D Animation Tests', () {
    testWidgets('Merender animasi kucing berjalan dan teks Memuat...', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: Center(child: WalkingCatLoader())),
        ),
      );

      expect(find.byType(WalkingCatLoader), findsOneWidget);
      expect(find.text('Memuat'), findsOneWidget);
      expect(find.text('.'), findsNWidgets(3));
      expect(
        find.descendant(
          of: find.byType(WalkingCatLoader),
          matching: find.byType(CustomPaint),
        ),
        findsOneWidget,
      );

      // Pastikan animasi melangkah mulus melewati beberapa frame tanpa error
      await tester.pump(const Duration(milliseconds: 550));
      await tester.pump(const Duration(milliseconds: 1100));
      await tester.pump(const Duration(milliseconds: 2200));

      expect(tester.takeException(), isNull);
    });

    testWidgets('Mendukung mode latar gelap (onDark) dan compact', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            backgroundColor: Colors.black,
            body: Center(
              child: WalkingCatLoader(onDark: true, compact: true, size: 120),
            ),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 800));
      expect(find.text('Memuat'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('LoadingIndicator global merender WalkingCatLoader dan merapikan titik akhir pesan', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LoadingIndicator(message: 'Memuat katalog adopsi...'),
          ),
        ),
      );

      expect(find.byType(WalkingCatLoader), findsOneWidget);
      expect(find.text('Memuat katalog adopsi'), findsOneWidget);
      expect(find.text('.'), findsNWidgets(3));

      await tester.pump(const Duration(milliseconds: 900));
      expect(tester.takeException(), isNull);
    });

    testWidgets('PageTransitionLoaderHost langsung pindah tanpa loading jika halaman cepat, dan tampil tanpa background jika melewati showDelay', (
      tester,
    ) async {
      final transitionNotifier = ValueNotifier<int>(0);
      final router = GoRouter(
        initialLocation: '/a',
        observers: [
          PageTransitionTracker(onTransition: () => transitionNotifier.value++),
        ],
        routes: [
          GoRoute(
            path: '/a',
            builder: (_, __) => const Scaffold(body: Text('Halaman A')),
          ),
          GoRoute(
            path: '/b',
            builder: (_, __) => const Scaffold(body: Text('Halaman B')),
          ),
        ],
      );

      // 1. Skenario cepat (halaman langsung selesai render < showDelay): tidak menampilkan overlay
      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: router,
          builder: (context, child) => PageTransitionLoaderHost(
            router: router,
            transitionListenable: transitionNotifier,
            showDelay: const Duration(milliseconds: 120),
            minVisibleDuration: const Duration(milliseconds: 200),
            fadeOutDuration: const Duration(milliseconds: 120),
            child: child ?? const SizedBox.shrink(),
          ),
        ),
      );
      await tester.pump();
      expect(find.byType(WalkingCatLoader), findsNothing);
      expect(find.text('Halaman A'), findsOneWidget);

      router.go('/b');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      expect(find.byType(WalkingCatLoader), findsNothing);
      expect(find.text('Halaman B'), findsOneWidget);

      // 2. Skenario lag (showDelay = 0 mensimulasikan frame belum selesai saat threshold tercapai)
      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: router,
          builder: (context, child) => PageTransitionLoaderHost(
            router: router,
            transitionListenable: transitionNotifier,
            showDelay: Duration.zero,
            minVisibleDuration: const Duration(milliseconds: 200),
            fadeOutDuration: const Duration(milliseconds: 120),
            showOnInitialLoad: false,
            child: child ?? const SizedBox.shrink(),
          ),
        ),
      );

      router.go('/a');
      await tester.pump(const Duration(milliseconds: 10));
      expect(find.byType(WalkingCatLoader), findsOneWidget);
      expect(find.text('Memuat'), findsOneWidget);

      // Setelah selesai render + minVisibleDuration + fade-out, overlay unmount bersih
      await tester.pump(const Duration(milliseconds: 250));
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.byType(WalkingCatLoader), findsNothing);
      expect(find.text('Halaman A'), findsOneWidget);
      expect(tester.takeException(), isNull);

      router.dispose();
      transitionNotifier.dispose();
    });

    testWidgets('Pindah branch StatefulShellRoute (/home -> /feeding -> /profile) cepat dan bebas error', (
      tester,
    ) async {
      final transitionNotifier = ValueNotifier<int>(0);
      final router = GoRouter(
        initialLocation: '/home',
        observers: [
          PageTransitionTracker(onTransition: () => transitionNotifier.value++),
        ],
        routes: [
          StatefulShellRoute.indexedStack(
            builder: (context, state, shell) => Scaffold(body: shell),
            branches: [
              StatefulShellBranch(
                routes: [
                  GoRoute(
                    path: '/home',
                    builder: (_, __) => const Center(child: Text('Tab Home')),
                  ),
                ],
              ),
              StatefulShellBranch(
                routes: [
                  GoRoute(
                    path: '/feeding',
                    builder: (_, __) =>
                        const Center(child: Text('Tab Feeding')),
                  ),
                ],
              ),
              StatefulShellBranch(
                routes: [
                  GoRoute(
                    path: '/profile',
                    builder: (_, __) =>
                        const Center(child: Text('Tab Profile')),
                  ),
                ],
              ),
            ],
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: router,
          builder: (context, child) => PageTransitionLoaderHost(
            router: router,
            transitionListenable: transitionNotifier,
            showDelay: const Duration(milliseconds: 120),
            minVisibleDuration: const Duration(milliseconds: 200),
            fadeOutDuration: const Duration(milliseconds: 120),
            child: child ?? const SizedBox.shrink(),
          ),
        ),
      );

      await tester.pump();
      expect(find.byType(WalkingCatLoader), findsNothing);
      expect(find.text('Tab Home'), findsOneWidget);

      // Pindah /home -> /feeding langsung tampil tanpa jeda loading buatan
      router.go('/feeding');
      await tester.pump();
      expect(find.byType(WalkingCatLoader), findsNothing);
      expect(find.text('Tab Feeding'), findsOneWidget);

      // Pindah /feeding -> /profile langsung tampil tanpa jeda loading buatan
      router.go('/profile');
      await tester.pump();
      expect(find.byType(WalkingCatLoader), findsNothing);
      expect(find.text('Tab Profile'), findsOneWidget);
      expect(tester.takeException(), isNull);

      router.dispose();
      transitionNotifier.dispose();
    });
  });
}
