import 'package:dude/AccountSelectScreen/AccountSelectScreen.dart';
import 'package:dude/DudeScreens/BottomNavBar/BottomNavBar.dart';
import 'package:dude/DudeScreens/LoginScreens/LoginScreen.dart';
import 'package:dude/Reusable_Widgets/AppText_Theme/AppText_Theme.dart';
import 'package:dude/Reusable_Widgets/BondingNavigator.dart';
import 'package:dude/DudeScreens/HomeScreen/HomeScreen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class SplashScreen2 extends StatefulWidget {
  const SplashScreen2({super.key});

  @override
  State<SplashScreen2> createState() => _SplashScreen2State();
}

class _SplashScreen2State extends State<SplashScreen2> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          /// 🔹 Background Image
          Positioned.fill(
            child: Image.asset("assets/Images/get1.png", fit: BoxFit.cover),
          ),

          SafeArea(
            child: Column(
              children: [
                // /// 🔹 App Logo (Top)
                // Padding(
                //   padding: const EdgeInsets.only(left: 8, top: 8),
                //   child: Row(
                //     children: [
                //       Image.asset(
                //         "assets/Images/voicey.png",
                //         height: 30,
                //
                //       ),
                //     ],
                //   ),
                // ),
                //
                // /// 🔹 Push content to center
                const Spacer(),

                /// 🔹 Center Content
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SvgPicture.asset("assets/Images/dude.svg", height: 80),
                    SizedBox(height: 20),

                    /// Title
                    RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                        ),
                        children: [
                          const TextSpan(
                            text: "Find Your Person\nFor Ever",
                            style: TextStyle(color: Colors.white),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 8),

                    /// Subtitle
                    AppText(
                      "Discover meaningful matches, deep conversations, and relationships\nthat are built to last.",
                      color: Colors.white,
                      fontSize: 14,
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 10),

                    /// Get Started Button
                    GestureDetector(
                      onTap: () {
                        bondNavigator.newPage(
                          context,
                          page: AccountSelectScreen(),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Container(
                          height: 45,

                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            gradient: const LinearGradient(
                              colors: [Color(0xFFbcd719), Color(0xFFbcd719)],
                            ),
                          ),
                          alignment: Alignment.center,
                          child: const Text(
                            "Get started",
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                /// 🔹 Bottom spacing
                const Spacer(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
