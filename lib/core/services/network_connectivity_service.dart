import 'dart:async';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

enum NetworkStatus {
  online,
  offline,
  poor,
  limited,
}

enum ConnectionType {
  wifi,
  mobile,
  ethernet,
  none,
}

class NetworkConnectivityService extends ChangeNotifier {
  static NetworkConnectivityService? _instance;
  static NetworkConnectivityService get instance =>
      _instance ??= NetworkConnectivityService._();

  NetworkConnectivityService._() {
    _initialize();
  }

  final Connectivity _connectivity = Connectivity();
  late StreamSubscription<List<ConnectivityResult>> _connectivitySubscription;
  Timer? _networkQualityTimer;

  NetworkStatus _currentStatus = NetworkStatus.offline;
  ConnectionType _connectionType = ConnectionType.none;
  double _networkQuality = 0.0; // 0.0 to 1.0
  int _pingLatency = 0; // milliseconds
  bool _hasInternetAccess = false;
  DateTime? _lastConnectedTime;
  DateTime? _lastDisconnectedTime;
  Duration _totalOnlineTime = Duration.zero;
  Duration _totalOfflineTime = Duration.zero;

  // Getters
  NetworkStatus get currentStatus => _currentStatus;
  ConnectionType get connectionType => _connectionType;
  double get networkQuality => _networkQuality;
  int get pingLatency => _pingLatency;
  bool get hasInternetAccess => _hasInternetAccess;
  bool get isOnline => _currentStatus == NetworkStatus.online;
  bool get isOffline => _currentStatus == NetworkStatus.offline;
  DateTime? get lastConnectedTime => _lastConnectedTime;
  DateTime? get lastDisconnectedTime => _lastDisconnectedTime;
  Duration get totalOnlineTime => _totalOnlineTime;
  Duration get totalOfflineTime => _totalOfflineTime;

  // Network quality thresholds
  static const double poorConnectionThreshold = 0.3;
  static const double goodConnectionThreshold = 0.7;
  static const int slowPingThreshold = 1000; // 1 second
  static const int fastPingThreshold = 100; // 100ms

  Future<void> _initialize() async {
    // Check initial connectivity
    await _checkConnectivity();

    // Listen to connectivity changes
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
      (List<ConnectivityResult> results) async {
        await _handleConnectivityChange(results);
      },
    );

