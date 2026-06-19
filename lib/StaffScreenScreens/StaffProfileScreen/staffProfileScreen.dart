import 'dart:async';

import 'package:dude/DudeScreens/HomeScreen/zego_lifecycle.dart';
import 'package:dude/DudeScreens/AccountSettingScreen/AccountSetting.dart';
import 'package:dude/DudeScreens/HomeScreen/Socket.dart';
import 'package:dude/DudeScreens/Splash/SplashScreen2.dart';
import 'package:dude/Dude_Utils/CustomSnackBar/StatusMessage.dart';
import 'package:dude/Reusable_Widgets/BondingNavigator.dart';
import 'package:dude/StaffScreenScreens/StaffBottomNavBar/StaffBottomNavBar.dart';
import 'package:dude/StaffScreenScreens/StaffRegistrationScreen/ViewModel/StaffRegisterVM.dart';
import 'package:dude/StaffScreenScreens/WalletFlow/WalletScreen/WalletScreen.dart';
import 'package:dude/StaffScreenScreens/WithdrawScreen/WithdrawHistory.dart';
import 'package:dude/StaffScreenScreens/StaffProfileScreen/StaffRewardsScreen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

// ── Design tokens ─────────────────────────────────────────────────────────
const _kBg = Color(0xFF080612);
const _kCard = Color(0xFF100E1E);
const _kCardBorder = Color(0xFF1E1A30);
const _kAccent = Color(0xFFD4F53C);
const _kAccentDim = Color(0xFF2A3010);
const _kPurple = Color(0xFF7B5CF5);
const _kPurpleDim = Color(0xFF1C1535);
const _kText = Color(0xFFFFFFFF);
const _kTextSub = Color(0xFF6B6585);
const _kTextMid = Color(0xFFADA8C0);
const _kDanger = Color(0xFFEF4444);
const _kDangerDim = Color(0xFF1E0404);
// ──────────────────────────────────────────────────────────────────────────

class StaffProfileScreen extends StatefulWidget {
  final bool backPage;
  const StaffProfileScreen({super.key, required this.backPage});

  @override
  State<StaffProfileScreen> createState() => _StaffProfileScreenState();
}

