import 'dart:convert';
import 'dart:async';

import 'package:dude/APIService/Remote/network/NetworkApiService.dart';
import 'package:dude/DudeScreens/HomeScreen/call_billing_observer.dart';
import 'package:dude/DudeScreens/HomeScreen/Repo/UserDataRepo.dart';
import 'package:dude/DudeScreens/HomeScreen/ViewModel/UserVM.dart';
import 'package:dude/DudeScreens/HomeScreen/zego_lifecycle.dart';
import 'package:dude/DudeScreens/LoginScreens/Repository/LoginRepo.dart';
import 'package:dude/DudeScreens/LoginScreens/ViewModel/LoginVM.dart';
import 'package:dude/DudeScreens/LoginScreens/ViewModel/ReferralVM.dart';
import 'package:dude/DudeScreens/Splash/SplashScreen.dart';
import 'package:dude/DudeScreens/BottomNavBar/BottomNavBar.dart';
import 'package:dude/DudeScreens/Transactions/TransactionScreen.dart';
import 'package:dude/DudeScreens/WalletScreen/AdBannerVM/AdBannerVM.dart';
import 'package:dude/Dude_Utils/push/local_notifications.dart';
import 'package:dude/Dude_Utils/push/push_service.dart';
import 'package:dude/NotificationService/NotificationService.dart';
import 'package:dude/StaffScreenScreens/StaffRegistrationScreen/Repo/StaffRegisterRepo.dart';
import 'package:dude/StaffScreenScreens/StaffRegistrationScreen/ViewModel/StaffRegisterVM.dart';
import 'package:dude/StaffScreenScreens/StaffBottomNavBar/StaffBottomNavBar.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:facebook_app_events/facebook_app_events.dart';
import 'package:dude/firebase_options.dart';
import 'package:dude/Dude_Utils/App_Theme/DudeTheme.dart';
import 'package:dude/Dude_Utils/navigation/route_observer.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:zego_uikit_prebuilt_call/zego_uikit_prebuilt_call.dart';
import 'DudeScreens/Transactions/ViewModel/TransactionHistoryVM.dart';
import 'DudeScreens/WalletScreen/razorPayFlow/Repository/PaymentRepo.dart';
import 'DudeScreens/WalletScreen/razorPayFlow/ViewModel/PaymentVM.dart';
import 'package:screen_brightness/screen_brightness.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

// ─────────────────────────────────────────────────────────────────────────────
// BACKGROUND FCM HANDLER
// Only shows CallKit UI — nothing else runs in killed state
// ─────────────────────────────────────────────────────────────────────────────
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  final data = message.data;
  // Zego/CallKit owns call invitations in the background.
  if (_isZegoCallInvitation(data)) return;

  // Notification+data FCM: Android/iOS already post the system tray entry.
  // Showing another local notification here creates duplicates.
  if (message.notification != null) {
    debugPrint(
      '[Push] background: system notification present — skip local display',
    );
    return;
  }

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  final title = data['title']?.toString();
  final body = data['body']?.toString();
  if (title == null || body == null) return;

  await LocalNotifications.instance.init();

  final payload = jsonEncode({
    ...data,
    if (message.messageId != null) 'messageId': message.messageId,
  });

  if (_isChatMessageData(data)) {
    await LocalNotifications.instance.showChatMessage(
      title: title,
      body: body,
      payload: payload,
      messageId: message.messageId,
    );
  } else {
    await LocalNotifications.instance.showPromo(
      title: title,
      body: body,
      payload: payload,
      messageId: message.messageId,
    );
  }
}

bool _isChatMessageData(Map<String, dynamic> data) {
  final type = data['type']?.toString().toLowerCase() ?? '';
  final screen = data['screen']?.toString().toLowerCase() ?? '';
  if (type == 'wave' || screen == 'wave') return false;
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
  await LocalNotifications.instance.init();
  LocalNotifications.instance.configureTapHandler((payload) async {
    final type = payload['type']?.toString().toLowerCase() ?? '';
    final screen = payload['screen']?.toString().toLowerCase() ?? '';
    if (type == 'wave' || screen == 'wave' || screen == 'home') {
      final nav = navigatorKey.currentState;
      if (nav == null) return;
      nav.pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const MainBottomBar(index: 0)),
        (route) => false,
      );
      return;
    }
    await NotificationService.navigateToChatData(payload);
  });
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
          navigatorObservers: [appRouteObserver],
          title: 'Dude',
          debugShowCheckedModeBanner: false,
          theme: DudeTheme.appTheme,
          builder: (context, child) {
            final base =
                Theme.of(context).textTheme.bodyMedium ??
                const TextStyle(fontSize: 14);
            return CallBillingObserver(
              child: DefaultTextStyle(
                style: base.copyWith(
                  fontFamily: DudeTheme.fontFamily,
                  color: DudeTheme.textPrimary,
                ),
                child: Stack(
                  children: [
                    child ?? const SizedBox.shrink(),
                    ZegoUIKitPrebuiltCallMiniOverlayPage(
                      contextQuery: () =>
                          navigatorKey.currentState?.context ?? context,
                    ),
                  ],
                ),
              ),
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
