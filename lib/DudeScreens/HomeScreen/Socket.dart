// lib/DudeScreens/HomeScreen/Socket.dart

import 'dart:async';
import 'package:dude/APIService/Remote/network/ApiEndPoints.dart';
import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

class SocketService {
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;

  late IO.Socket socket;
  bool _isConnected = false;
  String? _currentUserId;
  bool _isConnecting = false;

  // Listeners
  final List<Function(dynamic)> _staffListListeners = [];
  final List<Function(dynamic)> _statusChangeListeners = [];
  final List<Function(dynamic)> _callBalanceTopUpListeners = [];

  // Reconnection
  Timer? _reconnectTimer;
  Timer? _heartbeatTimer;
  int _reconnectAttempts = 0;
  static const int maxReconnectAttempts = 10;

  SocketService._internal();

  bool get isConnected => _isConnected;
  bool get isConnecting => _isConnecting;

  Future<void> ensureConnected(String userId) async {
    if (_isConnected && socket.connected && _currentUserId == userId) return;

    if (_isConnected && socket.connected && _currentUserId != userId) {
      socket.disconnect();
      socket.dispose();
      _isConnected = false;
      _isConnecting = false;
    }

    connectStaff(userId);

    final completer = Completer<void>();
    late Timer timer;
    timer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      if (_isConnected && socket.connected && !completer.isCompleted) {
        completer.complete();
      }
    });

    try {
      await completer.future.timeout(const Duration(seconds: 8));
    } finally {
      timer.cancel();
    }
  }

  void connectStaff(String userId) {
    if (_isConnected) {
      // debugPrint("🟢 [SOCKET] Already connected. Skipping reconnect.");
      return;
    }

    if (_isConnecting) {
      debugPrint("🟡 [SOCKET] Already connecting, please wait...");
      return;
    }

    _isConnecting = true;
    _currentUserId = userId;

    // debugPrint("🔌 [SOCKET] Connecting with userId: $userId");
    // debugPrint("🔌 [SOCKET] WebSocket URL: ${ApiEndPoints().webSocketUrl}");

    try {
      socket = IO.io(
        ApiEndPoints().webSocketUrl,
        IO.OptionBuilder()
            .setTransports(['websocket'])
            .disableAutoConnect()
            .setReconnectionAttempts(maxReconnectAttempts)
            .setReconnectionDelay(1000)
            .setReconnectionDelayMax(5000)
            .setQuery({'userId': userId, 'platform': 'mobile'})
            .build(),
      );

      _setupSocketListeners();
      socket.connect();
    } catch (e) {
      debugPrint("❌ [SOCKET] Error creating socket: $e");
      _isConnecting = false;
      _scheduleReconnect();
    }
  }

  void emitOffline(String memberID) {
    if (_isConnected && socket.connected) {
      // debugPrint("📤 [SOCKET] Emitting offline status for: $memberID");

      // Emit the same events as the toggle button
      emit("staff_offline", {"memberID": memberID});

      emit("staff_busy_status", {
        "memberID": memberID,
        "isBusy": false,
        "isOnline": false,
        "timestamp": DateTime.now().millisecondsSinceEpoch,
      });

      // Give time for events to be sent
      Future.delayed(const Duration(milliseconds: 300), () {
        if (_isConnected && socket.connected) {
          socket.disconnect();
          socket.dispose();
          _isConnected = false;
        }
      });
    } else {
      debugPrint("⚠️ [SOCKET] Cannot emit offline: Socket not connected");
      // Force disconnect even if not connected
      if (socket.connected) {
        socket.disconnect();
        socket.dispose();
      }
      _isConnected = false;
    }
  }

  void _setupSocketListeners() {
    socket.onConnect((_) {
      // debugPrint("✅ [SOCKET] Connected! ID: ${socket.id}");
      _isConnected = true;
      _isConnecting = false;
      _reconnectAttempts = 0;

      _startHeartbeat();

      // DON'T automatically emit online - let the toggle button control it
      // _emitUserOnline(); // COMMENTED OUT

      // Auto-request staff list after connection
      Future.delayed(const Duration(milliseconds: 500), () {
        requestStaffList();
      });
    });

    socket.onConnectError((data) {
      debugPrint("❌ [SOCKET] Connection error: $data");
      _isConnected = false;
      _isConnecting = false;
      _handleConnectionError();
    });

    socket.onDisconnect((_) {
      debugPrint("❌ [SOCKET] Disconnected");
      _isConnected = false;
      _isConnecting = false;
      _stopHeartbeat();
      // DON'T auto-reconnect on disconnect - let app control it
      // _handleDisconnect(); // COMMENTED OUT
    });

    socket.onError((data) {
      debugPrint("❌ [SOCKET] Error: $data");
    });

    socket.onReconnect((_) {
      debugPrint("🔄 [SOCKET] Reconnected");
      _isConnected = true;
      _isConnecting = false;
      // DON'T automatically emit online
      // _emitUserOnline();
      requestStaffList();
    });

    socket.onReconnectAttempt((_) {
      _reconnectAttempts++;
      debugPrint("🔄 [SOCKET] Reconnect attempt $_reconnectAttempts");
    });

    socket.onReconnectError((error) {
      debugPrint("❌ [SOCKET] Reconnect error: $error");
    });

    socket.onReconnectFailed((_) {
      debugPrint("❌ [SOCKET] Reconnect failed after all attempts");
      _isConnecting = false;
    });

    // Listen for ALL events with detailed logging
    socket.onAny((event, data) {
      // debugPrint("📡 [SOCKET] EVENT: $event");
      if (data != null) {
        // debugPrint("📡 [SOCKET] DATA: $data");
      }

      if (event == "staffList" ||
          event == "staff_list" ||
          event == "all_staff_data") {
        _notifyStaffListListeners(data);
        _notifyStatusChangeListeners(data);
      }

      if (event == "staffList" ||
          event == "staff_list" ||
          event == "all_staff_data") {
        // debugPrint("📡 [SOCKET] Received staff list on event: $event");
        _notifyStaffListListeners(data);
      }

      if (event == "staff_busy_status" ||
          event == "busy_status" ||
          (data is Map && data['isBusy'] != null)) {
        // debugPrint("🔥 [SOCKET] Busy status received");
        _notifyStatusChangeListeners(data);
      }

      if (event == "call_balance_topup") {
        _notifyCallBalanceTopUpListeners(data);
      }

      if (event == "staff_status_changed" ||
          event == "status_change" ||
          event == "presence" ||
          event == "staff_online_status" ||
          event == "online_status" ||
          event == "user_status" ||
          event == "status_update" ||
          event == "staff_status") {
        // debugPrint("📡 [SOCKET] Received status change on event: $event");
        _notifyStatusChangeListeners(data);
      }

      if (event == "connected" || event == "connection_established") {
        debugPrint("✅ [SOCKET] Connection confirmed by server");
        requestStaffList();
      }
    });

    socket.on("connect", (_) {
      // debugPrint("✅ [SOCKET] Connect event confirmed");
    });

    socket.on("connecting", (_) {
      // debugPrint("🟡 [SOCKET] Connecting...");
    });
  }

  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (_isConnected && socket.connected) {
        // debugPrint("💓 [SOCKET] Sending heartbeat ping");
        emit("ping", {
          "userId": _currentUserId,
          "timestamp": DateTime.now().millisecondsSinceEpoch,
        });
      }
    });
  }

  void _stopHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
  }

  // REMOVED - No automatic online emission
  // void _emitUserOnline() { ... }

  // Public method to request staff list
  void requestStaffList() {
    if (!_isConnected) {
      debugPrint("⚠️ [SOCKET] Cannot request staff list: Socket not connected");
      return;
    }
    _sendStaffListRequest();
  }

  void _sendStaffListRequest() {
    final requestData = {
      "requestId": DateTime.now().millisecondsSinceEpoch.toString(),
      "userId": _currentUserId,
      "timestamp": DateTime.now().toIso8601String(),
    };

    // debugPrint("📤 [SOCKET] Requesting staff list...");
    emit("get_all_staff", requestData);
  }

  void _handleConnectionError() {
    // Don't auto-reconnect
  }

  void _handleDisconnect() {
    // Don't auto-reconnect
  }

  void _scheduleReconnect() {
    // Don't auto-reconnect
  }

  // Public methods
  void listenStaffList(Function(dynamic) onUpdate) {
    // debugPrint("👂 [SOCKET] Adding staff list listener");
    _staffListListeners.add(onUpdate);
  }

  void listenStatusChanges(Function(dynamic) onStatusChange) {
    // debugPrint("👂 [SOCKET] Adding status change listener");
    _statusChangeListeners.add(onStatusChange);
  }

  void listenCallBalanceTopUp(Function(dynamic) onUpdate) {
    _callBalanceTopUpListeners.add(onUpdate);
  }

  void removeCallBalanceTopUpListener(Function(dynamic) onUpdate) {
    _callBalanceTopUpListeners.remove(onUpdate);
  }

  bool emit(String event, dynamic data) {
    if (_isConnected && socket.connected) {
      // debugPrint("📤 [SOCKET] Emitting event: $event");
      socket.emit(event, data);
      return true;
    } else {
      debugPrint("⚠️ [SOCKET] Cannot emit $event: Socket not connected");
      return false;
    }
  }

  void on(String event, Function(dynamic) handler) {
    if (!_isConnected && !_isConnecting) return;
    socket.off(event);
    socket.on(event, handler);
  }

  void off(String event) {
    if (!_isConnected && !_isConnecting) return;
    socket.off(event);
  }

  void _notifyStaffListListeners(dynamic data) {
    // debugPrint(
    //   "📢 [SOCKET] Notifying ${_staffListListeners.length} staff list listeners",
    // );
    for (var listener in _staffListListeners) {
      try {
        listener(data);
      } catch (e) {
        debugPrint("❌ [SOCKET] Error in staff list listener: $e");
      }
    }
  }

  void _notifyStatusChangeListeners(dynamic data) {
    // debugPrint(
    //   "📢 [SOCKET] Notifying ${_statusChangeListeners.length} status change listeners",
    // );
    for (var listener in _statusChangeListeners) {
      try {
        listener(data);
      } catch (e) {
        debugPrint("❌ [SOCKET] Error in status change listener: $e");
      }
    }
  }

  void _notifyCallBalanceTopUpListeners(dynamic data) {
    for (final listener in _callBalanceTopUpListeners) {
      try {
        listener(data);
      } catch (e) {
        debugPrint("❌ [SOCKET] Error in call balance top-up listener: $e");
      }
    }
  }

  void disconnect() {
    debugPrint("🔌 [SOCKET] Disconnecting...");
    _reconnectTimer?.cancel();
    _stopHeartbeat();

    if (_isConnected && socket.connected) {
      // ❌ DO NOT emit offline events - let backend handle via disconnect
      // Just disconnect silently
      socket.disconnect();
      socket.dispose();
      _isConnected = false;
    }

    _staffListListeners.clear();
    _statusChangeListeners.clear();
    _callBalanceTopUpListeners.clear();
    _currentUserId = null;
    _reconnectAttempts = 0;
    _isConnecting = false;
  }

  String? getCurrentUserId() {
    return _currentUserId;
  }
}
