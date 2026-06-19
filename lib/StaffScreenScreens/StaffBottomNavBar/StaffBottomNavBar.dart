import 'package:dude/DudeScreens/Chat/ChatListScreen.dart';
import 'package:dude/DudeScreens/HistoryCard/HistoryCardScreen.dart';
import 'package:dude/DudeScreens/HomeScreen/HomeScreen.dart';
import 'package:dude/DudeScreens/Transactions/TransactionScreen.dart';
import 'package:dude/StaffScreenScreens/RecentCallScreen/RecentCallScreen.dart';
import 'package:dude/StaffScreenScreens/StaffDashBoardScreen/DashBoardScreen.dart';
import 'package:dude/StaffScreenScreens/StaffProfileScreen/staffProfileScreen.dart';
import 'package:dude/StaffScreenScreens/WithdrawScreen/WithdrawHistory.dart';
import 'package:dude/StaffScreenScreens/staffChat/staffChatListScreen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:flutter_svg/flutter_svg.dart';

class StaffBottomBar extends StatefulWidget {
  final int? index;

  const StaffBottomBar({super.key, this.index});

  @override
  State<StaffBottomBar> createState() => _StaffBottomBarState();
}

class _StaffBottomBarState extends State<StaffBottomBar> {
  int _selectedIndex = 0;
  DateTime? _lastBackPressed;
  static const MethodChannel _windowChannel = MethodChannel(
    'com.dude.dudeapp/window',
  );

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.index ?? 0;
  }

  /// 🔹 Screens
  final List<Widget> _screens = [
    const BondingDashboardPage(),
    const RecentCallsPage(backPage: false),
    StaffChatListScreen(backPage: false),
    const WithdrawHistory(backPage: false),
    const StaffProfileScreen(backPage: false),
  ];

  /// 🔹 Back press handler
  Future<bool> _onWillPop() async {
    DateTime now = DateTime.now();
    if (_lastBackPressed == null ||
        now.difference(_lastBackPressed!) > const Duration(seconds: 2)) {
      _lastBackPressed = now;
      Fluttertoast.showToast(msg: "Press again to background app");
      return false;
    }

    // Keep app process alive for incoming calls.
    try {
      await _windowChannel.invokeMethod('moveToBackground');
      Fluttertoast.showToast(msg: "App moved to background");
    } catch (_) {
      // If channel is unavailable, fallback to default behavior.
      return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: _screens[_selectedIndex],

        /// 🔥 FLOATING BOTTOM BAR (MATCH MAIN)
        bottomNavigationBar: Padding(
          padding: const EdgeInsets.only(bottom: 20, left: 16, right: 16),
          child: Container(
            height: 70,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: const LinearGradient(
                colors: [
                  Color(0xFF0E0A14),
                  Color(0xFF1c122e),
                  Color(0xFF261247),
                ],
              ),
              border: Border.all(color: Colors.white24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.6),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _navItem(
                  "assets/Images/dis.svg",
                  "assets/Images/disunactive.svg",
                  0,
                ),
                _navItem(
                  "assets/Images/history1.svg",
                  "assets/Images/his.svg",
                  1,
                ),
                _navItem(
                  "assets/Images/chatactive1.svg",
                  "assets/Images/chatunactive.svg",
                  2,
                ),
                _navItem(
                  "assets/Images/transaction.svg",
                  "assets/Images/tranunactive.svg",
                  3,
                ),
                _navItem(
                  "assets/Images/pro.svg",
                  "assets/Images/prounactive.svg",
                  4,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 🔥 NAV ITEM (ACTIVE / INACTIVE SWITCH)
  Widget _navItem(String activeIcon, String inactiveIcon, int index) {
    final bool isActive = _selectedIndex == index;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedIndex = index;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: 55,
        height: 55,
        child: Center(
          child: SvgPicture.asset(isActive ? activeIcon : inactiveIcon),
        ),
      ),
    );
  }
}
