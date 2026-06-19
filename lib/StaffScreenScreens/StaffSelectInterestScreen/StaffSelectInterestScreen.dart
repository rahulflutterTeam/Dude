import 'package:dude/Dude_Utils/CustomSnackBar/StatusMessage.dart';
import 'package:dude/Reusable_Widgets/AppText_Theme/AppText_Theme.dart';
import 'package:dude/Reusable_Widgets/BondingNavigator.dart';
import 'package:dude/StaffScreenScreens/StaffBottomNavBar/StaffBottomNavBar.dart';
import 'package:dude/StaffScreenScreens/StaffInterestLanguage/staffInterestLanguage.dart';
import 'package:dude/StaffScreenScreens/StaffRegistrationScreen/ViewModel/StaffRegisterVM.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
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
          backgroundColor: const Color(0xFF100a0a),
          body: Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF241b40), // top
                  Color(0xFF1C1426),
                  Color(0xFF12151c),
                  Color(0xFF12151c),
                  Color(0xFF12151c),
                  Color(0xFF2b1e4e),
                ],
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),

                    // Logo
                    SvgPicture.asset("assets/Images/dude.svg", height: 40),

                    const SizedBox(height: 30),

                    // Title
                    Center(
                      child: AppText(
                        "Select your Interest",
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Subtitle
                    Center(
                      child: AppText(
                        "Select a few of your interests to match with users who have similar things in common.",
                        fontSize: 15,
                        color: const Color(0xFFc7c7cc),
                        maxLines: 3,
                        textAlign: TextAlign.center,
                      ),
                    ),

                    const SizedBox(height: 40),

                    // Interest Chips
                    // Replace the Interest Chips section and Continue Button in your build method

                    // Interest Chips → ListView
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
                                horizontal: 16,
                                vertical: 14,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? const Color(0xFFaecc01).withOpacity(0.08)
                                    : const Color(0xFF231d1d),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: isSelected
                                      ? const Color(0xFFaecc01)
                                      : Colors.white.withOpacity(0.12),
                                  width: isSelected ? 1.8 : 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  // Checkbox indicator
                                  AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    width: 22,
                                    height: 22,
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? const Color(0xFFaecc01)
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(5),
                                      border: Border.all(
                                        color: isSelected
                                            ? const Color(0xFFaecc01)
                                            : Colors.white.withOpacity(0.3),
                                        width: 1.5,
                                      ),
                                    ),
                                    child: isSelected
                                        ? const Icon(
                                            Icons.check,
                                            size: 15,
                                            color: Colors.black,
                                          )
                                        : null,
                                  ),
                                  const SizedBox(width: 14),
                                  // Label
                                  Text(
                                    categories[index],
                                    style: TextStyle(
                                      color: isSelected
                                          ? const Color(0xFFaecc01)
                                          : Colors.grey[400],
                                      fontSize: 15,
                                      fontWeight: isSelected
                                          ? FontWeight.w600
                                          : FontWeight.w400,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                    // Continue Button
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
                                  Utils.snackBar(
                                    "Interests saved successfully!",
                                  );
                                  bondNavigator.newPage(
                                    context,
                                    page: const staffInterestLanguageScreen(),
                                  );
                                } else {
                                  Utils.snackBarErrorMessage(
                                    vm.interestError ??
                                        "Failed to save interests. Try again.",
                                  );
                                }
                              },
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            gradient: canProceed && !vm.isUpdatingInterests
                                ? const LinearGradient(
                                    colors: [
                                      Color(0xFFaecc01),
                                      Color(0xFFaecc01),
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
                                      color: Colors.black,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
