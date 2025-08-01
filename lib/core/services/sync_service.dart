import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import '../../data/repositories/offline_repository.dart';
import 'network_connectivity_service.dart';

enum SyncStatus {
  idle,
  syncing,
  completed,
  failed,
  cancelled,
}

enum SyncPriority {
  low,
  normal,
  high,
  critical,
}

class SyncItem {
  final int id;
  final String actionType;
  final Map<String, dynamic> data;
  final DateTime createdAt;
  final SyncPriority priority;
  final int retryCount;
  final int maxRetries;

  const SyncItem({
    required this.id,
    required this.actionType,
    required this.data,
    required this.createdAt,
    this.priority = SyncPriority.normal,
    this.retryCount = 0,
    this.maxRetries = 3,
  });

  SyncItem copyWith({
    int? retryCount,
    SyncPriority? priority,
  }) {
    return SyncItem(
      id: id,
      actionType: actionType,
      data: data,
      createdAt: createdAt,
      priority: priority ?? this.priority,
      retryCount: retryCount ?? this.retryCount,
      maxRetries: maxRetries,
    );
  }
}

class SyncResult {
  final bool success;
  final String? error;
  final Map<String, dynamic>? responseData;
  final Duration syncDuration;

  const SyncResult({
    required this.success,
    this.error,
    this.responseData,
    required this.syncDuration,
  });
}

class SyncProgressInfo {
  final int totalItems;
  final int completedItems;
  final int failedItems;
  final String? currentItem;
  final double progress;
  final Duration estimatedTimeRemaining;

  const SyncProgressInfo({
    required this.totalItems,
    required this.completedItems,
    required this.failedItems,
    this.currentItem,
    required this.progress,
    required this.estimatedTimeRemaining,
  });
}

class SyncService extends ChangeNotifier {
  static SyncService? _instance;
  static SyncService get instance => _instance ??= SyncService._();

  SyncService._() {
    _initialize();
  }

  final OfflineRepository _offlineRepository = OfflineRepository.instance;
  final NetworkConnectivityService _networkService =
      NetworkConnectivityService.instance;

  Timer? _syncTimer;
  Timer? _retryTimer;
  bool _isManualSyncInProgress = false;
  bool _isAutoSyncEnabled = true;
  SyncStatus _currentSyncStatus = SyncStatus.idle;
  SyncProgressInfo? _currentProgress;
  DateTime? _lastSyncAttempt;
  DateTime? _lastSuccessfulSync;
  int _consecutiveFailures = 0;
  List<SyncItem> _currentSyncQueue = [];

  // Configuration
  Duration _autoSyncInterval = const Duration(minutes: 5);
  Duration _retryDelay = const Duration(seconds: 30);
  int _maxConsecutiveFailures = 5;
  bool _syncOnlyOnWifi = false;
  bool _syncOnLowBattery = false;

  // Getters
  SyncStatus get currentSyncStatus => _currentSyncStatus;
  SyncProgressInfo? get currentProgress => _currentProgress;
  bool get isManualSyncInProgress => _isManualSyncInProgress;
  bool get isAutoSyncEnabled => _isAutoSyncEnabled;
  DateTime? get lastSyncAttempt => _lastSyncAttempt;
  DateTime? get lastSuccessfulSync => _lastSuccessfulSync;
  int get consecutiveFailures => _consecutiveFailures;
  Duration get autoSyncInterval => _autoSyncInterval;
  bool get syncOnlyOnWifi => _syncOnlyOnWifi;

  void _initialize() {
    _networkService.addListener(_onNetworkStatusChanged);
    _startAutoSync();
  }

  void _onNetworkStatusChanged() {
    if (_networkService.isOnline && _isAutoSyncEnabled) {
      // Delay sync to allow network to stabilize
      Timer(const Duration(seconds: 2), () {
        if (_networkService.isOnline) {
          _performAutoSync();
        }
      });
    }
  }

  void _startAutoSync() {
    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(_autoSyncInterval, (timer) {
      if (_isAutoSyncEnabled && _shouldPerformAutoSync()) {
        _performAutoSync();
      }
    });
  }

  bool _shouldPerformAutoSync() {
    // Don't sync if manual sync is in progress
    if (_isManualSyncInProgress) return false;

    // Don't sync if we've had too many consecutive failures
    if (_consecutiveFailures >= _maxConsecutiveFailures) return false;

    // Check network conditions
    if (!_networkService.hasInternetAccess) return false;

    if (_syncOnlyOnWifi &&
        _networkService.connectionType != ConnectionType.wifi) {
      return false;
    }

    // Note: _syncOnLowBattery could be used here with battery_plus plugin
    // if (!_syncOnLowBattery && batteryLevel < 20) return false;

    // Check if we need to sync (has pending items)
    return true; // Will be checked in the actual sync method
  }

  /// Manually trigger sync
  Future<SyncResult> manualSync({bool forceSync = false}) async {
    if (_isManualSyncInProgress && !forceSync) {
      return const SyncResult(
        success: false,
        error: 'Sync already in progress',
        syncDuration: Duration.zero,
      );
    }

    _isManualSyncInProgress = true;
    _updateSyncStatus(SyncStatus.syncing);

    try {
      final result = await _performSync(isManual: true);
      return result;
    } finally {
      _isManualSyncInProgress = false;
    }
  }

