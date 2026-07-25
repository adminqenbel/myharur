import 'package:dio/dio.dart';

class ApiClient {
  static final Dio dio = _createDio();

  static Dio _createDio() {
    var dio = Dio(BaseOptions(
      baseUrl: 'https://myharur.onrender.com/api/v1',
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      headers: {'Content-Type': 'application/json'},
    ));

    dio.interceptors.add(InterceptorsWrapper(
      onError: (DioException e, handler) {
        // We will just pass the error along and handle it safely in the UI
        return handler.next(e);
      },
    ));
    
    return dio;
  }
}
