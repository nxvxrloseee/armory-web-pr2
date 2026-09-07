import 'package:go_router/go_router.dart';

import 'models/manufacturer_query.dart';
import 'models/weapon_query.dart';
import 'screens/home_screen.dart';
import 'screens/manufacturers/manufacturer_detail_screen.dart';
import 'screens/manufacturers/manufacturer_list_screen.dart';
import 'screens/not_found_screen.dart';
import 'screens/weapons/weapon_detail_screen.dart';
import 'screens/weapons/weapon_list_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (context, state) => const HomeScreen()),
    GoRoute(
      path: '/weapons',
      builder: (context, state) => WeaponListScreen(
        query: WeaponQuery.fromQueryParameters(state.uri.queryParameters),
      ),
      routes: [
        GoRoute(
          path: ':id',
          builder: (context, state) => WeaponDetailScreen(
            id: int.parse(state.pathParameters['id']!),
          ),
        ),
      ],
    ),
    GoRoute(
      path: '/manufacturers',
      builder: (context, state) => ManufacturerListScreen(
        query: ManufacturerQuery.fromQueryParameters(state.uri.queryParameters),
      ),
      routes: [
        GoRoute(
          path: ':id',
          builder: (context, state) => ManufacturerDetailScreen(
            id: int.parse(state.pathParameters['id']!),
          ),
        ),
      ],
    ),
  ],
  // Аналог страницы 404: сюда попадают все неизвестные адреса.
  errorBuilder: (context, state) => NotFoundScreen(location: state.uri.toString()),
);
