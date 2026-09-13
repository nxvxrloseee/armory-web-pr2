import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:provider/provider.dart';

import 'core/api_client.dart';
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
import 'repositories/api_category_repository.dart';
import 'repositories/api_client_repository.dart';
import 'repositories/api_designer_repository.dart';
import 'repositories/api_manufacturer_repository.dart';
import 'repositories/api_weapon_repository.dart';
import 'repositories/category_repository.dart';
import 'repositories/client_repository.dart';
import 'repositories/designer_repository.dart';
import 'repositories/manufacturer_repository.dart';
import 'repositories/weapon_repository.dart';
import 'router.dart';
import 'state/list_notifier.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  usePathUrlStrategy();
  runApp(const ArmoryApp());
}

class ArmoryApp extends StatelessWidget {
  const ArmoryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Единственное место, где приложение целиком переходит на сервер
        // (задание ПР4, раздел 2.5) — было: пять Persistent*Repository над
        // SharedPreferences, стало: пять Api*Repository над одним Dio.
        Provider<Dio>(create: (_) => buildDio()),
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
      child: MaterialApp.router(
        title: 'Оружейный магазин',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(colorSchemeSeed: Colors.blueGrey, useMaterial3: true),
        routerConfig: appRouter,
      ),
    );
  }
}
