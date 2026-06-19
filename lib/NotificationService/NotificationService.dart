// lib/NotificationService/NotificationService.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:provider/provider.dart';
import 'package:dude/main.dart' show navigatorKey;
import 'package:dude/DudeScreens/Chat/ChatDetailScreen.dart';
import 'package:dude/StaffScreenScreens/StaffRegistrationScreen/ViewModel/StaffRegisterVM.dart';
import 'package:dude/StaffScreenScreens/staffChat/staffChatDetailScreen.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;
  bool isStaffMode = false;
  String? currentUserId;

  final Map<String, String> _nameCache = {};

  /// Call this from ChatListScreen / StaffChatListScreen when you know a
  /// mapping between userID and display name.
  void registerName(String userId, String name) {
    if (userId.isNotEmpty && name.isNotEmpty) {
      _nameCache[userId] = name;
    }
  }

  // ──────────────────────────────────────────────────────────────
  // INIT
  // ──────────────────────────────────────────────────────────────
  Future<void> init({required bool staffMode, required String userId}) async {
    isStaffMode = staffMode;
    currentUserId = userId;

    if (_isInitialized) return;

    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );

    await _plugin.initialize(
      const InitializationSettings(android: androidSettings, iOS: iosSettings),
      onDidReceiveNotificationResponse: _onNotificationTapped,
      onDidReceiveBackgroundNotificationResponse:
          onNotificationTappedBackground,
    );

    final AndroidFlutterLocalNotificationsPlugin? androidImpl = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await androidImpl?.requestNotificationsPermission();

    _isInitialized = true;
    debugPrint('✅ NotificationService initialized (staffMode: $staffMode)');
  }

  void stopListening() {
    _isInitialized = false;
  }

  // ──────────────────────────────────────────────────────────────
  // SHOW LOCAL NOTIFICATION
  // ──────────────────────────────────────────────────────────────
  Future<void> _showNotification({
    required String conversationID,
    required int conversationTypeIndex,
    required String senderName,
    required String messageText,
  }) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'Chat_Message',
          'Messages',
          channelDescription: 'Chat message notifications',
          importance: Importance.high,
          priority: Priority.high,
          playSound: true,
          enableVibration: true,
        );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final payload = jsonEncode({
      'id': conversationID,
      'typeIndex': conversationTypeIndex,
      'isStaff': isStaffMode,
      'name': senderName, // pass name into payload for navigation title
    });

    await _plugin.show(
      conversationID.hashCode,
      senderName, // ← notification title = real name
      messageText,
      const NotificationDetails(android: androidDetails, iOS: iosDetails),
      payload: payload,
    );

    debugPrint('🔔 Notification: "$senderName" → "$messageText"');
  }

  // ──────────────────────────────────────────────────────────────
  // TAP HANDLERS
  // ──────────────────────────────────────────────────────────────
  void _onNotificationTapped(NotificationResponse response) {
    _navigateToChat(response.payload);
  }

  static void onNotificationTappedBackground(NotificationResponse response) {
    _navigateToChat(response.payload);
  }

  static void _navigateToChat(String? payload) {
    if (payload == null) return;
    try {
      navigateToChatData(Map<String, dynamic>.from(jsonDecode(payload)));
    } catch (e) {
      debugPrint('❌ Notification nav error: $e');
    }
  }

  static Future<void> navigateToChatData(Map<String, dynamic> data) async {
    try {
      final String id = _stringValue(data, [
        'id',
        'conversationID',
        'conversationId',
        'conversation_id',
        'senderUserID',
        'senderId',
        'sender_id',
        'fromUserID',
        'from',
      ]);
      if (id.isEmpty) return;

      final bool isStaff =
          data['isStaff'] == true ||
          _stringValue(data, ['role', 'receiverRole']).toLowerCase() == 'staff';
      final String name =
          _stringValue(data, ['name', 'senderName', 'title']).isNotEmpty
          ? _stringValue(data, ['name', 'senderName', 'title'])
          : id;
      await _waitForNavigator();
      final navigator = navigatorKey.currentState;
      final context = navigatorKey.currentContext;
      if (navigator == null || context == null) return;

      String staffId = _stringValue(data, ['staffId', 'staff_id']);
      if (!isStaff && staffId.isEmpty) {
        try {
          // ignore: use_build_context_synchronously
          final staffVM = context.read<StaffViewModel>();
          if (staffVM.staffList.isEmpty) {
            await staffVM.fetchStaffDetails();
          }
          staffId = staffVM.getStaffIdByMemberId(id) ?? id;
        } catch (e) {
          debugPrint('⚠️ Could not resolve staff id for notification: $e');
          staffId = id;
        }
      }

      navigator.push(
        MaterialPageRoute(
          builder: (context) => isStaff
              ? staffChatDetailScreen(
                  conversationID: id,
                  peerMemberID: id,
                  name: name,
                )
              : ChatDetailScreen(
                  conversationID: id,
                  peerMemberID: id,
                  name: name,
                  staffId: staffId,
                ),
        ),
      );
    } catch (e) {
      debugPrint('❌ Notification chat navigation error: $e');
    }
  }

  static String _stringValue(Map<String, dynamic> data, List<String> keys) {
    for (final key in keys) {
      final value = data[key];
      if (value != null && value.toString().trim().isNotEmpty) {
        return value.toString().trim();
      }
    }
    return '';
  }

  static Future<void> _waitForNavigator() async {
    var waited = 0;
    while (navigatorKey.currentState == null && waited < 5000) {
      await Future.delayed(const Duration(milliseconds: 100));
      waited += 100;
    }
  }
}