  Future<void> _performAutoSync() async {
    if (_currentSyncStatus == SyncStatus.syncing) return;

    try {
      await _performSync(isManual: false);
    } catch (e) {
      debugPrint('Auto sync failed: $e');
    }
  }

  Future<SyncResult> _performSync({bool isManual = false}) async {
    final stopwatch = Stopwatch()..start();
    _lastSyncAttempt = DateTime.now();

    try {
      // Mark sync as in progress in database
      await _offlineRepository.setSyncInProgress(true);

      // Get pending items from offline queue
      final pendingItems = await _getPendingSyncItems();

      if (pendingItems.isEmpty) {
        stopwatch.stop();
        _updateSyncStatus(SyncStatus.completed);
        _consecutiveFailures = 0;
        _lastSuccessfulSync = DateTime.now();

        return SyncResult(
          success: true,
          syncDuration: stopwatch.elapsed,
        );
      }

      _currentSyncQueue = pendingItems;
      _updateProgress(0, pendingItems.length);

      int completed = 0;
      int failed = 0;
      final List<String> errors = [];

      // Process each item
      for (int i = 0; i < pendingItems.length; i++) {
        final item = pendingItems[i];

        _updateProgress(i, pendingItems.length, currentItem: item.actionType);

        // Check if we should continue (network status, cancellation)
        if (!_networkService.hasInternetAccess) {
          throw Exception('Lost network connection during sync');
        }

        try {
          final success = await _syncSingleItem(item);

          if (success) {
            await _offlineRepository.removeFromOfflineQueue(item.id);
            completed++;
          } else {
            failed++;
            if (item.retryCount >= item.maxRetries) {
              await _offlineRepository.removeFromOfflineQueue(item.id);
              errors.add('Max retries exceeded for ${item.actionType}');
            } else {
              // Will be retried later
            }
          }
        } catch (e) {
          failed++;
          errors.add('${item.actionType}: $e');
        }

        // Add small delay between items to prevent overwhelming the server
        await Future.delayed(const Duration(milliseconds: 100));
      }

      stopwatch.stop();

      final success = failed == 0;

      if (success) {
        _consecutiveFailures = 0;
        _lastSuccessfulSync = DateTime.now();
        _updateSyncStatus(SyncStatus.completed);
      } else {
        _consecutiveFailures++;
        _updateSyncStatus(SyncStatus.failed);
        _scheduleRetry();
      }

      _updateProgress(completed, pendingItems.length);

      return SyncResult(
        success: success,
        error: errors.isNotEmpty ? errors.join('; ') : null,
        syncDuration: stopwatch.elapsed,
      );
    } catch (e) {
      stopwatch.stop();
      _consecutiveFailures++;
      _updateSyncStatus(SyncStatus.failed);
      _scheduleRetry();

      return SyncResult(
        success: false,
        error: e.toString(),
        syncDuration: stopwatch.elapsed,
      );
    } finally {
      await _offlineRepository.setSyncInProgress(false);
      _currentSyncQueue.clear();
      _currentProgress = null;
    }
  }

  Future<List<SyncItem>> _getPendingSyncItems() async {
    final rawItems = await _offlineRepository.getPendingOfflineActions();

    return rawItems.map((item) {
      return SyncItem(
        id: item['id'] as int,
        actionType: item['action_type'] as String,
        data: jsonDecode(item['data'] as String),
        createdAt:
            DateTime.fromMillisecondsSinceEpoch(item['created_at'] as int),
        priority: _getSyncPriority(item['priority'] as int),
        retryCount: item['retry_count'] as int,
      );
    }).toList();
  }

  SyncPriority _getSyncPriority(int priority) {
    switch (priority) {
      case 3:
        return SyncPriority.critical;
      case 2:
        return SyncPriority.high;
      case 1:
        return SyncPriority.normal;
      default:
        return SyncPriority.low;
    }
  }

  Future<bool> _syncSingleItem(SyncItem item) async {
    try {
      switch (item.actionType) {
        case 'send_message':
          return await _syncMessage(item.data);
        case 'save_lesson_plan':
          return await _syncLessonPlan(item.data);
        case 'save_user_content':
          return await _syncUserContent(item.data);
        case 'save_faq':
          return await _syncFaq(item.data);
        case 'upload_file':
          return await _syncFileUpload(item.data);
        default:
          debugPrint('Unknown sync action type: ${item.actionType}');
          return false;
      }
    } catch (e) {
      debugPrint('Error syncing item ${item.actionType}: $e');
      return false;
    }
  }

  Future<bool> _syncMessage(Map<String, dynamic> data) async {
    // Simulate API call to send message
    await Future.delayed(Duration(milliseconds: 100 + Random().nextInt(200)));

    // Simulate occasional failures
    if (Random().nextDouble() < 0.1) {
      throw Exception('Server error');
    }

    return true;
  }

