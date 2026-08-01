import 'package:dio/dio.dart';

class ApiException implements DioException {
  @override
  final String message;
  
  @override
  final RequestOptions requestOptions;

  @override
  final Response? response;

  @override
  final DioExceptionType type;

  @override
  final Object? error;

  @override
  final StackTrace stackTrace;

  @override
  DioExceptionReadableStringBuilder? stringBuilder;

  ApiException(this.message, this.requestOptions, [this.response, this.type = DioExceptionType.unknown, this.error, StackTrace? stackTrace]) 
    : stackTrace = stackTrace ?? StackTrace.empty;
    
  @override
  String toString() => message;
  
  @override
  DioException copyWith({
    RequestOptions? requestOptions,
    Response? response,
    DioExceptionType? type,
    Object? error,
    StackTrace? stackTrace,
    String? message,
  }) {
    return ApiException(
      message ?? this.message,
      requestOptions ?? this.requestOptions,
      response ?? this.response,
      type ?? this.type,
      error ?? this.error,
      stackTrace ?? this.stackTrace,
    );
  }
}

class ApiClient {
  static late Dio dio;

  static void init() {
    dio = Dio(BaseOptions(
      baseUrl: 'https://myharur.onrender.com/api/v1',
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      headers: {'Content-Type': 'application/json'},
    ));

    dio.interceptors.add(InterceptorsWrapper(
      onError: (DioException e, handler) {
        String msg = 'Something went wrong. Please try again.';
        if (e.type == DioExceptionType.connectionTimeout || e.type == DioExceptionType.receiveTimeout) {
          msg = 'Connection timed out. Please check your internet.';
        } else if (e.type == DioExceptionType.connectionError || e.type == DioExceptionType.unknown) {
          msg = 'Network unreachable. Please check your connection.';
        } else if (e.response != null) {
          final statusCode = e.response?.statusCode;
          if (statusCode == 400 || statusCode == 422) {
            msg = e.response?.data['detail']?.toString() ?? 'Validation error. Please check your input.';
          } else if (statusCode == 401 || statusCode == 403) {
            msg = 'Unauthorized access.';
          } else if (statusCode == 404) {
            msg = 'Resource not found.';
          } else if (statusCode != null && statusCode >= 500) {
            msg = 'Server error. Our team has been notified.';
          }
        }
        return handler.reject(ApiException(msg, e.requestOptions, e.response, e.type, e.error, e.stackTrace));
      },
    ));
  }

  static void setToken(String token) {
    dio.options.headers['Authorization'] = 'Bearer $token';
  }

  static void clearToken() {
    dio.options.headers.remove('Authorization');
  }
}
