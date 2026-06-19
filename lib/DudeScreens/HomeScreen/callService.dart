// lib/Services/CallService.dart

import 'dart:async';
import 'package:dude/DudeScreens/HomeScreen/Socket.dart';
import 'package:dude/DudeScreens/HomeScreen/call_balance_sync.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:zego_uikit/zego_uikit.dart';
import 'package:screen_brightness/screen_brightness.dart';

class CallService {
  static final CallService _instance = CallService._internal();
  factory CallService() => _instance;
  CallService._internal() {
    _startConnectivityWatcher();
  }

  final SocketService _socketService = SocketService();
  final Connectivity _connectivity = Connectivity();

  DateTime? _realCallStartTime;

  // Call tracking
  DateTime? _callStartTime;
  String? _currentCallID;
  String? _currentCallTargetID;
  String? _staffId;
  int? _currentCallPricePerMin;
  int _initialCoinBalance = 0;
  int _maxCallSeconds = 0;
  bool _isCurrentCallVideo = false;
  bool _wasCallReallyConnected = false;
  Timer? _callTimer;
  Timer? _uiTicker;
  Timer? _periodicCheckTimer;
  VoidCallback? _onCallTimeout;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;
  int _notInRoomCount = 0;
  bool _needsRoomCleanupOnReconnect = false;

  // Add a flag to track if a call is currently active
  bool _isCallActive = false;

  // Add a flag to track if we're currently processing a call end
  bool _isProcessingCallEnd = false;

  // Add a queue for pending call ends
  final List<Map<String, dynamic>> _pendingCallEnds = [];

  // Listeners for call state changes
  final List<VoidCallback> _listeners = [];

  // Getters
  DateTime? get callStartTime => _callStartTime;
  String? get currentCallID => _currentCallID;
  String? get currentCallTargetID => _currentCallTargetID;
  String? get staffId => _staffId;
  int? get currentCallPricePerMin => _currentCallPricePerMin;
  int get initialCoinBalance => _initialCoinBalance;
  int get maxCallSeconds => _maxCallSeconds;
  bool get isCurrentCallVideo => _isCurrentCallVideo;
  bool get wasCallReallyConnected => _wasCallReallyConnected;
  int get notInRoomCount => _notInRoomCount;
  bool get isCallActive => _isCallActive;
  int get connectedElapsedSeconds {
    final startTime = _realCallStartTime;
    if (!_isCallActive || !_wasCallReallyConnected || startTime == null) {
      return 0;
    }
    return DateTime.now().difference(startTime).inSeconds;
  }

  int get remainingCallSeconds {
    if (_maxCallSeconds <= 0) return 0;
    return (_maxCallSeconds - connectedElapsedSeconds).clamp(
      0,
      _maxCallSeconds,
    );
  }

  int get estimatedRemainingBalance {
    final pricePerMin = _currentCallPricePerMin ?? 0;
    final spent = calculateSpentCoins(
      durationSeconds: connectedElapsedSeconds,
      pricePerMin: pricePerMin,
    );
    return (_initialCoinBalance - spent).clamp(0, _initialCoinBalance);
  }

  final _callEndController = StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get onCallEnded => _callEndController.stream;

  static int maxCallSecondsForBalance(int balance, int pricePerMin) {
    if (balance <= 0 || pricePerMin <= 0) return 0;
    final maxMinutes = balance ~/ pricePerMin;
    return maxMinutes > 20 ? 20 * 60 : maxMinutes * 60;
  }

  static int secondsForCoinAmount(int coins, int pricePerMin) {
    if (coins <= 0 || pricePerMin <= 0) return 0;
    return (coins ~/ pricePerMin) * 60;
  }

  static int calculateSpentCoins({
    required int durationSeconds,
    required int pricePerMin,
  }) {
    if (durationSeconds <= 0 || pricePerMin <= 0) return 0;

    if (durationSeconds <= 30) {
      return ((durationSeconds / 60.0) * pricePerMin).ceil();
    }

    if (durationSeconds < 60) {
      return pricePerMin;
    }

    return ((durationSeconds / 60.0) * pricePerMin).ceil();
  }

  void addListener(VoidCallback listener) {
    _listeners.add(listener);
  }

  void removeListener(VoidCallback listener) {
    _listeners.remove(listener);
  }

  void _notifyListeners() {
    for (final listener in _listeners) {
      listener();
    }
  }

