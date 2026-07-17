import 'dart:convert';
import 'dart:async';

import 'package:dude/APIService/Remote/network/NetworkApiService.dart';
import 'package:dude/DudeScreens/HomeScreen/Repo/UserDataRepo.dart';
import 'package:dude/DudeScreens/HomeScreen/ViewModel/UserVM.dart';
import 'package:dude/DudeScreens/HomeScreen/zego_lifecycle.dart';
import 'package:dude/DudeScreens/LoginScreens/Repository/LoginRepo.dart';
import 'package:dude/DudeScreens/LoginScreens/ViewModel/LoginVM.dart';
import 'package:dude/DudeScreens/LoginScreens/ViewModel/ReferralVM.dart';
import 'package:dude/DudeScreens/Splash/SplashScreen.dart';
import 'package:dude/DudeScreens/Transactions/TransactionScreen.dart';
import 'package:dude/DudeScreens/WalletScreen/AdBannerVM/AdBannerVM.dart';
import 'package:dude/DudeScreens/WalletScreen/phonepe.dart';
import 'package:dude/Dude_Utils/push/local_notifications.dart';
import 'package:dude/Dude_Utils/push/push_service.dart';
import 'package:dude/StaffScreenScreens/StaffRegistrationScreen/Repo/StaffRegisterRepo.dart';
import 'package:dude/StaffScreenScreens/StaffRegistrationScreen/ViewModel/StaffRegisterVM.dart';
import 'package:dude/StaffScreenScreens/StaffBottomNavBar/StaffBottomNavBar.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:facebook_app_events/facebook_app_events.dart';
import 'package:dude/firebase_options.dart';
import 'package:dude/Dude_Utils/App_Theme/DudeTheme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:zego_uikit_prebuilt_call/zego_uikit_prebuilt_call.dart';
import 'DudeScreens/Transactions/ViewModel/TransactionHistoryVM.dart';
import 'DudeScreens/WalletScreen/razorPayFlow/Repository/PaymentRepo.dart';
import 'DudeScreens/WalletScreen/razorPayFlow/ViewModel/PaymentVM.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';
import 'package:flutter_callkit_incoming/entities/entities.dart';
import 'package:screen_brightness/screen_brightness.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

// ─────────────────────────────────────────────────────────────────────────────
// BACKGROUND FCM HANDLER
// Only shows CallKit UI — nothing else runs in killed state
// ─────────────────────────────────────────────────────────────────────────────
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  final data = message.data;
  if (!_isZegoCallInvitation(data)) return;

  String callId = data['call_id'] ?? data['callID'] ?? '';
  String callerName = data['caller_name'] ?? 'Incoming Call';
  String callerId = data['caller_id'] ?? '';
  bool isVideo = data['call_type'] == '1';

  if (callId.isEmpty) {
    try {
      final payload = data['payload'];
      if (payload != null) {
        final json = jsonDecode(payload) as Map<String, dynamic>;
        callId =
            json['call_id'] ?? json['callID'] ?? json['invitationID'] ?? '';
        final caller = json['caller'] as Map<String, dynamic>?;
        if (caller != null) {
          callerName = caller['name'] ?? callerName;
          callerId = caller['id'] ?? callerId;
        } else {
          callerName = json['caller_name'] ?? callerName;
          callerId = json['caller_id'] ?? callerId;
        }
        isVideo = json['call_type'] == '1' || json['call_type'] == 'video';
      }
    } catch (_) {}
  }

  if (callId.isEmpty) return;
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  final n = message.notification;

  final title = n?.title ?? data['title']?.toString();
  final body = n?.body ?? data['body']?.toString();

  // Skip if no content to show
  if (title == null || body == null) return;

  // Skip Zego call invitations — CallKit / Zego handles those
  if (_isZegoCallInvitation(data)) return;

  // Initialize local notification channels
  await LocalNotifications.instance.init();

  // Route to correct channel based on message type
  if (_isChatMessageData(data)) {
    await LocalNotifications.instance.showChatMessage(title: title, body: body);
  } else {
    await LocalNotifications.instance.showPromo(title: title, body: body);
  }
  // await FlutterCallkitIncoming.showCallkitIncoming(CallKitParams(
  //   id: callId,
  //   nameCaller: callerName,
  //   appName: 'Dude',
  //   handle: callerId,
  //   type: isVideo ? 1 : 0,
  //   textAccept: 'Accept',
  //   textDecline: 'Decline',
  //   duration: 60000,
  //   extra: <String, dynamic>{
  //     'callId': callId,
  //     'callerName': callerName,
  //     'callerId': callerId,
  //     'isVideo': isVideo,
  //   },
  //   missedCallNotification: const NotificationParams(
  //     showNotification: true,
  //     isShowCallback: false,
  //     subtitle: 'Missed call',
  //   ),
  //   android: const AndroidParams(
  //     isCustomNotification: true,
  //     isShowFullLockedScreen: true,
  //     isShowLogo: false,
  //     ringtonePath: 'system_ringtone_default',
  //     backgroundColor: '#1A1A2E',
  //     actionColor: '#CC529F',
  //     textColor: '#FFFFFF',
  //     incomingCallNotificationChannelName: 'Incoming Callsde',
  //     missedCallNotificationChannelName: 'Missed Calls',
  //   ),
  //   ios: const IOSParams(
  //     iconName: 'CallKitLogo',
  //     handleType: 'generic',
  //     supportsVideo: false,
  //     maximumCallGroups: 1,
  //     maximumCallsPerCallGroup: 1,
  //   ),
  // ));
}

