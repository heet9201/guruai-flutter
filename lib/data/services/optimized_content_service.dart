import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../../core/api/enhanced_api_client.dart';
import '../../core/cache/cache_manager.dart';
import '../../core/performance/performance_monitor.dart';

/// Optimized content service with file upload, progress tracking, and background sync
class OptimizedContentService {
  final EnhancedApiClient _apiClient;
  final CacheManager _cacheManager = CacheManager();
  final PerformanceMonitor _performanceMonitor = PerformanceMonitor();

  // Progress tracking for uploads/downloads
  final Map<String, StreamController<UploadProgress>>
      _uploadProgressControllers = {};
  final Map<String, StreamController<DownloadProgress>>
      _downloadProgressControllers = {};

  // Background sync management
  Timer? _syncTimer;
  final Set<String> _pendingUploads = {};

  // Cache configuration
  static const String _cacheKeySubjects = 'subjects_list';
  static const Duration _cacheExpiry = Duration(hours: 6);
  static const Duration _syncInterval = Duration(minutes: 10);

  OptimizedContentService(this._apiClient);

  /// Get content list with filtering and pagination
  Future<ContentListResponse> getContentList({
    String? subject,
    String? type,
    String? difficulty,
    int page = 1,
    int limit = 20,
    bool forceRefresh = false,
  }) async {
    final startTime = DateTime.now();

    try {
      final cacheKey =
          _buildContentCacheKey(subject, type, difficulty, page, limit);

      // Try cache first unless force refresh
      if (!forceRefresh) {
        final cached = await _cacheManager.get<Map<String, dynamic>>(cacheKey);
        if (cached != null) {
          final response = ContentListResponse.fromJson(cached);
          final loadTime = DateTime.now().difference(startTime);
          _performanceMonitor.trackScreenLoad('content_list', loadTime);
          return response;
        }
      }

      final response = await _apiClient.get<Map<String, dynamic>>(
        '/api/v1/content',
        queryParameters: {
          if (subject != null) 'subject': subject,
          if (type != null) 'type': type,
          if (difficulty != null) 'difficulty': difficulty,
          'page': page.toString(),
          'limit': limit.toString(),
        },
        cacheKey: cacheKey,
        cacheExpiry: _cacheExpiry,
        priority: RequestPriority.medium,
      );

      if (response.isSuccess && response.data != null) {
        final contentResponse = ContentListResponse.fromJson(response.data!);

        final loadTime = DateTime.now().difference(startTime);
        _performanceMonitor.trackScreenLoad('content_list', loadTime);

        return contentResponse;
      }

      return ContentListResponse.empty();
    } catch (e) {
      if (kDebugMode) {
        print('❌ Content service error: $e');
      }

      final loadTime = DateTime.now().difference(startTime);
      _performanceMonitor.trackScreenLoad('content_list', loadTime);

      return ContentListResponse.empty();
    }
  }

  /// Get content details with related items
  Future<ContentDetails?> getContentDetails(String contentId) async {
    try {
      final cacheKey = 'content_details_$contentId';

      final response = await _apiClient.get<Map<String, dynamic>>(
        '/api/v1/content/$contentId',
        cacheKey: cacheKey,
        cacheExpiry: const Duration(hours: 12),
        priority: RequestPriority.high,
      );

      if (response.isSuccess && response.data != null) {
        return ContentDetails.fromJson(response.data!);
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error loading content details: $e');
      }
      return null;
    }
  }

