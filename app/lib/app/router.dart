import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/auth_screen.dart';
import '../features/bookings/bookings_screen.dart';
import '../features/home/home_screen.dart';
import '../features/purchases/purchases_screen.dart';
import '../features/visits/visits_screen.dart';
import 'providers.dart';
import 'shell.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final session = ref.watch(sessionControllerProvider).valueOrNull;
  final authed = session != null;
  return GoRouter(
    initialLocation: authed ? '/home' : '/auth',
    routes: [
      if (!authed)
        GoRoute(
          path: '/auth',
          builder: (context, state) => const AuthScreen(),
        ),
      if (authed)
        StatefulShellRoute.indexedStack(
          builder: (context, state, navigationShell) {
            return AppShell(navigationShell: navigationShell);
          },
          branches: [
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/home',
                  builder: (context, state) => const HomeScreen(),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/visits',
                  builder: (context, state) => const VisitsScreen(),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/purchases',
                  builder: (context, state) => const PurchasesScreen(),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/bookings',
                  builder: (context, state) => const BookingsScreen(),
                ),
              ],
            ),
          ],
        ),
    ],
  );
});
