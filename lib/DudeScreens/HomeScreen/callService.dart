// lib/Services/CallService.dart

import 'dart:async';
import 'dart:math' as math;
import 'package:dude/APIService/Remote/network/NetworkApiService.dart';
import 'package:dude/Analytics/meta_app_events.dart';
import 'package:dude/DudeScreens/HomeScreen/Repo/UserDataRepo.dart';
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
  final UserRepository _userRepository = UserRepository(NetworkApiService());
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
  Duration? _armedCallTimerDuration;
  Timer? _uiTicker;
  Timer? _periodicCheckTimer;
  VoidCallback? _onCallTimeout;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;
  int _notInRoomCount = 0;
  bool _needsRoomCleanupOnReconnect = false;
  bool _missedCallReported = false;
  String? _lastMissedCallReportKey;
  DateTime? _lastMissedCallReportAt;
  int _billedSeconds = 0;
  int _billedCoins = 0;
  /// Only coins the API actually accepted — used so a failed/duplicate minute
  /// charge cannot suppress the end-of-call settlement (video bug).
  int _confirmedBilledCoins = 0;
  int _confirmedBilledSeconds = 0;
  /// Survives [_forceReset] so late minute-charge ACKs still apply, and so we
  /// can attribute confirmations to the call that just ended.
  String? _lastSettledCallID;
  bool _lowBalanceWarned = false;

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

  final _minuteChargeController =
      StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get onCallMinuteCharge =>
      _minuteChargeController.stream;

  /// True when ~1–2 minutes of paid time remain.
  bool get isLowBalanceWarningActive {
    if (!_isCallActive || !_wasCallReallyConnected) return false;
    final remaining = remainingCallSeconds;
    return remaining > 0 && remaining <= 120;
  }

  bool get didShowLowBalanceWarning => _lowBalanceWarned;

  void markLowBalanceWarned() {
    _lowBalanceWarned = true;
  }

  static int maxCallSecondsForBalance(int balance, int pricePerMin) {
    if (balance <= 0 || pricePerMin <= 0) return 0;
    final maxMinutes = balance ~/ pricePerMin;
    return maxMinutes * 60;
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

  /// Coins / seconds still owed after completed-minute slices already emitted.
  ///
  /// Hangup often races the async minute POST: `_confirmedBilled*` is still 0
  /// while `_billed*` already counts the in-flight minute. Using only confirmed
  /// totals here double-charged ~1-minute video (60+60 coins / 12+12 staff).
  static ({int remainingCoins, int remainingSeconds}) remainingAfterAccounted({
    required int totalSpent,
    required int durationSeconds,
    required int billedCoins,
    required int billedSeconds,
    int confirmedCoins = 0,
    int confirmedSeconds = 0,
  }) {
    final accountedCoins = math.max(billedCoins, confirmedCoins);
    final accountedSeconds = math.max(billedSeconds, confirmedSeconds);
    return (
      remainingCoins: (totalSpent - accountedCoins).clamp(0, totalSpent),
      remainingSeconds:
          (durationSeconds - accountedSeconds).clamp(0, durationSeconds),
    );
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
    _lastSettledCallID = null;

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
    _missedCallReported = false;
    _isCallActive = true;
    _isProcessingCallEnd = false;
    _billedSeconds = 0;
    _billedCoins = 0;
    _confirmedBilledCoins = 0;
    _confirmedBilledSeconds = 0;
    _lowBalanceWarned = false;

    // Emit busy status when call starts
    _emitBusyStatus(true);

    _notifyListeners();
    _startUiTicker();
    debugPrint(
      "📞 Call started - Target: $targetUserID, Price: $pricePerMin/min",
    );
    debugPrint("📞 Call started at: ${_callStartTime?.toIso8601String()}");
  }

  Future<void> reportMissedCall({
    String? staffId,
    String? callType,
    String? callID,
  }) async {
    final resolvedStaffId = staffId ?? _staffId;
    final resolvedCallType =
        callType ?? (_isCurrentCallVideo ? "video" : "audio");

    if (resolvedStaffId == null || resolvedStaffId.isEmpty) {
      debugPrint("⚠️ Missed call report skipped: staffId missing");
      return;
    }

    final reportKey =
        (callID != null && callID.isNotEmpty ? callID : _currentCallID) ??
        "$resolvedStaffId:$resolvedCallType";
    final now = DateTime.now();
    final alreadyReportedRecently =
        _lastMissedCallReportKey == reportKey &&
        _lastMissedCallReportAt != null &&
        now.difference(_lastMissedCallReportAt!) < const Duration(minutes: 2);

    if (_missedCallReported || alreadyReportedRecently) {
      debugPrint("⚠️ Missed call report skipped: already reported");
      return;
    }

    _missedCallReported = true;
    _lastMissedCallReportKey = reportKey;
    _lastMissedCallReportAt = now;

    try {
      await _userRepository.reportMissedCall(
        staffId: resolvedStaffId,
        callType: resolvedCallType,
      );
      debugPrint(
        "✅ Missed call reported → staffId: $resolvedStaffId, callType: $resolvedCallType",
      );
    } catch (e) {
      _missedCallReported = false;
      _lastMissedCallReportKey = null;
      _lastMissedCallReportAt = null;
      debugPrint("❌ Missed call report failed: $e");
    }
  }

  void _startUiTicker() {
    _uiTicker?.cancel();
    _uiTicker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_isCallActive) {
        _emitIncrementalMinuteCharges();
        _notifyListeners();
      }
    });
  }

  /// Charge each completed minute while the call is connected.
  void _emitIncrementalMinuteCharges() {
    if (!_isCallActive || !_wasCallReallyConnected) return;
    final pricePerMin = _currentCallPricePerMin ?? 0;
    if (pricePerMin <= 0) return;

    final elapsed = connectedElapsedSeconds;
    while (_billedSeconds + 60 <= elapsed) {
      _billedSeconds += 60;
      _billedCoins += pricePerMin;
      final payload = <String, dynamic>{
        'staffId': _staffId,
        'callID': _currentCallID,
        'isVideoCall': _isCurrentCallVideo,
        'durationSeconds': 60,
        'spent': pricePerMin,
        'incremental': true,
        'billedSeconds': _billedSeconds,
      };
      debugPrint('💳 Minute charge → $payload');
      _minuteChargeController.add(payload);
    }
  }

  /// Public flush for lifecycle observers (background / pause).
  void flushPendingMinuteCharges() => _emitIncrementalMinuteCharges();

  /// Mark a minute/end slice as successfully settled by the backend.
  void confirmServerBilling({
    required int spentCoins,
    required int durationSeconds,
    String? callID,
  }) {
    // Minute POSTs often ACK after hangup reset — accept for the settling call.
    final expectedCallID = _currentCallID ?? _lastSettledCallID;
    if (callID != null &&
        callID.isNotEmpty &&
        expectedCallID != null &&
        callID != expectedCallID) {
      return;
    }
    if (expectedCallID == null && !_isCallActive) return;
    if (spentCoins <= 0 && durationSeconds <= 0) return;
    _confirmedBilledCoins += spentCoins.clamp(0, 1 << 30);
    _confirmedBilledSeconds += durationSeconds.clamp(0, 1 << 30);
    debugPrint(
      '✅ Confirmed server billing +$spentCoins coins / ${durationSeconds}s '
      '(total confirmed: $_confirmedBilledCoins / ${_confirmedBilledSeconds}s)',
    );
  }

  /// Undo an emitted minute slice when the API rejects it while the call is live,
  /// so hangup can still settle that minute.
  void revokeEmittedBilling({
    required int spentCoins,
    required int durationSeconds,
  }) {
    if (!_isCallActive) return;
    _billedCoins = (_billedCoins - spentCoins).clamp(0, 1 << 30);
    _billedSeconds = (_billedSeconds - durationSeconds).clamp(0, 1 << 30);
    debugPrint(
      '↩️ Revoked emitted billing -$spentCoins coins / ${durationSeconds}s '
      '(now: $_billedCoins / ${_billedSeconds}s)',
    );
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
        _startArmedCallTimer();
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

    // Flush any completed minutes that landed on this tick.
    _emitIncrementalMinuteCharges();

    final pricePerMin = _currentCallPricePerMin ?? 0;

    final totalSpent = calculateSpentCoins(
      durationSeconds: durationSeconds,
      pricePerMin: pricePerMin,
    );
    // Subtract emitted minute slices (not only API-confirmed). Confirmed lags the
    // POST, so using it alone double-billed the first video minute at hangup.
    final remaining = remainingAfterAccounted(
      totalSpent: totalSpent,
      durationSeconds: durationSeconds,
      billedCoins: _billedCoins,
      billedSeconds: _billedSeconds,
      confirmedCoins: _confirmedBilledCoins,
      confirmedSeconds: _confirmedBilledSeconds,
    );
    final remainingSpent = remaining.remainingCoins;
    final unbilledSeconds = remaining.remainingSeconds;

    debugPrint(
      "spent:::::::$totalSpent (emitted: $_billedCoins / ${_billedSeconds}s, "
      "confirmed: $_confirmedBilledCoins / ${_confirmedBilledSeconds}s, "
      "remaining: $remainingSpent / ${unbilledSeconds}s)",
    );
    debugPrint("durationSeconds:::::::$durationSeconds");

    MetaAppEvents.spendCredits(
      credits: totalSpent,
      isVideoCall: _isCurrentCallVideo,
    );

    _lastSettledCallID = _currentCallID;

    final callData = {
      'staffId': _staffId,
      'callID': _currentCallID,
      'isVideoCall': _isCurrentCallVideo,
      // Never re-send full wall time when minutes already covered the call.
      'durationSeconds': remainingSpent > 0 ? unbilledSeconds : 0,
      'spent': remainingSpent,
      'totalDurationSeconds': durationSeconds,
      'totalSpent': totalSpent,
      'endReason': endReason,
      'outOfCoins': endReason == 'out_of_coins',
      'incremental': false,
      'billedSeconds': durationSeconds,
    };

    debugPrint("💰 Emitting call end event → $callData");

    // Emit available status (not busy) when call ends
    _emitBusyStatus(false);

    // Always emit end when there is remaining to charge; otherwise emit a marker
    // so UI can refresh after fully incremental settlements.
    if (remainingSpent > 0) {
      _callEndController.add(callData);
    } else if (totalSpent > 0) {
      _callEndController.add({
        ...callData,
        'spent': 0,
        'durationSeconds': 0,
        'alreadyBilled': true,
      });
    } else {
      _callEndController.add(callData);
    }

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
    _lowBalanceWarned = false;

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
    _armedCallTimerDuration = null;
    _realCallStartTime = null;
    _callStartTime = null;
    _currentCallID = null;
    _currentCallTargetID = null;
    _staffId = null;
    _currentCallPricePerMin = null;
    _initialCoinBalance = 0;
    _maxCallSeconds = 0;
    _billedSeconds = 0;
    _billedCoins = 0;
    _confirmedBilledCoins = 0;
    _confirmedBilledSeconds = 0;
    _lowBalanceWarned = false;
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
    _armedCallTimerDuration = duration;
    _callTimer?.cancel();
    _callTimer = null;
    if (_wasCallReallyConnected) {
      _startArmedCallTimer();
    }
  }

  void _startArmedCallTimer() {
    final duration = _armedCallTimerDuration;
    final onTimeout = _onCallTimeout;
    if (!_isCallActive ||
        !_wasCallReallyConnected ||
        duration == null ||
        onTimeout == null) {
      return;
    }

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
    _minuteChargeController.close();
    _listeners.clear();
    _pendingCallEnds.clear();
  }
}
