import 'package:flutter/foundation.dart';

import '../models/manufacturer.dart';
import '../models/manufacturer_query.dart';
import '../models/page_result.dart';
import '../repositories/manufacturer_repository.dart';
import 'load_status.dart';

class ManufacturerListNotifier extends ChangeNotifier {
  final ManufacturerRepository _repository;
  ManufacturerListNotifier(this._repository);

  ManufacturerQuery _query = const ManufacturerQuery();
  PageResult<Manufacturer> _result = PageResult.empty();
  LoadStatus _status = LoadStatus.idle;
  String? _error;
  final Set<int> _selected = {};

  ManufacturerQuery get query => _query;
  PageResult<Manufacturer> get result => _result;
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

  Future<void> applyQuery(ManufacturerQuery next) async {
    _query = next;
    _selected.clear();
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