  void _startConnectivityWatcher() {
    _connectivitySub ??= _connectivity.onConnectivityChanged.listen((results) {
      final isOnline = results.any(
        (result) =>
            result == ConnectivityResult.mobile ||
            result == ConnectivityResult.wifi ||
            result == ConnectivityResult.ethernet,
      );

      if (!isOnline) {
        _handleInternetLostDuringCall();
        return;
      }

      if (_needsRoomCleanupOnReconnect) {
        _needsRoomCleanupOnReconnect = false;
        debugPrint("📶 Internet restored - cleaning up any stale Zego room");
        ZegoUIKit().leaveRoom();
      }
    });
  }

  void _handleInternetLostDuringCall() {
    if (!_isCallActive || _callStartTime == null) return;

    debugPrint("📴 Internet lost during active call");
    _needsRoomCleanupOnReconnect = true;

    // The caller cannot notify Zego/staff while fully offline, but we still
    // close local billing immediately and clean up the stale room on reconnect.
    ZegoUIKit().leaveRoom();

    if (_wasCallReallyConnected) {
      endCall(endReason: 'network_disconnected');
    } else {
      resetCall();
    }
  }

  /// Emit busy status to socket
  void _emitBusyStatus(bool isBusy) {
    if (_staffId != null && _socketService.isConnected) {
      final data = {
        "memberID": _staffId,
        "isBusy": isBusy,
        "isOnline": true, // When busy, they're still online
        "timestamp": DateTime.now().millisecondsSinceEpoch,
      };

      // debugPrint(
      //   "📢 [CallService] Emitting busy status: $isBusy for staff: $_staffId",
      // );
      _socketService.emit("staff_busy_status", data);
    }
  }

  void startCall({
    required String callID,
    required String targetUserID,
    required String staffId,
    required int pricePerMin,
    required bool isVideoCall,
    required int initialCoinBalance,
    required int maxCallSeconds,
  }) {
    // Reset any previous call state first
    _forceReset();

    _callStartTime = DateTime.now();
    _currentCallID = callID;
    _currentCallTargetID = targetUserID;
    _staffId = staffId;
    _currentCallPricePerMin = pricePerMin;
    _initialCoinBalance = initialCoinBalance;
    _maxCallSeconds = maxCallSeconds;
    _isCurrentCallVideo = isVideoCall;
    _wasCallReallyConnected = false;
    _notInRoomCount = 0;
    _isCallActive = true;
    _isProcessingCallEnd = false;

    // Emit busy status when call starts
    _emitBusyStatus(true);

    _notifyListeners();
    _startUiTicker();
    debugPrint(
      "📞 Call started - Target: $targetUserID, Price: $pricePerMin/min",
    );
    debugPrint("📞 Call started at: ${_callStartTime?.toIso8601String()}");
  }

