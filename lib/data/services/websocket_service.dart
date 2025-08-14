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

    try {
      // Temporarily disable WebSocket to avoid type casting errors
      print('🔌 WebSocket connection disabled temporarily');
      _isConnected = true;
      onConnectionChanged?.call(true);
      return;

      /* DISABLED FOR NOW - WebSocket connection code
      _socket = IO.io(
        ApiConstants.webSocketUrl,
        IO.OptionBuilder()
            .setAuth({'token': token})
            .setTransports(['websocket'])
            .setTimeout(30000)
            .setReconnectionAttempts(3)
            .setReconnectionDelay(2000)
            .build(),
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

      _socket!.on('connect_timeout', (_) {
        print('⏰ WebSocket connection timeout');
        _isConnected = false;
        onConnectionChanged?.call(false);
      });

      // Chat events with error handling
      _socket!.on('new_message', (data) {
        try {
          print('💬 New message received: $data');
          if (data is Map) {
            onNewMessage?.call(Map<String, dynamic>.from(data));
          } else if (data is Map<String, dynamic>) {
            onNewMessage?.call(data);
          }
        } catch (e) {
          print('❌ Error processing new message: $e');
        }
      });

      _socket!.on('user_joined', (data) {
        try {
          print('👋 User joined: $data');
          if (data is Map) {
            onUserJoined?.call(Map<String, dynamic>.from(data));
          } else if (data is Map<String, dynamic>) {
            onUserJoined?.call(data);
          }
        } catch (e) {
          print('❌ Error processing user joined: $e');
        }
      });

      _socket!.on('user_left', (data) {
        try {
          print('👋 User left: $data');
          if (data is Map) {
            onUserLeft?.call(Map<String, dynamic>.from(data));
          } else if (data is Map<String, dynamic>) {
            onUserLeft?.call(data);
          }
        } catch (e) {
          print('❌ Error processing user left: $e');
        }
      });

      _socket!.on('typing_start', (data) {
        try {
          if (data is Map) {
            onTypingStart?.call(Map<String, dynamic>.from(data));
          } else if (data is Map<String, dynamic>) {
            onTypingStart?.call(data);
          }
        } catch (e) {
          print('❌ Error processing typing start: $e');
        }
      });

      _socket!.on('typing_stop', (data) {
        try {
          if (data is Map) {
            onTypingStop?.call(Map<String, dynamic>.from(data));
          } else if (data is Map<String, dynamic>) {
            onTypingStop?.call(data);
          }
        } catch (e) {
          print('❌ Error processing typing stop: $e');
        }
      });

      // Real-time collaboration events with error handling
      _socket!.on('plan_updated', (data) {
        try {
          print('📅 Plan updated: $data');
          // Handle plan updates
        } catch (e) {
          print('❌ Error processing plan update: $e');
        }
      });

      _socket!.on('activity_suggestion', (data) {
        try {
          print('💡 Activity suggestion: $data');
          // Handle activity suggestions
        } catch (e) {
          print('❌ Error processing activity suggestion: $e');
        }
      });
      */ // END OF DISABLED WEBSOCKET CODE
    } catch (e) {
      print('❌ Failed to initialize WebSocket: $e');
      _isConnected = false;
      onConnectionChanged?.call(false);
    }
  }

  void disconnect() {
    print('🔌 WebSocket disconnect called (currently disabled)');
    _isConnected = false;
    _currentRoom = null;
    onConnectionChanged?.call(false);

    /* DISABLED FOR NOW
    if (_socket != null) {
      _socket!.disconnect();
      _socket = null;
      _isConnected = false;
      _currentRoom = null;
      onConnectionChanged?.call(false);
    }
    */
  }

  // Chat Room Methods
  void joinChatRoom(String roomId, {String roomType = 'ai_chat'}) {
    _currentRoom = roomId;
    print('🏠 Joined room: $roomId (WebSocket disabled)');

    /* DISABLED FOR NOW
    if (!_isConnected) return;

    _currentRoom = roomId;
    _socket!.emit('join_room', {
      'room_id': roomId,
      'room_type': roomType,
    });
    print('🏠 Joined room: $roomId');
    */
  }

  void leaveChatRoom(String roomId) {
    if (_currentRoom == roomId) {
      _currentRoom = null;
    }
    print('🏠 Left room: $roomId (WebSocket disabled)');

    /* DISABLED FOR NOW
    if (!_isConnected) return;

    _socket!.emit('leave_room', {
      'room_id': roomId,
    });

    if (_currentRoom == roomId) {
      _currentRoom = null;
    }
    print('🏠 Left room: $roomId');
    */
  }

  void sendMessage({
    required String roomId,
    required String message,
    String messageType = 'text',
    Map<String, dynamic>? metadata,
  }) {
    print('💬 Message sent: $message (WebSocket disabled)');

    /* DISABLED FOR NOW
    if (!_isConnected) return;

    _socket!.emit('send_message', {
      'room_id': roomId,
      'message': message,
      'message_type': messageType,
      'metadata': metadata,
      'timestamp': DateTime.now().toIso8601String(),
    });
    */
  }

  void sendTypingIndicator({
    required String roomId,
    required bool isTyping,
  }) {
    print('⌨️ Typing indicator: $isTyping (WebSocket disabled)');

    /* DISABLED FOR NOW
    if (!_isConnected) return;

    _socket!.emit(isTyping ? 'typing_start' : 'typing_stop', {
      'room_id': roomId,
    });
    */
  }

  // Collaboration Methods
  void joinPlanningSession(String planId) {
    print('📅 Joined planning session: $planId (WebSocket disabled)');

    /* DISABLED FOR NOW
    if (!_isConnected) return;

    _socket!.emit('join_planning_session', {
      'plan_id': planId,
    });
    print('📅 Joined planning session: $planId');
    */
  }

  void leavePlanningSession(String planId) {
    print('📅 Left planning session: $planId (WebSocket disabled)');

    /* DISABLED FOR NOW
    if (!_isConnected) return;

    _socket!.emit('leave_planning_session', {
      'plan_id': planId,
    });
    print('📅 Left planning session: $planId');
    */
  }

  void broadcastPlanUpdate({
    required String planId,
    required Map<String, dynamic> changes,
  }) {
    print('📅 Broadcasting plan update: $planId (WebSocket disabled)');

    /* DISABLED FOR NOW
    if (!_isConnected) return;

    _socket!.emit('broadcast_plan_update', {
      'plan_id': planId,
      'changes': changes,
      'timestamp': DateTime.now().toIso8601String(),
    });
    */
  }

  void requestActivitySuggestions({
    required String planId,
    required Map<String, dynamic> context,
  }) {
    print('💡 Requesting activity suggestions: $planId (WebSocket disabled)');

    /* DISABLED FOR NOW
    if (!_isConnected) return;

    _socket!.emit('request_activity_suggestions', {
      'plan_id': planId,
      'context': context,
    });
    */
  }

  // Status Methods
  bool get isConnected => _isConnected;
  String? get currentRoom => _currentRoom;

  // Create private room for direct communication
  Future<String> createPrivateRoom({
    required String roomType,
    Map<String, dynamic>? roomData,
  }) async {
    final roomId = 'room_${DateTime.now().millisecondsSinceEpoch}';
    print('🏠 Creating private room: $roomId (WebSocket disabled)');
    return roomId;

    /* DISABLED FOR NOW
    if (!_isConnected) throw Exception('WebSocket not connected');

    final roomId = 'room_${DateTime.now().millisecondsSinceEpoch}';

    _socket!.emit('create_room', {
      'room_id': roomId,
      'room_type': roomType,
      'room_data': roomData,
    });

    return roomId;
    */
  }

  // Broadcast to multiple users
  void broadcastToUsers({
    required List<String> userIds,
    required String eventType,
    required Map<String, dynamic> data,
  }) {
    print('📢 Broadcasting to users: $userIds (WebSocket disabled)');

    /* DISABLED FOR NOW
    if (!_isConnected) return;

    _socket!.emit('broadcast_to_users', {
      'user_ids': userIds,
      'event_type': eventType,
      'data': data,
    });
    */
  }

  // Get room information
  void getRoomInfo(String roomId) {
    print('🔍 Getting room info: $roomId (WebSocket disabled)');

    /* DISABLED FOR NOW
    if (!_isConnected) return;

    _socket!.emit('get_room_info', {
      'room_id': roomId,
    });
    */
  }

  // Get active users in room
  void getRoomUsers(String roomId) {
    print('👥 Getting room users: $roomId (WebSocket disabled)');

    /* DISABLED FOR NOW
    if (!_isConnected) return;

    _socket!.emit('get_room_users', {
      'room_id': roomId,
    });
    */
  }

  // Voice call signaling (for future voice chat features)
  void initiateVoiceCall({
    required String roomId,
    required String targetUserId,
  }) {
    print('📞 Initiating voice call: $roomId (WebSocket disabled)');

    /* DISABLED FOR NOW
    if (!_isConnected) return;

    _socket!.emit('initiate_voice_call', {
      'room_id': roomId,
      'target_user_id': targetUserId,
    });
    */
  }

  void acceptVoiceCall({
    required String roomId,
    required String callerId,
  }) {
    print('✅ Accepting voice call: $roomId (WebSocket disabled)');

    /* DISABLED FOR NOW
    if (!_isConnected) return;

    _socket!.emit('accept_voice_call', {
      'room_id': roomId,
      'caller_id': callerId,
    });
    */
  }

  void rejectVoiceCall({
    required String roomId,
    required String callerId,
  }) {
    print('❌ Rejecting voice call: $roomId (WebSocket disabled)');

    /* DISABLED FOR NOW
    if (!_isConnected) return;

    _socket!.emit('reject_voice_call', {
      'room_id': roomId,
      'caller_id': callerId,
    });
    */
  }

  void endVoiceCall(String roomId) {
    print('📞 Ending voice call: $roomId (WebSocket disabled)');

    /* DISABLED FOR NOW
    if (!_isConnected) return;

    _socket!.emit('end_voice_call', {
      'room_id': roomId,
    });
    */
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
