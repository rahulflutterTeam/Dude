import 'package:dude/DudeScreens/LoginScreens/LoginOtpScreen.dart';
import 'package:dude/DudeScreens/LoginScreens/ViewModel/LoginVM.dart';
import 'package:dude/Dude_Utils/CustomSnackBar/StatusMessage.dart';
import 'package:dude/Reusable_Widgets/BondingNavigator.dart';
import 'package:dude/Reusable_Widgets/Premium_UI/login_auth_shell.dart';
import 'package:dude/Reusable_Widgets/Premium_UI/premium_glass_card.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _referralController = TextEditingController();

  bool _isValidPhone(String phone) {
    return RegExp(r'^[6-9]\d{9}$').hasMatch(phone);
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _referralController.dispose();
    super.dispose();
  }

  Future<void> _sendOtp(LoginViewModel vm) async {
    final phone = _phoneController.text.trim();
    final referralCode = _referralController.text.trim();

    if (phone.isEmpty) {
      Utils.snackBarErrorMessage("Please enter your phone number");
      return;
    }
    if (!_isValidPhone(phone)) {
      Utils.snackBarErrorMessage("Enter a valid 10-digit phone number");
      return;
    }
    if (referralCode.isNotEmpty && referralCode.length < 4) {
      Utils.snackBarErrorMessage("Please enter a valid referral code");
      return;
    }

    final success = await vm.sendOtp(
      phone,
      referralCode.isEmpty ? "" : referralCode,
    );

    if (!mounted) return;

    if (success) {
      bondNavigator.newPage(
        context,
        page: LoginOtpScreen(
          phoneNumber: phone,
          referralCode: referralCode.isEmpty ? "" : referralCode,
        ),
      );
    } else {
      Utils.snackBarErrorMessage("Failed to send OTP");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LoginViewModel>(
      builder: (context, vm, _) {
        return LoginAuthShell(
          title: "Join the vibe",
          subtitle:
              "Drop your number — we'll text you a quick 4-digit code. No spam.",
          form: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AuthInputField(
                label: "Mobile number",
                hint: "Phone number",
                icon: Icons.phone_rounded,
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                prefixText: "+91 ",
                maxLength: 10,
              ),
              const SizedBox(height: 16),
              AuthInputField(
                hint: "Invite code (optional)",
                controller: _referralController,
                icon: Icons.card_giftcard_rounded,
                maxLength: 8,
                textCapitalization: TextCapitalization.characters,
              ),
              const SizedBox(height: 24),
              PremiumPrimaryButton(
                label: "Send code →",
                loading: vm.isLoading,
                height: 54,
                onTap: vm.isLoading ? null : () => _sendOtp(vm),
              ),
            ],
          ),
          footer: Center(
            child: Text(
              "Invite codes unlock bonus coins ✨",
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.45),
                fontSize: 12.5,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        );
      },
    );
  }
}
