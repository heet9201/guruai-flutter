import 'dart:async';
import 'dart:math' as math;
import 'package:dio/dio.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import '../constants/api_constants.dart';
import '../cache/cache_manager.dart';
import '../performance/performance_monitor.dart';
import '../offline/offline_queue.dart';

/// Enhanced API response types for better error handling
enum ApiResponseType {
  success, // 200-299
  authError, // 401, 403
  rateLimited, // 429
  serverError, // 500-599
  networkError, // Connection issues
  timeout, // Request timeout
  unknown // Unknown error
}

/// Enhanced API response wrapper with metadata
class EnhancedApiResponse<T> {
  final T? data;
  final String? error;
  final int statusCode;
  final ApiResponseType type;
  final Map<String, dynamic>? metadata;
  final Duration? responseTime;
  final bool fromCache;

  const EnhancedApiResponse({
    this.data,
    this.error,
    required this.statusCode,
    required this.type,
    this.metadata,
    this.responseTime,
    this.fromCache = false,
  });

  bool get isSuccess => type == ApiResponseType.success && data != null;
  bool get isError => !isSuccess;
  bool get isFromCache => fromCache;

  factory EnhancedApiResponse.success(T data, {Duration? responseTime}) {
    return EnhancedApiResponse<T>(
      data: data,
      statusCode: 200,
      type: ApiResponseType.success,
      responseTime: responseTime,
    );
  }

  factory EnhancedApiResponse.error(
      String error, ApiResponseType type, int statusCode) {
    return EnhancedApiResponse<T>(
      error: error,
      statusCode: statusCode,
      type: type,
    );
  }

  factory EnhancedApiResponse.fromCache(T data) {
    return EnhancedApiResponse<T>(
      data: data,
      statusCode: 200,
      type: ApiResponseType.success,
      fromCache: true,
    );
  }
}

/// Request priority for queue management
enum RequestPriority { critical, high, medium, low }

/// Base API service with optimization patterns
abstract class BaseApiService {
  Future<EnhancedApiResponse<T>> get<T>(
    String endpoint, {
    Map<String, String>? headers,
    Map<String, dynamic>? queryParameters,
    RequestPriority priority = RequestPriority.medium,
    Duration? timeout,
    String? cacheKey,
    Duration? cacheExpiry,
  });

  Future<EnhancedApiResponse<T>> post<T>(
    String endpoint, {
    dynamic data,
    Map<String, String>? headers,
    RequestPriority priority = RequestPriority.medium,
    Duration? timeout,
    bool enableRetry = true,
  });

  Future<EnhancedApiResponse<T>> put<T>(
    String endpoint, {
    dynamic data,
    Map<String, String>? headers,
    RequestPriority priority = RequestPriority.medium,
    Duration? timeout,
  });

  Future<EnhancedApiResponse<T>> delete<T>(
    String endpoint, {
    Map<String, String>? headers,
    RequestPriority priority = RequestPriority.medium,
    Duration? timeout,
  });

  Future<EnhancedApiResponse<T>> executeWithRetry<T>(
    Future<EnhancedApiResponse<T>> Function() apiCall, {
    int maxRetries = 3,
    Duration baseDelay = const Duration(seconds: 1),
  });
}

/// Enhanced API client with all optimization patterns
class EnhancedApiClient extends BaseApiService {
  static final EnhancedApiClient _instance = EnhancedApiClient._internal();
  factory EnhancedApiClient() => _instance;
  EnhancedApiClient._internal();

  late final Dio _dio;
  final CacheManager _cacheManager = CacheManager();
  final PerformanceMonitor _performanceMonitor = PerformanceMonitor();
  final OfflineQueue _offlineQueue = OfflineQueue();
  final CircuitBreaker _circuitBreaker = CircuitBreaker();
  final RequestQueue _requestQueue = RequestQueue();

  // Connection state
  bool _isOnline = true;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  void initialize() {
    _initializeDio();
    _setupConnectivityMonitoring();
    _setupOfflineSync();
  }

