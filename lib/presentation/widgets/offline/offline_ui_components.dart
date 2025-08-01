import 'package:flutter/material.dart';
import '../../../core/services/network_connectivity_service.dart';
import '../../../core/services/sync_service.dart';
import '../../../data/repositories/offline_repository.dart';

/// Offline status indicator widget
class OfflineStatusWidget extends StatelessWidget {
  final bool showWhenOnline;
  final EdgeInsets padding;
  final bool compact;

  const OfflineStatusWidget({
    super.key,
    this.showWhenOnline = false,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: NetworkConnectivityService.instance,
      builder: (context, child) {
        final networkService = NetworkConnectivityService.instance;
        final theme = Theme.of(context);

        // Don't show when online unless explicitly requested
        if (networkService.isOnline && !showWhenOnline) {
          return const SizedBox.shrink();
        }

        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: padding,
          color: Color(networkService.getStatusColor()).withOpacity(0.1),
          child: Row(
            children: [
              Icon(
                _getStatusIcon(networkService.currentStatus),
                color: Color(networkService.getStatusColor()),
                size: compact ? 16 : 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      networkService.getStatusMessage(),
                      style: compact
                          ? theme.textTheme.bodySmall?.copyWith(
                              color: Color(networkService.getStatusColor()),
                              fontWeight: FontWeight.w500,
                            )
                          : theme.textTheme.bodyMedium?.copyWith(
                              color: Color(networkService.getStatusColor()),
                              fontWeight: FontWeight.w500,
                            ),
                    ),
                    if (!compact && !networkService.isOnline)
                      Text(
                        'Some features are limited',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.textTheme.bodySmall?.color
                              ?.withOpacity(0.7),
                        ),
                      ),
                  ],
                ),
              ),
              if (!networkService.isOnline)
                TextButton(
                  onPressed: () => networkService.refreshNetworkStatus(),
                  child: Text(
                    'Retry',
                    style: TextStyle(
                      color: Color(networkService.getStatusColor()),
                      fontSize: compact ? 12 : 14,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  IconData _getStatusIcon(NetworkStatus status) {
    switch (status) {
      case NetworkStatus.online:
        return Icons.wifi;
      case NetworkStatus.poor:
        return Icons.wifi_1_bar;
      case NetworkStatus.limited:
        return Icons.wifi_off;
      case NetworkStatus.offline:
        return Icons.cloud_off;
    }
  }
}

/// Sync status indicator widget
class SyncStatusWidget extends StatelessWidget {
  final bool showWhenIdle;
  final EdgeInsets padding;
  final bool compact;

  const SyncStatusWidget({
    super.key,
    this.showWhenIdle = false,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: SyncService.instance,
      builder: (context, child) {
        final syncService = SyncService.instance;
        final theme = Theme.of(context);

        // Don't show when idle unless explicitly requested
        if (syncService.currentSyncStatus == SyncStatus.idle && !showWhenIdle) {
          return const SizedBox.shrink();
        }

        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: padding,
          decoration: BoxDecoration(
            color: _getSyncStatusColor(syncService.currentSyncStatus)
                .withOpacity(0.1),
            border: Border(
              left: BorderSide(
                color: _getSyncStatusColor(syncService.currentSyncStatus),
                width: 3,
              ),
            ),
          ),
          child: Row(
            children: [
              if (syncService.currentSyncStatus == SyncStatus.syncing)
                SizedBox(
                  width: compact ? 16 : 20,
                  height: compact ? 16 : 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      _getSyncStatusColor(syncService.currentSyncStatus),
                    ),
                    value: syncService.currentProgress?.progress,
                  ),
                )
              else
                Icon(
                  _getSyncStatusIcon(syncService.currentSyncStatus),
                  color: _getSyncStatusColor(syncService.currentSyncStatus),
                  size: compact ? 16 : 20,
                ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _getSyncStatusText(syncService.currentSyncStatus),
                      style: compact
                          ? theme.textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w500,
                            )
                          : theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                    ),
                    if (!compact && syncService.currentProgress != null)
                      Text(
                        '${syncService.currentProgress!.completedItems}/${syncService.currentProgress!.totalItems} items',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.textTheme.bodySmall?.color
                              ?.withOpacity(0.7),
                        ),
                      ),
                  ],
                ),
              ),
              if (syncService.currentSyncStatus == SyncStatus.failed)
                TextButton(
                  onPressed: () => syncService.forceRetry(),
                  child: Text(
                    'Retry',
                    style: TextStyle(
                      color: _getSyncStatusColor(syncService.currentSyncStatus),
                      fontSize: compact ? 12 : 14,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Color _getSyncStatusColor(SyncStatus status) {
    switch (status) {
      case SyncStatus.idle:
        return Colors.grey;
      case SyncStatus.syncing:
        return Colors.blue;
      case SyncStatus.completed:
        return Colors.green;
      case SyncStatus.failed:
        return Colors.red;
      case SyncStatus.cancelled:
        return Colors.orange;
    }
  }

  IconData _getSyncStatusIcon(SyncStatus status) {
    switch (status) {
      case SyncStatus.idle:
        return Icons.sync;
      case SyncStatus.syncing:
        return Icons.sync;
      case SyncStatus.completed:
        return Icons.check_circle;
      case SyncStatus.failed:
        return Icons.error;
      case SyncStatus.cancelled:
        return Icons.cancel;
    }
  }

  String _getSyncStatusText(SyncStatus status) {
    switch (status) {
      case SyncStatus.idle:
        return 'Up to date';
      case SyncStatus.syncing:
        return 'Syncing...';
      case SyncStatus.completed:
        return 'Sync completed';
      case SyncStatus.failed:
        return 'Sync failed';
      case SyncStatus.cancelled:
        return 'Sync cancelled';
    }
  }
}

/// Offline badge for cached content
class OfflineBadge extends StatelessWidget {
  final bool isOfflineContent;
  final String? cacheTime;
  final VoidCallback? onRefresh;

  const OfflineBadge({
    super.key,
    required this.isOfflineContent,
    this.cacheTime,
    this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    if (!isOfflineContent) return const SizedBox.shrink();

    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.1),
        border: Border.all(color: Colors.orange, width: 1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.cloud_off,
            size: 14,
            color: Colors.orange,
          ),
          const SizedBox(width: 4),
          Text(
            cacheTime != null ? 'Cached $cacheTime' : 'Offline',
            style: theme.textTheme.bodySmall?.copyWith(
              color: Colors.orange,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (onRefresh != null) ...[
            const SizedBox(width: 4),
            GestureDetector(
              onTap: onRefresh,
              child: const Icon(
                Icons.refresh,
                size: 14,
                color: Colors.orange,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Offline-aware action button
class OfflineAwareButton extends StatelessWidget {
  final String text;
  final IconData? icon;
  final VoidCallback? onPressed;
  final VoidCallback? onOfflinePressed;
  final String? offlineText;
  final String actionType;
  final bool enabled;
  final ButtonStyle? style;

  const OfflineAwareButton({
    super.key,
    required this.text,
    this.icon,
    this.onPressed,
    this.onOfflinePressed,
    this.offlineText,
    required this.actionType,
    this.enabled = true,
    this.style,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: NetworkConnectivityService.instance,
      builder: (context, child) {
        final networkService = NetworkConnectivityService.instance;
        final canPerformAction = networkService.canPerformAction(actionType);
        final isEffectivelyEnabled =
            enabled && (canPerformAction || onOfflinePressed != null);

        return ElevatedButton.icon(
          onPressed: isEffectivelyEnabled
              ? (canPerformAction ? onPressed : onOfflinePressed)
              : null,
          icon: icon != null
              ? Icon(
                  canPerformAction ? icon : Icons.cloud_off,
                  size: 18,
                )
              : null,
          label: Text(
            canPerformAction ? text : (offlineText ?? '$text (Offline)'),
          ),
          style: style?.copyWith(
            backgroundColor: canPerformAction
                ? null
                : MaterialStateProperty.all(Colors.grey),
          ),
        );
      },
    );
  }
}

/// Loading state with offline context
class OfflineAwareLoadingWidget extends StatelessWidget {
  final String? message;
  final bool showOfflineMessage;
  final VoidCallback? onRetry;

  const OfflineAwareLoadingWidget({
    super.key,
    this.message,
    this.showOfflineMessage = true,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: NetworkConnectivityService.instance,
      builder: (context, child) {
        final networkService = NetworkConnectivityService.instance;
        final theme = Theme.of(context);

        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (networkService.isOnline)
                const CircularProgressIndicator()
              else
                Icon(
                  Icons.cloud_off,
                  size: 64,
                  color: theme.disabledColor,
                ),
              const SizedBox(height: 16),
              Text(
                message ??
                    (networkService.isOnline
                        ? 'Loading...'
                        : 'No internet connection'),
                style: theme.textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              if (!networkService.isOnline && showOfflineMessage) ...[
                const SizedBox(height: 8),
                Text(
                  'Please check your connection and try again',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
              if (onRetry != null) ...[
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

/// Cache management settings widget
class CacheManagementWidget extends StatelessWidget {
  const CacheManagementWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: OfflineRepository.instance.getCacheStatistics(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final stats = snapshot.data!;
        final theme = Theme.of(context);

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Cache Storage',
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 16),
                _buildCacheStatRow(
                  'AI Responses',
                  '${stats['aiResponsesCount']} items',
                  Icons.chat,
                ),
                _buildCacheStatRow(
                  'User Content',
                  '${stats['userContentCount']} items',
                  Icons.person,
                ),
                _buildCacheStatRow(
                  'Lesson Plans',
                  '${stats['lessonPlansCount']} plans',
                  Icons.school,
                ),
                _buildCacheStatRow(
                  'FAQs',
                  '${stats['faqsCount']} questions',
                  Icons.help,
                ),
                const SizedBox(height: 16),
                LinearProgressIndicator(
                  value: (stats['cacheUsagePercent'] as double) / 100,
                  backgroundColor: Colors.grey[300],
                  valueColor: AlwaysStoppedAnimation<Color>(
                    (stats['cacheUsagePercent'] as double) > 80
                        ? Colors.red
                        : Colors.blue,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${(stats['totalSizeMB'] as double).toStringAsFixed(1)} MB / ${stats['maxSizeMB']} MB used',
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _showClearCacheDialog(context),
                        icon: const Icon(Icons.delete_outline),
                        label: const Text('Clear Cache'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () =>
                            _showCacheDetailsDialog(context, stats),
                        icon: const Icon(Icons.info_outline),
                        label: const Text('Details'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCacheStatRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Expanded(child: Text(label)),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  void _showClearCacheDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Cache'),
        content: const Text(
          'This will remove all cached content. You may need to reload data when online.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              await OfflineRepository.instance.clearAllCache();
              if (context.mounted) {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Cache cleared successfully')),
                );
              }
            },
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  void _showCacheDetailsDialog(
      BuildContext context, Map<String, dynamic> stats) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cache Details'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                  'Total Size: ${(stats['totalSizeMB'] as double).toStringAsFixed(2)} MB'),
              Text(
                  'Usage: ${(stats['cacheUsagePercent'] as double).toStringAsFixed(1)}%'),
              Text('AI Responses: ${stats['aiResponsesCount']} items'),
              Text('User Content: ${stats['userContentCount']} items'),
              Text('Lesson Plans: ${stats['lessonPlansCount']} plans'),
              Text('FAQs: ${stats['faqsCount']} questions'),
              Text('Pending Sync: ${stats['queueCount']} items'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
