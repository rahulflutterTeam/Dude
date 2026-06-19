import 'dart:async';
import 'dart:io';

import 'package:dude/DudeScreens/AuthService.dart';
import 'package:dude/DudeScreens/BottomNavBar/BottomNavBar.dart';
import 'package:dude/DudeScreens/HomeScreen/AppUpdateService.dart';
import 'package:dude/DudeScreens/HomeScreen/ViewModel/UserVM.dart';
import 'package:dude/DudeScreens/LoginScreens/IdentityScreen/IdentityScreen.dart';
import 'package:dude/DudeScreens/LoginScreens/InterestLanguage/InterestedLanguage.dart';
import 'package:dude/DudeScreens/Splash/SplashScreen2.dart';
import 'package:dude/StaffScreenScreens/LiveSeflieVerificationScreen/LiveVerificationScreen.dart';
import 'package:dude/StaffScreenScreens/ProfileVerficationScreen/ProfileVerficationScreen.dart';
import 'package:dude/StaffScreenScreens/StaffBottomNavBar/StaffBottomNavBar.dart';
import 'package:dude/StaffScreenScreens/StaffRegistrationScreen/StaffRegistrationScreens.dart';
import 'package:dude/StaffScreenScreens/StaffRegistrationScreen/ViewModel/StaffRegisterVM.dart';
import 'package:dude/StaffScreenScreens/VerificationApprovedScreen/VerificationApprovedScreen.dart';
import 'package:dude/StaffScreenScreens/VerificationInprogressScreen/VerificationInprogressScreen.dart';
import 'package:dude/StaffScreenScreens/VerificationUnsuccessfulScreen/VerificationUnsuccessScreen.dart';
import 'package:dude/Dude_Utils/push/push_service.dart';
import 'package:dude/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class Splashscreen extends StatefulWidget {
  const Splashscreen({super.key});

  @override
  State<Splashscreen> createState() => _SplashscreenState();
}

class _SplashscreenState extends State<Splashscreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  bool _isOffline = false;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(
      begin: 0.95,
      end: 1.05,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _checkLoginAndStatus();
    _startConnectivityListener();
  }

  void _startConnectivityListener() {
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((
      results,
    ) async {
      if (_isOffline && results.any((r) => r != ConnectivityResult.none)) {
        // Check actual internet
        final hasInternet = await _hasInternetConnection();
        if (hasInternet && mounted) {
          setState(() => _isOffline = false);
          _checkLoginAndStatus(); // Retry navigation
        }
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _connectivitySubscription?.cancel();
    super.dispose();
  }

  Future<bool> _hasInternetConnection() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException catch (_) {
      return false;
    }
  }

  Future<void> _checkLoginAndStatus() async {
    // Show splash for branding
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    // === NETWORK CHECK ===
    final connectivityResult = await Connectivity().checkConnectivity();
    final hasInternet = await _hasInternetConnection();
    if (!mounted) return;

    if (connectivityResult.contains(ConnectivityResult.none) || !hasInternet) {
      if (mounted) {
        setState(() => _isOffline = true);
      }
      return; // Stay on splash screen
    }

    final shouldBlockApp = await AppUpdateService.checkForUpdate(
      context,
      showOptionalUpdate: false,
    );
    if (!mounted || shouldBlockApp) return;

    // === ONLINE → Proceed with normal flow ===
    final isLoggedIn = await AuthService.isLoggedIn();
    if (!mounted) return;

    if (!isLoggedIn) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const SplashScreen2()),
      );
      return;
    }

    final userVM = Provider.of<UserViewModel>(context, listen: false);
    final staffVM = Provider.of<StaffViewModel>(context, listen: false);

    await Future.wait([
      userVM.fetchUserDetails(),
      staffVM.fetchStaffSingleData(),
    ]);

    if (!mounted) return;

    final user = userVM.currentUser;
    final staff = staffVM.currentStaff;

    if (user == null && staff == null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const SplashScreen2()),
      );
      return;
    }

    String? role;
    String? formStatusStr;
    String? formStatusStr1;
    String? memberId;

    if (staff != null) {
      role = staff.role.toLowerCase();
      formStatusStr = staff.formStatus;
      memberId = staff.memberID;
    } else if (user != null) {
      role = user.role.toLowerCase();
      formStatusStr1 = user.formStatus;
      memberId = user.memberID;
    }

    // Push notification setup
    if (memberId != null && role != null) {
      // ignore: unawaited_futures
      PushService.instance.bootstrapAndRegister(memberId: memberId, role: role);
      PushService.instance.attachMessageOpenHandlers(
        navigatorKey: navigatorKey,
      );
    }

    final status = int.tryParse(formStatusStr ?? '-1') ?? -1;
    final status1 = int.tryParse(formStatusStr1 ?? '0') ?? 0;

    // ────────────────────────────────────────────────
    // STAFF FLOW
    // ────────────────────────────────────────────────
    if (role == 'staff') {
      if (status == -1) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const StaffRegisterScreen()),
        );
      } else if (status == 0) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const ProfileVerficationScreen()),
        );
      } else if (status == 1) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LiveVerificationScreen()),
        );
      } else if (status == 2) {
        final approval = staff!.isApproved?.toLowerCase().trim() ?? 'pending';

        if (approval == '1') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const ApprovedScreen()),
          );
        } else if (approval.contains('2') ||
            approval == 'declined' ||
            approval == 'not approved') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => const VerificationUnsuccessScreen(),
            ),
          );
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => const VerificationInprogressScreen(),
            ),
          );
        }
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const StaffBottomBar()),
        );
      }
    }
    // ────────────────────────────────────────────────
    // USER FLOW
    // ────────────────────────────────────────────────
    else {
      if (status1 == 0 || status1 == 1) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const IdentityScreen()),
        );
      } else if (status1 == 2) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const InterestLanguageScreen()),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const MainBottomBar()),
        );
      }
    }
  }

  Future<void> _retryConnection() async {
    setState(() => _isOffline = false);
    _checkLoginAndStatus();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0E0A14),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF3a1873),
              Color(0xFF0c001d),
              Color(0xFF0c001d),
              Color(0xFF3a1873),
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ScaleTransition(
                scale: _scaleAnimation,
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFe4f773).withOpacity(0.4),
                        blurRadius: 30,
                        spreadRadius: 8,
                      ),
                    ],
                  ),
                  child: SvgPicture.asset(
                    "assets/Images/splashlogo.svg",
                    height: 150,
                  ),
                ),
              ),

              const SizedBox(height: 50),

              if (_isOffline)
                Column(
                  children: [
                    const Icon(Icons.wifi_off, size: 60, color: Colors.white70),
                    const SizedBox(height: 20),
                    const Text(
                      "No Internet Connection",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      "Please turn on WiFi or Mobile Data\nto continue",
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                        height: 1.4,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 30),
                    ElevatedButton.icon(
                      onPressed: _retryConnection,
                      icon: const Icon(Icons.refresh),
                      label: const Text("Retry"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFe4f773),
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 14,
                        ),
                      ),
                    ),
                  ],
                )
              else
                const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFd2ea46)),
                  strokeWidth: 5,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