bool _isChatMessageData(Map<String, dynamic> data) {
  final screen = data['screen']?.toString().toLowerCase() ?? '';
  if (screen == 'chat' || screen == 'message' || screen == 'messages') {
    return true;
  }
  const chatKeys = [
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

bool _isZegoCallInvitation(Map<String, dynamic> data) {
  if (data.containsKey('call_id') || data.containsKey('callID')) return true;
  final payload = data['payload'];
  if (payload == null) return false;
  try {
    final json = jsonDecode(payload.toString()) as Map<String, dynamic>;
    return json.containsKey('call_id') ||
        json.containsKey('callID') ||
        json.containsKey('invitationID');
  } catch (_) {
    return false;
  }
}

// bool _isZegoCallInvitation(Map<String, dynamic> data) {
//   if (data.containsKey('call_id') || data.containsKey('callID')) return true;
//   final payload = data['payload'];
//   if (payload == null) return false;
//   try {
//     final json = jsonDecode(payload.toString()) as Map<String, dynamic>;
//     return json.containsKey('call_id') ||
//         json.containsKey('callID') ||
//         json.containsKey('invitationID');
//   } catch (_) {
//     return false;
//   }
// }

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light, // ← white icons on Android
      statusBarBrightness: Brightness.dark, // ← white icons on iOS
    ),
  );

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await PushService.instance.captureInitialMessage();

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // CRITICAL: Set navigator key BEFORE runApp
  ZegoUIKitPrebuiltCallInvitationService().setNavigatorKey(navigatorKey);

  // CRITICAL (killed-state calls): ZEGO requires the offline-call handler to be
  // registered via useSystemCallingUI() in main() and AWAITED *before* runApp().
  // Let Zego native signaling finish on the platform thread before the first
  // frame builds a heavy theme (google_fonts) on iOS.
  await ZegoLifecycle.ensureSystemCallingUIConfigured();
  await Future<void>.delayed(const Duration(milliseconds: 50));

  runApp(const MyApp());

  WidgetsBinding.instance.addPostFrameCallback((_) {
    unawaited(FacebookAppEvents().activateApp());
    unawaited(_resetScreenBrightnessAfterFirstFrame());
  });
}

Future<void> _resetScreenBrightnessAfterFirstFrame() async {
  try {
    await ScreenBrightness().resetScreenBrightness();
  } catch (e) {
    debugPrint("Failed to reset screen brightness: $e");
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ...getAllProviders(), // Your custom provider list
      ],
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
        ),
        child: MaterialApp(
          navigatorKey: navigatorKey,
          title: 'Dude',
          debugShowCheckedModeBanner: false,
          theme: DudeTheme.appTheme,
          builder: (context, child) {
            final base =
                Theme.of(context).textTheme.bodyMedium ??
                const TextStyle(fontSize: 14);
            return DefaultTextStyle(
              style: base.copyWith(
                fontFamily: DudeTheme.fontFamily,
                color: DudeTheme.textPrimary,
              ),
              child: child ?? const SizedBox.shrink(),
            );
          },
          home: const _InitialLaunchGate(),
        ),
      ),
    );
  }
}

class _InitialLaunchGate extends StatefulWidget {
  const _InitialLaunchGate();

  @override
  State<_InitialLaunchGate> createState() => _InitialLaunchGateState();
}

class _InitialLaunchGateState extends State<_InitialLaunchGate> {
  static const _channel = MethodChannel('com.dude.dudeapp/window');
  Widget? _destination;

  @override
  void initState() {
    super.initState();
    _resolve();
  }

  Future<void> _resolve() async {
    var accepted = false;
    try {
      accepted =
          await _channel.invokeMethod<bool>('hasAcceptedCallData') ?? false;
    } catch (e) {
      debugPrint('Accepted-call startup check failed: $e');
    }
    if (!mounted) return;
    setState(() {
      _destination = accepted
          ? const StaffBottomBar(index: 0, launchingAcceptedCall: true)
          : const Splashscreen();
    });
  }

  @override
  Widget build(BuildContext context) =>
      _destination ?? const Scaffold(backgroundColor: Colors.black);
}

List getAllProviders() {
  return [
    Provider<AuthRepository>(create: (_) => AuthRepository()),
    ChangeNotifierProvider<LoginViewModel>(
      create: (context) => LoginViewModel(context.read<AuthRepository>()),
    ),
    ChangeNotifierProvider(create: (_) => WalletViewModel(WalletRepository())),
    ChangeNotifierProvider(
      create: (_) => DepositHistoryViewModel(WalletRepository()),
      child: TransactionsScreen(backPage: true),
    ),
    Provider<UserRepository>(
      create: (context) => UserRepository(NetworkApiService()),
    ),
    ChangeNotifierProvider<UserViewModel>(
      create: (context) => UserViewModel(context.read<UserRepository>()),
      lazy: true,
    ),
    Provider<StaffRepository>(
      create: (context) => StaffRepository(NetworkApiService()),
    ),
    ChangeNotifierProvider<StaffViewModel>(
      create: (context) => StaffViewModel(context.read<StaffRepository>()),
    ),

    ChangeNotifierProvider(
      create: (_) => AdBannerViewModel(UserRepository(NetworkApiService())),
    ),

    ChangeNotifierProvider(create: (_) => ReferralViewModel(AuthRepository())),
  ];
}
