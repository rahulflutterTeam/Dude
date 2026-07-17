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
import 'package:dude/Reusable_Widgets/BondingNavigator.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:dude/Dude_Utils/App_Theme/DudeTheme.dart';
import 'package:dude/Reusable_Widgets/Premium_UI/premium_ambient_background.dart';
import 'package:dude/Reusable_Widgets/Premium_UI/premium_glass_card.dart';
import 'package:dude/Reusable_Widgets/Premium_UI/premium_stagger.dart';
import 'package:url_launcher/url_launcher.dart';

class ProfileScreen extends StatefulWidget {
  final bool backPage;
  const ProfileScreen({super.key, required this.backPage});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with TickerProviderStateMixin {
  late final AnimationController _fadeCtrl;
  late final Animation<double> _fadeAnim;
  late final AnimationController _avatarPulseCtrl;
  late final Animation<double> _avatarPulseAnim;
  String _appVersion = '';

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
    _loadAppVersion();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    _avatarPulseCtrl.dispose();
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
            backgroundColor: DudeTheme.background,
            body: Center(
              child: CircularProgressIndicator(color: DudeTheme.accent, strokeWidth: 2),
            ),
          );
        }

        if (user == null) {
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
                      border: Border.all(color: DudeTheme.accent.withOpacity(0.3)),
                    ),
                    child: const Icon(
                      Icons.person_off_outlined,
                      color: DudeTheme.accent,
                      size: 28,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No user data',
                    style: TextStyle(
                      color: DudeTheme.textPrimary,
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
                        color: DudeTheme.accent,
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
                        child: _buildProfileHeader(user),
                      ),
                      const SizedBox(height: 20),
                      PremiumStaggerItem(
                        index: 2,
                        child: _buildWalletBanner(user),
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
                        child: _buildLogoutSection(context, userVM),
                      ),
                      const SizedBox(height: 20),
                      PremiumStaggerItem(
                        index: 6,
                        child: _buildSecureVersionFooter(),
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

  // ─────────────────────────────────────────────────────────────────────
  // TOP BAR
  // ─────────────────────────────────────────────────────────────────────

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
                      page: const MainBottomBar(index: 0),
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
              child: const Icon(
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
                page: const AccountSettingsScreen(),
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
              child: const Icon(
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

  Widget _buildProfileHeader(dynamic user) {
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
                      child: user.image != null &&
                              (user.image as String).isNotEmpty
                          ? Image.network(
                              user.image as String,
                              width: 72,
                              height: 72,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Image.asset(
                                'assets/Images/men.png',
                                fit: BoxFit.cover,
                              ),
                            )
                          : Image.asset(
                              'assets/Images/men.png',
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
                    user.name ?? 'User',
                    style: const TextStyle(
                      color: DudeTheme.textPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                    ),
                  ),
                  if (user.phone != null &&
                      user.phone.toString().isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      '+91 ${user.phone}',
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
                        'ID ${user.memberID}',
                      ),
                      _infoChip(
                        Icons.calendar_today_outlined,
                        'Since ${_formatJoinDate(user.createdAt)}',
                      ),
                      _infoChip(Icons.verified_rounded, 'Active', accent: true),
                    ],
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                bondNavigator.newPage(context, page: const EditProfileScreen());
              },
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: DudeTheme.accentDim,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: DudeTheme.accent.withValues(alpha: 0.4),
                  ),
                ),
                child: const Icon(
                  Icons.edit_rounded,
                  color: DudeTheme.accent,
                  size: 18,
                ),
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

  Widget _buildWalletBanner(dynamic user) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          bondNavigator.newPage(context, page: const WalletScreen());
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
                      'Wallet balance',
                      style: TextStyle(
                        color: DudeTheme.textOnAccent.withValues(alpha: 0.85),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${user.coinBalance ?? 0}',
                      style: const TextStyle(
                        color: DudeTheme.textOnAccent,
                        fontSize: 34,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                        height: 1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Tap to add coins',
                      style: TextStyle(
                        color: DudeTheme.textOnAccent.withValues(alpha: 0.75),
                        fontSize: 12,
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
                      Icons.add_rounded,
                      color: DudeTheme.textOnAccent,
                      size: 18,
                    ),
                    SizedBox(width: 4),
                    Text(
                      'Add',
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
        icon: Icons.receipt_long_rounded,
        label: 'Transactions',
        color: DudeTheme.accent,
        onTap: () => bondNavigator.newPage(
          context,
          page: const TransactionsScreen(backPage: true),
        ),
      ),
      _QuickAction(
        icon: Icons.card_giftcard_rounded,
        label: 'Refer & Earn',
        color: DudeTheme.accentBright,
        onTap: () => bondNavigator.newPage(
          context,
          page: const ReferEarnScreen(backPage: true),
        ),
      ),
      _QuickAction(
        icon: Icons.support_agent_rounded,
        label: 'Support',
        color: DudeTheme.warning,
        onTap: () =>
            bondNavigator.newPage(context, page: HelpAndSupportScreen()),
      ),
      _QuickAction(
        icon: Icons.mail_outline_rounded,
        label: 'Email us',
        color: DudeTheme.accentDeep,
        onTap: _launchEmail,
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
              style: const TextStyle(
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
                  icon: Icons.undo_rounded,
                  title: 'Refunds & Cancellations',
                  onTap: () => bondNavigator.newPage(
                    context,
                    page: const RefundsCancellationsScreen(),
                  ),
                ),
                _divider(),
                _compactMenuRow(
                  icon: Icons.privacy_tip_outlined,
                  title: 'Privacy Policy',
                  onTap: _openPrivacyPolicy,
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
                style: const TextStyle(
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
                child: const Icon(
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
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: DudeTheme.danger.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
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

  void _showLogoutDialog(BuildContext context, UserViewModel userVM) {
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
              // Icon
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: DudeTheme.dangerDim,
                  shape: BoxShape.circle,
                  border: Border.all(color: DudeTheme.danger.withOpacity(0.3)),
                ),
                child: const Icon(
                  Icons.logout_rounded,
                  color: DudeTheme.danger,
                  size: 26,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Logout',
                style: TextStyle(
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
                  // Cancel
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
                        child: const Text(
                          'Cancel',
                          style: TextStyle(
                            color: DudeTheme.textMid,
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
