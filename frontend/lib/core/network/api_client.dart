import 'package:dio/dio.dart';
import 'package:uuid/uuid.dart';
import '../constants/app_constants.dart';
import '../storage/token_storage.dart';
import 'api_exception.dart';

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;

  late final Dio dio;
  final TokenStorage _tokenStorage = TokenStorage();
  final Uuid _uuid = const Uuid();

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
          // 1. Attach Bearer Token
          final token = await _tokenStorage.getToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }

          // 2. Automatically generate Idempotency-Key for mutation requests if not present
          final method = options.method.toUpperCase();
          if (['POST', 'PUT', 'PATCH', 'DELETE'].contains(method)) {
            if (!options.headers.containsKey('Idempotency-Key')) {
              options.headers['Idempotency-Key'] = _uuid.v4();
            }
          }

          return handler.next(options);
        },
        onError: (DioException e, handler) {
          ApiException apiException;
          if (e.response?.data is Map<String, dynamic>) {
            apiException = ApiException.fromJson(
              e.response!.data as Map<String, dynamic>,
              e.response?.statusCode,
            );
          } else {
            apiException = ApiException(
              message: e.message ?? 'Koneksi ke server bermasalah.',
              statusCode: e.response?.statusCode,
            );
          }

          return handler.reject(
            DioException(
              requestOptions: e.requestOptions,
              error: apiException,
              response: e.response,
              type: e.type,
            ),
          );
        },
      ),
    );
  }

  // HTTP Helper Methods
  Future<Response> get(String path, {Map<String, dynamic>? queryParameters}) async {
    return dio.get(path, queryParameters: queryParameters);
  }

  Future<Response> post(String path, {dynamic data, Map<String, dynamic>? headers}) async {
    return dio.post(path, data: data, options: Options(headers: headers));
  }

  Future<Response> put(String path, {dynamic data, Map<String, dynamic>? headers}) async {
    return dio.put(path, data: data, options: Options(headers: headers));
  }

  Future<Response> patch(String path, {dynamic data, Map<String, dynamic>? headers}) async {
    return dio.patch(path, data: data, options: Options(headers: headers));
  }

  Future<Response> delete(String path, {Map<String, dynamic>? headers}) async {
    return dio.delete(path, options: Options(headers: headers));
  }
}
