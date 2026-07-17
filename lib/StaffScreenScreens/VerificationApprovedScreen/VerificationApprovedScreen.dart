import 'package:dude/Dude_Utils/App_Theme/DudeTheme.dart';
import 'package:dude/Reusable_Widgets/Premium_UI/dude_logo.dart';
import 'package:dude/Reusable_Widgets/Premium_UI/premium_ambient_background.dart';
import 'package:dude/Reusable_Widgets/BondingNavigator.dart';
import 'package:dude/StaffScreenScreens/StaffSelectInterestScreen/StaffSelectInterestScreen.dart';
import 'package:flutter/material.dart';

class ApprovedScreen extends StatefulWidget {
  const ApprovedScreen({super.key});

  @override
  State<ApprovedScreen> createState() => _ApprovedScreenState();
}

class _ApprovedScreenState extends State<ApprovedScreen> {
  // Checklist states
  bool _isChecked1 = false;
  bool _isChecked2 = false;
  bool _isChecked3 = false;
  bool _isChecked4 = false;
  bool _isChecked5 = false;

  bool get _isAllChecked =>
      _isChecked1 && _isChecked2 && _isChecked3 && _isChecked4 && _isChecked5;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DudeTheme.background,
      body: PremiumAmbientBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 30),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Center(child: DudeLogo(height: 54)),
                const SizedBox(height: 34),
                Center(child: _approvedMark()),
                const SizedBox(height: 24),
                const Center(
                  child: Text(
                    "You’re verified!",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      height: 1.15,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.7,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  "Welcome to the Dude partner community. Before you start connecting and earning, please accept our safety guidelines.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: DudeTheme.textSubtle,
                    fontSize: 15,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 28),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: DudeTheme.accentDim,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: DudeTheme.accent.withValues(alpha: 0.35),
                    ),
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.shield_outlined,
                        color: DudeTheme.accentBright,
                        size: 24,
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Dude community guidelines",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            SizedBox(height: 3),
                            Text(
                              "Tap each item to confirm",
                              style: TextStyle(
                                color: DudeTheme.textSubtle,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Column(
                  children: [
                    _buildChecklistItem(
                      index: 1,
                      text:
                          "Keep payments inside Dude. Never share bank, UPI or wallet details.",
                      value: _isChecked1,
                      onChanged: (val) {
                        setState(() {
                          _isChecked1 = val ?? false;
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    _buildChecklistItem(
                      index: 2,
                      text:
                          "Keep conversations appropriate. Report sexual or unsafe behaviour.",
                      value: _isChecked2,
                      onChanged: (val) {
                        setState(() {
                          _isChecked2 = val ?? false;
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    _buildChecklistItem(
                      index: 3,
                      text:
                          "Be respectful and friendly. Abuse, threats and harassment are not allowed.",
                      value: _isChecked3,
                      onChanged: (val) {
                        setState(() {
                          _isChecked3 = val ?? false;
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    _buildChecklistItem(
                      index: 4,
                      text:
                          "Protect your privacy. Don’t share phone numbers, addresses or social accounts.",
                      value: _isChecked4,
                      onChanged: (val) {
                        setState(() {
                          _isChecked4 = val ?? false;
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    _buildChecklistItem(
                      index: 5,
                      text:
                          "Report violations promptly. Serious or repeated misuse may result in a ban.",
                      value: _isChecked5,
                      onChanged: (val) {
                        setState(() {
                          _isChecked5 = val ?? false;
                        });
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          child: GestureDetector(
            onTap: _isAllChecked
                ? () {
                    bondNavigator.newPage(
                      context,
                      page: const StaffInterestScreen(),
                    );
                  }
                : null,
            child: Container(
              height: 56,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: _isAllChecked
                    ? DudeTheme.premiumAccentGradient
                    : const LinearGradient(
                        colors: [Color(0xFF452331), Color(0xFF301923)],
                      ),
              ),
              child: Center(
                child: Text(
                  _isAllChecked
                      ? "Continue setup  →"
                      : "Accept all 5 guidelines",
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

  Widget _buildChecklistItem({
    required int index,
    required String text,
    required bool value,
    required Function(bool?) onChanged,
  }) {
    return GestureDetector(
      onTap: () {
        onChanged(!value);
      },
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: value
              ? DudeTheme.accentDim
              : DudeTheme.surface.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: value ? DudeTheme.accent : DudeTheme.borderSubtle,
            width: value ? 1.4 : 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 22,
              height: 22,
              margin: const EdgeInsets.only(top: 2),
              decoration: BoxDecoration(
                color: value ? DudeTheme.accent : Colors.transparent,
                borderRadius: BorderRadius.circular(7),
                border: Border.all(
                  color: value ? DudeTheme.accent : DudeTheme.border,
                  width: 2,
                ),
              ),
              child: value
                  ? const Icon(Icons.check, size: 16, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 13,
                  height: 1.45,
                  fontWeight: value ? FontWeight.w600 : FontWeight.w500,
                  color: value ? Colors.white : DudeTheme.textMuted,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _approvedMark() => Container(
    width: 112,
    height: 112,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: DudeTheme.accentDim,
      border: Border.all(color: DudeTheme.accent, width: 2),
      boxShadow: DudeTheme.accentGlowShadow(blur: 30),
    ),
    child: const Icon(
      Icons.verified_rounded,
      color: DudeTheme.accentBright,
      size: 58,
    ),
  );
}
