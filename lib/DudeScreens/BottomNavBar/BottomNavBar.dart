import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:ui';

import 'package:dude/DudeScreens/Chat/ChatListScreen.dart';
import 'package:dude/DudeScreens/HomeScreen/HomeScreen.dart';
import 'package:dude/DudeScreens/HomeScreen/ViewModel/UserVM.dart';
import 'package:dude/DudeScreens/IncomingCall/FakeIncomingCallScreen.dart';
import 'package:dude/DudeScreens/ProfileScreen/ProfileScreen.dart';
import 'package:dude/DudeScreens/Transactions/TransactionScreen.dart';
import 'package:dude/Dude_Utils/App_Theme/DudeTheme.dart';
import 'package:dude/Reusable_Widgets/Premium_UI/premium_animations.dart';
import 'package:dude/Reusable_Widgets/Premium_UI/premium_nav_icon.dart';
import 'package:dude/StaffScreenScreens/StaffRegistrationScreen/ViewModel/StaffRegisterVM.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:provider/provider.dart';

class MainBottomBar extends StatefulWidget {
  final int? index;

  const MainBottomBar({super.key, this.index});

  @override
  State<MainBottomBar> createState() => _MainBottomBarState();
}

class _MainBottomBarState extends State<MainBottomBar>
    with TickerProviderStateMixin {
  int _selectedIndex = 0;
  DateTime? _lastBackPressed;

  bool _isOffline = false;
  int _homeEntryId = 0;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  late final AnimationController _tabFadeCtrl;
  late final Animation<double> _tabFadeAnim;

  static const _tabs = [
    PremiumNavTab.home,
    PremiumNavTab.chat,
    PremiumNavTab.transactions,
    PremiumNavTab.profile,
  ];

  static const _pillWidth = 54.0;
  static const _pillHeight = 48.0;

  final List<Widget> _screens = const [
    HomeScreen(),
    ChatListScreen(backPage: false),
    TransactionsScreen(backPage: false),
    ProfileScreen(backPage: false),
  ];

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.index ?? 0;
    _tabFadeCtrl = AnimationController(
      vsync: this,
      duration: PremiumAnimations.normal,
    )..value = 1;
    _tabFadeAnim = CurvedAnimation(
      parent: _tabFadeCtrl,
      curve: PremiumAnimations.enter,
    );
    _startConnectivityListener();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showLowBalanceCallIfNeeded();
    });
  }

  Future<void> _showLowBalanceCallIfNeeded() async {
    if (!mounted || _selectedIndex != 0) return;
    final entryId = ++_homeEntryId;
    await Future.delayed(const Duration(seconds: 10));
    if (!mounted || _selectedIndex != 0 || entryId != _homeEntryId) return;

    final userVM = context.read<UserViewModel>();
    await userVM.fetchUserDetails();
    if (!mounted || _selectedIndex != 0 || entryId != _homeEntryId) return;
    final balance = userVM.currentUser?.coinBalance;
    if (balance == null || balance >= 20) return;

    final callableStaff = context
        .read<StaffViewModel>()
        .allStaffList
        .where(
          (staff) =>
              staff.name.trim().isNotEmpty &&
              staff.image?.trim().isNotEmpty == true,
        )
        .toList();
    if (callableStaff.isEmpty) return;
    final caller = callableStaff[Random().nextInt(callableStaff.length)];
    if (!mounted || _selectedIndex != 0 || entryId != _homeEntryId) return;
    await Navigator.of(context).push(
      PageRouteBuilder<void>(
        opaque: false,
        barrierColor: Colors.black.withValues(alpha: 0.72),
        transitionDuration: const Duration(milliseconds: 280),
        reverseTransitionDuration: const Duration(milliseconds: 220),
        pageBuilder: (_, animation, __) => FadeTransition(
          opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
          child: FakeIncomingCallScreen(
            callerName: caller.name.trim(),
            callerImage: caller.image,
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    _tabFadeCtrl.dispose();
    super.dispose();
  }

  void _startConnectivityListener() {
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((
      results,
    ) async {
      final hasConnection = results.any((r) => r != ConnectivityResult.none);
      if (!hasConnection) {
        if (mounted) setState(() => _isOffline = true);
        return;
      }
      final hasInternet = await _hasInternetConnection();
      if (mounted) setState(() => _isOffline = !hasInternet);
    });
  }

  Future<bool> _hasInternetConnection() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException catch (_) {
      return false;
    }
  }

  Future<bool> _onWillPop() async {
    final now = DateTime.now();
    if (_lastBackPressed == null ||
        now.difference(_lastBackPressed!) > const Duration(seconds: 2)) {
      _lastBackPressed = now;
      Fluttertoast.showToast(msg: "Press again to exit");
      return false;
    }
    return true;
  }

  void _onTabSelected(int index) {
    if (_selectedIndex == index) return;
    final isEnteringHome = _selectedIndex != 0 && index == 0;
    HapticFeedback.selectionClick();
    if (_selectedIndex == 0 && index != 0) {
      _homeEntryId++;
      context.read<StaffViewModel>().updateSearchQuery('');
    }
    _tabFadeCtrl.forward(from: 0).then((_) {
      if (mounted) _tabFadeCtrl.value = 1;
    });
    setState(() => _selectedIndex = index);
    if (isEnteringHome) _showLowBalanceCallIfNeeded();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: DudeTheme.background,
        body: Stack(
          children: [
            FadeTransition(
              opacity: _tabFadeAnim,
              child: IndexedStack(index: _selectedIndex, children: _screens),
            ),
            if (_isOffline)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Material(
                  color: Colors.transparent,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 10,
                      horizontal: 16,
                    ),
                    decoration: BoxDecoration(
                      color: DudeTheme.danger.withValues(alpha: 0.92),
                      boxShadow: DudeTheme.softShadow,
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.wifi_off, color: Colors.white, size: 18),
                        SizedBox(width: 8),
                        Text(
                          "No Internet Connection",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
        bottomNavigationBar: Padding(
          padding: const EdgeInsets.only(bottom: 20, left: 16, right: 16),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
              child: Container(
                height: 68,
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  color: DudeTheme.surface.withValues(alpha: 0.72),
                  border: Border.all(
                    color: DudeTheme.accent.withValues(alpha: 0.35),
                  ),
                  boxShadow: DudeTheme.accentGlowShadow(blur: 32, spread: -8),
                ),
                child: Row(
                  children: List.generate(
                    _tabs.length,
                    (index) => _navSlot(_tabs[index], index),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Each tab owns its pill + icon so alignment stays pixel-perfect.
  Widget _navSlot(PremiumNavTab tab, int index) {
    final isActive = _selectedIndex == index;

    return Expanded(
      child: GestureDetector(
        onTap: () => _onTabSelected(index),
        behavior: HitTestBehavior.opaque,
        child: SizedBox(
          height: 56,
          child: Stack(
            alignment: Alignment.center,
            children: [
              AnimatedScale(
                scale: isActive ? 1 : 0.92,
                duration: PremiumAnimations.normal,
                curve: PremiumAnimations.smooth,
                child: AnimatedOpacity(
                  duration: PremiumAnimations.fast,
                  opacity: isActive ? 1 : 0,
                  child: Container(
                    width: _pillWidth,
                    height: _pillHeight,
                    decoration: BoxDecoration(
                      gradient: DudeTheme.premiumAccentGradient,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: DudeTheme.accentGlowShadow(blur: 14),
                    ),
                  ),
                ),
              ),
              AnimatedScale(
                scale: isActive ? 1.05 : 1,
                duration: PremiumAnimations.fast,
                curve: PremiumAnimations.bounce,
                child: PremiumNavIcon(tab: tab, isActive: isActive),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
