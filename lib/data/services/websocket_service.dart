import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../../core/constants/api_constants.dart';

class WebSocketService {
  static final WebSocketService _instance = WebSocketService._internal();
  factory WebSocketService() => _instance;
  WebSocketService._internal();

  IO.Socket? _socket;
  String? _currentRoom;
  bool _isConnected = false;

  // Callbacks
  Function(Map<String, dynamic>)? onNewMessage;
  Function(Map<String, dynamic>)? onUserJoined;
  Function(Map<String, dynamic>)? onUserLeft;
  Function(Map<String, dynamic>)? onTypingStart;
  Function(Map<String, dynamic>)? onTypingStop;
  Function(bool)? onConnectionChanged;

  Future<void> connect(String token) async {
    if (_isConnected) return;

    _socket = IO.io(
      ApiConstants.webSocketUrl,
      IO.OptionBuilder()
          .setAuth({'token': token}).setTransports(['websocket']).build(),
    );

    _socket!.on('connect', (_) {
      print('🔌 WebSocket connected');
      _isConnected = true;
      onConnectionChanged?.call(true);
    });

    _socket!.on('disconnect', (_) {
      print('🔌 WebSocket disconnected');
      _isConnected = false;
      onConnectionChanged?.call(false);
    });

    _socket!.on('connect_error', (error) {
      print('❌ WebSocket connection error: $error');
      _isConnected = false;
      onConnectionChanged?.call(false);
    });

    // Chat events
    _socket!.on('new_message', (data) {
      print('💬 New message received: $data');
      onNewMessage?.call(Map<String, dynamic>.from(data));
    });

    _socket!.on('user_joined', (data) {
      print('👋 User joined: $data');
      onUserJoined?.call(Map<String, dynamic>.from(data));
    });

    _socket!.on('user_left', (data) {
      print('👋 User left: $data');
      onUserLeft?.call(Map<String, dynamic>.from(data));
    });

    _socket!.on('typing_start', (data) {
      onTypingStart?.call(Map<String, dynamic>.from(data));
    });

    _socket!.on('typing_stop', (data) {
      onTypingStop?.call(Map<String, dynamic>.from(data));
    });

    // Real-time collaboration events
    _socket!.on('plan_updated', (data) {
      print('📅 Plan updated: $data');
      // Handle plan updates
    });

    _socket!.on('activity_suggestion', (data) {
      print('💡 Activity suggestion: $data');
      // Handle activity suggestions
    });
  }

  void disconnect() {
    if (_socket != null) {
      _socket!.disconnect();
      _socket = null;
      _isConnected = false;
      _currentRoom = null;
      onConnectionChanged?.call(false);
    }
  }

  // Chat Room Methods
  void joinChatRoom(String roomId, {String roomType = 'ai_chat'}) {
    if (!_isConnected) return;

    _currentRoom = roomId;
    _socket!.emit('join_room', {
      'room_id': roomId,
      'room_type': roomType,
    });
    print('🏠 Joined room: $roomId');
  }

  void leaveChatRoom(String roomId) {
    if (!_isConnected) return;

    _socket!.emit('leave_room', {
      'room_id': roomId,
    });

    if (_currentRoom == roomId) {
      _currentRoom = null;
    }
    print('🏠 Left room: $roomId');
  }

  void sendMessage({
    required String roomId,
    required String message,
    String messageType = 'text',
    Map<String, dynamic>? metadata,
  }) {
    if (!_isConnected) return;

    _socket!.emit('send_message', {
      'room_id': roomId,
      'message': message,
      'message_type': messageType,
      'metadata': metadata,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  void sendTypingIndicator({
    required String roomId,
    required bool isTyping,
  }) {
    if (!_isConnected) return;

    _socket!.emit(isTyping ? 'typing_start' : 'typing_stop', {
      'room_id': roomId,
    });
  }

  // Collaboration Methods
  void joinPlanningSession(String planId) {
    if (!_isConnected) return;

    _socket!.emit('join_planning_session', {
      'plan_id': planId,
    });
    print('📅 Joined planning session: $planId');
  }

  void leavePlanningSession(String planId) {
    if (!_isConnected) return;

    _socket!.emit('leave_planning_session', {
      'plan_id': planId,
    });
    print('📅 Left planning session: $planId');
  }

  void broadcastPlanUpdate({
    required String planId,
    required Map<String, dynamic> changes,
  }) {
    if (!_isConnected) return;

    _socket!.emit('broadcast_plan_update', {
      'plan_id': planId,
      'changes': changes,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  void requestActivitySuggestions({
    required String planId,
    required Map<String, dynamic> context,
  }) {
    if (!_isConnected) return;

    _socket!.emit('request_activity_suggestions', {
      'plan_id': planId,
      'context': context,
    });
  }

  // Status Methods
  bool get isConnected => _isConnected;
  String? get currentRoom => _currentRoom;

  // Create private room for direct communication
  Future<String> createPrivateRoom({
    required String roomType,
    Map<String, dynamic>? roomData,
  }) async {
    if (!_isConnected) throw Exception('WebSocket not connected');

    final roomId = 'room_${DateTime.now().millisecondsSinceEpoch}';

    _socket!.emit('create_room', {
      'room_id': roomId,
      'room_type': roomType,
      'room_data': roomData,
    });

    return roomId;
  }

  // Broadcast to multiple users
  void broadcastToUsers({
    required List<String> userIds,
    required String eventType,
    required Map<String, dynamic> data,
  }) {
    if (!_isConnected) return;

    _socket!.emit('broadcast_to_users', {
      'user_ids': userIds,
      'event_type': eventType,
      'data': data,
    });
  }

  // Get room information
  void getRoomInfo(String roomId) {
    if (!_isConnected) return;

    _socket!.emit('get_room_info', {
      'room_id': roomId,
    });
  }

  // Get active users in room
  void getRoomUsers(String roomId) {
    if (!_isConnected) return;

    _socket!.emit('get_room_users', {
      'room_id': roomId,
    });
  }

  // Voice call signaling (for future voice chat features)
  void initiateVoiceCall({
    required String roomId,
    required String targetUserId,
  }) {
    if (!_isConnected) return;

    _socket!.emit('initiate_voice_call', {
      'room_id': roomId,
      'target_user_id': targetUserId,
    });
  }

  void acceptVoiceCall({
    required String roomId,
    required String callerId,
  }) {
    if (!_isConnected) return;

    _socket!.emit('accept_voice_call', {
      'room_id': roomId,
      'caller_id': callerId,
    });
  }

  void rejectVoiceCall({
    required String roomId,
    required String callerId,
  }) {
    if (!_isConnected) return;

    _socket!.emit('reject_voice_call', {
      'room_id': roomId,
      'caller_id': callerId,
    });
  }

  void endVoiceCall(String roomId) {
    if (!_isConnected) return;

    _socket!.emit('end_voice_call', {
      'room_id': roomId,
    });
  }

  // Cleanup
  void dispose() {
    disconnect();
    onNewMessage = null;
    onUserJoined = null;
    onUserLeft = null;
    onTypingStart = null;
    onTypingStop = null;
    onConnectionChanged = null;
  }
}
