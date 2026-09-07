import '../models/manufacturer.dart';
import '../models/manufacturer_query.dart';
import '../models/page_result.dart';

abstract interface class ManufacturerRepository {
  Future<PageResult<Manufacturer>> find(ManufacturerQuery query);
  Future<Manufacturer?> findById(int id);

  /// Полный список действующих производителей — нужен спискам оружия для
  /// выпадающего фильтра по производителю.
  Future<List<Manufacturer>> listAll();

  Future<void> softDelete(int id);
  Future<void> hardDelete(int id);
  Future<void> restore(int id);
  Future<int> deleteMany(List<int> ids);
}
