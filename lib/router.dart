import 'package:go_router/go_router.dart';

import 'models/category_query.dart';
import 'models/client_query.dart';
import 'models/designer_query.dart';
import 'models/manufacturer_query.dart';
import 'models/weapon_query.dart';
import 'screens/categories/category_detail_screen.dart';
import 'screens/categories/category_form_screen.dart';
import 'screens/categories/category_list_screen.dart';
import 'screens/clients/client_detail_screen.dart';
import 'screens/clients/client_form_screen.dart';
import 'screens/clients/client_list_screen.dart';
import 'screens/designers/designer_detail_screen.dart';
import 'screens/designers/designer_form_screen.dart';
import 'screens/designers/designer_list_screen.dart';
import 'screens/home_screen.dart';
import 'screens/manufacturers/manufacturer_detail_screen.dart';
import 'screens/manufacturers/manufacturer_form_screen.dart';
import 'screens/manufacturers/manufacturer_list_screen.dart';
import 'screens/not_found_screen.dart';
import 'screens/weapons/weapon_detail_screen.dart';
import 'screens/weapons/weapon_form_screen.dart';
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
        // Статический путь 'new' объявлен раньше ':id' — иначе роутер может
        // попытаться разобрать «new» как идентификатор.
        GoRoute(path: 'new', builder: (context, state) => const WeaponFormScreen()),
        GoRoute(
          path: ':id',
          builder: (context, state) => WeaponDetailScreen(
            id: int.parse(state.pathParameters['id']!),
          ),
          routes: [
            GoRoute(
              path: 'edit',
              builder: (context, state) =>
                  WeaponFormScreen(id: int.parse(state.pathParameters['id']!)),
            ),
          ],
        ),
      ],
    ),
    GoRoute(
      path: '/manufacturers',
      builder: (context, state) => ManufacturerListScreen(
        query: ManufacturerQuery.fromQueryParameters(state.uri.queryParameters),
      ),
      routes: [
        GoRoute(path: 'new', builder: (context, state) => const ManufacturerFormScreen()),
        GoRoute(
          path: ':id',
          builder: (context, state) => ManufacturerDetailScreen(
            id: int.parse(state.pathParameters['id']!),
          ),
          routes: [
            GoRoute(
              path: 'edit',
              builder: (context, state) =>
                  ManufacturerFormScreen(id: int.parse(state.pathParameters['id']!)),
            ),
          ],
        ),
      ],
    ),
    GoRoute(
      path: '/categories',
      builder: (context, state) => CategoryListScreen(
        query: CategoryQuery.fromQueryParameters(state.uri.queryParameters),
      ),
      routes: [
        GoRoute(path: 'new', builder: (context, state) => const CategoryFormScreen()),
        GoRoute(
          path: ':id',
          builder: (context, state) => CategoryDetailScreen(
            id: int.parse(state.pathParameters['id']!),
          ),
          routes: [
            GoRoute(
              path: 'edit',
              builder: (context, state) =>
                  CategoryFormScreen(id: int.parse(state.pathParameters['id']!)),
            ),
          ],
        ),
      ],
    ),
    GoRoute(
      path: '/designers',
      builder: (context, state) => DesignerListScreen(
        query: DesignerQuery.fromQueryParameters(state.uri.queryParameters),
      ),
      routes: [
        GoRoute(path: 'new', builder: (context, state) => const DesignerFormScreen()),
        GoRoute(
          path: ':id',
          builder: (context, state) => DesignerDetailScreen(
            id: int.parse(state.pathParameters['id']!),
          ),
          routes: [
            GoRoute(
              path: 'edit',
              builder: (context, state) =>
                  DesignerFormScreen(id: int.parse(state.pathParameters['id']!)),
            ),
          ],
        ),
      ],
    ),
    GoRoute(
      path: '/clients',
      builder: (context, state) => ClientListScreen(
        query: ClientQuery.fromQueryParameters(state.uri.queryParameters),
      ),
      routes: [
        GoRoute(path: 'new', builder: (context, state) => const ClientFormScreen()),
        GoRoute(
          path: ':id',
          builder: (context, state) => ClientDetailScreen(
            id: int.parse(state.pathParameters['id']!),
          ),
          routes: [
            GoRoute(
              path: 'edit',
              builder: (context, state) =>
                  ClientFormScreen(id: int.parse(state.pathParameters['id']!)),
            ),
          ],
        ),
      ],
    ),
  ],
  // Аналог страницы 404: сюда попадают все неизвестные адреса.
  errorBuilder: (context, state) => NotFoundScreen(location: state.uri.toString()),
);
