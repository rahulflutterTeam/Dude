import 'dart:async';

import 'package:dude/DudeScreens/BottomNavBar/BottomNavBar.dart';
import 'package:dude/DudeScreens/HomeScreen/ViewModel/UserVM.dart';
import 'package:dude/DudeScreens/LoginScreens/IdentityScreen/IdentityScreen.dart';
import 'package:dude/DudeScreens/LoginScreens/InterestLanguage/InterestedLanguage.dart';
import 'package:dude/DudeScreens/LoginScreens/ViewModel/LoginVM.dart';
import 'package:dude/Dude_Utils/CustomSnackBar/StatusMessage.dart';
import 'package:dude/Dude_Utils/otp/otp_autofill_service.dart';
import 'package:dude/Reusable_Widgets/AppText_Theme/AppText_Theme.dart';
import 'package:dude/Reusable_Widgets/BondingNavigator.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';

class LoginOtpScreen extends StatefulWidget {
  final String phoneNumber;
  final String referralCode;

  const LoginOtpScreen({
    super.key,
    required this.phoneNumber,
    required this.referralCode,
  });

  @override
  State<LoginOtpScreen> createState() => _LoginOtpScreenState();
}

class _LoginOtpScreenState extends State<LoginOtpScreen> {
  final TextEditingController _otpController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  late VideoPlayerController _videoController;
  bool _isVideoInitialized = false;

