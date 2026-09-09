import 'package:shared_preferences/shared_preferences.dart';

import '../data/seed_manufacturers.dart';
import '../models/manufacturer.dart';
import '../models/manufacturer_query.dart';
import '../models/page_result.dart';
import 'local/json_list_store.dart';
import 'manufacturer_repository.dart';
import 'persistent_weapon_repository.dart';
import 'repository_exceptions.dart';

class PersistentManufacturerRepository implements ManufacturerRepository {
  /// [_weapons] нужен только для проверки перед удалением: сколько единиц
  /// оружия ещё ссылаются на производителя.
  PersistentManufacturerRepository(SharedPreferences prefs, this._weapons)
      : _store = JsonListStore<Manufacturer>(
          key: 'manufacturers_v1',
          prefs: prefs,
          toJson: (m) => m.toJson(),
          fromJson: Manufacturer.fromJson,
          seed: seedManufacturers,
        );

  final JsonListStore<Manufacturer> _store;

  /// Не null, если локальные данные при старте оказались нечитаемыми и
  /// были сброшены к начальному набору — см. [JsonListStore.resetMessage].
  String? get storageResetMessage => _store.resetMessage;
  final PersistentWeaponRepository _weapons;
  List<Manufacturer> get _manufacturers => _store.items;

  @override
  Future<PageResult<Manufacturer>> find(ManufacturerQuery q) async {
    await Future.delayed(const Duration(milliseconds: 250));

    var rows = _manufacturers.where((m) => q.includeDeleted || !m.isDeleted).toList();

    if (q.search.trim().isNotEmpty) {
      final needle = q.search.trim().toLowerCase();
      rows = rows
          .where((m) =>
              m.name.toLowerCase().contains(needle) ||
              m.country.toLowerCase().contains(needle))
          .toList();
    }

    rows.sort((a, b) {
      final result = switch (q.sortField) {
        'country' => a.country.toLowerCase().compareTo(b.country.toLowerCase()),
        'founded' => a.founded.compareTo(b.founded),
        _ => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
      };
      return q.sortAscending ? result : -result;
    });

    final total = rows.length;
    final from = (q.page - 1) * q.size;
    final to = (from + q.size) > total ? total : (from + q.size);
    final items = from >= total ? <Manufacturer>[] : rows.sublist(from, to);
    return PageResult(items: items, page: q.page, size: q.size, total: total);
  }

  @override
  Future<Manufacturer?> findById(int id) async {
    for (final m in _manufacturers) {
      if (m.id == id) return m;
    }
    return null;
  }

  @override
  Future<List<Manufacturer>> listAll() async {
    final rows = _manufacturers.where((m) => !m.isDeleted).toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return List.unmodifiable(rows);
  }

  @override
  Future<Manufacturer> create(Manufacturer draft) async {
    final nextId = _manufacturers.isEmpty
        ? 1
        : _manufacturers.map((m) => m.id).reduce((a, b) => a > b ? a : b) + 1;
    final withId = Manufacturer(
      id: nextId,
      name: draft.name,
      country: draft.country,
      founded: draft.founded,
    );
    await _store.mutate((items) => items.add(withId));
    return withId;
  }

  @override
  Future<Manufacturer> update(Manufacturer manufacturer) async {
    final i = _manufacturers.indexWhere((m) => m.id == manufacturer.id);
    if (i == -1) throw StateError('Производитель ${manufacturer.id} не найден');
    await _store.mutate(
      (items) => items[i] = manufacturer.copyWith(deletedAt: _manufacturers[i].deletedAt),
    );
    return _manufacturers[i];
  }

  Future<void> _guardReferences(int id) async {
    final count = await _weapons.countActiveByManufacturer(id);
    if (count > 0) {
      throw ReferentialIntegrityException(
        count,
        'Нельзя удалить: на производителя ссылается $count ед. оружия',
      );
    }
  }

  @override
  Future<void> softDelete(int id) async {
    await _guardReferences(id);
    final i = _manufacturers.indexWhere((m) => m.id == id);
    if (i == -1) throw StateError('Производитель $id не найден');
    await _store.mutate((items) => items[i] = items[i].copyWith(deletedAt: DateTime.now()));
  }

  @override
  Future<void> hardDelete(int id) async {
    await _guardReferences(id);
    await _store.mutate((items) => items.removeWhere((m) => m.id == id));
  }

  @override
  Future<void> restore(int id) async {
    final i = _manufacturers.indexWhere((m) => m.id == id);
    if (i == -1) throw StateError('Производитель $id не найден');
    await _store.mutate((items) => items[i] = items[i].copyWith(clearDeletedAt: true));
  }

  @override
  Future<int> deleteMany(List<int> ids) async {
    // См. пояснение к аналогичному методу в persistent_weapon_repository.dart:
    // фикс той же намеренной ошибки из методички (раздел 2.4).
    //
    // Проверка ссылочной целостности здесь намеренно не выполняется: она
    // требуется заданием только для одиночного удаления с явным ответом
    // пользователю (см. softDelete/hardDelete) — при массовом выделении нет
    // понятного места показать «нельзя удалить, на запись ссылается N»
    // отдельно для каждой из выбранных записей.
    var count = 0;
    await _store.mutate((items) {
      for (final id in ids) {
        final i = items.indexWhere((m) => m.id == id && !m.isDeleted);
        if (i == -1) continue;
        items[i] = items[i].copyWith(deletedAt: DateTime.now());
        count++;
      }
    });
    return count;
  }
}
