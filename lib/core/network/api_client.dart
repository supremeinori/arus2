import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/env.dart';
import '../storage/secure_store.dart';
import 'app_exception.dart';

final apiClientProvider = Provider<ApiClient>((ref) {
  final secureStore = ref.watch(secureStoreProvider);
  return ApiClient(secureStore: secureStore);
});

/// Client HTTP terpusat menggunakan library Dio.
/// Mengatur Base URL, menyisipkan Token JWT, dan menangani error jaringan.
class ApiClient {
  late final Dio _dio;
  final SecureStore secureStore;

  ApiClient({required this.secureStore, Dio? customDio}) {
    _dio = customDio ??
        Dio(
          BaseOptions(
            baseUrl: AppEnv.apiBaseUrl,
            connectTimeout: const Duration(seconds: 15),
            receiveTimeout: const Duration(seconds: 15),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              'Bypass-Tunnel-Reminder': 'true',
            },
          ),
        );

    // Interceptor: Otomatis tempel Bearer Token di setiap request
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await secureStore.getAccessToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (DioException error, handler) async {
          // Jika token ditolak/kedaluwarsa (401), bersihkan sesi login lokal
          if (error.response?.statusCode == 401) {
            await secureStore.clearTokens();
          }

          final appException = _mapDioError(error);
          return handler.reject(
            DioException(
              requestOptions: error.requestOptions,
              error: appException,
              message: appException.message,
              type: error.type,
              response: error.response,
            ),
          );
        },
      ),
    );
  }

  Dio get rawDio => _dio;

  void updateBaseUrl(String newUrl) {
    _dio.options.baseUrl = newUrl;
  }

  // --- HTTP Methods (GET, POST, PUT, PATCH, DELETE) ---

  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.get<T>(
        path,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.post<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Response<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.put<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Response<T>> patch<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.patch<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Response<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.delete<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Helper untuk mengekstrak error yang ramah pengguna
  AppException _handleError(DioException e) {
    if (e.error is AppException) return e.error as AppException;
    return _mapDioError(e);
  }

  AppException _mapDioError(DioException error) {
    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.sendTimeout ||
        error.type == DioExceptionType.receiveTimeout) {
      return AppException.timeout();
    }

    if (error.type == DioExceptionType.connectionError) {
      return AppException.network('Tidak dapat terhubung ke server ARUS (${AppEnv.apiBaseUrl}).');
    }

    final response = error.response;
    if (response != null && response.data is Map<String, dynamic>) {
      final data = response.data as Map<String, dynamic>;
      if (data.containsKey('error') && data['error'] is Map<String, dynamic>) {
        return AppException.fromServer(data['error'] as Map<String, dynamic>, response.statusCode);
      }
    }

    return AppException(
      response?.statusMessage ?? 'Terjadi kesalahan jaringan.',
      code: 'HTTP_${response?.statusCode ?? 500}',
      statusCode: response?.statusCode,
    );
  }
}
