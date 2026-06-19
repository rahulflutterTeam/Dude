// lib/DudeScreens/WalletScreen/WithdrawDetailScreen.dart

import 'dart:ui';
import 'package:dude/Dude_Utils/DateTimeFormatter/history_time_formatter.dart';
import 'package:dude/Reusable_Widgets/AppText_Theme/AppText_Theme.dart';
import 'package:dude/Reusable_Widgets/BondingNavigator.dart';
import 'package:dude/StaffScreenScreens/WithdrawScreen/Model/WithdrawHistoryModel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class WithdrawDetailScreen extends StatelessWidget {
  final StaffWithdrawHistoryItem transaction;

  const WithdrawDetailScreen({super.key, required this.transaction});

  @override
  Widget build(BuildContext context) {
    final isPending = transaction.statusCode == 0;
    final isApproved = transaction.statusCode == 1;

    final formattedDate = HistoryTimeFormatter.detail(transaction.createdAt);

    // Masked account number (last 4 digits)
    final maskedAccount = transaction.accountNumber.length > 4
        ? "****${transaction.accountNumber.substring(transaction.accountNumber.length - 4)}"
        : transaction.accountNumber;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        color: const Color(0xFF100a0a),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              children: [
                // Top Bar
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => bondNavigator.backPage(context),
                        child: const Icon(
                          Icons.arrow_back,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 100),
                      AppText(
                        "Withdrawal Details",
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // User / Holder Profile Section
                Column(
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundImage: transaction.image.isNotEmpty
                          ? NetworkImage(transaction.image)
                          : const AssetImage("assets/Images/women.png")
                                as ImageProvider,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      transaction.bankHolderName.isNotEmpty
                          ? transaction.bankHolderName
                          : "Holder Name",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      "Name: ${transaction.name}",
                      style: TextStyle(color: Colors.grey[500], fontSize: 14),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                // Amount (withdrawal amount)
                Text(
                  "₹${transaction.netAmountText}",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 10),

                // Status (with icon & color)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: isPending
                            ? Colors.orange
                            : isApproved
                            ? Colors.green
                            : Colors.red,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isPending
                            ? Icons.hourglass_empty
                            : isApproved
                            ? Icons.check
                            : Icons.close,
                        color: Colors.white,
                        size: 14,
                      ),
                    ),
                    const SizedBox(width: 8),
                    AppText(
                      transaction.statusLabel.toString(),
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: isPending
                          ? Colors.orange
                          : isApproved
                          ? Colors.green
                          : Colors.red,
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // Date & Time
                Text(
                  formattedDate,
                  style: TextStyle(color: Colors.grey[500], fontSize: 14),
                ),

                const SizedBox(height: 40),

                // Withdrawal Details Card
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF35272d).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Payment Method / Bank Info
                        Row(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Center(
                                child:
                                    transaction.upi != null &&
                                        transaction.upi!.isNotEmpty
                                    ? SvgPicture.asset(
                                        "assets/icons/upi_icon.svg",
                                        height: 32,
                                      )
                                    : const Icon(
                                        Icons.account_balance,
                                        color: Colors.black,
                                        size: 32,
                                      ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            AppText(
                              transaction.upi != null &&
                                      transaction.upi!.isNotEmpty
                                  ? "UPI Transfer"
                                  : "Bank Transfer",
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ],
                        ),

                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Divider(color: Colors.grey, thickness: 0.2),
                        ),

                        // Dynamic Details
                        _buildDetailRow("Transaction ID:", transaction.id),
                        const SizedBox(height: 16),
                        if (transaction.upi != null &&
                            transaction.upi!.isNotEmpty) ...[
                          _buildDetailRow("UPI ID:", transaction.upi!),
                          const SizedBox(height: 16),
                          _buildDetailRow(
                            "Confirmed UPI:",
                            transaction.confirmUpi ?? "N/A",
                          ),
                        ] else ...[
                          _buildDetailRow("Account Number:", maskedAccount),
                          const SizedBox(height: 16),
                          _buildDetailRow(
                            "Confirmed Account:",
                            transaction.confirmAccountNumber,
                          ),
                          const SizedBox(height: 16),
                          _buildDetailRow("IFSC:", transaction.ifsc),
                          const SizedBox(height: 16),
                          _buildDetailRow("Bank Name:", transaction.bankNamee),
                        ],
                        const SizedBox(height: 16),
                        _buildDetailRow(
                          "Holder Name:",
                          transaction.bankHolderName,
                        ),
                        const SizedBox(height: 16),
                        _buildDetailRow("Email:", transaction.email),
                        const SizedBox(height: 16),
                        _buildDetailRow("Phone:", transaction.phone),
                        const SizedBox(height: 16),
                        _buildDetailRow(
                          "Requested Amount:",
                          "₹${transaction.requestedAmountText}",
                        ),
                        if (transaction.hasFeeBreakdown) ...[
                          const SizedBox(height: 16),
                          _buildDetailRow(
                            transaction.feeLabel,
                            "- ₹${transaction.feeAmountText}",
                          ),
                          const SizedBox(height: 16),
                          _buildDetailRow(
                            "Final Amount Sent:",
                            "₹${transaction.netAmountText}",
                          ),
                        ],
                        const SizedBox(height: 16),
                        _buildDetailRow(
                          "Status:",
                          transaction.statusLabel.toString(),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 14)),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
