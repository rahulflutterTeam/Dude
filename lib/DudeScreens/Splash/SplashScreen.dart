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
import 'package:dude/Dude_Utils/App_Theme/DudeTheme.dart';
import 'package:dude/Reusable_Widgets/Premium_UI/dude_logo_spin.dart';
import 'package:dude/Reusable_Widgets/Premium_UI/premium_ambient_background.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class Splashscreen extends StatefulWidget {
  const Splashscreen({super.key});

  @override
  State<Splashscreen> createState() => _SplashscreenState();
}

class _SplashscreenState extends State<Splashscreen> {
  bool _isOffline = false;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  @override
  void initState() {
    super.initState();
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
    _connectivitySubscription?.cancel();
    super.dispose();
  }

  Future<bool> _hasInternetConnection() async {
    try {
      final result = await InternetAddress.lookup(
        'google.com',
      ).timeout(const Duration(seconds: 4));
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException catch (_) {
      return false;
    } on TimeoutException catch (_) {
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<void> _checkLoginAndStatus() async {
    // Let the one-time logo spin finish before navigating.
    await Future.delayed(const Duration(milliseconds: 2200));

    if (!mounted) return;

    try {
      // === NETWORK CHECK ===
      final connectivityResult = await Connectivity()
          .checkConnectivity()
          .timeout(const Duration(seconds: 4));
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
      ).timeout(const Duration(seconds: 8), onTimeout: () => false);
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

      // Never hang forever on splash if profile APIs are slow/offline.
      await Future.wait([
        userVM.fetchUserDetails(),
        staffVM.fetchStaffSingleData(),
      ]).timeout(const Duration(seconds: 15));

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
    } catch (e, stack) {
      debugPrint('❌ [Splash] startup failed: $e');
      debugPrint('$stack');
      if (!mounted) return;
      // Fail open to login/welcome so users are never stuck on the logo.
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const SplashScreen2()),
      );
    }
  }

  Future<void> _retryConnection() async {
    setState(() => _isOffline = false);
    _checkLoginAndStatus();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DudeTheme.background,
      body: PremiumAmbientBackground(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const DudeLogoSpin(height: 140),
                const SizedBox(height: 48),
                if (_isOffline) ...[
                  const Icon(Icons.wifi_off, size: 52, color: Colors.white70),
                  const SizedBox(height: 16),
                  const Text(
                    'No Internet Connection',
                    style: TextStyle(
                      color: DudeTheme.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Please turn on WiFi or Mobile Data\nto continue',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: DudeTheme.textMuted, fontSize: 14),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: _retryConnection,
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Retry'),
                    style: DudeTheme.primaryButtonStyle(),
                  ),
                ] else
                  const SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(
                      color: DudeTheme.accent,
                      strokeWidth: 2.4,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
