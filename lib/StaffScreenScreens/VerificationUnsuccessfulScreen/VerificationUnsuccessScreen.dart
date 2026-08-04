import 'package:dude/DudeScreens/LoginScreens/IdentityScreen/IdentityScreen.dart';
import 'package:dude/Dude_Utils/App_Theme/DudeTheme.dart';
import 'package:dude/Reusable_Widgets/Premium_UI/premium_ambient_background.dart';

import 'package:dude/DudeScreens/Splash/SplashScreen.dart';
import 'package:dude/DudeScreens/Splash/SplashScreen2.dart';
import 'package:dude/Reusable_Widgets/AppText_Theme/AppText_Theme.dart';
import 'package:dude/Reusable_Widgets/BondingNavigator.dart';
import 'package:dude/Reusable_Widgets/Premium_UI/dude_logo.dart';
import 'package:flutter/material.dart';

class VerificationUnsuccessScreen extends StatefulWidget {
  const VerificationUnsuccessScreen({super.key});

  @override
  State<VerificationUnsuccessScreen> createState() =>
      _VerificationUnsuccessScreenState();
}

class _VerificationUnsuccessScreenState
    extends State<VerificationUnsuccessScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DudeTheme.background,
      body: PremiumAmbientBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 10),

                const DudeLogo(height: 45),

                SizedBox(height: 30),
                Center(
                  child: Image.asset("assets/Images/cancel.png", height: 200),
                ),

                const SizedBox(height: 20),

                /// 🔹 Title
                Center(
                  child: AppText(
                    "Verification Unsuccessful",
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    textAlign: TextAlign.center,
                  ),
                ),

                const SizedBox(height: 12),

                /// 🔹 Description
                Center(
                  child: AppText(
                    "Our verification request could not be approved due to policy or document issues. You may review the reason below and try again.",
                    color: DudeTheme.textSubtle,
                    fontSize: 16,
                    maxLines: 5,
                    textAlign: TextAlign.center,
                  ),
                ),

                const Spacer(),

                /// 🔹 Add Photo Button
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(10.0),
          child: GestureDetector(
            onTap: () {
              bondNavigator.replacePage(context, page: SplashScreen2());
            },
            child: Container(
              height: 50,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                gradient: const LinearGradient(
                  colors: [DudeTheme.accent, Color(0xFFFF6A6A)],
                ),
              ),
              child: const Center(
                child: Text(
                  "Try again  →",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
