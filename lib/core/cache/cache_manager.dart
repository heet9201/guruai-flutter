import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Cache priority levels for eviction strategy
enum CachePriority { low, normal, high, critical }

/// Cache item with metadata
class CacheItem {
  final dynamic data;
  final DateTime? expiry;
  final CachePriority priority;
  final DateTime createdAt;
  final DateTime lastAccessed;
  final int accessCount;

  CacheItem({
    required this.data,
    this.expiry,
    this.priority = CachePriority.normal,
    DateTime? createdAt,
    DateTime? lastAccessed,
    this.accessCount = 0,
  })  : createdAt = createdAt ?? DateTime.now(),
        lastAccessed = lastAccessed ?? DateTime.now();

  bool get isExpired {
    if (expiry == null) return false;
    return DateTime.now().isAfter(expiry!);
  }

  CacheItem copyWithAccess() {
    return CacheItem(
      data: data,
      expiry: expiry,
      priority: priority,
      createdAt: createdAt,
      lastAccessed: DateTime.now(),
      accessCount: accessCount + 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'data': data,
      'expiry': expiry?.toIso8601String(),
      'priority': priority.index,
      'createdAt': createdAt.toIso8601String(),
      'lastAccessed': lastAccessed.toIso8601String(),
      'accessCount': accessCount,
    };
  }

  factory CacheItem.fromJson(Map<String, dynamic> json) {
    return CacheItem(
      data: json['data'],
      expiry: json['expiry'] != null ? DateTime.parse(json['expiry']) : null,
      priority: CachePriority.values[json['priority'] ?? 1],
      createdAt: DateTime.parse(json['createdAt']),
      lastAccessed: DateTime.parse(json['lastAccessed']),
      accessCount: json['accessCount'] ?? 0,
    );
  }
}

/// Multi-level cache manager with memory, disk, and secure storage
class CacheManager {
  static final CacheManager _instance = CacheManager._internal();
  factory CacheManager() => _instance;
  CacheManager._internal();

  // Memory cache
  final Map<String, CacheItem> _memoryCache = {};
  final int _maxMemoryItems = 100;

  // Storage instances
  SharedPreferences? _prefs;
  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage();

