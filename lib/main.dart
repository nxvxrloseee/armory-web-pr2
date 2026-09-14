import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/api_client.dart';
import 'core/auth_api.dart';
import 'models/category.dart';
import 'models/category_query.dart';
import 'models/client.dart';
import 'models/client_query.dart';
import 'models/designer.dart';
import 'models/designer_query.dart';
import 'models/manufacturer.dart';
import 'models/manufacturer_query.dart';
import 'models/weapon.dart';
import 'models/weapon_query.dart';
import 'repositories/admin_api.dart';
import 'repositories/api_category_repository.dart';
import 'repositories/api_client_repository.dart';
import 'repositories/api_designer_repository.dart';
import 'repositories/api_manufacturer_repository.dart';
import 'repositories/api_weapon_repository.dart';
import 'repositories/category_repository.dart';
import 'repositories/client_repository.dart';
import 'repositories/designer_repository.dart';
import 'repositories/manufacturer_repository.dart';
import 'repositories/order_repository.dart';
import 'repositories/weapon_repository.dart';
import 'router.dart';
import 'state/auth_notifier.dart';
import 'state/list_notifier.dart';
import 'widgets/inactivity_watcher.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  usePathUrlStrategy();

  // ПР5: AuthNotifier нужен раньше GoRouter (redirect читает его состояние)
  // и раньше интерсептора авторизации на Dio — отсюда двухшаговая сборка:
  // сперва "голый" Dio для собственных вызовов AuthNotifier к /auth/*,
  // потом на тот же Dio навешивается интерсептор, который уже видит
  // AuthNotifier и умеет подставлять токен/обновлять его при 401.
  final prefs = await SharedPreferences.getInstance();
  final dio = buildDio();
  final authNotifier = AuthNotifier(prefs, AuthApi(dio));
  await authNotifier.restore();
  attachAuthInterceptor(dio, authNotifier);

  final router = buildRouter(authNotifier);

  runApp(ArmoryApp(dio: dio, authNotifier: authNotifier, router: router));
}

class ArmoryApp extends StatelessWidget {
  const ArmoryApp({super.key, required this.dio, required this.authNotifier, required this.router});

  final Dio dio;
  final AuthNotifier authNotifier;
  final GoRouter router;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthNotifier>.value(value: authNotifier),
        Provider<Dio>.value(value: dio),
        ProxyProvider<Dio, WeaponRepository>(
          update: (_, dio, _) => ApiWeaponRepository(dio),
        ),
        ProxyProvider<Dio, ManufacturerRepository>(
          update: (_, dio, _) => ApiManufacturerRepository(dio),
        ),
        ProxyProvider<Dio, CategoryRepository>(
          update: (_, dio, _) => ApiCategoryRepository(dio),
        ),
        ProxyProvider<Dio, DesignerRepository>(
          update: (_, dio, _) => ApiDesignerRepository(dio),
        ),
        ProxyProvider<Dio, ClientRepository>(
          update: (_, dio, _) => ApiClientRepository(dio),
        ),
        ProxyProvider<Dio, OrderRepository>(
          update: (_, dio, _) => OrderRepository(dio),
        ),
        ProxyProvider<Dio, AdminApi>(
          update: (_, dio, _) => AdminApi(dio),
        ),
        // Один обобщённый нотифаер на все пять сущностей (см.
        // state/list_notifier.dart) вместо пяти одинаковых классов.
        ChangeNotifierProvider(
          create: (context) => ListNotifier<Weapon, WeaponQuery>(
            context.read<WeaponRepository>(),
            const WeaponQuery(),
          ),
        ),
        ChangeNotifierProvider(
          create: (context) => ListNotifier<Manufacturer, ManufacturerQuery>(
            context.read<ManufacturerRepository>(),
            const ManufacturerQuery(),
          ),
        ),
        ChangeNotifierProvider(
          create: (context) => ListNotifier<Category, CategoryQuery>(
            context.read<CategoryRepository>(),
            const CategoryQuery(),
          ),
        ),
        ChangeNotifierProvider(
          create: (context) => ListNotifier<Designer, DesignerQuery>(
            context.read<DesignerRepository>(),
            const DesignerQuery(),
          ),
        ),
        ChangeNotifierProvider(
          create: (context) => ListNotifier<Client, ClientQuery>(
            context.read<ClientRepository>(),
            const ClientQuery(),
          ),
        ),
      ],
      child: Builder(
        builder: (context) {
          final scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();
          return MaterialApp.router(
            title: 'Оружейный магазин',
            debugShowCheckedModeBanner: false,
            theme: ThemeData(colorSchemeSeed: Colors.blueGrey, useMaterial3: true),
            routerConfig: router,
            scaffoldMessengerKey: scaffoldMessengerKey,
            builder: (context, child) => Consumer<AuthNotifier>(
              builder: (context, auth, _) => InactivityWatcher(
                // ПР5, оценка «5»: 3 минуты без действий — выход,
                // предупреждение за 30 секунд до этого.
                timeout: const Duration(minutes: 3),
                warnBefore: const Duration(seconds: 30),
                enabled: auth.isAuthenticated,
                onWarn: () => scaffoldMessengerKey.currentState?.showSnackBar(
                  const SnackBar(
                    content: Text('Сессия завершится через 30 секунд из-за неактивности'),
                    duration: Duration(seconds: 10),
                  ),
                ),
                onTimeout: () => auth.logout(reason: 'Сессия завершена по неактивности.'),
                child: child ?? const SizedBox.shrink(),
              ),
            ),
          );
        },
      ),
    );
  }
}
