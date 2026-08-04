import 'package:dude/DudeScreens/WalletScreen/razorPayFlow/ViewModel/PaymentVM.dart';
import 'package:dude/Dude_Utils/App_Theme/DudeTheme.dart';
import 'package:dude/Dude_Utils/CustomSnackBar/StatusMessage.dart';
import 'package:dude/Reusable_Widgets/BondingNavigator.dart';
import 'package:dude/Reusable_Widgets/Premium_UI/premium_ambient_background.dart';
import 'package:dude/Reusable_Widgets/Premium_UI/premium_animations.dart';
import 'package:dude/Reusable_Widgets/Premium_UI/premium_glass_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

class WithdrawAddBank extends StatefulWidget {
  const WithdrawAddBank({super.key});

  @override
  State<WithdrawAddBank> createState() => _WithdrawAddBankState();
}

class _WithdrawAddBankState extends State<WithdrawAddBank> {
  int _selectedTab = 0; // 0 = Bank, 1 = UPI

  final _accountNumberController = TextEditingController();
  final _ifscController = TextEditingController();
  final _accountHolderController = TextEditingController();
  final _bankNameController = TextEditingController();
  final _upiController = TextEditingController();

  @override
  void dispose() {
    _accountNumberController.dispose();
    _ifscController.dispose();
    _accountHolderController.dispose();
    _bankNameController.dispose();
    _upiController.dispose();
    super.dispose();
  }

  void _submitDetails() {
    final vm = context.read<WalletViewModel>();

    if (_selectedTab == 0) {
      if (_accountNumberController.text.isEmpty ||
          _ifscController.text.isEmpty ||
          _accountHolderController.text.isEmpty ||
          _bankNameController.text.isEmpty) {
        Utils.snackBarErrorMessage('Please fill all bank details');
        return;
      }

      vm.addBankOrUpiDetails(
        accountNumber: _accountNumberController.text.trim(),
        ifsc: _ifscController.text.trim().toUpperCase(),
        bankHolderName: _accountHolderController.text.trim(),
        bankName: _bankNameController.text.trim(),
        context: context,
      );
    } else {
      if (_upiController.text.isEmpty) {
        Utils.snackBarErrorMessage('Please enter UPI ID');
        return;
      }

      vm.addBankOrUpiDetails(upi: _upiController.text.trim(), context: context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<WalletViewModel>(
      builder: (context, vm, child) {
        return Scaffold(
          backgroundColor: DudeTheme.background,
          body: PremiumAmbientBackground(
            child: SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () {
                            HapticFeedback.lightImpact();
                            bondNavigator.backPage(context);
                          },
                          child: Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: DudeTheme.surface.withValues(alpha: 0.8),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: DudeTheme.border.withValues(alpha: 0.5),
                              ),
                            ),
                            child: const Icon(
                              Icons.arrow_back_ios_new_rounded,
                              color: DudeTheme.textPrimary,
                              size: 18,
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        const Text(
                          'Add Bank / UPI',
                          style: TextStyle(
                            color: DudeTheme.textPrimary,
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      physics: PremiumAnimations.scrollPhysics,
                      padding: const EdgeInsets.fromLTRB(16, 24, 16, 28),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildTabSwitcher(),
                          const SizedBox(height: 24),
                          if (_selectedTab == 0) ...[
                            _buildTextField(
                              controller: _accountHolderController,
                              label: 'Account Holder Name',
                              hint: 'Enter full name',
                            ),
                            const SizedBox(height: 16),
                            _buildTextField(
                              controller: _accountNumberController,
                              label: 'Account Number',
                              hint: 'XXXXXXXXXXXX',
                              keyboardType: TextInputType.number,
                            ),
                            const SizedBox(height: 16),
                            _buildTextField(
                              controller: _ifscController,
                              label: 'IFSC Code',
                              hint: 'SBIN0001234',
                              textCapitalization: TextCapitalization.characters,
                            ),
                            const SizedBox(height: 16),
                            _buildTextField(
                              controller: _bankNameController,
                              label: 'Bank Name',
                              hint: 'HDFC Bank',
                            ),
                          ] else ...[
                            _buildTextField(
                              controller: _upiController,
                              label: 'UPI ID',
                              hint: 'yourname@upi',
                            ),
                          ],
                          const SizedBox(height: 32),
                          PremiumPrimaryButton(
                            label: 'Save Details',
                            loading: vm.isLoading,
                            height: 54,
                            onTap: vm.isLoading ? null : _submitDetails,
                          ),
                          const SizedBox(height: 18),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: DudeTheme.surface.withValues(alpha: 0.8),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: DudeTheme.accent.withValues(alpha: 0.35),
                              ),
                            ),
                            child: const Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  Icons.info_outline_rounded,
                                  color: DudeTheme.accentBright,
                                  size: 20,
                                ),
                                SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    'Bank/UPI details are required for withdrawal. Ensure accuracy. Verification may take 24–48 hours.',
                                    style: TextStyle(
                                      color: DudeTheme.textMuted,
                                      fontSize: 13.5,
                                      height: 1.45,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTabSwitcher() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: DudeTheme.surfaceRaised.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: DudeTheme.border.withValues(alpha: 0.45)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _TabChip(
              label: 'Bank Account',
              selected: _selectedTab == 0,
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() => _selectedTab = 0);
              },
            ),
          ),
          Expanded(
            child: _TabChip(
              label: 'UPI ID',
              selected: _selectedTab == 1,
              onTap: () {
                HapticFeedback.selectionClick();
                Utils.snackBar('UPI coming soon!');
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    TextCapitalization textCapitalization = TextCapitalization.none,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: DudeTheme.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: DudeTheme.background.withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: DudeTheme.border.withValues(alpha: 0.45)),
          ),
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            textCapitalization: textCapitalization,
            style: const TextStyle(color: DudeTheme.textPrimary, fontSize: 16),
            cursorColor: DudeTheme.accent,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(color: DudeTheme.textSubtle),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
              border: InputBorder.none,
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(
                  color: DudeTheme.accent,
                  width: 1.4,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _TabChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _TabChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          gradient: selected ? DudeTheme.premiumAccentGradient : null,
          color: selected ? null : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          boxShadow: selected
              ? DudeTheme.accentGlowShadow(blur: 12, spread: -4)
              : null,
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: selected ? DudeTheme.textOnAccent : DudeTheme.textMuted,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}
