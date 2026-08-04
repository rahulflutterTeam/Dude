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

  void _openMaleFlow() {
    HapticFeedback.mediumImpact();
    setState(() => selectedAccount = 1);
    Future.delayed(const Duration(milliseconds: 180), () {
      if (!mounted) return;
      bondNavigator.newPage(context, page: const LoginScreen());
    });
  }

  void _openFemaleFlow() {
    HapticFeedback.mediumImpact();
    setState(() => selectedAccount = 2);
    Future.delayed(const Duration(milliseconds: 180), () {
      if (!mounted) return;
      bondNavigator.newPage(context, page: const StaffRegisterNew());
    });
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
                        accent: const Color(0xFF6EC8FF),
                        isSelected: selectedAccount == 1,
                        onTap: _openMaleFlow,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: _GenderGlassCard(
                        imagePath: 'assets/Images/women.png',
                        label: 'Female',
                        accent: DudeTheme.accent,
                        isSelected: selectedAccount == 2,
                        onTap: _openFemaleFlow,
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
  final Color accent;
  final bool isSelected;
  final VoidCallback onTap;

  const _GenderGlassCard({
    required this.imagePath,
    required this.label,
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
