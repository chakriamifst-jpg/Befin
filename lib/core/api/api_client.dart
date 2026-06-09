import 'package:dio/dio.dart';
import '../auth/auth_storage.dart';

class ApiClient {
  static final Dio _dio = _build();
  static Dio get dio => _dio;

  static Dio _build() {
    final d = Dio(BaseOptions(
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {'Content-Type': 'application/json'},
    ));

    // Auto-attach JWT Bearer token to every request
    d.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await AuthStorage.getToken();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (err, handler) async {
        // Token expired → clear session
        if (err.response?.statusCode == 401) {
          await AuthStorage.clear();
        }
        handler.next(err);
      },
    ));

    return d;
  }
}
