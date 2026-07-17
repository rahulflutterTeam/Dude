import 'dart:async';

import 'package:dude/DudeScreens/HomeScreen/zego_lifecycle.dart';
import 'package:dude/DudeScreens/Splash/SplashScreen2.dart';
import 'package:dude/Dude_Utils/App_Theme/DudeTheme.dart';
import 'package:dude/Dude_Utils/CustomSnackBar/StatusMessage.dart';
import 'package:dude/Reusable_Widgets/BondingNavigator.dart';
import 'package:dude/Reusable_Widgets/Premium_UI/premium_ambient_background.dart';
import 'package:dude/Reusable_Widgets/Premium_UI/premium_glass_card.dart';
import 'package:dude/Reusable_Widgets/Premium_UI/premium_stagger.dart';
import 'package:dude/StaffScreenScreens/StaffBottomNavBar/StaffBottomNavBar.dart';
import 'package:dude/StaffScreenScreens/StaffProfileScreen/StaffRewardsScreen.dart';
import 'package:dude/StaffScreenScreens/StaffRegistrationScreen/ViewModel/StaffRegisterVM.dart';
import 'package:dude/StaffScreenScreens/WalletFlow/WalletScreen/WalletScreen.dart';
import 'package:dude/StaffScreenScreens/WithdrawScreen/WithdrawHistory.dart';
import 'package:dude/StaffScreenScreens/staffAccountSettingScreen/staffAccountSettingScreen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:dude/DudeScreens/HomeScreen/Socket.dart';

class StaffProfileScreen extends StatefulWidget {
  final bool backPage;
  const StaffProfileScreen({super.key, required this.backPage});

  @override
  State<StaffProfileScreen> createState() => _StaffProfileScreenState();
}

