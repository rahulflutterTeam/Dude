import 'package:dude/Dude_Utils/CustomSnackBar/StatusMessage.dart';
import 'package:dude/Reusable_Widgets/BondingNavigator.dart';
import 'package:dude/Reusable_Widgets/Premium_UI/login_auth_shell.dart';
import 'package:dude/Reusable_Widgets/Premium_UI/premium_glass_card.dart';
import 'package:dude/StaffScreenScreens/StaffRegistrationScreen/VerifyOtpStaffScreen.dart';
import 'package:dude/StaffScreenScreens/StaffRegistrationScreen/ViewModel/StaffRegisterVM.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
      Utils.snackBarErrorMessage('Please enter a valid 10-digit phone number');
      return false;
    }
    return true;
  }

  Future<void> _continue(StaffViewModel vm) async {
    if (!_isValidInput()) return;

    final success = await vm.registerStaffNew(
      phone: phoneController.text.trim(),
    );

    if (!mounted) return;

    if (success) {
      bondNavigator.newPage(
        context,
        page: LoginOtpStaffScreen(
          phoneNumber: phoneController.text.trim(),
        ),
      );
    } else {
      Utils.snackBarErrorMessage('Registration failed. Please try again.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<StaffViewModel>(
      builder: (context, vm, child) {
        return LoginAuthShell(
          title: 'Join as staff',
          subtitle:
              'Enter your mobile number — we\'ll send a 4-digit code to verify you.',
          form: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AuthInputField(
                label: 'Mobile number',
                hint: 'Phone number',
                icon: Icons.phone_rounded,
                controller: phoneController,
                keyboardType: TextInputType.phone,
                prefixText: '+91 ',
                maxLength: 10,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),
              if (vm.errorMessage != null) ...[
                const SizedBox(height: 14),
                Text(
                  vm.errorMessage!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFFFF6B6B),
                    fontSize: 13,
                  ),
                ),
              ],
              const SizedBox(height: 24),
              PremiumPrimaryButton(
                label: 'Send code →',
                loading: vm.isRegistering,
                height: 54,
                onTap: vm.isRegistering ? null : () => _continue(vm),
              ),
            ],
          ),
          footer: Center(
            child: Text(
              'Verified female staff · earn through audio & video calls',
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
