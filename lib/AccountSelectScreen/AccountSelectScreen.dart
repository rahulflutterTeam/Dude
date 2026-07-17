import 'dart:ui';

import 'package:dude/DudeScreens/LoginScreens/LoginScreen.dart';
import 'package:dude/Dude_Utils/App_Theme/DudeTheme.dart';
import 'package:dude/Reusable_Widgets/BondingNavigator.dart';
import 'package:dude/Reusable_Widgets/Premium_UI/dude_logo.dart';
import 'package:dude/Reusable_Widgets/Premium_UI/premium_ambient_background.dart';
import 'package:dude/Reusable_Widgets/Premium_UI/premium_animations.dart';
import 'package:dude/StaffScreenScreens/StaffRegistrationScreen/staffregisterNew.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AccountSelectScreen extends StatefulWidget {
  const AccountSelectScreen({super.key});

  @override
  State<AccountSelectScreen> createState() => _AccountSelectScreenState();
}

class _AccountSelectScreenState extends State<AccountSelectScreen> {
  int selectedAccount = 0;

  void _openDiscoverPeopleFlow() {
    HapticFeedback.mediumImpact();
    setState(() => selectedAccount = 1);
    Future.delayed(const Duration(milliseconds: 180), () {
      if (!mounted) return;
      bondNavigator.newPage(context, page: const LoginScreen());
    });
  }

  void _openBeActiveFlow() {
    HapticFeedback.mediumImpact();
    setState(() => selectedAccount = 2);
    Future.delayed(const Duration(milliseconds: 180), () {
      if (!mounted) return;
      _showBeActiveRoleDialog();
    });
  }

  Future<void> _showBeActiveRoleDialog() async {
    await showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.72),
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
              child: Container(
                padding: const EdgeInsets.fromLTRB(22, 16, 22, 22),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      DudeTheme.surface.withValues(alpha: 0.95),
                      DudeTheme.background.withValues(alpha: 0.92),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: DudeTheme.accent.withValues(alpha: 0.35),
                  ),
                  boxShadow: DudeTheme.accentGlowShadow(blur: 28, spread: -6),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Align(
                      alignment: Alignment.centerRight,
                      child: IconButton(
                        onPressed: () => Navigator.of(dialogContext).pop(),
                        icon: const Icon(
                          Icons.close_rounded,
                          color: DudeTheme.textMuted,
                        ),
                      ),
                    ),
                    Container(
                      width: 68,
                      height: 68,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: DudeTheme.premiumAccentGradient,
                        boxShadow: DudeTheme.accentGlowShadow(blur: 20),
                      ),
                      child: const Icon(
                        Icons.how_to_reg_rounded,
                        color: DudeTheme.textOnAccent,
                        size: 34,
                      ),
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'Continue as',
                      style: TextStyle(
                        color: DudeTheme.textPrimary,
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Pick the experience that fits you best.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: DudeTheme.textMuted.withValues(alpha: 0.9),
                        fontSize: 14,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 22),
                    _RoleOption(
                      icon: Icons.person_search_rounded,
                      title: 'User',
                      subtitle: 'Discover people & start connecting',
                      onTap: () {
                        Navigator.of(dialogContext).pop();
                        bondNavigator.newPage(context, page: const LoginScreen());
                      },
                    ),
                    const SizedBox(height: 12),
                    _RoleOption(
                      icon: Icons.verified_user_rounded,
                      title: 'Host',
                      subtitle: 'Go live, earn & build your audience',
                      onTap: () {
                        Navigator.of(dialogContext).pop();
                        bondNavigator.newPage(
                          context,
                          page: const StaffRegisterNew(),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DudeTheme.background,
      body: PremiumAmbientBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                const SizedBox(height: 12),
                const Center(child: DudeLogo(height: 150)),

                const Text(
                  'Who are you?',
                  style: TextStyle(
                    color: DudeTheme.textPrimary,
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Tap your gender to continue — we\'ll tailor your experience.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: DudeTheme.textMuted.withValues(alpha: 0.9),
                    fontSize: 15,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 36),
                Row(
                  children: [
                    Expanded(
                      child: _GenderGlassCard(
                        imagePath: 'assets/Images/men.png',
                        label: 'Male',
                        subtitle: '',
                        accent: const Color(0xFF6EC8FF),
                        isSelected: selectedAccount == 1,
                        onTap: _openDiscoverPeopleFlow,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: _GenderGlassCard(
                        imagePath: 'assets/Images/women.png',
                        label: 'Female',
                        subtitle: '',
                        accent: DudeTheme.accent,
                        isSelected: selectedAccount == 2,
                        onTap: _openBeActiveFlow,
                      ),
                    ),
                  ],
                ),
                const Spacer(),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GenderGlassCard extends StatefulWidget {
  final String imagePath;
  final String label;
  final String subtitle;
  final Color accent;
  final bool isSelected;
  final VoidCallback onTap;

  const _GenderGlassCard({
    required this.imagePath,
    required this.label,
    required this.subtitle,
    required this.accent,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_GenderGlassCard> createState() => _GenderGlassCardState();
}

class _GenderGlassCardState extends State<_GenderGlassCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? 0.96 : 1,
        duration: PremiumAnimations.fast,
        curve: PremiumAnimations.bounce,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOutCubic,
          height: 220,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: widget.isSelected
                  ? widget.accent.withValues(alpha: 0.9)
                  : DudeTheme.border.withValues(alpha: 0.45),
              width: widget.isSelected ? 1.8 : 1,
            ),
            boxShadow: widget.isSelected
                ? [
                    BoxShadow(
                      color: widget.accent.withValues(alpha: 0.35),
                      blurRadius: 24,
                      spreadRadius: -2,
                    ),
                  ]
                : DudeTheme.softShadow,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: widget.isSelected
                        ? [
                            widget.accent.withValues(alpha: 0.14),
                            DudeTheme.surface.withValues(alpha: 0.88),
                          ]
                        : [
                            DudeTheme.surface.withValues(alpha: 0.82),
                            DudeTheme.surfaceRaised.withValues(alpha: 0.72),
                          ],
                  ),
                ),
                child: Column(
                  children: [
                    const SizedBox(height: 18),
                    Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            widget.accent.withValues(alpha: 0.45),
                            widget.accent.withValues(alpha: 0.08),
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: widget.accent.withValues(alpha: 0.35),
                            blurRadius: 18,
                            spreadRadius: -2,
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(3),
                      child: Container(
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: DudeTheme.background,
                        ),
                        padding: const EdgeInsets.all(3),
                        child: ClipOval(
                          child: Image.asset(
                            widget.imagePath,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: double.infinity,
                            errorBuilder: (_, __, ___) => Icon(
                              widget.label == 'Male'
                                  ? Icons.man_rounded
                                  : Icons.woman_rounded,
                              size: 44,
                              color: widget.accent,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      widget.label,
                      style: TextStyle(
                        color: widget.isSelected
                            ? DudeTheme.textPrimary
                            : DudeTheme.textMuted,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.subtitle,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: DudeTheme.textSubtle.withValues(alpha: 0.85),
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RoleOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _RoleOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        child: Ink(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: DudeTheme.surfaceRaised.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: DudeTheme.border.withValues(alpha: 0.4)),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: DudeTheme.premiumAccentGradient,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: DudeTheme.textOnAccent, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: DudeTheme.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: DudeTheme.textMuted.withValues(alpha: 0.85),
                        fontSize: 12.5,
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                color: DudeTheme.textSubtle.withValues(alpha: 0.7),
                size: 15,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
