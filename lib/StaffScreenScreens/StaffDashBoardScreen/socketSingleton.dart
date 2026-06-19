// lib/services/SocketServiceSingleton.dart
import 'package:dude/DudeScreens/HomeScreen/Socket.dart';

class SocketServiceSingleton {
  static final SocketServiceSingleton _instance =
      SocketServiceSingleton._internal();
  factory SocketServiceSingleton() => _instance;
  SocketServiceSingleton._internal();

  SocketService? _socketService;

  SocketService get instance {
    _socketService ??= SocketService();
    return _socketService!;
  }

  void dispose() {
    if (_socketService != null && _socketService!.isConnected) {
      _socketService!.disconnect();
    }
    _socketService = null;
  }
}
