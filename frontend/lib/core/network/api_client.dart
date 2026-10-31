import 'package:dio/dio.dart';

import '../constants/app_constants.dart';
import '../storage/token_storage.dart';
import 'api_exception.dart';

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;

  late final Dio dio;
  final TokenStorage _tokenStorage = TokenStorage();

  ApiClient._internal() {
    dio = Dio(
      BaseOptions(
        baseUrl: AppConstants.apiBaseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      ),
    );

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _tokenStorage.getToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (DioException e, handler) {
          final errorMessage = _extractErrorMessage(e);
          return handler.reject(
            DioException(
              requestOptions: e.requestOptions,
              error: ApiException(
                message: errorMessage,
                statusCode: e.response?.statusCode,
                errors: e.response?.data is Map
                    ? e.response?.data['errors']
                    : null,
              ),
              response: e.response,
              type: e.type,
            ),
          );
        },
      ),
    );
  }

  String _extractErrorMessage(DioException e) {
    if (e.response?.data is Map) {
      final data = e.response!.data as Map;
      if (data.containsKey('message')) {
        return data['message'].toString();
      }
    }
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Koneksi ke server timeout. Silakan periksa jaringan Anda.';
      case DioExceptionType.badResponse:
        return 'Terjadi kesalahan pada server (${e.response?.statusCode}).';
      case DioExceptionType.connectionError:
        return 'Tidak dapat terhubung ke server Meowtopia. Pastikan backend aktif.';
      default:
        return 'Terjadi kesalahan tak terduga: ${e.message}';
    }
  }

  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      return await dio.get(path, queryParameters: queryParameters);
    } on DioException catch (e) {
      throw (e.error is ApiException)
          ? e.error as ApiException
          : ApiException(message: e.message ?? 'Unknown error');
    }
  }

  Future<Response> post(String path, {dynamic data}) async {
    try {
      return await dio.post(path, data: data);
    } on DioException catch (e) {
      throw (e.error is ApiException)
          ? e.error as ApiException
          : ApiException(message: e.message ?? 'Unknown error');
    }
  }

  Future<Response> put(String path, {dynamic data}) async {
    try {
      return await dio.put(path, data: data);
    } on DioException catch (e) {
      throw (e.error is ApiException)
          ? e.error as ApiException
          : ApiException(message: e.message ?? 'Unknown error');
    }
  }

  Future<Response> delete(String path) async {
    try {
      return await dio.delete(path);
    } on DioException catch (e) {
      throw (e.error is ApiException)
          ? e.error as ApiException
          : ApiException(message: e.message ?? 'Unknown error');
    }
  }
}