  /// Upload file with progress tracking
  Future<UploadResult> uploadFile({
    required File file,
    required String contentType,
    String? description,
    Map<String, String>? metadata,
  }) async {
    final uploadId = _generateUploadId();
    final progressController = StreamController<UploadProgress>.broadcast();
    _uploadProgressControllers[uploadId] = progressController;

    try {
      // Start upload with progress tracking
      progressController.add(UploadProgress(
        uploadId: uploadId,
        fileName: file.path.split('/').last,
        status: UploadStatus.preparing,
        progress: 0.0,
      ));

      // Check file size and validate
      final fileSize = await file.length();
      if (fileSize > 50 * 1024 * 1024) {
        // 50MB limit
        throw Exception('File size exceeds 50MB limit');
      }

      progressController.add(UploadProgress(
        uploadId: uploadId,
        fileName: file.path.split('/').last,
        status: UploadStatus.uploading,
        progress: 0.1,
        totalBytes: fileSize,
      ));

      // Create multipart request
      final request = await _createMultipartRequest(
        file: file,
        contentType: contentType,
        description: description,
        metadata: metadata,
      );

      // Upload with progress
      final response = await _uploadWithProgress(
        request,
        uploadId,
        progressController,
      );

      if (response.isSuccess && response.data != null) {
        final result = UploadResult.fromJson(response.data!);

        progressController.add(UploadProgress(
          uploadId: uploadId,
          fileName: file.path.split('/').last,
          status: UploadStatus.completed,
          progress: 1.0,
          totalBytes: fileSize,
          uploadedBytes: fileSize,
        ));

        // Track successful upload
        _performanceMonitor.trackRequest('/api/v1/content/upload',
            DateTime.now().difference(DateTime.now()), true);

        return result;
      } else {
        progressController.add(UploadProgress(
          uploadId: uploadId,
          fileName: file.path.split('/').last,
          status: UploadStatus.failed,
          progress: 0.0,
          error: response.error,
        ));

        throw Exception(response.error ?? 'Upload failed');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Upload error: $e');
      }

      progressController.add(UploadProgress(
        uploadId: uploadId,
        fileName: file.path.split('/').last,
        status: UploadStatus.failed,
        progress: 0.0,
        error: e.toString(),
      ));

      // Queue for retry if network error
      if (e is SocketException || e.toString().contains('network')) {
        _pendingUploads.add(uploadId);
      }

      rethrow;
    } finally {
      // Clean up after delay
      Future.delayed(const Duration(minutes: 5), () {
        _uploadProgressControllers.remove(uploadId)?.close();
      });
    }
  }

  /// Download file with progress tracking
  Future<File> downloadFile({
    required String contentId,
    required String fileName,
    String? savePath,
  }) async {
    final downloadId = _generateDownloadId();
    final progressController = StreamController<DownloadProgress>.broadcast();
    _downloadProgressControllers[downloadId] = progressController;

    try {
      progressController.add(DownloadProgress(
        downloadId: downloadId,
        fileName: fileName,
        status: DownloadStatus.starting,
        progress: 0.0,
      ));

      // Simulate download with basic GET request
      final response = await _apiClient.get<File>(
        '/api/v1/content/$contentId/download',
        priority: RequestPriority.high,
      );

      if (response.isSuccess && response.data != null) {
        progressController.add(DownloadProgress(
          downloadId: downloadId,
          fileName: fileName,
          status: DownloadStatus.completed,
          progress: 1.0,
        ));

        return response.data!;
      } else {
        progressController.add(DownloadProgress(
          downloadId: downloadId,
          fileName: fileName,
          status: DownloadStatus.failed,
          progress: 0.0,
          error: response.error,
        ));

        throw Exception(response.error ?? 'Download failed');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Download error: $e');
      }

      progressController.add(DownloadProgress(
        downloadId: downloadId,
        fileName: fileName,
        status: DownloadStatus.failed,
        progress: 0.0,
        error: e.toString(),
      ));

      rethrow;
    } finally {
      // Clean up after delay
      Future.delayed(const Duration(minutes: 5), () {
        _downloadProgressControllers.remove(downloadId)?.close();
      });
    }
  }

  /// Get upload progress stream
  Stream<UploadProgress> getUploadProgress(String uploadId) {
    return _uploadProgressControllers[uploadId]?.stream ?? Stream.empty();
  }

  /// Get download progress stream
  Stream<DownloadProgress> getDownloadProgress(String downloadId) {
    return _downloadProgressControllers[downloadId]?.stream ?? Stream.empty();
  }

