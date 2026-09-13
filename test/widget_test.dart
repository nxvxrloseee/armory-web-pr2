import 'package:flutter_test/flutter_test.dart';

import 'package:armory_web/main.dart';

void main() {
  testWidgets('приложение запускается и показывает главный экран', (tester) async {
    // С переходом на сервер (ПР4) ArmoryApp сама строит Dio и репозитории —
    // внешние параметры конструктору больше не нужны, инъекция моков для
    // тестов репозиториев теперь на уровне Dio (см. задание, раздел 4,
    // оценка «5»), а не всего дерева виджетов.
    await tester.pumpWidget(const ArmoryApp());
    await tester.pump();

    expect(find.text('Оружие'), findsOneWidget);
    expect(find.text('Производители'), findsOneWidget);
  });
}
