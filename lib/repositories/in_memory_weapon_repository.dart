import '../data/seed_weapons.dart';
import '../models/page_result.dart';
import '../models/weapon.dart';
import '../models/weapon_query.dart';
import 'weapon_repository.dart';

class InMemoryWeaponRepository implements WeaponRepository {
  final List<Weapon> _weapons = [...seedWeapons];

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

  @override
  Future<void> softDelete(int id) async {
    final i = _weapons.indexWhere((w) => w.id == id);
    if (i == -1) throw StateError('Оружие $id не найдено');
    _weapons[i] = _weapons[i].copyWith(deletedAt: DateTime.now());
  }

  @override
  Future<void> hardDelete(int id) async {
    _weapons.removeWhere((w) => w.id == id);
  }

  @override
  Future<void> restore(int id) async {
    final i = _weapons.indexWhere((w) => w.id == id);
    if (i == -1) throw StateError('Оружие $id не найдено');
    _weapons[i] = _weapons[i].copyWith(clearDeletedAt: true);
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
    for (final id in ids) {
      final i = _weapons.indexWhere((w) => w.id == id && !w.isDeleted);
      if (i != -1) {
        _weapons[i] = _weapons[i].copyWith(deletedAt: DateTime.now());
        count++;
      }
    }
    return count;
  }
}
