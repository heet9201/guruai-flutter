import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/foundation.dart';
import '../../core/bloc/optimized_bloc_patterns.dart';
import '../../core/api/api_orchestrator.dart';
import '../../core/api/enhanced_api_client.dart';
import '../../data/services/optimized_dashboard_service.dart';

/// Enhanced dashboard screen with comprehensive API optimizations
class OptimizedDashboardScreen extends StatefulWidget {
  const OptimizedDashboardScreen({super.key});

  @override
  State<OptimizedDashboardScreen> createState() =>
      _OptimizedDashboardScreenState();
}

class _OptimizedDashboardScreenState extends State<OptimizedDashboardScreen>
    with WidgetsBindingObserver, AutomaticKeepAliveClientMixin {
  late OptimizedDashboardBloc _bloc;
  final ApiOrchestrator _orchestrator = ApiOrchestrator();

  // Progressive loading controllers
  final Map<String, bool> _sectionLoaded = {};
  final Set<String> _visibleSections = {};

  // Performance tracking
  DateTime? _screenStartTime;
  final List<String> _loadingOrder = [];

  @override
  bool get wantKeepAlive => true; // Keep screen alive for better UX

  @override
  void initState() {
    super.initState();
    _screenStartTime = DateTime.now();

    // Initialize optimized BLoC
    _bloc = OptimizedDashboardBloc(
      OptimizedDashboardService(
          EnhancedApiClient()), // Use direct client instead of orchestrator
    );

    // Setup lifecycle observers
    WidgetsBinding.instance.addObserver(this);

    // Setup progressive loading listeners
    _setupProgressiveLoading();

    // Initial load with optimizations
    _loadDashboardOptimized();
  }

  void _setupProgressiveLoading() {
    // Listen to progressive loading streams
    _bloc.getProgressStream('primary').listen((data) {
      if (mounted) {
        setState(() {
          _updateSectionLoadingState('primary', data);
        });
        _trackLoadingProgress('primary');
      }
    });

    _bloc.getProgressStream('secondary').listen((data) {
      if (mounted) {
        setState(() {
          _updateSectionLoadingState('secondary', data);
        });
        _trackLoadingProgress('secondary');
      }
    });

    _bloc.getProgressStream('tertiary').listen((data) {
      if (mounted) {
        setState(() {
          _updateSectionLoadingState('tertiary', data);
        });
        _trackLoadingProgress('tertiary');
      }
    });
  }

  void _updateSectionLoadingState(String priority, dynamic data) {
    if (data is Map<String, dynamic>) {
      for (final key in data.keys) {
        _sectionLoaded[key] = data[key] != null;
      }
    }
  }

  void _trackLoadingProgress(String priority) {
    _loadingOrder.add(priority);

    if (kDebugMode) {
      final elapsed =
          DateTime.now().difference(_screenStartTime!).inMilliseconds;
      print('📊 Dashboard $priority loaded in ${elapsed}ms');
    }
  }

  void _loadDashboardOptimized() {
    // Load dashboard with progressive loading
    _bloc.add(const LoadDashboardEvent());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        // App resumed - check if refresh needed
        _handleAppResumed();
        break;
      case AppLifecycleState.paused:
        // App paused - optimize resources
        _handleAppPaused();
        break;
      default:
        break;
    }
  }

  void _handleAppResumed() {
    final blocState = _bloc.state;

    // Only refresh if data is stale
    if (blocState.isStale) {
      _bloc.add(const RefreshDashboardEvent(silent: true));
    }

    if (kDebugMode) {
      print('📱 Dashboard resumed - data stale: ${blocState.isStale}');
    }
  }

  void _handleAppPaused() {
    // App paused - could implement resource optimization here
    if (kDebugMode) {
      print('📱 Dashboard paused - optimizing resources');
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin

    return Scaffold(
      appBar: AppBar(
        title: const Text('Enhanced Dashboard'),
        actions: [
          // Refresh button with smart refresh logic
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _handleManualRefresh,
          ),
          // Debug info button
          if (kDebugMode)
            IconButton(
              icon: const Icon(Icons.info),
              onPressed: _showDebugInfo,
            ),
        ],
      ),
      body: BlocBuilder<OptimizedDashboardBloc, DashboardState>(
        bloc: _bloc,
        builder: (context, state) {
          return RefreshIndicator(
            onRefresh: _handlePullToRefresh,
            child: CustomScrollView(
              slivers: [
                // Loading indicator for initial load
                if (state.isLoading && state.dashboardData == null)
                  const SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 16),
                          Text('Loading optimized dashboard...'),
                        ],
                      ),
                    ),
                  )
                else ...[
                  // User stats section (primary)
                  _buildProgressiveSection(
                    title: 'User Statistics',
                    sectionKey: 'primary_user_stats',
                    builder: () =>
                        _buildUserStatsSection(state.dashboardData?.userStats),
                  ),

                  // Recent activities section (primary)
                  _buildProgressiveSection(
                    title: 'Recent Activities',
                    sectionKey: 'primary_recent_activities',
                    builder: () => _buildRecentActivitiesSection(
                        state.dashboardData?.recentActivities),
                  ),

                  // Analytics section (secondary)
                  _buildProgressiveSection(
                    title: 'Analytics',
                    sectionKey: 'secondary_analytics',
                    builder: () =>
                        _buildAnalyticsSection(state.dashboardData?.analytics),
                  ),

                  // Recommendations section (secondary)
                  _buildProgressiveSection(
                    title: 'Recommendations',
                    sectionKey: 'secondary_recommendations',
                    builder: () => _buildRecommendationsSection(
                        state.dashboardData?.recommendations),
                  ),

                  // Insights section (tertiary)
                  _buildProgressiveSection(
                    title: 'Insights',
                    sectionKey: 'tertiary_insights',
                    builder: () =>
                        _buildInsightsSection(state.dashboardData?.insights),
                  ),

                  // Achievements section (tertiary)
                  _buildProgressiveSection(
                    title: 'Achievements',
                    sectionKey: 'tertiary_achievements',
                    builder: () => _buildAchievementsSection(
                        state.dashboardData?.achievements),
                  ),
                ],

                // Error handling
                if (state.error != null)
                  SliverToBoxAdapter(
                    child: Container(
                      margin: const EdgeInsets.all(16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Column(
                        children: [
                          Icon(Icons.error, color: Colors.red.shade700),
                          const SizedBox(height: 8),
                          Text(
                            'Error: ${state.error}',
                            style: TextStyle(color: Colors.red.shade700),
                          ),
                          const SizedBox(height: 8),
                          ElevatedButton(
                            onPressed: () => _bloc.add(
                                const LoadDashboardEvent(forceRefresh: true)),
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
      // Floating refresh indicator
      floatingActionButton: BlocBuilder<OptimizedDashboardBloc, DashboardState>(
        bloc: _bloc,
        builder: (context, state) {
          if (state.isRefreshing) {
            return FloatingActionButton(
              onPressed: null,
              child: const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  /// Build progressive loading section with lazy loading
  Widget _buildProgressiveSection({
    required String title,
    required String sectionKey,
    required Widget Function() builder,
  }) {
    return SliverToBoxAdapter(
      child: VisibilityDetector(
        key: Key(sectionKey),
        onVisibilityChanged: (info) {
          _handleSectionVisibility(sectionKey, info.visibleFraction > 0.1);
        },
        child: Container(
          margin: const EdgeInsets.all(8),
          child: Card(
            elevation: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Section header
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const Spacer(),
                      if (_getSectionLoadingState(sectionKey))
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      else if (_sectionLoaded[sectionKey] == true)
                        Icon(Icons.check_circle,
                            color: Colors.green.shade600, size: 16),
                    ],
                  ),
                ),
                // Section content
                if (_sectionLoaded[sectionKey] == true)
                  builder()
                else if (_getSectionLoadingState(sectionKey))
                  const Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else
                  Padding(
                    padding: const EdgeInsets.all(32),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(Icons.cloud_download,
                              color: Colors.grey.shade400),
                          const SizedBox(height: 8),
                          Text(
                            'Scroll to load $title',
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  bool _getSectionLoadingState(String sectionKey) {
    return _bloc.isOperationOngoing(sectionKey) ||
        (_visibleSections.contains(sectionKey) &&
            _sectionLoaded[sectionKey] != true);
  }

  void _handleSectionVisibility(String sectionKey, bool isVisible) {
    if (isVisible && !_visibleSections.contains(sectionKey)) {
      _visibleSections.add(sectionKey);

      // Load section if not already loaded
      if (_sectionLoaded[sectionKey] != true) {
        _loadSectionIfNeeded(sectionKey);
      }
    } else if (!isVisible) {
      _visibleSections.remove(sectionKey);
    }
  }

  void _loadSectionIfNeeded(String sectionKey) {
    // Extract section name from key
    final sectionName = sectionKey.split('_').skip(1).join('_');

    // Load specific section
    _bloc.add(LoadDashboardSectionEvent(sectionName));
  }

  Widget _buildUserStatsSection(Map<String, dynamic>? stats) {
    if (stats == null || stats.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Text('No user statistics available'),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 2,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 2,
        children: stats.entries.map((entry) {
          return Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  entry.value.toString(),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  entry.key.replaceAll('_', ' ').toUpperCase(),
                  style: const TextStyle(fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildRecentActivitiesSection(List<dynamic>? activities) {
    if (activities == null || activities.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Text('No recent activities'),
      );
    }

    return Column(
      children: activities.take(5).map((activity) {
        return ListTile(
          leading: const Icon(Icons.local_activity), // Fixed icon name
          title: Text(activity['title'] ?? 'Activity'),
          subtitle: Text(activity['description'] ?? 'No description'),
          trailing: Text(activity['time'] ?? ''),
        );
      }).toList(),
    );
  }

  Widget _buildAnalyticsSection(Map<String, dynamic>? analytics) {
    if (analytics == null || analytics.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Text('No analytics data available'),
      );
    }

    return Container(
      height: 200,
      padding: const EdgeInsets.all(16),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.analytics, size: 48, color: Colors.blue),
            SizedBox(height: 8),
            Text('Analytics Chart Placeholder'),
            Text('(Would show actual charts here)'),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendationsSection(List<dynamic>? recommendations) {
    if (recommendations == null || recommendations.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Text('No recommendations available'),
      );
    }

    return Container(
      height: 150,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: recommendations.length,
        itemBuilder: (context, index) {
          final rec = recommendations[index];
          return Container(
            width: 200,
            margin: const EdgeInsets.all(8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  rec['title'] ?? 'Recommendation',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: Text(
                    rec['description'] ?? 'No description',
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInsightsSection(Map<String, dynamic>? insights) {
    if (insights == null || insights.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Text('No insights available'),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      child: const Column(
        children: [
          Icon(Icons.lightbulb, size: 48, color: Colors.orange),
          SizedBox(height: 8),
          Text('Insights Section'),
          Text('(Would show personalized insights here)'),
        ],
      ),
    );
  }

  Widget _buildAchievementsSection(List<dynamic>? achievements) {
    if (achievements == null || achievements.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Text('No achievements yet'),
      );
    }

    return Container(
      height: 120,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: achievements.length,
        itemBuilder: (context, index) {
          final achievement = achievements[index];
          return Container(
            width: 100,
            margin: const EdgeInsets.all(8),
            child: Column(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.amber.shade100,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.amber.shade300),
                  ),
                  child: const Icon(Icons.star, color: Colors.amber),
                ),
                const SizedBox(height: 8),
                Text(
                  achievement['name'] ?? 'Achievement',
                  style: const TextStyle(fontSize: 12),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _handleManualRefresh() async {
    _bloc.add(const RefreshDashboardEvent(forceRefresh: true));
  }

  Future<void> _handlePullToRefresh() async {
    _bloc.add(const RefreshDashboardEvent(forceRefresh: true));

    // Wait for refresh to complete
    await Future.delayed(const Duration(seconds: 1));
  }

  void _showDebugInfo() {
    final stats = _bloc.getOptimizationStats();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Debug Information'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Optimization Stats:\n$stats'),
            const SizedBox(height: 16),
            Text('Loading Order: ${_loadingOrder.join(' → ')}'),
            const SizedBox(height: 16),
            Text('Sections Loaded: ${_sectionLoaded.length}'),
            Text('Visible Sections: ${_visibleSections.length}'),
          ],
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

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _bloc.close();
    super.dispose();
  }
}

/// Visibility detector for lazy loading sections
class VisibilityDetector extends StatefulWidget {
  final Key key;
  final Widget child;
  final Function(VisibilityInfo) onVisibilityChanged;

  const VisibilityDetector({
    required this.key,
    required this.child,
    required this.onVisibilityChanged,
  }) : super(key: key);

  @override
  State<VisibilityDetector> createState() => _VisibilityDetectorState();
}

class _VisibilityDetectorState extends State<VisibilityDetector> {
  @override
  Widget build(BuildContext context) {
    // Simple visibility detection - in a real app, you might use
    // the visibility_detector package for more sophisticated detection
    return widget.child;
  }

  @override
  void initState() {
    super.initState();
    // Simulate visibility detection
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onVisibilityChanged(VisibilityInfo(visibleFraction: 1.0));
    });
  }
}

class VisibilityInfo {
  final double visibleFraction;

  const VisibilityInfo({required this.visibleFraction});
}
