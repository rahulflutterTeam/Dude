import 'package:dude/DudeScreens/BlockedUsers/BlockUserScreen.dart';
import 'package:dude/DudeScreens/DeleteAccountScreeen/DeleteAccountScreen.dart';
import 'package:dude/DudeScreens/ReportOverview/ReportOverviewScreen.dart';
import 'package:dude/Dude_Utils/App_Theme/DudeTheme.dart';
import 'package:dude/Dude_Utils/CustomSnackBar/StatusMessage.dart';
import 'package:dude/Reusable_Widgets/AppText_Theme/AppText_Theme.dart';
import 'package:dude/Reusable_Widgets/BondingNavigator.dart';
import 'package:dude/Reusable_Widgets/Premium_UI/premium_ambient_background.dart';
import 'package:dude/Reusable_Widgets/Premium_UI/premium_glass_card.dart';
import 'package:dude/StaffScreenScreens/staffDeleteAccountScreen/staffDeleteAccountScreen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

class staffAccountSettingsScreen extends StatefulWidget {
  const staffAccountSettingsScreen({super.key});

  @override
  State<staffAccountSettingsScreen> createState() =>
      _staffAccountSettingsScreenState();
}

class _staffAccountSettingsScreenState
    extends State<staffAccountSettingsScreen> {
  Future<void> _openPrivacyPolicy() async {
    const String privacyUrl = "https://dudee.online/privacy";

    final Uri url = Uri.parse(privacyUrl);
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      Utils.snackBarErrorMessage("Could not open Privacy Policy");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DudeTheme.background,
      body: PremiumAmbientBackground(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        bondNavigator.backPage(context);
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
                    const SizedBox(width: 16),
                    Text(
                      "Account Settings",
                      style: TextStyle(
                        color: DudeTheme.textPrimary,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Settings List
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      _buildSettingsItem(
                        icon: Icons.privacy_tip_outlined,
                        title: "Privacy Policy",
                        onTap: () {
                          _openPrivacyPolicy();
                        },
                      ),
                      const SizedBox(height: 12),
                      // _buildSettingsItem(
                      //   icon: Icons.block_outlined,
                      //   title: "Blocked Users",
                      //   onTap: () {
                      //     bondNavigator.newPage(context, page: const BlockedUsersScreen());
                      //   },
                      // ),
                      // const SizedBox(height: 12),
                      // _buildSettingsItem(
                      //   icon: Icons.report_outlined,
                      //   title: "Report Overview",
                      //   onTap: () {
                      //     bondNavigator.newPage(context, page: const ReportOverviewScreen());
                      //   },
                      // ),
                      // const SizedBox(height: 12),
                      _buildSettingsItem(
                        icon: Icons.delete_outline,
                        title: "Delete Account",
                        onTap: () {
                          bondNavigator.newPage(
                            context,
                            page: const staffDeleteAccountScreen(),
                          );
                        },
                        isDestructive: true,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: PremiumGlassCard(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        radius: 16,
        child: Row(
          children: [
            Icon(
              icon,
              color: isDestructive ? DudeTheme.danger : DudeTheme.accent,
              size: 26,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: isDestructive
                      ? DudeTheme.danger
                      : DudeTheme.textPrimary,
                  fontSize: 16.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              color: isDestructive
                  ? DudeTheme.danger.withValues(alpha: 0.7)
                  : DudeTheme.textSubtle,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
