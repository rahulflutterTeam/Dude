import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:zego_uikit/zego_uikit.dart';
import 'package:zego_uikit_prebuilt_call/zego_uikit_prebuilt_call.dart';
import 'package:zego_uikit_signaling_plugin/zego_uikit_signaling_plugin.dart';

class ZegoLifecycle {
  ZegoLifecycle._();

  static Future<void>? _systemCallingUISetup;
  static Future<void>? _uninitializing;

  static Future<void> ensureSystemCallingUIConfigured() {
    return _systemCallingUISetup ??= _configureSystemCallingUI();
  }

  static Future<void> _configureSystemCallingUI() async {
    try {
      await ZegoUIKit().initLog().timeout(const Duration(seconds: 4));
      await ZegoUIKitPrebuiltCallInvitationService()
          .useSystemCallingUI([ZegoUIKitSignalingPlugin()])
          .timeout(const Duration(seconds: 4));
    } catch (e) {
      debugPrint('ZEGO system calling UI setup failed or timed out: $e');
    }
  }

  static Future<void> uninitSafely() {
    return _uninitializing ??= _runUninitSafely();
  }

  static Future<void> _runUninitSafely() async {
    try {
      await ZegoUIKitPrebuiltCallInvitationService().uninit().timeout(
        const Duration(seconds: 4),
      );
    } catch (e) {
      debugPrint('ZEGO uninit failed or timed out: $e');
    } finally {
      _uninitializing = null;
    }
  }
}
