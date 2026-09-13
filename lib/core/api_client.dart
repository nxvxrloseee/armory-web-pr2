import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart'; // kDebugMode, debugPrint

import 'api_exceptions.dart';
import 'config.dart';

Dio buildDio() {
  final dio = Dio(
    BaseOptions(
      baseUrl: apiBaseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 15),
      headers: {'Content-Type': 'application/json'},
      // Не бросать исключение на кодах 4xx — разберём их сами.
      validateStatus: (status) => status != null && status < 500,
    ),
  );
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        if (kDebugMode) {
          debugPrint('[API] → ${options.method} ${options.uri}');
        }
        return handler.next(options);
      },
      onResponse: (response, handler) {
        if (kDebugMode) {
          debugPrint('[API] ← ${response.statusCode} ${response.requestOptions.uri}');
        }
        // Коды 4xx попадают сюда, а не в onError, из-за validateStatus.
        final status = response.statusCode ?? 0;
        if (status >= 400) {
          // Просто написать `throw mapHttpError(...)` нельзя: dio перехватит
          // любое исключение из интерсептора и завернёт его в DioException
          // с типом unknown, а наш ApiException окажется спрятан внутри поля
          // error. Поэтому отправляем ответ по ветке ошибок сами, приложив
          // уже разобранное исключение.
          return handler.reject(
            DioException(
              requestOptions: response.requestOptions,
              response: response,
              type: DioExceptionType.badResponse,
              error: mapHttpError(status, response.data),
            ),
            true,
          );
        }
        return handler.next(response);
      },
      onError: (error, handler) {
        // Сюда приходят сетевые сбои, таймауты, коды 5xx и всё, что отклонил
        // обработчик выше.
        if (kDebugMode) {
          debugPrint('[API] сбой ${error.requestOptions.uri}: ${error.type}');
        }
        return handler.next(error);
      },
    ),
  );
  return dio;
}
