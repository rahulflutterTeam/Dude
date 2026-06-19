import 'package:dude/DudeScreens/LoginScreens/IdentityScreen/IdentityScreen.dart';
import 'package:dude/Reusable_Widgets/AppText_Theme/AppText_Theme.dart';
import 'package:dude/Reusable_Widgets/BondingNavigator.dart';
import 'package:dude/StaffScreenScreens/StaffSelectInterestScreen/StaffSelectInterestScreen.dart';
import 'package:dude/StaffScreenScreens/VerificationInprogressScreen/VerificationInprogressScreen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

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
      backgroundColor: const Color(0xFF140810),
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
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 10),

                /// 🔹 Logo
                SvgPicture.asset("assets/Images/dude.svg", height: 45),

                const SizedBox(height: 20),

                Center(
                  child: Image.asset("assets/Images/success.png", height: 200),
                ),

                /// 🔹 Title
                Center(
                  child: AppText(
                    "Congratulations Your\nProfile is Approved",
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
                    "Your identity and documents have been successfully verified. You are now an approved partner and can start receiving calls and earning.",
                    color: const Color(0XFFc7c7cc),
                    fontSize: 16,
                    maxLines: 5,
                    textAlign: TextAlign.center,
                  ),
                ),

                const SizedBox(height: 20),

                /// 🔹 Guidelines Title
                Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 16,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFbdd534).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFFbdd534).withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: const Color(0xFFbdd534),
                        size: 22,
                      ),
                      const SizedBox(width: 12),
                      AppText(
                        "Guidelines For Friend Zone",
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFFbdd534),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                /// 🔹 Checklist Items
                Column(
                  children: [
                    _buildChecklistItem(
                      index: 1,
                      text:
                          "Do not share your bank details with anyone like G-Pay, Phonepe & Paytm",
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
                          "Do not engage in adult conversations and report if any user does this",
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
                          "Zero tolerance for abusive language, be polite and friendly",
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
                          "Do not share address, phone number and social media handle details like Instagram, Facebook, WhatsApp, Snapchat",
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
                          "If any user or host violates the above guidelines, they will definitely be banned",
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
      bottomNavigationBar: Container(
        color: const Color(0xFF2b1e4e),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(10.0),
            child: GestureDetector(
              onTap: _isAllChecked
                  ? () {
                      bondNavigator.newPage(
                        context,
                        page: StaffInterestScreen(),
                      );
                    }
                  : null,
              child: Container(
                height: 50,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  gradient: _isAllChecked
                      ? const LinearGradient(
                          colors: [Color(0xFFaecc01), Color(0xFFaecc01)],
                        )
                      : const LinearGradient(
                          colors: [Color(0xFF5a5a5a), Color(0xFF3a3a3a)],
                        ),
                ),
                child: Center(
                  child: Text(
                    "Continue  →",
                    style: TextStyle(
                      color: _isAllChecked ? Colors.black : Colors.grey[400],
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
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
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: const Color(0xFF241b40).withOpacity(0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: value ? const Color(0xFFbdd534) : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// 🔹 Custom Checkbox
            GestureDetector(
              onTap: () {
                onChanged(!value);
              },
              child: Container(
                width: 22,
                height: 22,
                margin: const EdgeInsets.only(top: 2),
                decoration: BoxDecoration(
                  color: value ? const Color(0xFFbdd534) : Colors.transparent,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: value
                        ? const Color(0xFFbdd534)
                        : const Color(0xFFc7c7cc),
                    width: 2,
                  ),
                ),
                child: value
                    ? const Icon(Icons.check, size: 16, color: Colors.black)
                    : null,
              ),
            ),
            const SizedBox(width: 12),

            /// 🔹 Text
            Expanded(
              child: AppText(
                text,
                fontSize: 13,
                color: value
                    ? const Color(0xFFbdd534)
                    : const Color(0XFFc7c7cc),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