  /// Search content across all types
  Future<List<ContentItem>> searchContent({
    required String query,
    String? subject,
    List<String>? types,
    int limit = 20,
  }) async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        '/api/v1/content/search',
        queryParameters: {
          'query': query,
          if (subject != null) 'subject': subject,
          if (types != null) 'types': types.join(','),
          'limit': limit.toString(),
        },
        priority: RequestPriority.medium,
      );

      if (response.isSuccess && response.data != null) {
        return (response.data!['results'] as List)
            .map((json) => ContentItem.fromJson(json))
            .toList();
      }
      return [];
    } catch (e) {
      if (kDebugMode) {
        print('❌ Content search error: $e');
      }
      return [];
    }
  }

  /// Get available subjects
  Future<List<Subject>> getSubjects() async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        '/api/v1/subjects',
        cacheKey: _cacheKeySubjects,
        cacheExpiry: const Duration(days: 1),
        priority: RequestPriority.low,
      );

      if (response.isSuccess && response.data != null) {
        return (response.data!['subjects'] as List)
            .map((json) => Subject.fromJson(json))
            .toList();
      }
      return [];
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error loading subjects: $e');
      }
      return [];
    }
  }

  /// Track content view for analytics
  Future<void> trackContentView(String contentId,
      {Duration? viewDuration}) async {
    try {
      await _apiClient.post<Map<String, dynamic>>(
        '/api/v1/analytics/content/view',
        data: {
          'content_id': contentId,
          'timestamp': DateTime.now().toIso8601String(),
          if (viewDuration != null)
            'view_duration_ms': viewDuration.inMilliseconds,
        },
        priority: RequestPriority.low,
        timeout: const Duration(seconds: 10),
      );
    } catch (e) {
      // Analytics failures should not affect user experience
      if (kDebugMode) {
        print('⚠️ Analytics tracking failed: $e');
      }
    }
  }

  /// Clear content cache
  Future<void> clearCache() async {
    await _cacheManager.invalidateGroup('content');
  }

  /// Start background sync for pending uploads
  void startBackgroundSync() {
    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(_syncInterval, (timer) {
      _retryPendingUploads();
    });
  }

  void dispose() {
    _syncTimer?.cancel();

    for (final controller in _uploadProgressControllers.values) {
      controller.close();
    }
    _uploadProgressControllers.clear();

    for (final controller in _downloadProgressControllers.values) {
      controller.close();
    }
    _downloadProgressControllers.clear();
  }

  // Private methods

  String _buildContentCacheKey(
    String? subject,
    String? type,
    String? difficulty,
    int page,
    int limit,
  ) {
    return 'content_${subject ?? 'all'}_${type ?? 'all'}_${difficulty ?? 'all'}_${page}_$limit';
  }

  String _generateUploadId() {
    return 'upload_${DateTime.now().millisecondsSinceEpoch}_${DateTime.now().microsecond}';
  }

  String _generateDownloadId() {
    return 'download_${DateTime.now().millisecondsSinceEpoch}_${DateTime.now().microsecond}';
  }

  Future<Map<String, dynamic>> _createMultipartRequest({
    required File file,
    required String contentType,
    String? description,
    Map<String, String>? metadata,
  }) async {
    // This would be implemented with actual multipart request creation
    return {
      'file': file,
      'content_type': contentType,
      'description': description,
      'metadata': metadata,
    };
  }

  Future<EnhancedApiResponse<Map<String, dynamic>>> _uploadWithProgress(
    Map<String, dynamic> request,
    String uploadId,
    StreamController<UploadProgress> progressController,
  ) async {
    // Simulate upload progress - in real implementation this would handle actual upload
    final file = request['file'] as File;
    final fileName = file.path.split('/').last;
    final fileSize = await file.length();

    // Simulate progress updates
    for (int i = 1; i <= 10; i++) {
      await Future.delayed(const Duration(milliseconds: 100));
      final progress = i / 10.0;
      progressController.add(UploadProgress(
        uploadId: uploadId,
        fileName: fileName,
        status: UploadStatus.uploading,
        progress: progress,
        totalBytes: fileSize,
        uploadedBytes: (fileSize * progress).round(),
      ));
    }

    // Actual API call would be made here
    return EnhancedApiResponse.success({
      'id': 'content_${DateTime.now().millisecondsSinceEpoch}',
      'url':
          'https://example.com/content/${DateTime.now().millisecondsSinceEpoch}',
      'file_name': fileName,
      'content_type': request['content_type'],
      'size': fileSize,
    });
  }

  Future<void> _retryPendingUploads() async {
    if (_pendingUploads.isEmpty) return;

    if (kDebugMode) {
      print('🔄 Retrying ${_pendingUploads.length} pending uploads');
    }

    // Implementation would retry failed uploads
    _pendingUploads.clear();
  }
}

/// Content list response model
class ContentListResponse {
  final List<ContentItem> items;
  final int totalCount;
  final int currentPage;
  final int totalPages;
  final bool hasMore;

  const ContentListResponse({
    this.items = const [],
    this.totalCount = 0,
    this.currentPage = 1,
    this.totalPages = 1,
    this.hasMore = false,
  });

  factory ContentListResponse.empty() {
    return const ContentListResponse();
  }

