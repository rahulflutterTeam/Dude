// lib/DudeScreens/WalletScreen/WithdrawHistory.dart

import 'dart:ui';
import 'package:dude/Dude_Utils/App_Theme/DudeTheme.dart';
import 'package:dude/Dude_Utils/DateTimeFormatter/history_time_formatter.dart';
import 'package:dude/DudeScreens/WalletScreen/razorPayFlow/ViewModel/PaymentVM.dart';
import 'package:dude/Reusable_Widgets/BondingNavigator.dart';
import 'package:dude/Reusable_Widgets/Premium_UI/premium_ambient_background.dart';
import 'package:dude/Reusable_Widgets/Premium_UI/premium_animations.dart';
import 'package:dude/Reusable_Widgets/Premium_UI/premium_stagger.dart';
import 'package:dude/StaffScreenScreens/StaffBottomNavBar/StaffBottomNavBar.dart';
import 'package:dude/StaffScreenScreens/WithdrawScreen/Model/WithdrawHistoryModel.dart';
import 'package:dude/StaffScreenScreens/WithdrawScreen/WithdrawDetailPage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

// ── Helper class to handle status mapping ─────────────────────────────────
class WithdrawalStatus {
  final String displayText;
  final Color color;
  final Color bgColor;
  final IconData icon;

  WithdrawalStatus({
    required this.displayText,
    required this.color,
    required this.bgColor,
    required this.icon,
  });

  // Map backend status codes to UI representation based on StaffWithdrawHistoryItem
  factory WithdrawalStatus.fromStatusCode(int statusCode, String statusLabel) {
    // statusCode: 0 = Pending/Processing, 1 = Approved/Success, 2 = Rejected/Failed
    switch (statusCode) {
      case 1:
        return WithdrawalStatus(
          displayText: 'APPROVED',
          color: DudeTheme.success,
          bgColor: DudeTheme.success.withValues(alpha: 0.12),
          icon: Icons.check_circle_rounded,
        );
      case 0:
        return WithdrawalStatus(
          displayText: 'PROCESSING',
          color: DudeTheme.warning,
          bgColor: DudeTheme.warningDim,
          icon: Icons.hourglass_bottom_rounded,
        );
      case 2:
        return WithdrawalStatus(
          displayText: 'REJECTED',
          color: DudeTheme.danger,
          bgColor: DudeTheme.dangerDim,
          icon: Icons.cancel_rounded,
        );
      default:
        // Fallback using statusLabel
        final label = statusLabel.toLowerCase();
        if (label.contains('approve') || label.contains('success')) {
          return WithdrawalStatus(
            displayText: 'APPROVED',
            color: DudeTheme.success,
            bgColor: DudeTheme.success.withValues(alpha: 0.12),
            icon: Icons.check_circle_rounded,
          );
        } else if (label.contains('pending') || label.contains('process')) {
          return WithdrawalStatus(
            displayText: 'PROCESSING',
            color: DudeTheme.warning,
            bgColor: DudeTheme.warningDim,
            icon: Icons.hourglass_bottom_rounded,
          );
        } else if (label.contains('reject') || label.contains('fail')) {
          return WithdrawalStatus(
            displayText: 'REJECTED',
            color: DudeTheme.danger,
            bgColor: DudeTheme.dangerDim,
            icon: Icons.cancel_rounded,
          );
        }
        return WithdrawalStatus(
          displayText: statusLabel.toUpperCase(),
          color: DudeTheme.accent,
          bgColor: DudeTheme.accentDim,
          icon: Icons.info_outline_rounded,
        );
    }
  }
}

// ── Date range options ────────────────────────────────────────────────────
enum _DateFilter { thisMonth, last3Months, last6Months, thisYear, all }

extension _DateFilterLabel on _DateFilter {
  String get label {
    switch (this) {
      case _DateFilter.thisMonth:
        return 'This Month';
      case _DateFilter.last3Months:
        return 'Last 3 Months';
      case _DateFilter.last6Months:
        return 'Last 6 Months';
      case _DateFilter.thisYear:
        return 'This Year';
      case _DateFilter.all:
        return 'All Time';
    }
  }
}