  // ── Resend OTP timer ──────────────────────────────────────────
  int _resendSeconds = 30;
  bool _canResend = false;
  Timer? _resendTimer;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
    _startOtpAutofill();
    _startResendTimer();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final vm = Provider.of<LoginViewModel>(context, listen: false);
      if (vm.autoOtp != null) {
        _otpController.text = vm.autoOtp!;
        setState(() {});
      }
      _focusNode.requestFocus();
    });
  }

  // ── Timer ─────────────────────────────────────────────────────
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

  // ── Resend OTP ────────────────────────────────────────────────
  Future<void> _resendOtp() async {
    if (!_canResend) return;

    final vm = context.read<LoginViewModel>();
    final success = await vm.sendOtp(widget.phoneNumber, widget.referralCode);

    if (success) {
      _otpController.clear();
      _startResendTimer();
      Utils.snackBar("OTP resent successfully!");

      if (vm.autoOtp != null) {
        _otpController.text = vm.autoOtp!;
        setState(() {});
      }
    } else {
      Utils.snackBarErrorMessage("Failed to resend OTP. Try again.");
    }
  }

  Future<void> _initializeVideo() async {
    _videoController = VideoPlayerController.asset(
      'assets/Video/pairvideo2.mp4',
    );
    await _videoController.initialize();
    await _videoController.setLooping(true);
    await _videoController.setVolume(0.0);
    await _videoController.play();
    setState(() => _isVideoInitialized = true);
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

  @override
  void dispose() {
    _resendTimer?.cancel();
    OtpAutofillService.instance.stop();
    _videoController.dispose();
    _otpController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  bool _isValidOtp(String otp) => RegExp(r'^\d{4}$').hasMatch(otp);

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;

    return Consumer<LoginViewModel>(
      builder: (context, vm, child) {
        return Scaffold(
          resizeToAvoidBottomInset: true,
          backgroundColor: const Color(0xFF0E0A14),
          body: Stack(
            children: [
              // ── Video Background ──────────────────────────────
              if (_isVideoInitialized)
                Positioned.fill(
                  child: FittedBox(
                    fit: BoxFit.cover,
                    child: SizedBox(
                      width: _videoController.value.size.width,
                      height: _videoController.value.size.height,
                      child: VideoPlayer(_videoController),
                    ),
                  ),
                ),

              // ── Dark Gradient Overlay ─────────────────────────
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withOpacity(0.4),
                        Colors.black.withOpacity(0.65),
                        const Color(0xFF0E0A14),
                      ],
                    ),
                  ),
                ),
              ),

              // ── Content ───────────────────────────────────────
              SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: height * 0.08),

                      // Logo
                      Center(
                        child: SvgPicture.asset(
                          "assets/Images/dude.svg",
                          height: height * 0.18,
                        ),
                      ),
                      SizedBox(height: height * 0.08),

                      AppText(
                        "Enter your code",
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),

                      const SizedBox(height: 6),

                      // Phone hint
                      Text(
                        "Sent to +91 ${widget.phoneNumber}",
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.5),
                          fontSize: 13.5,
                        ),
                      ),

                      const SizedBox(height: 24),

                      // ── OTP Hearts Input ──────────────────────
                      Stack(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              HeartOtpDisplay(
                                length: 4,
                                controller: _otpController,
                              ),
                            ],
                          ),

                          // Transparent TextField overlay
                          Positioned(
                            top: 0,
                            left: 0,
                            right: 0,
                            child: GestureDetector(
                              onTap: () => _focusNode.requestFocus(),
                              child: Container(
                                height: 85,
                                color: Colors.transparent,
                                child: TextField(
                                  controller: _otpController,
                                  focusNode: _focusNode,
                                  keyboardType: TextInputType.number,
                                  autofillHints: const [
                                    AutofillHints.oneTimeCode,
                                  ],
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
                                  decoration: const InputDecoration(
                                    border: InputBorder.none,
                                    counterText: '',
                                    contentPadding: EdgeInsets.zero,
                                  ),
                                  onChanged: (_) => setState(() {}),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // ── Resend OTP Row ────────────────────────
                      Row(
                        children: [
                          Text(
                            "Didn't receive the code? ",
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.55),
                              fontSize: 13.5,
                            ),
                          ),
                          GestureDetector(
                            onTap: _canResend && !vm.isLoading
                                ? _resendOtp
                                : null,
                            child: vm.isLoading
                                ? const SizedBox(
                                    height: 14,
                                    width: 14,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Color(0xFFd2ea46),
                                    ),
                                  )
                                : Text(
                                    _canResend
                                        ? "Resend OTP"
                                        : "Resend in ${_resendSeconds}s",
                                    style: TextStyle(
                                      color: _canResend
                                          ? const Color(0xFFd2ea46)
                                          : Colors.white.withOpacity(0.35),
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 40),

                      // ── Login Button ──────────────────────────
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

                                final success = await vm.verifyOtp(
                                  widget.phoneNumber,
                                  otp,
                                );

                                if (success) {
                                  final userVM = Provider.of<UserViewModel>(
                                    context,
                                    listen: false,
                                  );
                                  await userVM.fetchUserDetails();

                                  final user = userVM.currentUser;

                                  if (user == null) {
                                    bondNavigator.newPage(
                                      context,
                                      page: const IdentityScreen(),
                                    );
                                    return;
                                  }

                                  final status =
                                      int.tryParse(user.formStatus ?? "0") ?? 0;

                                  if (status == 0 || status == 1) {
                                    bondNavigator.newPageRemoveUntil(
                                      context,
                                      page: const IdentityScreen(),
                                    );
                                  } else if (status == 2) {
                                    bondNavigator.newPageRemoveUntil(
                                      context,
                                      page: const MainBottomBar(),
                                    );
                                  } else if (status == 3) {
                                    bondNavigator.newPageRemoveUntil(
                                      context,
                                      page: const InterestLanguageScreen(),
                                    );
                                  } else {
                                    bondNavigator.newPageRemoveUntil(
                                      context,
                                      page: const MainBottomBar(),
                                    );
                                  }
                                } else {
                                  Utils.snackBarErrorMessage("Invalid OTP");
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

                      SizedBox(height: height * 0.11),

                      Padding(
                        padding: const EdgeInsets.only(left: 50.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Opacity(
                              opacity: 0.3,
                              child: Image.asset(
                                "assets/Images/gender.png",
                                width: 280,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ── HeartOtpDisplay ───────────────────────────────────────────────
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
          padding: const EdgeInsets.only(right: 1),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Icon(
                Icons.favorite,
                color: const Color(0xFFbdd534).withOpacity(0.3),
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