  Future<bool> _syncLessonPlan(Map<String, dynamic> data) async {
    // Simulate API call to save lesson plan
    await Future.delayed(Duration(milliseconds: 200 + Random().nextInt(300)));

    if (Random().nextDouble() < 0.05) {
      throw Exception('Validation error');
    }

    return true;
  }

  Future<bool> _syncUserContent(Map<String, dynamic> data) async {
    // Simulate API call to save user content
    await Future.delayed(Duration(milliseconds: 150 + Random().nextInt(250)));
    return true;
  }

  Future<bool> _syncFaq(Map<String, dynamic> data) async {
    // Simulate API call to save FAQ
    await Future.delayed(Duration(milliseconds: 100 + Random().nextInt(150)));
    return true;
  }

  Future<bool> _syncFileUpload(Map<String, dynamic> data) async {
    // Simulate file upload (longer duration)
    await Future.delayed(Duration(milliseconds: 500 + Random().nextInt(1000)));

    // File uploads have higher failure rate on poor connections
    if (_networkService.networkQuality < 0.5 && Random().nextDouble() < 0.3) {
      throw Exception('Upload failed due to poor connection');
    }

    return true;
  }

  void _updateSyncStatus(SyncStatus status) {
    _currentSyncStatus = status;
    notifyListeners();
  }

  void _updateProgress(int completed, int total, {String? currentItem}) {
    final progress = total > 0 ? completed / total : 0.0;
    final remaining = total - completed;

    // Estimate time remaining based on average time per item
    final avgTimePerItem = const Duration(milliseconds: 200);
    final estimatedTimeRemaining = avgTimePerItem * remaining;

    _currentProgress = SyncProgressInfo(
      totalItems: total,
      completedItems: completed,
      failedItems: 0, // Calculate if needed
      currentItem: currentItem,
      progress: progress,
      estimatedTimeRemaining: estimatedTimeRemaining,
    );

    notifyListeners();
  }

  void _scheduleRetry() {
    _retryTimer?.cancel();

    // Exponential backoff with jitter
    final delay = Duration(
      milliseconds: (_retryDelay.inMilliseconds *
                  pow(2, min(_consecutiveFailures - 1, 4)))
              .round() +
          Random().nextInt(1000),
    );

    _retryTimer = Timer(delay, () {
      if (_networkService.hasInternetAccess && _isAutoSyncEnabled) {
        _performAutoSync();
      }
    });
  }

  /// Configuration methods
  void setAutoSyncEnabled(bool enabled) {
    _isAutoSyncEnabled = enabled;
    if (enabled) {
      _startAutoSync();
    } else {
      _syncTimer?.cancel();
    }
    notifyListeners();
  }

  void setAutoSyncInterval(Duration interval) {
    _autoSyncInterval = interval;
    if (_isAutoSyncEnabled) {
      _startAutoSync();
    }
  }

  void setSyncOnlyOnWifi(bool wifiOnly) {
    _syncOnlyOnWifi = wifiOnly;
    notifyListeners();
  }

  void setSyncOnLowBattery(bool allowOnLowBattery) {
    _syncOnLowBattery = allowOnLowBattery;
    notifyListeners();
  }

  /// Cancel current sync
  void cancelSync() {
    if (_currentSyncStatus == SyncStatus.syncing) {
      _updateSyncStatus(SyncStatus.cancelled);
      _isManualSyncInProgress = false;
    }
  }

  /// Force immediate sync retry
  Future<void> forceRetry() async {
    _retryTimer?.cancel();
    _consecutiveFailures = 0;
    await _performAutoSync();
  }

  /// Get sync statistics
  Map<String, dynamic> getSyncStatistics() {
    return {
      'currentStatus': _currentSyncStatus.toString(),
      'isAutoSyncEnabled': _isAutoSyncEnabled,
      'lastSyncAttempt': _lastSyncAttempt?.toIso8601String(),
      'lastSuccessfulSync': _lastSuccessfulSync?.toIso8601String(),
      'consecutiveFailures': _consecutiveFailures,
      'autoSyncIntervalMinutes': _autoSyncInterval.inMinutes,
      'syncOnlyOnWifi': _syncOnlyOnWifi,
      'pendingItemsCount': _currentSyncQueue.length,
    };
  }

  /// Add item to sync queue
  Future<void> addToSyncQueue({
    required String actionType,
    required Map<String, dynamic> data,
    SyncPriority priority = SyncPriority.normal,
  }) async {
    await _offlineRepository.addToOfflineQueue(
      actionType: actionType,
      data: data,
      priority: priority.index,
    );

    // Trigger immediate sync for high priority items if online
    if (priority == SyncPriority.critical && _networkService.isOnline) {
      _performAutoSync();
    }
  }

  /// Clear all pending sync items
  Future<void> clearSyncQueue() async {
    // This would require a method in OfflineRepository to clear all queue items
    // await _offlineRepository.clearOfflineQueue();
    _currentSyncQueue.clear();
    notifyListeners();
  }

  /// Dispose resources
  void dispose() {
    _syncTimer?.cancel();
    _retryTimer?.cancel();
    _networkService.removeListener(_onNetworkStatusChanged);
    super.dispose();
  }
}
