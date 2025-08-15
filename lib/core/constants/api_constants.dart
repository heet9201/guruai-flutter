import '../config/environment_config.dart';

class ApiConstants {
  // Get configuration from environment
  static final EnvironmentConfig _config = EnvironmentConfig.instance;

  // Base URLs - loaded from environment variables
  static String get baseUrl => _config.apiBaseUrl;
  static String get webSocketUrl => _config.webSocketUrl;

  // API timeout
  static Duration get timeout => _config.apiTimeout;

  // API Key (if needed for authentication)
  static String get apiKey => _config.apiKey;

  // API Endpoints

  // Authentication
  static const String register = '/auth/register';
  static const String login = '/auth/login';
  static const String refreshToken = '/auth/refresh';
  static const String verifyToken = '/auth/verify-token';
  static const String logout = '/auth/logout';
  static const String resetPassword = '/auth/reset-password';

  // User Profile
  static const String userProfile = '/user/profile';
  static const String userDevices = '/user/devices';
  static const String deleteAccount = '/user/delete';

  // AI & Chat
  static const String aiChat = '/chat';
  static const String aiVision = '/ai/vision';
  static const String aiSummary = '/ai/summary';
  static const String aiConversation = '/ai/conversation';
  static const String aiStatus = '/ai/status';
  static const String aiModels = '/ai/models';

  // Speech Services
  static const String speechToText = '/speech/speech-to-text';
  static const String textToSpeech = '/speech/text-to-speech';
  static const String uploadAudio = '/speech/upload';
  static const String batchTranscribe = '/speech/batch-transcribe';
  static const String speechStatus = '/speech/status';
  static const String supportedLanguages = '/speech/languages';

  // Content Generation
  static const String generateContent = '/content/generate';
  static const String contentHistory = '/content/history';
  static const String contentById = '/content';
  static const String exportContent = '/content/export';
  static const String contentVariants = '/content/variants';
  static const String contentTemplates = '/content/templates';
  static const String contentSuggestions = '/content/suggestions';
  static const String contentStatistics = '/content/statistics';

  // Weekly Planning
  static const String weeklyPlans = '/weekly-planning/plans';
  static const String planTemplates = '/weekly-planning/templates';
  static const String planActivities = '/weekly-planning/activities';
  static const String aiSuggestions = '/weekly-planning/suggest-activities';
  static const String schedulingOptimization = '/weekly-planning/optimize';
  static const String exportPlan = '/weekly-planning/export';

  // Dashboard & Analytics
  static const String dashboardOverview = '/dashboard/overview';
  static const String dashboardAnalytics = '/dashboard/analytics';
  static const String trackActivity = '/dashboard/track-activity';
  static const String refreshRecommendations =
      '/dashboard/recommendations/refresh';
  static const String performanceInsights = '/dashboard/performance-insights';

  // File Management
  static const String uploadFile = '/files/upload';
  static const String fileInfo = '/files';
  static const String downloadFile = '/files';
  static const String listFiles = '/files';
  static const String deleteFile = '/files';
  static const String fileStatistics = '/files/statistics';
  static const String shareFile = '/files/share';

  // WebSocket & Real-time
  static const String webSocketStats = '/websocket/stats';
  static const String activeRooms = '/websocket/rooms';
  static const String createRoom = '/websocket/rooms';
  static const String roomDetails = '/websocket/rooms';
  static const String roomUsers = '/websocket/rooms';
  static const String roomMessages = '/websocket/rooms';
  static const String userStatus = '/websocket/user-status';
  static const String broadcastMessage = '/websocket/broadcast';

  // Accessibility
  static const String accessibilitySettings = '/accessibility/settings';
  static const String accessibilityFeatures = '/accessibility/features';
  static const String adaptContent = '/accessibility/adapt-content';
  static const String generateAltText = '/accessibility/generate-alt-text';
  static const String voiceCommand = '/accessibility/voice-command';
  static const String validateCompliance = '/accessibility/validate-compliance';

  // Offline Sync
  static const String uploadOfflineData = '/offline-sync/upload';
  static const String downloadSyncData = '/offline-sync/download';
  static const String syncConflicts = '/offline-sync/conflicts';
  static const String resolveSyncConflict = '/offline-sync/resolve';
  static const String syncStatistics = '/offline-sync/statistics';
  static const String compressSyncData = '/offline-sync/compress';

