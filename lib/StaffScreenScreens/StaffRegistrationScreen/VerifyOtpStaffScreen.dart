import 'dart:async';
import 'dart:io';

import 'package:dude/DudeScreens/LoginScreens/LoginOtpScreen.dart';
import 'package:dude/DudeScreens/LoginScreens/ViewModel/LoginVM.dart';
import 'package:dude/Dude_Utils/App_Theme/DudeTheme.dart';
import 'package:dude/Dude_Utils/CustomSnackBar/StatusMessage.dart';
import 'package:dude/Dude_Utils/otp/otp_autofill_service.dart';
import 'package:dude/Reusable_Widgets/BondingNavigator.dart';
import 'package:dude/Reusable_Widgets/Premium_UI/login_auth_shell.dart';
import 'package:dude/Reusable_Widgets/Premium_UI/premium_glass_card.dart';
import 'package:dude/StaffScreenScreens/LiveSeflieVerificationScreen/LiveVerificationScreen.dart';
import 'package:dude/StaffScreenScreens/ProfileVerficationScreen/ProfileVerficationScreen.dart';
import 'package:dude/StaffScreenScreens/StaffBottomNavBar/StaffBottomNavBar.dart';
import 'package:dude/StaffScreenScreens/StaffRegistrationScreen/StaffRegistrationScreens.dart';
import 'package:dude/StaffScreenScreens/StaffRegistrationScreen/ViewModel/StaffRegisterVM.dart';
import 'package:dude/StaffScreenScreens/VerificationInprogressScreen/VerificationInprogressScreen.dart';
import 'package:dude/StaffScreenScreens/VerificationUnsuccessfulScreen/VerificationUnsuccessScreen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

  int _resendSeconds = 30;
  bool _canResend = false;
  bool _autoVerifyTriggered = false;
  Timer? _resendTimer;
  Timer? _autoVerifyTimer;

  @override
  void initState() {
    super.initState();
    _startOtpAutofill();
    _startResendTimer();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final vm = Provider.of<LoginViewModel>(context, listen: false);
      if (vm.autoOtp != null) {
        _applyOtp(vm, vm.autoOtp!, autoVerify: true);
      }
      _focusNode.requestFocus();
    });
  }

  void _applyOtp(
    LoginViewModel vm,
    String code, {
    bool autoVerify = false,
  }) {
    final otp = code.length > 4 ? code.substring(0, 4) : code;
    _otpController.text = otp;
    _otpController.selection = TextSelection.collapsed(offset: otp.length);
    setState(() {});

    if (autoVerify && otp.length == 4) {
      _scheduleAutoVerify(vm);
    }
  }

  void _scheduleAutoVerify(LoginViewModel vm) {
    if (_autoVerifyTriggered || vm.isVerifying) return;
    if (!_isValidOtp(_otpController.text.trim())) return;

    _autoVerifyTimer?.cancel();
    _autoVerifyTimer = Timer(const Duration(milliseconds: 650), () {
      if (!mounted) return;
      _tryAutoVerify(vm);
    });
  }

  void _tryAutoVerify(LoginViewModel vm) {
    if (_autoVerifyTriggered || vm.isVerifying) return;
    if (!_isValidOtp(_otpController.text.trim())) return;

    _autoVerifyTriggered = true;
    _verifyOtp(vm);
  }

  void _startResendTimer() {
    _resendSeconds = 30;
    _canResend = false;
    _resendTimer?.cancel();
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        if (_resendSeconds > 0) {
          _resendSeconds--;
        } else {
          _canResend = true;
          timer.cancel();
        }
      });
    });
  }

  Future<void> _resendOtp() async {
    if (!_canResend) return;

    final staffVM = context.read<StaffViewModel>();
    final success = await staffVM.registerStaffNew(phone: widget.phoneNumber);

    if (!mounted) return;

    if (success) {
      _otpController.clear();
      _autoVerifyTriggered = false;
      _startResendTimer();
      Utils.snackBar('OTP resent successfully!');

      await OtpAutofillService.instance.stop();
      await _startOtpAutofill();

      final loginVM = context.read<LoginViewModel>();
      if (loginVM.autoOtp != null) {
        _applyOtp(loginVM, loginVM.autoOtp!, autoVerify: true);
      }
    } else {
      Utils.snackBarErrorMessage('Failed to resend OTP. Try again.');
    }
  }

  Future<void> _startOtpAutofill() async {
    await OtpAutofillService.instance.start(
      onCodeReceived: (code) {
        if (!mounted) return;
        final vm = context.read<LoginViewModel>();
        _applyOtp(vm, code, autoVerify: true);
      },
    );
  }

  @override
  void dispose() {
    _resendTimer?.cancel();
    _autoVerifyTimer?.cancel();
    OtpAutofillService.instance.stop();
    _otpController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  bool _isValidOtp(String otp) => RegExp(r'^\d{4}$').hasMatch(otp);

  Future<void> _verifyOtp(LoginViewModel vm) async {
    final otp = _otpController.text.trim();

    if (otp.isEmpty) {
      _autoVerifyTriggered = false;
      Utils.snackBarErrorMessage('Please enter the OTP');
      return;
    }
    if (!_isValidOtp(otp)) {
      _autoVerifyTriggered = false;
      Utils.snackBarErrorMessage('Please enter all 4 digits');
      return;
    }

    final success = await vm.staffVerifyOtp(widget.phoneNumber, otp);
    if (!mounted) return;

    if (!success) {
      _autoVerifyTriggered = false;
      Utils.snackBarErrorMessage('Invalid OTP');
      return;
    }

    final staffVM = context.read<StaffViewModel>();
    await staffVM.fetchStaffSingleData();
    if (!mounted) return;

    final staff = staffVM.currentStaff;
    final formStatus = int.tryParse(staff?.formStatus ?? '0') ?? 0;
    final approval = staff?.isApproved?.toLowerCase().trim() ?? 'pending';
    final isRegister = staff?.isRegister;

    if (isRegister == false) {
      bondNavigator.newPage(context, page: const StaffRegisterScreen());
      return;
    }
    if (approval == '0') {
      bondNavigator.newPageRemoveUntil(
        context,
        page: const VerificationInprogressScreen(),
      );
      return;
    }
    if (formStatus >= 3) {
      bondNavigator.newPageRemoveUntil(context, page: const StaffBottomBar());
    } else if (formStatus == 2) {
      if (approval == '1') {
        bondNavigator.newPageRemoveUntil(context, page: const StaffBottomBar());
      } else if (approval.contains('2') ||
          approval == 'declined' ||
          approval == 'not approved') {
        bondNavigator.newPageRemoveUntil(
          context,
          page: const VerificationUnsuccessScreen(),
        );
      } else {
        bondNavigator.newPageRemoveUntil(
          context,
          page: const VerificationInprogressScreen(),
        );
      }
    } else if (formStatus == 1) {
      bondNavigator.newPageRemoveUntil(
        context,
        page: const LiveVerificationScreen(),
      );
    } else {
      bondNavigator.newPageRemoveUntil(
        context,
        page: const ProfileVerficationScreen(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LoginViewModel>(
      builder: (context, vm, child) {
        return LoginAuthShell(
          showBack: true,
          showLogo: true,
          title: 'Verify your number',
          subtitle:
              'Enter the 4-digit code we sent to +91 ${widget.phoneNumber}',
          form: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _StaffOtpAutofillHint(isAndroid: Platform.isAndroid),
              const SizedBox(height: 16),
              AutofillGroup(
                child: Stack(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        OtpBoxDisplay(
                          length: 4,
                          controller: _otpController,
                          activeIndex: _otpController.text.length,
                        ),
                      ],
                    ),
                    Positioned.fill(
                      child: GestureDetector(
                        onTap: () => _focusNode.requestFocus(),
                        behavior: HitTestBehavior.translucent,
                        child: TextField(
                          controller: _otpController,
                          focusNode: _focusNode,
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
                          cursorColor: Colors.transparent,
                          decoration: kOtpHiddenFieldDecoration,
                          onChanged: (value) {
                            setState(() {});
                            if (value.length == 4) {
                              _scheduleAutoVerify(vm);
                            } else {
                              _autoVerifyTriggered = false;
                              _autoVerifyTimer?.cancel();
                            }
                          },
                          onSubmitted: (_) {
                            if (_isValidOtp(_otpController.text.trim())) {
                              _tryAutoVerify(vm);
                            }
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Didn't receive the code? ",
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 13,
                    ),
                  ),
                  GestureDetector(
                    onTap: _canResend && !vm.isVerifying ? _resendOtp : null,
                    child: Text(
                      _canResend
                          ? 'Resend OTP'
                          : 'Resend in ${_resendSeconds}s',
                      style: TextStyle(
                        color: _canResend
                            ? DudeTheme.accent
                            : Colors.white.withValues(alpha: 0.35),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              PremiumPrimaryButton(
                label: 'Continue →',
                loading: vm.isVerifying,
                height: 54,
                onTap: vm.isVerifying ? null : () => _tryAutoVerify(vm),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _StaffOtpAutofillHint extends StatelessWidget {
  final bool isAndroid;

  const _StaffOtpAutofillHint({required this.isAndroid});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: DudeTheme.accentDim.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: DudeTheme.accent.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Icon(
            isAndroid ? Icons.sms_outlined : Icons.keyboard_alt_outlined,
            color: DudeTheme.accent,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              isAndroid
                  ? 'When SMS arrives, tap Allow — OTP fills here automatically.'
                  : 'OTP from Messages will appear above keyboard — tap to fill.',
              style: TextStyle(
                color: DudeTheme.textMuted.withValues(alpha: 0.95),
                fontSize: 12.5,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
