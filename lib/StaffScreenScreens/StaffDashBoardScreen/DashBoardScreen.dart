import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:android_intent_plus/android_intent.dart';
import 'package:dude/DudeScreens/HomeScreen/AppUpdateService.dart';
import 'package:dude/DudeScreens/HomeScreen/Socket.dart';
import 'package:dude/DudeScreens/HomeScreen/call_balance_overlay.dart';
import 'package:dude/DudeScreens/HomeScreen/call_balance_sync.dart';
import 'package:dude/DudeScreens/HomeScreen/callService.dart';
import 'package:dude/DudeScreens/HomeScreen/zego_lifecycle.dart';
import 'package:dude/Dude_Utils/CustomSnackBar/StatusMessage.dart';
import 'package:dude/Reusable_Widgets/ActivePopupService.dart';
import 'package:dude/Reusable_Widgets/BondingNavigator.dart';
import 'package:dude/Dude_Utils/App_Theme/DudeTheme.dart';
import 'package:dude/Reusable_Widgets/Premium_UI/dude_logo.dart';
import 'package:dude/Reusable_Widgets/Premium_UI/premium_ambient_background.dart';
import 'package:dude/Reusable_Widgets/Premium_UI/premium_glass_card.dart';
import 'package:dude/Reusable_Widgets/Premium_UI/premium_stagger.dart';
import 'package:dude/StaffScreenScreens/RecentCallScreen/RecentCallScreen.dart';
import 'package:dude/StaffScreenScreens/StaffDashBoardScreen/Model/StaffSingleDataModel.dart';
import 'package:dude/StaffScreenScreens/StaffProfileScreen/staffProfileScreen.dart';
import 'package:dude/StaffScreenScreens/StaffRegistrationScreen/ViewModel/StaffRegisterVM.dart';
import 'package:dude/StaffScreenScreens/WalletFlow/WalletScreen/WalletScreen.dart';
import 'package:dude/StaffScreenScreens/WithdrawScreen/WithdrawHistory.dart';
import 'package:dude/StaffScreenScreens/WithdrawScreen/WithdrawRequestScreen.dart';
import 'package:dude/StaffScreenScreens/staffChat/staffChatListScreen.dart';
import 'package:dude/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_callkit_incoming/entities/android_params.dart';
import 'package:flutter_callkit_incoming/entities/call_kit_params.dart';
import 'package:flutter_callkit_incoming/entities/ios_params.dart';
import 'package:flutter_callkit_incoming/entities/notification_params.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:screen_brightness/screen_brightness.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:zego_uikit/zego_uikit.dart';
import 'package:zego_uikit_prebuilt_call/zego_uikit_prebuilt_call.dart';
import 'package:zego_uikit_signaling_plugin/zego_uikit_signaling_plugin.dart';

const _windowChannel = MethodChannel('com.dude.dudeapp/window');

/// Wraps [FlutterCallkitIncoming.endAllCalls] so the native
/// `argument "content" is null` PlatformException can never abort call flow.
Future<void> _safeEndAllCalls() async {
  try {
    await FlutterCallkitIncoming.endAllCalls();
  } catch (e) {
    debugPrint('endAllCalls ignored (no active/valid call): $e');
  }
}

const _kCommunityGroupUrl =
    'https://chat.whatsapp.com/BZ8VkPf99GDGP8cU8EhpNy?s=cl&p=a&ilr=2';
const _kIsOnlineKey = 'staff_is_online';
const _kCallTypeKey = 'staff_call_type';

enum StaffCallType { audio, video, both }

class BondingDashboardPage extends StatefulWidget {
  const BondingDashboardPage({super.key, this.launchingAcceptedCall = false});
  final bool launchingAcceptedCall;

  @override
  State<BondingDashboardPage> createState() => _BondingDashboardPageState();
}

