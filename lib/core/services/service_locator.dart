import 'package:get_it/get_it.dart';
import '../../data/datasources/api_service.dart';
import '../../data/services/auth_service.dart';
import '../../data/services/chat_service.dart';
import '../../data/services/intelligent_chat_service.dart';
import '../../data/services/lazy_chat_service.dart';
import '../../data/services/content_service.dart';
import '../../data/services/weekly_planning_service.dart';
import '../../data/services/dashboard_service.dart';
import '../../data/services/file_service.dart';
import '../../data/services/speech_service.dart';
import '../../data/services/websocket_service.dart';
import '../config/environment_config.dart';

class ServiceLocator {
  static final GetIt _getIt = GetIt.instance;

  static void setup() {
    // Log environment configuration for debugging
    EnvironmentConfig.instance.logConfiguration();

    // Register API Client (Singleton)
    _getIt.registerLazySingleton<ApiClient>(() {
      final apiClient = ApiClient();
      apiClient.initialize();
      return apiClient;
    });

    // Register WebSocket Service (Singleton)
    _getIt.registerLazySingleton<WebSocketService>(() => WebSocketService());

    // Register API Services (Singletons)
    _getIt.registerLazySingleton<AuthService>(
      () => AuthService(_getIt<ApiClient>()),
    );

    _getIt.registerLazySingleton<ChatService>(
      () => ChatService(_getIt<ApiClient>()),
    );

    _getIt.registerLazySingleton<IntelligentChatService>(
      () => IntelligentChatService(apiClient: _getIt<ApiClient>()),
    );

    _getIt.registerLazySingleton<LazyChatService>(
      () => LazyChatService(apiClient: _getIt<ApiClient>()),
    );

    _getIt.registerLazySingleton<ContentService>(
      () => ContentService(_getIt<ApiClient>()),
    );

    _getIt.registerLazySingleton<WeeklyPlanningService>(
      () => WeeklyPlanningService(_getIt<ApiClient>()),
    );

    _getIt.registerLazySingleton<DashboardService>(
      () => DashboardService(_getIt<ApiClient>()),
    );

    _getIt.registerLazySingleton<FileService>(
      () => FileService(_getIt<ApiClient>()),
    );

    _getIt.registerLazySingleton<SpeechService>(
      () => SpeechService(_getIt<ApiClient>()),
    );
  }

  // Convenience getters
  static ApiClient get apiClient => _getIt<ApiClient>();
  static AuthService get authService => _getIt<AuthService>();
  static ChatService get chatService => _getIt<ChatService>();
  static IntelligentChatService get intelligentChatService =>
      _getIt<IntelligentChatService>();
  static LazyChatService get lazyChatService => _getIt<LazyChatService>();
  static ContentService get contentService => _getIt<ContentService>();
  static WeeklyPlanningService get weeklyPlanningService =>
      _getIt<WeeklyPlanningService>();
  static DashboardService get dashboardService => _getIt<DashboardService>();
  static FileService get fileService => _getIt<FileService>();
  static SpeechService get speechService => _getIt<SpeechService>();
  static WebSocketService get webSocketService => _getIt<WebSocketService>();

  // Register individual service if needed
  static void registerService<T extends Object>(T service) {
    if (!_getIt.isRegistered<T>()) {
      _getIt.registerSingleton<T>(service);
    }
  }

  // Unregister service
  static void unregisterService<T extends Object>() {
    if (_getIt.isRegistered<T>()) {
      _getIt.unregister<T>();
    }
  }

  // Reset all services
  static void reset() {
    _getIt.reset();
  }

  // Check if service is registered
  static bool isRegistered<T extends Object>() {
    return _getIt.isRegistered<T>();
  }
}
