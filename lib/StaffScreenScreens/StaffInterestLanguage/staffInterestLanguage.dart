import 'package:dude/DudeScreens/LoginScreens/AllsetScreen/AllSetScreen.dart';
import 'package:dude/DudeScreens/LoginScreens/ViewModel/LoginVM.dart';
import 'package:dude/Dude_Utils/CustomSnackBar/StatusMessage.dart';
import 'package:dude/Reusable_Widgets/AppText_Theme/AppText_Theme.dart';
import 'package:dude/Reusable_Widgets/BondingNavigator.dart';
import 'package:dude/StaffScreenScreens/StaffBottomNavBar/StaffBottomNavBar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

class staffInterestLanguageScreen extends StatefulWidget {
  const staffInterestLanguageScreen({super.key});

  @override
  State<staffInterestLanguageScreen> createState() =>
      _staffInterestLanguageScreenState();
}

class _staffInterestLanguageScreenState
    extends State<staffInterestLanguageScreen> {
  final List<Map<String, dynamic>> languages = [
    {
      "title": "Tamil",
      "active": "assets/Images/tamactive.svg",
      "inactive": "assets/Images/taminactive.svg",
      "selected": false,
    },
    {
      "title": "English",
      "active": "assets/Images/engactive.svg",
      "inactive": "assets/Images/enginactive.svg",
      "selected": false,
    },
    {
      "title": "Malayalam",
      "active": "assets/Images/malactive.svg",
      "inactive": "assets/Images/malinactive.svg",
      "selected": false,
    },
    {
      "title": "Hindi",
      "active": "assets/Images/hinactive.svg",
      "inactive": "assets/Images/hininactive.svg",
      "selected": false,
    },
    {
      "title": "Telugu",
      "active": "assets/Images/telactive.svg",
      "inactive": "assets/Images/telinactive.svg",
      "selected": false,
    },
    {
      "title": "Kannada",
      "active": "assets/Images/kanactive.svg",
      "inactive": "assets/Images/kaninactive.svg",
      "selected": false,
    },
  ];

  String? get selectedLanguage {
    final selected = languages.firstWhere(
      (e) => e["selected"] == true,
      orElse: () => {"title": null}, // Return null title
    );
    return selected["title"] as String?;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LoginViewModel>(
      builder: (context, vm, child) {
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 10),
                        SvgPicture.asset("assets/Images/dude.svg", height: 40),
                        const SizedBox(height: 30),

                        Row(
                          children: [
                            GestureDetector(
                              onTap: () => bondNavigator.backPage(context),
                              child: const Icon(
                                Icons.arrow_back_ios,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 12),
                            AppText(
                              "Select your Language",
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ],
                        ),

                        const SizedBox(height: 8),
                        AppText(
                          "Select a Few of your Language to match with users who have similar things in common.",
                          fontSize: 15,
                          color: const Color(0xFFc7c7cc),
                          maxLines: 2,
                        ),

                        if (vm.languageError != null) ...[
                          const SizedBox(height: 16),
                          Center(
                            child: Text(
                              vm.languageError!,
                              style: const TextStyle(
                                color: Colors.redAccent,
                                fontSize: 14,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: GridView.builder(
                        itemCount: languages.length,
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              mainAxisSpacing: 10,
                              crossAxisSpacing: 12,
                              childAspectRatio: 1.3,
                            ),
                        itemBuilder: (context, index) {
                          final item = languages[index];
                          return _languageCard(item, index);
                        },
                      ),
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                    child: GestureDetector(
                      onTap: vm.isUpdatingLanguage
                          ? null
                          : () async {
                              final lang = selectedLanguage;
                              if (lang == null || lang.isEmpty) {
                                Utils.snackBarErrorMessage(
                                  "Please select a language",
                                );
                                return;
                              }

                              final success = await vm.staffUpdateUserLanguage(
                                lang,
                              );

                              if (success) {
                                bondNavigator.newPageRemoveUntil(
                                  context,
                                  page: const StaffBottomBar(),
                                );
                              } else {
                                Utils.snackBarErrorMessage(
                                  "Failed to save language preference",
                                );
                              }
                            },
                      child: Container(
                        height: 54,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          gradient: selectedLanguage != null
                              ? const LinearGradient(
                                  colors: [
                                    Color(0xFFd0e844),
                                    Color(0xFFd0e844),
                                  ],
                                )
                              : const LinearGradient(
                                  colors: [
                                    Color(0xFF353535),
                                    Color(0xFF353535),
                                  ],
                                ),
                        ),
                        child: Center(
                          child: vm.isUpdatingLanguage
                              ? const SizedBox(
                                  height: 24,
                                  width: 24,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2.5,
                                  ),
                                )
                              : const Text(
                                  "Continue  →",
                                  style: TextStyle(
                                    color: Colors.black,
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
      },
    );
  }

  Widget _languageCard(Map<String, dynamic> item, int index) {
    final bool selected = item["selected"];

    return GestureDetector(
      onTap: () {
        setState(() {
          // Unselect all others
          for (var i = 0; i < languages.length; i++) {
            languages[i]["selected"] = false;
          }
          // Select current
          languages[index]["selected"] = true;
        });
      },
      child: SvgPicture.asset(selected ? item["active"] : item["inactive"]),
    );
  }
}
