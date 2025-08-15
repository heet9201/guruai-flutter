import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;

/// Mock backend service for development
/// This provides fake API responses when the real backend is not available
class MockBackendService {
  static final MockBackendService _instance = MockBackendService._();
  static MockBackendService get instance => _instance;
  MockBackendService._();

  static const String _baseUrl = 'https://jsonplaceholder.typicode.com';

  // Mock user data
  static const Map<String, dynamic> _mockUser = {
    'id': '1',
    'name': 'Test User',
    'email': 'test@example.com',
    'role': 'teacher',
    'avatar': 'https://via.placeholder.com/150',
  };

  // Mock authentication
  Future<Map<String, dynamic>> login(String email, String password) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 1500));

    // Mock authentication logic
    if (email.isNotEmpty && password.isNotEmpty) {
      return {
        'success': true,
        'message': 'Login successful',
        'data': {
          'user': _mockUser,
          'token': _generateMockJWT(),
          'refreshToken': _generateMockRefreshToken(),
        }
      };
    } else {
      throw Exception('Invalid credentials');
    }
  }

  Future<Map<String, dynamic>> register(Map<String, dynamic> userData) async {
    await Future.delayed(const Duration(milliseconds: 1500));

    return {
      'success': true,
      'message': 'Registration successful',
      'data': {
        'user': {..._mockUser, ...userData},
        'token': _generateMockJWT(),
        'refreshToken': _generateMockRefreshToken(),
      }
    };
  }

  Future<Map<String, dynamic>> chatWithAI(String message) async {
    await Future.delayed(const Duration(milliseconds: 2000));

    // Mock AI responses
    final responses = [
      'That\'s an interesting question! Let me help you with that.',
      'I understand your concern. Here\'s what I suggest...',
      'Great question! Based on my knowledge, I can tell you that...',
      'Let me break this down for you step by step.',
      'That\'s a common challenge many students face. Here\'s how you can approach it...',
    ];

    final randomResponse = responses[Random().nextInt(responses.length)];

    return {
      'success': true,
      'data': {
        'id': _generateRandomId(),
        'message': randomResponse,
        'timestamp': DateTime.now().toIso8601String(),
        'isFromAI': true,
      }
    };
  }

  Future<Map<String, dynamic>> getDashboardData() async {
    await Future.delayed(const Duration(milliseconds: 1000));

    return {
      'success': true,
      'data': {
        'stats': {
          'totalStudents': 156,
          'activeClasses': 8,
          'completedLessons': 24,
          'averageProgress': 78.5,
        },
        'recentActivities': [
          {
            'id': '1',
            'title': 'Mathematics Quiz completed',
            'timestamp': DateTime.now()
                .subtract(const Duration(hours: 2))
                .toIso8601String(),
            'type': 'quiz'
          },
          {
            'id': '2',
            'title': 'New student enrolled',
            'timestamp': DateTime.now()
                .subtract(const Duration(hours: 5))
                .toIso8601String(),
            'type': 'enrollment'
          },
        ],
        'upcomingTasks': [
          {
            'id': '1',
            'title': 'Review Science homework',
            'dueDate':
                DateTime.now().add(const Duration(days: 1)).toIso8601String(),
            'priority': 'high'
          },
          {
            'id': '2',
            'title': 'Prepare English lesson plan',
            'dueDate':
                DateTime.now().add(const Duration(days: 2)).toIso8601String(),
            'priority': 'medium'
          },
        ]
      }
    };
  }

  Future<List<Map<String, dynamic>>> getChatHistory() async {
    await Future.delayed(const Duration(milliseconds: 800));

    return [
      {
        'id': '1',
        'message': 'Hello! How can I help you today?',
        'timestamp': DateTime.now()
            .subtract(const Duration(minutes: 30))
            .toIso8601String(),
        'isFromUser': false,
      },
      {
        'id': '2',
        'message': 'I need help with creating a lesson plan for mathematics.',
        'timestamp': DateTime.now()
            .subtract(const Duration(minutes: 25))
            .toIso8601String(),
        'isFromUser': true,
      },
      {
        'id': '3',
        'message':
            'I\'d be happy to help you create a mathematics lesson plan! What grade level and specific topic are you focusing on?',
        'timestamp': DateTime.now()
            .subtract(const Duration(minutes: 20))
            .toIso8601String(),
        'isFromUser': false,
      },
    ];
  }

  // Helper methods
  String _generateMockJWT() {
    final random = Random();
    final header = base64Encode(utf8.encode('{"alg":"HS256","typ":"JWT"}'));
    final payload = base64Encode(utf8.encode(jsonEncode({
      'sub': '1',
      'email': 'test@example.com',
      'iat': DateTime.now().millisecondsSinceEpoch ~/ 1000,
      'exp': DateTime.now()
              .add(const Duration(hours: 24))
              .millisecondsSinceEpoch ~/
          1000,
    })));
    final signature = List.generate(32, (index) => random.nextInt(256))
        .map((e) => e.toRadixString(16).padLeft(2, '0'))
        .join();

    return '$header.$payload.$signature';
  }

  String _generateMockRefreshToken() {
    final random = Random();
    return List.generate(64, (index) => random.nextInt(256))
        .map((e) => e.toRadixString(16).padLeft(2, '0'))
        .join();
  }

  String _generateRandomId() {
    return DateTime.now().millisecondsSinceEpoch.toString();
  }

  // Network connectivity check
  Future<bool> checkConnectivity() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/posts/1'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 5));

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}
