import 'package:dio/dio.dart';

import '../core/api_exceptions.dart';
import '../models/client.dart';
import '../models/client_query.dart';
import '../models/page_result.dart';
import 'client_repository.dart';
import 'repository_exceptions.dart';

class ApiClientRepository implements ClientRepository {
  ApiClientRepository(this._dio);
  final Dio _dio;

  @override
  Future<PageResult<Client>> find(ClientQuery q) => guard(() async {
        final response = await _dio.get('/clients', queryParameters: q.toQueryParameters());
        final data = response.data as Map<String, dynamic>;
        return PageResult<Client>(
          items: (data['items'] as List)
              .whereType<Map<String, dynamic>>()
              .map(Client.fromJson)
              .toList(),
          page: data['page'] as int? ?? q.page,
          size: data['size'] as int? ?? q.size,
          total: data['total'] as int? ?? 0,
        );
      });

  @override
  Future<Client?> findById(int id) async {
    try {
      return await guard(() async {
        final response = await _dio.get('/clients/$id');
        return Client.fromJson(response.data as Map<String, dynamic>);
      });
    } on NotFoundException {
      return null;
    }
  }

  Map<String, dynamic> _body(Client c) => {
        'fullName': c.fullName,
        'email': c.email,
        'phone': c.phone,
        'licenseNumber': c.licenseNumber,
        'licenseIssuedAt': c.licenseIssuedAt.toIso8601String(),
        'licenseExpiresAt': c.licenseExpiresAt.toIso8601String(),
      };

  /// Ошибка уникальности почты приходит с сервера как 422 с полем `email` в
  /// `errors` — превращается обратно в [UniqueConstraintException], который
  /// ловит client_form_screen.dart, чтобы форма не менялась.
  Future<T> _rethrowEmailConflict<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on ValidationException catch (e) {
      final emailError = e.errors['email'];
      if (emailError != null) {
        throw UniqueConstraintException('email', emailError);
      }
      rethrow;
    }
  }

  @override
  Future<Client> create(Client draft) => _rethrowEmailConflict(() => guard(() async {
        final response = await _dio.post('/clients', data: _body(draft));
        return Client.fromJson(response.data as Map<String, dynamic>);
      }));

  @override
  Future<Client> update(Client client) => _rethrowEmailConflict(() => guard(() async {
        final response = await _dio.put('/clients/${client.id}', data: _body(client));
        return Client.fromJson(response.data as Map<String, dynamic>);
      }));

  @override
  Future<void> softDelete(int id) => guard(() => _dio.delete('/clients/$id'));

  @override
  Future<void> hardDelete(int id) =>
      guard(() => _dio.delete('/clients/$id', queryParameters: {'hard': 'true'}));

  @override
  Future<void> restore(int id) => guard(() => _dio.post('/clients/$id/restore'));

  @override
  Future<int> deleteMany(List<int> ids) => guard(() async {
        final response = await _dio.post('/clients/bulk-delete', data: {'ids': ids});
        return (response.data as Map<String, dynamic>)['deleted'] as int? ?? 0;
      });
}
