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
import 'package:dude/Reusable_Widgets/AppText_Theme/AppText_Theme.dart';
import 'package:dude/Reusable_Widgets/BondingNavigator.dart';
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
import 'package:flutter_svg/svg.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:screen_brightness/screen_brightness.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:zego_uikit/zego_uikit.dart';
import 'package:zego_uikit_prebuilt_call/zego_uikit_prebuilt_call.dart';
import 'package:zego_uikit_signaling_plugin/zego_uikit_signaling_plugin.dart';

const _windowChannel = MethodChannel('com.dude.dudeapp/window');

// ── Design tokens ─────────────────────────────────────────────────────────
const _kBg = Color(0xFF0D0D1A);
const _kCard = Color(0xFF13132A);
const _kCardBorder = Color(0xFF2A2A4A);
const _kAccent = Color(0xFFD4F53C);
const _kAccent2 = Color(0xFFB8E832);
const _kPurple = Color(0xFF6C4EF5);
const _kPurple2 = Color(0xFF9B6DFF);
const _kText = Color(0xFFFFFFFF);
const _kTextSub = Color(0xFF8888AA);
const _kGold = Color(0xFFFFCC00);
const _kCommunityGroupUrl =
    'https://chat.whatsapp.com/BZ8VkPf99GDGP8cU8EhpNy?s=cl&p=a&ilr=2';
// ──────────────────────────────────────────────────────────────────────────

// SharedPreferences keys
const _kIsOnlineKey = 'staff_is_online';
const _kCallTypeKey = 'staff_call_type';

enum StaffCallType { audio, video, both }

class BondingDashboardPage extends StatefulWidget {
  const BondingDashboardPage({super.key});

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
  String? _pendingCallID;
  String _pendingCallCustomData = '';
  final ValueNotifier<CallBalanceOverlayData> _staffCallBalanceData =
      ValueNotifier<CallBalanceOverlayData>(
        const CallBalanceOverlayData.empty(),
      );
  bool _isCallkitListenerSetup = false;
  Timer? _acceptTimeoutTimer;
  Timer? _toggleTimeoutTimer;

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
    WidgetsBinding.instance.addObserver(this);
    _socketCallBalanceTopUpHandler = _handleSocketCallBalanceTopUp;
    AppUpdateService.checkForUpdate(context);
    _setupCallListeners();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (Platform.isAndroid) _requestOverlayPermission();

      // ── Step 1: Load persisted UI state FIRST — no flicker on re-entry ──
      final persistedOnline = await _loadPersistedOnlineStatus();
      if (mounted) setState(() => _isOnline = persistedOnline);

      // ── Step 2: Fetch server data ────────────────────────────────────────
      final staffVM = context.read<StaffViewModel>();
      await staffVM.fetchStaffSingleData();
      await staffVM.fetchStaffCallStats();
      await staffVM.fetchWeeklyCallGraph();

      final staff = staffVM.currentStaff;
      if (staff == null || staff.memberID.isEmpty) return;

      // ── Step 3: Resolve call type (local pref wins) ──────────────────────
      final resolvedCallType = await _loadPersistedCallType(staff.callType);
      if (mounted) setState(() => _selectedCallType = resolvedCallType);

      // ── Step 4: Connect socket using the persisted online status ─────────
      if (persistedOnline) {
        if (!socketService.isConnected) {
          socketService.connectStaff(staff.memberID);
          await Future.delayed(const Duration(milliseconds: 600));
        }
        if (socketService.isConnected) {
          _emitOnlineStatus(staff.memberID, isOnline: true);
        }
      }

      socketService.listenStatusChanges((data) {
        if (mounted) debugPrint("📡 Status change: $data");
      });

      await _detectKilledStateAccept();
      if (persistedOnline) {
        await _initZego(staff);
      }

