import 'package:dude/DudeScreens/LoginScreens/InterestLanguage/InterestedLanguage.dart';
import 'package:dude/DudeScreens/LoginScreens/ViewModel/LoginVM.dart';
import 'package:dude/Dude_Utils/App_Theme/DudeTheme.dart';
import 'package:dude/Dude_Utils/CustomSnackBar/StatusMessage.dart';
import 'package:dude/Reusable_Widgets/BondingNavigator.dart';
import 'package:dude/Reusable_Widgets/Premium_UI/dude_logo.dart';
import 'package:dude/Reusable_Widgets/Premium_UI/premium_ambient_background.dart';
import 'package:dude/Reusable_Widgets/Premium_UI/premium_glass_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1950),
      lastDate: DateTime.now().subtract(const Duration(days: 18 * 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: DudeTheme.accent,
              onPrimary: Colors.white,
              surface: DudeTheme.surface,
              onSurface: Colors.white,
            ),
            dialogTheme: const DialogThemeData(backgroundColor: DudeTheme.background),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(foregroundColor: DudeTheme.accent),
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null && mounted) {
      dobController.text =
          "${pickedDate.day.toString().padLeft(2, '0')}/"
          "${pickedDate.month.toString().padLeft(2, '0')}/"
          "${pickedDate.year}";
    }
  }

  Future<void> _continue(LoginViewModel vm) async {
    final name = nameController.text.trim();
    final bio = bioController.text.trim();
    final dob = dobController.text.trim();
    final gender = isMale ? "Male" : "Female";

    if (!_isValidDob(dob)) {
      Utils.snackBarErrorMessage("You must be at least 18 years old");
      return;
    }
    if (!_isValidName(name)) {
      Utils.snackBarErrorMessage("Please enter a valid name");
      return;
    }

    final success = await vm.updateBioData(
      name: name,
      gender: gender,
      dob: dob,
      bio: bio,
    );

    if (!mounted) return;

    if (success) {
      bondNavigator.newPage(context, page: const InterestLanguageScreen());
    } else {
      Utils.snackBarErrorMessage("Failed to update profile. Try again.");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LoginViewModel>(
      builder: (context, vm, _) {
        return Scaffold(
          backgroundColor: DudeTheme.background,
          resizeToAvoidBottomInset: true,
          body: PremiumAmbientBackground(
            child: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    const DudeLogo(height: 52),
                    const SizedBox(height: 28),
                    const Text(
                      "Tell us about you",
                      style: TextStyle(
                        color: DudeTheme.textPrimary,
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Pick your gender, birthday, and name to get started.",
                      style: TextStyle(
                        color: DudeTheme.textMuted.withValues(alpha: 0.9),
                        fontSize: 15,
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 28),
                    const Text(
                      "I am",
                      style: TextStyle(
                        color: DudeTheme.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _GenderOptionCard(
                            label: "Male",
                            icon: Icons.male_rounded,
                            selected: isMale,
                            onTap: () => setState(() => isMale = true),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: _GenderOptionCard(
                            label: "Female",
                            icon: Icons.female_rounded,
                            selected: !isMale,
                            onTap: () => setState(() => isMale = false),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    PremiumGlassCard(
                      glow: true,
                      padding: const EdgeInsets.fromLTRB(18, 20, 18, 20),
                      radius: 20,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const _FieldLabel("Birthday (18+)"),
                          const SizedBox(height: 8),
                          _ProfileField(
                            controller: dobController,
                            hint: "DD / MM / YYYY",
                            readOnly: true,
                            onTap: () => _selectDate(context),
                            suffix: SvgPicture.asset(
                              "assets/Images/calender.svg",
                              width: 20,
                              height: 20,
                              colorFilter: const ColorFilter.mode(
                                DudeTheme.accent,
                                BlendMode.srcIn,
                              ),
                            ),
                          ),
                          const SizedBox(height: 18),
                          const _FieldLabel("Full name"),
                          const SizedBox(height: 8),
                          _ProfileField(
                            controller: nameController,
                            hint: "What should we call you?",
                            textInputAction: TextInputAction.done,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),
                    PremiumPrimaryButton(
                      label: "Continue →",
                      loading: vm.isUpdatingBio,
                      height: 54,
                      onTap: vm.isUpdatingBio ? null : () => _continue(vm),
                    ),
                    const SizedBox(height: 32),
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

class _FieldLabel extends StatelessWidget {
  final String text;

  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: DudeTheme.textPrimary,
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class _ProfileField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final bool readOnly;
  final VoidCallback? onTap;
  final Widget? suffix;
  final TextInputAction? textInputAction;

  const _ProfileField({
    required this.controller,
    required this.hint,
    this.readOnly = false,
    this.onTap,
    this.suffix,
    this.textInputAction,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: DudeTheme.background.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: DudeTheme.border.withValues(alpha: 0.45)),
      ),
      child: TextField(
        controller: controller,
        readOnly: readOnly,
        onTap: onTap,
        textInputAction: textInputAction,
        style: const TextStyle(color: DudeTheme.textPrimary, fontSize: 16),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: DudeTheme.textSubtle),
          suffixIcon: suffix != null
              ? Padding(padding: const EdgeInsets.all(14), child: suffix)
              : null,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
          border: InputBorder.none,
        ),
      ),
    );
  }
}

class _GenderOptionCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _GenderOptionCard({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        height: 108,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: selected
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    DudeTheme.accent.withValues(alpha: 0.22),
                    DudeTheme.accentDeep.withValues(alpha: 0.12),
                  ],
                )
              : LinearGradient(
                  colors: [
                    DudeTheme.surface.withValues(alpha: 0.9),
                    DudeTheme.surfaceRaised.withValues(alpha: 0.75),
                  ],
                ),
          border: Border.all(
            color: selected
                ? DudeTheme.accent.withValues(alpha: 0.85)
                : DudeTheme.border.withValues(alpha: 0.45),
            width: selected ? 1.6 : 1,
          ),
          boxShadow: selected
              ? DudeTheme.accentGlowShadow(blur: 18, spread: -4)
              : DudeTheme.softShadow,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 34,
              color: selected ? DudeTheme.accentBright : DudeTheme.textSubtle,
            ),
            const SizedBox(height: 10),
            Text(
              label,
              style: TextStyle(
                color: selected ? DudeTheme.textPrimary : DudeTheme.textMuted,
                fontSize: 16,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
