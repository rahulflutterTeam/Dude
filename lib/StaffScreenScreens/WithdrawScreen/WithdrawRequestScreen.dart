// lib/DudeScreens/WalletScreen/WithdrawalRequestScreen.dart

import 'dart:ui';
import 'package:dude/DudeScreens/WalletScreen/razorPayFlow/ViewModel/PaymentVM.dart';
import 'package:dude/Dude_Utils/CustomSnackBar/StatusMessage.dart';
import 'package:dude/Reusable_Widgets/BondingNavigator.dart';
import 'package:dude/StaffScreenScreens/StaffRegistrationScreen/ViewModel/StaffRegisterVM.dart';
import 'package:dude/StaffScreenScreens/WithdrawScreen/Model/BankDetailModel.dart';
import 'package:dude/StaffScreenScreens/WithdrawScreen/StaffWithdrawScreen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class WithdrawalRequestScreen extends StatefulWidget {
  final String withdrawAmount;
  const WithdrawalRequestScreen({super.key, required this.withdrawAmount});

  @override
  State<WithdrawalRequestScreen> createState() =>
      _WithdrawalRequestScreenState();
}

class _WithdrawalRequestScreenState extends State<WithdrawalRequestScreen> {
  final TextEditingController _amountController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _amountController.text = widget.withdrawAmount;
    _amountController.addListener(_refreshFeePreview);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final vm = context.read<WalletViewModel>();
      final staffVM = context.read<StaffViewModel>();
      vm.fetchBankDetails();
      if (staffVM.currentStaff != null &&
          staffVM.feeManagement == null &&
          !staffVM.isLoadingFeeManagement) {
        staffVM.fetchFeeManagement();
      }
    });
  }

  @override
  void dispose() {
    _amountController.removeListener(_refreshFeePreview);
    _amountController.dispose();
    super.dispose();
  }

  void _refreshFeePreview() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _confirmDelete(BankDetailItem detail) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF241b40),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          "Delete Detail?",
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          detail.isUpi
              ? "Delete UPI: ${detail.upi ?? 'N/A'}?"
              : "Delete Bank: ****${detail.accountNumber?.substring(detail.accountNumber!.length - 4) ?? 'N/A'}?",
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              "Cancel",
              style: TextStyle(color: Colors.white70),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              "Delete",
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      if (!mounted) return;
      final vm = context.read<WalletViewModel>();
      await vm.deleteBankDetail(detail.id);
    }
  }

  Future<void> _submitWithdrawal() async {
    final vm = context.read<WalletViewModel>();
    final staffVM = context.read<StaffViewModel>();

    if (_amountController.text.isEmpty ||
        double.tryParse(_amountController.text) == null) {
      Utils.snackBarErrorMessage("Please enter a valid amount");
      return;
    }

    final amount = double.parse(_amountController.text);
    final availableBalance = double.parse(widget.withdrawAmount);

    if (amount < 200) {
      Utils.snackBarErrorMessage("Minimum withdrawal amount is ₹200");
      return;
    }

    if (amount > availableBalance) {
      Utils.snackBarErrorMessage("Amount exceeds available balance");
      return;
    }

    final fee = staffVM.staffWithdrawalFeeFor(amount);
    final netAmount = staffVM.staffWithdrawalNetAmountFor(amount);

    if (fee >= amount) {
      Utils.snackBarErrorMessage(
        "Withdrawal amount must be greater than the fee",
      );
      return;
    }

    if (vm.bankDetails.isEmpty) {
      Utils.snackBarErrorMessage(
        "No saved bank/UPI details. Please add one first.",
      );
      return;
    }

    final detail = vm.bankDetails.first;

    final confirmed = await _showWithdrawalConfirmDialog(
      staffVM: staffVM,
      amount: amount,
      fee: fee,
      netAmount: netAmount,
      detail: detail,
    );

    if (confirmed != true || !mounted) return;

    final netSubmitAmount = vm.normalizedMoney(netAmount);
    final requestedSubmitAmount = vm.normalizedMoney(amount);
    final feeSubmitAmount = vm.normalizedMoney(fee);
    final feePercent = staffVM.staffWithdrawalFeePercent();

    vm.submitStaffWithdrawal(
      accountNumber: detail.accountNumber ?? '',
      confirmAccountNumber: detail.accountNumber ?? '',
      ifsc: detail.ifsc ?? '',
      bankHolderName: detail.bankHolderName ?? '',
      bankName: detail.bankName ?? '',
      upi: detail.upi ?? '',
      confirmUpi: detail.upi ?? '',
      amount: netSubmitAmount,
      requestedAmount: requestedSubmitAmount,
      withdrawFeeAmount: feeSubmitAmount,
      withdrawFeePercent: feePercent > 0
          ? vm.normalizedMoney(feePercent)
          : null,
      netAmount: netSubmitAmount,
      context: context,
    );
  }

  Future<bool?> _showWithdrawalConfirmDialog({
    required StaffViewModel staffVM,
    required double amount,
    required double fee,
    required double netAmount,
    required BankDetailItem detail,
  }) {
    final feeLabel = staffVM.staffWithdrawalFeeLabel();
    final accountText = detail.isUpi
        ? (detail.upi ?? 'UPI')
        : detail.accountNumber != null && detail.accountNumber!.length > 4
        ? 'Bank ****${detail.accountNumber!.substring(detail.accountNumber!.length - 4)}'
        : 'Bank account';

    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: const Color(0xFF1C1426),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    height: 40,
                    width: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFFaecc01).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.account_balance_wallet_outlined,
                      color: Color(0xFFaecc01),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      "Confirm Withdrawal",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Text(
                accountText,
                style: const TextStyle(
                  color: Color(0xFFB0A8C0),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 16),
              _buildConfirmRow("Requested amount", "₹${_formatAmount(amount)}"),
              const SizedBox(height: 10),
              _buildConfirmRow(
                "Withdrawal fee ($feeLabel)",
                "- ₹${_formatAmount(fee)}",
                valueColor: Colors.orangeAccent,
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 14),
                child: Divider(color: Color(0xFF3A2A4A), height: 1),
              ),
              _buildConfirmRow(
                "Amount sent to bank",
                "₹${_formatAmount(netAmount)}",
                isTotal: true,
              ),
              const SizedBox(height: 14),
              const Text(
                "Only the final amount after fee deduction will be submitted.",
                style: TextStyle(
                  color: Color(0xFFB0A8C0),
                  fontSize: 12,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context, false),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFF3A2A4A)),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text("Cancel"),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFaecc01),
                        foregroundColor: Colors.black,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        "Confirm",
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildConfirmRow(
    String label,
    String value, {
    bool isTotal = false,
    Color? valueColor,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: isTotal ? Colors.white : const Color(0xFFB0A8C0),
              fontSize: isTotal ? 15 : 13,
              fontWeight: isTotal ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          value,
          style: TextStyle(
            color:
                valueColor ??
                (isTotal ? const Color(0xFFaecc01) : Colors.white),
            fontSize: isTotal ? 18 : 14,
            fontWeight: isTotal ? FontWeight.w900 : FontWeight.w700,
          ),
        ),
      ],
    );
  }

  String _formatAmount(double value) {
    if (value == value.roundToDouble()) {
      return value.toStringAsFixed(0);
    }

    return value.toStringAsFixed(2);
  }

  Widget _buildFeeSummary({
    required StaffViewModel staffVM,
    required double amount,
    required double fee,
    required double netAmount,
  }) {
    if (staffVM.isLoadingFeeManagement) {
      return const Row(
        children: [
          SizedBox(
            height: 16,
            width: 16,
            child: CircularProgressIndicator(
              color: Color(0xFFaecc01),
              strokeWidth: 2,
            ),
          ),
          SizedBox(width: 10),
          Text(
            "Checking withdrawal fee...",
            style: TextStyle(color: Color(0xFFB0A8C0), fontSize: 13),
          ),
        ],
      );
    }

    if (staffVM.feeManagementError != null ||
        staffVM.staffWithdrawalFeeConfig == null) {
      return const Text(
        "Withdrawal fee will be confirmed while processing.",
        style: TextStyle(color: Color(0xFFB0A8C0), fontSize: 13),
      );
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1426),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF3A2A4A)),
      ),
      child: Column(
        children: [
          _buildFeeRow("Withdrawal amount", "₹${_formatAmount(amount)}"),
          const SizedBox(height: 8),
          _buildFeeRow("Fee deduction", "- ₹${_formatAmount(fee)}"),
          const Divider(height: 20, color: Color(0xFF3A2A4A)),
          _buildFeeRow(
            "You will receive",
            "₹${_formatAmount(netAmount)}",
            isTotal: true,
          ),
        ],
      ),
    );
  }

  Widget _buildFeeRow(String label, String value, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: isTotal ? Colors.white : const Color(0xFFB0A8C0),
            fontSize: isTotal ? 15 : 13,
            fontWeight: isTotal ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: isTotal ? const Color(0xFFaecc01) : Colors.white,
            fontSize: isTotal ? 16 : 14,
            fontWeight: isTotal ? FontWeight.w800 : FontWeight.w600,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<WalletViewModel>(
      builder: (context, vm, child) {
        final staffVM = context.watch<StaffViewModel>();
        final hasDetails = vm.bankDetails.isNotEmpty;
        final enteredAmount =
            double.tryParse(_amountController.text.trim()) ?? 0;
        final withdrawalFee = staffVM.staffWithdrawalFeeFor(enteredAmount);
        final netAmount = staffVM.staffWithdrawalNetAmountFor(enteredAmount);

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
              child: vm.isFetchingBankDetails
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFFB86AF6),
                      ),
                    )
                  : SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
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
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white12),
                                  ),
                                  child: const Icon(
                                    Icons.arrow_back,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              const Text(
                                "Withdrawal Request",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 32),

                          if (!hasDetails)
                            // No Details Prompt
                            GestureDetector(
                              onTap: () {
                                bondNavigator.newPage(
                                  context,
                                  page: const WithdrawAddBank(),
                                );
                              },
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF2A1F38),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: const Color(0xFF3A2A4A),
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    const Icon(
                                      Icons.account_balance_wallet_outlined,
                                      color: Color(0xFFd9f155),
                                      size: 60,
                                    ),
                                    const SizedBox(height: 16),
                                    const Text(
                                      "No Bank / UPI Details Added",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    const Text(
                                      "Add your bank account or UPI ID to withdraw earnings",
                                      style: TextStyle(
                                        color: Color(0xFFB0A8C0),
                                        fontSize: 14,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 20),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 32,
                                        vertical: 14,
                                      ),
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(
                                          colors: [
                                            Color(0xFFd9f155),
                                            Color(0xFFd9f155),
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: const Text(
                                        "Add Bank / UPI",
                                        style: TextStyle(
                                          color: Colors.black,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          else ...[
                            // Saved Details
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: const Color(0xFF2A1F38),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: const Color(0xFF3A2A4A),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    "Saved Account Details",
                                    style: TextStyle(
                                      color: Color(0xFFB0A8C0),
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  ...vm.bankDetails.map((detail) {
                                    return Padding(
                                      padding: const EdgeInsets.only(
                                        bottom: 12,
                                      ),
                                      child: Container(
                                        padding: const EdgeInsets.all(14),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF1C1426),
                                          borderRadius: BorderRadius.circular(
                                            14,
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(
                                              detail.isUpi
                                                  ? Icons.qr_code_rounded
                                                  : Icons.account_balance,
                                              color: const Color(0xFFaecc01),
                                              size: 26,
                                            ),
                                            const SizedBox(width: 14),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    detail.isUpi
                                                        ? "UPI ID"
                                                        : "Bank Account",
                                                    style: const TextStyle(
                                                      color: Color(0xFFB0A8C0),
                                                      fontSize: 13,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    detail.displayText,
                                                    style: const TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 15.5,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            GestureDetector(
                                              onTap: () =>
                                                  _confirmDelete(detail),
                                              child: const Icon(
                                                Icons.delete_outline,
                                                color: Colors.redAccent,
                                                size: 22,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  }),
                                ],
                              ),
                            ),

                            const SizedBox(height: 24),

                            // Amount Input
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: const Color(0xFF2A1F38),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: const Color(0xFF3A2A4A),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    "Enter Amount (₹)",
                                    style: TextStyle(
                                      color: Color(0xFFB0A8C0),
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(14),
                                    child: BackdropFilter(
                                      filter: ImageFilter.blur(
                                        sigmaX: 10,
                                        sigmaY: 10,
                                      ),
                                      child: Container(
                                        height: 58,
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(
                                            14,
                                          ),
                                          border: Border.all(
                                            color: const Color(
                                              0xFFB86AF6,
                                            ).withOpacity(0.3),
                                          ),
                                        ),
                                        child: TextField(
                                          controller: _amountController,
                                          keyboardType: TextInputType.number,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 28,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          decoration: const InputDecoration(
                                            hintText: "0",
                                            hintStyle: TextStyle(
                                              color: Colors.white38,
                                              fontSize: 28,
                                            ),
                                            prefixText: "₹ ",
                                            prefixStyle: TextStyle(
                                              color: Colors.white,
                                              fontSize: 28,
                                              fontWeight: FontWeight.bold,
                                            ),
                                            border: InputBorder.none,
                                            contentPadding:
                                                EdgeInsets.symmetric(
                                                  horizontal: 16,
                                                ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),

                                  const SizedBox(height: 16),
                                  _buildFeeSummary(
                                    staffVM: staffVM,
                                    amount: enteredAmount,
                                    fee: withdrawalFee,
                                    netAmount: netAmount,
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 40),

                            // Action Buttons
                            Row(
                              children: [
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () =>
                                        bondNavigator.backPage(context),
                                    child: Container(
                                      height: 54,
                                      decoration: BoxDecoration(
                                        border: Border.all(
                                          color: const Color(
                                            0xFFB0A8C0,
                                          ).withOpacity(0.4),
                                        ),
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: const Center(
                                        child: Text(
                                          "Cancel",
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: GestureDetector(
                                    onTap: vm.isLoading
                                        ? null
                                        : _submitWithdrawal,
                                    child: Container(
                                      height: 54,
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(
                                          colors: [
                                            Color(0xFFaecc01),
                                            Color(0xFFaecc01),
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(16),
                                        boxShadow: [
                                          BoxShadow(
                                            color: const Color(
                                              0xFFaecc01,
                                            ).withOpacity(0.4),
                                            blurRadius: 12,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: Center(
                                        child: vm.isLoading
                                            ? const SizedBox(
                                                height: 24,
                                                width: 24,
                                                child:
                                                    CircularProgressIndicator(
                                                      color: Colors.white,
                                                      strokeWidth: 3,
                                                    ),
                                              )
                                            : const Text(
                                                "Confirm Withdrawal",
                                                style: TextStyle(
                                                  color: Colors.black,
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 40),
                          ],
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
