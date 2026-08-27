import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dude/Dude_Utils/push/local_notifications.dart';
import 'package:dude/Dude_Utils/push/push_repo.dart';
import 'package:dude/DudeScreens/BottomNavBar/BottomNavBar.dart';
import 'package:dude/NotificationService/NotificationService.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PushService {
  PushService._();
  static final PushService instance = PushService._();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final PushRepo _repo = PushRepo();

  StreamSubscription<String>? _tokenSub;
  StreamSubscription<RemoteMessage>? _foregroundSub;
  bool _handlersAttached = false;
  bool _bootstrapped = false;
  String? _bootstrappedMemberId;
  String? _bootstrappedRole;
  bool _initialMessageLoaded = false;
  bool _initialMessageOpened = false;
  RemoteMessage? _pendingInitialMessage;
  String? _currentRole;

  /// Call this as early as possible (before runApp) so the initial
  /// notification is captured even in killed-state launches.
  Future<void> captureInitialMessage() async {
    if (_initialMessageLoaded) return;
    _initialMessageLoaded = true;

    try {
      _pendingInitialMessage = await _messaging.getInitialMessage();
      if (_pendingInitialMessage != null) {
        debugPrint('[Push] captured initial notification message');
      }
    } catch (e) {
      debugPrint('❌ [Push] getInitialMessage error: $e');
    }
  }

  Future<void> bootstrapAndRegister({
    required String memberId,
    required String role,
  }) async {
    final normalizedRole = role.toLowerCase();
    _currentRole = normalizedRole;

    if (_bootstrapped &&
        _bootstrappedMemberId == memberId &&
        _bootstrappedRole == normalizedRole) {
      return;
    }

    _bootstrapped = true;
    _bootstrappedMemberId = memberId;
    _bootstrappedRole = normalizedRole;

    // Init local notification channels first
    await LocalNotifications.instance.init();

    await captureInitialMessage();

    // ── Permissions ──────────────────────────────────────────────────────────
    try {
      final settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      debugPrint('[Push] permission: ${settings.authorizationStatus}');

      // Android 13+: system notification prompt needs POST_NOTIFICATIONS.
      if (Platform.isAndroid) {
        final status = await Permission.notification.status;
        if (!status.isGranted) {
          await Permission.notification.request();
        }
      }

      if (Platform.isIOS) {
        await _messaging.setForegroundNotificationPresentationOptions(
          alert: true,
          badge: true,
          sound: true,
        );
      }
    } catch (e) {
      debugPrint('❌ [Push] permission request error: $e');
    }

    // ── Token ────────────────────────────────────────────────────────────────
    await _registerCurrentToken(memberId: memberId, role: normalizedRole);

    _tokenSub?.cancel();
    _tokenSub = _messaging.onTokenRefresh.listen((newToken) {
      _registerToken(memberId: memberId, role: normalizedRole, token: newToken);
    });

    // ── Foreground messages ──────────────────────────────────────────────────
    // FCM does NOT show OS notifications automatically in foreground.
    // We route to the correct channel based on message type.
    _foregroundSub?.cancel();
    _foregroundSub = FirebaseMessaging.onMessage.listen((message) {
      final n = message.notification;
      final title = n?.title ?? message.data['title']?.toString();
      final body = n?.body ?? message.data['body']?.toString();
      if (title == null || body == null) return;

      final payload = jsonEncode({
        ...message.data,
        if (message.messageId != null) 'messageId': message.messageId,
      });

      if (_isWaveMessage(message.data)) {
        LocalNotifications.instance.showPromo(
          title: title,
          body: body,
          payload: payload,
          messageId: message.messageId,
        );
      } else if (_isChatMessage(message.data)) {
        // ← gentle message_tone sound
        LocalNotifications.instance.showChatMessage(
          title: title,
          body: body,
          payload: payload,
          messageId: message.messageId,
        );
      } else {
        // ← default system sound
        LocalNotifications.instance.showPromo(
          title: title,
          body: body,
          payload: payload,
          messageId: message.messageId,
        );
      }
    });
  }

  bool _isWaveMessage(Map<String, dynamic> data) {
    final type = data['type']?.toString().toLowerCase() ?? '';
    final screen = data['screen']?.toString().toLowerCase() ?? '';
    return type == 'wave' || screen == 'wave';
  }

  /// Determines if the incoming FCM data payload is a chat message.
  bool _isChatMessage(Map<String, dynamic> data) {
    if (_isWaveMessage(data)) return false;
    final screen = data['screen']?.toString().toLowerCase() ?? '';
    if (screen == 'chat' || screen == 'message' || screen == 'messages') {
      return true;
    }
    // Check for common chat-related keys
    final chatKeys = [
      'senderId',
      'sender_id',
      'senderUserID',
      'conversationId',
      'conversationID',
      'conversation_id',
    ];
    return chatKeys.any(
      (key) =>
          data.containsKey(key) &&
          data[key] != null &&
          data[key].toString().trim().isNotEmpty,
    );
  }

  void attachMessageOpenHandlers({
    required GlobalKey<NavigatorState> navigatorKey,
  }) {
    if (_handlersAttached) return;
    _handlersAttached = true;

    // Opened from background (app was in background, user tapped notification)
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      _handleNotificationTap(message, navigatorKey);
    });

    // Opened from terminated state
    captureInitialMessage().then((_) {
      openPendingInitialMessage(navigatorKey: navigatorKey);
    });
  }

  void openPendingInitialMessage({
    required GlobalKey<NavigatorState> navigatorKey,
  }) {
    final message = _pendingInitialMessage;
    if (message == null || _initialMessageOpened) return;

    _initialMessageOpened = true;
    _pendingInitialMessage = null;

    // Small delay to ensure navigator is ready
    Future.delayed(const Duration(milliseconds: 1800), () {
      _handleNotificationTap(message, navigatorKey);
    });
  }

  Future<void> _registerCurrentToken({
    required String memberId,
    required String role,
  }) async {
    try {
      final token = await _messaging.getToken();
      if (token == null || token.isEmpty) return;
      await _registerToken(memberId: memberId, role: role, token: token);
    } catch (e) {
      debugPrint('❌ [Push] getToken error: $e');
    }
  }

  Future<void> _registerToken({
    required String memberId,
    required String role,
    required String token,
  }) async {
    final platform = Platform.isIOS ? 'ios' : 'android';
    final registrationKey = '$memberId|${role.toLowerCase()}|$platform|$token';
    try {
      final prefs = await SharedPreferences.getInstance();
      const prefsKey = 'last_registered_fcm_token';
      if (prefs.getString(prefsKey) == registrationKey) {
        debugPrint(
          '[Push] token already registered for $memberId ($role/$platform)',
        );
        return;
      }

      await _repo.registerDeviceToken(
        memberId: memberId,
        role: role,
        platform: platform,
        token: token,
      );
      await prefs.setString(prefsKey, registrationKey);
      debugPrint('[Push] token registered for $memberId ($role/$platform)');
    } catch (e) {
      debugPrint('❌ [Push] token register failed: $e');
    }
  }

  void _handleNotificationTap(
    RemoteMessage message,
    GlobalKey<NavigatorState> navigatorKey,
  ) {
    final screen = message.data['screen']?.toString();
    final type = message.data['type']?.toString();

    debugPrint('[Push] tapped. screen=$screen type=$type data=${message.data}');

    if (_isWaveMessage(message.data)) {
      _openUserHome(navigatorKey);
      return;
    }

    final chatData = _extractChatData(message);
    if (chatData != null) {
      NotificationService.navigateToChatData(chatData);
    }
  }

  void _openUserHome(GlobalKey<NavigatorState> navigatorKey) {
    final nav = navigatorKey.currentState;
    if (nav == null) return;
    nav.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const MainBottomBar(index: 0)),
      (route) => false,
    );
  }

  Map<String, dynamic>? _extractChatData(RemoteMessage message) {
    if (_isWaveMessage(message.data)) return null;

    final merged = <String, dynamic>{};
    merged.addAll(message.data);

    final notification = message.notification;
    if (notification?.title != null) {
      merged.putIfAbsent('name', () => notification!.title);
      merged.putIfAbsent('title', () => notification!.title);
    }

    _mergeJsonPayload(merged, message.data['payload']);
    _mergeJsonPayload(merged, message.data['data']);
    _mergeJsonPayload(merged, merged['sender']);
    _mergeJsonPayload(merged, merged['message']);
    _mergeJsonPayload(merged, merged['conversation']);

    final senderId = _stringValue(merged, [
      'senderUserID',
      'senderMemberID',
      'senderId',
      'sender_id',
      'senderUserId',
      'staffMemberID',
      'userMemberID',
      'userID',
      'userId',
      'fromUserID',
      'from',
      'id',
    ]);
    final conversationId = _stringValue(merged, [
      'conversationID',
      'conversationId',
      'conversation_id',
    ]);

    final screen = _stringValue(merged, ['screen', 'type']).toLowerCase();
    final looksLikeChat =
        senderId.isNotEmpty ||
        conversationId.isNotEmpty ||
        screen == 'chat' ||
        screen == 'message' ||
        screen == 'messages';

    if (!looksLikeChat) return null;

    if (senderId.isNotEmpty) {
      merged['id'] = senderId;
    }

    merged.putIfAbsent('typeIndex', () => 0);
    merged['isStaff'] =
        _currentRole == 'staff' ||
        _stringValue(merged, ['role', 'receiverRole']).toLowerCase() == 'staff';

    return merged;
  }

  void _mergeJsonPayload(Map<String, dynamic> target, Object? rawPayload) {
    if (rawPayload == null) return;

    try {
      if (rawPayload is String) {
        final trimmed = rawPayload.trim();
        if (!trimmed.startsWith('{') && !trimmed.startsWith('[')) return;
      }

      final decoded = rawPayload is String
          ? jsonDecode(rawPayload)
          : rawPayload;
      if (decoded is Map) {
        decoded.forEach((key, value) {
          if (key != null) target.putIfAbsent(key.toString(), () => value);
        });
        _mergeJsonPayload(target, decoded['payload']);
      }
    } catch (e) {
      debugPrint('⚠️ [Push] payload parse failed: $e');
    }
  }

  String _stringValue(Map<String, dynamic> data, List<String> keys) {
    for (final key in keys) {
      final value = data[key];
      if (value != null && value.toString().trim().isNotEmpty) {
        return value.toString().trim();
      }
    }
    return '';
  }
}
