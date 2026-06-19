import 'package:dude/DudeScreens/AccountSettingScreen/AccountSetting.dart';
import 'package:dude/DudeScreens/AuthService.dart';
import 'package:dude/DudeScreens/BottomNavBar/BottomNavBar.dart';
import 'package:dude/DudeScreens/HomeScreen/callServic.dart';
import 'package:dude/DudeScreens/HomeScreen/ViewModel/UserVM.dart';
import 'package:dude/DudeScreens/ProfileScreen/EditProfile/EditProfileScreen.dart';
import 'package:dude/DudeScreens/ProfileScreen/Refer&Earn.dart';
import 'package:dude/DudeScreens/ProfileScreen/helpandSupportScreen.dart';
import 'package:dude/DudeScreens/RefundScreen/RefundScreen.dart';
import 'package:dude/DudeScreens/Splash/SplashScreen2.dart';
import 'package:dude/DudeScreens/Transactions/TransactionScreen.dart';
import 'package:dude/DudeScreens/WalletScreen/WalletScreen.dart';
import 'package:dude/Dude_Utils/CustomSnackBar/StatusMessage.dart';
import 'package:dude/Reusable_Widgets/AppText_Theme/AppText_Theme.dart';
import 'package:dude/Reusable_Widgets/BondingNavigator.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
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

class ProfileScreen extends StatefulWidget {
  final bool backPage;
  const ProfileScreen({super.key, required this.backPage});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _fadeCtrl;
  late final Animation<double> _fadeAnim;
  String _appVersion = '';

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _fadeCtrl.forward();
    _loadAppVersion();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  // ── External launchers ────────────────────────────────────────────────

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

