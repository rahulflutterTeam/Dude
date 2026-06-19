import 'package:dude/DudeScreens/BottomNavBar/BottomNavBar.dart';
import 'package:dude/DudeScreens/LoginScreens/InterestLanguage/InterestedLanguage.dart';
import 'package:dude/DudeScreens/LoginScreens/ViewModel/LoginVM.dart';
import 'package:dude/Dude_Utils/CustomSnackBar/StatusMessage.dart';
import 'package:dude/Reusable_Widgets/AppText_Theme/AppText_Theme.dart';
import 'package:dude/Reusable_Widgets/BondingNavigator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

class IdentityScreen extends StatefulWidget {
  const IdentityScreen({super.key});

  @override
  State<IdentityScreen> createState() => _IdentityScreenState();
}

class _IdentityScreenState extends State<IdentityScreen> {
  bool isMale = true;

  final TextEditingController nameController = TextEditingController();
  final TextEditingController bioController = TextEditingController();
  final TextEditingController dobController = TextEditingController();

  @override
  void dispose() {
    nameController.dispose();
    bioController.dispose();
    dobController.dispose();
    super.dispose();
  }

  bool _isValidName(String name) =>
      name.trim().isNotEmpty && name.trim().length >= 2;
  bool _isValidBio(String bio) =>
      bio.trim().isNotEmpty && bio.trim().length >= 10;

