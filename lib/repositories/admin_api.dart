import 'package:dio/dio.dart';

import '../core/api_exceptions.dart';
import '../models/role.dart';

class AdminUserRow {
  const AdminUserRow({required this.id, required this.username, required this.fullName, required this.role});
  final int id;
  final String username;
  final String fullName;
  final Role role;

  factory AdminUserRow.fromJson(Map<String, dynamic> json) => AdminUserRow(
        id: json['id'] as int,
        username: json['username']?.toString() ?? '',
        fullName: json['fullName']?.toString() ?? '',
        role: Role.fromWire(json['role']?.toString() ?? 'buyer'),
      );
}

/// Единственный экран, недоступный никому, кроме администратора — сервер
/// сам это перепроверяет (RequireRole(RoleAdmin) на /api/users и
/// /api/admin/stats), эта обёртка только даёт клиенту типизированный доступ.
class AdminApi {
  AdminApi(this._dio);
  final Dio _dio;

  Future<List<AdminUserRow>> listUsers() => guard(() async {
        final response = await _dio.get('/users');
        final data = response.data as Map<String, dynamic>;
        return (data['items'] as List).whereType<Map<String, dynamic>>().map(AdminUserRow.fromJson).toList();
      });

  Future<void> setRole(int userId, Role role) =>
      guard(() => _dio.put('/users/$userId/role', data: {'role': role.wireValue}));

  Future<Map<String, dynamic>> stats() => guard(() async {
        final response = await _dio.get('/admin/stats');
        return response.data as Map<String, dynamic>;
      });
}