// ── Status options for filtering ────────────────────────────────────────
enum _StatusFilter { all, approved, processing, rejected }

extension _StatusFilterLabel on _StatusFilter {
  String get label {
    switch (this) {
      case _StatusFilter.all:
        return 'All Status';
      case _StatusFilter.approved:
        return 'Approved';
      case _StatusFilter.processing:
        return 'Processing';
      case _StatusFilter.rejected:
        return 'Rejected';
    }
  }
}

class WithdrawHistory extends StatefulWidget {
  final bool backPage;
  const WithdrawHistory({super.key, required this.backPage});

  @override
  State<WithdrawHistory> createState() => _WithdrawHistoryState();
}

class _WithdrawHistoryState extends State<WithdrawHistory>
    with SingleTickerProviderStateMixin {
  // ── Search ────────────────────────────────────────────────────────────
  bool _searchVisible = false;
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';

  // ── Active filters ────────────────────────────────────────────────────
  _DateFilter _dateFilter = _DateFilter.thisMonth;
  _StatusFilter _statusFilter = _StatusFilter.all;

  // ── Animation ────────────────────────────────────────────────────────
  late final AnimationController _fadeCtrl;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();

    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await context.read<WalletViewModel>().fetchStaffWithdrawHistory();
      _fadeCtrl.forward();
    });

    _searchCtrl.addListener(() {
      setState(() => _searchQuery = _searchCtrl.text.toLowerCase().trim());
    });
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  // ─────────────────────────────────────────────────────────────────────
  // Helper to get normalized status for filtering
  // ─────────────────────────────────────────────────────────────────────

  String _getNormalizedStatus(StaffWithdrawHistoryItem item) {
    // Use statusCode first as it's more reliable
    switch (item.statusCode) {
      case 1:
        return 'approved';
      case 0:
        return 'processing';
      case 2:
        return 'rejected';
      default:
        // Fallback to statusLabel
        final label = item.statusLabel.toLowerCase();
        if (label.contains('approve')) return 'approved';
        if (label.contains('pending')) return 'processing';
        if (label.contains('reject')) return 'rejected';
        return 'processing';
    }
  }

  // ─────────────────────────────────────────────────────────────────────
  // FILTERING LOGIC
  // ─────────────────────────────────────────────────────────────────────

  List<StaffWithdrawHistoryItem> _applyFilters(
    List<StaffWithdrawHistoryItem> withdrawals,
  ) {
    final now = DateTime.now();

    return withdrawals.where((txn) {
      // ── Date filter ──────────────────────────────────────────────────
      bool dateOk = true;
      switch (_dateFilter) {
        case _DateFilter.thisMonth:
          dateOk =
              txn.createdAt.year == now.year &&
              txn.createdAt.month == now.month;
          break;
        case _DateFilter.last3Months:
          dateOk = txn.createdAt.isAfter(
            now.subtract(const Duration(days: 90)),
          );
          break;
        case _DateFilter.last6Months:
          dateOk = txn.createdAt.isAfter(
            now.subtract(const Duration(days: 180)),
          );
          break;
        case _DateFilter.thisYear:
          dateOk = txn.createdAt.year == now.year;
          break;
        case _DateFilter.all:
          dateOk = true;
          break;
      }
      if (!dateOk) return false;

      // ── Status filter ────────────────────────────────────────────────
      if (_statusFilter != _StatusFilter.all) {
        final normalizedStatus = _getNormalizedStatus(txn);
        if (_statusFilter == _StatusFilter.approved &&
            normalizedStatus != 'approved')
          return false;
        if (_statusFilter == _StatusFilter.processing &&
            normalizedStatus != 'processing')
          return false;
        if (_statusFilter == _StatusFilter.rejected &&
            normalizedStatus != 'rejected')
          return false;
      }

      // ── Search filter ────────────────────────────────────────────────
      if (_searchQuery.isNotEmpty) {
        final name = txn.name.toLowerCase();
        if (!name.contains(_searchQuery)) return false;
      }

      return true;
    }).toList();
  }

  // ─────────────────────────────────────────────────────────────────────
  // SUMMARY TOTALS
  // ─────────────────────────────────────────────────────────────────────

  Map<String, dynamic> _calcSummary(List<StaffWithdrawHistoryItem> filtered) {
    double total = 0;
    int approved = 0;
    int processing = 0;
    int rejected = 0;

    for (final t in filtered) {
      total += t.amount.toDouble();

      if (t.statusCode == 1)
        approved++;
      else if (t.statusCode == 0)
        processing++;
      else if (t.statusCode == 2)
        rejected++;
    }
    return {
      'total': total,
      'approved': approved,
      'processing': processing,
      'rejected': rejected,
    };
  }

  // ─────────────────────────────────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Consumer<WalletViewModel>(
      builder: (context, vm, _) {
        // Ensure we're working with StaffWithdrawHistoryItem list
        final List<StaffWithdrawHistoryItem> withdrawals =
            (vm.withdrawHistory as List?)?.cast<StaffWithdrawHistoryItem>() ??
            [];

        final filtered = _applyFilters(withdrawals);
        final summary = _calcSummary(filtered);

        return Scaffold(
          backgroundColor: DudeTheme.background,
          body: PremiumAmbientBackground(
            child: SafeArea(
              child: vm.isLoadingWithdraw
                  ? _buildLoader()
                  : vm.withdrawError != null
                  ? _buildError(vm)
                  : FadeTransition(
                      opacity: _fadeAnim,
                      child: Column(
                        children: [
                          _buildTopBar(),
                          if (_searchVisible) _buildSearchBar(),
                          _buildFilterRow(),
                          if (withdrawals.isNotEmpty)
                            _buildSummaryStrip(summary),
                          _buildListHeader(filtered.length),
                          Expanded(
                            child: filtered.isEmpty
                                ? _buildEmpty()
                                : RefreshIndicator(
                                    onRefresh: vm.refreshWithdrawHistory,
                                    color: DudeTheme.accent,
                                    child: _buildList(filtered),
                                  ),
                          ),
                        ],
                      ),
                    ),
            ),
          ),
        );
      },
    );
  }

  // ─────────────────────────────────────────────────────────────────────
  // LOADER / ERROR / EMPTY
  // ─────────────────────────────────────────────────────────────────────

  Widget _buildLoader() => const Center(
    child: CircularProgressIndicator(color: DudeTheme.accent, strokeWidth: 2),
  );

  Widget _buildError(WalletViewModel vm) => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: DudeTheme.dangerDim,
            shape: BoxShape.circle,
            border: Border.all(color: DudeTheme.danger.withOpacity(0.3)),
          ),
          child: Icon(Icons.wifi_off_rounded, color: DudeTheme.danger, size: 28),
        ),
        const SizedBox(height: 16),
        Text('Connection failed', style: TextStyle(
            color: DudeTheme.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          vm.withdrawError!,
          style: TextStyle(color: DudeTheme.textSubtle, fontSize: 13),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        GestureDetector(
          onTap: vm.refreshWithdrawHistory,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
            decoration: BoxDecoration(
              color: DudeTheme.accent,
              borderRadius: BorderRadius.circular(30),
            ),
            child: const Text(
              'Retry',
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
            ),
          ),
        ),
      ],
    ),
  );

  Widget _buildEmpty() => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: DudeTheme.accentDim,
            shape: BoxShape.circle,
            border: Border.all(color: DudeTheme.accent.withOpacity(0.3)),
          ),
          child: Icon(
            Icons.account_balance_wallet_outlined,
            color: DudeTheme.accent,
            size: 36,
          ),
        ),
        const SizedBox(height: 20),
        Text('No withdrawal requests', style: TextStyle(
            color: DudeTheme.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Text('Try adjusting your filters', style: TextStyle(color: DudeTheme.textSubtle, fontSize: 13),
        ),
        const SizedBox(height: 20),
        GestureDetector(
          onTap: _resetFilters,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              border: Border.all(color: DudeTheme.accent.withOpacity(0.5)),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Text('Clear Filters', style: TextStyle(
                color: DudeTheme.accent,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    ),
  );

  void _resetFilters() {
    HapticFeedback.lightImpact();
    setState(() {
      _dateFilter = _DateFilter.thisMonth;
      _statusFilter = _StatusFilter.all;
      _searchQuery = '';
      _searchCtrl.clear();
    });
  }

  // ─────────────────────────────────────────────────────────────────────
  // TOP BAR
  // ─────────────────────────────────────────────────────────────────────

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      child: Row(
        children: [
          // Back button
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              widget.backPage
                  ? bondNavigator.backPage(context)
                  : bondNavigator.newPageRemoveUntil(
                      context,
                      page: const StaffBottomBar(index: 0),
                    );
            },
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: DudeTheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: DudeTheme.border),
              ),
              child: Icon(
                Icons.arrow_back_ios_new_rounded,
                color: DudeTheme.textPrimary,
                size: 16,
              ),
            ),
          ),
          const SizedBox(width: 14),

          // Title
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Withdrawal History',
                  style: TextStyle(
                    color: DudeTheme.textPrimary,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                ),
                Text(
                  'Your withdrawal requests',
                  style: TextStyle(color: DudeTheme.textSubtle, fontSize: 12),
                ),
              ],
            ),
          ),

          // Search icon
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              setState(() {
                _searchVisible = !_searchVisible;
                if (!_searchVisible) {
                  _searchCtrl.clear();
                  _searchQuery = '';
                }
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _searchVisible ? DudeTheme.accentDim : DudeTheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _searchVisible
                      ? DudeTheme.accent.withOpacity(0.4)
                      : DudeTheme.border,
                ),
              ),
              child: Icon(
                _searchVisible ? Icons.close_rounded : Icons.search_rounded,
                color: _searchVisible ? DudeTheme.accent : DudeTheme.textMid,
                size: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────
  // SEARCH BAR
  // ─────────────────────────────────────────────────────────────────────

  Widget _buildSearchBar() {
    return AnimatedSize(
      duration: const Duration(milliseconds: 250),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        child: Container(
          height: 46,
          decoration: BoxDecoration(
            color: DudeTheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _searchQuery.isNotEmpty
                  ? DudeTheme.accent.withOpacity(0.4)
                  : DudeTheme.border,
            ),
          ),
          child: TextField(
            controller: _searchCtrl,
            autofocus: true,
            style: TextStyle(color: DudeTheme.textPrimary, fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Search by name...',
              hintStyle: TextStyle(color: DudeTheme.textSubtle, fontSize: 13),
              prefixIcon: Icon(
                Icons.search_rounded,
                color: DudeTheme.textSubtle,
                size: 18,
              ),
              suffixIcon: _searchQuery.isNotEmpty
                  ? GestureDetector(
                      onTap: () {
                        _searchCtrl.clear();
                        setState(() => _searchQuery = '');
                      },
                      child: Icon(
                        Icons.clear_rounded,
                        color: DudeTheme.textSubtle,
                        size: 16,
                      ),
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 13),
            ),
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────
  // FILTER ROW
  // ─────────────────────────────────────────────────────────────────────

  Widget _buildFilterRow() {
    final hasActiveFilters =
        _dateFilter != _DateFilter.thisMonth ||
        _statusFilter != _StatusFilter.all;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(
        children: [
          // Date filter
          Expanded(
            flex: 4,
            child: _filterChip(
              icon: Icons.calendar_today_rounded,
              label: _dateFilter.label,
              isActive: _dateFilter != _DateFilter.thisMonth,
              onTap: _showDateFilterSheet,
            ),
          ),
          const SizedBox(width: 8),

          // Status filter
          Expanded(
            flex: 3,
            child: _filterChip(
              icon: Icons.radio_button_checked_rounded,
              label: _statusFilter.label,
              isActive: _statusFilter != _StatusFilter.all,
              onTap: _showStatusFilterSheet,
            ),
          ),

          // Clear all (only when filters active)
          if (hasActiveFilters) ...[
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _resetFilters,
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: DudeTheme.dangerDim,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: DudeTheme.danger.withOpacity(0.3)),
                ),
                child: Icon(
                  Icons.filter_alt_off_rounded,
                  color: DudeTheme.danger,
                  size: 16,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _filterChip({
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: isActive ? DudeTheme.accentDim : DudeTheme.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isActive ? DudeTheme.accent.withOpacity(0.5) : DudeTheme.border,
            width: isActive ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: isActive ? DudeTheme.accent : DudeTheme.textSubtle, size: 13),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  color: isActive ? DudeTheme.accent : DudeTheme.textMid,
                  fontSize: 11,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 3),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              color: isActive ? DudeTheme.accent : DudeTheme.textSubtle,
              size: 13,
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────
  // FILTER BOTTOM SHEETS
  // ─────────────────────────────────────────────────────────────────────

  void _showDateFilterSheet() {
    _showPickerSheet<_DateFilter>(
      title: 'Date Range',
      options: _DateFilter.values,
      selected: _dateFilter,
      labelOf: (v) => v.label,
      onSelect: (v) => setState(() => _dateFilter = v),
    );
  }

  void _showStatusFilterSheet() {
    _showPickerSheet<_StatusFilter>(
      title: 'Withdrawal Status',
      options: _StatusFilter.values,
      selected: _statusFilter,
      labelOf: (v) => v.label,
      onSelect: (v) => setState(() => _statusFilter = v),
    );
  }

  void _showPickerSheet<T>({
    required String title,
    required List<T> options,
    required T selected,
    required String Function(T) labelOf,
    required void Function(T) onSelect,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: BoxDecoration(
          color: DudeTheme.surface.withValues(alpha: 0.96),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border.all(color: DudeTheme.border.withValues(alpha: 0.6)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: DudeTheme.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Text(
              title,
              style: TextStyle(
                color: DudeTheme.textPrimary,
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),
            ...options.map((opt) {
              final isSelected = opt == selected;
              return GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  onSelect(opt);
                  Navigator.pop(context);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected ? DudeTheme.accentDim : DudeTheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? DudeTheme.accent.withOpacity(0.5)
                          : DudeTheme.border,
                      width: isSelected ? 1.5 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          labelOf(opt),
                          style: TextStyle(
                            color: isSelected ? DudeTheme.accent : DudeTheme.textMid,
                            fontSize: 14,
                            fontWeight: isSelected
                                ? FontWeight.w700
                                : FontWeight.w500,
                          ),
                        ),
                      ),
                      if (isSelected)
                        Container(
                          width: 20,
                          height: 20,
                          decoration: const BoxDecoration(
                            color: DudeTheme.accent,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.check_rounded,
                            color: Colors.black,
                            size: 13,
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
    );
  }

  // ─────────────────────────────────────────────────────────────────────
  // SUMMARY STRIP
  // ─────────────────────────────────────────────────────────────────────

  Widget _buildSummaryStrip(Map<String, dynamic> summary) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  DudeTheme.surface.withValues(alpha: 0.92),
                  DudeTheme.surfaceRaised.withValues(alpha: 0.78),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: DudeTheme.border),
            ),
            child: Row(
              children: [
                _summaryTile(
                  label: 'Total',
                  value: '₹${(summary['total'] as double).toStringAsFixed(0)}',
                  color: DudeTheme.accent,
                ),
                _vDivider(),
                _summaryTile(
                  label: 'Approved',
                  value: '${summary['approved']}',
                  color: DudeTheme.success,
                  icon: Icons.check_circle_outline_rounded,
                ),
                _vDivider(),
                _summaryTile(
                  label: 'Processing',
                  value: '${summary['processing']}',
                  color: DudeTheme.warning,
                  icon: Icons.hourglass_bottom_rounded,
                ),
                _vDivider(),
                _summaryTile(
                  label: 'Rejected',
                  value: '${summary['rejected']}',
                  color: DudeTheme.danger,
                  icon: Icons.cancel_outlined,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _vDivider() => Container(
    width: 1,
    height: 36,
    margin: const EdgeInsets.symmetric(horizontal: 12),
    color: DudeTheme.border,
  );

  Widget _summaryTile({
    required String label,
    required String value,
    required Color color,
    IconData? icon,
  }) {
    return Expanded(
      child: Column(
        children: [
          if (icon != null) ...[
            Icon(icon, color: color, size: 14),
            const SizedBox(height: 2),
          ],
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(color: DudeTheme.textSubtle, fontSize: 10)),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────
  // LIST HEADER
  // ─────────────────────────────────────────────────────────────────────

  Widget _buildListHeader(int count) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: [
          Text(
            '$count withdrawal request${count == 1 ? '' : 's'}',
            style: TextStyle(
              color: DudeTheme.textSubtle,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          Text(
            HistoryTimeFormatter.shortMonthYear(DateTime.now()),
            style: TextStyle(color: DudeTheme.textSubtle, fontSize: 12),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────
  // WITHDRAWALS LIST
  // ─────────────────────────────────────────────────────────────────────

  Widget _buildList(List<StaffWithdrawHistoryItem> filtered) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      physics: PremiumAnimations.scrollPhysics,
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final txn = filtered[index];
        return PremiumStaggerItem(
          index: index.clamp(0, 12),
          child: _withdrawalCard(txn, index),
        );
      },
    );
  }

  Widget _withdrawalCard(StaffWithdrawHistoryItem txn, int index) {
    // Use statusCode and statusLabel from the model
    final status = WithdrawalStatus.fromStatusCode(
      txn.statusCode,
      txn.statusLabel,
    );

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        bondNavigator.newPage(
          context,
          page: WithdrawDetailScreen(transaction: txn),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: status.color.withValues(alpha: 0.32)),
          boxShadow: [
            BoxShadow(
              color: status.color.withValues(alpha: 0.1),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    DudeTheme.surface.withValues(alpha: 0.9),
                    status.color.withValues(alpha: 0.05),
                    DudeTheme.surfaceRaised.withValues(alpha: 0.78),
                  ],
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        gradient: LinearGradient(
                          colors: [
                            status.color.withValues(alpha: 0.2),
                            DudeTheme.accentDim.withValues(alpha: 0.35),
                          ],
                        ),
                        border: Border.all(
                          color: status.color.withValues(alpha: 0.35),
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(13),
                        child: txn.image.isNotEmpty
                            ? Image.network(
                                txn.image,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) =>
                                    _defaultAvatar(status.color),
                              )
                            : _defaultAvatar(status.color),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'Name: ',
                                style: TextStyle(
                                  color: DudeTheme.textSubtle.withValues(
                                    alpha: 0.9,
                                  ),
                                  fontSize: 11,
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  txn.name,
                                  style: TextStyle(
                                    color: DudeTheme.textPrimary,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.2,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 5),
                          Row(
                            children: [
                              Icon(
                                Icons.access_time_rounded,
                                color: DudeTheme.textSubtle.withValues(
                                  alpha: 0.85,
                                ),
                                size: 11,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                HistoryTimeFormatter.list(txn.createdAt),
                                style: TextStyle(
                                  color: DudeTheme.textSubtle.withValues(
                                    alpha: 0.85,
                                  ),
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: status.bgColor,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: status.color.withValues(alpha: 0.35),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  status.icon,
                                  color: status.color,
                                  size: 10,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  status.displayText,
                                  style: TextStyle(
                                    color: status.color,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        ShaderMask(
                          blendMode: BlendMode.srcIn,
                          shaderCallback: (bounds) {
                            return txn.statusCode == 1
                                ? DudeTheme.premiumAccentGradient
                                      .createShader(bounds)
                                : LinearGradient(
                                    colors: [
                                      DudeTheme.textPrimary,
                                      DudeTheme.textPrimary,
                                    ],
                                  ).createShader(bounds);
                          },
                          child: Text(
                            '₹${txn.amountText}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.3,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            gradient: DudeTheme.premiumAccentGradient,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: DudeTheme.accentGlowShadow(
                              blur: 10,
                              spread: -4,
                            ),
                          ),
                          child: Icon(
                            Icons.arrow_forward_ios_rounded,
                            color: DudeTheme.textOnAccent,
                            size: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _defaultAvatar(Color accentColor) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            DudeTheme.accentDim.withValues(alpha: 0.8),
            DudeTheme.surfaceRaised.withValues(alpha: 0.9),
          ],
        ),
      ),
      child: Icon(Icons.person_outline, color: accentColor, size: 22),
    );
  }
}
