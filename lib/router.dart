import 'package:go_router/go_router.dart';

import 'models/category_query.dart';
import 'models/client_query.dart';
import 'models/designer_query.dart';
import 'models/manufacturer_query.dart';
import 'models/role.dart';
import 'models/weapon_query.dart';
import 'screens/admin/admin_screen.dart';
import 'screens/auth/forbidden_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
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
import 'screens/orders/orders_screen.dart';
import 'screens/weapons/weapon_detail_screen.dart';
import 'screens/weapons/weapon_form_screen.dart';
import 'screens/weapons/weapon_list_screen.dart';
import 'state/auth_notifier.dart';

const _publicPaths = {'/login', '/register'};

/// Строится один раз в main.dart, после того как [AuthNotifier] уже
/// существует — redirect читает его состояние на каждом переходе, а
/// refreshListenable пересчитывает redirect при login()/logout()/restore()
/// без ручного вызова router.refresh() (задание ПР5, раздел 2.2).
GoRouter buildRouter(AuthNotifier auth) {
  return GoRouter(
    refreshListenable: auth,
    initialLocation: '/',
    redirect: (context, state) {
      // Пока восстанавливаем сессию (проверяем токен на сервере), решение
      // принимать рано — иначе есть окно, где ещё не знаем, залогинен ли
      // пользователь, и redirect успевает отправить его на /login зря.
      if (auth.isRestoring) return null;

      final loggedIn = auth.isAuthenticated;
      final target = state.matchedLocation;
      final isPublic = _publicPaths.contains(target);

      if (!loggedIn && !isPublic) {
        return '/login?from=${Uri.encodeComponent(state.uri.toString())}';
      }
      if (loggedIn && isPublic) return '/';
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => LoginScreen(from: state.uri.queryParameters['from']),
      ),
      GoRoute(path: '/register', builder: (context, state) => const RegisterScreen()),
      GoRoute(path: '/forbidden', builder: (context, state) => const ForbiddenScreen()),

      GoRoute(path: '/', builder: (context, state) => const HomeScreen()),
      GoRoute(path: '/orders', builder: (context, state) => const OrdersScreen()),
      GoRoute(
        path: '/admin',
        builder: (context, state) => const AdminScreen(),
        redirect: (context, state) => auth.has(Role.admin) ? null : '/forbidden',
      ),
      GoRoute(
        path: '/weapons',
        builder: (context, state) => WeaponListScreen(
          query: WeaponQuery.fromQueryParameters(state.uri.queryParameters),
        ),
        routes: [
          // Статический путь 'new' объявлен раньше ':id' — иначе роутер может
          // попытаться разобрать «new» как идентификатор.
          GoRoute(
            path: 'new',
            builder: (context, state) => const WeaponFormScreen(),
            redirect: (context, state) => auth.has(Role.seller) ? null : '/forbidden',
          ),
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
                redirect: (context, state) => auth.has(Role.seller) ? null : '/forbidden',
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
          GoRoute(
            path: 'new',
            builder: (context, state) => const ManufacturerFormScreen(),
            redirect: (context, state) => auth.has(Role.seller) ? null : '/forbidden',
          ),
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
                redirect: (context, state) => auth.has(Role.seller) ? null : '/forbidden',
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
          GoRoute(
            path: 'new',
            builder: (context, state) => const CategoryFormScreen(),
            redirect: (context, state) => auth.has(Role.seller) ? null : '/forbidden',
          ),
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
                redirect: (context, state) => auth.has(Role.seller) ? null : '/forbidden',
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
          GoRoute(
            path: 'new',
            builder: (context, state) => const DesignerFormScreen(),
            redirect: (context, state) => auth.has(Role.seller) ? null : '/forbidden',
          ),
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
                redirect: (context, state) => auth.has(Role.seller) ? null : '/forbidden',
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
        redirect: (context, state) => auth.has(Role.seller) ? null : '/forbidden',
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
}