      if (Platform.isAndroid) {
        if (await Permission.notification.isDenied) {
          await Permission.notification.request();
        }
        await FlutterCallkitIncoming.requestFullIntentPermission();
        if (!await Permission.systemAlertWindow.isGranted) {
          await Permission.systemAlertWindow.request();
        }
      }

      if (_killedStateAcceptPending) _startAcceptTimeout();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _callEventSubscription?.cancel();
    _callBalanceSyncSubscription?.cancel();
    socketService.removeCallBalanceTopUpListener(
      _socketCallBalanceTopUpHandler,
    );
    _acceptTimeoutTimer?.cancel();
    _toggleTimeoutTimer?.cancel();
    _staffCallBalanceData.dispose();

    if (socketService.isConnected) socketService.disconnect();
    if (_isOnCall) _updateBusyStatus(false);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final staffVM = context.read<StaffViewModel>();
    final staff = staffVM.currentStaff;
    final isOnline = _isOnline ?? false;

    switch (state) {
      case AppLifecycleState.resumed:
        _isAppInForeground = true;
        _isAppMinimized = false;
        debugPrint("📱 App resumed");

        if (isOnline && staff != null) {
          if (!socketService.isConnected) {
            socketService.connectStaff(staff.memberID);
            Future.delayed(const Duration(milliseconds: 600), () {
              if (socketService.isConnected && (_isOnline ?? false)) {
                _emitOnlineStatus(staff.memberID, isOnline: true);
              }
            });
          } else {
            _emitOnlineStatus(staff.memberID, isOnline: true);
          }
        }
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

  // ─────────────────────────────────────────────────────────────────────────
  // KILLED-STATE DETECTION
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> _detectKilledStateAccept() async {
    bool detected = false;
    try {
      final activeCalls = await FlutterCallkitIncoming.activeCalls();
      if (activeCalls != null) {
        final list = activeCalls is List ? activeCalls : [activeCalls];
        if (list.isNotEmpty) {
          detected = true;
          try {
            final first = list.first;
            if (first is Map) {
              _pendingCallID =
                  first['id']?.toString() ?? first['callID']?.toString();
            }
          } catch (_) {}
        }
      }
    } catch (e) {
      debugPrint("activeCalls() error: $e");
    }

    if (!detected) {
      try {
        final data = await _windowChannel.invokeMethod('getAcceptedCallData');
        if (data != null && data is Map) {
          final action = (data['action'] as String? ?? 'ACCEPT').toUpperCase();
          if (action == 'DECLINE') {
            await FlutterCallkitIncoming.endAllCalls();
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
      } catch (e) {
        try {
          await ZegoUIKitPrebuiltCallInvitationService().accept();
        } catch (e2) {
          _isCallBeingHandled = false;
        }
      }
    });
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
    if (!mounted) return;

    final hasActiveCallOverlay =
        _staffCallBalanceData.value.initialBalance > 0 ||
        _staffCallBalanceData.value.maxSeconds > 0;
    if (!_isOnCall && !hasActiveCallOverlay && !_isZegoShowingUI) return;

    final current = _staffCallBalanceData.value;
    final pricePerMin = payload.pricePerMin > 0
        ? payload.pricePerMin
        : current.pricePerMin;

    _staffCallBalanceData.value = CallBalanceOverlayData(
      initialBalance: payload.coinBalance,
      pricePerMin: pricePerMin,
      maxSeconds: payload.maxSeconds,
      syncedElapsedSeconds: payload.elapsedSeconds,
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
      appID: 1545531832,
      appSign:
          "9c91e452ef3e7c19b88c8a332ca0b6caf18bfd2f2232e7b37239bd98a81ebf0d",
      userID: staff.memberID,
      userName: staff.name ?? "Staff",
      plugins: [ZegoUIKitSignalingPlugin()],

      notificationConfig: ZegoCallInvitationNotificationConfig(
        androidNotificationConfig: ZegoAndroidNotificationConfig(
          channelID: "zego_call_channel",
          channelName: "Incoming Calls",
          sound: "zego_incoming",
          icon: "ic_stat_notify",
          vibrate: true,
          callIDVisibility: true,
          showOnLockedScreen: true,
          showOnFullScreen: true,
          callChannel: ZegoCallAndroidNotificationChannelConfig(
            channelID: "zego_call_channel",
            channelName: "Incoming Calls",
            icon: "ic_stat_notify",
            sound: "zego_incoming",
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
                  await FlutterCallkitIncoming.endAllCalls();
                } catch (e) {
                  try {
                    await ZegoUIKitPrebuiltCallInvitationService().accept();
                    await FlutterCallkitIncoming.endAllCalls();
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
          _resetCallState();
          await FlutterCallkitIncoming.endAllCalls();
        },
        onIncomingCallTimeout: (callID, caller) async {
          _resetCallState();
          await FlutterCallkitIncoming.endAllCalls();
        },
        onIncomingCallAcceptButtonPressed: () async {
          _isZegoShowingUI = false;
          _isCallBeingHandled = true;
          _pendingCallID = null;
          await FlutterCallkitIncoming.endAllCalls();
        },
        onIncomingCallDeclineButtonPressed: () async {
          _resetCallState();
          await FlutterCallkitIncoming.endAllCalls();
        },
      ),
      events: ZegoUIKitPrebuiltCallEvents(
        onCallEnd: (event, defaultAction) {
          _resetCallState(markAvailable: true);
          FlutterCallkitIncoming.endAllCalls();
          defaultAction();
        },
        user: ZegoCallUserEvents(
          onLeave: (user) {
            ZegoUIKit().leaveRoom();
            _resetCallState(markAvailable: true);
            FlutterCallkitIncoming.endAllCalls();
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
              _resetCallState(markAvailable: true);
              FlutterCallkitIncoming.endAllCalls();
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
          ..useSpeakerWhenJoining = true;
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
        ? ((balance ~/ pricePerMin) * 60).clamp(0, 20 * 60)
        : 0;

    if (balance <= 0 && pricePerMin <= 0 && maxSeconds <= 0) {
      return;
    }

    _staffCallBalanceData.value = CallBalanceOverlayData(
      initialBalance: balance,
      pricePerMin: pricePerMin,
      maxSeconds: maxSeconds,
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

  void _resetCallState({bool markAvailable = false}) {
    _acceptTimeoutTimer?.cancel();
    _killedStateAcceptPending = false;
    _pendingCallID = null;
    _pendingCallCustomData = '';
    _staffCallBalanceData.value = const CallBalanceOverlayData.empty();
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
    // Show a minimal loader until persisted state is ready — prevents flicker
    if (_isOnline == null || _selectedCallType == null) {
      return Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFF241b40),
                Color(0xFF1C1426),
                Color(0xFF12151c),
                Color(0xFF12151c),
                Color(0xFF12151c),
                Color(0xFF2b1e4e),
              ],
            ),
          ),
          child: const Center(
            child: CircularProgressIndicator(color: _kAccent),
          ),
        ),
      );
    }

    return Consumer<StaffViewModel>(
      builder: (context, vm, child) {
        final staff = vm.currentStaff;
        return Scaffold(
          body: Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF241b40),
                  Color(0xFF1C1426),
                  Color(0xFF12151c),
                  Color(0xFF12151c),
                  Color(0xFF12151c),
                  Color(0xFF2b1e4e),
                ],
              ),
            ),
            child: SafeArea(
              child: RefreshIndicator(
                onRefresh: _refreshAllData,
                color: _kAccent,
                backgroundColor: _kCard,
                child: vm.isFetchingSingleStaff
                    ? ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: const [
                          SizedBox(height: 300),
                          Center(
                            child: CircularProgressIndicator(color: _kAccent),
                          ),
                        ],
                      )
                    : vm.singleStaffError != null
                    ? ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: const [
                          SizedBox(height: 300),
                          Center(
                            child: Text(
                              "Error loading profile",
                              style: TextStyle(color: Colors.redAccent),
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
                              "No profile data",
                              style: TextStyle(color: _kTextSub),
                            ),
                          ),
                        ],
                      )
                    : SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        child: Column(
                          children: [
                            const SizedBox(height: 12),
                            _topBar(staff),
                            const SizedBox(height: 16),
                            if (_isOnCall) ...[
                              _onCallBanner(),
                              const SizedBox(height: 12),
                            ],
                            _earningsCard(staff),
                            const SizedBox(height: 12),
                            _actionButtons(staff),
                            const SizedBox(height: 20),
                            _callTypeSelector(),
                            const SizedBox(height: 20),
                            _callsSection(),
                            const SizedBox(height: 20),
                            _quickLinks(),
                            const SizedBox(height: 12),
                            _quickChatAccess(),
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

  // ─────────────────────────────────────────────────────────────────────────
  // TOP BAR — logo · Online/Offline pill · avatar
  // ─────────────────────────────────────────────────────────────────────────

  Widget _topBar(StaffSingleProfile staff) {
    final isOnline = _isOnline!; // safe: guarded by build() null-check above

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Row(
        children: [
          SvgPicture.asset("assets/Images/dude.svg", height: 46),
          const SizedBox(width: 36),

          // ── Online / Offline pill ──────────────────────────────────────
          GestureDetector(
            onTap: _isTogglingStatus ? null : _toggleOnlineStatus,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: const Color(0xFF221b3c),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _kCardBorder),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Online option
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: isOnline
                          ? const Color(0xFF1C2E1C)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isOnline
                                ? const Color(0xFF7dff63)
                                : Colors.transparent,
                            border: isOnline
                                ? null
                                : Border.all(color: Colors.white24, width: 1.5),
                          ),
                        ),
                        const SizedBox(width: 6),
                        // Show spinner while toggling
                        if (_isTogglingStatus && isOnline)
                          const SizedBox(
                            width: 12,
                            height: 12,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: _kAccent,
                            ),
                          )
                        else
                          Text(
                            "Online",
                            style: TextStyle(
                              color: isOnline
                                  ? const Color(0xFF7dff63)
                                  : _kTextSub,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                      ],
                    ),
                  ),

                  // Offline option
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: !isOnline
                          ? const Color(0xFF2A1C1C)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: !isOnline
                                ? Colors.redAccent
                                : Colors.transparent,
                            border: !isOnline
                                ? null
                                : Border.all(color: Colors.white24, width: 1.5),
                          ),
                        ),
                        const SizedBox(width: 6),
                        if (_isTogglingStatus && !isOnline)
                          const SizedBox(
                            width: 12,
                            height: 12,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.redAccent,
                            ),
                          )
                        else
                          Text(
                            "Offline",
                            style: TextStyle(
                              color: !isOnline ? Colors.white70 : _kTextSub,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const Spacer(),

          // Avatar
          GestureDetector(
            onTap: () => bondNavigator.newPage(
              context,
              page: StaffProfileScreen(backPage: true),
            ),
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: _kAccent.withOpacity(0.6), width: 2),
              ),
              child: ClipOval(
                child: Image(
                  image: (staff.image != null && staff.image!.isNotEmpty)
                      ? NetworkImage(staff.image!)
                      : const AssetImage("assets/Images/women.png"),
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) =>
                      Image.asset("assets/Images/women.png", fit: BoxFit.cover),
                  loadingBuilder: (_, child, progress) {
                    if (progress == null) return child;
                    return const Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: _kAccent,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _onCallBanner() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.orange.withOpacity(0.6)),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.call, color: Colors.orange, size: 16),
          SizedBox(width: 8),
          Text(
            "You are currently on a call",
            style: TextStyle(color: Colors.orange, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // EARNINGS CARD
  // ─────────────────────────────────────────────────────────────────────────

  Widget _earningsCard(StaffSingleProfile staff) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: const LinearGradient(
            begin: Alignment.bottomLeft,
            end: Alignment.topRight,
            colors: [
              Color(0xFF140a27),
              Color(0xFF1e0e3a),
              Color(0xFF1e0e3a),
              Color(0xFF140a27),
            ],
          ),
          border: Border.all(color: _kCardBorder),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Total Earnings",
                          style: TextStyle(color: _kTextSub, fontSize: 13),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "₹${staff.staffEarned!.toStringAsFixed(2)}",
                          style: const TextStyle(
                            color: _kText,
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Image.asset(
                    "assets/Images/coins.png",
                    height: 100,
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.monetization_on,
                      color: _kGold,
                      size: 70,
                    ),
                  ),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Divider(color: Color(0xFF2A2A4A), height: 1),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 18),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Pending payouts:",
                          style: TextStyle(color: _kTextSub, fontSize: 12),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          "₹${staff.pendingBalance!.toStringAsFixed(2)}",
                          style: const TextStyle(
                            color: _kAccent,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 36,
                    color: const Color(0xFF2A2A4A),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(left: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "This month",
                            style: TextStyle(color: _kTextSub, fontSize: 12),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            "₹${(staff.staffEarned ?? 0).toStringAsFixed(2)}",
                            style: const TextStyle(
                              color: _kAccent,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // ACTION BUTTONS
  // ─────────────────────────────────────────────────────────────────────────

  Widget _actionButtons(StaffSingleProfile staff) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => bondNavigator.newPage(
                context,
                page: WithdrawalRequestScreen(
                  withdrawAmount: staff.pendingBalance!.toStringAsFixed(2),
                ),
              ),
              child: Container(
                height: 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: _kAccent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  "Withdraw",
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: GestureDetector(
              onTap: () => bondNavigator.newPage(
                context,
                page: const WithdrawHistory(backPage: true),
              ),
              child: Container(
                height: 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _kAccent, width: 1.5),
                ),
                child: const Text(
                  "View Transaction",
                  style: TextStyle(
                    color: _kAccent,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // CALL TYPE SELECTOR
  // ─────────────────────────────────────────────────────────────────────────

  Widget _callTypeSelector() {
    // Guard: don't render until state is loaded
    if (_selectedCallType == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                "Users Can\nCall Via:",
                style: TextStyle(
                  color: _kText,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  height: 1.4,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _callTypePill(type: StaffCallType.audio, label: "Audio"),
              const SizedBox(width: 10),
              _callTypePill(type: StaffCallType.video, label: "Video"),
              const SizedBox(width: 10),
              _callTypePill(type: StaffCallType.both, label: "Both"),
              if (_isUpdatingCallType) ...[
                const SizedBox(width: 12),
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: _kAccent,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 14),
          _communityGroupButton(),
        ],
      ),
    );
  }

  Widget _communityGroupButton() {
    return Align(
      alignment: Alignment.centerRight,
      child: GestureDetector(
        onTap: _openCommunityGroup,
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(minHeight: 52),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFF0F2A1D),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFF25D366), width: 1.4),
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
                  "Join our community group for more updates",
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    height: 1.25,
                  ),
                ),
              ),
              SizedBox(width: 8),
              Icon(
                Icons.open_in_new_rounded,
                color: Color(0xFF25D366),
                size: 18,
              ),
            ],
          ),
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
            // Persist immediately so re-entry won't reset it
            await _saveCallType(type);
            setState(() => _selectedCallType = type);
            Utils.snackBar("Call type updated to $label");
          } else {
            Utils.snackBarErrorMessage(
              staffVM.callTypeUpdateError ?? "Failed to update call type",
            );
          }
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: isSelected ? _kAccent : const Color(0xFF3A3A5A),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? _kAccent : _kTextSub,
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // CALLS INFO + BAR CHART
  // ─────────────────────────────────────────────────────────────────────────

  Widget _callsSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Consumer<StaffViewModel>(
        builder: (context, vm, child) {
          if (vm.isFetchingWeeklyGraph || vm.isFetchingCallStats) {
            return const Center(
              child: CircularProgressIndicator(color: _kAccent),
            );
          }
          if (vm.weeklyGraphError != null || vm.callStatsError != null) {
            return Column(
              children: [
                Text(
                  vm.weeklyGraphError ?? vm.callStatsError ?? "",
                  style: const TextStyle(color: Colors.redAccent),
                ),
                TextButton(
                  onPressed: () {
                    vm.fetchWeeklyCallGraph();
                    vm.fetchStaffCallStats();
                  },
                  child: const Text("Retry", style: TextStyle(color: _kAccent)),
                ),
              ],
            );
          }

          final dayOrder = ["Sun", "Sat", "Fri", "Thu", "Wed", "Tue", "Mon"];
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
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  const Text(
                    "Calls Info",
                    style: TextStyle(
                      color: _kText,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => bondNavigator.newPage(
                      context,
                      page: RecentCallsPage(backPage: true),
                    ),
                    child: const Text(
                      "View history",
                      style: TextStyle(
                        color: _kAccent,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        decoration: TextDecoration.underline,
                        decorationColor: _kAccent,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Text(
                    "Total Minutes: ",
                    style: TextStyle(color: _kTextSub, fontSize: 14),
                  ),
                  Text(
                    _formatMinutes(vm.totalMinutes),
                    style: const TextStyle(
                      color: _kText,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Bar chart
              SizedBox(
                height: 120,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: List.generate(7, (i) {
                    final calls = orderedCalls[i];
                    final frac = maxCalls == 0
                        ? 0.0
                        : calls / maxCalls.toDouble();
                    final h = (frac * 110).clamp(6.0, 110.0);
                    return Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Container(
                            margin: const EdgeInsets.symmetric(horizontal: 5),
                            height: h,
                            decoration: BoxDecoration(
                              color: _kAccent,
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
                          style: const TextStyle(
                            color: _kTextSub,
                            fontSize: 12,
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

  // ─────────────────────────────────────────────────────────────────────────
  // QUICK LINKS
  // ─────────────────────────────────────────────────────────────────────────

  Widget _quickLinks() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          color: _kCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _kCardBorder),
        ),
        child: Column(
          children: [
            _quickLinkTile(
              icon: Icons.account_balance_wallet_outlined,
              label: "Wallet",
              onTap: () => bondNavigator.newPage(
                context,
                page: const StaffWalletScreen(),
              ),
            ),
            const Divider(color: Color(0xFF2A2A4A), height: 1),
            _quickLinkTile(
              icon: Icons.help_outline_rounded,
              label: "Help & Support",
              onTap: () {},
            ),
          ],
        ),
      ),
    );
  }

  Widget _quickLinkTile({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E38),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _kCardBorder),
        ),
        child: Icon(icon, color: _kAccent, size: 20),
      ),
      title: Text(
        label,
        style: const TextStyle(
          color: _kText,
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
      ),
      trailing: const Icon(Icons.arrow_forward, color: _kAccent, size: 18),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // QUICK CHAT ACCESS
  // ─────────────────────────────────────────────────────────────────────────

  Widget _quickChatAccess() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GestureDetector(
        onTap: () => bondNavigator.newPage(
          context,
          page: const StaffChatListScreen(backPage: true),
        ),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _kCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _kCardBorder),
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E38),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: _kCardBorder),
                ),
                child: const Icon(
                  Icons.chat_bubble_outline_rounded,
                  color: _kAccent,
                  size: 20,
                ),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Open Messages",
                      style: TextStyle(
                        color: _kText,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      "Reply to users · See new messages",
                      style: TextStyle(color: _kTextSub, fontSize: 12),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward, color: _kAccent, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}
