import 'package:dude/DudeScreens/LoginScreens/LoginOtpScreen.dart';
import 'package:dude/DudeScreens/LoginScreens/ViewModel/LoginVM.dart';
import 'package:dude/Dude_Utils/CustomSnackBar/StatusMessage.dart';
import 'package:dude/Reusable_Widgets/AppText_Theme/AppText_Theme.dart';
import 'package:dude/Reusable_Widgets/BondingNavigator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _referralController = TextEditingController();

  late VideoPlayerController _videoController;
  bool _isVideoInitialized = false;

  bool _isValidPhone(String phone) {
    return RegExp(r'^[6-9]\d{9}$').hasMatch(phone);
  }

  @override
  void initState() {
    super.initState();
    _initializeVideo();
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

  @override
  void dispose() {
    _videoController.dispose();
    _phoneController.dispose();
    _referralController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;

    return Consumer<LoginViewModel>(
      builder: (context, vm, child) {
        return Scaffold(
          backgroundColor: const Color(0xFF0E0A14),
          body: Stack(
            children: [
              // Video Background
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

              // Gradient Overlay
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withOpacity(0.35),
                        Colors.black.withOpacity(0.65),
                        const Color(0xFF0E0A14),
                      ],
                    ),
                  ),
                ),
              ),

              SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: height * 0.08), // Responsive top padding
                      // Logo
                      Center(
                        child: SvgPicture.asset(
                          "assets/Images/dude.svg",
                          height: height * 0.18, // Responsive logo size
                        ),
                      ),

                      SizedBox(height: height * 0.08), // Responsive spacing
                      // Title
                      const Text(
                        "What’s your number?",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),

                      const SizedBox(height: 12),

                      Text(
                        "We’ll send you a 4-digit verification code to confirm your number.",
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.75),
                          fontSize: 15.5,
                          height: 1.45,
                        ),
                      ),

                      SizedBox(height: height * 0.04),

                      // Phone Number Field
                      const Text(
                        "Phone Number",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 10),

                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF1C122D).withOpacity(0.85),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: const Color(0xFF2A1F38),
                            width: 1.2,
                          ),
                        ),
                        child: TextField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          maxLength: 10,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                          ),
                          decoration: const InputDecoration(
                            hintText: "Enter 10-digit mobile number",
                            hintStyle: TextStyle(color: Color(0xFF6B5F7A)),
                            prefixText: "+91 ",
                            prefixStyle: TextStyle(
                              color: Color(0xFFB0A8C0),
                              fontSize: 17,
                            ),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 18,
                            ),
                            border: InputBorder.none,
                            counterText: "",
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Referral Code Field
                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF1C122D).withOpacity(0.85),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: const Color(0xFF2A1F38),
                            width: 1.2,
                          ),
                        ),
                        child: TextField(
                          controller: _referralController,
                          keyboardType: TextInputType.text,
                          textCapitalization: TextCapitalization.characters,
                          maxLength: 8,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                          ),
                          decoration: InputDecoration(
                            hintText: "Enter referral code (optional)",
                            hintStyle: const TextStyle(
                              color: Color(0xFF6B5F7A),
                            ),
                            // prefixIcon: Container(
                            //   padding: const EdgeInsets.all(12),
                            //   child: SvgPicture.asset(
                            //     "assets/Images/gift.svg",
                            //     height: 20,
                            //     width: 20,
                            //     colorFilter: const ColorFilter.mode(
                            //       Color(0xFFB86AF6),
                            //       BlendMode.srcIn,
                            //     ),
                            //   ),
                            // ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 18,
                            ),
                            border: InputBorder.none,
                            counterText: "",
                          ),
                        ),
                      ),

                      SizedBox(height: height * 0.05),

                      // Get OTP Button
                      GestureDetector(
                        onTap: vm.isLoading
                            ? null
                            : () async {
                                final phone = _phoneController.text.trim();
                                final referralCode = _referralController.text
                                    .trim();

                                if (phone.isEmpty) {
                                  Utils.snackBarErrorMessage(
                                    "Please enter your phone number",
                                  );
                                  return;
                                }
                                if (!_isValidPhone(phone)) {
                                  Utils.snackBarErrorMessage(
                                    "Enter a valid 10-digit phone number",
                                  );
                                  return;
                                }

                                if (referralCode.isNotEmpty &&
                                    referralCode.length < 4) {
                                  Utils.snackBarErrorMessage(
                                    "Please enter a valid referral code",
                                  );
                                  return;
                                }

                                final success = await context
                                    .read<LoginViewModel>()
                                    .sendOtp(
                                      phone,
                                      referralCode.isEmpty ? "" : referralCode,
                                    );

                                if (success) {
                                  bondNavigator.newPage(
                                    context,
                                    page: LoginOtpScreen(
                                      phoneNumber: phone,
                                      referralCode: referralCode.isEmpty
                                          ? ""
                                          : referralCode,
                                    ),
                                  );
                                } else {
                                  Utils.snackBarErrorMessage(
                                    "Failed to send OTP",
                                  );
                                }
                              },
                        child: Container(
                          height: 56,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            gradient: vm.isLoading
                                ? const LinearGradient(
                                    colors: [Colors.grey, Colors.blueGrey],
                                  )
                                : const LinearGradient(
                                    colors: [
                                      Color(0xFFd2ea46),
                                      Color(0xFFb8d02e),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                            boxShadow: vm.isLoading
                                ? []
                                : [
                                    BoxShadow(
                                      color: const Color(
                                        0xFFd2ea46,
                                      ).withOpacity(0.35),
                                      blurRadius: 16,
                                      offset: const Offset(0, 6),
                                    ),
                                  ],
                          ),
                          alignment: Alignment.center,
                          child: vm.isLoading
                              ? const SizedBox(
                                  height: 24,
                                  width: 24,
                                  child: CircularProgressIndicator(
                                    color: Color(0xFF0E0A14),
                                    strokeWidth: 3,
                                  ),
                                )
                              : const Text(
                                  "Get OTP →",
                                  style: TextStyle(
                                    color: Color(0xFF0E0A14),
                                    fontSize: 17,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.6,
                                  ),
                                ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      Center(
                        child: Text(
                          "Have a referral code? Enter it above to get rewards! 🎁",
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.5),
                            fontSize: 12.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),

                      SizedBox(height: height * 0.04), // Bottom padding
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
