import 'package:dio/dio.dio';

class ApiClient {
  static final Dio dio = Dio(
    BaseOptions(
      // Hosted on Render
      baseUrl: 'https://myharur.onrender.com/api/v1',
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {
        'Content-Type': 'application/json',
      },
    ),
  );
}
