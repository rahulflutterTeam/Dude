import 'package:dude/DudeScreens/BlockedUsers/BlockUserScreen.dart';
import 'package:dude/DudeScreens/DeleteAccountScreeen/DeleteAccountScreen.dart';
import 'package:dude/DudeScreens/ProfileScreen/CommunityGuideline.dart';
import 'package:dude/DudeScreens/ProfileScreen/RefundPolicy.dart';
import 'package:dude/DudeScreens/ProfileScreen/privacypolicyScreen.dart';
import 'package:dude/DudeScreens/RefundScreen/TermsandCondition.dart';
import 'package:dude/DudeScreens/ReportOverview/ReportOverviewScreen.dart';
import 'package:dude/Dude_Utils/CustomSnackBar/StatusMessage.dart';
import 'package:dude/Reusable_Widgets/AppText_Theme/AppText_Theme.dart';
import 'package:dude/Reusable_Widgets/BondingNavigator.dart';
import 'package:dude/Dude_Utils/App_Theme/DudeTheme.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class AccountSettingsScreen extends StatefulWidget {
  const AccountSettingsScreen({super.key});

  @override
  State<AccountSettingsScreen> createState() => _AccountSettingsScreenState();
}

class _AccountSettingsScreenState extends State<AccountSettingsScreen> {
  Future<void> _openPrivacyPolicy() async {
    const String privacyUrl =
        "https://www.pair-ever.com/privacy-policy"; // Change this to your actual URL

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
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: DudeTheme.backgroundGradient,
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Top Bar
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        bondNavigator.backPage(context);
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: DudeTheme.surfaceRaised, // Updated color
                          borderRadius: BorderRadius.circular(40),
                        ),
                        child: const Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Icon(Icons.arrow_back, color: Colors.white),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    AppText(
                      "Account Settings",
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Settings List
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    children: [
                      _buildSettingsItem(
                        icon: Icons.privacy_tip_outlined,
                        title: "Privacy Policy",
                        onTap: () {
                          bondNavigator.newPage(
                            context,
                            page: const PrivacyPolicyScreen(),
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                      _buildSettingsItem(
                        icon: Icons.description_outlined,
                        title: "Terms & Conditions",
                        onTap: () {
                          bondNavigator.newPage(
                            context,
                            page: const TermsAndConditionsScreen(),
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                      _buildSettingsItem(
                        icon: Icons.group_outlined, // or any suitable icon
                        title: "Community Guidelines",
                        onTap: () {
                          bondNavigator.newPage(
                            context,
                            page: const CommunityGuidelinesScreen(),
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                      _buildSettingsItem(
                        icon: Icons
                            .refresh_outlined, // or Icons.money_off, Icons.receipt_long, etc.
                        title: "Refund Policy",
                        onTap: () {
                          bondNavigator.newPage(
                            context,
                            page: const RefundPolicyScreen(),
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                      _buildSettingsItem(
                        icon: Icons.delete_outline,
                        title: "Delete Account",
                        onTap: () {
                          bondNavigator.newPage(
                            context,
                            page: DeleteAccountScreen(),
                          );
                        },
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
    Color? iconColor,
    Color? titleColor,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [DudeTheme.surface, DudeTheme.surfaceRaised, DudeTheme.surfaceRaised],
          ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: DudeTheme.surfaceRaised, width: 1),
        ),
        child: Row(
          children: [
            Icon(icon, color: iconColor ?? DudeTheme.textMid, size: 28),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: titleColor ?? Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: Colors.grey[400], size: 18),
          ],
        ),
      ),
    );
  }
}
