import 'package:go_router/go_router.dart';
import 'package:saferoute/models/route_model.dart';
import 'package:saferoute/screens/home_screen.dart';
import 'package:saferoute/screens/map_screen.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: AppRoutes.home,
    routes: [
      GoRoute(
        path: AppRoutes.home,
        name: 'home',
        pageBuilder: (context, state) => const NoTransitionPage(child: HomeScreen()),
      ),
      GoRoute(
        path: AppRoutes.map,
        name: 'map',
        pageBuilder: (context, state) {
          final extra = state.extra;
          final mode = extra is TravelMode ? extra : TravelMode.run;
          return NoTransitionPage(child: MapScreen(mode: mode));
        },
      ),
    ],
  );
}

class AppRoutes {
  static const String home = '/';
  static const String map = '/map';
}
