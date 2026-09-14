import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/api_exceptions.dart';
import '../core/auth_api.dart';
import '../models/app_user.dart';
import '../models/role.dart';

/// Состояние входа на всё приложение — токены переживают перезагрузку
/// страницы (лежат в shared_preferences, то есть в localStorage на web).
///
/// Профиль пользователя (в т.ч. роль) кэшируется здесь же, в
/// `auth_cached_user`, и после первого входа именно этот кэш красит
/// интерфейс — сервер на /auth/me запрашивается только чтобы убедиться, что
/// токен ещё жив, его ответ роль в кэше не перезаписывает. Это НАМЕРЕННО
/// уязвимое для подмены место (см. задание ПР5, п.17: открыть DevTools,
/// поменять `auth_cached_user` в localStorage на role":"admin", перезагрузить
/// страницу — интерфейс покажет кнопки администратора). Реальная защита
/// живёт только на сервере: тот же токен доступа привязан к настоящей роли
/// в таблице app_users, и любое действие продавца/администратора сервер
/// перепроверяет сам (RequireRole в armory_api/internal/auth) — интерфейс
/// можно обмануть, конкретный запрос — нет.
class AuthNotifier extends ChangeNotifier {
  static const _kAccess = 'auth_access_token';
  static const _kRefresh = 'auth_refresh_token';
  static const _kSessionStarted = 'auth_session_started';
  static const _kCachedUser = 'auth_cached_user';

  /// Общая длительность сессии (ПР5, оценка «5») — независимо от активности,
  /// по истечении этого времени от входа пользователь выходит.
  static const sessionMaxAge = Duration(hours: 8);

  AuthNotifier(this._prefs, this._api);

  final SharedPreferences _prefs;
  final AuthApi _api;

  AppUser? _user;
  String? _accessToken;
  String? _refreshToken;
  DateTime? _sessionStarted;
  String? _restoreError;
  String? _lastLogoutReason;
  bool _restoring = true;

  AppUser? get user => _user;
  String? get accessToken => _accessToken;
  String? get restoreError => _restoreError;
  bool get isAuthenticated => _user != null;
  bool get isRestoring => _restoring;

  /// Причина последнего автоматического выхода (по неактивности, по общей
  /// длительности сессии, по неудачному обновлению токена) — экран входа
  /// показывает её один раз и сбрасывает через [consumeLogoutReason].
  String? get lastLogoutReason => _lastLogoutReason;

  String? consumeLogoutReason() {
    final reason = _lastLogoutReason;
    _lastLogoutReason = null;
    return reason;
  }

  bool has(Role role) => _user != null && _user!.role.level >= role.level;

  DateTime? get sessionExpiresAt => _sessionStarted?.add(sessionMaxAge);

  /// Восстановление сессии при запуске приложения — вызывается один раз до
  /// построения дерева виджетов (см. main.dart).
  Future<void> restore() async {
    _restoring = true;
    final access = _prefs.getString(_kAccess);
    final refresh = _prefs.getString(_kRefresh);
    final startedRaw = _prefs.getString(_kSessionStarted);
    _sessionStarted = startedRaw == null ? null : DateTime.tryParse(startedRaw);

    if (access == null) {
      _restoring = false;
      notifyListeners();
      return;
    }
    if (_sessionExpired()) {
      await logout(reason: 'Сессия завершена: истекло максимальное время входа.');
      _restoring = false;
      notifyListeners();
      return;
    }

    _accessToken = access;
    _refreshToken = refresh;
    // Красим интерфейс сразу по кэшу, не дожидаясь сети — и именно этот
    // кэш, не ответ сервера, остаётся источником роли для UI (см. класс-doc).
    final cachedRaw = _prefs.getString(_kCachedUser);
    if (cachedRaw != null) {
      try {
        _user = AppUser.fromJson(jsonDecode(cachedRaw) as Map<String, dynamic>);
      } catch (_) {
        _user = null;
      }
    }
    try {
      await _api.me(access); // только проверка, что токен ещё жив
      _restoreError = null;
    } on UnauthorizedException {
      if (refresh != null) {
        try {
          await _refreshWith(refresh);
        } catch (_) {
          await logout(reason: 'Сессия завершена: не удалось обновить токен.');
        }
      } else {
        await logout(reason: 'Сессия истекла, войдите снова.');
      }
    } catch (_) {
      // Сервер недоступен: сессию не сбрасываем, покажем ошибку на экране
      // входа, но токен остаётся — при следующей успешной проверке (или
      // перезагрузке, когда сервер снова будет доступен) всё восстановится
      // само, без повторного ввода пароля.
      _restoreError = 'Не удалось проверить сессию: сервер недоступен.';
    }
    _restoring = false;
    notifyListeners();
  }

  bool _sessionExpired() {
    final started = _sessionStarted;
    return started != null && DateTime.now().toUtc().difference(started) > sessionMaxAge;
  }

  Future<void> login(String username, String password) async {
    final result = await _api.login(username, password);
    await _applySession(result);
  }

  Future<void> register(RegisterInput input) async {
    final result = await _api.register(input);
    await _applySession(result);
  }

  Future<void> _applySession(LoginResult result) async {
    _accessToken = result.accessToken;
    _refreshToken = result.refreshToken;
    _user = result.user;
    _sessionStarted = DateTime.now().toUtc();
    _restoreError = null;
    await _prefs.setString(_kAccess, result.accessToken);
    await _prefs.setString(_kRefresh, result.refreshToken);
    await _prefs.setString(_kSessionStarted, _sessionStarted!.toIso8601String());
    await _prefs.setString(_kCachedUser, jsonEncode(result.user.toJson()));
    notifyListeners();
  }

  /// Вызывается интерсептором Dio при 401 на "боевом" запросе — молча
  /// обновляет токен, чтобы исходный запрос можно было повторить прозрачно
  /// для пользователя (ПР5, оценка «5»). Бросает исключение, если refresh
  /// не удался — тогда интерсептор обязан разлогинить пользователя сам.
  Future<void> refreshTokens() async {
    final refresh = _refreshToken;
    if (refresh == null) throw const UnauthorizedException();
    await _refreshWith(refresh);
  }

  Future<void> _refreshWith(String refreshToken) async {
    final result = await _api.refresh(refreshToken);
    await _applySession(result);
  }

  Future<void> logout({String? reason}) async {
    final token = _accessToken;
    _user = null;
    _accessToken = null;
    _refreshToken = null;
    _sessionStarted = null;
    if (reason != null) _lastLogoutReason = reason;
    await _prefs.remove(_kAccess);
    await _prefs.remove(_kRefresh);
    await _prefs.remove(_kSessionStarted);
    await _prefs.remove(_kCachedUser);
    notifyListeners();
    if (token != null) {
      try {
        await _api.logout(token);
      } catch (_) {
        // Сервер недоступен/токен уже недействителен — локальный выход уже
        // произошёл, серверная сессия просто протухнет по TTL сама.
      }
    }
  }
}
