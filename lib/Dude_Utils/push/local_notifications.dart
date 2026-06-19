import 'dart:io';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class LocalNotifications {
  LocalNotifications._();
  static final LocalNotifications instance = LocalNotifications._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;
  final Map<String, DateTime> _recentNotifications = {};
  static const Duration _duplicateWindow = Duration(minutes: 2);

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true; // Set early to prevent re-entry

    const android = AndroidInitializationSettings('ic_promo_notify');
    const ios = DarwinInitializationSettings();
    const settings = InitializationSettings(android: android, iOS: ios);

    await _plugin.initialize(settings);

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

      await androidImpl?.createNotificationChannel(promoChannel);
      await androidImpl?.createNotificationChannel(chatChannel);
    }
  }

  // ── Chat message — uses message_tone.mp3 ──────────────────────────────────
  Future<void> showChatMessage({
    required String title,
    required String body,
    String? payload,
  }) async {
    await init();
    try {
      final notificationId = _notificationId(
        channel: 'chat_messages',
        title: title,
        body: body,
        payload: payload,
      );
      if (_isDuplicate(notificationId)) return;

      const androidDetails = AndroidNotificationDetails(
        'chat_messages',
        'Chat Messages',
        channelDescription: 'Incoming chat message notifications',
        importance: Importance.high,
        priority: Priority.high,
        playSound: true,
        sound: RawResourceAndroidNotificationSound('message_tone'),
        icon: 'ic_stat_notify',
        largeIcon: DrawableResourceAndroidBitmap('ic_promo_notify'),
        color: Color(0xFFCC529F),
      );

      const iosDetails = DarwinNotificationDetails(
        sound: 'message_tone.aiff',
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
      debugPrint('❌ [LocalNotifications] showChatMessage error: $e');
    }
  }

  // ── Promo / general — uses default system sound ───────────────────────────
  Future<void> showPromo({
    required String title,
    required String body,
    String? payload,
  }) async {
    await init();
    try {
      final notificationId = _notificationId(
        channel: 'promo_channel',
        title: title,
        body: body,
        payload: payload,
      );
      if (_isDuplicate(notificationId)) return;

      const androidDetails = AndroidNotificationDetails(
        'promo_channel',
        'Promotions',
        channelDescription: 'Promotional and announcement notifications',
        importance: Importance.high,
        priority: Priority.high,
        playSound: true,
        icon: 'ic_stat_notify',
        largeIcon: DrawableResourceAndroidBitmap('ic_promo_notify'),
        color: Color(0xFFCC529F),
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
      debugPrint('❌ [LocalNotifications] showPromo error: $e');
    }
  }

  int _notificationId({
    required String channel,
    required String title,
    required String body,
    String? payload,
  }) {
    return Object.hash(channel, title.trim(), body.trim(), payload ?? '') &
        0x7fffffff;
  }

  bool _isDuplicate(int notificationId) {
    final key = notificationId.toString();
    final now = DateTime.now();
    _recentNotifications.removeWhere(
      (_, shownAt) => now.difference(shownAt) > _duplicateWindow,
    );

    final previous = _recentNotifications[key];
    if (previous != null && now.difference(previous) <= _duplicateWindow) {
      debugPrint('[LocalNotifications] duplicate notification suppressed');
      return true;
    }

    _recentNotifications[key] = now;
    return false;
  }
}
