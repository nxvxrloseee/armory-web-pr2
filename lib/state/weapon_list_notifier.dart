import 'package:flutter/foundation.dart';

import '../models/page_result.dart';
import '../models/weapon.dart';
import '../models/weapon_query.dart';
import '../repositories/weapon_repository.dart';
import 'load_status.dart';

class WeaponListNotifier extends ChangeNotifier {
  final WeaponRepository _repository;
  WeaponListNotifier(this._repository);

  WeaponQuery _query = const WeaponQuery();
  PageResult<Weapon> _result = PageResult.empty();
  LoadStatus _status = LoadStatus.idle;
  String? _error;
  final Set<int> _selected = {};

  WeaponQuery get query => _query;
  PageResult<Weapon> get result => _result;
  LoadStatus get status => _status;
  String? get error => _error;
  Set<int> get selected => Set.unmodifiable(_selected);
  bool get hasSelection => _selected.isNotEmpty;

  Future<void> load() async {
    _status = LoadStatus.loading;
    _error = null;
    notifyListeners();
    try {
      _result = await _repository.find(_query);
      _status = LoadStatus.success;
    } catch (e) {
      _error = 'Не удалось загрузить список: $e';
      _status = LoadStatus.error;
    }
    notifyListeners();
  }

  Future<void> applyQuery(WeaponQuery next) async {
    _query = next;
    _selected.clear(); // выделение теряет смысл при смене условий отбора
    await load();
  }

  void toggleSelection(int id) {
    _selected.contains(id) ? _selected.remove(id) : _selected.add(id);
    notifyListeners();
  }

  void toggleSelectAll(List<int> ids) {
    final allSelected = ids.isNotEmpty && ids.every(_selected.contains);
    if (allSelected) {
      _selected.removeAll(ids);
    } else {
      _selected.addAll(ids);
    }
    notifyListeners();
  }

  Future<void> deleteSelected() async {
    await _repository.deleteMany(_selected.toList());
    _selected.clear();
    await load();
  }
}
