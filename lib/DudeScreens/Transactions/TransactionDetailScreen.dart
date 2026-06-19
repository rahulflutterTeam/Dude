import 'dart:ui';
import 'package:dude/Dude_Utils/DateTimeFormatter/history_time_formatter.dart';
import 'package:dude/DudeScreens/Transactions/Model/TransactionHistoryModel.dart';
import 'package:dude/Reusable_Widgets/AppText_Theme/AppText_Theme.dart';
import 'package:dude/Reusable_Widgets/BondingNavigator.dart';
import 'package:flutter/material.dart';

class TransactionDetailsScreen extends StatelessWidget {
  final DepositHistoryItem transaction;

  const TransactionDetailsScreen({super.key, required this.transaction});

  @override
  Widget build(BuildContext context) {
    final isCompleted = transaction.paymentStatus.toLowerCase() == 'paid';
    final isPending = transaction.paymentStatus.toLowerCase() == 'created';
    final formattedDate = HistoryTimeFormatter.detail(transaction.createdAt);

    return Scaffold(
      backgroundColor: const Color(0xFF0E0A14),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF241b40),
              Color(0xFF12151c),
              Color(0xFF12151c),
              Color(0xFF12151c),
              Color(0xFF12151c),
              Color(0xFF12151c),
              Color(0xFF2b1e4e),
            ],
          ),
        ),
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
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF2c1e4f),
                            borderRadius: BorderRadius.circular(40),
                          ),
                          child: const Padding(
                            padding: EdgeInsets.all(8.0),
                            child: Icon(
                              Icons.arrow_back,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                        ),
                      ),
                      const Spacer(),
                      AppText(
                        "Transaction Details",
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                      const Spacer(),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // User Profile Section
                Column(
                  children: [
                    Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFFe4f773),
                          width: 3,
                        ),
                      ),
                      child: ClipOval(
                        child:
                            transaction.image != null &&
                                transaction.image!.isNotEmpty
                            ? Image.network(
                                transaction.image!,
                                fit: BoxFit.cover,
                              )
                            : Image.asset(
                                "assets/Images/men.png",
                                fit: BoxFit.cover,
                              ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      transaction.userName.isNotEmpty
                          ? transaction.userName
                          : "User",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 21,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "ID: ${transaction.razorpayOrderId.substring(0, 10)}...",
                      style: const TextStyle(
                        color: Color(0xFFB0A8C0),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 30),

                // Amount
                Text(
                  "₹${transaction.totalAmount}",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 42,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),

                const SizedBox(height: 12),

                // Status
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        color: transaction.statusColor.withOpacity(0.15),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: transaction.statusColor,
                          width: 2,
                        ),
                      ),
                      child: Icon(
                        isCompleted
                            ? Icons.check
                            : isPending
                            ? Icons.hourglass_empty
                            : Icons.close,
                        color: transaction.statusColor,
                        size: 14,
                      ),
                    ),
                    const SizedBox(width: 10),
                    AppText(
                      transaction.statusText,
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: transaction.statusColor,
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // Date & Time
                Text(
                  formattedDate,
                  style: const TextStyle(
                    color: Color(0xFFB0A8C0),
                    fontSize: 14,
                  ),
                ),

                const SizedBox(height: 40),

                // Transaction Details Card
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Color(0xFF1c122d),
                          Color(0xFF1c122e),
                          Color(0xFF261247),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: const Color(0xFF2A1F38),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Payment Gateway Header
                        Row(
                          children: [
                            Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color: const Color(0xFF2c1e4f),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Center(
                                child: Icon(
                                  Icons.payment,
                                  color: Color(0xFFe4f773),
                                  size: 32,
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  AppText(
                                    "Razorpay Payment",
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  Text(
                                    "Secure Payment Gateway",
                                    style: TextStyle(
                                      color: Color(0xFFB0A8C0),
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 18),
                          child: Divider(
                            color: Color(0xFF2A1F38),
                            thickness: 1,
                          ),
                        ),

                        // Transaction Details
                        _buildDetailRow(
                          "Transaction ID:",
                          transaction.razorpayOrderId,
                        ),
                        const SizedBox(height: 18),
                        _buildDetailRow(
                          "Payment ID:",
                          transaction.razorpayPaymentId ?? "N/A",
                        ),
                        const SizedBox(height: 18),
                        _buildDetailRow(
                          "Amount:",
                          "₹${transaction.totalAmount} ${transaction.currency}",
                        ),
                        const SizedBox(height: 18),
                        _buildDetailRow(
                          "User:",
                          "${transaction.userName} (${transaction.userPhone})",
                        ),
                        if (transaction.razorpaySignature != null) ...[
                          const SizedBox(height: 18),
                          _buildDetailRow(
                            "Signature:",
                            transaction.razorpaySignature!.length > 20
                                ? "${transaction.razorpaySignature!.substring(0, 20)}..."
                                : transaction.razorpaySignature!,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 50),
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
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFFB0A8C0),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),
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
