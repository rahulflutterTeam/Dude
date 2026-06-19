import 'dart:async';
import 'dart:io';

import 'package:dude/DudeScreens/Chat/ChatListScreen.dart';
import 'package:dude/DudeScreens/HomeScreen/HomeScreen.dart';
import 'package:dude/DudeScreens/ProfileScreen/ProfileScreen.dart';
import 'package:dude/DudeScreens/Transactions/TransactionScreen.dart';
import 'package:dude/StaffScreenScreens/StaffRegistrationScreen/ViewModel/StaffRegisterVM.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

class MainBottomBar extends StatefulWidget {
  final int? index;

  const MainBottomBar({super.key, this.index});

  @override
  State<MainBottomBar> createState() => _MainBottomBarState();
}

class _MainBottomBarState extends State<MainBottomBar> {
  int _selectedIndex = 0;
  DateTime? _lastBackPressed;

  bool _isOffline = false;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.index ?? 0;
    _startConnectivityListener();
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

      // Verify real internet
      final hasInternet = await _hasInternetConnection();
      if (mounted) {
        setState(() => _isOffline = !hasInternet);
      }
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

  /// 🔹 Screens
  final List<Widget> _screens = const [
    HomeScreen(),
    // HistoryScreen(),
    ChatListScreen(backPage: false),
    TransactionsScreen(backPage: false),
    ProfileScreen(backPage: false),
  ];

  /// 🔹 Back press handler
  Future<bool> _onWillPop() async {
    DateTime now = DateTime.now();
    if (_lastBackPressed == null ||
        now.difference(_lastBackPressed!) > const Duration(seconds: 2)) {
      _lastBackPressed = now;
      Fluttertoast.showToast(msg: "Press again to exit");
      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          children: [
            _screens[_selectedIndex],
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
                    decoration: const BoxDecoration(
                      color: Color(0xFFd9534f),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 6,
                          offset: Offset(0, 2),
                        ),
                      ],
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

        /// 🔹 Custom Floating Bottom Bar
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
                  "assets/Images/chatactive.svg",
                  "assets/Images/chatinactive.svg",
                  1,
                ),
                // _navItem(
                //   "assets/Images/transaction.svg",
                //   "assets/Images/tranunactive.svg",
                //   2,
                // ),
                _navItem(
                  "assets/Images/transaction.svg",
                  "assets/Images/tranunactive.svg",
                  2,
                ),
                _navItem(
                  "assets/Images/pro.svg",
                  "assets/Images/prounactive.svg",
                  3,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 🔹 Bottom Nav Item
  Widget _navItem(String activeIcon, String inactiveIcon, int index) {
    final bool isActive = _selectedIndex == index;

    return GestureDetector(
      onTap: () {
        if (_selectedIndex == 0 && index != 0) {
          context.read<StaffViewModel>().updateSearchQuery('');
        }
        setState(() {
          _selectedIndex = index;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: 55,
        height: 55,
        child: Center(
          child: SvgPicture.asset(
            isActive ? activeIcon : inactiveIcon, //
          ),
        ),
      ),
    );
  }
}
