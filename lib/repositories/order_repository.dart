import 'package:dio/dio.dart';

import '../core/api_exceptions.dart';
import '../models/order.dart';
import '../models/page_result.dart';

/// Список заказов у сервера уже отфильтрован по роли (покупатель видит
/// только свои — см. armory_api/internal/orders: clientIDOf), поэтому
/// клиенту не нужен собственный Query-класс, как у остальных пяти
/// сущностей — только страница.
class OrderRepository {
  OrderRepository(this._dio);
  final Dio _dio;

  Future<PageResult<Order>> find({int page = 1, int size = 10}) => guard(() async {
        final response = await _dio.get('/orders', queryParameters: {'page': page, 'size': size});
        final data = response.data as Map<String, dynamic>;
        return PageResult<Order>(
          items: (data['items'] as List).whereType<Map<String, dynamic>>().map(Order.fromJson).toList(),
          page: data['page'] as int? ?? page,
          size: data['size'] as int? ?? size,
          total: data['total'] as int? ?? 0,
        );
      });

  /// Бросает [ConflictException], если у модели нет свободных экземпляров.
  Future<Order> create(int weaponId) => guard(() async {
        final response = await _dio.post('/orders', data: {'weaponId': weaponId});
        return Order.fromJson(response.data as Map<String, dynamic>);
      });

  Future<Order> cancel(int id) => guard(() async {
        final response = await _dio.post('/orders/$id/cancel');
        return Order.fromJson(response.data as Map<String, dynamic>);
      });

  Future<Order> pickup(int id, String serialNumber) => guard(() async {
        final response = await _dio.post('/orders/$id/pickup', data: {'serialNumber': serialNumber});
        return Order.fromJson(response.data as Map<String, dynamic>);
      });
}
