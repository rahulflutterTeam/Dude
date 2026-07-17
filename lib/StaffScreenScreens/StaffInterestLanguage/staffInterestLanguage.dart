import 'package:dude/Dude_Utils/App_Theme/DudeTheme.dart';
import 'package:dude/Reusable_Widgets/Premium_UI/dude_logo.dart';
import 'package:dude/Reusable_Widgets/Premium_UI/premium_ambient_background.dart';
import 'package:dude/DudeScreens/LoginScreens/ViewModel/LoginVM.dart';
import 'package:dude/Dude_Utils/CustomSnackBar/StatusMessage.dart';
import 'package:dude/Reusable_Widgets/BondingNavigator.dart';
import 'package:dude/StaffScreenScreens/StaffBottomNavBar/StaffBottomNavBar.dart';
import 'package:flutter/material.dart';
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
    {"title": "Tamil", "native": "தமிழ்", "selected": false},
    {"title": "English", "native": "English", "selected": false},
    {"title": "Malayalam", "native": "മലയാളം", "selected": false},
    {"title": "Hindi", "native": "हिन्दी", "selected": false},
    {"title": "Telugu", "native": "తెలుగు", "selected": false},
    {"title": "Kannada", "native": "ಕನ್ನಡ", "selected": false},
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
          backgroundColor: DudeTheme.background,
          body: PremiumAmbientBackground(
            child: SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Center(child: DudeLogo(height: 54)),
                        const SizedBox(height: 26),
                        Row(
                          children: [
                            GestureDetector(
                              onTap: () => bondNavigator.backPage(context),
                              child: Container(
                                width: 38,
                                height: 38,
                                decoration: BoxDecoration(
                                  color: DudeTheme.surfaceRaised,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: DudeTheme.borderSubtle,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.arrow_back_ios_new_rounded,
                                  color: Colors.white,
                                  size: 17,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            _stepLabel("2 OF 2  •  LANGUAGE"),
                          ],
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          "Which language do you prefer?",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 27,
                            height: 1.18,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.6,
                          ),
                        ),
                        const SizedBox(height: 9),
                        const Text(
                          "Choose your primary conversation language. You can update it later from your profile.",
                          style: TextStyle(
                            color: DudeTheme.textSubtle,
                            fontSize: 14,
                            height: 1.5,
                          ),
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

                  const SizedBox(height: 22),

                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: GridView.builder(
                        itemCount: languages.length,
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              mainAxisSpacing: 12,
                              crossAxisSpacing: 12,
                              childAspectRatio: 1.15,
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
                      onTap: vm.isUpdatingLanguage || selectedLanguage == null
                          ? null
                          : () async {
                              final lang = selectedLanguage;
                              if (lang == null || lang.isEmpty) return;

                              final success = await vm.staffUpdateUserLanguage(
                                lang,
                              );

                              if (!context.mounted) return;
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
                          borderRadius: BorderRadius.circular(16),
                          gradient: selectedLanguage != null
                              ? DudeTheme.premiumAccentGradient
                              : const LinearGradient(
                                  colors: [
                                    Color(0xFF452331),
                                    Color(0xFF301923),
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
                              : Text(
                                  selectedLanguage == null
                                      ? "Select a language"
                                      : "Finish setup  →",
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
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: selected
              ? DudeTheme.accentDim
              : DudeTheme.surface.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? DudeTheme.accent : DudeTheme.borderSubtle,
            width: selected ? 1.5 : 1,
          ),
          boxShadow: selected
              ? DudeTheme.accentGlowShadow(blur: 18, spread: -5)
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: selected
                        ? DudeTheme.accent
                        : DudeTheme.surfaceRaised,
                  ),
                  child: Icon(
                    Icons.translate_rounded,
                    size: 19,
                    color: selected ? Colors.white : DudeTheme.textSubtle,
                  ),
                ),
                AnimatedOpacity(
                  opacity: selected ? 1 : 0,
                  duration: const Duration(milliseconds: 180),
                  child: const Icon(
                    Icons.check_circle_rounded,
                    color: DudeTheme.accentBright,
                    size: 22,
                  ),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item["native"],
                  style: TextStyle(
                    color: selected ? Colors.white : DudeTheme.textMuted,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  item["title"],
                  style: const TextStyle(
                    color: DudeTheme.textSubtle,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _stepLabel(String text) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
    decoration: BoxDecoration(
      color: DudeTheme.accentDim,
      borderRadius: BorderRadius.circular(30),
      border: Border.all(color: DudeTheme.accent.withValues(alpha: 0.35)),
    ),
    child: Text(
      text,
      style: const TextStyle(
        color: DudeTheme.accentBright,
        fontSize: 11,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.7,
      ),
    ),
  );
}