    // Start periodic network quality checks
    _startNetworkQualityMonitoring();
  }

  Future<void> _checkConnectivity() async {
    try {
      final connectivityResults = await _connectivity.checkConnectivity();
      await _handleConnectivityChange(connectivityResults);
    } catch (e) {
      debugPrint('Error checking connectivity: $e');
      _updateStatus(NetworkStatus.offline, ConnectionType.none);
    }
  }

  Future<void> _handleConnectivityChange(
      List<ConnectivityResult> results) async {
    final hasConnection = !results.contains(ConnectivityResult.none);

    if (hasConnection) {
      // Determine connection type
      ConnectionType newConnectionType = _getConnectionType(results);

      // Check actual internet access
      final hasInternet = await _checkInternetAccess();

      if (hasInternet) {
        _updateStatus(NetworkStatus.online, newConnectionType);
        _lastConnectedTime = DateTime.now();

        // Start measuring network quality
        await _measureNetworkQuality();
      } else {
        _updateStatus(NetworkStatus.limited, newConnectionType);
      }
    } else {
      _updateStatus(NetworkStatus.offline, ConnectionType.none);
      _lastDisconnectedTime = DateTime.now();
    }
  }

  ConnectionType _getConnectionType(List<ConnectivityResult> results) {
    if (results.contains(ConnectivityResult.wifi)) {
      return ConnectionType.wifi;
    } else if (results.contains(ConnectivityResult.mobile)) {
      return ConnectionType.mobile;
    } else if (results.contains(ConnectivityResult.ethernet)) {
      return ConnectionType.ethernet;
    }
    return ConnectionType.none;
  }

  Future<bool> _checkInternetAccess() async {
    try {
      final result = await InternetAddress.lookup('google.com')
          .timeout(const Duration(seconds: 5));
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  Future<void> _measureNetworkQuality() async {
    try {
      // Measure ping latency
      final stopwatch = Stopwatch()..start();

      await InternetAddress.lookup('google.com')
          .timeout(const Duration(seconds: 3));

      stopwatch.stop();
      _pingLatency = stopwatch.elapsedMilliseconds;

      // Calculate network quality based on ping and connection type
      double quality = _calculateNetworkQuality(_pingLatency, _connectionType);

      _networkQuality = quality;

      // Update status based on quality
      if (quality < poorConnectionThreshold) {
        _updateStatus(NetworkStatus.poor, _connectionType);
      } else {
        _updateStatus(NetworkStatus.online, _connectionType);
      }
    } catch (e) {
      _pingLatency = 9999; // Very high latency indicates poor connection
      _networkQuality = 0.0;
      _updateStatus(NetworkStatus.poor, _connectionType);
    }
  }

  double _calculateNetworkQuality(int latency, ConnectionType connectionType) {
    double baseQuality;

    // Base quality by connection type
    switch (connectionType) {
      case ConnectionType.wifi:
        baseQuality = 1.0;
        break;
      case ConnectionType.ethernet:
        baseQuality = 1.0;
        break;
      case ConnectionType.mobile:
        baseQuality = 0.8;
        break;
      case ConnectionType.none:
        baseQuality = 0.0;
        break;
    }

    // Adjust quality based on latency
    if (latency <= fastPingThreshold) {
      return baseQuality;
    } else if (latency <= slowPingThreshold) {
      // Linear decrease from base quality to 0.3
      double factor = 1.0 -
          ((latency - fastPingThreshold) /
                  (slowPingThreshold - fastPingThreshold)) *
              0.7;
      return baseQuality * factor;
    } else {
      // Very poor connection
      return baseQuality * 0.1;
    }
  }

  void _updateStatus(NetworkStatus status, ConnectionType connectionType) {
    final previousStatus = _currentStatus;

    _currentStatus = status;
    _connectionType = connectionType;
    _hasInternetAccess =
        status == NetworkStatus.online || status == NetworkStatus.poor;

    // Track connection times
    _updateConnectionTimes(previousStatus, status);

    notifyListeners();
  }

  void _updateConnectionTimes(
      NetworkStatus previousStatus, NetworkStatus currentStatus) {
    final now = DateTime.now();

    if (previousStatus == NetworkStatus.offline &&
        (currentStatus == NetworkStatus.online ||
            currentStatus == NetworkStatus.poor)) {
      // Came online
      if (_lastDisconnectedTime != null) {
        _totalOfflineTime += now.difference(_lastDisconnectedTime!);
      }
    } else if ((previousStatus == NetworkStatus.online ||
            previousStatus == NetworkStatus.poor) &&
        currentStatus == NetworkStatus.offline) {
      // Went offline
      if (_lastConnectedTime != null) {
        _totalOnlineTime += now.difference(_lastConnectedTime!);
      }
    }
  }

  void _startNetworkQualityMonitoring() {
    _networkQualityTimer?.cancel();
    _networkQualityTimer = Timer.periodic(
      const Duration(seconds: 30),
      (timer) async {
        if (_hasInternetAccess) {
          await _measureNetworkQuality();
        }
      },
    );
  }

  /// Force refresh network status
  Future<void> refreshNetworkStatus() async {
    await _checkConnectivity();
  }

  /// Get network statistics
  Map<String, dynamic> getNetworkStatistics() {
    return {
      'currentStatus': _currentStatus.toString(),
      'connectionType': _connectionType.toString(),
      'networkQuality': _networkQuality,
      'pingLatency': _pingLatency,
      'hasInternetAccess': _hasInternetAccess,
      'lastConnectedTime': _lastConnectedTime?.toIso8601String(),
      'lastDisconnectedTime': _lastDisconnectedTime?.toIso8601String(),
      'totalOnlineTimeMinutes': _totalOnlineTime.inMinutes,
      'totalOfflineTimeMinutes': _totalOfflineTime.inMinutes,
    };
  }

  /// Check if specific features are available based on network status
  bool canPerformAction(String actionType) {
    switch (actionType) {
      case 'send_message':
      case 'ai_request':
        return _currentStatus == NetworkStatus.online;

      case 'upload_file':
      case 'download_content':
        return _currentStatus == NetworkStatus.online &&
            _networkQuality > poorConnectionThreshold;

      case 'sync_data':
        return _hasInternetAccess;

      case 'stream_audio':
      case 'video_call':
        return _currentStatus == NetworkStatus.online &&
            _networkQuality > goodConnectionThreshold;

      default:
        return _hasInternetAccess;
    }
  }

  /// Get user-friendly status message
  String getStatusMessage() {
    switch (_currentStatus) {
      case NetworkStatus.online:
        if (_networkQuality > goodConnectionThreshold) {
          return 'Excellent connection';
        } else {
          return 'Good connection';
        }
      case NetworkStatus.poor:
        return 'Poor connection - some features may be slow';
      case NetworkStatus.limited:
        return 'Limited connectivity - no internet access';
      case NetworkStatus.offline:
        return 'No connection - working offline';
    }
  }

  /// Get connection quality color for UI
  int getStatusColor() {
    switch (_currentStatus) {
      case NetworkStatus.online:
        return _networkQuality > goodConnectionThreshold
            ? 0xFF4CAF50
            : 0xFF8BC34A; // Green or light green
      case NetworkStatus.poor:
        return 0xFFFF9800; // Orange
      case NetworkStatus.limited:
        return 0xFFF44336; // Red
      case NetworkStatus.offline:
        return 0xFF9E9E9E; // Grey
    }
  }

  /// Wait for network connection with timeout
  Future<bool> waitForConnection(
      {Duration timeout = const Duration(seconds: 30)}) async {
    if (_hasInternetAccess) return true;

    final completer = Completer<bool>();
    late StreamSubscription subscription;

    subscription =
        Stream.periodic(const Duration(seconds: 1)).listen((_) async {
      await _checkConnectivity();
      if (_hasInternetAccess) {
        subscription.cancel();
        if (!completer.isCompleted) completer.complete(true);
      }
    });

    // Timeout fallback
    Timer(timeout, () {
      subscription.cancel();
      if (!completer.isCompleted) completer.complete(false);
    });

    return completer.future;
  }

  /// Dispose resources
  @override
  void dispose() {
    _connectivitySubscription.cancel();
    _networkQualityTimer?.cancel();
    super.dispose();
  }

  /// Reset statistics
  void resetStatistics() {
    _totalOnlineTime = Duration.zero;
    _totalOfflineTime = Duration.zero;
    _lastConnectedTime = null;
    _lastDisconnectedTime = null;
  }
}
