import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Хранит список сущностей в localStorage (через [SharedPreferences]) как
/// JSON-массив под одним ключом — общая для всех пяти сущностей замена
/// пяти одинаковых по структуре `_restore`/`_persist` (см. методичку,
/// раздел 3.2).
///
/// Суффикс версии зашит в [key] самим вызывающим кодом (например,
/// `weapons_v1`): при изменении состава полей модели переход на `_v2`
/// делает старые данные просто нечитаемыми под новым ключом — без
/// падения приложения и без ручной чистки хранилища пользователя.
class JsonListStore<T> {
  JsonListStore({
    required this.key,
    required this.prefs,
    required this.toJson,
    required this.fromJson,
    required List<T> seed,
  }) : _seed = seed {
    _restore();
  }

  final String key;
  final SharedPreferences prefs;
  final Map<String, dynamic> Function(T item) toJson;
  final T Function(Map<String, dynamic> json) fromJson;
  final List<T> _seed;

  late List<T> _items;
  List<T> get items => _items;

  /// Не null, если при запуске данные под [key] оказались нечитаемыми
  /// (испорчены или относятся к более старому формату модели) и были
  /// сброшены к начальному набору. Приложение показывает это сообщение
  /// пользователю один раз при старте — молча терять его правки нельзя,
  /// даже если формально это лишь демо-данные (см. задание, раздел 4,
  /// оценка «5»: «реализована либо миграция, либо смена ключа с показом
  /// сообщения»).
  String? resetMessage;

  void _restore() {
    // Само чтение из SharedPreferences тоже может бросить исключение — не
    // только jsonDecode/fromJson ниже. Значение под тем же ключом, но в
    // несовместимом внутреннем представлении (например, оставшееся от
    // более старой версии плагина или записанное не через этот класс),
    // валит getString() до того, как раскодировать что-либо, поэтому весь
    // разбор — включая сам вызов getString — обёрнут в один try/catch.
    try {
      final raw = prefs.getString(key);
      if (raw == null) {
        _items = [..._seed]; // первый запуск — начальный набор
        _persist();
        return;
      }
      final list = jsonDecode(raw) as List;
      _items = list.map((e) => fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      // Данные испорчены, нечитаемы или относятся к старому формату
      // (например, после смены состава полей модели без смены ключа) —
      // начинаем заново, не роняя приложение, но и не скрывая это от
      // пользователя.
      _items = [..._seed];
      resetMessage = 'Локальные данные «$key» были в неподдерживаемом '
          'формате и сброшены к начальному набору.';
      _persist();
    }
  }

  Future<void> _persist() async {
    await prefs.setString(key, jsonEncode(_items.map(toJson).toList()));
  }

  /// Все точечные изменения (create/update/delete) идут через этот метод:
  /// он одновременно обновляет память и сохраняет снимок на диск, поэтому
  /// вызывающему репозиторию не нужно помнить об этом самому.
  Future<void> mutate(void Function(List<T> items) apply) async {
    apply(_items);
    await _persist();
  }
}
