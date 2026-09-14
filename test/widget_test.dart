import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:armory_web/core/auth_api.dart';
import 'package:armory_web/main.dart';
import 'package:armory_web/router.dart';
import 'package:armory_web/state/auth_notifier.dart';

void main() {
  testWidgets('приложение запускается и показывает главный экран', (tester) async {
    // AuthNotifier до restore() ещё "восстанавливается" (isRestoring == true),
    // поэтому redirect() в router.dart ничего не решает и пропускает прямо
    // на '/', как и раньше без входа — то же поведение, что ожидал старый
    // тест, без реального похода на сервер.
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final dio = Dio();
    final authNotifier = AuthNotifier(prefs, AuthApi(dio));
    final router = buildRouter(authNotifier);

    await tester.pumpWidget(ArmoryApp(dio: dio, authNotifier: authNotifier, router: router));
    await tester.pump();

    expect(find.text('Оружие'), findsOneWidget);
    expect(find.text('Производители'), findsOneWidget);
  });
}
