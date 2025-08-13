import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../core/constants/api_constants.dart';
import '../models/api_models.dart';

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;
  ApiClient._internal();

  late final Dio _dio;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  String? _cachedToken;
  String? _cachedRefreshToken;

  void initialize() {
    _dio = Dio(BaseOptions(
      baseUrl: ApiConstants.baseUrl,
      connectTimeout:
          const Duration(milliseconds: ApiConstants.connectionTimeoutMs),
      receiveTimeout:
          const Duration(milliseconds: ApiConstants.receiveTimeoutMs),
      sendTimeout: const Duration(milliseconds: ApiConstants.sendTimeoutMs),
      headers: {
        ApiConstants.contentTypeHeader: 'application/json',
        ApiConstants.acceptHeader: 'application/json',
        ApiConstants.userAgentHeader: 'Sahayak-Flutter-App/1.0.0',
      },
    ));

    // Add interceptors
    _dio.interceptors.add(_createAuthInterceptor());
    _dio.interceptors.add(_createLoggingInterceptor());
    _dio.interceptors.add(_createRetryInterceptor());
  }

  InterceptorsWrapper _createAuthInterceptor() {
    return InterceptorsWrapper(
      onRequest: (options, handler) async {
        // Skip auth for certain endpoints
        if (_isPublicEndpoint(options.path)) {
          handler.next(options);
          return;
        }

        // Add auth token
        final token = await _getAccessToken();
        if (token != null) {
          options.headers[ApiConstants.authorizationHeader] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (error, handler) async {
        // Handle token refresh on 401
        if (error.response?.statusCode == 401 &&
            !_isRefreshTokenEndpoint(error.requestOptions.path)) {
          try {
            await _refreshAccessToken();
            // Retry the original request
            final response = await _dio.request(
              error.requestOptions.path,
              data: error.requestOptions.data,
              queryParameters: error.requestOptions.queryParameters,
              options: Options(
                method: error.requestOptions.method,
                headers: error.requestOptions.headers,
              ),
            );
            return handler.resolve(response);
          } catch (e) {
            // Refresh failed, redirect to login
            await _clearTokens();
            handler.next(error);
          }
        } else {
          handler.next(error);
        }
      },
    );
  }

  InterceptorsWrapper _createLoggingInterceptor() {
    return InterceptorsWrapper(
      onRequest: (options, handler) {
        print('🌐 API Request: ${options.method} ${options.path}');
        if (options.data != null) {
          print('📤 Request Data: ${options.data}');
        }
        handler.next(options);
      },
      onResponse: (response, handler) {
        print(
            '✅ API Response: ${response.statusCode} ${response.requestOptions.path}');
        print('📥 Response Data: ${response.data}');
        handler.next(response);
      },
      onError: (error, handler) {
        print(
            '❌ API Error: ${error.response?.statusCode} ${error.requestOptions.path}');
        print('Error Data: ${error.response?.data}');
        handler.next(error);
      },
    );
  }

  InterceptorsWrapper _createRetryInterceptor() {
    return InterceptorsWrapper(
      onError: (error, handler) async {
        if (_shouldRetry(error)) {
          try {
            await Future.delayed(
                const Duration(milliseconds: ApiConstants.retryDelayMs));
            final response = await _dio.request(
              error.requestOptions.path,
              data: error.requestOptions.data,
              queryParameters: error.requestOptions.queryParameters,
              options: Options(
                method: error.requestOptions.method,
                headers: error.requestOptions.headers,
              ),
            );
            return handler.resolve(response);
          } catch (e) {
            handler.next(error);
          }
        } else {
          handler.next(error);
        }
      },
    );
  }

  bool _isPublicEndpoint(String path) {
    final publicEndpoints = [
      ApiConstants.login,
      ApiConstants.register,
      ApiConstants.resetPassword,
      ApiConstants.healthCheck,
      ApiConstants.readinessCheck,
    ];
    return publicEndpoints.any((endpoint) => path.contains(endpoint));
  }

  bool _isRefreshTokenEndpoint(String path) {
    return path.contains(ApiConstants.refreshToken);
  }

  bool _shouldRetry(DioException error) {
    return error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.sendTimeout ||
        (error.response?.statusCode != null &&
            error.response!.statusCode! >= 500);
  }

  Future<String?> _getAccessToken() async {
    _cachedToken ??= await _storage.read(key: ApiConstants.accessTokenKey);
    return _cachedToken;
  }

  Future<String?> _getRefreshToken() async {
    _cachedRefreshToken ??=
        await _storage.read(key: ApiConstants.refreshTokenKey);
    return _cachedRefreshToken;
  }

  Future<void> _storeTokens(String accessToken, String refreshToken) async {
    _cachedToken = accessToken;
    _cachedRefreshToken = refreshToken;
    await _storage.write(key: ApiConstants.accessTokenKey, value: accessToken);
    await _storage.write(
        key: ApiConstants.refreshTokenKey, value: refreshToken);
  }

  Future<void> _clearTokens() async {
    _cachedToken = null;
    _cachedRefreshToken = null;
    await _storage.delete(key: ApiConstants.accessTokenKey);
    await _storage.delete(key: ApiConstants.refreshTokenKey);
  }

  Future<void> _refreshAccessToken() async {
    final refreshToken = await _getRefreshToken();
    if (refreshToken == null) {
      throw ApiError(message: 'No refresh token available');
    }

    final response = await _dio.post(
      ApiConstants.refreshToken,
      data: {'refreshToken': refreshToken},
      options: Options(headers: {ApiConstants.authorizationHeader: ''}),
    );

    if (response.statusCode == 200) {
      final authResponse = AuthResponse.fromJson(response.data);
      await _storeTokens(authResponse.token, authResponse.refreshToken);
    } else {
      throw ApiError(message: 'Failed to refresh token');
    }
  }

  // Generic API methods
  Future<ApiResponse<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    T Function(Map<String, dynamic>)? fromJson,
  }) async {
    try {
      final response = await _dio.get(path, queryParameters: queryParameters);
      return _handleResponse<T>(response, fromJson);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<ApiResponse<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    T Function(Map<String, dynamic>)? fromJson,
    Options? options,
  }) async {
    try {
      final response = await _dio.post(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      return _handleResponse<T>(response, fromJson);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<ApiResponse<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    T Function(Map<String, dynamic>)? fromJson,
  }) async {
    try {
      final response = await _dio.put(
        path,
        data: data,
        queryParameters: queryParameters,
      );
      return _handleResponse<T>(response, fromJson);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<ApiResponse<T>> delete<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    T Function(Map<String, dynamic>)? fromJson,
  }) async {
    try {
      final response =
          await _dio.delete(path, queryParameters: queryParameters);
      return _handleResponse<T>(response, fromJson);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // File upload method
  Future<ApiResponse<FileUploadResponse>> uploadFile(
    String path,
    String filePath, {
    String? accessLevel,
    List<String>? tags,
    String? description,
    ProgressCallback? onSendProgress,
  }) async {
    try {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(filePath),
        'access_level': accessLevel ?? 'private',
        'tags': tags?.join(','),
        'description': description,
      });

      final response = await _dio.post(
        path,
        data: formData,
        onSendProgress: onSendProgress,
      );

      return _handleResponse<FileUploadResponse>(
        response,
        (json) => FileUploadResponse.fromJson(json['file']),
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Download file method
  Future<void> downloadFile(
    String url,
    String savePath, {
    ProgressCallback? onReceiveProgress,
  }) async {
    try {
      await _dio.download(
        url,
        savePath,
        onReceiveProgress: onReceiveProgress,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  ApiResponse<T> _handleResponse<T>(
    Response response,
    T Function(Map<String, dynamic>)? fromJson,
  ) {
    if (response.statusCode! >= 200 && response.statusCode! < 300) {
      // Check if response has 'data' field (wrapped format)
      if (response.data is Map<String, dynamic> &&
          response.data['data'] != null) {
        // Wrapped format: { "success": true, "data": {...}, "message": "..." }
        if (fromJson != null) {
          return ApiResponse<T>(
            success: response.data['success'] ?? true,
            data: fromJson(response.data['data']),
            message: response.data['message'],
          );
        } else {
          return ApiResponse<T>(
            success: response.data['success'] ?? true,
            data: response.data['data'],
            message: response.data['message'],
          );
        }
      } else {
        // Direct format: { "token": "...", "user": {...} } or with "status": "success"
        bool isSuccess = response.data['success'] == true ||
            response.data['status'] == 'success' ||
            response.statusCode == 200;

        if (fromJson != null && response.data is Map<String, dynamic>) {
          return ApiResponse<T>(
            success: isSuccess,
            data: fromJson(response.data),
            message: response.data['message'],
          );
        } else {
          return ApiResponse<T>(
            success: isSuccess,
            data: response.data,
            message: response.data['message'],
          );
        }
      }
    } else {
      throw ApiError.fromJson(response.data);
    }
  }

  ApiError _handleError(DioException error) {
    if (error.response != null) {
      return ApiError.fromJson(error.response!.data);
    } else {
      return ApiError(
        message: error.message ?? 'Network error occurred',
        statusCode: error.response?.statusCode,
      );
    }
  }

  // Utility methods
  void clearCache() {
    _cachedToken = null;
    _cachedRefreshToken = null;
  }

  bool get hasValidToken => _cachedToken != null;

  // Public methods for token management
  Future<void> storeAuthTokens(String accessToken, String refreshToken) async {
    await _storeTokens(accessToken, refreshToken);
  }

  Future<void> clearAuthTokens() async {
    await _clearTokens();
  }

  Future<String?> getStoredAccessToken() async {
    return await _getAccessToken();
  }

  Future<String?> getStoredRefreshToken() async {
    return await _getRefreshToken();
  }
}
