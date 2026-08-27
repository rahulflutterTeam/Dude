import 'dart:ui';

import 'package:dude/Dude_Utils/App_Theme/DudeTheme.dart';
import 'package:dude/Reusable_Widgets/Premium_UI/premium_animations.dart';
import 'package:dude/Reusable_Widgets/Premium_UI/premium_nav_icon.dart';
import 'package:dude/StaffScreenScreens/RecentCallScreen/RecentCallScreen.dart';
import 'package:dude/StaffScreenScreens/StaffDashBoardScreen/DashBoardScreen.dart';
import 'package:dude/StaffScreenScreens/StaffProfileScreen/staffProfileScreen.dart';
import 'package:dude/StaffScreenScreens/OnlineUsersScreen/staff_online_users_screen.dart';
import 'package:dude/StaffScreenScreens/staffChat/staffChatListScreen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';

class StaffBottomBar extends StatefulWidget {
  final int? index;
  final bool launchingAcceptedCall;

  const StaffBottomBar({
    super.key,
    this.index,
    this.launchingAcceptedCall = false,
  });

  @override
  State<StaffBottomBar> createState() => _StaffBottomBarState();
}

class _StaffBottomBarState extends State<StaffBottomBar>
    with TickerProviderStateMixin {
  int _selectedIndex = 0;
  DateTime? _lastBackPressed;
  late final ValueNotifier<int> _activeTab;

  late final AnimationController _tabFadeCtrl;
  late final Animation<double> _tabFadeAnim;

  static const MethodChannel _windowChannel = MethodChannel(
    'com.dude.dudeapp/window',
  );

  static const _tabs = [
    StaffNavTab.dashboard,
    StaffNavTab.chat,
    StaffNavTab.onlineUsers,
    StaffNavTab.recentCalls,
    StaffNavTab.profile,
  ];

  static const _pillWidth = 46.0;
  static const _pillHeight = 44.0;

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.index ?? 0;
    _activeTab = ValueNotifier<int>(_selectedIndex);
    _screens = [
      BondingDashboardPage(launchingAcceptedCall: widget.launchingAcceptedCall),
      const StaffChatListScreen(backPage: false),
      StaffOnlineUsersScreen(
        backPage: false,
        activeTab: _activeTab,
        tabIndex: 2,
      ),
      RecentCallsPage(
        backPage: false,
        activeTab: _activeTab,
        tabIndex: 3,
      ),
      const StaffProfileScreen(backPage: false),
    ];
    _tabFadeCtrl = AnimationController(
      vsync: this,
      duration: PremiumAnimations.normal,
    )..value = 1;
    _tabFadeAnim = CurvedAnimation(
      parent: _tabFadeCtrl,
      curve: PremiumAnimations.enter,
    );
  }

  @override
  void dispose() {
    _activeTab.dispose();
    _tabFadeCtrl.dispose();
    super.dispose();
  }

  Future<bool> _onWillPop() async {
    final now = DateTime.now();
    if (_lastBackPressed == null ||
        now.difference(_lastBackPressed!) > const Duration(seconds: 2)) {
      _lastBackPressed = now;
      Fluttertoast.showToast(msg: 'Press again to background app');
      return false;
    }

    try {
      await _windowChannel.invokeMethod('moveToBackground');
      Fluttertoast.showToast(msg: 'App moved to background');
    } catch (_) {
      return true;
    }
    return false;
  }

  void _onTabSelected(int index) {
    if (_selectedIndex == index) return;
    HapticFeedback.selectionClick();
    _tabFadeCtrl.forward(from: 0).then((_) {
      if (mounted) _tabFadeCtrl.value = 1;
    });
    setState(() => _selectedIndex = index);
    _activeTab.value = index;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: DudeTheme.background,
        body: FadeTransition(
          opacity: _tabFadeAnim,
          child: IndexedStack(index: _selectedIndex, children: _screens),
        ),
        bottomNavigationBar: widget.launchingAcceptedCall
            ? null
            : Padding(
                padding: const EdgeInsets.only(bottom: 20, left: 12, right: 12),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
                    child: Container(
                      height: 68,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        color: DudeTheme.surface.withValues(alpha: 0.72),
                        border: Border.all(
                          color: DudeTheme.accent.withValues(alpha: 0.35),
                        ),
                        boxShadow: DudeTheme.accentGlowShadow(
                          blur: 32,
                          spread: -8,
                        ),
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

  Widget _navSlot(StaffNavTab tab, int index) {
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
                child: StaffPremiumNavIcon(tab: tab, isActive: isActive),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
