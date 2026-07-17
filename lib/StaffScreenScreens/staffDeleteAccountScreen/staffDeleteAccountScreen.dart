import 'package:dude/DudeScreens/Splash/SplashScreen2.dart';
import 'package:dude/Dude_Utils/App_Theme/DudeTheme.dart';
import 'package:dude/Reusable_Widgets/Premium_UI/premium_ambient_background.dart';

import 'package:dude/StaffScreenScreens/StaffRegistrationScreen/ViewModel/StaffRegisterVM.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dude/Reusable_Widgets/AppText_Theme/AppText_Theme.dart';
import 'package:dude/Reusable_Widgets/BondingNavigator.dart';

class staffDeleteAccountScreen extends StatelessWidget {
  const staffDeleteAccountScreen({super.key});

  void _showConfirmDeleteDialog(BuildContext context) {
    final viewModel = Provider.of<StaffViewModel>(context, listen: false);

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: DudeTheme.surfaceRaised,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            "Confirm Delete",
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          content: const Text(
            "This will permanently delete your staff account.\nAll earnings history and profile data will be scheduled for deletion (30-day retention period applies).",
            style: TextStyle(color: Colors.white70, fontSize: 16, height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text("Cancel", style: TextStyle(color: DudeTheme.textMid, fontSize: 16),
              ),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(dialogContext);
                final result = await viewModel.deleteStaffAccount();

                if (result != null && result.status) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Staff account deleted successfully"),
                      backgroundColor: Colors.green,
                    ),
                  );
                  bondNavigator.newPageRemoveUntil(
                    context,
                    page: const SplashScreen2(),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        viewModel.errorMessage ??
                            "Failed to delete staff account",
                      ),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: const Text(
                "Confirm Delete",
                style: TextStyle(
                  color: Color(0xFFFF5A5F),
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
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
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Bar
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => bondNavigator.backPage(context),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: DudeTheme.surface,
                          borderRadius: BorderRadius.circular(40),
                          border: Border.all(color: Colors.white12),
                        ),
                        child: const Icon(
                          Icons.arrow_back,
                          color: Colors.white,
                          size: 26,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Text(
                      "Delete Account",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 40),

                const Text(
                  "Are you sure you want to delete your staff account?",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    height: 1.3,
                  ),
                ),

                const SizedBox(height: 32),

                _buildBulletPoint(
                  "All profile information, call history, and earnings records will be retained for 30 days and permanently deleted after no activity.",
                ),
                const SizedBox(height: 20),
                _buildBulletPoint(
                  "You will immediately lose access to staff features, and this action cannot be undone.",
                ),
                const SizedBox(height: 20),
                _buildBulletPoint(
                  "Pending payouts (if any) may be affected — please check your wallet before proceeding.",
                ),

                const Spacer(),

                // Continue Button with #aecc01 gradient
                GestureDetector(
                  onTap: () => _showConfirmDeleteDialog(context),
                  child: Container(
                    height: 46,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      gradient: DudeTheme.premiumAccentGradient,
                      boxShadow: [
                        BoxShadow(
                          color: DudeTheme.accent.withOpacity(0.4),
                          blurRadius: 15,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: const Text(
                      "Continue",
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Go Back Button
                GestureDetector(
                  onTap: () => bondNavigator.backPage(context),
                  child: Container(
                    height: 46,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: DudeTheme.textMid.withOpacity(0.4),
                      ),
                    ),
                    alignment: Alignment.center,
                    child: const Text(
                      "Go Back",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBulletPoint(String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 8),
          width: 7,
          height: 7,
          decoration: const BoxDecoration(
            color: DudeTheme.accent,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 15.5,
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }
}