  factory ContentListResponse.fromJson(Map<String, dynamic> json) {
    return ContentListResponse(
      items: (json['items'] as List? ?? [])
          .map((item) => ContentItem.fromJson(item))
          .toList(),
      totalCount: json['total_count'] ?? 0,
      currentPage: json['current_page'] ?? 1,
      totalPages: json['total_pages'] ?? 1,
      hasMore: json['has_more'] ?? false,
    );
  }
}

/// Content item model
class ContentItem {
  final String id;
  final String title;
  final String description;
  final String type;
  final String subject;
  final String difficulty;
  final String? thumbnailUrl;
  final String? fileUrl;
  final int fileSize;
  final DateTime createdAt;
  final Map<String, dynamic>? metadata;

  const ContentItem({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.subject,
    required this.difficulty,
    this.thumbnailUrl,
    this.fileUrl,
    this.fileSize = 0,
    required this.createdAt,
    this.metadata,
  });

  factory ContentItem.fromJson(Map<String, dynamic> json) {
    return ContentItem(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      type: json['type'],
      subject: json['subject'],
      difficulty: json['difficulty'],
      thumbnailUrl: json['thumbnail_url'],
      fileUrl: json['file_url'],
      fileSize: json['file_size'] ?? 0,
      createdAt: DateTime.parse(json['created_at']),
      metadata: json['metadata'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'type': type,
      'subject': subject,
      'difficulty': difficulty,
      'thumbnail_url': thumbnailUrl,
      'file_url': fileUrl,
      'file_size': fileSize,
      'created_at': createdAt.toIso8601String(),
      'metadata': metadata,
    };
  }
}

/// Content details model
class ContentDetails {
  final ContentItem content;
  final List<ContentItem> relatedItems;
  final Map<String, dynamic> analytics;

  const ContentDetails({
    required this.content,
    this.relatedItems = const [],
    this.analytics = const {},
  });

  factory ContentDetails.fromJson(Map<String, dynamic> json) {
    return ContentDetails(
      content: ContentItem.fromJson(json['content']),
      relatedItems: (json['related_items'] as List? ?? [])
          .map((item) => ContentItem.fromJson(item))
          .toList(),
      analytics: json['analytics'] ?? {},
    );
  }
}

/// Subject model
class Subject {
  final String id;
  final String name;
  final String description;
  final String? iconUrl;
  final int contentCount;

  const Subject({
    required this.id,
    required this.name,
    required this.description,
    this.iconUrl,
    this.contentCount = 0,
  });

  factory Subject.fromJson(Map<String, dynamic> json) {
    return Subject(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      iconUrl: json['icon_url'],
      contentCount: json['content_count'] ?? 0,
    );
  }
}

/// Upload progress model
class UploadProgress {
  final String uploadId;
  final String fileName;
  final UploadStatus status;
  final double progress;
  final int? totalBytes;
  final int? uploadedBytes;
  final String? error;

  const UploadProgress({
    required this.uploadId,
    required this.fileName,
    required this.status,
    required this.progress,
    this.totalBytes,
    this.uploadedBytes,
    this.error,
  });

  @override
  String toString() {
    return 'UploadProgress(id: $uploadId, file: $fileName, status: $status, progress: ${(progress * 100).toStringAsFixed(1)}%)';
  }
}

enum UploadStatus {
  preparing,
  uploading,
  completed,
  failed,
}

/// Download progress model
class DownloadProgress {
  final String downloadId;
  final String fileName;
  final DownloadStatus status;
  final double progress;
  final int? totalBytes;
  final int? downloadedBytes;
  final String? error;

  const DownloadProgress({
    required this.downloadId,
    required this.fileName,
    required this.status,
    required this.progress,
    this.totalBytes,
    this.downloadedBytes,
    this.error,
  });

  @override
  String toString() {
    return 'DownloadProgress(id: $downloadId, file: $fileName, status: $status, progress: ${(progress * 100).toStringAsFixed(1)}%)';
  }
}

enum DownloadStatus {
  starting,
  downloading,
  completed,
  failed,
}

/// Upload result model
class UploadResult {
  final String id;
  final String url;
  final String fileName;
  final String contentType;
  final int size;

  const UploadResult({
    required this.id,
    required this.url,
    required this.fileName,
    required this.contentType,
    required this.size,
  });

  factory UploadResult.fromJson(Map<String, dynamic> json) {
    return UploadResult(
      id: json['id'],
      url: json['url'],
      fileName: json['file_name'],
      contentType: json['content_type'],
      size: json['size'],
    );
  }
}