  void _startUiTicker() {
    _uiTicker?.cancel();
    _uiTicker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_isCallActive) {
        _notifyListeners();
      }
    });
  }

  void updateRoomState(bool isInRoom) {
    if (!_isCallActive || _callStartTime == null) return;

    if (!isInRoom) {
      _notInRoomCount++;
      debugPrint("Not in room detected ($_notInRoomCount / 5)");

      // If we've been out of the room for too long after being connected, end the call
      if (_wasCallReallyConnected && _notInRoomCount >= 3) {
        debugPrint("Room left for too long → ending call");
        _forceEndCall();
      }
    } else {
      _notInRoomCount = 0;
      if (!_wasCallReallyConnected) {
        _wasCallReallyConnected = true;
        _realCallStartTime = DateTime.now();
        debugPrint("✅ Real call started at: ${_realCallStartTime}");
        _notifyListeners();

        // Release screen brightness lock to allow manual control
        Future.delayed(const Duration(seconds: 1), () async {
          try {
            await ScreenBrightness().resetScreenBrightness();
            debugPrint(
              "🔆 Call connected - reset screen brightness override successfully",
            );
          } catch (e) {
            debugPrint("Failed to reset screen brightness: $e");
          }
        });
      }
    }
  }

  void _forceEndCall() {
    if (!_isCallActive) return;

    debugPrint("⚠️ Force ending call");
    ZegoUIKit().leaveRoom();
    endCall();
  }

  Map<String, dynamic>? endCall({String endReason = 'normal'}) {
    if (!_isCallActive || _callStartTime == null) {
      debugPrint("⚠️ endCall called but no active call");
      return null;
    }

    if (_isProcessingCallEnd) {
      debugPrint("⚠️ Already processing call end");
      return null;
    }

    _isProcessingCallEnd = true;

    final now = DateTime.now();
    final startTime = _realCallStartTime ?? _callStartTime!;
    final durationSeconds = now.difference(startTime).inSeconds;

    if (!_wasCallReallyConnected) {
      debugPrint("Call ended without real connection → no deduction");

      // Emit available status (not busy) even if call wasn't connected
      _emitBusyStatus(false);

      _forceReset();
      return null;
    }

    _callTimer?.cancel();

    final pricePerMin = _currentCallPricePerMin ?? 0;
    print("???????$pricePerMin");

    final spent = calculateSpentCoins(
      durationSeconds: durationSeconds,
      pricePerMin: pricePerMin,
    );
    debugPrint("spent:::::::$spent");
    debugPrint("durationSeconds:::::::$durationSeconds");

    final callData = {
      'staffId': _staffId,
      'callID': _currentCallID,
      'isVideoCall': _isCurrentCallVideo,
      'durationSeconds': durationSeconds,
      'spent': spent,
      'endReason': endReason,
    };

    debugPrint("💰 Emitting call end event → $callData");

    // Emit available status (not busy) when call ends
    _emitBusyStatus(false);

    // 🔥 EMIT EVENT HERE
    _callEndController.add(callData);

    _forceReset();

    return callData;
  }

  void resetCall() {
    debugPrint("🔄 Resetting call state");

    // Emit available status on reset
    if (_isCallActive && _staffId != null) {
      _emitBusyStatus(false);
    }

    _forceReset();

    // Check if there are pending call ends
    if (_pendingCallEnds.isNotEmpty) {
      debugPrint("📋 Processing ${_pendingCallEnds.length} pending call ends");
      final nextCall = _pendingCallEnds.removeAt(0);
      // You'll need to handle this in the screen
    }
  }

  void extendCallWithAddedCoins(int addedCoins) {
    if (!_isCallActive || addedCoins <= 0) return;

    final pricePerMin = _currentCallPricePerMin ?? 0;
    if (pricePerMin <= 0) return;

    _initialCoinBalance += addedCoins;
    final additionalSeconds = secondsForCoinAmount(addedCoins, pricePerMin);
    _maxCallSeconds += additionalSeconds;

    debugPrint(
      "In-call top-up: +$addedCoins coins, +${additionalSeconds}s | "
      "max seconds: $_maxCallSeconds",
    );

    if (_onCallTimeout != null) {
      final remaining = remainingCallSeconds;
      cancelCallTimer();
      if (remaining > 0) {
        startCallTimer(Duration(seconds: remaining), _onCallTimeout!);
      }
    }

    unawaited(CallBalanceSync.notifyStaffTopUp(this));
    _notifyListeners();
  }

  void _forceReset() {
    _onCallTimeout = null;
    _realCallStartTime = null;
    _callStartTime = null;
    _currentCallID = null;
    _currentCallTargetID = null;
    _staffId = null;
    _currentCallPricePerMin = null;
    _initialCoinBalance = 0;
    _maxCallSeconds = 0;
    _isCurrentCallVideo = false;
    _wasCallReallyConnected = false;
    _notInRoomCount = 0;
    _isCallActive = false;
    _isProcessingCallEnd = false;
    _callTimer?.cancel();
    _callTimer = null;
    _uiTicker?.cancel();
    _uiTicker = null;
    try {
      ScreenBrightness().resetScreenBrightness();
    } catch (e) {
      debugPrint("Failed to reset screen brightness in forceReset: $e");
    }
    _notifyListeners();
  }

  void startCallTimer(Duration duration, VoidCallback onTimeout) {
    _onCallTimeout = onTimeout;
    _callTimer?.cancel();
    _callTimer = Timer(duration, () {
      if (_isCallActive) {
        debugPrint("⏰ Call timer expired - ending call");
        onTimeout();
      }
    });
  }

  void cancelCallTimer() {
    _callTimer?.cancel();
    _callTimer = null;
  }

  void startPeriodicChecker(Function onCheck) {
    _periodicCheckTimer?.cancel();
    _periodicCheckTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      onCheck();
    });
  }

  void stopPeriodicChecker() {
    _periodicCheckTimer?.cancel();
    _periodicCheckTimer = null;
  }

  void dispose() {
    // Emit offline status when service is disposed
    if (_isCallActive && _staffId != null) {
      _emitBusyStatus(false);
    }

    _callTimer?.cancel();
    _periodicCheckTimer?.cancel();
    _connectivitySub?.cancel();
    _connectivitySub = null;
    _callEndController.close();
    _listeners.clear();
    _pendingCallEnds.clear();
  }
}
