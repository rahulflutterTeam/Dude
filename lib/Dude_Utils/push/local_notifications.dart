import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

typedef LocalNotificationTapHandler =
    Future<void> Function(Map<String, dynamic> payload);

class LocalNotifications {
  LocalNotifications._();
  static final LocalNotifications instance = LocalNotifications._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;
  LocalNotificationTapHandler? _tapHandler;
  String? _pendingTapPayload;
  final Map<String, DateTime> _recentNotifications = {};
  static const Duration _duplicateWindow = Duration(minutes: 2);

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true; // Set early to prevent re-entry

    const android = AndroidInitializationSettings('ic_stat_notify');
    const ios = DarwinInitializationSettings();
    const settings = InitializationSettings(android: android, iOS: ios);

    await _plugin.initialize(
      settings,
      onDidReceiveNotificationResponse: _handleNotificationResponse,
    );
    final launchDetails = await _plugin.getNotificationAppLaunchDetails();
    if (launchDetails?.didNotificationLaunchApp == true) {
      _pendingTapPayload = launchDetails?.notificationResponse?.payload;
    }

    if (Platform.isAndroid) {
      final androidImpl = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();

      // ── DO NOT delete channels on every init — this resets custom sounds ──
      // Only create them if they don't exist yet (Android handles idempotency)

      // ── Promo channel (default system sound) ──────────────────────────────
      const promoChannel = AndroidNotificationChannel(
        'promo_channel',
        'Promotions',
        description: 'Promotional and announcement notifications',
        importance: Importance.high,
        playSound: true,
        // No custom sound → system default
      );

      // ── Chat channel with message_tone ────────────────────────────────────
      // REQUIRED FILE: android/app/src/main/res/raw/message_tone.mp3
      const chatChannel = AndroidNotificationChannel(
        'chat_messages',
        'Chat Messages',
        description: 'Incoming chat message notifications',
        importance: Importance.high,
        playSound: true,
        sound: RawResourceAndroidNotificationSound('message_tone'),
      );

      // ── Wave channel (staff → online user) ────────────────────────────────
      const waveChannel = AndroidNotificationChannel(
        'wave_channel',
        'Waves',
        description: 'Staff wave notifications while you are online',
        importance: Importance.high,
        playSound: true,
      );

      await androidImpl?.createNotificationChannel(promoChannel);
      await androidImpl?.createNotificationChannel(chatChannel);
      await androidImpl?.createNotificationChannel(waveChannel);
    }
  }

  void configureTapHandler(LocalNotificationTapHandler handler) {
    _tapHandler = handler;
    final pending = _pendingTapPayload;
    _pendingTapPayload = null;
    if (pending != null) _dispatchTapPayload(pending);
  }

  void _handleNotificationResponse(NotificationResponse response) {
    final payload = response.payload;
    if (payload == null || payload.isEmpty) return;
    if (_tapHandler == null) {
      _pendingTapPayload = payload;
      return;
    }
    _dispatchTapPayload(payload);
  }

  void _dispatchTapPayload(String payload) {
    try {
      final decoded = jsonDecode(payload);
      if (decoded is Map) {
        _tapHandler?.call(Map<String, dynamic>.from(decoded));
      }
    } catch (e) {
      debugPrint('Invalid local notification payload: $e');
    }
  }

  // ── Chat message — uses message_tone.mp3 ──────────────────────────────────
  Future<void> showChatMessage({
    required String title,
    required String body,
    String? payload,
    String? messageId,
  }) async {
    await init();
    try {
      final notificationId = _notificationId(
        channel: 'chat_messages',
        title: title,
        body: body,
        messageId: messageId,
      );
      if (_isDuplicate(notificationId, contentKey: 'chat|$title|$body')) {
        return;
      }

      final androidDetails = AndroidNotificationDetails(
        'chat_messages',
        'Chat Messages',
        channelDescription: 'Incoming chat message notifications',
        importance: Importance.high,
        priority: Priority.high,
        playSound: true,
        sound: const RawResourceAndroidNotificationSound('message_tone'),
        icon: 'ic_stat_notify',
        largeIcon: const DrawableResourceAndroidBitmap('ic_promo_notify'),
        color: const Color(0xFFF2608C),
        // Same sender+body replaces instead of stacking duplicates.
        tag: 'chat_${_stableTag(title, body)}',
      );

      const iosDetails = DarwinNotificationDetails(
        sound: 'message_tone.aiff',
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      final details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _plugin.show(
        notificationId,
        title,
        body,
        details,
        payload: payload,
      );
    } catch (e) {
      debugPrint('❌ [LocalNotifications] showChatMessage error: $e');
    }
  }

  // ── Promo / general — uses default system sound ───────────────────────────
  Future<void> showPromo({
    required String title,
    required String body,
    String? payload,
    String? messageId,
  }) async {
    await init();
    try {
      final notificationId = _notificationId(
        channel: 'promo_channel',
        title: title,
        body: body,
        messageId: messageId,
      );
      if (_isDuplicate(notificationId, contentKey: 'promo|$title|$body')) {
        return;
      }

      final androidDetails = AndroidNotificationDetails(
        'promo_channel',
        'Promotions',
        channelDescription: 'Promotional and announcement notifications',
        importance: Importance.high,
        priority: Priority.high,
        playSound: true,
        icon: 'ic_stat_notify',
        largeIcon: const DrawableResourceAndroidBitmap('ic_promo_notify'),
        color: const Color(0xFFF2608C),
        tag: 'promo_${_stableTag(title, body)}',
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      final details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _plugin.show(
        notificationId,
        title,
        body,
        details,
        payload: payload,
      );
    } catch (e) {
      debugPrint('❌ [LocalNotifications] showPromo error: $e');
    }
  }

  /// Staff wave while user is online — socket delivery only (no FCM).
  Future<void> showWave({
    required String title,
    required String body,
    String? payload,
  }) async {
    await init();
    try {
      // Unique id each time so repeated waves always show.
      final notificationId =
          DateTime.now().millisecondsSinceEpoch.remainder(0x7fffffff);

      const androidDetails = AndroidNotificationDetails(
        'wave_channel',
        'Waves',
        channelDescription: 'Staff wave notifications while you are online',
        importance: Importance.high,
        priority: Priority.high,
        playSound: true,
        icon: 'ic_stat_notify',
        largeIcon: DrawableResourceAndroidBitmap('ic_promo_notify'),
        color: Color(0xFFF2608C),
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _plugin.show(
        notificationId,
        title,
        body,
        details,
        payload: payload,
      );
    } catch (e) {
      debugPrint('❌ [LocalNotifications] showWave error: $e');
    }
  }

  int _notificationId({
    required String channel,
    required String title,
    required String body,
    String? messageId,
  }) {
    // Prefer FCM messageId so the same push always maps to one local id.
    if (messageId != null && messageId.trim().isNotEmpty) {
      return Object.hash(channel, messageId.trim()) & 0x7fffffff;
    }
    // Ignore payload — it used to create different ids for the same message.
    return Object.hash(channel, title.trim(), body.trim()) & 0x7fffffff;
  }

  String _stableTag(String title, String body) {
    return (Object.hash(title.trim(), body.trim()) & 0x7fffffff).toString();
  }

  bool _isDuplicate(int notificationId, {String? contentKey}) {
    final now = DateTime.now();
    _recentNotifications.removeWhere(
      (_, shownAt) => now.difference(shownAt) > _duplicateWindow,
    );

    final keys = <String>[
      notificationId.toString(),
      if (contentKey != null && contentKey.trim().isNotEmpty)
        contentKey.trim().toLowerCase(),
    ];

    for (final key in keys) {
      final previous = _recentNotifications[key];
      if (previous != null && now.difference(previous) <= _duplicateWindow) {
        debugPrint('[LocalNotifications] duplicate notification suppressed');
        return true;
      }
    }

    for (final key in keys) {
      _recentNotifications[key] = now;
    }
    return false;
  }
}
