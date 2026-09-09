import 'package:shared_preferences/shared_preferences.dart';

import '../data/seed_categories.dart';
import '../models/category.dart';
import '../models/category_query.dart';
import '../models/page_result.dart';
import 'category_repository.dart';
import 'local/json_list_store.dart';
import 'persistent_weapon_repository.dart';
import 'repository_exceptions.dart';

class PersistentCategoryRepository implements CategoryRepository {
  PersistentCategoryRepository(SharedPreferences prefs, this._weapons)
      : _store = JsonListStore<Category>(
          key: 'categories_v1',
          prefs: prefs,
          toJson: (c) => c.toJson(),
          fromJson: Category.fromJson,
          seed: seedCategories,
        );

  final JsonListStore<Category> _store;

  /// Не null, если локальные данные при старте оказались нечитаемыми и
  /// были сброшены к начальному набору — см. [JsonListStore.resetMessage].
  String? get storageResetMessage => _store.resetMessage;
  final PersistentWeaponRepository _weapons;
  List<Category> get _categories => _store.items;

  @override
  Future<PageResult<Category>> find(CategoryQuery q) async {
    await Future.delayed(const Duration(milliseconds: 250));

    var rows = _categories.where((c) => q.includeDeleted || !c.isDeleted).toList();

    if (q.search.trim().isNotEmpty) {
      final needle = q.search.trim().toLowerCase();
      rows = rows.where((c) => c.name.toLowerCase().contains(needle)).toList();
    }

    rows.sort((a, b) {
      final result = a.name.toLowerCase().compareTo(b.name.toLowerCase());
      return q.sortAscending ? result : -result;
    });

    final total = rows.length;
    final from = (q.page - 1) * q.size;
    final to = (from + q.size) > total ? total : (from + q.size);
    final items = from >= total ? <Category>[] : rows.sublist(from, to);
    return PageResult(items: items, page: q.page, size: q.size, total: total);
  }

  @override
  Future<Category?> findById(int id) async {
    for (final c in _categories) {
      if (c.id == id) return c;
    }
    return null;
  }

  @override
  Future<List<Category>> listAll() async {
    final rows = _categories.where((c) => !c.isDeleted).toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return List.unmodifiable(rows);
  }

  @override
  Future<Category> create(Category draft) async {
    final nextId =
        _categories.isEmpty ? 1 : _categories.map((c) => c.id).reduce((a, b) => a > b ? a : b) + 1;
    final withId = Category(id: nextId, name: draft.name);
    await _store.mutate((items) => items.add(withId));
    return withId;
  }

  @override
  Future<Category> update(Category category) async {
    final i = _categories.indexWhere((c) => c.id == category.id);
    if (i == -1) throw StateError('Категория ${category.id} не найдена');
    await _store.mutate(
      (items) => items[i] = category.copyWith(deletedAt: _categories[i].deletedAt),
    );
    return _categories[i];
  }

  Future<void> _guardReferences(int id) async {
    final count = await _weapons.countActiveByCategory(id);
    if (count > 0) {
      throw ReferentialIntegrityException(
        count,
        'Нельзя удалить: на категорию ссылается $count ед. оружия',
      );
    }
  }

  @override
  Future<void> softDelete(int id) async {
    await _guardReferences(id);
    final i = _categories.indexWhere((c) => c.id == id);
    if (i == -1) throw StateError('Категория $id не найдена');
    await _store.mutate((items) => items[i] = items[i].copyWith(deletedAt: DateTime.now()));
  }

  @override
  Future<void> hardDelete(int id) async {
    await _guardReferences(id);
    await _store.mutate((items) => items.removeWhere((c) => c.id == id));
  }

  @override
  Future<void> restore(int id) async {
    final i = _categories.indexWhere((c) => c.id == id);
    if (i == -1) throw StateError('Категория $id не найдена');
    await _store.mutate((items) => items[i] = items[i].copyWith(clearDeletedAt: true));
  }

  @override
  Future<int> deleteMany(List<int> ids) async {
    var count = 0;
    await _store.mutate((items) {
      for (final id in ids) {
        final i = items.indexWhere((c) => c.id == id && !c.isDeleted);
        if (i == -1) continue;
        items[i] = items[i].copyWith(deletedAt: DateTime.now());
        count++;
      }
    });
    return count;
  }
}
