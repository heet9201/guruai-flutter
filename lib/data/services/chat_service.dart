import '../models/api_models.dart';
import '../datasources/api_service.dart';
import '../../core/constants/api_constants.dart';
import '../../core/services/service_locator.dart';

class ChatService {
  final ApiClient _apiClient;

  ChatService(this._apiClient);

  Future<ChatResponse> sendMessage({
    required String message,
    String? conversationId,
    Map<String, dynamic>? context,
    int maxTokens = 1000,
    double temperature = 0.7,
  }) async {
    try {
      // Get current user ID from auth service
      final userService = ServiceLocator.authService;
      final currentUser = await userService.getCurrentUser();
      final userId = currentUser?.id;

      final chatRequest = ChatRequest(
        message: message,
        userId: userId,
        conversationId: conversationId,
        context: context ??
            {
              'conversation_id': conversationId ??
                  'conv_${DateTime.now().millisecondsSinceEpoch}',
              'previous_messages': []
            },
        maxTokens: maxTokens,
        temperature: temperature,
      );

      print(
          '🔤 ChatService: Sending message with request: ${chatRequest.toJson()}');

      final response = await _apiClient.post<ChatResponse>(
        ApiConstants.aiChat,
        data: chatRequest.toJson(),
        fromJson: (json) {
          print('🔍 ChatService: Raw response: $json');
          return ChatResponse.fromJson(json);
        },
      );

      if (response.isSuccess && response.data != null) {
        print('✅ ChatService: API response successful');
        return response.data!;
      } else {
        print('⚠️ ChatService: API failed, using demo response');
        // If API fails, provide a demo response
        return _createDemoResponse(message, conversationId);
      }
    } catch (e) {
      // If there's any error (network, auth, etc.), provide a demo response
      print('❌ Chat API Error: $e');
      return _createDemoResponse(message, conversationId);
    }
  }

  ChatResponse _createDemoResponse(String userMessage, String? conversationId) {
    // Create intelligent demo responses based on user input
    String response = _generateDemoResponse(userMessage);

    return ChatResponse(
      response: response,
      conversationId: conversationId ??
          'demo_conversation_${DateTime.now().millisecondsSinceEpoch}',
      status: 'success',
      suggestions: _generateSuggestions(userMessage),
    );
  }

  String _generateDemoResponse(String userMessage) {
    final message = userMessage.toLowerCase();

    // Educational responses
    if (message.contains('math') || message.contains('mathematics')) {
      return '🧮 I can help you with mathematics! Whether it\'s basic arithmetic, algebra, geometry, or calculus, I\'m here to make math fun and easy to understand. What specific math topic would you like to explore?';
    } else if (message.contains('science')) {
      return '🔬 Science is fascinating! I can help you understand physics, chemistry, biology, and earth science concepts. What scientific phenomena would you like to learn about today?';
    } else if (message.contains('english') || message.contains('language')) {
      return '📚 Let\'s improve your English skills! I can help with grammar, vocabulary, reading comprehension, creative writing, and literature analysis. What aspect of English would you like to work on?';
    } else if (message.contains('history')) {
      return '🏛️ History is full of amazing stories! I can help you explore different time periods, civilizations, and historical events. What historical topic interests you most?';
    } else if (message.contains('art') || message.contains('creative')) {
      return '🎨 Creativity is wonderful! I can help you explore different art forms, techniques, and creative expression. What type of artistic project are you working on?';
    } else if (message.contains('hello') || message.contains('hi')) {
      return '👋 Hello! I\'m Sahayak, your AI learning assistant. I\'m here to help you learn and explore various subjects. How can I assist you today?';
    } else if (message.contains('help')) {
      return '💡 I\'m here to help! You can ask me about:\n• Mathematics and problem-solving\n• Science concepts and experiments\n• English language and literature\n• History and social studies\n• Art and creative projects\n• Study tips and learning strategies\n\nWhat would you like to learn about?';
    } else {
      return '🤔 That\'s an interesting question! While I\'m currently in demo mode, I can still help you explore this topic. In the full version, I would provide detailed, personalized responses based on your learning level and interests. What specific aspect would you like to know more about?';
    }
  }

  List<String> _generateSuggestions(String userMessage) {
    final message = userMessage.toLowerCase();

    if (message.contains('math')) {
      return [
        'Solve a word problem',
        'Learn about fractions',
        'Practice multiplication'
      ];
    } else if (message.contains('science')) {
      return [
        'Explore the solar system',
        'Learn about animals',
        'Understand weather'
      ];
    } else if (message.contains('english')) {
      return ['Write a story', 'Learn new vocabulary', 'Practice grammar'];
    } else {
      return [
        'Ask about math',
        'Explore science',
        'Learn English',
        'Study history'
      ];
    }
  }

  Future<ChatResponse> analyzeImage({
    required String imageData,
    required String prompt,
    String imageFormat = 'jpeg',
  }) async {
    final response = await _apiClient.post<ChatResponse>(
      ApiConstants.aiVision,
      data: {
        'image_data': imageData,
        'prompt': prompt,
        'image_format': imageFormat,
      },
      fromJson: (json) => ChatResponse.fromJson(json),
    );

    if (response.isSuccess && response.data != null) {
      return response.data!;
    } else {
      throw ApiError(message: response.error ?? 'Failed to analyze image');
    }
  }

  Future<String> generateSummary(String text) async {
    final response = await _apiClient.post(
      ApiConstants.aiSummary,
      data: {'text': text},
    );

    if (response.isSuccess && response.data != null) {
      return response.data['summary'];
    } else {
      throw ApiError(message: response.error ?? 'Failed to generate summary');
    }
  }

  Future<Map<String, dynamic>> getAiStatus() async {
    final response = await _apiClient.get(ApiConstants.aiStatus);

    if (response.isSuccess && response.data != null) {
      return response.data;
    } else {
      throw ApiError(message: response.error ?? 'Failed to get AI status');
    }
  }

  Future<List<Map<String, dynamic>>> getAvailableModels() async {
    final response = await _apiClient.get(ApiConstants.aiModels);

    if (response.isSuccess && response.data != null) {
      return List<Map<String, dynamic>>.from(response.data['models']);
    } else {
      throw ApiError(message: response.error ?? 'Failed to get AI models');
    }
  }
}
