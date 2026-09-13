import 'package:dio/dio.dart';

import '../core/api_exceptions.dart';
import '../models/manufacturer.dart';
import '../models/manufacturer_query.dart';
import '../models/page_result.dart';
import 'manufacturer_repository.dart';
import 'repository_exceptions.dart';

class ApiManufacturerRepository implements ManufacturerRepository {
  ApiManufacturerRepository(this._dio);
  final Dio _dio;

  @override
  Future<PageResult<Manufacturer>> find(ManufacturerQuery q) => guard(() async {
        final response =
            await _dio.get('/manufacturers', queryParameters: q.toQueryParameters());
        final data = response.data as Map<String, dynamic>;
        return PageResult<Manufacturer>(
          items: (data['items'] as List)
              .whereType<Map<String, dynamic>>()
              .map(Manufacturer.fromJson)
              .toList(),
          page: data['page'] as int? ?? q.page,
          size: data['size'] as int? ?? q.size,
          total: data['total'] as int? ?? 0,
        );
      });

  @override
  Future<Manufacturer?> findById(int id) async {
    try {
      return await guard(() async {
        final response = await _dio.get('/manufacturers/$id');
        return Manufacturer.fromJson(response.data as Map<String, dynamic>);
      });
    } on NotFoundException {
      return null;
    }
  }

  /// Через тот же список, с большим размером страницы: для выпадающего поля
  /// формы отдельный эндпоинт не нужен, восьми-десяти производителей на
  /// одну страницу вполне достаточно с запасом.
  @override
  Future<List<Manufacturer>> listAll() => guard(() async {
        final response = await _dio.get('/manufacturers', queryParameters: {'size': '100'});
        final data = response.data as Map<String, dynamic>;
        return (data['items'] as List)
            .whereType<Map<String, dynamic>>()
            .map(Manufacturer.fromJson)
            .toList();
      });

  Map<String, dynamic> _body(Manufacturer m) =>
      {'name': m.name, 'country': m.country, 'founded': m.founded};

  @override
  Future<Manufacturer> create(Manufacturer draft) => guard(() async {
        final response = await _dio.post('/manufacturers', data: _body(draft));
        return Manufacturer.fromJson(response.data as Map<String, dynamic>);
      });

  @override
  Future<Manufacturer> update(Manufacturer manufacturer) => guard(() async {
        final response = await _dio.put('/manufacturers/${manufacturer.id}', data: _body(manufacturer));
        return Manufacturer.fromJson(response.data as Map<String, dynamic>);
      });

  /// 409 с сервера — тот же случай, что раньше ловил
  /// [ReferentialIntegrityException] у локального репозитория: экраны
  /// (manufacturer_detail_screen.dart) продолжают ловить именно его. Должен
  /// оборачивать guard() снаружи — ConflictException появляется только
  /// после того, как guard() сам разберёт DioException.
  Future<T> _rethrowConflict<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on ConflictException catch (e) {
      throw ReferentialIntegrityException(e.count, e.message);
    }
  }

  @override
  Future<void> softDelete(int id) => _rethrowConflict(() => guard(() => _dio.delete('/manufacturers/$id')));

  @override
  Future<void> hardDelete(int id) => _rethrowConflict(
        () => guard(
          () => _dio.delete('/manufacturers/$id', queryParameters: {'hard': 'true'}),
        ),
      );

  @override
  Future<void> restore(int id) => guard(() => _dio.post('/manufacturers/$id/restore'));

  @override
  Future<int> deleteMany(List<int> ids) => guard(() async {
        final response = await _dio.post('/manufacturers/bulk-delete', data: {'ids': ids});
        return (response.data as Map<String, dynamic>)['deleted'] as int? ?? 0;
      });
}
