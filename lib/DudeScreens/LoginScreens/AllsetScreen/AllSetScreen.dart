import 'package:dude/DudeScreens/BottomNavBar/BottomNavBar.dart';
import 'package:dude/DudeScreens/HomeScreen/HomeScreen.dart';
import 'package:dude/Reusable_Widgets/AppText_Theme/AppText_Theme.dart';
import 'package:dude/Reusable_Widgets/BondingNavigator.dart';
import 'package:dude/Dude_Utils/App_Theme/DudeTheme.dart';
import 'package:flutter/material.dart';
import 'package:dude/Reusable_Widgets/Premium_UI/dude_logo.dart';

class AllsetScreen extends StatefulWidget {
  const AllsetScreen({super.key});

  @override
  State<AllsetScreen> createState() => _AllsetScreenState();
}

class _AllsetScreenState extends State<AllsetScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [
              DudeTheme.background,
              DudeTheme.background,
              DudeTheme.background,
              DudeTheme.background,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 10),

                    /// Logo
                    DudeLogo(height: 40),

                    const SizedBox(height: 30),

                    /// Title
                    Row(
                      children: [
                        // GestureDetector(
                        //     onTap: (){
                        //       bondNavigator.backPage(context);
                        //     },
                        //     child: Icon(Icons.arrow_back_ios,color: Colors.white,)),
                        AppText(
                          "Your Profile Is All Set!",
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),

                    /// Subtitle
                    AppText(
                      "You’re ready to start discovering meaningful connections.",
                      fontSize: 15,
                      color: DudeTheme.textMuted,
                      maxLines: 2,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              /// 🔹 Interest Grid
              Image.asset("assets/Images/couple6.png"),

              /// 🔹 Bottom Button
              Spacer(),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                child: GestureDetector(
                  onTap: () {
                    bondNavigator.newPage(context, page: MainBottomBar());
                  },
                  child: Container(
                    height: 54,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      gradient: const LinearGradient(
                        colors: [DudeTheme.accent, DudeTheme.accent],
                      ),
                    ),
                    child: Center(
                      child: Text(
                        "Start Discovering  →",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
