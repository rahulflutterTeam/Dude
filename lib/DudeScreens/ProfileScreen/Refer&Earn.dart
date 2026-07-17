import 'package:dude/Dude_Utils/App_Theme/DudeTheme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:dude/DudeScreens/LoginScreens/Model/referralModel.dart';
import 'package:dude/DudeScreens/LoginScreens/ViewModel/ReferralVM.dart';

class ReferEarnScreen extends StatefulWidget {
  final bool backPage;
  const ReferEarnScreen({super.key, required this.backPage});

  @override
  State<ReferEarnScreen> createState() => _ReferEarnScreenState();
}

class _ReferEarnScreenState extends State<ReferEarnScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _fadeCtrl;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _fadeCtrl.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ReferralViewModel>().fetchReferralDashboard();
    });
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  String _buildInviteMessage(String inviteCode, String shareLink) {
    return "Join Dude App and make real friends!❤️\nUse my code $inviteCode to sign up.\n\nDownload now: $shareLink";
  }

  Future<void> _shareInvite(String inviteCode, String shareLink) async {
    final message = _buildInviteMessage(inviteCode, shareLink);
    final box = context.findRenderObject() as RenderBox?;

    await SharePlus.instance.share(
      ShareParams(
        text: message,
        subject: 'Join me on Dude',
        title: 'Invite Friends',
        sharePositionOrigin: box == null
            ? null
            : box.localToGlobal(Offset.zero) & box.size,
      ),
    );
  }

  Future<void> _copyInviteMessage(String inviteCode, String shareLink) async {
    final message = _buildInviteMessage(inviteCode, shareLink);
    await Clipboard.setData(ClipboardData(text: message));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invite message copied!'),
          backgroundColor: DudeTheme.accent,
          duration: Duration(seconds: 1),
        ),
      );
    }
  }

  Future<void> _copyInviteCode(String inviteCode) async {
    await Clipboard.setData(ClipboardData(text: inviteCode));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Code copied to clipboard!'),
          backgroundColor: DudeTheme.accent,
          duration: Duration(seconds: 1),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ReferralViewModel>(
      builder: (context, vm, child) {
        final data = vm.dashboardData?.data;

        return Scaffold(
          backgroundColor: DudeTheme.background,
          body: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [DudeTheme.accentDim, DudeTheme.background],
              ),
            ),
            child: SafeArea(
              child: FadeTransition(
                opacity: _fadeAnim,
                child: vm.isLoading
                    ? const Center(
                        child: CircularProgressIndicator(color: DudeTheme.accent),
                      )
                    : vm.errorMessage != null
                    ? _buildErrorState(vm)
                    : _buildMainContent(data),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildErrorState(ReferralViewModel vm) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: Colors.redAccent, size: 60),
          const SizedBox(height: 16),
          Text(
            vm.errorMessage!,
            style: const TextStyle(color: DudeTheme.textMid),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () => vm.fetchReferralDashboard(),
            style: ElevatedButton.styleFrom(
              backgroundColor: DudeTheme.accent,
              foregroundColor: Colors.black,
            ),
            child: const Text('Retry Now'),
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent(ReferralData? data) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        children: [
          _buildCustomAppBar(),
          const SizedBox(height: 20),
          _buildHeroSection(),
          const SizedBox(height: 24),
          _buildModernStats(data),
          const SizedBox(height: 24),
          _buildReferralCard(data),
          const SizedBox(height: 30),
          _buildActionButtons(data),
          const SizedBox(height: 40),
          _buildStepByStepGuide(data),
          const SizedBox(height: 40),
          _buildTermsAndConditions(),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildCustomAppBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: DudeTheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: DudeTheme.border),
              ),
              child: const Icon(
                Icons.arrow_back_ios_new,
                color: DudeTheme.textPrimary,
                size: 18,
              ),
            ),
          ),
          const Expanded(
            child: Text(
              'Refer & Earn',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: DudeTheme.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 42),
        ],
      ),
    );
  }

  Widget _buildHeroSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          const Text(
            'Share the love, earn coins!',
            style: TextStyle(
              color: DudeTheme.textPrimary,
              fontSize: 26,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          const Text(
            'Invite your best friends to Dude and unlock exclusive rewards together.',
            style: TextStyle(color: DudeTheme.textSubtle, fontSize: 14, height: 1.5),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildModernStats(ReferralData? data) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          _statCard(
            'Invites',
            '${data?.myInvites ?? 0}',
            Icons.people_alt_rounded,
            DudeTheme.accent,
          ),
          const SizedBox(width: 16),
          _statCard(
            'Per Referral',
            '${data?.perInvite ?? 0}',
            Icons.stars_rounded,
            DudeTheme.accent,
          ),
        ],
      ),
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: DudeTheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: DudeTheme.border),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                color: DudeTheme.textPrimary,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(label, style: const TextStyle(color: DudeTheme.textSubtle, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildReferralCard(ReferralData? data) {
    final code = data?.inviteCode ?? 'LOADING';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [DudeTheme.accentDim, DudeTheme.surface]),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: DudeTheme.accent.withValues(alpha: 0.4),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: DudeTheme.accent.withValues(alpha: 0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: DudeTheme.accent.withValues(alpha: 0.2),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'MY REFERRAL CODE',
                    style: TextStyle(
                      color: DudeTheme.accent,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const Icon(
                    Icons.confirmation_number_outlined,
                    color: DudeTheme.accent,
                    size: 20,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      code,
                      style: const TextStyle(
                        color: DudeTheme.accent,
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 4,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => _copyInviteCode(code),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: DudeTheme.accent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.copy_all_rounded,
                        color: Colors.black,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: DudeTheme.border)),
              ),
              child: Column(
                children: [
                  const Text(
                    'Total Rewards Earned',
                    style: TextStyle(color: DudeTheme.textSubtle, fontSize: 13),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset("assets/Images/paircoin.png"),
                      const SizedBox(width: 8),
                      Text(
                        '${data?.totalCoinsEarned ?? 0}',
                        style: const TextStyle(
                          color: DudeTheme.textPrimary,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
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

  Widget _buildActionButtons(ReferralData? data) {
    final inviteCode = data?.inviteCode ?? '';
    final shareLink =
        data?.shareLink ??
        'https://play.google.com/store/apps/details?id=com.dude.dudeapp';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          GestureDetector(
            onTap: () {
              HapticFeedback.mediumImpact();
              _shareInvite(inviteCode, shareLink);
            },
            child: Container(
              height: 56,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [DudeTheme.accent, Color(0xFF9CC21C)],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: DudeTheme.accent.withValues(alpha: 0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.ios_share_rounded,
                    color: Colors.black,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Share Invite',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              _copyInviteMessage(inviteCode, shareLink);
            },
            child: Container(
              height: 56,
              decoration: BoxDecoration(
                color: DudeTheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: DudeTheme.border),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.content_copy_rounded,
                    color: DudeTheme.accent,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Copy Invite Message',
                    style: TextStyle(
                      color: DudeTheme.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepByStepGuide(ReferralData? data) {
    final perInvite = data?.perInvite ?? 20;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'How to get rewards?',
            style: TextStyle(
              color: DudeTheme.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          _stepItem(
            '1',
            'Share Your Code',
            'Send your unique code to your friends.',
            Icons.share_rounded,
            false,
          ),
          _stepItem(
            '2',
            'Friend Signs Up',
            'Friend registers using your referral code.',
            Icons.person_add_rounded,
            false,
          ),
          _stepItem(
            '3',
            'Minimum Purchase',
            'Friend adds the minimum required amount to their wallet.',
            Icons.wallet_rounded,
            false,
          ),
          _stepItem(
            '4',
            'Get $perInvite Coins',
            'Bonus coins are credited to your account!',
            Icons.celebration_rounded,
            true,
          ),
        ],
      ),
    );
  }

  Widget _stepItem(
    String num,
    String title,
    String desc,
    IconData icon,
    bool isLast,
  ) {
    return IntrinsicHeight(
      child: Row(
        children: [
          Column(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: DudeTheme.accent,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    num,
                    style: const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              if (!isLast)
                Expanded(child: Container(width: 2, color: DudeTheme.border)),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: DudeTheme.textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(icon, color: DudeTheme.textMid, size: 16),
                  ],
                ),
                Text(
                  desc,
                  style: const TextStyle(color: DudeTheme.textSubtle, fontSize: 13),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTermsAndConditions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: DudeTheme.surface.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: DudeTheme.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.info_outline, color: DudeTheme.accent, size: 16),
                SizedBox(width: 8),
                Text(
                  'Terms & Conditions',
                  style: TextStyle(
                    color: DudeTheme.accent,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            const Text(
              '• Bonus coins credited after friend completes the minimum required purchase\n• Minimum wallet deposit required for reward eligibility\n• Bonus credited within 24 hours\n• Bonus coins are non-withdrawable',
              style: TextStyle(color: DudeTheme.textSubtle, fontSize: 11, height: 1.6),
            ),
          ],
        ),
      ),
    );
  }
}
