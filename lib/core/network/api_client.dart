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

    // [FLOW NET 1] Interceptor onRequest: tiap mau nembak API, ambil token dari secure_store.dart
    // lalu otomatis ditempel ke header Authorization biar server tahu user ini udah login sah.
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
          // [FLOW NET 2] Kalau server balas 401 (token basi/ditolak), langsung sapu bersih token di HP,
          // terus error mentahnya dilempar ke _mapDioError biar diubah jadi AppException yang ramah.
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

  // [FLOW NET 3] Pembungkus GET/POST/PUT/PATCH/DELETE biar semua Repository cukup lewat 1 pintu ini.
  // Kalau ada error internet/server, semuanya bermuara ke _handleError() di bawah.

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

  // [FLOW NET 4] Muara semua error jaringan (timeout / putus / error server),
  // diterjemahin ke AppException (app_exception.dart) biar pesan ke user nggak pakai bahasa teknis.
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
