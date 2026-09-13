import 'package:dio/dio.dart';

/// Между сетевым слоем и остальным приложением стоит набор собственных
/// исключений — виджеты не должны знать о существовании Dio (задание ПР4,
/// раздел 2.3).
sealed class ApiException implements Exception {
  final String message;
  const ApiException(this.message);

  @override
  String toString() => message;
}

/// Нет соединения, таймаут, сервер недоступен, заблокировано CORS.
class NetworkException extends ApiException {
  const NetworkException([super.message = 'Сервер недоступен. Проверьте соединение.']);
}

class UnauthorizedException extends ApiException {
  const UnauthorizedException([super.message = 'Требуется вход в систему.']);
}

class ForbiddenException extends ApiException {
  const ForbiddenException([super.message = 'Недостаточно прав для этого действия.']);
}

class NotFoundException extends ApiException {
  const NotFoundException([super.message = 'Запись не найдена.']);
}

/// 409 — нарушено ограничение целостности. [count], если сервер его прислал
/// (наш — присылает для производителя/категории/конструктора), нужен, чтобы
/// восстановить [ReferentialIntegrityException] с тем же числом, что
/// показывали экраны до перехода на API.
class ConflictException extends ApiException {
  final int count;
  const ConflictException(super.message, {this.count = 0});
}

/// 422 — ошибки валидации по полям. Ключи в [errors] совпадают с именами
/// полей модели.
class ValidationException extends ApiException {
  final Map<String, String> errors;
  const ValidationException(super.message, this.errors);
}

class ServerException extends ApiException {
  const ServerException([super.message = 'Ошибка на сервере. Попробуйте позже.']);
}

ApiException mapHttpError(int status, dynamic body) {
  final message = (body is Map && body['message'] is String) ? body['message'] as String : null;
  return switch (status) {
    401 => UnauthorizedException(message ?? 'Требуется вход в систему.'),
    403 => ForbiddenException(message ?? 'Недостаточно прав для этого действия.'),
    404 => NotFoundException(message ?? 'Запись не найдена.'),
    409 => ConflictException(
        message ?? 'Операция невозможна.',
        count: (body is Map && body['count'] is int) ? body['count'] as int : 0,
      ),
    422 => ValidationException(
        message ?? 'Ошибка валидации',
        (body is Map && body['errors'] is Map)
            ? (body['errors'] as Map).map((k, v) => MapEntry('$k', '$v'))
            : const {},
      ),
    _ => ServerException(message ?? 'Неизвестная ошибка (код $status).'),
  };
}

ApiException mapDioError(DioException e) {
  // Если исключение уже разобрал интерсептор (см. api_client.dart), повторно
  // его не разбираем — иначе ошибка 422 придёт в приложение как
  // ServerException, и `on ValidationException` никогда не сработает.
  final existing = e.error;
  if (existing is ApiException) return existing;
  return switch (e.type) {
    DioExceptionType.connectionTimeout ||
    DioExceptionType.sendTimeout ||
    DioExceptionType.receiveTimeout =>
      const NetworkException('Сервер не ответил вовремя.'),
    DioExceptionType.connectionError => const NetworkException(
        'Не удалось соединиться с сервером. '
        'Если сервер запущен, откройте консоль браузера и проверьте наличие ошибки CORS.',
      ),
    DioExceptionType.cancel => const NetworkException('Запрос отменён.'),
    _ => const ServerException(),
  };
}

/// Каждое обращение к сети оборачивается этой функцией — единственная её
/// задача — не выпустить наружу [DioException]: в приложение должны попадать
/// только исключения предметной области.
Future<T> guard<T>(Future<T> Function() action) async {
  try {
    return await action();
  } on DioException catch (e) {
    throw mapDioError(e);
  }
}
