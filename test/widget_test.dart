import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:armory_web/main.dart';
import 'package:armory_web/repositories/persistent_category_repository.dart';
import 'package:armory_web/repositories/persistent_client_repository.dart';
import 'package:armory_web/repositories/persistent_designer_repository.dart';
import 'package:armory_web/repositories/persistent_manufacturer_repository.dart';
import 'package:armory_web/repositories/persistent_weapon_repository.dart';

void main() {
  testWidgets('приложение запускается и показывает главный экран', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final weaponRepository = PersistentWeaponRepository(prefs);

    await tester.pumpWidget(ArmoryApp(
      weaponRepository: weaponRepository,
      manufacturerRepository: PersistentManufacturerRepository(prefs, weaponRepository),
      categoryRepository: PersistentCategoryRepository(prefs, weaponRepository),
      designerRepository: PersistentDesignerRepository(prefs, weaponRepository),
      clientRepository: PersistentClientRepository(prefs),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Оружие'), findsOneWidget);
    expect(find.text('Производители'), findsOneWidget);
  });
}
