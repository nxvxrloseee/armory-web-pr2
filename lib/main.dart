import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:provider/provider.dart';

import 'repositories/in_memory_manufacturer_repository.dart';
import 'repositories/in_memory_weapon_repository.dart';
import 'repositories/manufacturer_repository.dart';
import 'repositories/weapon_repository.dart';
import 'router.dart';
import 'state/manufacturer_list_notifier.dart';
import 'state/weapon_list_notifier.dart';

void main() {
  usePathUrlStrategy();
  runApp(const ArmoryApp());
}

class ArmoryApp extends StatelessWidget {
  const ArmoryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<WeaponRepository>(create: (_) => InMemoryWeaponRepository()),
        Provider<ManufacturerRepository>(create: (_) => InMemoryManufacturerRepository()),
        ChangeNotifierProvider(
          create: (context) => WeaponListNotifier(context.read<WeaponRepository>()),
        ),
        ChangeNotifierProvider(
          create: (context) => ManufacturerListNotifier(context.read<ManufacturerRepository>()),
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
