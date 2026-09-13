import 'package:dio/dio.dart';

import '../core/api_exceptions.dart';
import '../models/page_result.dart';
import '../models/weapon.dart';
import '../models/weapon_query.dart';
import 'repository_exceptions.dart';
import 'weapon_repository.dart';

/// Единственное место, где меняется доступ к оружию при переходе на сервер
/// (задание ПР4, раздел 2.4) — интерфейс [WeaponRepository] и все экраны,
/// которые на него ссылаются, остаются как были.
class ApiWeaponRepository implements WeaponRepository {
  ApiWeaponRepository(this._dio);
  final Dio _dio;

  @override
  Future<PageResult<Weapon>> find(WeaponQuery q) => guard(() async {
        final response = await _dio.get('/weapons', queryParameters: q.toQueryParameters());
        final data = response.data as Map<String, dynamic>;
        return PageResult<Weapon>(
          items: (data['items'] as List)
              .whereType<Map<String, dynamic>>()
              .map(Weapon.fromJson)
              .toList(),
          page: data['page'] as int? ?? q.page,
          size: data['size'] as int? ?? q.size,
          total: data['total'] as int? ?? 0,
        );
      });

  // guard() unwraps DioException into ApiException только в своём catch —
  // значит on NotFoundException должен стоять СНАРУЖИ guard(), а не внутри
  // его action-колбэка: внутри в момент сбоя ещё летит сырой DioException.
  @override
  Future<Weapon?> findById(int id) async {
    try {
      return await guard(() async {
        final response = await _dio.get('/weapons/$id');
        return Weapon.fromJson(response.data as Map<String, dynamic>);
      });
    } on NotFoundException {
      return null;
    }
  }

  Map<String, dynamic> _body(Weapon w) => {
        'name': w.name,
        'sku': w.sku,
        'year': w.year,
        'caliber': w.caliber,
        'manufacturerId': w.manufacturerId,
        'categoryIds': w.categoryIds,
        'designerIds': w.designerIds,
        'price': w.price,
        'stockTotal': w.stockTotal,
        'stockAvailable': w.stockAvailable,
      };

  /// Ошибка уникальности артикула приходит с сервера как 422 с полем `sku`
  /// в `errors` — здесь она превращается обратно в тот же
  /// [UniqueConstraintException], который ловит weapon_form_screen.dart,
  /// чтобы форма не менялась. Снаружи guard(), по той же причине, что и в
  /// findById: ValidationException появляется только после того, как
  /// guard() сам разберёт DioException.
  Future<T> _rethrowSkuConflict<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on ValidationException catch (e) {
      final skuError = e.errors['sku'];
      if (skuError != null) {
        throw UniqueConstraintException('sku', skuError);
      }
      rethrow;
    }
  }

  @override
  Future<Weapon> create(Weapon draft) => _rethrowSkuConflict(() => guard(() async {
        final response = await _dio.post('/weapons', data: _body(draft));
        return Weapon.fromJson(response.data as Map<String, dynamic>);
      }));

  @override
  Future<Weapon> update(Weapon weapon) => _rethrowSkuConflict(() => guard(() async {
        final response = await _dio.put('/weapons/${weapon.id}', data: _body(weapon));
        return Weapon.fromJson(response.data as Map<String, dynamic>);
      }));

  @override
  Future<void> softDelete(int id) => guard(() => _dio.delete('/weapons/$id'));

  @override
  Future<void> hardDelete(int id) =>
      guard(() => _dio.delete('/weapons/$id', queryParameters: {'hard': 'true'}));

  @override
  Future<void> restore(int id) => guard(() => _dio.post('/weapons/$id/restore'));

  @override
  Future<int> deleteMany(List<int> ids) => guard(() async {
        final response = await _dio.post('/weapons/bulk-delete', data: {'ids': ids});
        return (response.data as Map<String, dynamic>)['deleted'] as int? ?? 0;
      });
}
