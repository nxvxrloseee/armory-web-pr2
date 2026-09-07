import '../data/seed_manufacturers.dart';
import '../models/manufacturer.dart';
import '../models/manufacturer_query.dart';
import '../models/page_result.dart';
import 'manufacturer_repository.dart';

class InMemoryManufacturerRepository implements ManufacturerRepository {
  final List<Manufacturer> _manufacturers = [...seedManufacturers];

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
  Future<void> softDelete(int id) async {
    final i = _manufacturers.indexWhere((m) => m.id == id);
    if (i == -1) throw StateError('Производитель $id не найден');
    _manufacturers[i] = _manufacturers[i].copyWith(deletedAt: DateTime.now());
  }

  @override
  Future<void> hardDelete(int id) async {
    _manufacturers.removeWhere((m) => m.id == id);
  }

  @override
  Future<void> restore(int id) async {
    final i = _manufacturers.indexWhere((m) => m.id == id);
    if (i == -1) throw StateError('Производитель $id не найден');
    _manufacturers[i] = _manufacturers[i].copyWith(clearDeletedAt: true);
  }

  @override
  Future<int> deleteMany(List<int> ids) async {
    // См. пояснение к аналогичному методу в in_memory_weapon_repository.dart:
    // фикс той же намеренной ошибки из методички (раздел 2.4).
    var count = 0;
    for (final id in ids) {
      final i = _manufacturers.indexWhere((m) => m.id == id && !m.isDeleted);
      if (i != -1) {
        _manufacturers[i] = _manufacturers[i].copyWith(deletedAt: DateTime.now());
        count++;
      }
    }
    return count;
  }
}
