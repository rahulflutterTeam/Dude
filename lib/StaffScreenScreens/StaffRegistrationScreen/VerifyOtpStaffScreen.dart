import 'package:dude/DudeScreens/LoginScreens/ViewModel/LoginVM.dart';
import 'package:dude/Dude_Utils/CustomSnackBar/StatusMessage.dart';
import 'package:dude/Dude_Utils/otp/otp_autofill_service.dart';
import 'package:dude/Reusable_Widgets/AppText_Theme/AppText_Theme.dart';
import 'package:dude/Reusable_Widgets/BondingNavigator.dart';
import 'package:dude/StaffScreenScreens/LiveSeflieVerificationScreen/LiveVerificationScreen.dart';
import 'package:dude/StaffScreenScreens/ProfileVerficationScreen/ProfileVerficationScreen.dart';
import 'package:dude/StaffScreenScreens/StaffBottomNavBar/StaffBottomNavBar.dart';
import 'package:dude/StaffScreenScreens/StaffRegistrationScreen/StaffRegistrationScreens.dart';
import 'package:dude/StaffScreenScreens/StaffRegistrationScreen/ViewModel/StaffRegisterVM.dart';
import 'package:dude/StaffScreenScreens/VerificationInprogressScreen/VerificationInprogressScreen.dart';
import 'package:dude/StaffScreenScreens/VerificationUnsuccessfulScreen/VerificationUnsuccessScreen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

class LoginOtpStaffScreen extends StatefulWidget {
  final String phoneNumber;

  const LoginOtpStaffScreen({super.key, required this.phoneNumber});

  @override
  State<LoginOtpStaffScreen> createState() => _LoginOtpStaffScreenState();
}

class _LoginOtpStaffScreenState extends State<LoginOtpStaffScreen> {
  final TextEditingController _otpController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _startOtpAutofill();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final vm = Provider.of<LoginViewModel>(context, listen: false);

      if (vm.autoOtp != null) {
        _otpController.text = vm.autoOtp!;
        setState(() {}); // refresh hearts
      }

