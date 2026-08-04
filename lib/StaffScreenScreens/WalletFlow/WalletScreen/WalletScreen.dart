// lib/DudeScreens/WalletScreen/StaffWalletScreen.dart

import 'dart:ui';
import 'package:dude/Dude_Utils/App_Theme/DudeTheme.dart';
import 'package:dude/Reusable_Widgets/Premium_UI/premium_ambient_background.dart';

import 'package:dude/Dude_Utils/DateTimeFormatter/history_time_formatter.dart';
import 'package:dude/DudeScreens/WalletScreen/razorPayFlow/ViewModel/PaymentVM.dart';
import 'package:dude/Reusable_Widgets/AppText_Theme/AppText_Theme.dart';
import 'package:dude/Reusable_Widgets/BondingNavigator.dart';
import 'package:dude/StaffScreenScreens/StaffRegistrationScreen/ViewModel/StaffRegisterVM.dart';
import 'package:dude/StaffScreenScreens/WithdrawScreen/WithdrawRequestScreen.dart';
import 'package:dude/Reusable_Widgets/Premium_UI/dude_logo.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class StaffWalletScreen extends StatefulWidget {
  const StaffWalletScreen({super.key});

  @override
  State<StaffWalletScreen> createState() => _StaffWalletScreenState();
}

class _StaffWalletScreenState extends State<StaffWalletScreen> {
  int _selectedTab = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<WalletViewModel>().fetchStaffWithdrawHistory();
    });
  }

  void _changeTab(int index) {
    if (_selectedTab == index) return;
    setState(() => _selectedTab = index);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<WalletViewModel>(
      builder: (context, vm, child) {
        final staffVM = context.read<StaffViewModel>();
        final staff = staffVM.currentStaff;
        final totalBalance =
            staff?.pendingBalance!.toStringAsFixed(2) ?? "0.00";

        String headerYear = HistoryTimeFormatter.year(DateTime.now());
        String headerMonth = HistoryTimeFormatter.month(DateTime.now());

        if (vm.withdrawHistory.isNotEmpty) {
          final latest = vm.withdrawHistory.reduce(
            (a, b) => a.createdAt.isAfter(b.createdAt) ? a : b,
          );
          headerYear = HistoryTimeFormatter.year(latest.createdAt);
          headerMonth = HistoryTimeFormatter.month(latest.createdAt);
        }

        return Scaffold(
          backgroundColor: DudeTheme.background,
      body: PremiumAmbientBackground(
        child: SafeArea(
              child: vm.isLoadingWithdraw
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: DudeTheme.accent,
                      ),
                    )
                  : vm.withdrawError != null
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            vm.withdrawError!,
                            style: const TextStyle(color: Colors.redAccent),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: vm.fetchStaffWithdrawHistory,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: DudeTheme.accent,
                            ),
                            child: const Text("Retry"),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: vm.fetchStaffWithdrawHistory,
                      color: DudeTheme.accent,
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        child: Column(
                          children: [
                            // Top Bar
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              child: Row(
                                children: [
                                  GestureDetector(
                                    onTap: () =>
                                        bondNavigator.backPage(context),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: DudeTheme.surface,
                                        borderRadius: BorderRadius.circular(40),
                                        border: Border.all(
                                          color: Colors.white12,
                                        ),
                                      ),
                                      child: const Padding(
                                        padding: EdgeInsets.all(10),
                                        child: Icon(
                                          Icons.arrow_back,
                                          color: Colors.white,
                                          size: 26,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const Spacer(),
                                  const DudeLogo(height: 40),
                                  const Spacer(),
                                  const SizedBox(width: 40),
                                ],
                              ),
                            ),

                            // Balance Card
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              child: Container(
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(24),
                                  gradient: DudeTheme.premiumAccentGradient,
                                  boxShadow: DudeTheme.accentGlowShadow(blur: 18, spread: -4),
                                ),
                                child: Column(
                                  children: [
                                    Text(
                                      "Total Balance",
                                      style: TextStyle(
                                        color: DudeTheme.textOnAccent.withValues(alpha: 0.85),
                                        fontSize: 15,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      "₹${totalBalance.toString()}",
                                      style: const TextStyle(
                                        color: DudeTheme.textOnAccent,
                                        fontSize: 38,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            const SizedBox(height: 20),

                            // Withdraw Button
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              child: GestureDetector(
                                onTap: () => bondNavigator.newPage(
                                  context,
                                  page: WithdrawalRequestScreen(
                                    withdrawAmount: totalBalance.toString(),
                                  ),
                                ),
                                child: Container(
                                  height: 58,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(16),
                                    gradient: DudeTheme.premiumAccentGradient,
                                    boxShadow: DudeTheme.accentGlowShadow(blur: 20, spread: -2),
                                  ),
                                  child: const Center(
                                    child: Text(
                                      "Withdraw Now",
                                      style: TextStyle(
                                        color: DudeTheme.textOnAccent,
                                        fontSize: 18,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 30),

                            // Month Header
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        headerYear,
                                        style: TextStyle(
                                          color: DudeTheme.textMid,
                                          fontSize: 14,
                                        ),
                                      ),
                                      Text(
                                        headerMonth,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 22,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Text(
                                    "₹${vm.withdrawHistory.fold<double>(0.0, (sum, txn) => sum + txn.amount).toStringAsFixed(0)}",
                                    style: TextStyle(
                                      color: DudeTheme.accent,
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 16),

                            // Transaction List
                            ...vm.withdrawHistory.map(
                              (txn) => _TransactionItem(
                                title: txn.upi != null && txn.upi!.isNotEmpty
                                    ? "UPI Transfer"
                                    : "Bank Transfer",
                                status: txn.statusLabel.toString(),
                                amount: "₹${txn.amountText}",
                                date: HistoryTimeFormatter.shortDate(
                                  txn.createdAt,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
            ),
          ),
        );
      },
    );
  }
}

// Transaction Item
class _TransactionItem extends StatelessWidget {
  final String title;
  final String status;
  final String amount;
  final String date;

  const _TransactionItem({
    required this.title,
    required this.status,
    required this.amount,
    required this.date,
  });

  @override
  Widget build(BuildContext context) {
    final isPending = status.toLowerCase().contains("pending");
    final isReject = status.toLowerCase().contains("rejected");
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: DudeTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: DudeTheme.border),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: DudeTheme.surface,
            child: Icon(
              title.contains("UPI") ? Icons.qr_code : Icons.account_balance,
              color: DudeTheme.accent,
              size: 26,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  "$status • $date",
                  style: TextStyle(
                    color: isPending
                        ? Colors.orange
                        : isReject
                        ? Colors.red
                        : DudeTheme.online,
                    fontSize: 13.5,
                  ),
                ),
              ],
            ),
          ),
          Text(
            amount,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