  Future<void> _openWhatsApp(String phone) async {
    final Uri url = Uri.parse("https://wa.me/$phone");
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      Utils.snackBarErrorMessage("Could not open WhatsApp");
    }
  }

  Future<void> _openPrivacyPolicy() async {
    const String privacyUrl = "https://www.pair-ever.com/privacy-policy";
    final Uri url = Uri.parse(privacyUrl);
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      Utils.snackBarErrorMessage("Could not open Privacy Policy");
    }
  }

  Future<void> _loadAppVersion() async {
    final info = await PackageInfo.fromPlatform();
    if (!mounted) return;
    setState(() {
      _appVersion = '${info.version}';
    });
  }

  // ─────────────────────────────────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Consumer<UserViewModel>(
      builder: (context, userVM, _) {
        final user = userVM.currentUser;

        if (userVM.isLoading) {
          return const Scaffold(
            backgroundColor: _kBg,
            body: Center(
              child: CircularProgressIndicator(color: _kAccent, strokeWidth: 2),
            ),
          );
        }

        if (user == null) {
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
                    'No user data',
                    style: TextStyle(
                      color: _kText,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 20),
                  GestureDetector(
                    onTap: userVM.fetchUserDetails,
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
                      _buildProfileHero(user),
                      const SizedBox(height: 32),

                      // ── Stats Row ────────────────────────────────────
                      _buildStatsRow(user),
                      const SizedBox(height: 28),

                      // ── Menu ─────────────────────────────────────────
                      _buildMenuSection(context, user),
                      const SizedBox(height: 16),

                      // ── Logout ───────────────────────────────────────
                      _buildLogoutSection(context, userVM),
                      const SizedBox(height: 28),

                      // ── Support footer ───────────────────────────────
                      _buildSupportFooter(),
                      const SizedBox(height: 18),
                      _buildSecureVersionFooter(),
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
          // Back button
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              widget.backPage
                  ? bondNavigator.backPage(context)
                  : bondNavigator.newPageRemoveUntil(
                      context,
                      page: const MainBottomBar(index: 0),
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

          // Edit button
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              bondNavigator.newPage(context, page: const EditProfileScreen());
            },
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _kAccentDim,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _kAccent.withOpacity(0.35)),
              ),
              child: const Icon(Icons.edit_rounded, color: _kAccent, size: 18),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────
  // PROFILE HERO
  // ─────────────────────────────────────────────────────────────────────

  Widget _buildProfileHero(dynamic user) {
    return Column(
      children: [
        // Avatar with glow ring
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
                child: user.image != null && (user.image as String).isNotEmpty
                    ? Image.network(
                        user.image as String,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Image.asset(
                          "assets/Images/men.png",
                          fit: BoxFit.cover,
                        ),
                      )
                    : Image.asset("assets/Images/men.png", fit: BoxFit.cover),
              ),
            ),
            // Online indicator
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

        // Name
        Text(
          user.name ?? 'User',
          style: const TextStyle(
            color: _kText,
            fontSize: 22,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
          ),
        ),

        const SizedBox(height: 6),

        // Member ID pill
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
                'ID: ${user.memberID}',
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
  // STATS ROW
  // ─────────────────────────────────────────────────────────────────────

  Widget _buildStatsRow(dynamic user) {
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
              label: 'Balance',
              value: '${user.coinBalance ?? 0}',
              assetIcon: "assets/Images/paircoin.png",
              color: _kAccent,
              showAddButton: true,
              onTap: () =>
                  bondNavigator.newPage(context, page: const WalletScreen()),
            ),
            _vDivider(),
            _statTile(
              label: 'Member Since',
              value: _formatJoinDate(user.createdAt),
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

  Widget _statTile({
    required String label,
    required String value,
    IconData? icon,
    String? assetIcon,
    required Color color,
    bool showAddButton = false,
    VoidCallback? onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: assetIcon != null
                  ? Center(child: Image.asset(assetIcon, width: 20, height: 20))
                  : Icon(icon, color: color, size: 17),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (showAddButton) ...[
                  Container(
                    width: 18,
                    height: 18,
                    decoration: const BoxDecoration(
                      color: _kAccent,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.add_rounded,
                      color: Colors.black,
                      size: 14,
                    ),
                  ),
                  const SizedBox(width: 5),
                ],
                Text(
                  value,
                  style: TextStyle(
                    color: color,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(label, style: const TextStyle(color: _kTextSub, fontSize: 10)),
          ],
        ),
      ),
    );
  }

  Widget _vDivider() => Container(width: 1, height: 48, color: _kCardBorder);

  // ─────────────────────────────────────────────────────────────────────
  // MENU SECTION
  // ─────────────────────────────────────────────────────────────────────

  Widget _buildMenuSection(BuildContext context, dynamic user) {
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
              assetIcon: "assets/Images/paircoin.png",
              iconColor: _kAccent,
              iconBg: _kAccentDim,
              title: 'Wallet',
              subtitle: 'Manage your balance',
              onTap: () =>
                  bondNavigator.newPage(context, page: const WalletScreen()),
            ),
            _divider(),
            _menuTile(
              icon: Icons.receipt_long_rounded,
              iconColor: _kPurple,
              iconBg: _kPurpleDim,
              title: 'Transactions',
              subtitle: 'View payment history',
              onTap: () => bondNavigator.newPage(
                context,
                page: const TransactionsScreen(backPage: true),
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
              icon: Icons.manage_accounts_outlined,
              iconColor: const Color(0xFF38BDF8),
              iconBg: const Color(0xFF071520),
              title: 'Refunds & Cancellations',
              subtitle: 'Subscription Cancellation',
              onTap: () => bondNavigator.newPage(
                context,
                page: const RefundsCancellationsScreen(),
              ),
            ),
            _divider(),
            _menuTile(
              icon: Icons.card_giftcard_rounded,
              iconColor: const Color(0xFF38BDF8),
              iconBg: const Color(0xFF071520),
              title: 'Refer & Earn',
              subtitle: 'Refer Your Friends',
              onTap: () => bondNavigator.newPage(
                context,
                page: const ReferEarnScreen(backPage: true),
              ),
            ),
            _divider(),
            _menuTile(
              icon: Icons.support_agent_rounded,
              iconColor: const Color(0xFFF59E0B),
              iconBg: const Color(0xFF211500),
              title: 'Contact Us',
              subtitle: 'Chat with support',
              onTap: () {
                bondNavigator.newPage(context, page: HelpAndSupportScreen());
              },
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
    IconData? icon,
    String? assetIcon,
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
            // Icon box
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: iconColor.withOpacity(0.2)),
              ),
              child: assetIcon != null
                  ? Center(child: Image.asset(assetIcon, width: 24, height: 24))
                  : Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 14),

            // Text
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

            // Arrow
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

  Widget _buildLogoutSection(BuildContext context, UserViewModel userVM) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GestureDetector(
        onTap: () async {
          HapticFeedback.mediumImpact();
          _showLogoutDialog(context, userVM);
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
                child: const Icon(
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

  void _showLogoutDialog(BuildContext context, UserViewModel userVM) {
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
              // Icon
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
                  // Cancel
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
                  // Confirm
                  Expanded(
                    child: GestureDetector(
                      onTap: () async {
                        Navigator.pop(context);
                        await ZegoCallService().uninitialize();
                        await AuthService.logout();
                        userVM.clearUser();
                        if (!context.mounted) return;
                        bondNavigator.newPageRemoveUntil(
                          context,
                          page: const SplashScreen2(),
                        );
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

  Widget _buildSecureVersionFooter() {
    final versionText = _appVersion.isEmpty
        ? 'Version loading'
        : 'v$_appVersion';

    return Center(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: _kCard.withOpacity(0.55),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: _kAccent.withOpacity(0.18)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.verified_user_rounded, color: _kAccent, size: 16),
                SizedBox(width: 6),
                Text(
                  '100% Safe and private',
                  style: TextStyle(
                    color: _kText,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Version: $versionText",
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