  // Cache groups for invalidation
  final Map<String, Set<String>> _cacheGroups = {
    'user_profile': {'profile_basic', 'profile_detailed', 'user_settings'},
    'dashboard': {'dashboard_overview', 'quick_stats', 'recent_activities'},
    'chat': {'chat_sessions', 'chat_history_*'},
    'planner': {'weekly_plans_*', 'planning_templates', 'suggestions_*'},
    'content': {'content_templates', 'generation_history'},
  };

  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    await _cleanupExpiredItems();
  }

  /// Get cached data with fallback hierarchy: memory -> disk -> secure -> null
  Future<T?> get<T>(String key, {bool secure = false}) async {
    try {
      // Try memory cache first (fastest)
      final memoryItem = _memoryCache[key];
      if (memoryItem != null && !memoryItem.isExpired) {
        _memoryCache[key] = memoryItem.copyWithAccess();
        return memoryItem.data as T?;
      }

      // Remove expired memory item
      if (memoryItem?.isExpired == true) {
        _memoryCache.remove(key);
      }

      // Try persistent cache
      final persistentData = secure
          ? await _getFromSecureStorage(key)
          : await _getFromDiskCache(key);

      if (persistentData != null && !persistentData.isExpired) {
        // Promote to memory cache
        _addToMemoryCache(key, persistentData);
        return persistentData.data as T?;
      }

      // Clean up expired persistent data
      if (persistentData?.isExpired == true) {
        secure
            ? await _removeFromSecureStorage(key)
            : await _removeFromDiskCache(key);
      }

      return null;
    } catch (e) {
      if (kDebugMode) {
        print('Cache get error for key $key: $e');
      }
      return null;
    }
  }

  /// Store data in cache with specified level and expiry
  Future<void> store<T>(
    String key,
    T data, {
    Duration? expiry,
    bool secure = false,
    CachePriority priority = CachePriority.normal,
  }) async {
    try {
      final cacheItem = CacheItem(
        data: data,
        expiry: expiry != null ? DateTime.now().add(expiry) : null,
        priority: priority,
      );

      // Store in memory cache
      _addToMemoryCache(key, cacheItem);

      // Store in persistent cache
      if (secure) {
        await _storeInSecureStorage(key, cacheItem);
      } else {
        await _storeToDiskCache(key, cacheItem);
      }
    } catch (e) {
      if (kDebugMode) {
        print('Cache store error for key $key: $e');
      }
    }
  }

  /// Remove item from all cache levels
  Future<void> remove(String key, {bool secure = false}) async {
    try {
      _memoryCache.remove(key);

      if (secure) {
        await _removeFromSecureStorage(key);
      } else {
        await _removeFromDiskCache(key);
      }
    } catch (e) {
      if (kDebugMode) {
        print('Cache remove error for key $key: $e');
      }
    }
  }

  /// Invalidate cache group
  Future<void> invalidateGroup(String group) async {
    final cacheKeys = _cacheGroups[group];
    if (cacheKeys != null) {
      for (final key in cacheKeys) {
        if (key.endsWith('*')) {
          // Pattern-based invalidation
          await _invalidatePattern(key.substring(0, key.length - 1));
        } else {
          await remove(key);
        }
      }
    }
  }

  /// Clear all caches
  Future<void> clear({bool includeSecure = false}) async {
    try {
      _memoryCache.clear();
      await _prefs?.clear();

      if (includeSecure) {
        await _secureStorage.deleteAll();
      }
    } catch (e) {
      if (kDebugMode) {
        print('Cache clear error: $e');
      }
    }
  }

  /// Get cache statistics
  CacheStats getStats() {
    final memorySize = _memoryCache.length;
    final diskSize = _prefs?.getKeys().length ?? 0;

    return CacheStats(
      memoryItems: memorySize,
      diskItems: diskSize,
      memoryHitRate: _calculateHitRate(),
    );
  }

  // Private methods

  void _addToMemoryCache(String key, CacheItem item) {
    _memoryCache[key] = item;

    // Evict if memory cache is full
    if (_memoryCache.length > _maxMemoryItems) {
      _evictFromMemoryCache();
    }
  }

  void _evictFromMemoryCache() {
    // LRU eviction with priority consideration
    final sortedEntries = _memoryCache.entries.toList()
      ..sort((a, b) {
        // First sort by priority (higher priority last)
        final priorityCompare =
            a.value.priority.index.compareTo(b.value.priority.index);
        if (priorityCompare != 0) return priorityCompare;

        // Then by last accessed time (older first)
        return a.value.lastAccessed.compareTo(b.value.lastAccessed);
      });

    // Remove 20% of items
    final itemsToRemove = (_maxMemoryItems * 0.2).ceil();
    for (int i = 0; i < itemsToRemove && sortedEntries.isNotEmpty; i++) {
      _memoryCache.remove(sortedEntries[i].key);
    }
  }

  Future<CacheItem?> _getFromDiskCache(String key) async {
    try {
      final jsonString = _prefs?.getString('cache_$key');
      if (jsonString != null) {
        final json = jsonDecode(jsonString);
        return CacheItem.fromJson(json);
      }
    } catch (e) {
      if (kDebugMode) {
        print('Disk cache get error: $e');
      }
    }
    return null;
  }

  Future<void> _storeToDiskCache(String key, CacheItem item) async {
    try {
      final jsonString = jsonEncode(item.toJson());
      await _prefs?.setString('cache_$key', jsonString);
    } catch (e) {
      if (kDebugMode) {
        print('Disk cache store error: $e');
      }
    }
  }

  Future<void> _removeFromDiskCache(String key) async {
    try {
      await _prefs?.remove('cache_$key');
    } catch (e) {
      if (kDebugMode) {
        print('Disk cache remove error: $e');
      }
    }
  }

  Future<CacheItem?> _getFromSecureStorage(String key) async {
    try {
      final jsonString = await _secureStorage.read(key: 'cache_$key');
      if (jsonString != null) {
        final json = jsonDecode(jsonString);
        return CacheItem.fromJson(json);
      }
    } catch (e) {
      if (kDebugMode) {
        print('Secure cache get error: $e');
      }
    }
    return null;
  }

  Future<void> _storeInSecureStorage(String key, CacheItem item) async {
    try {
      final jsonString = jsonEncode(item.toJson());
      await _secureStorage.write(key: 'cache_$key', value: jsonString);
    } catch (e) {
      if (kDebugMode) {
        print('Secure cache store error: $e');
      }
    }
  }

  Future<void> _removeFromSecureStorage(String key) async {
    try {
      await _secureStorage.delete(key: 'cache_$key');
    } catch (e) {
      if (kDebugMode) {
        print('Secure cache remove error: $e');
      }
    }
  }

  Future<void> _invalidatePattern(String pattern) async {
    // Invalidate memory cache
    final keysToRemove =
        _memoryCache.keys.where((key) => key.startsWith(pattern)).toList();

    for (final key in keysToRemove) {
      _memoryCache.remove(key);
    }

    // Invalidate disk cache
    final allKeys = _prefs?.getKeys() ?? <String>{};
    for (final key in allKeys) {
      if (key.startsWith('cache_$pattern')) {
        await _prefs?.remove(key);
      }
    }
  }

  Future<void> _cleanupExpiredItems() async {
    // Clean memory cache
    final expiredKeys = _memoryCache.entries
        .where((entry) => entry.value.isExpired)
        .map((entry) => entry.key)
        .toList();

    for (final key in expiredKeys) {
      _memoryCache.remove(key);
    }

    // Clean disk cache (periodic cleanup)
    Timer.periodic(const Duration(hours: 1), (timer) async {
      final allKeys = _prefs?.getKeys() ?? <String>{};
      for (final key in allKeys) {
        if (key.startsWith('cache_')) {
          final item = await _getFromDiskCache(key.substring(6));
          if (item?.isExpired == true) {
            await _prefs?.remove(key);
          }
        }
      }
    });
  }

  double _calculateHitRate() {
    // Simple hit rate calculation based on access count
    if (_memoryCache.isEmpty) return 0.0;

    final totalAccess = _memoryCache.values
        .map((item) => item.accessCount)
        .fold(0, (sum, count) => sum + count);

    return totalAccess / _memoryCache.length;
  }
}

