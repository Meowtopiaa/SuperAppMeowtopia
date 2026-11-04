import 'package:go_router/go_router.dart';

import 'ui/login_page.dart';
import 'ui/register_page.dart';

final List<RouteBase> authRoutes = [
  GoRoute(path: '/login', builder: (context, state) => const LoginPage()),
  GoRoute(path: '/register', builder: (context, state) => const RegisterPage()),
];
