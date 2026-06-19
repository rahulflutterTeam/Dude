// lib/StaffScreenScreens/VerificationInprogressScreen/VerificationInprogressScreen.dart

import 'dart:async';
import 'package:dude/DudeScreens/LoginScreens/IdentityScreen/IdentityScreen.dart';
import 'package:dude/Reusable_Widgets/AppText_Theme/AppText_Theme.dart';
import 'package:dude/Reusable_Widgets/BondingNavigator.dart';
import 'package:dude/StaffScreenScreens/StaffRegistrationScreen/ViewModel/StaffRegisterVM.dart';
import 'package:dude/StaffScreenScreens/VerificationApprovedScreen/VerificationApprovedScreen.dart';
import 'package:dude/StaffScreenScreens/VerificationUnsuccessfulScreen/VerificationUnsuccessScreen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
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

        // Debug: show real status every rebuild
        print(
          "Current staff isApproved: ${staff?.isApproved} (raw: ${staff?.isApproved.runtimeType})",
        );

        if (staff == null) {
          return const Scaffold(
            backgroundColor: Color(0xFF140810),
            body: Center(child: CircularProgressIndicator(color: Colors.white)),
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
          backgroundColor: const Color(0xFF140810),
          body: Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF241b40), // top
                  Color(0xFF1C1426),
                  Color(0xFF12151c),
                  Color(0xFF12151c),
                  Color(0xFF12151c),
                  Color(0xFF2b1e4e),
                ],
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 10),
                    SvgPicture.asset("assets/Images/dude.svg", height: 50),

                    const SizedBox(height: 30),
                    Center(
                      child: Image.asset(
                        "assets/Images/verification.png",
                        height: 200,
                      ),
                    ),
                    const SizedBox(height: 30),
                    Center(
                      child: AppText(
                        "Verification Under Review",
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Center(
                      child: AppText(
                        "We’ve received your documents successfully.\nOur team is currently reviewing your profile.\nThis process usually takes 24–48 hours.",
                        color: const Color(0xFFc7c7cc),
                        fontSize: 16,
                        textAlign: TextAlign.center,
                        maxLines: 5,
                      ),
                    ),
                    const Spacer(),
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
            color: Color(0xFF2b1e4e),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: isApprovedNow || isRejected
                    ? const SizedBox.shrink()
                    : Opacity(
                        opacity: 0.6,
                        child: Container(
                          height: 52,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            gradient: const LinearGradient(
                              colors: [Color(0xFFaecc01), Color(0xFFaecc01)],
                            ),
                          ),
                          child: const Center(
                            child: Text(
                              "Waiting for Approval...",
                              style: TextStyle(
                                color: Colors.black87,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
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
          borderRadius: BorderRadius.circular(12),
          gradient: const LinearGradient(
            colors: [Color(0xFFFF6A6A), Color(0xFFB86AF6)],
          ),
        ),
        child: const Center(
          child: Text(
            "Re-upload Documents →",
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
}
