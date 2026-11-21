import 'package:go_router/go_router.dart';

import 'ui/auth_page_shell.dart';
import 'ui/login_page.dart';
import 'ui/register_page.dart';
import 'ui/verify_email_page.dart';

final List<RouteBase> authRoutes = [
  GoRoute(
    path: '/login',
    pageBuilder: (context, state) => NoTransitionPage(
      key: state.pageKey,
      child: LoginPage(startsGripped: state.extra == AuthPageArrival.paw),
    ),
  ),
  GoRoute(
    path: '/register',
    pageBuilder: (context, state) => NoTransitionPage(
      key: state.pageKey,
      child: RegisterPage(startsGripped: state.extra == AuthPageArrival.paw),
    ),
  ),
  GoRoute(
      path: '/verify-email',
      builder: (context, state) => const VerifyEmailPage()),
];
