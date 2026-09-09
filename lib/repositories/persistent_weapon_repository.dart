import 'package:shared_preferences/shared_preferences.dart';

import '../data/seed_weapons.dart';
import '../models/page_result.dart';
import '../models/weapon.dart';
import '../models/weapon_query.dart';
import 'local/json_list_store.dart';
import 'repository_exceptions.dart';
import 'weapon_repository.dart';

class PersistentWeaponRepository implements WeaponRepository {
  PersistentWeaponRepository(SharedPreferences prefs)
      : _store = JsonListStore<Weapon>(
          key: 'weapons_v1',
          prefs: prefs,
          toJson: (w) => w.toJson(),
          fromJson: Weapon.fromJson,
          seed: seedWeapons,
        );

  final JsonListStore<Weapon> _store;

  /// Не null, если локальные данные при старте оказались нечитаемыми и
  /// были сброшены к начальному набору — см. [JsonListStore.resetMessage].
  String? get storageResetMessage => _store.resetMessage;
  List<Weapon> get _weapons => _store.items;

  @override
  Future<PageResult<Weapon>> find(WeaponQuery q) async {
    // Небольшая задержка имитирует сеть: без неё индикатор загрузки
    // невозможно увидеть, а на следующей практике он понадобится по-настоящему.
    await Future.delayed(const Duration(milliseconds: 250));

    var rows = _weapons.where((w) => q.includeDeleted || !w.isDeleted).toList();

    if (q.search.trim().isNotEmpty) {
      final needle = q.search.trim().toLowerCase();
      rows = rows
          .where((w) =>
              w.name.toLowerCase().contains(needle) ||
              w.sku.toLowerCase().contains(needle))
          .toList();
    }
    if (q.categoryId != null) {
      rows = rows.where((w) => w.categoryIds.contains(q.categoryId)).toList();
    }
    if (q.manufacturerId != null) {
      rows = rows.where((w) => w.manufacturerId == q.manufacturerId).toList();
    }
    if (q.designerId != null) {
      rows = rows.where((w) => w.designerIds.contains(q.designerId)).toList();
    }
    if (q.yearFrom != null) {
      rows = rows.where((w) => w.year >= q.yearFrom!).toList();
    }
    if (q.yearTo != null) {
      rows = rows.where((w) => w.year <= q.yearTo!).toList();
    }

    rows.sort((a, b) {
      final result = switch (q.sortField) {
        'year' => a.year.compareTo(b.year),
        'price' => a.price.compareTo(b.price),
        _ => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
      };
      return q.sortAscending ? result : -result;
    });

    final total = rows.length;
    final from = (q.page - 1) * q.size;
    // num.clamp возвращает num, а не int, и в sublist его передать нельзя.
    // Границу считаем явно.
    final to = (from + q.size) > total ? total : (from + q.size);
    final items = from >= total ? <Weapon>[] : rows.sublist(from, to);
    return PageResult(items: items, page: q.page, size: q.size, total: total);
  }

  @override
  Future<Weapon?> findById(int id) async {
    for (final w in _weapons) {
      if (w.id == id) return w;
    }
    return null;
  }

  bool _skuTaken(String sku, {int? excludingId}) => _weapons.any(
        (w) => w.id != excludingId && w.sku.toLowerCase() == sku.toLowerCase(),
      );

  @override
  Future<Weapon> create(Weapon draft) async {
    if (_skuTaken(draft.sku)) {
      throw UniqueConstraintException('sku', 'Артикул «${draft.sku}» уже используется');
    }
    final nextId =
        _weapons.isEmpty ? 1 : _weapons.map((w) => w.id).reduce((a, b) => a > b ? a : b) + 1;
    final withId = Weapon(
      id: nextId,
      name: draft.name,
      sku: draft.sku,
      year: draft.year,
      caliber: draft.caliber,
      manufacturerId: draft.manufacturerId,
      categoryIds: draft.categoryIds,
      designerIds: draft.designerIds,
      price: draft.price,
      stockTotal: draft.stockTotal,
      stockAvailable: draft.stockAvailable,
    );
    await _store.mutate((items) => items.add(withId));
    return withId;
  }

  @override
  Future<Weapon> update(Weapon weapon) async {
    if (_skuTaken(weapon.sku, excludingId: weapon.id)) {
      throw UniqueConstraintException('sku', 'Артикул «${weapon.sku}» уже используется');
    }
    final i = _weapons.indexWhere((w) => w.id == weapon.id);
    if (i == -1) throw StateError('Оружие ${weapon.id} не найдено');
    await _store.mutate((items) => items[i] = weapon.copyWith(deletedAt: _weapons[i].deletedAt));
    return _weapons[i];
  }

  @override
  Future<void> softDelete(int id) async {
    final i = _weapons.indexWhere((w) => w.id == id);
    if (i == -1) throw StateError('Оружие $id не найдено');
    await _store.mutate((items) => items[i] = items[i].copyWith(deletedAt: DateTime.now()));
  }

  @override
  Future<void> hardDelete(int id) async {
    await _store.mutate((items) => items.removeWhere((w) => w.id == id));
  }

  @override
  Future<void> restore(int id) async {
    final i = _weapons.indexWhere((w) => w.id == id);
    if (i == -1) throw StateError('Оружие $id не найдено');
    await _store.mutate((items) => items[i] = items[i].copyWith(clearDeletedAt: true));
  }

  @override
  Future<int> deleteMany(List<int> ids) async {
    // В методичке (раздел 2.4) аналогичный метод намеренно содержит ошибку:
    // `_books.indexWhere((b) => b.id == id && !b[i].isDeleted)` — индекс `i`
    // используется до того, как indexWhere успел его вернуть, а `b[i]`
    // вообще не имеет смысла для Book/Weapon (это не список). Правильно
    // проверять флаг удаления у самого кандидата `w` внутри предиката, а не
    // индексировать по нему же.
    var count = 0;
    await _store.mutate((items) {
      for (final id in ids) {
        final i = items.indexWhere((w) => w.id == id && !w.isDeleted);
        if (i != -1) {
          items[i] = items[i].copyWith(deletedAt: DateTime.now());
          count++;
        }
      }
    });
    return count;
  }

  /// Нужен производителям/категориям/конструкторам для запрета каскадного
  /// удаления — считает не удалённое логически оружие, ссылающееся на связь.
  Future<int> countActiveByManufacturer(int manufacturerId) async =>
      _weapons.where((w) => !w.isDeleted && w.manufacturerId == manufacturerId).length;

  Future<int> countActiveByCategory(int categoryId) async =>
      _weapons.where((w) => !w.isDeleted && w.categoryIds.contains(categoryId)).length;

  Future<int> countActiveByDesigner(int designerId) async =>
      _weapons.where((w) => !w.isDeleted && w.designerIds.contains(designerId)).length;
}
