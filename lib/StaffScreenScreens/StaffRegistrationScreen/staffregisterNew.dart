import 'package:dude/Dude_Utils/CustomSnackBar/StatusMessage.dart';
import 'package:dude/Reusable_Widgets/AppText_Theme/AppText_Theme.dart';
import 'package:dude/Reusable_Widgets/BondingNavigator.dart';
import 'package:dude/StaffScreenScreens/StaffRegistrationScreen/VerifyOtpStaffScreen.dart';
import 'package:dude/StaffScreenScreens/StaffRegistrationScreen/ViewModel/StaffRegisterVM.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

class StaffRegisterNew extends StatefulWidget {
  const StaffRegisterNew({super.key});

  @override
  State<StaffRegisterNew> createState() => _StaffRegisterNewState();
}

class _StaffRegisterNewState extends State<StaffRegisterNew> {
  final TextEditingController phoneController = TextEditingController();

  @override
  void dispose() {
    phoneController.dispose();
    super.dispose();
  }

  bool _isValidInput() {
    final phone = phoneController.text.trim();
    if (phone.isEmpty || phone.length != 10) {
      Utils.snackBarErrorMessage("Please enter a valid 10-digit phone number");
      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<StaffViewModel>(
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
                  Color(0xFF241b40), // top
                  Color(0xFF1C1426),
                  Color(0xFF12151c),
                  Color(0xFF12151c),
                  Color(0xFF12151c),
                  Color(0xFF2b1e4e), // bottom
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
                    SvgPicture.asset("assets/Images/dude.svg", height: 54),
                    const SizedBox(height: 50),

                    Center(
                      child: AppText(
                        "What's Your Number?",
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),

                    const SizedBox(height: 12),

                    const Text(
                      "Join as a verified female staff member and start earning through audio and video calls.",
                      style: TextStyle(
                        color: Color(0xFFB0A8C0),
                        fontSize: 15,
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 40),

                    // ─── Mobile Number ────────────────────────────────────────
                    const Text(
                      "Mobile number",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),

                    TextField(
                      controller: phoneController,
                      keyboardType: TextInputType.number,
                      maxLength: 10,
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                      decoration: InputDecoration(
                        hintText: "Enter 10-digit number",
                        hintStyle: const TextStyle(color: Color(0xFF6B5F7A)),
                        prefixText: "+91 ",
                        prefixStyle: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                        filled: true,
                        fillColor: const Color(0xFF1C1426),
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
                            color: Color(0xFFB86AF6),
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),

                    if (vm.errorMessage != null) ...[
                      const SizedBox(height: 20),
                      Center(
                        child: Text(
                          vm.errorMessage!,
                          style: const TextStyle(
                            color: Colors.redAccent,
                            fontSize: 14,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],

                    const SizedBox(height: 50),

                    // ─── Continue Button ──────────────────────────────────────
                    GestureDetector(
                      onTap: vm.isRegistering
                          ? null
                          : () async {
                              if (!_isValidInput()) return;

                              final success = await vm.registerStaffNew(
                                phone: phoneController.text.trim(),
                              );

                              if (success) {
                                bondNavigator.newPage(
                                  context,
                                  page: LoginOtpStaffScreen(
                                    phoneNumber: phoneController.text.trim(),
                                  ),
                                );
                              } else {
                                Utils.snackBarErrorMessage(
                                  "Registration failed. Please try again.",
                                );
                              }
                            },
                      child: Container(
                        height: 54,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          gradient: vm.isRegistering
                              ? const LinearGradient(
                                  colors: [Colors.grey, Colors.blueGrey],
                                )
                              : const LinearGradient(
                                  colors: [
                                    Color(0xFFbdd534),
                                    Color(0xFFbdd534),
                                  ],
                                ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFbdd534).withOpacity(0.4),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Center(
                          child: vm.isRegistering
                              ? const SizedBox(
                                  height: 26,
                                  width: 26,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 3,
                                  ),
                                )
                              : const Text(
                                  "Continue to Verification →",
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 17,
                                    fontWeight: FontWeight.w600,
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
}
