import 'package:flutter_test/flutter_test.dart';

import 'package:armory_web/main.dart';

void main() {
  testWidgets('приложение запускается и показывает главный экран', (tester) async {
    await tester.pumpWidget(const ArmoryApp());
    await tester.pumpAndSettle();

    expect(find.text('Оружие'), findsOneWidget);
    expect(find.text('Производители'), findsOneWidget);
  });
}