  // Localization
  static const String localizedStrings = '/localization/strings';
  static const String supportedLangs = '/localization/languages';
  static const String translateText = '/localization/translate';
  static const String localizeContent = '/localization/localize';
  static const String detectLanguage = '/localization/detect';
  static const String rtlLanguages = '/localization/rtl';

  // Health & Monitoring
  static const String healthCheck = '/health';
  static const String readinessCheck = '/health/ready';
  static const String detailedStatus = '/health/status';
  static const String apiQuotas = '/health/quotas';
  static const String systemMetrics = '/monitoring/metrics';
  static const String performanceMetrics = '/monitoring/performance';
  static const String cacheStats = '/monitoring/cache';

  // HTTP Headers
  static const String authorizationHeader = 'Authorization';
  static const String contentTypeHeader = 'Content-Type';
  static const String acceptHeader = 'Accept';
  static const String userAgentHeader = 'User-Agent';

  // Storage Keys
  static const String accessTokenKey = 'access_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String userDataKey = 'user_data';
  static const String deviceIdKey = 'device_id';
  static const String languageKey = 'language';
  static const String offlineDataKey = 'offline_data';
  static const String lastSyncKey = 'last_sync';

  // App Configuration
  static const int connectionTimeoutMs = 30000;
  static const int receiveTimeoutMs = 30000;
  static const int sendTimeoutMs = 30000;
  static const int maxRetries = 3;
  static const int retryDelayMs = 1000;

  // File Upload Limits
  static const int maxFileSize = 100 * 1024 * 1024; // 100MB
  static const List<String> allowedImageTypes = [
    'jpg',
    'jpeg',
    'png',
    'gif',
    'webp'
  ];
  static const List<String> allowedDocumentTypes = [
    'pdf',
    'doc',
    'docx',
    'txt',
    'rtf'
  ];
  static const List<String> allowedAudioTypes = [
    'mp3',
    'wav',
    'ogg',
    'aac',
    'm4a'
  ];

  // Rate Limits (requests per minute)
  static const int loginRateLimit = 10;
  static const int registerRateLimit = 5;
  static const int chatRateLimit = 60;
  static const int contentGenerationRateLimit = 20;
  static const int fileUploadRateLimit = 10;

  // Content Generation Types
  static const List<String> contentTypes = [
    'story',
    'worksheet',
    'quiz',
    'lesson_plan',
    'visual_aid',
    'assessment',
    'activity',
    'game'
  ];

  // Supported Languages
  static const List<Map<String, String>> availableLanguages = [
    {'code': 'en', 'name': 'English', 'nativeName': 'English'},
    {'code': 'hi', 'name': 'Hindi', 'nativeName': 'हिंदी'},
    {'code': 'es', 'name': 'Spanish', 'nativeName': 'Español'},
    {'code': 'fr', 'name': 'French', 'nativeName': 'Français'},
    {'code': 'de', 'name': 'German', 'nativeName': 'Deutsch'},
    {'code': 'zh', 'name': 'Chinese', 'nativeName': '中文'},
  ];

  // Accessibility Features
  static const List<String> availableAccessibilityFeatures = [
    'screen_reader',
    'voice_navigation',
    'high_contrast',
    'large_text',
    'reduced_motion',
    'color_blind_support'
  ];

  // Activity Types
  static const List<String> activityTypes = [
    'lesson',
    'assignment',
    'assessment',
    'break',
    'activity',
    'discussion',
    'project',
    'review'
  ];

  // Subject Categories
  static const List<String> subjects = [
    'english',
    'mathematics',
    'science',
    'social_studies',
    'art',
    'physical_education',
    'music',
    'computer_science',
    'environmental_studies'
  ];

  // Grade Levels
  static const List<String> grades = [
    'nursery',
    'kg1',
    'kg2',
    'grade1',
    'grade2',
    'grade3',
    'grade4',
    'grade5',
    'grade6',
    'grade7',
    'grade8',
    'grade9',
    'grade10',
    'grade11',
    'grade12'
  ];
}
