import 'dart:ui';
import 'package:dude/Dude_Utils/DateTimeFormatter/history_time_formatter.dart';
import 'package:dude/DudeScreens/Transactions/Model/TransactionHistoryModel.dart';
import 'package:dude/Reusable_Widgets/AppText_Theme/AppText_Theme.dart';
import 'package:dude/Reusable_Widgets/BondingNavigator.dart';
import 'package:dude/Dude_Utils/App_Theme/DudeTheme.dart';
import 'package:dude/Reusable_Widgets/Premium_UI/premium_ambient_background.dart';
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
      backgroundColor: DudeTheme.background,
      body: PremiumAmbientBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => bondNavigator.backPage(context),
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
                      const Expanded(
                        child: Text(
                          'Transaction Details',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: DudeTheme.textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 42),
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
                          color: DudeTheme.accent,
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
                        color: DudeTheme.textMid,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 30),

                // Amount
                ShaderMask(
                  blendMode: BlendMode.srcIn,
                  shaderCallback: (bounds) =>
                      DudeTheme.premiumAccentGradient.createShader(bounds),
                  child: Text(
                    '₹${transaction.totalAmount}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 42,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
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
                    color: DudeTheme.textMid,
                    fontSize: 14,
                  ),
                ),

                const SizedBox(height: 40),

                // Transaction Details Card
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              DudeTheme.surface.withValues(alpha: 0.92),
                              DudeTheme.accentDim.withValues(alpha: 0.4),
                              DudeTheme.surfaceRaised.withValues(alpha: 0.82),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: DudeTheme.accent.withValues(alpha: 0.35),
                          ),
                          boxShadow: DudeTheme.accentGlowShadow(
                            blur: 16,
                            spread: -6,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 50,
                                  height: 50,
                                  decoration: BoxDecoration(
                                    gradient: DudeTheme.premiumAccentGradient,
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: DudeTheme.accentGlowShadow(
                                      blur: 12,
                                      spread: -4,
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.payment_rounded,
                                    color: DudeTheme.textOnAccent,
                                    size: 28,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      AppText(
                                        'Razorpay Payment',
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      Text(
                                        'Secure Payment Gateway',
                                        style: TextStyle(
                                          color: DudeTheme.textMid,
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
                                color: DudeTheme.border,
                                thickness: 1,
                              ),
                            ),
                            _buildDetailRow(
                              'Transaction ID:',
                              transaction.razorpayOrderId,
                            ),
                            const SizedBox(height: 18),
                            _buildDetailRow(
                              'Payment ID:',
                              transaction.razorpayPaymentId ?? 'N/A',
                            ),
                            const SizedBox(height: 18),
                            _buildDetailRow(
                              'Amount:',
                              '₹${transaction.totalAmount} ${transaction.currency}',
                            ),
                            const SizedBox(height: 18),
                            _buildDetailRow(
                              'User:',
                              '${transaction.userName} (${transaction.userPhone})',
                            ),
                            if (transaction.razorpaySignature != null) ...[
                              const SizedBox(height: 18),
                              _buildDetailRow(
                                'Signature:',
                                transaction.razorpaySignature!.length > 20
                                    ? '${transaction.razorpaySignature!.substring(0, 20)}...'
                                    : transaction.razorpaySignature!,
                              ),
                            ],
                          ],
                        ),
                      ),
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
            color: DudeTheme.textMid,
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