class _BondingDashboardPageState extends State<BondingDashboardPage>
    with WidgetsBindingObserver {
  bool _zegoInitialized = false;

  final socketService = SocketService();
  final callService = CallService();
  bool _isOnCall = false;
  bool _isUpdatingStatus = false;
  StreamSubscription? _callEventSubscription;
  StreamSubscription<ZegoInRoomCommandReceivedData>?
  _callBalanceSyncSubscription;
  late final void Function(dynamic) _socketCallBalanceTopUpHandler;
  late final void Function(dynamic) _socketStatusChangeHandler;
  late final void Function(dynamic) _socketDisconnectHandler;

  // ── nullable until loaded from prefs — prevents flicker on re-entry ──
  bool? _isOnline;
  StaffCallType? _selectedCallType;

  bool _isTogglingStatus = false;
  bool _isUpdatingCallType = false;

  bool _isAppInForeground = true;
  bool _isAppMinimized = false;

  bool _killedStateAcceptPending = false;
  bool _isCallBeingHandled = false;
  bool _isZegoShowingUI = false;
  bool _showAcceptedCallConnecting = false;
  String? _pendingCallID;
  String _pendingCallCustomData = '';
  // App-lifetime notifier. The Zego call overlay (config.foreground) holds a
  // reference to this and can outlive this State during call-screen
  // transitions, so it must NOT be disposed with the dashboard — otherwise the
  // overlay's initState addListener hits a "used after being disposed" crash.
  static final ValueNotifier<CallBalanceOverlayData> _staffCallBalanceData =
      ValueNotifier<CallBalanceOverlayData>(
        const CallBalanceOverlayData.empty(),
      );
  bool _isCallkitListenerSetup = false;
  bool _isStaffCallEnding = false;
  Timer? _acceptTimeoutTimer;
  Timer? _toggleTimeoutTimer;
  bool _isDashboardDisposed = false;
  bool _activePopupShown = false;

  // ─────────────────────────────────────────────────────────────────────────
  // PERSISTENCE HELPERS
  // ─────────────────────────────────────────────────────────────────────────

  Future<bool> _loadPersistedOnlineStatus() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kIsOnlineKey) ?? false; // default: offline
  }

  Future<void> _saveOnlineStatus(bool isOnline) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kIsOnlineKey, isOnline);
  }

  /// Local pref wins over server value so re-entry never resets the selector.
  Future<StaffCallType> _loadPersistedCallType(String? serverCallType) async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_kCallTypeKey);
    if (saved != null) return _parseCallType(saved);
    return _parseCallType(serverCallType); // first launch: use server value
  }

  Future<void> _saveCallType(StaffCallType type) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kCallTypeKey, _callTypeToString(type));
  }

  String _callTypeToString(StaffCallType type) {
    switch (type) {
      case StaffCallType.audio:
        return 'audio';
      case StaffCallType.video:
        return 'video';
      case StaffCallType.both:
        return 'both';
    }
  }

  StaffCallType _parseCallType(String? v) {
    switch (v?.toLowerCase()) {
      case 'audio':
        return StaffCallType.audio;
      case 'video':
        return StaffCallType.video;
      default:
        return StaffCallType.both;
    }
  }

  Future<void> _openCommunityGroup() async {
    final uri = Uri.parse(_kCommunityGroupUrl);
    try {
      final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!opened) {
        Utils.snackBarErrorMessage("Could not open WhatsApp");
      }
    } catch (_) {
      Utils.snackBarErrorMessage("Could not open WhatsApp");
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // LIFECYCLE
  // ─────────────────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _showAcceptedCallConnecting = widget.launchingAcceptedCall;
    _killedStateAcceptPending = widget.launchingAcceptedCall;
    WidgetsBinding.instance.addObserver(this);
    _socketCallBalanceTopUpHandler = _handleSocketCallBalanceTopUp;
    _socketStatusChangeHandler = _handleSocketStatusChange;
    _socketDisconnectHandler = _handleSocketDisconnect;
    AppUpdateService.checkForUpdate(context);
    _setupCallListeners();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (Platform.isAndroid) _requestOverlayPermission();

      // ── Step 1: Load persisted UI state FIRST — no flicker on re-entry ──
      var effectiveOnline = await _loadPersistedOnlineStatus();
      if (mounted) setState(() => _isOnline = effectiveOnline);
      if (!mounted) return;

      // ── Step 2: Fetch staff profile (needed for Zego memberID) ───────────
      final staffVM = context.read<StaffViewModel>();
      await staffVM.fetchStaffSingleData();

      final staff = staffVM.currentStaff;
      if (staff == null || staff.memberID.isEmpty) return;

      if (staff.isOnline != null && staff.isOnline != effectiveOnline) {
        effectiveOnline = staff.isOnline!;
        await _saveOnlineStatus(effectiveOnline);
        if (mounted) setState(() => _isOnline = effectiveOnline);
      }

      final resolvedCallType = await _loadPersistedCallType(staff.callType);
      if (mounted) setState(() => _selectedCallType = resolvedCallType);

      // ── Step 3: Register with Zego as early as possible (killed-state) ─
      await _detectKilledStateAccept();
      if (effectiveOnline) {
        await _initZego(staff);
      }
      if (_killedStateAcceptPending) _startAcceptTimeout();

      if (Platform.isAndroid) {
        if (await Permission.notification.isDenied) {
          await Permission.notification.request();
        }
        await FlutterCallkitIncoming.requestFullIntentPermission();
        if (!await Permission.systemAlertWindow.isGranted) {
          await Permission.systemAlertWindow.request();
        }
        await _ensureBatteryOptimizationDisabled();
      }

      // ── Step 4: Socket + dashboard stats ─────────────────────────────────
      if (effectiveOnline) {
        if (!socketService.isConnected) {
          socketService.connectStaff(staff.memberID);
          await Future.delayed(const Duration(milliseconds: 600));
        }
        if (socketService.isConnected) {
          _registerSocketDashboardListeners();
          _emitOnlineStatus(staff.memberID, isOnline: true);
        }
      }

      _registerSocketDashboardListeners();

      await staffVM.fetchStaffCallStats();
      await staffVM.fetchWeeklyCallGraph();
      await _maybeShowActivePopup();
    });
  }

  Future<void> _maybeShowActivePopup() async {
    if (_activePopupShown || !mounted || _isDashboardDisposed) return;
    _activePopupShown = true;
    await ActivePopupService.showActivePopupsForRole(context, role: 'staff');
  }

  @override
  void dispose() {
    _isDashboardDisposed = true;
    WidgetsBinding.instance.removeObserver(this);
    _callEventSubscription?.cancel();
    _callBalanceSyncSubscription?.cancel();
    socketService.removeCallBalanceTopUpListener(
      _socketCallBalanceTopUpHandler,
    );
    socketService.removeStatusChangeListener(_socketStatusChangeHandler);
    socketService.removeDisconnectListener(_socketDisconnectHandler);
    _acceptTimeoutTimer?.cancel();
    _toggleTimeoutTimer?.cancel();
    // Do not dispose: it is app-lifetime and may still be referenced by the
    // Zego call overlay. Just reset it to the empty state.
    _staffCallBalanceData.value = const CallBalanceOverlayData.empty();

    if (socketService.isConnected) socketService.disconnect();
    if (_isOnCall) _updateBusyStatus(false);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        _isAppInForeground = true;
        _isAppMinimized = false;
        debugPrint("📱 App resumed");
        unawaited(_syncOnlineStatusOnResume());
        break;

      case AppLifecycleState.paused:
        _isAppInForeground = false;
        _isAppMinimized = true;
        debugPrint("📱 App paused - Keeping socket alive");
        break;

      case AppLifecycleState.inactive:
        _isAppInForeground = false;
        debugPrint("📱 App inactive");
        break;

      default:
        break;
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // ONLINE / OFFLINE TOGGLE
  // ─────────────────────────────────────────────────────────────────────────

  void _startToggleTimeout() {
    _toggleTimeoutTimer?.cancel();
    _toggleTimeoutTimer = Timer(const Duration(seconds: 10), () {
      if (_isTogglingStatus) {
        _isTogglingStatus = false;
        if (mounted) {
          setState(() {});
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Operation timed out. Please try again."),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    });
  }

  Future<void> _toggleOnlineStatus() async {
    if (_isTogglingStatus) return;

    _isTogglingStatus = true;
    _startToggleTimeout();

    final staffVM = context.read<StaffViewModel>();
    final staff = staffVM.currentStaff;
    final isOnline = _isOnline ?? false;

    if (staff == null) {
      _isTogglingStatus = false;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Staff data not available"),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    final newStatus = !isOnline;

    try {
      if (newStatus) {
        // ── Going ONLINE ───────────────────────────────────────────────────
        await _initZego(staff);

        if (!socketService.isConnected) {
          socketService.connectStaff(staff.memberID);
          await Future.delayed(const Duration(milliseconds: 800));
        }

        if (socketService.isConnected) {
          _registerSocketDashboardListeners();
          _emitOnlineStatus(staff.memberID, isOnline: true);
          socketService.emit("staff_online", {"memberID": staff.memberID});
          await Future.delayed(const Duration(milliseconds: 200));
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Failed to connect. Please try again."),
                backgroundColor: Colors.red,
              ),
            );
          }
          _isTogglingStatus = false;
          return;
        }

        // Persist BEFORE setState so re-entry reads the correct value
        await _saveOnlineStatus(true);
        if (mounted) {
          setState(() => _isOnline = true);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("You are now online"),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 1),
            ),
          );
        }
      } else {
        // ── Going OFFLINE ──────────────────────────────────────────────────
        try {
          await ZegoLifecycle.uninitSafely();
          _zegoInitialized = false;
        } catch (e) {
          debugPrint("❌ Error uninitializing Zego: $e");
        }

        if (socketService.isConnected) {
          _emitOnlineStatus(staff.memberID, isOnline: false);
          socketService.emit("staff_offline", {"memberID": staff.memberID});
          await Future.delayed(const Duration(milliseconds: 500));
          socketService.disconnect();
          await Future.delayed(const Duration(milliseconds: 200));
        }

        // Persist BEFORE setState
        await _saveOnlineStatus(false);
        if (mounted) {
          setState(() => _isOnline = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("You are now offline"),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 1),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error: ${e.toString().split('\n').first}"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      _isTogglingStatus = false;
      _toggleTimeoutTimer?.cancel();
      if (mounted) setState(() {});
    }
  }

  void _emitOnlineStatus(String memberID, {required bool isOnline}) {
    try {
      if (!socketService.isConnected && isOnline) return;
      socketService.emit("staff_busy_status", {
        "memberID": memberID,
        "isBusy": _isOnCall,
        "isOnline": isOnline,
        "timestamp": DateTime.now().millisecondsSinceEpoch,
      });
    } catch (e) {
      debugPrint("❌ Error emitting online status: $e");
    }
  }

  void _registerSocketDashboardListeners() {
    socketService.listenCallBalanceTopUp(_socketCallBalanceTopUpHandler);
    socketService.listenStatusChanges(_socketStatusChangeHandler);
    socketService.listenDisconnect(_socketDisconnectHandler);
  }

  Map<String, dynamic>? _socketMap(dynamic data) {
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    return null;
  }

  Map<String, dynamic> _statusPayload(Map<String, dynamic> data) {
    for (final key in const ['data', 'staff', 'staffData', 'payload']) {
      final nested = data[key];
      if (nested is Map<String, dynamic>) {
        return {...data, ...nested};
      }
      if (nested is Map) {
        return {...data, ...Map<String, dynamic>.from(nested)};
      }
    }
    return data;
  }

  bool? _onlineStatusFromPayload(Map<String, dynamic> data) {
    final payload = _statusPayload(data);
    // NOTE: intentionally do NOT read `status` here. On bulk staff-list
    // broadcasts (`{status: true, data: [...]}`) `status` is the API success
    // flag, not a presence value — treating it as presence flips this staff
    // back online right after they tap Offline.
    final value =
        payload['isOnline'] ?? payload['online'] ?? payload['presence'];
    if (value is bool) return value;

    final normalized = value?.toString().toLowerCase();
    if (normalized == 'online' ||
        normalized == 'available' ||
        normalized == 'active' ||
        normalized == 'true') {
      return true;
    }
    if (normalized == 'offline' ||
        normalized == 'inactive' ||
        normalized == 'false') {
      return false;
    }
    return null;
  }

  bool _isStatusForCurrentStaff(Map<String, dynamic> data) {
    final staff = context.read<StaffViewModel>().currentStaff;
    if (staff == null) return false;

    // Bulk staff-list broadcasts (`{status: true, data: [...]}`) are the list
    // of online staff shown to users — they are NOT presence updates for this
    // staff. Ignore them entirely so they can't flip our toggle.
    if (data['data'] is List) return false;

    final payload = _statusPayload(data);
    final targetId =
        payload['memberID']?.toString() ??
        payload['memberId']?.toString() ??
        payload['userId']?.toString() ??
        payload['staffId']?.toString() ??
        payload['staff_id']?.toString() ??
        payload['_id']?.toString() ??
        payload['id']?.toString();

    // Only act on updates that explicitly target this staff. If we can't tell
    // who the update is for, do NOT assume it's ours.
    if (targetId == null || targetId.isEmpty) return false;
    return targetId == staff.memberID || targetId == staff.id;
  }

  void _handleSocketStatusChange(dynamic data) {
    if (!mounted || _isDashboardDisposed) return;
    // While the user is mid-toggle, ignore backend echoes so a stale broadcast
    // can't fight the manual action (duplicate toasts / flip back online).
    if (_isTogglingStatus) return;
    debugPrint("📡 Status change: $data");

    final map = _socketMap(data);
    if (map == null || !_isStatusForCurrentStaff(map)) return;

    final payload = _statusPayload(map);
    final isOnline = _onlineStatusFromPayload(payload);
    if (isOnline == null || isOnline == (_isOnline ?? false)) return;

    unawaited(
      _applyBackendOnlineStatus(
        isOnline,
        reason: payload['reason']?.toString(),
      ),
    );
  }

  void _handleSocketDisconnect(dynamic data) {
    if (!mounted || _isDashboardDisposed || _isTogglingStatus) return;
    if (!(_isOnline ?? false)) return;

    debugPrint("📡 Staff socket disconnected while online: $data");
    unawaited(_syncOnlineStatusAfterSocketDisconnect());
  }

  Future<void> _syncOnlineStatusAfterSocketDisconnect() async {
    await Future.delayed(const Duration(milliseconds: 700));
    if (!mounted || _isDashboardDisposed || _isTogglingStatus) return;
    if (!(_isOnline ?? false)) return;

    final staffVM = context.read<StaffViewModel>();
    try {
      await staffVM.fetchStaffSingleData();
    } catch (e) {
      debugPrint("❌ Failed to sync staff status after socket disconnect: $e");
      return;
    }

    if (!mounted || _isDashboardDisposed || _isTogglingStatus) return;

    final serverOnline = staffVM.currentStaff?.isOnline;
    if (serverOnline == false) {
      await _applyBackendOnlineStatus(false, reason: "missed_calls");
    } else if (serverOnline == null) {
      debugPrint(
        "⚠️ Staff status API did not include isOnline after disconnect; "
        "keeping local toggle unchanged",
      );
    }
  }

  Future<void> _syncOnlineStatusOnResume() async {
    if (!mounted || _isDashboardDisposed) return;

    final staffVM = context.read<StaffViewModel>();
    await staffVM.fetchStaffSingleData();
    if (!mounted || _isDashboardDisposed) return;

    final staff = staffVM.currentStaff;
    final serverOnline = staff?.isOnline;

    if (serverOnline != null && serverOnline != (_isOnline ?? false)) {
      await _applyBackendOnlineStatus(serverOnline);
      return;
    }

    if ((_isOnline ?? false) && staff != null) {
      if (!socketService.isConnected) {
        socketService.connectStaff(staff.memberID);
        await Future.delayed(const Duration(milliseconds: 600));
      }
      if (socketService.isConnected && (_isOnline ?? false)) {
        _registerSocketDashboardListeners();
        _emitOnlineStatus(staff.memberID, isOnline: true);
      }
    }
  }

  Future<void> _applyBackendOnlineStatus(
    bool isOnline, {
    String? reason,
  }) async {
    await _saveOnlineStatus(isOnline);

    if (!mounted || _isDashboardDisposed) return;
    setState(() => _isOnline = isOnline);

    if (!isOnline) {
      try {
        await ZegoLifecycle.uninitSafely();
        _zegoInitialized = false;
      } catch (e) {
        debugPrint("❌ Error uninitializing Zego after backend offline: $e");
      }

      if (socketService.isConnected) {
        socketService.disconnect();
      }

      final message = reason == 'missed_calls'
          ? "You are offline due to missed calls"
          : "You are now offline";
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 2),
          ),
        );
      }
      return;
    }

    final staff = context.read<StaffViewModel>().currentStaff;
    if (staff == null) return;

    await _initZego(staff);
    if (!socketService.isConnected) {
      socketService.connectStaff(staff.memberID);
      await Future.delayed(const Duration(milliseconds: 600));
    }
    if (socketService.isConnected) {
      _registerSocketDashboardListeners();
      _emitOnlineStatus(staff.memberID, isOnline: true);
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // KILLED-STATE DETECTION
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> _detectKilledStateAccept() async {
    // Do NOT use activeCalls() — on Android it returns ringing calls too, which
    // falsely auto-accepts the first killed-state call instead of letting it ring.
    bool detected = false;

    try {
      final data = await _windowChannel.invokeMethod('getAcceptedCallData');
      if (data != null && data is Map) {
        final action = (data['action'] as String? ?? 'ACCEPT').toUpperCase();
        if (action == 'DECLINE') {
          await _safeEndAllCalls();
          try {
            await ZegoUIKitPrebuiltCallInvitationService().reject();
          } catch (_) {}
          return;
        }
        detected = true;
        _pendingCallID = data['callId'] as String?;
      }
    } catch (e) {
      debugPrint("getAcceptedCallData error: $e");
    }

    if (detected) {
      _killedStateAcceptPending = true;
      _isCallBeingHandled = false;
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // ACCEPT TIMEOUT
  // ─────────────────────────────────────────────────────────────────────────

  void _startAcceptTimeout() {
    _acceptTimeoutTimer?.cancel();
    _acceptTimeoutTimer = Timer(const Duration(seconds: 6), () async {
      if (!_killedStateAcceptPending || _isCallBeingHandled) return;
      _killedStateAcceptPending = false;
      _isCallBeingHandled = true;
      try {
        ZegoUIKitPrebuiltCallInvitationService().enterAcceptedOfflineCall();
        _finishAcceptedCallConnecting();
      } catch (e) {
        try {
          await ZegoUIKitPrebuiltCallInvitationService().accept();
          _finishAcceptedCallConnecting();
        } catch (e2) {
          _isCallBeingHandled = false;
        }
      }
    });
  }

  void _finishAcceptedCallConnecting() {
    if (mounted && _showAcceptedCallConnecting) {
      setState(() => _showAcceptedCallConnecting = false);
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // CALL LISTENERS
  // ─────────────────────────────────────────────────────────────────────────

  void _setupCallListeners() {
    _callEventSubscription = callService.onCallEnded.listen((callData) {
      if (mounted) setState(() => _isOnCall = false);
    });

    _callBalanceSyncSubscription = ZegoUIKit()
        .getInRoomCommandReceivedStream()
        .listen((event) {
          final payload = CallBalanceSync.parseTopUpMessage(event.command);
          if (payload != null) {
            _applyStaffCallBalanceTopUp(payload);
          }
        });

    socketService.listenCallBalanceTopUp(_socketCallBalanceTopUpHandler);

    ZegoUIKit().getRoomStateStream()?.addListener(() {
      final state = ZegoUIKit().getRoomStateStream()?.value;
      if (state == null) return;
      final inRoom = state.reason == ZegoRoomStateChangedReason.Logined;
      if (inRoom && !_isOnCall) {
        if (mounted) setState(() => _isOnCall = true);
        _updateBusyStatus(true);
      } else if (!inRoom && _isOnCall) {
        if (mounted) setState(() => _isOnCall = false);
        _updateBusyStatus(false);
      }
    });
  }

  void _handleSocketCallBalanceTopUp(dynamic data) {
    if (!mounted) return;

    final hasActiveCallOverlay =
        _staffCallBalanceData.value.initialBalance > 0 ||
        _staffCallBalanceData.value.maxSeconds > 0;
    if (!_isOnCall && !hasActiveCallOverlay && !_isZegoShowingUI) return;

    final staffMemberId = context.read<StaffViewModel>().currentStaff?.memberID;
    if (staffMemberId == null || staffMemberId.isEmpty) return;

    Map<String, dynamic>? map;
    if (data is Map<String, dynamic>) {
      map = data;
    } else if (data is Map) {
      map = Map<String, dynamic>.from(data);
    }
    if (map == null) return;

    final targetMemberId =
        map['staff_member_id']?.toString() ?? map['staffMemberId']?.toString();
    if (targetMemberId != null &&
        targetMemberId.isNotEmpty &&
        targetMemberId != staffMemberId) {
      return;
    }

    final payload = CallBalanceSync.parseTopUpMessage(map);
    if (payload != null) {
      _applyStaffCallBalanceTopUp(payload);
    }
  }

  void _applyStaffCallBalanceTopUp(CallBalanceTopUpPayload payload) {
    if (!mounted || _isDashboardDisposed) return;

    final hasActiveCallOverlay =
        _staffCallBalanceData.value.initialBalance > 0 ||
        _staffCallBalanceData.value.maxSeconds > 0;
    if (!_isOnCall && !hasActiveCallOverlay && !_isZegoShowingUI) return;

    final current = _staffCallBalanceData.value;
    final pricePerMin = payload.pricePerMin > 0
        ? payload.pricePerMin
        : current.pricePerMin;

    _setStaffCallBalanceData(
      CallBalanceOverlayData(
        initialBalance: payload.coinBalance,
        pricePerMin: pricePerMin,
        maxSeconds: payload.maxSeconds,
        syncedElapsedSeconds: payload.elapsedSeconds,
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // ZEGO INIT
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> _initZego(StaffSingleProfile staff) async {
    if (_zegoInitialized) return;

    await Permission.notification.request();
    await FlutterCallkitIncoming.requestFullIntentPermission();

    await ZegoUIKitPrebuiltCallInvitationService().init(
      appID: 474972896,
      appSign:
          "e950eba53072e23f8cdd3f0e2341f60cb240300059d8e613c53aafdd5d844ad3",
      userID: staff.memberID,
      userName: staff.name ?? "Staff",
      plugins: [ZegoUIKitSignalingPlugin()],

      notificationConfig: ZegoCallInvitationNotificationConfig(
        androidNotificationConfig: ZegoAndroidNotificationConfig(
          channelID: "zego_call_channel",
          channelName: "Incoming Calls",
          sound: "duderingtone",
          icon: "ic_stat_notify",
          vibrate: true,
          callIDVisibility: true,
          showOnLockedScreen: true,
          showOnFullScreen: true,
          callChannel: ZegoCallAndroidNotificationChannelConfig(
            channelID: "zego_call_channel",
            channelName: "Incoming Calls",
            icon: "ic_stat_notify",
            sound: "duderingtone",
            vibrate: true,
          ),
          missedCallChannel: ZegoCallAndroidNotificationChannelConfig(
            channelID: "missed_call_channel",
            channelName: "Missed Calls",
            icon: "ic_stat_notify",
            sound: "missed_call_sound",
            vibrate: true,
          ),
        ),
        iOSNotificationConfig: ZegoIOSNotificationConfig(
          isSandboxEnvironment: false,
        ),
      ),
      ringtoneConfig: ZegoCallRingtoneConfig(
        incomingCallPath: 'assets/audio/duderingtone.mp3',
        outgoingCallPath: 'assets/audio/duderingtone.mp3',
      ),
      invitationEvents: ZegoUIKitPrebuiltCallInvitationEvents(
        onIncomingCallReceived:
            (callID, caller, callType, callees, customData) async {
              _pendingCallID = callID;
              _pendingCallCustomData = customData;
              debugPrint("Incoming call custom data: $customData");
              _updateStaffCallBalanceData(
                customData: customData,
                callID: callID,
              );
              if (_killedStateAcceptPending) {
                _acceptTimeoutTimer?.cancel();
                _killedStateAcceptPending = false;
                _isCallBeingHandled = true;

                int waited = 0;
                while (navigatorKey.currentContext == null && waited < 5000) {
                  await Future.delayed(const Duration(milliseconds: 100));
                  waited += 100;
                }

                try {
                  ZegoUIKitPrebuiltCallInvitationService()
                      .enterAcceptedOfflineCall();
                  _finishAcceptedCallConnecting();
                  await _safeEndAllCalls();
                } catch (e) {
                  try {
                    await ZegoUIKitPrebuiltCallInvitationService().accept();
                    _finishAcceptedCallConnecting();
                    await _safeEndAllCalls();
                  } catch (e2) {
                    _isCallBeingHandled = false;
                  }
                }
                return;
              }

              if (_isAppInForeground && !_isAppMinimized) {
                _isZegoShowingUI = true;
                _isCallBeingHandled = false;
                return;
              }

              _isZegoShowingUI = false;
              _isCallBeingHandled = false;
            },
        onIncomingCallCanceled: (callID, caller, customData) async {
          if (_isDashboardDisposed) return;
          _resetCallState();
          await _safeEndAllCalls();
        },
        onIncomingCallTimeout: (callID, caller) async {
          if (_isDashboardDisposed) return;
          _resetCallState();
          await _safeEndAllCalls();
        },
        onIncomingCallAcceptButtonPressed: () async {
          _isZegoShowingUI = false;
          _isCallBeingHandled = true;
          _pendingCallID = null;
          await _safeEndAllCalls();
        },
        onIncomingCallDeclineButtonPressed: () async {
          if (_isDashboardDisposed) return;
          _resetCallState();
          await _safeEndAllCalls();
        },
      ),
      events: ZegoUIKitPrebuiltCallEvents(
        onCallEnd: (event, defaultAction) {
          _onStaffCallEnded(event, defaultAction);
        },
        user: ZegoCallUserEvents(
          onLeave: (user) {
            if (_isDashboardDisposed) return;
            debugPrint('📞 Staff remote user left → ${user.id}');
            // Do not call leaveRoom() here. Zego triggers onCallEnd with
            // defaultAction to pop the call page; leaving the room early leaves
            // the UI stuck on screen.
          },
        ),
        room: ZegoCallRoomEvents(
          onStateChanged: (state) {
            debugPrint("📞 Staff room state changed → ${state.reason}");
            if (state.reason == ZegoRoomStateChangedReason.Logined) {
              if (mounted && !_isOnCall) {
                setState(() => _isOnCall = true);
              }
              _updateBusyStatus(true);

              // Release screen brightness lock to allow manual control
              Future.delayed(const Duration(seconds: 1), () async {
                try {
                  await ScreenBrightness().resetScreenBrightness();
                  debugPrint(
                    "🔆 Staff call connected - reset screen brightness override successfully",
                  );
                } catch (e) {
                  debugPrint("Failed to reset screen brightness: $e");
                }
              });
            }

            if (state.reason == ZegoRoomStateChangedReason.Logout) {
              if (_isDashboardDisposed || _isStaffCallEnding || !_isOnCall) {
                return;
              }
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (_isDashboardDisposed || _isStaffCallEnding || !_isOnCall) {
                  return;
                }
                _resetCallState(markAvailable: true);
                unawaited(_safeEndAllCalls());
              });
            }
          },
        ),
      ),
      requireConfig: (ZegoCallInvitationData data) {
        var config = data.invitees.length > 1
            ? ZegoUIKitPrebuiltCallConfig.groupVideoCall()
            : data.type == ZegoInvitationType.videoCall
            ? ZegoUIKitPrebuiltCallConfig.oneOnOneVideoCall()
            : ZegoUIKitPrebuiltCallConfig.oneOnOneVoiceCall();

        config.avatarBuilder =
            (
              BuildContext context,
              Size size,
              ZegoUIKitUser? user,
              Map extraInfo,
            ) {
              return user != null
                  ? Container(
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        image: DecorationImage(
                          image: AssetImage('assets/Images/men.png'),
                          fit: BoxFit.cover,
                        ),
                      ),
                    )
                  : const SizedBox();
            };

        config.noResponseEnd = ZegoCallNoResponseEndConfig(
          enabled: true,
          timeoutSeconds: 3,
        );
        _updateStaffCallBalanceData(
          customData: data.customData,
          callID: data.callID,
        );
        config.foreground = CallBalanceOverlay.listenable(
          dataListenable: _staffCallBalanceData,
        );

        config
          ..turnOnCameraWhenJoining = false
          ..turnOnMicrophoneWhenJoining = false
          ..useSpeakerWhenJoining = true
          ..rootNavigator = true;
        return config;
      },
    );

    _zegoInitialized = true;
    if (!_isCallkitListenerSetup) _isCallkitListenerSetup = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ZegoUIKitPrebuiltCallInvitationService().enterAcceptedOfflineCall();
    });
  }

  void _updateStaffCallBalanceData({
    required String customData,
    required String callID,
  }) {
    final payloadData = _decodeCallCustomData(
      customData.trim().isNotEmpty ? customData : _pendingCallCustomData,
    );
    final callIDData = _decodeCallIDData(callID);
    final data = <String, dynamic>{...callIDData, ...payloadData};

    final balance = _firstIntFromMap(data, const [
      'coin_balance',
      'coinBalance',
      'balance',
      'user_coin_balance',
      'userCoinBalance',
    ]);
    final pricePerMin = _firstIntFromMap(data, const [
      'price_per_min',
      'pricePerMin',
      'rate',
    ]);
    final sentMaxSeconds = _firstIntFromMap(data, const [
      'max_seconds',
      'maxSeconds',
      'remaining_seconds',
      'remainingSeconds',
    ]);
    final maxSeconds = sentMaxSeconds > 0
        ? sentMaxSeconds
        : pricePerMin > 0
        ? (balance ~/ pricePerMin) * 60
        : 0;

    if (balance <= 0 && pricePerMin <= 0 && maxSeconds <= 0) {
      return;
    }

    _setStaffCallBalanceData(
      CallBalanceOverlayData(
        initialBalance: balance,
        pricePerMin: pricePerMin,
        maxSeconds: maxSeconds,
      ),
    );
  }

  Map<String, dynamic> _decodeCallCustomData(String customData) {
    if (customData.isEmpty) return <String, dynamic>{};

    try {
      final decoded = jsonDecode(customData);
      final decodedMap = decoded is Map<String, dynamic>
          ? decoded
          : decoded is Map
          ? Map<String, dynamic>.from(decoded)
          : null;

      if (decodedMap == null) return <String, dynamic>{};

      final wrappedCustomData =
          decodedMap['custom_data'] ??
          decodedMap['customData'] ??
          decodedMap['data'];
      if (wrappedCustomData is String && wrappedCustomData.trim().isNotEmpty) {
        final nestedData = _decodeCallCustomData(wrappedCustomData);
        if (nestedData.isNotEmpty) return nestedData;
      }

      return decodedMap;
    } catch (e) {
      debugPrint('Failed to decode call custom data: $e');
    }

    return <String, dynamic>{};
  }

  int _intFromDynamic(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  int _firstIntFromMap(Map<String, dynamic> data, List<String> keys) {
    for (final key in keys) {
      final value = _intFromDynamic(data[key]);
      if (value > 0) return value;
    }
    return 0;
  }

  Map<String, dynamic> _decodeCallIDData(String callID) {
    final parts = callID.split('_');
    if (parts.length < 8 || parts.first != 'pe') {
      return <String, dynamic>{};
    }

    final timestampIndex = parts.length - 1;
    final maxSecondsIndex = timestampIndex - 1;
    final balanceIndex = timestampIndex - 2;
    final priceIndex = timestampIndex - 3;
    final callTypeIndex = timestampIndex - 4;

    return <String, dynamic>{
      'call_type': parts[callTypeIndex],
      'price_per_min': _intFromDynamic(parts[priceIndex]),
      'coin_balance': _intFromDynamic(parts[balanceIndex]),
      'max_seconds': _intFromDynamic(parts[maxSecondsIndex]),
    };
  }

  // ─────────────────────────────────────────────────────────────────────────
  // HELPERS
  // ─────────────────────────────────────────────────────────────────────────

  void _setStaffCallBalanceData(CallBalanceOverlayData data) {
    if (_isDashboardDisposed) return;
    _staffCallBalanceData.value = data;
  }

  void _onStaffCallEnded(
    ZegoCallEndEvent event,
    VoidCallback defaultAction, {
    bool markAvailable = true,
  }) {
    if (_isDashboardDisposed) {
      WidgetsBinding.instance.addPostFrameCallback((_) => defaultAction());
      return;
    }
    if (_isStaffCallEnding) {
      debugPrint('📞 Duplicate staff onCallEnd ignored → ${event.reason}');
      return;
    }
    _isStaffCallEnding = true;

    debugPrint('📞 Staff onCallEnd → ${event.reason}');

    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        defaultAction();
      } catch (e) {
        debugPrint('Failed to run staff call defaultAction: $e');
      }

      if (_isDashboardDisposed) {
        _isStaffCallEnding = false;
        return;
      }
      _resetCallState(markAvailable: markAvailable);
      unawaited(_safeEndAllCalls());
      _isStaffCallEnding = false;
    });
  }

  void _resetCallState({bool markAvailable = false}) {
    if (_isDashboardDisposed) return;

    _acceptTimeoutTimer?.cancel();
    _killedStateAcceptPending = false;
    _pendingCallID = null;
    _pendingCallCustomData = '';
    _setStaffCallBalanceData(const CallBalanceOverlayData.empty());
    _isZegoShowingUI = false;
    _isCallBeingHandled = false;

    if (_isOnCall && mounted) {
      setState(() => _isOnCall = false);
    } else {
      _isOnCall = false;
    }

    if (markAvailable) {
      _updateBusyStatus(false);
    }

    try {
      ScreenBrightness().resetScreenBrightness();
    } catch (e) {
      debugPrint("Failed to reset screen brightness in _resetCallState: $e");
    }
  }

  Future<void> _requestOverlayPermission() async {
    if (!Platform.isAndroid) return;
    if (!await Permission.systemAlertWindow.isGranted) {
      final intent = AndroidIntent(
        action: 'android.settings.action.MANAGE_OVERLAY_PERMISSION',
        data: 'package:com.dude.dudeapp',
      );
      await intent.launch();
    }
  }

  Future<void> _ensureBatteryOptimizationDisabled() async {
    if (!Platform.isAndroid) return;
    try {
      final ignoring = await _windowChannel.invokeMethod(
        'isIgnoringBatteryOptimizations',
      );
      if (ignoring == false) {
        await _windowChannel.invokeMethod('requestIgnoreBatteryOptimizations');
      }
    } catch (e) {
      debugPrint("battery optimization request error: $e");
    }
  }

  Future<void> _updateBusyStatus(bool isBusy) async {
    if (_isUpdatingStatus) return;
    _isUpdatingStatus = true;
    final staffVM = context.read<StaffViewModel>();
    final staff = staffVM.currentStaff;
    if (staff == null) {
      _isUpdatingStatus = false;
      return;
    }
    try {
      final ok = await staffVM.updateStaffCallStatus(
        staffId: staff.id,
        isBusy: isBusy,
      );
      if (ok && socketService.isConnected) {
        socketService.emit("staff_busy_status", {
          "memberID": staff.memberID,
          "isBusy": isBusy,
          "isOnline": _isOnline ?? false,
          "timestamp": DateTime.now().millisecondsSinceEpoch,
        });
      }
    } catch (e) {
      debugPrint("❌ updateBusyStatus error: $e");
    } finally {
      _isUpdatingStatus = false;
    }
  }

  Future<void> _refreshAllData() async {
    final staffVM = context.read<StaffViewModel>();
    await Future.wait([
      staffVM.fetchStaffSingleData(),
      staffVM.fetchStaffCallStats(),
      staffVM.fetchWeeklyCallGraph(),
    ]);
  }

  // ─────────────────────────────────────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_showAcceptedCallConnecting) {
      return const Scaffold(
        backgroundColor: Color(0xFF050505),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.call_rounded, color: Color(0xFFF2608C), size: 54),
              SizedBox(height: 22),
              Text(
                'Connecting call...',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: 24),
              CircularProgressIndicator(color: Color(0xFFF2608C)),
            ],
          ),
        ),
      );
    }
    if (_isOnline == null || _selectedCallType == null) {
      return Scaffold(
        backgroundColor: DudeTheme.background,
        body: PremiumAmbientBackground(
          child: const Center(
            child: CircularProgressIndicator(
              color: DudeTheme.accent,
              strokeWidth: 2,
            ),
          ),
        ),
      );
    }

    return Consumer<StaffViewModel>(
      builder: (context, vm, child) {
        final staff = vm.currentStaff;
        return Scaffold(
          backgroundColor: DudeTheme.background,
          body: PremiumAmbientBackground(
            child: SafeArea(
              child: RefreshIndicator(
                onRefresh: _refreshAllData,
                color: DudeTheme.accent,
                backgroundColor: DudeTheme.surface,
                child: vm.isFetchingSingleStaff
                    ? ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: const [
                          SizedBox(height: 300),
                          Center(
                            child: CircularProgressIndicator(
                              color: DudeTheme.accent,
                              strokeWidth: 2,
                            ),
                          ),
                        ],
                      )
                    : vm.singleStaffError != null
                    ? ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: [
                          const SizedBox(height: 300),
                          Center(
                            child: Text(
                              vm.singleStaffError!,
                              style: TextStyle(color: DudeTheme.danger),
                            ),
                          ),
                        ],
                      )
                    : staff == null
                    ? ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: const [
                          SizedBox(height: 300),
                          Center(
                            child: Text(
                              'No profile data',
                              style: TextStyle(color: DudeTheme.textMuted),
                            ),
                          ),
                        ],
                      )
                    : SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        child: Column(
                          children: [
                            PremiumStaggerItem(
                              index: 0,
                              child: _buildTopBar(staff),
                            ),
                            const SizedBox(height: 14),
                            PremiumStaggerItem(
                              index: 1,
                              child: _buildOnlineStatusCard(),
                            ),
                            if (_isOnCall) ...[
                              const SizedBox(height: 12),
                              PremiumStaggerItem(
                                index: 2,
                                child: _onCallBanner(),
                              ),
                            ],
                            const SizedBox(height: 16),
                            PremiumStaggerItem(
                              index: 3,
                              child: _buildEarningsHero(staff),
                            ),
                            const SizedBox(height: 16),
                            PremiumStaggerItem(
                              index: 4,
                              child: _buildQuickActionsGrid(staff),
                            ),
                            const SizedBox(height: 16),
                            PremiumStaggerItem(
                              index: 5,
                              child: _buildCallTypeSection(),
                            ),
                            const SizedBox(height: 16),
                            PremiumStaggerItem(
                              index: 6,
                              child: _buildCallsSection(),
                            ),
                            const SizedBox(height: 100),
                          ],
                        ),
                      ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTopBar(StaffSingleProfile staff) {
    final firstName = (staff.name ?? 'Staff').split(' ').first;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Row(
        children: [
          const DudeLogo(height: 36),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hi, $firstName',
                  style: TextStyle(
                    color: DudeTheme.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                ),
                Text(
                  'Staff dashboard',
                  style: TextStyle(
                    color: DudeTheme.textMuted.withValues(alpha: 0.95),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              bondNavigator.newPage(
                context,
                page: const StaffProfileScreen(backPage: true),
              );
            },
            child: Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: DudeTheme.premiumAccentGradient,
                boxShadow: DudeTheme.accentGlowShadow(blur: 12, spread: -6),
              ),
              padding: const EdgeInsets.all(2),
              child: ClipOval(
                child: Image(
                  image: (staff.image != null && staff.image!.isNotEmpty)
                      ? NetworkImage(staff.image!)
                      : const AssetImage('assets/Images/women.png'),
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) =>
                      Image.asset('assets/Images/women.png', fit: BoxFit.cover),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOnlineStatusCard() {
    final isOnline = _isOnline!;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: PremiumGlassCard(
        glow: isOnline,
        padding: const EdgeInsets.all(14),
        radius: 20,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isOnline
                      ? Icons.wifi_tethering_rounded
                      : Icons.power_settings_new_rounded,
                  color: isOnline ? DudeTheme.success : DudeTheme.textSubtle,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  isOnline ? 'You are online' : 'You are offline',
                  style: TextStyle(
                    color: DudeTheme.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                if (_isTogglingStatus)
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: DudeTheme.accent,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: _isTogglingStatus ? null : _toggleOnlineStatus,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: DudeTheme.background.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: DudeTheme.border.withValues(alpha: 0.6),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _onlineOption(
                        label: 'Online',
                        selected: isOnline,
                        activeColor: DudeTheme.success,
                      ),
                    ),
                    Expanded(
                      child: _onlineOption(
                        label: 'Offline',
                        selected: !isOnline,
                        activeColor: DudeTheme.danger,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isOnline
                  ? 'Users can reach you for calls'
                  : 'Go online to start receiving calls',
              style: TextStyle(
                color: DudeTheme.textSubtle.withValues(alpha: 0.9),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _onlineOption({
    required String label,
    required bool selected,
    required Color activeColor,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: selected
            ? activeColor.withValues(alpha: 0.15)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        border: selected
            ? Border.all(color: activeColor.withValues(alpha: 0.45))
            : null,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: selected ? activeColor : Colors.transparent,
              border: selected
                  ? null
                  : Border.all(color: DudeTheme.textSubtle, width: 1.2),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: selected ? activeColor : DudeTheme.textMuted,
              fontSize: 13,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _onCallBanner() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: DudeTheme.warning.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: DudeTheme.warning.withValues(alpha: 0.45)),
        ),
        child: const Row(
          children: [
            Icon(Icons.call_rounded, color: DudeTheme.warning, size: 18),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'You are currently on a call',
                style: TextStyle(
                  color: DudeTheme.warning,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEarningsHero(StaffSingleProfile staff) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
        decoration: BoxDecoration(
          gradient: DudeTheme.premiumAccentGradient,
          borderRadius: BorderRadius.circular(22),
          boxShadow: DudeTheme.accentGlowShadow(blur: 22, spread: -4),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Total earnings',
              style: TextStyle(
                color: DudeTheme.textOnAccent.withValues(alpha: 0.85),
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '₹${staff.staffEarned?.toStringAsFixed(2) ?? '0.00'}',
              style: TextStyle(
                color: DudeTheme.textOnAccent,
                fontSize: 34,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.5,
                height: 1,
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _earningsChip(
                    label: 'Pending',
                    value:
                        '₹${staff.pendingBalance?.toStringAsFixed(2) ?? '0.00'}',
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _earningsChip(
                    label: 'This month',
                    value: '₹${(staff.staffEarned ?? 0).toStringAsFixed(2)}',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _earningsChip({required String label, required String value}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: DudeTheme.textOnAccent.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: DudeTheme.textOnAccent.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: DudeTheme.textOnAccent.withValues(alpha: 0.8),
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              color: DudeTheme.textOnAccent,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsGrid(StaffSingleProfile staff) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick actions',
            style: TextStyle(
              color: DudeTheme.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _quickActionTile(
                  icon: Icons.account_balance_wallet_outlined,
                  label: 'Withdraw',
                  color: DudeTheme.accent,
                  onTap: () => bondNavigator.newPage(
                    context,
                    page: WithdrawalRequestScreen(
                      withdrawAmount:
                          staff.pendingBalance?.toStringAsFixed(2) ?? '0',
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _quickActionTile(
                  icon: Icons.receipt_long_outlined,
                  label: 'History',
                  color: DudeTheme.accentBright,
                  onTap: () => bondNavigator.newPage(
                    context,
                    page: const WithdrawHistory(backPage: true),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _quickActionTile(
                  icon: Icons.savings_outlined,
                  label: 'Wallet',
                  color: DudeTheme.success,
                  onTap: () => bondNavigator.newPage(
                    context,
                    page: const StaffWalletScreen(),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _quickActionTile(
                  icon: Icons.chat_bubble_outline_rounded,
                  label: 'Messages',
                  color: DudeTheme.warning,
                  onTap: () => bondNavigator.newPage(
                    context,
                    page: const StaffChatListScreen(backPage: true),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _quickActionTile({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: PremiumGlassCard(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        radius: 18,
        child: Column(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: color.withValues(alpha: 0.3)),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 10),
            Text(
              label,
              style: TextStyle(
                color: DudeTheme.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCallTypeSection() {
    if (_selectedCallType == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: PremiumGlassCard(
        padding: const EdgeInsets.all(16),
        radius: 20,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Call preferences',
              style: TextStyle(
                color: DudeTheme.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Users can call you via',
              style: TextStyle(
                color: DudeTheme.textMuted.withValues(alpha: 0.95),
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _callTypePill(type: StaffCallType.audio, label: 'Audio'),
                _callTypePill(type: StaffCallType.video, label: 'Video'),
                _callTypePill(type: StaffCallType.both, label: 'Both'),
                if (_isUpdatingCallType)
                  const Padding(
                    padding: EdgeInsets.only(left: 4),
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: DudeTheme.accent,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 14),
            _communityGroupButton(),
          ],
        ),
      ),
    );
  }

  Widget _communityGroupButton() {
    return GestureDetector(
      onTap: _openCommunityGroup,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF0F2A1D),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFF25D366), width: 1.2),
        ),
        child: const Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: Color(0xFF25D366),
              child: Icon(
                Icons.phone_in_talk_rounded,
                color: Colors.white,
                size: 18,
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Join community group for updates',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  height: 1.3,
                ),
              ),
            ),
            Icon(Icons.open_in_new_rounded, color: Color(0xFF25D366), size: 18),
          ],
        ),
      ),
    );
  }

  Widget _callTypePill({required StaffCallType type, required String label}) {
    final isSelected = _selectedCallType == type;
    final staffVM = context.read<StaffViewModel>();

    return GestureDetector(
      onTap: () async {
        if (isSelected) return;
        HapticFeedback.lightImpact();

        setState(() => _isUpdatingCallType = true);
        final success = await staffVM.updateStaffCallType(
          _callTypeToString(type),
        );

        if (mounted) {
          setState(() => _isUpdatingCallType = false);
          if (success) {
            await _saveCallType(type);
            setState(() => _selectedCallType = type);
            Utils.snackBar('Call type updated to $label');
          } else {
            Utils.snackBarErrorMessage(
              staffVM.callTypeUpdateError ?? 'Failed to update call type',
            );
          }
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        decoration: BoxDecoration(
          gradient: isSelected ? DudeTheme.premiumAccentGradient : null,
          color: isSelected
              ? null
              : DudeTheme.background.withValues(alpha: 0.45),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected
                ? DudeTheme.accent
                : DudeTheme.border.withValues(alpha: 0.7),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? DudeTheme.textOnAccent : DudeTheme.textMuted,
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildCallsSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: PremiumGlassCard(
        padding: const EdgeInsets.all(16),
        radius: 20,
        child: Consumer<StaffViewModel>(
          builder: (context, vm, child) {
            if (vm.isFetchingWeeklyGraph || vm.isFetchingCallStats) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: CircularProgressIndicator(
                    color: DudeTheme.accent,
                    strokeWidth: 2,
                  ),
                ),
              );
            }
            if (vm.weeklyGraphError != null || vm.callStatsError != null) {
              return Column(
                children: [
                  Text(
                    vm.weeklyGraphError ?? vm.callStatsError ?? '',
                    style: TextStyle(color: DudeTheme.danger),
                    textAlign: TextAlign.center,
                  ),
                  TextButton(
                    onPressed: () {
                      vm.fetchWeeklyCallGraph();
                      vm.fetchStaffCallStats();
                    },
                    child: Text(
                      'Retry',
                      style: TextStyle(color: DudeTheme.accent),
                    ),
                  ),
                ],
              );
            }

            final dayOrder = ['Sun', 'Sat', 'Fri', 'Thu', 'Wed', 'Tue', 'Mon'];
            final callMap = {for (var d in vm.weeklyCallGraph) d.day: d.calls};
            final orderedCalls = dayOrder
                .map((day) => callMap[day] ?? 0)
                .toList();
            final maxCalls = orderedCalls.isEmpty
                ? 1
                : orderedCalls.reduce((a, b) => a > b ? a : b);

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Calls this week',
                        style: TextStyle(
                          color: DudeTheme.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => bondNavigator.newPage(
                        context,
                        page: const RecentCallsPage(backPage: true),
                      ),
                      child: Text(
                        'View all',
                        style: TextStyle(
                          color: DudeTheme.accent,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Text(
                      'Total minutes: ',
                      style: TextStyle(
                        color: DudeTheme.textMuted.withValues(alpha: 0.95),
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      _formatMinutes(vm.totalMinutes),
                      style: TextStyle(
                        color: DudeTheme.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                SizedBox(
                  height: 110,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: List.generate(7, (i) {
                      final calls = orderedCalls[i];
                      final frac = maxCalls == 0
                          ? 0.0
                          : calls / maxCalls.toDouble();
                      final h = (frac * 100).clamp(6.0, 100.0);
                      return Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Container(
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              height: h,
                              decoration: BoxDecoration(
                                gradient: DudeTheme.premiumAccentGradient,
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: dayOrder
                      .map(
                        (d) => Expanded(
                          child: Text(
                            d,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: DudeTheme.textSubtle.withValues(
                                alpha: 0.9,
                              ),
                              fontSize: 11,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  String _formatMinutes(int seconds) {
    if (seconds < 60) return '0';
    final minutes = seconds ~/ 60;
    final rem = seconds % 60;
    if (minutes >= 60) {
      final h = minutes ~/ 60;
      final m = minutes % 60;
      return m > 0 ? '$h hr $m min' : '$h hr';
    }
    return rem > 0 ? '$minutes min $rem sec' : '$minutes min';
  }
}
