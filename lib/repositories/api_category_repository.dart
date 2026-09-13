import 'package:dio/dio.dart';

import '../core/api_exceptions.dart';
import '../models/category.dart';
import '../models/category_query.dart';
import '../models/page_result.dart';
import 'category_repository.dart';
import 'repository_exceptions.dart';

class ApiCategoryRepository implements CategoryRepository {
  ApiCategoryRepository(this._dio);
  final Dio _dio;

  @override
  Future<PageResult<Category>> find(CategoryQuery q) => guard(() async {
        final response = await _dio.get('/categories', queryParameters: q.toQueryParameters());
        final data = response.data as Map<String, dynamic>;
        return PageResult<Category>(
          items: (data['items'] as List)
              .whereType<Map<String, dynamic>>()
              .map(Category.fromJson)
              .toList(),
          page: data['page'] as int? ?? q.page,
          size: data['size'] as int? ?? q.size,
          total: data['total'] as int? ?? 0,
        );
      });

  @override
  Future<Category?> findById(int id) async {
    try {
      return await guard(() async {
        final response = await _dio.get('/categories/$id');
        return Category.fromJson(response.data as Map<String, dynamic>);
      });
    } on NotFoundException {
      return null;
    }
  }

  @override
  Future<List<Category>> listAll() => guard(() async {
        final response = await _dio.get('/categories', queryParameters: {'size': '100'});
        final data = response.data as Map<String, dynamic>;
        return (data['items'] as List)
            .whereType<Map<String, dynamic>>()
            .map(Category.fromJson)
            .toList();
      });

  @override
  Future<Category> create(Category draft) => guard(() async {
        final response = await _dio.post('/categories', data: {'name': draft.name});
        return Category.fromJson(response.data as Map<String, dynamic>);
      });

  @override
  Future<Category> update(Category category) => guard(() async {
        final response =
            await _dio.put('/categories/${category.id}', data: {'name': category.name});
        return Category.fromJson(response.data as Map<String, dynamic>);
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
  Future<void> softDelete(int id) => _rethrowConflict(() => guard(() => _dio.delete('/categories/$id')));

  @override
  Future<void> hardDelete(int id) => _rethrowConflict(
        () => guard(
          () => _dio.delete('/categories/$id', queryParameters: {'hard': 'true'}),
        ),
      );

  @override
  Future<void> restore(int id) => guard(() => _dio.post('/categories/$id/restore'));

  @override
  Future<int> deleteMany(List<int> ids) => guard(() async {
        final response = await _dio.post('/categories/bulk-delete', data: {'ids': ids});
        return (response.data as Map<String, dynamic>)['deleted'] as int? ?? 0;
      });
}
