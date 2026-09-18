// lib/Services/ZegoCallService.dart

import 'dart:async';
import 'dart:convert';

import 'package:dude/Dude_Utils/CustomSnackBar/StatusMessage.dart';
import 'package:dude/DudeScreens/HomeScreen/call_balance_overlay.dart';
import 'package:dude/DudeScreens/HomeScreen/callService.dart';
import 'package:dude/DudeScreens/HomeScreen/zego_lifecycle.dart';
import 'package:dude/Reusable_Widgets/dude_cached_image.dart';
import 'package:flutter/material.dart';
import 'package:zego_uikit/zego_uikit.dart';
import 'package:zego_uikit_prebuilt_call/zego_uikit_prebuilt_call.dart';
import 'package:zego_uikit_signaling_plugin/zego_uikit_signaling_plugin.dart';

class ZegoCallService {
  static final ZegoCallService _instance = ZegoCallService._internal();
  factory ZegoCallService() => _instance;
  ZegoCallService._internal();

  bool _isInitialized = false;
  String? _currentUserId;
  Future<void>? _initializing;

  bool get isInitialized => _isInitialized;
  String? get currentUserId => _currentUserId;

  Map<String, dynamic> _decodeCustomData(String customData) {
    if (customData.isEmpty) return {};

    try {
      final decoded = jsonDecode(customData);
      if (decoded is Map) {
        return Map<String, dynamic>.from(decoded);
      }
    } catch (e) {
      debugPrint("Failed to decode call customData: $e");
    }

    return {};
  }

  void _reportMissedCall({
    required String callID,
    String customData = '',
    bool? isVideoCall,
  }) {
    final data = _decodeCustomData(customData);
    final staffId = data['staff_id']?.toString();
    final callType =
        data['call_type']?.toString() ??
        (isVideoCall == true ? "video" : "audio");

    unawaited(
      CallService().reportMissedCall(
        staffId: staffId,
        callType: callType,
        callID: callID,
      ),
    );
  }

  Future<void> ensureInitializedForCaller({
    required String userId,
    required String userName,
    String? avatarUrl,
    ZegoUIKitPrebuiltCallEvents? events,
  }) async {
    // Don't reinitialize if already initialized for same user
    if (_isInitialized && _currentUserId == userId) {
      return;
    }

    if (_initializing != null) {
      await _initializing;
      if (_isInitialized && _currentUserId == userId) return;
    }

    _initializing = _initialize(
      userId: userId,
      userName: userName,
      avatarUrl: avatarUrl,
      events: events,
    );

    try {
      await _initializing;
    } finally {
      _initializing = null;
    }
  }

  Future<void> _initialize({
    required String userId,
    required String userName,
    String? avatarUrl,
    ZegoUIKitPrebuiltCallEvents? events,
  }) async {
    // If initialized for different user, we need to reinitialize
    if (_isInitialized && _currentUserId != userId) {
      debugPrint("🔄 Reinitializing Zego for different user...");
      await ZegoLifecycle.uninitSafely();
      _isInitialized = false;
    }

    // debugPrint("🔌 Initializing Zego for user: $userId");

    await ZegoUIKitPrebuiltCallInvitationService().init(
      appID: 474972896,
      appSign:
          "e950eba53072e23f8cdd3f0e2341f60cb240300059d8e613c53aafdd5d844ad3",
      userID: userId,
      userName: userName,
      plugins: [ZegoUIKitSignalingPlugin()],
      invitationEvents: ZegoUIKitPrebuiltCallInvitationEvents(
        onOutgoingCallRejectedCauseBusy:
            (String callID, ZegoCallUser callee, String customData) {
              debugPrint(
                "Call rejected (busy) → callID: $callID, "
                "callee: ${callee.id} (${callee.name}), "
                "customData: $customData",
              );
              CallService().resetCall();
              Utils.snackBarErrorMessage("User is busy right now");
            },
        onOutgoingCallDeclined:
            (String callID, ZegoCallUser callee, String customData) {
              _reportMissedCall(callID: callID, customData: customData);
              CallService().resetCall();
              Utils.snackBarErrorMessage("Call was declined");
            },
        onOutgoingCallTimeout:
            (String callID, List<ZegoCallUser> callees, bool isVideoCall) {
              _reportMissedCall(callID: callID, isVideoCall: isVideoCall);
              CallService().resetCall();
              Utils.snackBarErrorMessage("No response from user");
            },
      ),

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
      events: events,
      uiConfig: ZegoCallInvitationUIConfig(
        inviter: ZegoCallInvitationInviterUIConfig(defaultSpeakerOn: true),
      ),
      requireConfig: (ZegoCallInvitationData invitationData) {
        var config = invitationData.invitees.length > 1
            ? ZegoCallType.videoCall == invitationData.type
                  ? ZegoUIKitPrebuiltCallConfig.groupVideoCall()
                  : ZegoUIKitPrebuiltCallConfig.groupVoiceCall()
            : invitationData.type == ZegoInvitationType.videoCall
            ? ZegoUIKitPrebuiltCallConfig.oneOnOneVideoCall()
            : ZegoUIKitPrebuiltCallConfig.oneOnOneVoiceCall();
        config.avatarBuilder =
            (
              BuildContext context,
              Size size,
              ZegoUIKitUser? user,
              Map extraInfo,
            ) {
              if (user == null) return const SizedBox();

              // ── Resolve image: network URL if available, else fallback asset ──
              final ImageProvider imageProvider =
                  (avatarUrl != null && avatarUrl.isNotEmpty)
                  ? DudeCachedImage.provider(avatarUrl)
                  : const AssetImage('assets/Images/women.png')
                        as ImageProvider;

              return Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  image: DecorationImage(
                    image: imageProvider,
                    fit: BoxFit.cover,
                  ),
                ),
              );
            };
        config.noResponseEnd = ZegoCallNoResponseEndConfig(
          enabled: true,
          timeoutSeconds: 3,
        );
        config.foreground = const CallBalanceOverlay.user();
        config
          ..turnOnCameraWhenJoining = false
          ..turnOnMicrophoneWhenJoining = false
          ..useSpeakerWhenJoining = true
          ..rootNavigator = true;
        return config;
      },
    );

    _isInitialized = true;
    _currentUserId = userId;
    // debugPrint("✅ Zego initialized successfully");
  }

  Future<void> uninitialize() async {
    if (!_isInitialized) return;

    debugPrint("🔌 Uninitializing Zego...");
    await ZegoLifecycle.uninitSafely();
    _isInitialized = false;
    _currentUserId = null;
    _initializing = null;
  }
}
