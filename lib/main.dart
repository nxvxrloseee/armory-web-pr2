import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
import 'repositories/category_repository.dart';
import 'repositories/client_repository.dart';
import 'repositories/designer_repository.dart';
import 'repositories/manufacturer_repository.dart';
import 'repositories/persistent_category_repository.dart';
import 'repositories/persistent_client_repository.dart';
import 'repositories/persistent_designer_repository.dart';
import 'repositories/persistent_manufacturer_repository.dart';
import 'repositories/persistent_weapon_repository.dart';
import 'repositories/weapon_repository.dart';
import 'router.dart';
import 'state/list_notifier.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  usePathUrlStrategy();
  final prefs = await SharedPreferences.getInstance();

  // Оружие создаётся первым: производитель/категория/конструктор используют
  // его для проверки перед удалением («на запись ещё ссылается N ед.
  // оружия», см. репозитории соответствующих сущностей).
  final weaponRepository = PersistentWeaponRepository(prefs);
  final manufacturerRepository = PersistentManufacturerRepository(prefs, weaponRepository);
  final categoryRepository = PersistentCategoryRepository(prefs, weaponRepository);
  final designerRepository = PersistentDesignerRepository(prefs, weaponRepository);
  final clientRepository = PersistentClientRepository(prefs);

  // Если локальные данные какой-то сущности оказались нечитаемыми и были
  // сброшены к начальному набору — пользователь должен узнать об этом
  // явно, а не просто увидеть демо-данные вместо своих (см. задание,
  // раздел 4, оценка «5»: «смена ключа с показом сообщения»).
  final storageResetMessages = [
    weaponRepository.storageResetMessage,
    manufacturerRepository.storageResetMessage,
    categoryRepository.storageResetMessage,
    designerRepository.storageResetMessage,
    clientRepository.storageResetMessage,
  ].whereType<String>().toList();

  runApp(ArmoryApp(
    weaponRepository: weaponRepository,
    manufacturerRepository: manufacturerRepository,
    categoryRepository: categoryRepository,
    designerRepository: designerRepository,
    clientRepository: clientRepository,
    storageResetMessages: storageResetMessages,
  ));
}

class ArmoryApp extends StatelessWidget {
  const ArmoryApp({
    super.key,
    required this.weaponRepository,
    required this.manufacturerRepository,
    required this.categoryRepository,
    required this.designerRepository,
    required this.clientRepository,
    this.storageResetMessages = const [],
  });

  final WeaponRepository weaponRepository;
  final ManufacturerRepository manufacturerRepository;
  final CategoryRepository categoryRepository;
  final DesignerRepository designerRepository;
  final ClientRepository clientRepository;
  final List<String> storageResetMessages;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<WeaponRepository>.value(value: weaponRepository),
        Provider<ManufacturerRepository>.value(value: manufacturerRepository),
        Provider<CategoryRepository>.value(value: categoryRepository),
        Provider<DesignerRepository>.value(value: designerRepository),
        Provider<ClientRepository>.value(value: clientRepository),
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
        builder: (context, child) =>
            _StorageResetGate(messages: storageResetMessages, child: child!),
      ),
    );
  }
}

/// Показывает предупреждение о сбросе локальных данных один раз при
/// старте приложения — независимо от того, какой маршрут открылся первым.
class _StorageResetGate extends StatefulWidget {
  const _StorageResetGate({required this.messages, required this.child});

  final List<String> messages;
  final Widget child;

  @override
  State<_StorageResetGate> createState() => _StorageResetGateState();
}

class _StorageResetGateState extends State<_StorageResetGate> {
  @override
  void initState() {
    super.initState();
    if (widget.messages.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.messages.join(' ')),
            duration: const Duration(seconds: 8),
          ),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