/// Cache statistics
class CacheStats {
  final int memoryItems;
  final int diskItems;
  final double memoryHitRate;

  const CacheStats({
    required this.memoryItems,
    required this.diskItems,
    required this.memoryHitRate,
  });

  @override
  String toString() {
    return 'CacheStats(memory: $memoryItems, disk: $diskItems, hitRate: ${(memoryHitRate * 100).toStringAsFixed(1)}%)';
  }
}

/// Offline-first cache strategy
class OfflineFirstCache {
  final CacheManager _cacheManager = CacheManager();

  /// Get data with offline-first strategy
  Future<T?> getOfflineFirst<T>(
    String cacheKey,
    Future<T> Function() networkCall, {
    Duration cacheExpiry = const Duration(minutes: 15),
    bool refreshInBackground = true,
  }) async {
    // Return cached data immediately if available
    final cached = await _cacheManager.get<T>(cacheKey);
    if (cached != null) {
      if (refreshInBackground) {
        // Start background refresh
        _refreshInBackground(cacheKey, networkCall, cacheExpiry);
      }
      return cached;
    }

    // No cache, fetch immediately
    try {
      final fresh = await networkCall();
      await _cacheManager.store(cacheKey, fresh, expiry: cacheExpiry);
      return fresh;
    } catch (e) {
      if (kDebugMode) {
        print('Network call failed, no cache available: $e');
      }
      return null;
    }
  }

  Future<void> _refreshInBackground<T>(
    String cacheKey,
    Future<T> Function() networkCall,
    Duration cacheExpiry,
  ) async {
    try {
      final fresh = await networkCall();
      await _cacheManager.store(cacheKey, fresh, expiry: cacheExpiry);
    } catch (e) {
      if (kDebugMode) {
        print('Background refresh failed for $cacheKey: $e');
      }
    }
  }
}
