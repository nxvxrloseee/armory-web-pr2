import 'package:shared_preferences/shared_preferences.dart';

import '../data/seed_designers.dart';
import '../models/designer.dart';
import '../models/designer_query.dart';
import '../models/page_result.dart';
import 'designer_repository.dart';
import 'local/json_list_store.dart';
import 'persistent_weapon_repository.dart';
import 'repository_exceptions.dart';

class PersistentDesignerRepository implements DesignerRepository {
  PersistentDesignerRepository(SharedPreferences prefs, this._weapons)
      : _store = JsonListStore<Designer>(
          key: 'designers_v1',
          prefs: prefs,
          toJson: (d) => d.toJson(),
          fromJson: Designer.fromJson,
          seed: seedDesigners,
        );

  final JsonListStore<Designer> _store;

  /// Не null, если локальные данные при старте оказались нечитаемыми и
  /// были сброшены к начальному набору — см. [JsonListStore.resetMessage].
  String? get storageResetMessage => _store.resetMessage;
  final PersistentWeaponRepository _weapons;
  List<Designer> get _designers => _store.items;

  @override
  Future<PageResult<Designer>> find(DesignerQuery q) async {
    await Future.delayed(const Duration(milliseconds: 250));

    var rows = _designers.where((d) => q.includeDeleted || !d.isDeleted).toList();

    if (q.search.trim().isNotEmpty) {
      final needle = q.search.trim().toLowerCase();
      rows = rows
          .where((d) =>
              d.fullName.toLowerCase().contains(needle) ||
              d.country.toLowerCase().contains(needle))
          .toList();
    }

    rows.sort((a, b) {
      final result = switch (q.sortField) {
        'country' => a.country.toLowerCase().compareTo(b.country.toLowerCase()),
        'activeSince' => a.activeSince.compareTo(b.activeSince),
        _ => a.fullName.toLowerCase().compareTo(b.fullName.toLowerCase()),
      };
      return q.sortAscending ? result : -result;
    });

    final total = rows.length;
    final from = (q.page - 1) * q.size;
    final to = (from + q.size) > total ? total : (from + q.size);
    final items = from >= total ? <Designer>[] : rows.sublist(from, to);
    return PageResult(items: items, page: q.page, size: q.size, total: total);
  }

  @override
  Future<Designer?> findById(int id) async {
    for (final d in _designers) {
      if (d.id == id) return d;
    }
    return null;
  }

  @override
  Future<List<Designer>> listAll() async {
    final rows = _designers.where((d) => !d.isDeleted).toList()
      ..sort((a, b) => a.fullName.toLowerCase().compareTo(b.fullName.toLowerCase()));
    return List.unmodifiable(rows);
  }

  @override
  Future<Designer> create(Designer draft) async {
    final nextId =
        _designers.isEmpty ? 1 : _designers.map((d) => d.id).reduce((a, b) => a > b ? a : b) + 1;
    final withId = Designer(
      id: nextId,
      fullName: draft.fullName,
      country: draft.country,
      activeSince: draft.activeSince,
    );
    await _store.mutate((items) => items.add(withId));
    return withId;
  }

  @override
  Future<Designer> update(Designer designer) async {
    final i = _designers.indexWhere((d) => d.id == designer.id);
    if (i == -1) throw StateError('Конструктор ${designer.id} не найден');
    await _store.mutate(
      (items) => items[i] = designer.copyWith(deletedAt: _designers[i].deletedAt),
    );
    return _designers[i];
  }

  Future<void> _guardReferences(int id) async {
    final count = await _weapons.countActiveByDesigner(id);
    if (count > 0) {
      throw ReferentialIntegrityException(
        count,
        'Нельзя удалить: с конструктором связано $count ед. оружия',
      );
    }
  }

  @override
  Future<void> softDelete(int id) async {
    await _guardReferences(id);
    final i = _designers.indexWhere((d) => d.id == id);
    if (i == -1) throw StateError('Конструктор $id не найден');
    await _store.mutate((items) => items[i] = items[i].copyWith(deletedAt: DateTime.now()));
  }

  @override
  Future<void> hardDelete(int id) async {
    await _guardReferences(id);
    await _store.mutate((items) => items.removeWhere((d) => d.id == id));
  }

  @override
  Future<void> restore(int id) async {
    final i = _designers.indexWhere((d) => d.id == id);
    if (i == -1) throw StateError('Конструктор $id не найден');
    await _store.mutate((items) => items[i] = items[i].copyWith(clearDeletedAt: true));
  }

  @override
  Future<int> deleteMany(List<int> ids) async {
    var count = 0;
    await _store.mutate((items) {
      for (final id in ids) {
        final i = items.indexWhere((d) => d.id == id && !d.isDeleted);
        if (i == -1) continue;
        items[i] = items[i].copyWith(deletedAt: DateTime.now());
        count++;
      }
    });
    return count;
  }
}
