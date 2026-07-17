// lib/StaffScreenScreens/VerificationInprogressScreen/VerificationInprogressScreen.dart

import 'dart:async';
import 'package:dude/Dude_Utils/App_Theme/DudeTheme.dart';
import 'package:dude/Reusable_Widgets/Premium_UI/dude_logo.dart';
import 'package:dude/Reusable_Widgets/Premium_UI/premium_ambient_background.dart';
import 'package:dude/DudeScreens/LoginScreens/IdentityScreen/IdentityScreen.dart';
import 'package:dude/Reusable_Widgets/BondingNavigator.dart';
import 'package:dude/StaffScreenScreens/StaffRegistrationScreen/ViewModel/StaffRegisterVM.dart';
import 'package:dude/StaffScreenScreens/VerificationApprovedScreen/VerificationApprovedScreen.dart';
import 'package:dude/StaffScreenScreens/VerificationUnsuccessfulScreen/VerificationUnsuccessScreen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class VerificationInprogressScreen extends StatefulWidget {
  const VerificationInprogressScreen({super.key});

  @override
  State<VerificationInprogressScreen> createState() =>
      _VerificationInprogressScreenState();
}

class _VerificationInprogressScreenState
    extends State<VerificationInprogressScreen> {
  Timer? _pollingTimer;

  @override
  void initState() {
    super.initState();
    _startPolling();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<StaffViewModel>().fetchStaffSingleData();
    });
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  void _startPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (!mounted) return;
      context.read<StaffViewModel>().fetchStaffSingleData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<StaffViewModel>(
      builder: (context, staffVM, child) {
        final staff = staffVM.currentStaff;

        if (staff == null) {
          return Scaffold(
            backgroundColor: DudeTheme.background,
            body: PremiumAmbientBackground(
              child: const Center(
                child: CircularProgressIndicator(color: DudeTheme.accent),
              ),
            ),
          );
        }

        final status = staff.isApproved?.toString().trim() ?? '0';
        final isApprovedNow = status == '1' || status == 'approved';
        final isRejected =
            status == '2' || status == 'rejected' || status == 'declined';

        // Auto-navigation (safe, post-frame)
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (isApprovedNow) {
            _pollingTimer?.cancel();
            bondNavigator.newPageRemoveUntil(
              context,
              page: const ApprovedScreen(),
            );
          } else if (isRejected) {
            _pollingTimer?.cancel();
            bondNavigator.newPageRemoveUntil(
              context,
              page: const VerificationUnsuccessScreen(),
            );
          }
        });

        return Scaffold(
          backgroundColor: DudeTheme.background,
          body: PremiumAmbientBackground(
            child: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 30),
                child: Column(
                  children: [
                    const DudeLogo(height: 54),
                    const SizedBox(height: 44),
                    _reviewIndicator(),
                    const SizedBox(height: 30),
                    const Text(
                      "Your profile is in review",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 27,
                        height: 1.2,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.6,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      "Thanks — we have everything we need. The Dude team is checking your details now.",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: DudeTheme.textSubtle,
                        fontSize: 15,
                        height: 1.55,
                      ),
                    ),
                    const SizedBox(height: 28),
                    Container(
                      padding: const EdgeInsets.fromLTRB(18, 20, 18, 20),
                      decoration: BoxDecoration(
                        color: DudeTheme.surface.withValues(alpha: 0.92),
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: DudeTheme.borderSubtle),
                        boxShadow: DudeTheme.softShadow,
                      ),
                      child: const Column(
                        children: [
                          _ReviewStep(
                            icon: Icons.check_rounded,
                            title: "Details submitted",
                            subtitle: "Your ID and selfie were uploaded",
                            complete: true,
                          ),
                          _StepLine(active: true),
                          _ReviewStep(
                            icon: Icons.manage_search_rounded,
                            title: "Review in progress",
                            subtitle: "Our team is verifying your profile",
                            active: true,
                          ),
                          _StepLine(),
                          _ReviewStep(
                            icon: Icons.verified_outlined,
                            title: "Final decision",
                            subtitle: "We’ll update your account automatically",
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: DudeTheme.accentDim.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.notifications_none_rounded,
                            color: DudeTheme.accentBright,
                            size: 21,
                          ),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              "Most reviews finish within 24–48 hours. You can safely close the app — we’ll keep your status updated.",
                              style: TextStyle(
                                color: DudeTheme.textMuted,
                                fontSize: 13,
                                height: 1.45,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isRejected) ...[
                      const SizedBox(height: 20),
                      _buildRetryButton(context),
                    ],
                  ],
                ),
              ),
            ),
          ),
          bottomNavigationBar: Container(
            color: Colors.transparent,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                child: isApprovedNow || isRejected
                    ? const SizedBox.shrink()
                    : Container(
                        height: 54,
                        decoration: BoxDecoration(
                          color: DudeTheme.surfaceRaised,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: DudeTheme.borderSubtle),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                color: DudeTheme.accent,
                                strokeWidth: 2.2,
                              ),
                            ),
                            SizedBox(width: 11),
                            Text(
                              "Review in progress",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
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

  Widget _buildRetryButton(BuildContext context) {
    return GestureDetector(
      onTap: () => bondNavigator.newPage(context, page: const IdentityScreen()),
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: DudeTheme.premiumAccentGradient,
        ),
        child: const Center(
          child: Text(
            "Try verification again  →",
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _reviewIndicator() => SizedBox(
    width: 132,
    height: 132,
    child: Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 108,
          height: 108,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: DudeTheme.accentDim,
            boxShadow: DudeTheme.accentGlowShadow(blur: 30),
          ),
        ),
        const SizedBox(
          width: 132,
          height: 132,
          child: CircularProgressIndicator(
            value: 0.68,
            strokeWidth: 3,
            backgroundColor: DudeTheme.borderSubtle,
            color: DudeTheme.accentBright,
          ),
        ),
        const Icon(
          Icons.verified_user_outlined,
          color: DudeTheme.accentBright,
          size: 48,
        ),
      ],
    ),
  );
}

class _ReviewStep extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool active;
  final bool complete;

  const _ReviewStep({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.active = false,
    this.complete = false,
  });

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: (active || complete)
              ? DudeTheme.accentDim
              : DudeTheme.surfaceRaised,
          border: Border.all(
            color: (active || complete)
                ? DudeTheme.accent
                : DudeTheme.borderSubtle,
          ),
        ),
        child: Icon(
          icon,
          size: 21,
          color: (active || complete)
              ? DudeTheme.accentBright
              : DudeTheme.textSubtle,
        ),
      ),
      const SizedBox(width: 13),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                color: (active || complete)
                    ? Colors.white
                    : DudeTheme.textMuted,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              subtitle,
              style: const TextStyle(
                color: DudeTheme.textSubtle,
                fontSize: 12,
                height: 1.3,
              ),
            ),
          ],
        ),
      ),
    ],
  );
}

class _StepLine extends StatelessWidget {
  final bool active;
  const _StepLine({this.active = false});

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.centerLeft,
    child: Container(
      width: 2,
      height: 22,
      margin: const EdgeInsets.only(left: 20),
      color: active ? DudeTheme.accent : DudeTheme.borderSubtle,
    ),
  );
}