      _focusNode.requestFocus();
    });
  }

  Future<void> _startOtpAutofill() async {
    await OtpAutofillService.instance.start(
      onCodeReceived: (code) {
        if (!mounted) return;
        _otpController.text = code.length > 4 ? code.substring(0, 4) : code;
        _otpController.selection = TextSelection.collapsed(
          offset: _otpController.text.length,
        );
        setState(() {});
      },
    );
  }

  void _handleOtpFill() {
    final vm = Provider.of<LoginViewModel>(context, listen: false);

    if (vm.autoOtp != null && _otpController.text != vm.autoOtp) {
      _otpController.text = vm.autoOtp!;
      setState(() {});
    }
  }

  @override
  void dispose() {
    final vm = Provider.of<LoginViewModel>(context, listen: false);
    vm.removeListener(_handleOtpFill);

    OtpAutofillService.instance.stop();
    _otpController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  bool _isValidOtp(String otp) => RegExp(r'^\d{4}$').hasMatch(otp);

  // Method to open keyboard
  void _openKeyboard() {
    _focusNode.requestFocus();
    // Force keyboard to show
    SystemChannels.textInput.invokeMethod('TextInput.show');
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
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
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
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 10),
                    SvgPicture.asset("assets/Images/dude.svg", height: 50),
                    const SizedBox(height: 30),
                    Center(
                      child: Image.asset(
                        "assets/Images/gender.png",
                        width: 280,
                      ),
                    ),
                    const SizedBox(height: 30),

                    AppText(
                      "Enter your code",
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),

                    const SizedBox(height: 12),

                    // OTP Input Section
                    Column(
                      children: [
                        // Hidden TextField for input
                        SizedBox(
                          height: 1,
                          child: TextField(
                            cursorColor: Colors.transparent,
                            controller: _otpController,
                            focusNode: _focusNode,
                            autofocus: true,
                            keyboardType: TextInputType.number,
                            autofillHints: const [AutofillHints.oneTimeCode],
                            textInputAction: TextInputAction.done,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            maxLength: 4,
                            style: const TextStyle(
                              fontSize: 1,
                              color: Colors.transparent,
                            ),
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              counterText: '',
                              contentPadding: EdgeInsets.zero,
                            ),
                            onChanged: (_) => setState(() {}),
                          ),
                        ),

                        const SizedBox(height: 10),

                        // Heart Display (Clickable)
                        Row(
                          children: [
                            GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: _openKeyboard,
                              child: HeartOtpDisplay(
                                length: 4,
                                controller: _otpController,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    // if (vm.verifyError != null) ...[
                    //   const SizedBox(height: 16),
                    //   Text(
                    //     vm.verifyError!,
                    //     style: const TextStyle(color: Colors.redAccent, fontSize: 14),
                    //     textAlign: TextAlign.center,
                    //   ),
                    // ],
                    const SizedBox(height: 40),

                    // Login Button
                    GestureDetector(
                      onTap: vm.isVerifying
                          ? null
                          : () async {
                              final otp = _otpController.text.trim();

                              if (otp.isEmpty) {
                                Utils.snackBarErrorMessage(
                                  "Please enter the OTP",
                                );
                                return;
                              }
                              if (!_isValidOtp(otp)) {
                                Utils.snackBarErrorMessage(
                                  "Please enter all 4 digits",
                                );
                                return;
                              }

                              final success = await vm.staffVerifyOtp(
                                widget.phoneNumber,
                                otp,
                              );

                              if (success) {
                                final staffVM = Provider.of<StaffViewModel>(
                                  context,
                                  listen: false,
                                );

                                // Fetch latest staff data after login
                                await staffVM.fetchStaffSingleData();

                                final staff = staffVM.currentStaff;

                                final formStatus =
                                    int.tryParse(staff?.formStatus ?? '0') ?? 0;
                                final approval =
                                    staff?.isApproved?.toLowerCase().trim() ??
                                    'pending';
                                final isRegister = staff?.isRegister;
                                print("isRegister ::::: ${isRegister}");

                                print("After OTP → formStatus: $formStatus");
                                print("After OTP → isApproved: $approval");
                                if (isRegister == false) {
                                  bondNavigator.newPage(
                                    context,
                                    page: StaffRegisterScreen(),
                                  );
                                  return;
                                }
                                if (approval == "0") {
                                  bondNavigator.newPageRemoveUntil(
                                    context,
                                    page: const VerificationInprogressScreen(),
                                  );
                                  return;
                                }

                                if (formStatus >= 3) {
                                  // Fully completed → go to dashboard
                                  bondNavigator.newPageRemoveUntil(
                                    context,
                                    page: const StaffBottomBar(),
                                  );
                                } else if (formStatus == 2) {
                                  if (approval == '1') {
                                    // Approved
                                    bondNavigator.newPageRemoveUntil(
                                      context,
                                      page: const StaffBottomBar(),
                                    );
                                  } else if (approval.contains('2') ||
                                      approval == 'declined' ||
                                      approval == 'not approved') {
                                    bondNavigator.newPageRemoveUntil(
                                      context,
                                      page: const VerificationUnsuccessScreen(),
                                    );
                                  } else {
                                    // Pending
                                    bondNavigator.newPageRemoveUntil(
                                      context,
                                      page:
                                          const VerificationInprogressScreen(),
                                    );
                                  }
                                } else if (formStatus == 1) {
                                  bondNavigator.newPageRemoveUntil(
                                    context,
                                    page: const LiveVerificationScreen(),
                                  );
                                } else {
                                  // First time staff
                                  bondNavigator.newPageRemoveUntil(
                                    context,
                                    page: const ProfileVerficationScreen(),
                                  );
                                }
                              } else {
                                Utils.snackBarErrorMessage("Invalid Otp");
                              }
                            },
                      child: Container(
                        height: 50,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          gradient: vm.isVerifying
                              ? const LinearGradient(
                                  colors: [Colors.grey, Colors.blueGrey],
                                )
                              : const LinearGradient(
                                  colors: [
                                    Color(0xFFbdd534),
                                    Color(0xFFbdd534),
                                  ],
                                ),
                        ),
                        child: Center(
                          child: vm.isVerifying
                              ? const SizedBox(
                                  height: 24,
                                  width: 24,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2.5,
                                  ),
                                )
                              : const Text(
                                  "Login  →",
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 30),

                    // Keyboard Toggle Button (Optional)
                    Center(
                      child: TextButton(
                        onPressed: _openKeyboard,
                        child: const Text(
                          "Tap to open keyboard",
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ),
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

class HeartOtpDisplay extends StatelessWidget {
  final int length;
  final TextEditingController controller;

  const HeartOtpDisplay({
    super.key,
    required this.length,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(length, (index) {
        final text = controller.text;
        final char = index < text.length ? text[index] : "-";

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Icon(
                Icons.favorite,
                color: Color(0xFFbdd534).withOpacity(0.1),
                size: 70,
              ),
              Text(
                char,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}
