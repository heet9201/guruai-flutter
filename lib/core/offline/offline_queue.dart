import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

/// Offline queue item with retry logic
class OfflineQueueItem {
  final String id;
  final String endpoint;
  final dynamic data;
  final String method;
  final DateTime createdAt;
  final int retryCount;
  final int maxRetries;
  final Map<String, String>? headers;

  const OfflineQueueItem({
    required this.id,
    required this.endpoint,
    required this.data,
    required this.method,
    required this.createdAt,
    this.retryCount = 0,
    this.maxRetries = 3,
    this.headers,
  });

  bool get shouldRetry => retryCount < maxRetries;
  bool get isExpired => DateTime.now().difference(createdAt).inDays > 7;

  OfflineQueueItem copyWithRetry() {
    return OfflineQueueItem(
      id: id,
      endpoint: endpoint,
      data: data,
      method: method,
      createdAt: createdAt,
      retryCount: retryCount + 1,
      maxRetries: maxRetries,
      headers: headers,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'endpoint': endpoint,
      'data': data,
      'method': method,
      'createdAt': createdAt.toIso8601String(),
      'retryCount': retryCount,
      'maxRetries': maxRetries,
      'headers': headers,
    };
  }

  factory OfflineQueueItem.fromJson(Map<String, dynamic> json) {
    return OfflineQueueItem(
      id: json['id'],
      endpoint: json['endpoint'],
      data: json['data'],
      method: json['method'],
      createdAt: DateTime.parse(json['createdAt']),
      retryCount: json['retryCount'] ?? 0,
      maxRetries: json['maxRetries'] ?? 3,
      headers: json['headers'] != null
          ? Map<String, String>.from(json['headers'])
          : null,
    );
  }
}

/// Priority levels for offline queue items
enum OfflinePriority {
  low, // Analytics, logs
  normal, // User actions
  high, // Critical user data
  critical // Authentication, security
}

/// Offline queue manager for handling network interruptions
class OfflineQueue {
  static final OfflineQueue _instance = OfflineQueue._internal();
  factory OfflineQueue() => _instance;
  OfflineQueue._internal();

  static const String _queueKey = 'offline_queue';
  static const String _priorityQueueKey = 'priority_offline_queue';

  final List<OfflineQueueItem> _queue = [];
  final Map<OfflinePriority, List<OfflineQueueItem>> _priorityQueues = {
    OfflinePriority.critical: [],
    OfflinePriority.high: [],
    OfflinePriority.normal: [],
    OfflinePriority.low: [],
  };