  // Enforce 18+ age validation
  bool _isValidDob(String dob) {
    if (dob.isEmpty) return false;
    try {
      final parts = dob.split('/');
      if (parts.length != 3) return false;

      final day = int.parse(parts[0]);
      final month = int.parse(parts[1]);
      final year = int.parse(parts[2]);

      final birthDate = DateTime(year, month, day);
      final today = DateTime.now();
      final age = today.year - birthDate.year;

      if (birthDate.month > today.month ||
          (birthDate.month == today.month && birthDate.day > today.day)) {
        return age - 1 >= 18;
      }
      return age >= 18;
    } catch (e) {
      return false;
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1950),
      lastDate: DateTime.now().subtract(
        const Duration(days: 18 * 365),
      ), // Minimum 18 years
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFFaecc01),
              onPrimary: Colors.white,
              surface: Color(0xFF1C1426),
              onSurface: Colors.white,
            ),
            dialogBackgroundColor: const Color(0xFF241b40),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFFaecc01),
              ),
            ),
            inputDecorationTheme: const InputDecorationTheme(
              labelStyle: TextStyle(color: Colors.white),
              hintStyle: TextStyle(color: Colors.grey),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.white),
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Color(0xFFaecc01)),
              ),
            ),
            textTheme: const TextTheme(
              bodyLarge: TextStyle(color: Colors.white), // typed text color
              bodyMedium: TextStyle(color: Colors.white),
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null && mounted) {
      String formatted =
          "${pickedDate.day.toString().padLeft(2, '0')}/"
          "${pickedDate.month.toString().padLeft(2, '0')}/"
          "${pickedDate.year}";
      dobController.text = formatted;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LoginViewModel>(
      builder: (context, vm, child) {
        return Scaffold(
          resizeToAvoidBottomInset: true,
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
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 10),
                    SvgPicture.asset("assets/Images/dude.svg", height: 40),
                    const SizedBox(height: 40),

                    Row(
                      children: [
                        // GestureDetector(
                        //   onTap: () => bondNavigator.backPage(context),
                        //   child: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 26),
                        // ),
                        // const SizedBox(width: 16),
                        const Text(
                          "Identify Yourself",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),
                    const Text(
                      "Introduce yourself so people know about you.",
                      style: TextStyle(color: Color(0xFFB0A8C0), fontSize: 15),
                    ),

                    const SizedBox(height: 32),

                    const Text(
                      "I am a:",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    const SizedBox(height: 12),

                    Row(
                      children: [
                        _genderButton(
                          "Male",
                          isMale,
                          () => setState(() => isMale = true),
                        ),
                        const SizedBox(width: 12),
                        _genderButton(
                          "Female",
                          !isMale,
                          () => setState(() => isMale = false),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    const Text(
                      "Birthday (18+)",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    const SizedBox(height: 8),

                    TextField(
                      onTap: () => _selectDate(context),
                      controller: dobController,
                      readOnly: true,
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                      decoration: InputDecoration(
                        hintText: "DD/MM/YYYY",
                        hintStyle: const TextStyle(color: Color(0xFF6B5F7A)),
                        filled: true,
                        fillColor: const Color(0xFF1C1426),
                        suffixIcon: Padding(
                          padding: const EdgeInsets.all(12),
                          child: SvgPicture.asset(
                            "assets/Images/calender.svg",
                            width: 22,
                            height: 22,
                            colorFilter: const ColorFilter.mode(
                              Color(0xFFaecc01),
                              BlendMode.srcIn,
                            ),
                          ),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFF2E2040),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFF2E2040),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFFaecc01),
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    const Text(
                      "Full Name",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildTextField(nameController, "Enter your full name"),

                    const SizedBox(height: 24),

                    // const Text("Bio", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                    // const SizedBox(height: 8),
                    // _buildTextField(bioController, "Write a short bio about yourself...", maxLines: 4),
                    const SizedBox(height: 40),

                    // Continue Button
                    GestureDetector(
                      onTap: vm.isUpdatingBio
                          ? null
                          : () async {
                              final name = nameController.text.trim();
                              final bio = bioController.text.trim();
                              final dob = dobController.text.trim();
                              final gender = isMale ? "Male" : "Female";

                              if (!_isValidDob(dob)) {
                                Utils.snackBarErrorMessage(
                                  "You must be at least 18 years old",
                                );
                                return;
                              }
                              if (!_isValidName(name)) {
                                Utils.snackBarErrorMessage(
                                  "Please enter a valid name",
                                );
                                return;
                              }
                              // if (!_isValidBio(bio)) {
                              //   Utils.snackBarErrorMessage("Bio must be at least 10 characters");
                              //   return;
                              // }

                              final success = await vm.updateBioData(
                                name: name,
                                gender: gender,
                                dob: dob,
                                bio: bio,
                              );

                              if (success) {
                                bondNavigator.newPage(
                                  context,
                                  page: const InterestLanguageScreen(),
                                );
                              } else {
                                Utils.snackBarErrorMessage(
                                  "Failed to update profile. Try again.",
                                );
                              }
                            },
                      child: Container(
                        height: 56,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          gradient: vm.isUpdatingBio
                              ? const LinearGradient(
                                  colors: [Colors.grey, Colors.blueGrey],
                                )
                              : const LinearGradient(
                                  colors: [
                                    Color(0xFFaecc01),
                                    Color(0xFFaecc01),
                                  ],
                                ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFaecc01).withOpacity(0.4),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Center(
                          child: vm.isUpdatingBio
                              ? const SizedBox(
                                  height: 26,
                                  width: 26,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 3,
                                  ),
                                )
                              : const Text(
                                  "Continue →",
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 17,
                                    fontWeight: FontWeight.w700,
                                  ),
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
      },
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String hint, {
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: const TextStyle(color: Colors.white, fontSize: 16),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFF6B5F7A)),
        filled: true,
        fillColor: const Color(0xFF1C1426),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF2E2040)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF2E2040)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFaecc01), width: 1.5),
        ),
      ),
    );
  }

  Widget _genderButton(String text, bool isActive, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 56,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: isActive
                ? const LinearGradient(
                    colors: [Color(0xFFaecc01), Color(0xFFaecc01)],
                  )
                : const LinearGradient(
                    colors: [Color(0xFF2A1F38), Color(0xFF1C1426)],
                  ),
            border: isActive
                ? null
                : Border.all(color: const Color(0xFFaecc01), width: 0.5),
          ),
          child: Center(
            child: Text(
              text,
              style: TextStyle(
                color: isActive ? Colors.black : Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
