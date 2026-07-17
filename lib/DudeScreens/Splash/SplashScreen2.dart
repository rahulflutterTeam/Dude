import 'package:dude/AccountSelectScreen/AccountSelectScreen.dart';
import 'package:dude/Dude_Utils/App_Theme/DudeTheme.dart';
import 'package:dude/Reusable_Widgets/BondingNavigator.dart';
import 'package:dude/Reusable_Widgets/Premium_UI/dude_logo.dart';
import 'package:dude/Reusable_Widgets/Premium_UI/premium_ambient_background.dart';
import 'package:dude/Reusable_Widgets/Premium_UI/premium_glass_card.dart';
import 'package:flutter/material.dart';

class SplashScreen2 extends StatefulWidget {
  const SplashScreen2({super.key});

  @override
  State<SplashScreen2> createState() => _SplashScreen2State();
}

class _SplashScreen2State extends State<SplashScreen2> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DudeTheme.background,
      body: PremiumAmbientBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              children: [
                const Spacer(),
                const DudeLogo(height: 110),
                const SizedBox(height: 36),
                ShaderMask(
                  blendMode: BlendMode.srcIn,
                  shaderCallback: (bounds) =>
                      DudeTheme.premiumAccentGradient.createShader(bounds),
                  child: const Text(
                    'Vibes that hit different',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 30,
                      fontWeight: FontWeight.w900,
                      height: 1.15,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'Match with real people, spark deep chats, and make every call feel personal.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: DudeTheme.textMuted.withValues(alpha: 0.92),
                    fontSize: 15.5,
                    height: 1.55,
                  ),
                ),
                const SizedBox(height: 28),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 10,
                  runSpacing: 10,
                  children: const [
                    _VibeChip(icon: Icons.favorite_rounded, label: 'Real matches'),
                    _VibeChip(icon: Icons.chat_bubble_rounded, label: 'Live chats'),
                    _VibeChip(icon: Icons.videocam_rounded, label: 'Video calls'),
                  ],
                ),
                const SizedBox(height: 36),
                PremiumPrimaryButton(
                  label: 'Let\'s go →',
                  height: 56,
                  onTap: () {
                    bondNavigator.newPage(
                      context,
                      page: const AccountSelectScreen(),
                    );
                  },
                ),
                const Spacer(flex: 2),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _VibeChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _VibeChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: DudeTheme.surface.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: DudeTheme.border.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: DudeTheme.accent),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: DudeTheme.textMuted,
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
