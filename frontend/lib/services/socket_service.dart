import 'dart:async';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../api_client.dart';

/// Singleton Socket.IO service.
/// Architecture: Emit-first (optimistic) → DB async save → confirm real ID.
class SocketService {
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;
  SocketService._internal();

  IO.Socket? _socket;
  bool _isConnected = false;
  String? _currentToken;

  // Stream controllers
  final _messageCtrl = StreamController<Map<String, dynamic>>.broadcast();
  final _typingCtrl = StreamController<Map<String, dynamic>>.broadcast();
  final _presenceCtrl = StreamController<Map<String, dynamic>>.broadcast();
  final _mentionCtrl = StreamController<Map<String, dynamic>>.broadcast();
  final _confirmCtrl = StreamController<Map<String, dynamic>>.broadcast();

  Stream<Map<String, dynamic>> get onNewMessage => _messageCtrl.stream;
  Stream<Map<String, dynamic>> get onTyping => _typingCtrl.stream;
  Stream<Map<String, dynamic>> get onPresence => _presenceCtrl.stream;
  Stream<Map<String, dynamic>> get onMention => _mentionCtrl.stream;
  Stream<Map<String, dynamic>> get onMessageConfirmed => _confirmCtrl.stream;

  bool get isConnected => _isConnected;

  String get _baseUrl {
    return ApiClient.dio.options.baseUrl.replaceAll('/api/v1', '').replaceAll('/api/v1/', '');
  }

  void connect(String token) {
    if (_isConnected && _currentToken == token) return;
    disconnect();
    _currentToken = token;

    _socket = IO.io(
      _baseUrl,
      IO.OptionBuilder()
          .setTransports(['websocket']) // Force WebSocket (not polling)
          .setAuth({'token': token})
          .setQuery({'token': token})
          .enableAutoConnect()
          .enableReconnection()
          .setReconnectionDelay(1000)
          .setReconnectionDelayMax(5000)
          .setReconnectionAttempts(20)
          .setTimeout(5000)
          .build(),
    );

    _socket!.onConnect((_) {
      _isConnected = true;
      print('[SocketService] Connected via WebSocket');
    });

    _socket!.on('new_message', (data) {
      _messageCtrl.add(_toMap(data));
    });

    _socket!.on('typing', (data) {
      _typingCtrl.add(_toMap(data));
    });

    _socket!.on('presence', (data) {
      _presenceCtrl.add(_toMap(data));
    });

    _socket!.on('mention', (data) {
      _mentionCtrl.add(_toMap(data));
    });

    _socket!.on('message_confirmed', (data) {
      // Server confirmed real DB ID → replace temp ID in UI
      _confirmCtrl.add(_toMap(data));
    });

    _socket!.onDisconnect((_) {
      _isConnected = false;
      print('[SocketService] Disconnected');
    });

    _socket!.onConnectError((err) {
      _isConnected = false;
      print('[SocketService] Connection error: $err');
    });

    _socket!.onReconnect((_) {
      _isConnected = true;
      print('[SocketService] Reconnected');
    });
  }

  void joinRoom(int roomId) {
    _socket?.emit('join_room', {'room_id': roomId});
  }

  void leaveRoom(int roomId) {
    _socket?.emit('leave_room', {'room_id': roomId});
  }

  /// Send message - server emits to room BEFORE saving to DB.
  /// clientMsgId: local temp ID for deduplication with server confirmation.
  void sendMessage(int roomId, String content, {String? clientMsgId}) {
    _socket?.emit('send_message', {
      'room_id': roomId,
      'content': content,
      'client_msg_id': clientMsgId,
    });
  }

  void sendTyping(int roomId, bool isTyping) {
    _socket?.emit('typing', {'room_id': roomId, 'is_typing': isTyping});
  }

  void disconnect() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    _isConnected = false;
    _currentToken = null;
  }

  void dispose() {
    disconnect();
    _messageCtrl.close();
    _typingCtrl.close();
    _presenceCtrl.close();
    _mentionCtrl.close();
    _confirmCtrl.close();
  }

  static Map<String, dynamic> _toMap(dynamic data) {
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    return {};
  }
}
