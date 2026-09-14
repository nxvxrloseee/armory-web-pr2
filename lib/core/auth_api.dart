import 'package:dio/dio.dart';

import '../models/app_user.dart';
import 'api_exceptions.dart';

class LoginResult {
  const LoginResult({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresIn,
    required this.user,
  });

  final String accessToken;
  final String refreshToken;
  final int expiresIn;
  final AppUser user;

  factory LoginResult.fromJson(Map<String, dynamic> json) => LoginResult(
        accessToken: json['accessToken']?.toString() ?? '',
        refreshToken: json['refreshToken']?.toString() ?? '',
        expiresIn: json['expiresIn'] is int ? json['expiresIn'] as int : 900,
        user: AppUser.fromJson(json['user'] as Map<String, dynamic>),
      );
}

/// Тело регистрации — покупатель (единственная роль, доступная для
/// самостоятельной регистрации, см. armory_api/internal/auth: продавец и
/// администратор заводятся отдельно, не публичной формой).
class RegisterInput {
  const RegisterInput({
    required this.username,
    required this.password,
    required this.fullName,
    required this.email,
    required this.phone,
    required this.birthDate,
    required this.passportSeries,
    required this.passportNumber,
    required this.licenseNumber,
    required this.licenseIssuedAt,
    required this.licenseExpiresAt,
  });

  final String username;
  final String password;
  final String fullName;
  final String email;
  final String phone;
  final DateTime birthDate;
  final String passportSeries;
  final String passportNumber;
  final String licenseNumber;
  final DateTime licenseIssuedAt;
  final DateTime licenseExpiresAt;

  Map<String, dynamic> toJson() => {
        'username': username,
        'password': password,
        'fullName': fullName,
        'email': email,
        'phone': phone,
        'birthDate': _date(birthDate),
        'passportSeries': passportSeries,
        'passportNumber': passportNumber,
        'licenseNumber': licenseNumber,
        'licenseIssuedAt': licenseIssuedAt.toUtc().toIso8601String(),
        'licenseExpiresAt': licenseExpiresAt.toUtc().toIso8601String(),
      };

  static String _date(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}

/// Тонкая обёртка над /api/auth/* — используется только [AuthNotifier],
/// остальное приложение об этом классе не знает (тот же принцип, что и
/// Api*Repository у остальных пяти сущностей).
class AuthApi {
  AuthApi(this._dio);
  final Dio _dio;

  Future<LoginResult> login(String username, String password) => guard(() async {
        final r = await _dio.post('/auth/login', data: {'username': username, 'password': password});
        return LoginResult.fromJson(r.data as Map<String, dynamic>);
      });

  Future<LoginResult> register(RegisterInput input) => guard(() async {
        final r = await _dio.post('/auth/register', data: input.toJson());
        return LoginResult.fromJson(r.data as Map<String, dynamic>);
      });

  Future<LoginResult> refresh(String refreshToken) => guard(() async {
        final r = await _dio.post('/auth/refresh', data: {'refreshToken': refreshToken});
        return LoginResult.fromJson(r.data as Map<String, dynamic>);
      });

  Future<AppUser> me(String accessToken) => guard(() async {
        final r = await _dio.get(
          '/auth/me',
          options: Options(headers: {'Authorization': 'Bearer $accessToken'}),
        );
        return AppUser.fromJson(r.data as Map<String, dynamic>);
      });

  Future<void> logout(String accessToken) => guard(() async {
        await _dio.post(
          '/auth/logout',
          options: Options(headers: {'Authorization': 'Bearer $accessToken'}),
        );
      });
}
