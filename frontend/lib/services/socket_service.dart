import 'dart:async';
import 'package:socket_io_client/socket_io_client.dart' as IO;

/// Singleton service for real-time Socket.IO messaging.
/// Replaces the 3-second HTTP polling approach with ~50-100ms delivery.
class SocketService {
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;
  SocketService._internal();

  IO.Socket? _socket;
  bool _isConnected = false;
  String? _currentToken;

  // Stream controllers for incoming messages
  final _messageController = StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get onNewMessage => _messageController.stream;

  bool get isConnected => _isConnected;

  /// Base URL for the Socket.IO server (same as API but without /api/v1)
  static const String _baseUrl = 'https://myharur.onrender.com';

  /// Connect to Socket.IO server with JWT auth.
  void connect(String token) {
    if (_isConnected && _currentToken == token) return;

    // Disconnect previous connection if any
    disconnect();
    _currentToken = token;

    _socket = IO.io(_baseUrl, IO.OptionBuilder()
      .setTransports(['websocket', 'polling'])
      .setAuth({'token': token})
      .setQuery({'token': token})
      .enableAutoConnect()
      .enableReconnection()
      .setReconnectionDelay(1000)
      .setReconnectionAttempts(10)
      .build(),
    );

    _socket!.onConnect((_) {
      _isConnected = true;
      print('[SocketService] Connected');
    });

    _socket!.on('new_message', (data) {
      if (data is Map<String, dynamic>) {
        _messageController.add(data);
      } else if (data is Map) {
        _messageController.add(Map<String, dynamic>.from(data));
      }
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

  /// Join a specific chat room for real-time updates.
  void joinRoom(int roomId) {
    _socket?.emit('join_room', {'room_id': roomId});
  }

  /// Leave a chat room.
  void leaveRoom(int roomId) {
    _socket?.emit('leave_room', {'room_id': roomId});
  }

  /// Send a message via Socket.IO (bypasses REST for speed).
  void sendMessage(int roomId, String content) {
    _socket?.emit('send_message', {
      'room_id': roomId,
      'content': content,
    });
  }

  /// Disconnect and clean up.
  void disconnect() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    _isConnected = false;
    _currentToken = null;
  }

  /// Dispose stream controllers (call on app shutdown).
  void dispose() {
    disconnect();
    _messageController.close();
  }
}
