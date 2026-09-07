import '../models/page_result.dart';
import '../models/weapon.dart';
import '../models/weapon_query.dart';

abstract interface class WeaponRepository {
  Future<PageResult<Weapon>> find(WeaponQuery query);
  Future<Weapon?> findById(int id);
  Future<void> softDelete(int id);
  Future<void> hardDelete(int id);
  Future<void> restore(int id);
  Future<int> deleteMany(List<int> ids);
}