  SharedPreferences? _prefs;
  bool _isProcessing = false;
  Timer? _processingTimer;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  // Success and failure callbacks
  final Map<String, void Function()> _successCallbacks = {};
  final Map<String, void Function(String error)> _failureCallbacks = {};

  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    await _loadQueueFromStorage();
    _setupConnectivityMonitoring();
    _startPeriodicProcessing();
  }

  /// Add item to offline queue
  Future<String> add(
    String endpoint,
    dynamic data,
    String method, {
    OfflinePriority priority = OfflinePriority.normal,
    Map<String, String>? headers,
    void Function()? onSuccess,
    void Function(String error)? onFailure,
  }) async {
    final id = _generateId();
    final item = OfflineQueueItem(
      id: id,
      endpoint: endpoint,
      data: data,
      method: method,
      createdAt: DateTime.now(),
      headers: headers,
    );

    // Store callbacks
    if (onSuccess != null) _successCallbacks[id] = onSuccess;
    if (onFailure != null) _failureCallbacks[id] = onFailure;

    // Add to appropriate queue
    _priorityQueues[priority]!.add(item);
    await _saveQueueToStorage();

    if (kDebugMode) {
      print('📴 Added to offline queue: ${item.method} ${item.endpoint}');
    }

    return id;
  }

  /// Process the offline queue
  Future<void> processQueue() async {
    if (_isProcessing) return;

    _isProcessing = true;

    try {
      // Process priority queues in order
      for (final priority in OfflinePriority.values) {
        await _processPriorityQueue(priority);
      }

      // Clean up expired items
      await _cleanupExpiredItems();
    } finally {
      _isProcessing = false;
    }
  }

  /// Get queue statistics
  OfflineQueueStats getStats() {
    final totalItems = _priorityQueues.values
        .map((queue) => queue.length)
        .fold(0, (sum, count) => sum + count);

    final itemsByPriority = _priorityQueues.map(
      (priority, queue) => MapEntry(priority, queue.length),
    );

    final oldestItem = _priorityQueues.values
        .expand((queue) => queue)
        .fold<DateTime?>(null, (oldest, item) {
      if (oldest == null || item.createdAt.isBefore(oldest)) {
        return item.createdAt;
      }
      return oldest;
    });

    return OfflineQueueStats(
      totalItems: totalItems,
      itemsByPriority: itemsByPriority,
      oldestItemAge:
          oldestItem != null ? DateTime.now().difference(oldestItem) : null,
    );
  }

  /// Remove item from queue
  Future<void> remove(String itemId) async {
    for (final queue in _priorityQueues.values) {
      queue.removeWhere((item) => item.id == itemId);
    }

    _successCallbacks.remove(itemId);
    _failureCallbacks.remove(itemId);

    await _saveQueueToStorage();
  }

  /// Clear all queues
  Future<void> clear() async {
    for (final queue in _priorityQueues.values) {
      queue.clear();
    }

    _successCallbacks.clear();
    _failureCallbacks.clear();

    await _saveQueueToStorage();
  }

  /// Get pending items for a specific endpoint
  List<OfflineQueueItem> getPendingItems(String endpoint) {
    return _priorityQueues.values
        .expand((queue) => queue)
        .where((item) => item.endpoint == endpoint)
        .toList();
  }

  void dispose() {
    _processingTimer?.cancel();
    _connectivitySubscription?.cancel();
  }

  // Private methods

  Future<void> _processPriorityQueue(OfflinePriority priority) async {
    final queue = _priorityQueues[priority]!;
    final itemsToRemove = <OfflineQueueItem>[];

    for (final item in List<OfflineQueueItem>.from(queue)) {
      try {
        final success = await _processItem(item);

        if (success) {
          itemsToRemove.add(item);
          _successCallbacks[item.id]?.call();
          _successCallbacks.remove(item.id);

          if (kDebugMode) {
            print(
                '✅ Offline queue item processed: ${item.method} ${item.endpoint}');
          }
        } else if (!item.shouldRetry) {
          // Max retries reached
          itemsToRemove.add(item);
          _failureCallbacks[item.id]?.call('Max retries exceeded');
          _failureCallbacks.remove(item.id);

          if (kDebugMode) {
            print(
                '❌ Offline queue item failed permanently: ${item.method} ${item.endpoint}');
          }
        } else {
          // Update retry count
          final index = queue.indexOf(item);
          if (index != -1) {
            queue[index] = item.copyWithRetry();
          }

          if (kDebugMode) {
            print(
                '🔄 Offline queue item retry: ${item.method} ${item.endpoint} (${item.retryCount + 1}/${item.maxRetries})');
          }
        }
      } catch (e) {
        if (kDebugMode) {
          print('⚠️ Error processing offline queue item: $e');
        }

        if (!item.shouldRetry) {
          itemsToRemove.add(item);
          _failureCallbacks[item.id]?.call(e.toString());
          _failureCallbacks.remove(item.id);
        }
      }
    }

    // Remove processed items
    for (final item in itemsToRemove) {
      queue.remove(item);
    }

    if (itemsToRemove.isNotEmpty) {
      await _saveQueueToStorage();
    }
  }

  Future<bool> _processItem(OfflineQueueItem item) async {
    // This would be implemented to make the actual API call
    // For now, we'll simulate processing
    await Future.delayed(const Duration(milliseconds: 100));

    // Simulate network success/failure
    // In real implementation, this would make the HTTP request
    return true; // Placeholder
  }

  void _setupConnectivityMonitoring() {
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen(
      (List<ConnectivityResult> results) {
        final isConnected = !results.contains(ConnectivityResult.none);

        if (isConnected && !_isProcessing) {
          // Back online - process queue
          processQueue();
        }
      },
    );
  }

  void _startPeriodicProcessing() {
    // Process queue every 30 seconds
    _processingTimer = Timer.periodic(
      const Duration(seconds: 30),
      (timer) => processQueue(),
    );
  }

  Future<void> _loadQueueFromStorage() async {
    try {
      // Load priority queues
      for (final priority in OfflinePriority.values) {
        final key = '${_priorityQueueKey}_${priority.name}';
        final jsonString = _prefs?.getString(key);

        if (jsonString != null) {
          final List<dynamic> jsonList = jsonDecode(jsonString);
          _priorityQueues[priority] =
              jsonList.map((json) => OfflineQueueItem.fromJson(json)).toList();
        }
      }

      if (kDebugMode) {
        final totalItems = _priorityQueues.values
            .map((queue) => queue.length)
            .fold(0, (sum, count) => sum + count);

        if (totalItems > 0) {
          print('📴 Loaded $totalItems items from offline queue');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ Error loading offline queue: $e');
      }
    }
  }

  Future<void> _saveQueueToStorage() async {
    try {
      for (final priority in OfflinePriority.values) {
        final key = '${_priorityQueueKey}_${priority.name}';
        final queue = _priorityQueues[priority]!;

        if (queue.isEmpty) {
          await _prefs?.remove(key);
        } else {
          final jsonString = jsonEncode(
            queue.map((item) => item.toJson()).toList(),
          );
          await _prefs?.setString(key, jsonString);
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ Error saving offline queue: $e');
      }
    }
  }

  Future<void> _cleanupExpiredItems() async {
    bool hasChanges = false;

    for (final queue in _priorityQueues.values) {
      final expiredItems = queue.where((item) => item.isExpired).toList();

      for (final item in expiredItems) {
        queue.remove(item);
        _successCallbacks.remove(item.id);
        _failureCallbacks.remove(item.id);
        hasChanges = true;

        if (kDebugMode) {
          print('🗑️ Removed expired offline queue item: ${item.endpoint}');
        }
      }
    }

    if (hasChanges) {
      await _saveQueueToStorage();
    }
  }

  String _generateId() {
    return '${DateTime.now().millisecondsSinceEpoch}_${DateTime.now().microsecond}';
  }
}

/// Statistics for offline queue
class OfflineQueueStats {
  final int totalItems;
  final Map<OfflinePriority, int> itemsByPriority;
  final Duration? oldestItemAge;

  const OfflineQueueStats({
    required this.totalItems,
    required this.itemsByPriority,
    this.oldestItemAge,
  });

  bool get hasItems => totalItems > 0;
  bool get hasOldItems => oldestItemAge != null && oldestItemAge!.inHours > 24;

  @override
  String toString() {
    return 'OfflineQueueStats('
        'total: $totalItems, '
        'critical: ${itemsByPriority[OfflinePriority.critical]}, '
        'high: ${itemsByPriority[OfflinePriority.high]}, '
        'normal: ${itemsByPriority[OfflinePriority.normal]}, '
        'low: ${itemsByPriority[OfflinePriority.low]}, '
        'oldestAge: ${oldestItemAge?.inHours}h)';
  }
}

/// Retry strategy configuration
class RetryStrategy {
  final int maxRetries;
  final Duration initialDelay;
  final double backoffMultiplier;
  final Duration maxDelay;

  const RetryStrategy({
    this.maxRetries = 3,
    this.initialDelay = const Duration(seconds: 1),
    this.backoffMultiplier = 2.0,
    this.maxDelay = const Duration(minutes: 5),
  });

  Duration getDelay(int retryCount) {
    final delay = initialDelay * Math.pow(backoffMultiplier, retryCount);
    return delay > maxDelay ? maxDelay : delay;
  }
}

/// Mathematical functions
class Math {
  static double pow(double base, int exponent) {
    if (exponent == 0) return 1.0;
    if (exponent == 1) return base;

    double result = 1.0;
    for (int i = 0; i < exponent; i++) {
      result *= base;
    }
    return result;
  }
}