  void _initializeDio() {
    _dio = Dio(BaseOptions(
      baseUrl: ApiConstants.baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 60),
      sendTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'User-Agent': 'Sahayak-Flutter-App/2.0.0',
      },
    ));

    // Add interceptors in order
    _dio.interceptors.add(_createAuthInterceptor());
    _dio.interceptors.add(_createPerformanceInterceptor());
    _dio.interceptors.add(_createLoggingInterceptor());
  }

  void _setupConnectivityMonitoring() {
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen(
      (List<ConnectivityResult> results) {
        final wasOnline = _isOnline;
        _isOnline = !results.contains(ConnectivityResult.none);

        if (!wasOnline && _isOnline) {
          // Back online - process offline queue
          _offlineQueue.processQueue();
        }
      },
    );
  }

  void _setupOfflineSync() {
    // Process offline queue every 30 seconds when online
    Timer.periodic(const Duration(seconds: 30), (timer) {
      if (_isOnline) {
        _offlineQueue.processQueue();
      }
    });
  }

  /// Auth interceptor with automatic token refresh
  InterceptorsWrapper _createAuthInterceptor() {
    return InterceptorsWrapper(
      onRequest: (options, handler) async {
        if (_isPublicEndpoint(options.path)) {
          handler.next(options);
          return;
        }

        final token = await _getAccessToken();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (error, handler) async {
        if (error.response?.statusCode == 401 &&
            !_isRefreshTokenEndpoint(error.requestOptions.path)) {
          try {
            await _refreshAccessToken();
            final retryOptions = error.requestOptions;
            final token = await _getAccessToken();
            retryOptions.headers['Authorization'] = 'Bearer $token';

            final response = await _dio.fetch(retryOptions);
            handler.resolve(response);
          } catch (e) {
            await _clearTokens();
            handler.next(error);
          }
        } else {
          handler.next(error);
        }
      },
    );
  }

  /// Performance monitoring interceptor
  InterceptorsWrapper _createPerformanceInterceptor() {
    return InterceptorsWrapper(
      onRequest: (options, handler) {
        options.extra['start_time'] = DateTime.now();
        handler.next(options);
      },
      onResponse: (response, handler) {
        final startTime =
            response.requestOptions.extra['start_time'] as DateTime?;
        if (startTime != null) {
          final responseTime = DateTime.now().difference(startTime);
          _performanceMonitor.trackRequest(
            response.requestOptions.path,
            responseTime,
            true,
          );
        }
        handler.next(response);
      },
      onError: (error, handler) {
        final startTime = error.requestOptions.extra['start_time'] as DateTime?;
        if (startTime != null) {
          final responseTime = DateTime.now().difference(startTime);
          _performanceMonitor.trackRequest(
            error.requestOptions.path,
            responseTime,
            false,
          );
        }
        handler.next(error);
      },
    );
  }

  /// Enhanced logging interceptor
  InterceptorsWrapper _createLoggingInterceptor() {
    return InterceptorsWrapper(
      onRequest: (options, handler) {
        if (kDebugMode) {
          print('🌐 API Request: ${options.method} ${options.path}');
          if (options.data != null) {
            print('📤 Request Data: ${options.data}');
          }
        }
        handler.next(options);
      },
      onResponse: (response, handler) {
        if (kDebugMode) {
          print(
              '✅ API Response: ${response.statusCode} ${response.requestOptions.path}');
          print('📥 Response Data: ${response.data}');
        }
        handler.next(response);
      },
      onError: (error, handler) {
        if (kDebugMode) {
          print(
              '❌ API Error: ${error.response?.statusCode} ${error.requestOptions.path}');
          print('Error Data: ${error.response?.data}');
        }
        handler.next(error);
      },
    );
  }

  @override
  Future<EnhancedApiResponse<T>> get<T>(
    String endpoint, {
    Map<String, String>? headers,
    Map<String, dynamic>? queryParameters,
    RequestPriority priority = RequestPriority.medium,
    Duration? timeout,
    String? cacheKey,
    Duration? cacheExpiry,
  }) async {
    // Check cache first
    if (cacheKey != null) {
      final cachedData = await _cacheManager.get<T>(cacheKey);
      if (cachedData != null) {
        return EnhancedApiResponse.fromCache(cachedData);
      }
    }

    return _requestQueue.enqueue(
      () => _executeGet<T>(
        endpoint,
        headers: headers,
        queryParameters: queryParameters,
        timeout: timeout,
        cacheKey: cacheKey,
        cacheExpiry: cacheExpiry,
      ),
      priority,
    );
  }

  Future<EnhancedApiResponse<T>> _executeGet<T>(
    String endpoint, {
    Map<String, String>? headers,
    Map<String, dynamic>? queryParameters,
    Duration? timeout,
    String? cacheKey,
    Duration? cacheExpiry,
  }) async {
    try {
      final response = await _circuitBreaker.execute(() async {
        return await _dio.get<dynamic>(
          endpoint,
          queryParameters: queryParameters,
          options: Options(
            headers: headers,
            receiveTimeout: timeout,
          ),
        );
      });

      final apiResponse = EnhancedApiResponse<T>(
        data: response.data as T,
        statusCode: response.statusCode ?? 200,
        type: ApiResponseType.success,
        responseTime: _getResponseTime(response),
      );

      // Cache successful response
      if (cacheKey != null && apiResponse.isSuccess) {
        await _cacheManager.store(
          cacheKey,
          response.data as T,
          expiry: cacheExpiry ?? const Duration(minutes: 15),
        );
      }

      return apiResponse;
    } catch (e) {
      return _handleError<T>(e);
    }
  }

  @override
  Future<EnhancedApiResponse<T>> post<T>(
    String endpoint, {
    dynamic data,
    Map<String, String>? headers,
    RequestPriority priority = RequestPriority.medium,
    Duration? timeout,
    bool enableRetry = true,
  }) async {
    if (!_isOnline) {
      // Queue for offline processing
      await _offlineQueue.add(endpoint, data, 'POST');
      return EnhancedApiResponse.error(
        'Queued for offline processing',
        ApiResponseType.networkError,
        0,
      );
    }

    final apiCall = () => _executePost<T>(endpoint,
        data: data, headers: headers, timeout: timeout);

    return enableRetry
        ? executeWithRetry(apiCall)
        : _requestQueue.enqueue(apiCall, priority);
  }

  Future<EnhancedApiResponse<T>> _executePost<T>(
    String endpoint, {
    dynamic data,
    Map<String, String>? headers,
    Duration? timeout,
  }) async {
    try {
      final response = await _circuitBreaker.execute(() async {
        return await _dio.post<dynamic>(
          endpoint,
          data: data,
          options: Options(
            headers: headers,
            sendTimeout: timeout,
            receiveTimeout: timeout,
          ),
        );
      });

      return EnhancedApiResponse<T>(
        data: response.data as T,
        statusCode: response.statusCode ?? 200,
        type: ApiResponseType.success,
        responseTime: _getResponseTime(response),
      );
    } catch (e) {
      return _handleError<T>(e);
    }
  }

  @override
  Future<EnhancedApiResponse<T>> put<T>(
    String endpoint, {
    dynamic data,
    Map<String, String>? headers,
    RequestPriority priority = RequestPriority.medium,
    Duration? timeout,
  }) async {
    return _requestQueue.enqueue(
      () => _executePut<T>(endpoint,
          data: data, headers: headers, timeout: timeout),
      priority,
    );
  }

  Future<EnhancedApiResponse<T>> _executePut<T>(
    String endpoint, {
    dynamic data,
    Map<String, String>? headers,
    Duration? timeout,
  }) async {
    try {
      final response = await _circuitBreaker.execute(() async {
        return await _dio.put<dynamic>(
          endpoint,
          data: data,
          options: Options(
            headers: headers,
            sendTimeout: timeout,
            receiveTimeout: timeout,
          ),
        );
      });

      return EnhancedApiResponse<T>(
        data: response.data as T,
        statusCode: response.statusCode ?? 200,
        type: ApiResponseType.success,
        responseTime: _getResponseTime(response),
      );
    } catch (e) {
      return _handleError<T>(e);
    }
  }

  @override
  Future<EnhancedApiResponse<T>> delete<T>(
    String endpoint, {
    Map<String, String>? headers,
    RequestPriority priority = RequestPriority.medium,
    Duration? timeout,
  }) async {
    return _requestQueue.enqueue(
      () => _executeDelete<T>(endpoint, headers: headers, timeout: timeout),
      priority,
    );
  }

  Future<EnhancedApiResponse<T>> _executeDelete<T>(
    String endpoint, {
    Map<String, String>? headers,
    Duration? timeout,
  }) async {
    try {
      final response = await _circuitBreaker.execute(() async {
        return await _dio.delete<dynamic>(
          endpoint,
          options: Options(
            headers: headers,
            receiveTimeout: timeout,
          ),
        );
      });

      return EnhancedApiResponse<T>(
        data: response.data as T,
        statusCode: response.statusCode ?? 200,
        type: ApiResponseType.success,
        responseTime: _getResponseTime(response),
      );
    } catch (e) {
      return _handleError<T>(e);
    }
  }

  @override
  Future<EnhancedApiResponse<T>> executeWithRetry<T>(
    Future<EnhancedApiResponse<T>> Function() apiCall, {
    int maxRetries = 3,
    Duration baseDelay = const Duration(seconds: 1),
  }) async {
    int attempt = 0;
    Duration delay = baseDelay;

    while (attempt < maxRetries) {
      try {
        final response = await apiCall();

        if (response.isSuccess) {
          return response;
        }

        // Don't retry client errors (4xx)
        if (response.statusCode >= 400 && response.statusCode < 500) {
          return response;
        }

        if (attempt == maxRetries - 1) {
          return response;
        }
      } catch (e) {
        if (attempt == maxRetries - 1) {
          return _handleError<T>(e);
        }
      }

      // Exponential backoff with jitter
      final jitter = math.Random().nextDouble() * 0.1;
      await Future.delayed(delay * (1 + jitter));
      delay *= 2;
      attempt++;
    }

    return EnhancedApiResponse.error(
      'Max retries exceeded',
      ApiResponseType.unknown,
      0,
    );
  }

  /// Enhanced error handling
  EnhancedApiResponse<T> _handleError<T>(dynamic error) {
    if (error is DioException) {
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          return EnhancedApiResponse.error(
            'Request timeout',
            ApiResponseType.timeout,
            0,
          );
        case DioExceptionType.connectionError:
          return EnhancedApiResponse.error(
            'Network connection error',
            ApiResponseType.networkError,
            0,
          );
        case DioExceptionType.badResponse:
          final statusCode = error.response?.statusCode ?? 0;
          ApiResponseType type;

          if (statusCode == 401 || statusCode == 403) {
            type = ApiResponseType.authError;
          } else if (statusCode == 429) {
            type = ApiResponseType.rateLimited;
          } else if (statusCode >= 500) {
            type = ApiResponseType.serverError;
          } else {
            type = ApiResponseType.unknown;
          }

          return EnhancedApiResponse.error(
            error.response?.data?.toString() ?? 'Request failed',
            type,
            statusCode,
          );
        default:
          return EnhancedApiResponse.error(
            'Unknown error occurred',
            ApiResponseType.unknown,
            0,
          );
      }
    }

    return EnhancedApiResponse.error(
      error.toString(),
      ApiResponseType.unknown,
      0,
    );
  }

  Duration? _getResponseTime(Response response) {
    final startTime = response.requestOptions.extra['start_time'] as DateTime?;
    return startTime != null ? DateTime.now().difference(startTime) : null;
  }

  // Token management methods
  Future<String?> _getAccessToken() async {
    // Implementation would get token from secure storage
    return null; // Placeholder
  }

  Future<void> _refreshAccessToken() async {
    // Implementation would refresh the token
    throw UnimplementedError('Token refresh not implemented');
  }

  Future<void> _clearTokens() async {
    // Implementation would clear tokens
  }

  bool _isPublicEndpoint(String path) {
    final publicEndpoints = ['/auth/login', '/auth/register', '/health'];
    return publicEndpoints.any((endpoint) => path.contains(endpoint));
  }

  bool _isRefreshTokenEndpoint(String path) {
    return path.contains('/auth/refresh');
  }

  void dispose() {
    _connectivitySubscription?.cancel();
    _dio.close();
  }
}

