import 'package:dude/Dude_Utils/CustomSnackBar/StatusMessage.dart';
import 'package:dude/Dude_Utils/App_Theme/DudeTheme.dart';
import 'package:dude/Reusable_Widgets/Premium_UI/dude_logo.dart';
import 'package:dude/Reusable_Widgets/Premium_UI/premium_ambient_background.dart';
import 'package:dude/Reusable_Widgets/BondingNavigator.dart';
import 'package:dude/StaffScreenScreens/StaffInterestLanguage/staffInterestLanguage.dart';
import 'package:dude/StaffScreenScreens/StaffRegistrationScreen/ViewModel/StaffRegisterVM.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class StaffInterestScreen extends StatefulWidget {
  const StaffInterestScreen({super.key});

  @override
  State<StaffInterestScreen> createState() => _StaffInterestScreenState();
}

class _StaffInterestScreenState extends State<StaffInterestScreen> {
  final List<String> categories = [
    "Serious relationship",
    "Casual dating",
    "Genuine friendship",
    "Caring companion",
    "Deep conversations",
    "Finding the right person",
    "Someone who understands me",
    "Fun & spontaneous",
    "Chill vibes",
    "Long-term connection",
    "Genuine companionship",
    "Open to exploring",
  ];

  List<bool> selectedCategories = List.filled(12, false);

  int get selectedCount =>
      selectedCategories.where((selected) => selected).length;

  bool get canProceed => selectedCount >= 3;

  @override
  Widget build(BuildContext context) {
    return Consumer<StaffViewModel>(
      builder: (context, vm, child) {
        return Scaffold(
          backgroundColor: DudeTheme.background,
          body: PremiumAmbientBackground(
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Center(child: DudeLogo(height: 54)),
                    const SizedBox(height: 26),
                    _stepLabel("1 OF 2  •  YOUR VIBE"),
                    const SizedBox(height: 13),
                    const Text(
                      "What do you enjoy talking about?",
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
                      "Choose at least 3 topics. These help Dude connect you with people who share your vibe.",
                      style: TextStyle(
                        color: DudeTheme.textSubtle,
                        fontSize: 14,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Text(
                          "$selectedCount selected",
                          style: const TextStyle(
                            color: DudeTheme.accentBright,
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          canProceed
                              ? "Ready to continue"
                              : "${3 - selectedCount} more needed",
                          style: const TextStyle(
                            color: DudeTheme.textSubtle,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: ListView.separated(
                        itemCount: categories.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final isSelected = selectedCategories[index];
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                selectedCategories[index] = !isSelected;
                              });
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 15,
                                vertical: 15,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? DudeTheme.accentDim
                                    : DudeTheme.surface.withValues(alpha: 0.9),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isSelected
                                      ? DudeTheme.accent
                                      : DudeTheme.borderSubtle,
                                  width: isSelected ? 1.4 : 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    width: 22,
                                    height: 22,
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? DudeTheme.accent
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(7),
                                      border: Border.all(
                                        color: isSelected
                                            ? DudeTheme.accent
                                            : DudeTheme.border,
                                        width: 1.5,
                                      ),
                                    ),
                                    child: isSelected
                                        ? const Icon(
                                            Icons.check,
                                            size: 15,
                                            color: Colors.white,
                                          )
                                        : null,
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Text(
                                      categories[index],
                                      style: TextStyle(
                                        color: isSelected
                                            ? Colors.white
                                            : DudeTheme.textMuted,
                                        fontSize: 14,
                                        fontWeight: isSelected
                                            ? FontWeight.w700
                                            : FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                    if (vm.interestError != null) ...[
                      const SizedBox(height: 16),
                      Center(
                        child: Text(
                          vm.interestError!,
                          style: const TextStyle(
                            color: Colors.redAccent,
                            fontSize: 14,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: GestureDetector(
                        onTap: vm.isUpdatingInterests || !canProceed
                            ? null
                            : () async {
                                final success = await vm
                                    .updateStaffAreaOfInterest(
                                      categories
                                          .asMap()
                                          .entries
                                          .where(
                                            (entry) =>
                                                selectedCategories[entry.key],
                                          )
                                          .map((entry) => entry.value)
                                          .toList(),
                                    );

                                if (success) {
                                  if (!context.mounted) return;
                                  Utils.snackBar(
                                    "Interests saved successfully!",
                                  );
                                  bondNavigator.newPage(
                                    context,
                                    page: const staffInterestLanguageScreen(),
                                  );
                                } else {
                                  if (!context.mounted) return;
                                  Utils.snackBarErrorMessage(
                                    vm.interestError ??
                                        "Failed to save interests. Try again.",
                                  );
                                }
                              },
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            gradient: canProceed && !vm.isUpdatingInterests
                                ? DudeTheme.premiumAccentGradient
                                : const LinearGradient(
                                    colors: [
                                      Color(0xFF452331),
                                      Color(0xFF301923),
                                    ],
                                  ),
                          ),
                          child: Center(
                            child: vm.isUpdatingInterests
                                ? const SizedBox(
                                    height: 24,
                                    width: 24,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2.5,
                                    ),
                                  )
                                : Text(
                                    canProceed
                                        ? "Continue → ($selectedCount selected)"
                                        : "Select at least 3 interests",
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

                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),
        );
      },
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