class _StaffProfileScreenState extends State<StaffProfileScreen>
    with TickerProviderStateMixin {
  bool _isLoggingOut = false;
  late final AnimationController _fadeCtrl;
  late final Animation<double> _fadeAnim;
  late final AnimationController _avatarPulseCtrl;
  late final Animation<double> _avatarPulseAnim;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _avatarPulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);
    _avatarPulseAnim = Tween<double>(begin: 0.85, end: 1.12).animate(
      CurvedAnimation(parent: _avatarPulseCtrl, curve: Curves.easeInOut),
    );
    _fadeCtrl.forward();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    _avatarPulseCtrl.dispose();
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

      // Force a clean connect so logout presence events always leave the device.
      if (socketService.isConnected) {
        socketService.emit("staff_offline", {"memberID": memberID});
        socketService.emit("staff_busy_status", {
          "memberID": memberID,
          "isBusy": false,
          "isOnline": false,
          "timestamp": DateTime.now().millisecondsSinceEpoch,
        });
        await Future.delayed(const Duration(milliseconds: 400));
        socketService.disconnect();
        debugPrint(
          "📡 [LOGOUT] Offline events emitted and socket disconnected",
        );
        return;
      }

      socketService.connectStaff(memberID);
      await Future.delayed(const Duration(milliseconds: 1000));

      if (socketService.isConnected) {
        debugPrint("📡 [LOGOUT] Socket connected, emitting offline events...");
        socketService.emit("staff_offline", {"memberID": memberID});
        await Future.delayed(const Duration(milliseconds: 150));
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
            backgroundColor: DudeTheme.background,
            body: Center(
              child: CircularProgressIndicator(
                color: DudeTheme.accent,
                strokeWidth: 2,
              ),
            ),
          );
        }

        if (staff == null) {
          return Scaffold(
            backgroundColor: DudeTheme.background,
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: DudeTheme.accentDim,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: DudeTheme.accent.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Icon(
                      Icons.person_off_outlined,
                      color: DudeTheme.accent,
                      size: 28,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text('No staff data', style: TextStyle(
                      color: DudeTheme.textPrimary,
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
                        color: DudeTheme.accent,
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Text('Retry', style: TextStyle(
                          color: DudeTheme.textOnAccent,
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
          backgroundColor: DudeTheme.background,
          body: PremiumAmbientBackground(
            child: SafeArea(
              child: FadeTransition(
                opacity: _fadeAnim,
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(
                    parent: AlwaysScrollableScrollPhysics(),
                  ),
                  child: Column(
                    children: [
                      PremiumStaggerItem(
                        index: 0,
                        child: _buildTopBar(),
                      ),
                      const SizedBox(height: 20),
                      PremiumStaggerItem(
                        index: 1,
                        child: _buildProfileHeader(staff),
                      ),
                      const SizedBox(height: 20),
                      PremiumStaggerItem(
                        index: 2,
                        child: _buildEarningsBanner(staff),
                      ),
                      const SizedBox(height: 20),
                      PremiumStaggerItem(
                        index: 3,
                        child: _buildQuickActionsGrid(context),
                      ),
                      const SizedBox(height: 16),
                      PremiumStaggerItem(
                        index: 4,
                        child: _buildMoreOptions(context),
                      ),
                      const SizedBox(height: 16),
                      PremiumStaggerItem(
                        index: 5,
                        child: _buildLogoutSection(context, staffVM),
                      ),
                      const SizedBox(height: 20),
                      PremiumStaggerItem(
                        index: 6,
                        child: _buildSupportFooter(),
                      ),
                      const SizedBox(height: 32),
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

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
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
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: DudeTheme.surface.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: DudeTheme.border.withValues(alpha: 0.5),
                ),
              ),
              child: Icon(
                Icons.arrow_back_ios_new_rounded,
                color: DudeTheme.textPrimary,
                size: 18,
              ),
            ),
          ),
          const Expanded(
            child: Text(
              'My Profile',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: DudeTheme.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.2,
              ),
            ),
          ),
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              bondNavigator.newPage(
                context,
                page: const staffAccountSettingsScreen(),
              );
            },
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: DudeTheme.surface.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: DudeTheme.border.withValues(alpha: 0.5),
                ),
              ),
              child: Icon(
                Icons.settings_rounded,
                color: DudeTheme.accent,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileHeader(dynamic staff) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: PremiumGlassCard(
        glow: true,
        padding: const EdgeInsets.all(16),
        radius: 20,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Stack(
              alignment: Alignment.bottomRight,
              children: [
                AnimatedBuilder(
                  animation: _avatarPulseAnim,
                  builder: (context, child) {
                    return Container(
                      width: 76,
                      height: 76,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: DudeTheme.accent.withValues(
                              alpha: 0.22 * _avatarPulseAnim.value,
                            ),
                            blurRadius: 20 * _avatarPulseAnim.value,
                          ),
                        ],
                      ),
                      child: child,
                    );
                  },
                  child: Container(
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: DudeTheme.premiumAccentGradient,
                    ),
                    padding: const EdgeInsets.all(2),
                    child: ClipOval(
                      child: staff.image != null && staff.image!.isNotEmpty
                          ? Image.network(
                              staff.image!,
                              width: 72,
                              height: 72,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Image.asset(
                                'assets/Images/women.png',
                                fit: BoxFit.cover,
                              ),
                            )
                          : Image.asset(
                              'assets/Images/women.png',
                              fit: BoxFit.cover,
                            ),
                    ),
                  ),
                ),
                Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: DudeTheme.success,
                    shape: BoxShape.circle,
                    border: Border.all(color: DudeTheme.background, width: 2),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    staff.name ?? 'Staff Member',
                    style: TextStyle(
                      color: DudeTheme.textPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                    ),
                  ),
                  if (staff.phone != null &&
                      staff.phone.toString().isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      '+91 ${staff.phone}',
                      style: TextStyle(
                        color: DudeTheme.textMuted.withValues(alpha: 0.9),
                        fontSize: 13,
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      _infoChip(
                        Icons.badge_outlined,
                        'ID ${staff.memberID}',
                      ),
                      _infoChip(
                        Icons.calendar_today_outlined,
                        'Since ${_formatJoinDate(staff.createdAt)}',
                      ),
                      _infoChip(Icons.verified_rounded, 'Active', accent: true),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoChip(IconData icon, String text, {bool accent = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: accent
            ? DudeTheme.accent.withValues(alpha: 0.12)
            : DudeTheme.background.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: accent
              ? DudeTheme.accent.withValues(alpha: 0.35)
              : DudeTheme.border.withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 11,
            color: accent ? DudeTheme.accent : DudeTheme.textSubtle,
          ),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: accent ? DudeTheme.accent : DudeTheme.textMid,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEarningsBanner(dynamic staff) {
    final earned = staff.staffEarned?.toStringAsFixed(2) ?? '0.00';
    final pending = staff.pendingBalance?.toStringAsFixed(2) ?? '0.00';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          bondNavigator.newPage(context, page: const StaffWalletScreen());
        },
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
          decoration: BoxDecoration(
            gradient: DudeTheme.premiumAccentGradient,
            borderRadius: BorderRadius.circular(22),
            boxShadow: DudeTheme.accentGlowShadow(blur: 22, spread: -4),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total earned',
                      style: TextStyle(
                        color: DudeTheme.textOnAccent.withValues(alpha: 0.85),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '₹$earned',
                      style: TextStyle(
                        color: DudeTheme.textOnAccent,
                        fontSize: 34,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                        height: 1,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Pending balance: ₹$pending',
                      style: TextStyle(
                        color: DudeTheme.textOnAccent.withValues(alpha: 0.75),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Tap to open wallet',
                      style: TextStyle(
                        color: DudeTheme.textOnAccent.withValues(alpha: 0.65),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.35),
                  ),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.account_balance_wallet_outlined,
                      color: DudeTheme.textOnAccent,
                      size: 18,
                    ),
                    SizedBox(width: 4),
                    Text(
                      'Wallet',
                      style: TextStyle(
                        color: DudeTheme.textOnAccent,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActionsGrid(BuildContext context) {
    final actions = [
      _QuickAction(
        icon: Icons.account_balance_wallet_outlined,
        label: 'Wallet',
        color: DudeTheme.accent,
        onTap: () => bondNavigator.newPage(
          context,
          page: const StaffWalletScreen(),
        ),
      ),
      _QuickAction(
        icon: Icons.receipt_long_rounded,
        label: 'Withdraw History',
        color: DudeTheme.accentBright,
        onTap: () => bondNavigator.newPage(
          context,
          page: const WithdrawHistory(backPage: true),
        ),
      ),
      _QuickAction(
        icon: Icons.card_giftcard_rounded,
        label: 'Rewards',
        color: DudeTheme.accentDeep,
        onTap: () => bondNavigator.newPage(
          context,
          page: const StaffRewardsScreen(),
        ),
      ),
      _QuickAction(
        icon: Icons.support_agent_rounded,
        label: 'Contact',
        color: DudeTheme.warning,
        onTap: () => openWhatsApp("919999999999"),
      ),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionLabel('Quick actions'),
          const SizedBox(height: 10),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: actions.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 1.55,
            ),
            itemBuilder: (context, index) {
              final action = actions[index];
              return _quickActionTile(action);
            },
          ),
        ],
      ),
    );
  }

  Widget _quickActionTile(_QuickAction action) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        action.onTap();
      },
      child: PremiumGlassCard(
        padding: const EdgeInsets.all(14),
        radius: 16,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: action.color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(11),
                border: Border.all(
                  color: action.color.withValues(alpha: 0.35),
                ),
              ),
              child: Icon(action.icon, color: action.color, size: 20),
            ),
            Text(
              action.label,
              style: TextStyle(
                color: DudeTheme.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMoreOptions(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionLabel('More'),
          const SizedBox(height: 10),
          PremiumGlassCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                _compactMenuRow(
                  icon: Icons.mail_outline_rounded,
                  title: 'Email support',
                  onTap: _launchEmail,
                ),
                _divider(),
                _compactMenuRow(
                  icon: Icons.manage_accounts_outlined,
                  title: 'Account settings',
                  onTap: () => bondNavigator.newPage(
                    context,
                    page: const staffAccountSettingsScreen(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _compactMenuRow({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        child: Row(
          children: [
            Icon(icon, color: DudeTheme.accent, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: DudeTheme.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: DudeTheme.textSubtle.withValues(alpha: 0.8),
              size: 22,
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          color: DudeTheme.textSubtle.withValues(alpha: 0.9),
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.1,
        ),
      ),
    );
  }

  Widget _divider() => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Container(height: 1, color: DudeTheme.border),
      );

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
            color: DudeTheme.dangerDim,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: DudeTheme.danger.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: DudeTheme.danger.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: DudeTheme.danger.withOpacity(0.25)),
                ),
                child: _isLoggingOut
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: DudeTheme.danger,
                        ),
                      )
                    : Icon(
                        Icons.logout_rounded,
                        color: DudeTheme.danger,
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
                        color: DudeTheme.danger,
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
                    color: DudeTheme.danger.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: DudeTheme.danger,
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
            color: DudeTheme.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: DudeTheme.border),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: DudeTheme.dangerDim,
                  shape: BoxShape.circle,
                  border: Border.all(color: DudeTheme.danger.withOpacity(0.3)),
                ),
                child: Icon(
                  Icons.logout_rounded,
                  color: DudeTheme.danger,
                  size: 26,
                ),
              ),
              const SizedBox(height: 16),
              Text('Logout', style: TextStyle(
                  color: DudeTheme.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Are you sure you want to\nsign out of your account?',
                textAlign: TextAlign.center,
                style: TextStyle(color: DudeTheme.textSubtle, fontSize: 14),
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
                          color: DudeTheme.border,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text('Cancel', style: TextStyle(
                            color: DudeTheme.textMid,
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
                          color: DudeTheme.danger,
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

  Widget _buildSupportFooter() {
    return Center(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: DudeTheme.surface.withOpacity(0.55),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: DudeTheme.accent.withOpacity(0.18)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.verified_user_rounded, color: DudeTheme.accent, size: 16),
                SizedBox(width: 6),
                Text(
                  '100% Safe and private',
                  style: TextStyle(
                    color: DudeTheme.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: _launchEmail,
            child: Text(
              'dudeofficial@gmail.com',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: DudeTheme.accent.withValues(alpha: 0.9),
                fontSize: 12,
                fontWeight: FontWeight.w500,
                decoration: TextDecoration.underline,
                decorationColor: DudeTheme.accent.withValues(alpha: 0.5),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickAction {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });
}
