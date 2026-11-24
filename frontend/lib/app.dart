import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'core/constants/app_constants.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/widgets/page_transition_overlay.dart';

class MeowtopiaApp extends StatelessWidget {
  const MeowtopiaApp({super.key, this.router});

  final GoRouter? router;

  @override
  Widget build(BuildContext context) {
    final activeRouter = router ?? AppRouter.router;
    return MaterialApp.router(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: activeRouter,
      builder: (context, child) => PageTransitionLoaderHost(
        router: activeRouter,
        transitionListenable: AppRouter.transitionNotifier,
        child: child ?? const SizedBox.shrink(),
      ),
    );
  }
}