class _StaffProfileScreenState extends State<StaffProfileScreen>
    with SingleTickerProviderStateMixin {
  bool _isLoggingOut = false;
  late final AnimationController _fadeCtrl;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _fadeCtrl.forward();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  Future<void> openWhatsApp(String phone) async {
    final Uri url = Uri.parse("https://wa.me/$phone");
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      Utils.snackBarErrorMessage("Could not open WhatsApp");
    }
  }

  Future<void> _launchEmail() async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: 'dudeofficial@gmail.com',
      query: 'subject=Dude Support Request',
    );

    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri);
    } else {
      Utils.snackBarErrorMessage("Could not open mail app");
    }
  }

  Future<void> _clearAllLocalData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('staff_is_online');
      await prefs.remove('staff_call_type');
      await prefs.remove('auth_token');
      await prefs.remove('user_id');
      await prefs.remove('user_phone');
      await prefs.remove('staff_data');
      await prefs.remove('staff_profile');
      await prefs.remove('isLoggedIn');
      debugPrint("✅ All local data cleared");
    } catch (e) {
      debugPrint("❌ Error clearing local data: $e");
      throw Exception("Failed to clear local data: $e");
    }
  }

  Future<void> _emitOfflineAndDisconnect(String memberID) async {
    try {
      final socketService = SocketService();
      socketService.connectStaff(memberID);
      await Future.delayed(const Duration(milliseconds: 800));

      if (socketService.isConnected) {
        debugPrint("📡 [LOGOUT] Socket connected, emitting offline events...");
        socketService.emit("staff_offline", {"memberID": memberID});
        await Future.delayed(const Duration(milliseconds: 200));
        socketService.emit("staff_busy_status", {
          "memberID": memberID,
          "isBusy": false,
          "isOnline": false,
          "timestamp": DateTime.now().millisecondsSinceEpoch,
        });
        await Future.delayed(const Duration(milliseconds: 500));
        socketService.disconnect();
        debugPrint(
          "📡 [LOGOUT] Offline events emitted and socket disconnected",
        );
      } else {
        debugPrint("⚠️ [LOGOUT] Could not connect socket for offline emission");
      }
    } catch (e) {
      debugPrint("❌ [LOGOUT] Error emitting offline events: $e");
    }
  }

  Future<void> _updateServerOfflineStatus(String staffId) async {
    try {
      if (!mounted) return;
      final staffVM = context.read<StaffViewModel>();
      final success = await staffVM.updateStaffCallStatus(
        staffId: staffId,
        isBusy: false,
      );
      if (success) {
        debugPrint("📡 [LOGOUT] Server status updated to offline");
      } else {
        debugPrint("⚠️ [LOGOUT] Server status update failed");
      }
    } catch (e) {
      debugPrint("❌ [LOGOUT] Error updating server status: $e");
    }
  }

  Future<void> _logout() async {
    if (_isLoggingOut) return;
    setState(() => _isLoggingOut = true);

    StaffViewModel? staffVM;
    String? memberId;
    String? staffId;

    try {
      if (mounted) {
        staffVM = context.read<StaffViewModel>();
        final staff = staffVM?.currentStaff;
        if (staff != null) {
          memberId = staff.memberID;
          staffId = staff.id;
        }
      }

      if (memberId != null) {
        try {
          await _emitOfflineAndDisconnect(memberId);
        } catch (e) {
          debugPrint("⚠️ Socket offline emission failed: $e");
        }
      }

      if (staffId != null && staffVM != null) {
        try {
          await _updateServerOfflineStatus(staffId);
        } catch (e) {
          debugPrint("⚠️ Server status update failed: $e");
        }
      }

      await Future.delayed(const Duration(milliseconds: 500));

      unawaited(_uninitZegoForLogout());

      try {
        await _clearAllLocalData();
      } catch (e) {
        debugPrint("❌ Error clearing local data: $e");
      }

      if (mounted && staffVM != null) {
        staffVM.clearStaffData();
      }

      if (mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            bondNavigator.newPageRemoveUntil(
              context,
              page: const SplashScreen2(),
            );
          }
        });
      }
    } catch (e) {
      debugPrint("❌ [LOGOUT] Logout error: $e");
      if (mounted) {
        Utils.snackBarErrorMessage(
          "Logout failed: ${e.toString().split('\n').first}",
        );
      }
      setState(() => _isLoggingOut = false);
    }
  }

  Future<void> _uninitZegoForLogout() async {
    await ZegoLifecycle.uninitSafely();
    debugPrint("✅ [LOGOUT] Zego SDK uninitialized");
  }

  String _formatJoinDate(dynamic date) {
    if (date == null) return '—';
    try {
      final d = date is DateTime ? date : DateTime.parse(date.toString());
      const months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ];
      return '${months[d.month - 1]} ${d.year}';
    } catch (_) {
      return '—';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<StaffViewModel>(
      builder: (context, staffVM, child) {
        final staff = staffVM.currentStaff;

        if (staffVM.isFetchingSingleStaff) {
          return const Scaffold(
            backgroundColor: _kBg,
            body: Center(
              child: CircularProgressIndicator(color: _kAccent, strokeWidth: 2),
            ),
          );
        }

        if (staff == null) {
          return Scaffold(
            backgroundColor: _kBg,
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: _kPurpleDim,
                      shape: BoxShape.circle,
                      border: Border.all(color: _kPurple.withOpacity(0.3)),
                    ),
                    child: const Icon(
                      Icons.person_off_outlined,
                      color: _kPurple,
                      size: 28,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No staff data',
                    style: TextStyle(
                      color: _kText,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 20),
                  GestureDetector(
                    onTap: staffVM.fetchStaffSingleData,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 28,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: _kAccent,
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: const Text(
                        'Retry',
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return Scaffold(
          backgroundColor: _kBg,
          body: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF0E0A1E),
                  Color(0xFF080612),
                  Color(0xFF080612),
                  Color(0xFF0D0A1C),
                ],
              ),
            ),
            child: SafeArea(
              child: FadeTransition(
                opacity: _fadeAnim,
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    children: [
                      // ── Top Bar ──────────────────────────────────────
                      _buildTopBar(),
                      const SizedBox(height: 28),

                      // ── Avatar + Name ────────────────────────────────
                      _buildProfileHero(staff),
                      const SizedBox(height: 32),

                      // ── Stats Row ────────────────────────────────────
                      _buildStatsRow(staff),
                      const SizedBox(height: 28),

                      // ── Menu ─────────────────────────────────────────
                      _buildMenuSection(context, staff),
                      const SizedBox(height: 16),

                      // ── Logout ───────────────────────────────────────
                      _buildLogoutSection(context, staffVM),
                      const SizedBox(height: 28),

                      // ── Support footer ───────────────────────────────
                      _buildSupportFooter(),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // ─────────────────────────────────────────────────────────────────────
  // TOP BAR
  // ─────────────────────────────────────────────────────────────────────

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              widget.backPage
                  ? bondNavigator.backPage(context)
                  : bondNavigator.newPageRemoveUntil(
                      context,
                      page: const StaffBottomBar(index: 0),
                    );
            },
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _kCard,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _kCardBorder),
              ),
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: _kText,
                size: 16,
              ),
            ),
          ),
          const Expanded(
            child: Text(
              'Profile',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _kText,
                fontSize: 18,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.2,
              ),
            ),
          ),
          const SizedBox(width: 40), // Placeholder for symmetry
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────
  // PROFILE HERO
  // ─────────────────────────────────────────────────────────────────────

  Widget _buildProfileHero(dynamic staff) {
    return Column(
      children: [
        Stack(
          alignment: Alignment.bottomRight,
          children: [
            Container(
              width: 104,
              height: 104,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [_kAccent, _kPurple],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: _kAccent.withOpacity(0.25),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
              padding: const EdgeInsets.all(2.5),
              child: ClipOval(
                child: staff.image != null && staff.image!.isNotEmpty
                    ? Image.network(
                        staff.image!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Image.asset(
                          "assets/Images/profileimg.png",
                          fit: BoxFit.cover,
                        ),
                      )
                    : Image.asset(
                        "assets/Images/profileimg.png",
                        fit: BoxFit.cover,
                      ),
              ),
            ),
            // Simple indicator without isOnline check
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: const Color(0xFF22C55E),
                shape: BoxShape.circle,
                border: Border.all(color: _kBg, width: 3),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Text(
          staff.name ?? 'Staff Member',
          style: const TextStyle(
            color: _kText,
            fontSize: 22,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
          decoration: BoxDecoration(
            color: _kCard,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: _kCardBorder),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.tag_rounded, color: _kTextSub, size: 13),
              const SizedBox(width: 4),
              Text(
                'ID: ${staff.memberID}',
                style: const TextStyle(
                  color: _kTextMid,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────────
  // STATS ROW - Using only available properties
  // ─────────────────────────────────────────────────────────────────────

  Widget _buildStatsRow(dynamic staff) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: _kCard,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _kCardBorder),
        ),
        child: Row(
          children: [
            _statTile(
              label: 'Staff ID',
              value:
                  staff.memberID?.substring(
                    0,
                    staff.memberID.length > 8 ? 8 : staff.memberID.length,
                  ) ??
                  '---',
              icon: Icons.badge_rounded,
              color: _kAccent,
            ),
            _vDivider(),
            _statTile(
              label: 'Member Since',
              value: _formatJoinDate(staff.createdAt),
              icon: Icons.calendar_today_rounded,
              color: _kPurple,
            ),
            _vDivider(),
            _statTile(
              label: 'Status',
              value: 'Active',
              icon: Icons.verified_rounded,
              color: const Color(0xFF22C55E),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statTile({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Expanded(
      child: Column(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 17),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(color: _kTextSub, fontSize: 10)),
        ],
      ),
    );
  }

  Widget _vDivider() => Container(width: 1, height: 48, color: _kCardBorder);

  // ─────────────────────────────────────────────────────────────────────
  // MENU SECTION
  // ─────────────────────────────────────────────────────────────────────

  Widget _buildMenuSection(BuildContext context, dynamic staff) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          color: _kCard,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _kCardBorder),
        ),
        child: Column(
          children: [
            _menuTile(
              icon: Icons.account_balance_wallet_outlined,
              iconColor: _kAccent,
              iconBg: _kAccentDim,
              title: 'Wallet',
              subtitle: 'Manage your balance',
              onTap: () => bondNavigator.newPage(
                context,
                page: const StaffWalletScreen(),
              ),
            ),
            _divider(),
            _menuTile(
              icon: Icons.receipt_long_rounded,
              iconColor: _kPurple,
              iconBg: _kPurpleDim,
              title: 'Withdraw History',
              subtitle: 'View withdrawal requests',
              onTap: () => bondNavigator.newPage(
                context,
                page: const WithdrawHistory(backPage: true),
              ),
            ),
            _divider(),
            _menuTile(
              icon: Icons.card_giftcard_rounded,
              iconColor: const Color(0xFFFF5FA2),
              iconBg: const Color(0xFF250B1B),
              title: 'My Rewards',
              subtitle: 'Rewards earned',
              onTap: () => bondNavigator.newPage(
                context,
                page: const StaffRewardsScreen(),
              ),
            ),
            _divider(),
            _menuTile(
              icon: Icons.manage_accounts_outlined,
              iconColor: const Color(0xFF38BDF8),
              iconBg: const Color(0xFF071520),
              title: 'Account Settings',
              subtitle: 'Privacy & preferences',
              onTap: () => bondNavigator.newPage(
                context,
                page: const AccountSettingsScreen(),
              ),
            ),
            _divider(),
            _menuTile(
              icon: Icons.support_agent_rounded,
              iconColor: const Color(0xFFF59E0B),
              iconBg: const Color(0xFF211500),
              title: 'Contact Us',
              subtitle: 'Chat with support',
              onTap: () => openWhatsApp("919342730160"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _divider() => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16),
    child: Container(height: 1, color: _kCardBorder),
  );

  Widget _menuTile({
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: iconColor.withOpacity(0.2)),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: _kText,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(color: _kTextSub, fontSize: 12),
                  ),
                ],
              ),
            ),
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: _kCardBorder,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.arrow_forward_ios_rounded,
                color: _kTextMid,
                size: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────
  // LOGOUT SECTION
  // ─────────────────────────────────────────────────────────────────────

  Widget _buildLogoutSection(BuildContext context, StaffViewModel staffVM) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GestureDetector(
        onTap: () async {
          HapticFeedback.mediumImpact();
          _showLogoutDialog(context, staffVM);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: _kDangerDim,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: _kDanger.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: _kDanger.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _kDanger.withOpacity(0.25)),
                ),
                child: _isLoggingOut
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: _kDanger,
                        ),
                      )
                    : const Icon(
                        Icons.logout_rounded,
                        color: _kDanger,
                        size: 20,
                      ),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Logout',
                      style: TextStyle(
                        color: _kDanger,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Sign out of your account',
                      style: TextStyle(color: Color(0xFF885555), fontSize: 12),
                    ),
                  ],
                ),
              ),
              if (!_isLoggingOut)
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: _kDanger.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: _kDanger,
                    size: 12,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, StaffViewModel staffVM) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: _kCard,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _kCardBorder),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: _kDangerDim,
                  shape: BoxShape.circle,
                  border: Border.all(color: _kDanger.withOpacity(0.3)),
                ),
                child: const Icon(
                  Icons.logout_rounded,
                  color: _kDanger,
                  size: 26,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Logout',
                style: TextStyle(
                  color: _kText,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Are you sure you want to\nsign out of your account?',
                textAlign: TextAlign.center,
                style: TextStyle(color: _kTextSub, fontSize: 14),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        height: 46,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: _kCardBorder,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(
                            color: _kTextMid,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: () async {
                        Navigator.pop(context);
                        await _logout();
                      },
                      child: Container(
                        height: 46,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: _kDanger,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'Logout',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────
  // SUPPORT FOOTER
  // ─────────────────────────────────────────────────────────────────────

  Widget _buildSupportFooter() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _kCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _kCardBorder),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: _kAccentDim,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.mail_outline_rounded,
                color: _kAccent,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Need Help?',
                    style: TextStyle(color: _kTextMid, fontSize: 12),
                  ),
                  const SizedBox(height: 2),
                  GestureDetector(
                    onTap: _launchEmail,
                    child: const Text(
                      'dudeofficial@gmail.com',
                      style: TextStyle(
                        color: _kAccent,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        decoration: TextDecoration.underline,
                        decorationColor: _kAccent,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
