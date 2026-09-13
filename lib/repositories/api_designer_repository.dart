import 'package:dio/dio.dart';

import '../core/api_exceptions.dart';
import '../models/designer.dart';
import '../models/designer_query.dart';
import '../models/page_result.dart';
import 'designer_repository.dart';
import 'repository_exceptions.dart';

class ApiDesignerRepository implements DesignerRepository {
  ApiDesignerRepository(this._dio);
  final Dio _dio;

  @override
  Future<PageResult<Designer>> find(DesignerQuery q) => guard(() async {
        final response = await _dio.get('/designers', queryParameters: q.toQueryParameters());
        final data = response.data as Map<String, dynamic>;
        return PageResult<Designer>(
          items: (data['items'] as List)
              .whereType<Map<String, dynamic>>()
              .map(Designer.fromJson)
              .toList(),
          page: data['page'] as int? ?? q.page,
          size: data['size'] as int? ?? q.size,
          total: data['total'] as int? ?? 0,
        );
      });

  @override
  Future<Designer?> findById(int id) async {
    try {
      return await guard(() async {
        final response = await _dio.get('/designers/$id');
        return Designer.fromJson(response.data as Map<String, dynamic>);
      });
    } on NotFoundException {
      return null;
    }
  }

  @override
  Future<List<Designer>> listAll() => guard(() async {
        final response = await _dio.get('/designers', queryParameters: {'size': '100'});
        final data = response.data as Map<String, dynamic>;
        return (data['items'] as List)
            .whereType<Map<String, dynamic>>()
            .map(Designer.fromJson)
            .toList();
      });

  Map<String, dynamic> _body(Designer d) =>
      {'fullName': d.fullName, 'country': d.country, 'activeSince': d.activeSince};

  @override
  Future<Designer> create(Designer draft) => guard(() async {
        final response = await _dio.post('/designers', data: _body(draft));
        return Designer.fromJson(response.data as Map<String, dynamic>);
      });

  @override
  Future<Designer> update(Designer designer) => guard(() async {
        final response = await _dio.put('/designers/${designer.id}', data: _body(designer));
        return Designer.fromJson(response.data as Map<String, dynamic>);
      });

  // Снаружи guard() — ConflictException появляется только после того, как
  // guard() сам разберёт DioException (см. api_weapon_repository.dart).
  Future<T> _rethrowConflict<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on ConflictException catch (e) {
      throw ReferentialIntegrityException(e.count, e.message);
    }
  }

  @override
  Future<void> softDelete(int id) => _rethrowConflict(() => guard(() => _dio.delete('/designers/$id')));

  @override
  Future<void> hardDelete(int id) => _rethrowConflict(
        () => guard(
          () => _dio.delete('/designers/$id', queryParameters: {'hard': 'true'}),
        ),
      );

  @override
  Future<void> restore(int id) => guard(() => _dio.post('/designers/$id/restore'));

  @override
  Future<int> deleteMany(List<int> ids) => guard(() async {
        final response = await _dio.post('/designers/bulk-delete', data: {'ids': ids});
        return (response.data as Map<String, dynamic>)['deleted'] as int? ?? 0;
      });
}
