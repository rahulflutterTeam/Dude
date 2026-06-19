import 'package:dude/DudeScreens/BlockedUsers/BlockUserScreen.dart';
import 'package:dude/DudeScreens/DeleteAccountScreeen/DeleteAccountScreen.dart';
import 'package:dude/DudeScreens/ReportOverview/ReportOverviewScreen.dart';
import 'package:dude/Dude_Utils/CustomSnackBar/StatusMessage.dart';
import 'package:dude/Reusable_Widgets/AppText_Theme/AppText_Theme.dart';
import 'package:dude/Reusable_Widgets/BondingNavigator.dart';
import 'package:dude/StaffScreenScreens/staffDeleteAccountScreen/staffDeleteAccountScreen.dart';
import 'package:flutter/material.dart';
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
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF241b40),
              Color(0xFF1C1426),
              Color(0xFF12151c),
              Color(0xFF12151c),
              Color(0xFF12151c),
              Color(0xFF2b1e4e),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Top Bar
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => bondNavigator.backPage(context),
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF2A1F38),
                          borderRadius: BorderRadius.circular(40),
                          border: Border.all(color: Colors.white12),
                        ),
                        padding: const EdgeInsets.all(10),
                        child: const Icon(
                          Icons.arrow_back,
                          color: Colors.white,
                          size: 26,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Text(
                      "Account Settings",
                      style: TextStyle(
                        color: Colors.white,
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
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF2A1F38), Color(0xFF1C1426)],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF3A2A4A)),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isDestructive ? Colors.redAccent : const Color(0xFFB86AF6),
              size: 26,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: isDestructive ? Colors.redAccent : Colors.white,
                  fontSize: 16.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              color: isDestructive
                  ? Colors.redAccent.withOpacity(0.7)
                  : Colors.grey[400],
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
