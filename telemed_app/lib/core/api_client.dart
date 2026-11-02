import 'package:dio/dio.dart';
import '../config/api_config.dart';
import 'token_storage.dart';

class ApiClient {
  ApiClient._() {
    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await TokenStorage.read();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (e, handler) async {
        // 401 = token missing or expired (Fix 3) → force re-login
        if (e.response?.statusCode == 401) {
          await TokenStorage.clear();
        }
        handler.next(e);
      },
    ));
  }

  static final ApiClient instance = ApiClient._();

  final Dio dio = Dio(BaseOptions(
    baseUrl: ApiConfig.baseUrl,
    connectTimeout: ApiConfig.timeout,
    receiveTimeout: ApiConfig.timeout,
    headers: {'Content-Type': 'application/json'},
  ));

  static String errorMessage(Object e) {
    if (e is DioException) {
      final data = e.response?.data;
      if (data is Map && data['error'] != null) return data['error'].toString();
      if (e.type == DioExceptionType.connectionError) {
        return 'Cannot reach the server. Check your internet connection.';
      }
      if (e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.connectionTimeout) {
        return 'The server took too long to respond. Please try again.';
      }
    }
    return 'Something went wrong. Please try again.';
  }
}