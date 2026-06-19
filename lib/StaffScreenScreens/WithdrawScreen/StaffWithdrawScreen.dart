// lib/DudeScreens/WalletScreen/WithdrawAddBank.dart

import 'dart:ui';
import 'package:dude/DudeScreens/WalletScreen/razorPayFlow/ViewModel/PaymentVM.dart';
import 'package:dude/Dude_Utils/CustomSnackBar/StatusMessage.dart';
import 'package:dude/Reusable_Widgets/AppText_Theme/AppText_Theme.dart';
import 'package:dude/Reusable_Widgets/BondingNavigator.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class WithdrawAddBank extends StatefulWidget {
  const WithdrawAddBank({super.key});

  @override
  State<WithdrawAddBank> createState() => _WithdrawAddBankState();
}

class _WithdrawAddBankState extends State<WithdrawAddBank> {
  int _selectedTab = 0; // 0 = Bank, 1 = UPI

  // Bank fields
  final _accountNumberController = TextEditingController();
  final _ifscController = TextEditingController();
  final _accountHolderController = TextEditingController();
  final _bankNameController = TextEditingController();

  // UPI field
  final _upiController = TextEditingController();

  bool _isLoading = false;

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
        Utils.snackBarErrorMessage("Please fill all bank details");
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
        Utils.snackBarErrorMessage("Please enter UPI ID");
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
          body: Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF241b40),
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
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top Bar
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () => bondNavigator.backPage(context),
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFF2A1F38),
                              borderRadius: BorderRadius.circular(40),
                              border: Border.all(color: Colors.white12),
                            ),
                            child: const Icon(
                              Icons.arrow_back,
                              color: Colors.white,
                              size: 26,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        const Text(
                          "Add Bank / UPI",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 32),

                    // Tabs
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF2A1F38),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFF3A2A4A)),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setState(() => _selectedTab = 0),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                decoration: BoxDecoration(
                                  color: _selectedTab == 0
                                      ? const Color(0xFFd9f155)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Center(
                                  child: Text(
                                    "Bank Account",
                                    style: TextStyle(
                                      color: _selectedTab == 0
                                          ? Colors.black
                                          : Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                // setState(() => _selectedTab = 1);
                                Utils.snackBar("UPI coming soon!");
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                decoration: BoxDecoration(
                                  color: _selectedTab == 1
                                      ? const Color(0xFFd9f155)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Center(
                                  child: Text(
                                    "UPI ID",
                                    style: TextStyle(
                                      color: _selectedTab == 1
                                          ? Colors.black
                                          : Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 28),

                    // Form Fields
                    if (_selectedTab == 0) ...[
                      _buildTextField(
                        _accountHolderController,
                        "Account Holder Name",
                        "Enter full name",
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        _accountNumberController,
                        "Account Number",
                        "XXXXXXXXXXXX",
                        TextInputType.number,
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        _ifscController,
                        "IFSC Code",
                        "SBIN0001234",
                        TextInputType.text,
                        TextCapitalization.characters,
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        _bankNameController,
                        "Bank Name",
                        "HDFC Bank",
                      ),
                    ] else ...[
                      _buildTextField(_upiController, "UPI ID", "yourname@upi"),
                    ],

                    const SizedBox(height: 40),

                    // Submit Button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: GestureDetector(
                        onTap: vm.isLoading ? null : _submitDetails,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFd9f155), Color(0xFFd9f155)],
                            ),
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFd9f155).withOpacity(0.4),
                                blurRadius: 12,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Center(
                            child: vm.isLoading
                                ? const SizedBox(
                                    height: 26,
                                    width: 26,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 3,
                                    ),
                                  )
                                : const Text(
                                    "Save Details",
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Note Box
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2A1F38),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFF3A2A4A)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.info_outline,
                            color: Color(0xFFd9f155),
                            size: 28,
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              "Bank/UPI details are required for withdrawal. Ensure accuracy. Verification may take 24-48 hours.",
                              style: TextStyle(
                                color: Color(0xFFB0A8C0),
                                fontSize: 14,
                                height: 1.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    String hint, [
    TextInputType keyboardType = TextInputType.text,
    TextCapitalization textCapitalization = TextCapitalization.none,
  ]) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFFB0A8C0),
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          textCapitalization: textCapitalization,
          style: const TextStyle(color: Colors.white, fontSize: 16),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Color(0xFF6B5F7A)),
            filled: true,
            fillColor: const Color(0xFF1C1426),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF2E2040)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF2E2040)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Color(0xFFd9f155),
                width: 1.5,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