/// Circuit breaker implementation
class CircuitBreaker {
  final int failureThreshold;
  final Duration timeout;

  int _failureCount = 0;
  DateTime? _lastFailureTime;
  CircuitState _state = CircuitState.closed;

  CircuitBreaker({
    this.failureThreshold = 5,
    this.timeout = const Duration(minutes: 1),
  });

  Future<T> execute<T>(Future<T> Function() operation) async {
    if (_state == CircuitState.open) {
      if (DateTime.now().difference(_lastFailureTime!) > timeout) {
        _state = CircuitState.halfOpen;
      } else {
        throw Exception('Circuit breaker is open');
      }
    }

    try {
      final result = await operation();
      _onSuccess();
      return result;
    } catch (e) {
      _onFailure();
      rethrow;
    }
  }

  void _onSuccess() {
    _failureCount = 0;
    _state = CircuitState.closed;
  }

  void _onFailure() {
    _failureCount++;
    _lastFailureTime = DateTime.now();

    if (_failureCount >= failureThreshold) {
      _state = CircuitState.open;
    }
  }
}

enum CircuitState { closed, open, halfOpen }

/// Request queue for prioritization
class RequestQueue {
  final Map<RequestPriority, List<Future<dynamic> Function()>> _queues = {
    RequestPriority.critical: [],
    RequestPriority.high: [],
    RequestPriority.medium: [],
    RequestPriority.low: [],
  };

  final int _maxConcurrentRequests = 3;
  int _activeRequests = 0;

  Future<T> enqueue<T>(
    Future<T> Function() request,
    RequestPriority priority,
  ) async {
    final completer = Completer<T>();

    _queues[priority]!.add(() async {
      try {
        final result = await request();
        completer.complete(result);
      } catch (e) {
        completer.completeError(e);
      }
    });

    _processQueue();
    return completer.future;
  }

  void _processQueue() {
    if (_activeRequests >= _maxConcurrentRequests) return;

    for (final priority in RequestPriority.values) {
      if (_queues[priority]!.isNotEmpty) {
        final request = _queues[priority]!.removeAt(0);
        _activeRequests++;

        request().whenComplete(() {
          _activeRequests--;
          _processQueue();
        });

        break;
      }
    }
  }
}
