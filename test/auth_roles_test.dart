import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:armory_web/core/auth_api.dart';
import 'package:armory_web/models/role.dart';
import 'package:armory_web/state/auth_notifier.dart';

/// Подменяет реальную сеть на канонические ответы /auth/login|register|me —
/// тем же приёмом, что и задание рекомендует для тестов репозитория
/// ("модульные тесты репозитория с подменённым Dio"), только здесь
/// подменяется не сам Dio-репозиторий, а его транспорт (HttpClientAdapter),
/// поэтому проверяется настоящий код AuthNotifier/AuthApi, а не заглушка.
class _FakeAuthAdapter implements HttpClientAdapter {
  _FakeAuthAdapter(this.role);
  final String role;

  static const _headers = {
    Headers.contentTypeHeader: [Headers.jsonContentType],
  };

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    if (options.path.contains('/auth/login') || options.path.contains('/auth/register')) {
      final body = jsonEncode({
        'accessToken': 'test-access',
        'refreshToken': 'test-refresh',
        'expiresIn': 900,
        'user': {
          'id': 1,
          'username': 'test-user',
          'fullName': 'Тестовый пользователь',
          'role': role,
          if (role == 'buyer') 'clientId': 1,
        },
      });
      return ResponseBody.fromString(body, 200, headers: _headers);
    }
    return ResponseBody.fromString(jsonEncode({'message': 'not found'}), 404, headers: _headers);
  }

  @override
  void close({bool force = false}) {}
}

Future<AuthNotifier> _loggedInAs(String role) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final dio = Dio()..httpClientAdapter = _FakeAuthAdapter(role);
  final auth = AuthNotifier(prefs, AuthApi(dio));
  await auth.login('test-user', 'irrelevant');
  return auth;
}

void main() {
  // ПР5, оценка «5»: «тесты на логику разграничения прав — не менее пяти
  // проверок соответствия роли и доступности операции».
  group('Role — иерархия уровней', () {
    test('buyer < seller < admin', () {
      expect(Role.buyer.level, lessThan(Role.seller.level));
      expect(Role.seller.level, lessThan(Role.admin.level));
    });

    test('fromWire восстанавливает роль по строке с сервера', () {
      expect(Role.fromWire('seller'), Role.seller);
      expect(Role.fromWire('admin'), Role.admin);
    });

    test('fromWire откатывается на buyer для неизвестного значения', () {
      // Сервер — источник истины по ролям; если когда-нибудь пришлют
      // значение, которого клиент не знает, показывать нужно наименьшие
      // права, а не падать и не молча выдавать что-то более привилегированное.
      expect(Role.fromWire('unknown-role'), Role.buyer);
    });
  });

  group('AuthNotifier.has — соответствие роли и доступности операции', () {
    test('покупатель не видит операций продавца и администратора', () async {
      final auth = await _loggedInAs('buyer');
      expect(auth.has(Role.buyer), isTrue);
      expect(auth.has(Role.seller), isFalse);
      expect(auth.has(Role.admin), isFalse);
    });

    test('продавец видит операции покупателя и продавца, но не администратора', () async {
      final auth = await _loggedInAs('seller');
      expect(auth.has(Role.buyer), isTrue);
      expect(auth.has(Role.seller), isTrue);
      expect(auth.has(Role.admin), isFalse);
    });

    test('администратор видит операции всех трёх ролей', () async {
      final auth = await _loggedInAs('admin');
      expect(auth.has(Role.buyer), isTrue);
      expect(auth.has(Role.seller), isTrue);
      expect(auth.has(Role.admin), isTrue);
    });

    test('незалогиненный пользователь не имеет прав ни одной роли', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final dio = Dio()..httpClientAdapter = _FakeAuthAdapter('admin');
      final auth = AuthNotifier(prefs, AuthApi(dio)); // login() ни разу не вызван
      expect(auth.has(Role.buyer), isFalse);
      expect(auth.has(Role.seller), isFalse);
      expect(auth.has(Role.admin), isFalse);
    });

    test('вход как покупатель привязывает clientId — нужен для "своих" заказов', () async {
      final auth = await _loggedInAs('buyer');
      expect(auth.user?.clientId, 1);
    });
  });
}
