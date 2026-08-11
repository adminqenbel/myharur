import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiConfig {
  static const String myharurApiUrl = String.fromEnvironment(
    'MYHARUR_API_URL',
    defaultValue: 'https://myharur.onrender.com/api/v1',
  );

  static const String qenbelIdentityUrl = String.fromEnvironment(
    'QENBEL_IDENTITY_URL',
    defaultValue: 'https://qenbel.onrender.com',
  );
}

class ApiClient {
  static late Dio dio;
  static const _storage = FlutterSecureStorage();

  static void init() {
    dio = Dio(BaseOptions(
      baseUrl: ApiConfig.myharurApiUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      headers: {'Content-Type': 'application/json'},
    ));

    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _storage.read(key: 'qenbel_access_token');
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onError: (DioException e, handler) async {
        if (e.response?.statusCode == 401) {
          final refreshToken = await _storage.read(key: 'qenbel_refresh_token');
          if (refreshToken != null && refreshToken.isNotEmpty) {
            try {
              final refreshDio = Dio();
              final response = await refreshDio.post(
                '${ApiConfig.qenbelIdentityUrl}/auth/refresh',
                data: {'refresh_token': refreshToken},
              );
              final newAccessToken = response.data['access_token'] as String;
              final newRefreshToken = response.data['refresh_token'] as String;

              await _storage.write(key: 'qenbel_access_token', value: newAccessToken);
              await _storage.write(key: 'qenbel_refresh_token', value: newRefreshToken);

              e.requestOptions.headers['Authorization'] = 'Bearer $newAccessToken';
              final cloneReq = await dio.fetch(e.requestOptions);
              return handler.resolve(cloneReq);
            } catch (_) {
              await _storage.deleteAll();
            }
          }
        }
        return handler.next(e);
      },
    ));
  }

  static Future<void> saveTokens(String accessToken, String refreshToken) async {
    await _storage.write(key: 'qenbel_access_token', value: accessToken);
    await _storage.write(key: 'qenbel_refresh_token', value: refreshToken);
    dio.options.headers['Authorization'] = 'Bearer $accessToken';
  }

  static Future<void> clearTokens() async {
    await _storage.deleteAll();
    dio.options.headers.remove('Authorization');
  }
}
