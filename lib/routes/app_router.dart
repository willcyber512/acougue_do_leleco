import 'package:go_router/go_router.dart';

import '../screens/shell/desktop_shell_screen.dart';

class AppRouter {
  AppRouter._();

  static final GoRouter router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const DesktopShellScreen(),
      ),
    ],
  );
}
