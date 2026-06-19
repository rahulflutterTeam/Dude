import 'dart:ui';
import 'package:dude/Dude_Utils/DateTimeFormatter/history_time_formatter.dart';
import 'package:dude/DudeScreens/BottomNavBar/BottomNavBar.dart';
import 'package:dude/DudeScreens/Transactions/TransactionDetailScreen.dart';
import 'package:dude/DudeScreens/Transactions/ViewModel/TransactionHistoryVM.dart';
import 'package:dude/Reusable_Widgets/AppText_Theme/AppText_Theme.dart';
import 'package:dude/Reusable_Widgets/BondingNavigator.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';

// ── Design tokens ─────────────────────────────────────────────────────────
const _kBg = Color(0xFF080612);
const _kCard = Color(0xFF100E1E);
const _kCardBorder = Color(0xFF1E1A30);
const _kAccent = Color(0xFFD4F53C);
const _kAccentDim = Color(0xFF2A3010);
const _kPurple = Color(0xFF7B5CF5);
const _kPurpleDim = Color(0xFF1C1535);
const _kText = Color(0xFFFFFFFF);
const _kTextSub = Color(0xFF6B6585);
const _kTextMid = Color(0xFFADA8C0);
const _kSuccess = Color(0xFF22C55E);
const _kSuccessDim = Color(0xFF052010);
const _kWarning = Color(0xFFF59E0B);
const _kWarningDim = Color(0xFF211500);
const _kDanger = Color(0xFFEF4444);
const _kDangerDim = Color(0xFF1E0404);
// ──────────────────────────────────────────────────────────────────────────

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

// ── Status options ────────────────────────────────────────────────────────
enum _StatusFilter { all, success, pending, failed }

extension _StatusFilterLabel on _StatusFilter {
  String get label {
    switch (this) {
      case _StatusFilter.all:
        return 'All Status';
      case _StatusFilter.success:
        return 'Success';
      case _StatusFilter.pending:
        return 'Pending';
      case _StatusFilter.failed:
        return 'Failed';
    }
  }
}

class TransactionsScreen extends StatefulWidget {
  final bool backPage;
  const TransactionsScreen({super.key, required this.backPage});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen>
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
      await context.read<DepositHistoryViewModel>().fetchDepositHistory();
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
  // FILTERING LOGIC
  // ─────────────────────────────────────────────────────────────────────

  List _applyFilters(List txns) {
    final now = DateTime.now();

    return txns.where((txn) {
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
      // Uses the existing statusText from your model
      if (_statusFilter != _StatusFilter.all) {
        final s = (txn.statusText as String? ?? '').toLowerCase();
        if (_statusFilter == _StatusFilter.success && !s.contains('completed'))
          return false; // ✅ Changed from 'success'
        if (_statusFilter == _StatusFilter.pending && !s.contains('pending'))
          return false;
        if (_statusFilter == _StatusFilter.failed && !s.contains('fail'))
          return false;
      }

      // ── Search filter ────────────────────────────────────────────────
      if (_searchQuery.isNotEmpty) {
        final id = (txn.razorpayOrderId as String? ?? '').toLowerCase();
        if (!id.contains(_searchQuery)) return false;
      }

      return true;
    }).toList();
  }

  // ─────────────────────────────────────────────────────────────────────
  // SUMMARY TOTALS
  // ─────────────────────────────────────────────────────────────────────

  Map<String, dynamic> _calcSummary(List filtered) {
    double total = 0;
    int success = 0;
    int pending = 0;
    int failed = 0;

    for (final t in filtered) {
      total += (t.totalAmount as num? ?? 0).toDouble();
      final s = (t.statusText as String? ?? '').toLowerCase();
      if (s.contains('completed'))
        success++; // ✅ Changed from 'success'
      else if (s.contains('pending'))
        pending++;
      else
        failed++;
    }
    return {
      'total': total,
      'success': success,
      'pending': pending,
      'failed': failed,
    };
  }

  // ─────────────────────────────────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Consumer<DepositHistoryViewModel>(
      builder: (context, vm, _) {
        final filtered = _applyFilters(vm.depositHistory);
        final summary = _calcSummary(filtered);

        return Scaffold(
          backgroundColor: _kBg,
          body: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF0E0A1E),
                  Color(0xFF080612),
                  Color(0xFF080612),
                  Color(0xFF0D0A1C),
                ],
              ),
            ),
            child: SafeArea(
              child: vm.isLoading
                  ? _buildLoader()
                  : vm.errorMessage != null
                  ? _buildError(vm)
                  : FadeTransition(
                      opacity: _fadeAnim,
                      child: Column(
                        children: [
                          _buildTopBar(),
                          if (_searchVisible) _buildSearchBar(),
                          _buildFilterRow(),
                          if (vm.depositHistory.isNotEmpty)
                            _buildSummaryStrip(summary),
                          _buildListHeader(filtered.length),
                          Expanded(
                            child: filtered.isEmpty
                                ? _buildEmpty()
                                : _buildList(filtered),
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
    child: CircularProgressIndicator(color: _kAccent, strokeWidth: 2),
  );

  Widget _buildError(DepositHistoryViewModel vm) => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: _kDangerDim,
            shape: BoxShape.circle,
            border: Border.all(color: _kDanger.withOpacity(0.3)),
          ),
          child: const Icon(Icons.wifi_off_rounded, color: _kDanger, size: 28),
        ),
        const SizedBox(height: 16),
        const Text(
          'Connection failed',
          style: TextStyle(
            color: _kText,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          vm.errorMessage!,
          style: const TextStyle(color: _kTextSub, fontSize: 13),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        GestureDetector(
          onTap: vm.refresh,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
            decoration: BoxDecoration(
              color: _kAccent,
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
            color: _kPurpleDim,
            shape: BoxShape.circle,
            border: Border.all(color: _kPurple.withOpacity(0.3)),
          ),
          child: const Icon(
            Icons.receipt_long_rounded,
            color: _kPurple,
            size: 36,
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'No transactions found',
          style: TextStyle(
            color: _kText,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Try adjusting your filters',
          style: TextStyle(color: _kTextSub, fontSize: 13),
        ),
        const SizedBox(height: 20),
        GestureDetector(
          onTap: _resetFilters,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              border: Border.all(color: _kAccent.withOpacity(0.5)),
              borderRadius: BorderRadius.circular(30),
            ),
            child: const Text(
              'Clear Filters',
              style: TextStyle(
                color: _kAccent,
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
                      page: MainBottomBar(index: 0),
                    );
            },
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _kCard,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _kCardBorder),
              ),
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: _kText,
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
                  'Transactions',
                  style: TextStyle(
                    color: _kText,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                ),
                Text(
                  'Your payment history',
                  style: TextStyle(color: _kTextSub, fontSize: 12),
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
                color: _searchVisible ? _kAccentDim : _kCard,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _searchVisible
                      ? _kAccent.withOpacity(0.4)
                      : _kCardBorder,
                ),
              ),
              child: Icon(
                _searchVisible ? Icons.close_rounded : Icons.search_rounded,
                color: _searchVisible ? _kAccent : _kTextMid,
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
            color: _kCard,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _searchQuery.isNotEmpty
                  ? _kAccent.withOpacity(0.4)
                  : _kCardBorder,
            ),
          ),
          child: TextField(
            controller: _searchCtrl,
            autofocus: true,
            style: const TextStyle(color: _kText, fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Search by Transaction ID...',
              hintStyle: const TextStyle(color: _kTextSub, fontSize: 13),
              prefixIcon: const Icon(
                Icons.search_rounded,
                color: _kTextSub,
                size: 18,
              ),
              suffixIcon: _searchQuery.isNotEmpty
                  ? GestureDetector(
                      onTap: () {
                        _searchCtrl.clear();
                        setState(() => _searchQuery = '');
                      },
                      child: const Icon(
                        Icons.clear_rounded,
                        color: _kTextSub,
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
                  color: _kDangerDim,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: _kDanger.withOpacity(0.3)),
                ),
                child: const Icon(
                  Icons.filter_alt_off_rounded,
                  color: _kDanger,
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
          color: isActive ? _kAccentDim : _kCard,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isActive ? _kAccent.withOpacity(0.5) : _kCardBorder,
            width: isActive ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: isActive ? _kAccent : _kTextSub, size: 13),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  color: isActive ? _kAccent : _kTextMid,
                  fontSize: 11,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 3),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              color: isActive ? _kAccent : _kTextSub,
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
      title: 'Transaction Status',
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
          color: const Color(0xFF100E1E),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border.all(color: _kCardBorder),
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
                color: _kCardBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Text(
              title,
              style: const TextStyle(
                color: _kText,
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
                    color: isSelected ? _kAccentDim : _kCard,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? _kAccent.withOpacity(0.5)
                          : _kCardBorder,
                      width: isSelected ? 1.5 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          labelOf(opt),
                          style: TextStyle(
                            color: isSelected ? _kAccent : _kTextMid,
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
                            color: _kAccent,
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
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF130F24), Color(0xFF1A1232)],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _kCardBorder),
        ),
        child: Row(
          children: [
            _summaryTile(
              label: 'Total',
              value: '₹${(summary['total'] as double).toStringAsFixed(0)}',
              color: _kAccent,
            ),
            _vDivider(),
            _summaryTile(
              label: 'Success',
              value: '${summary['success']}',
              color: _kSuccess,
              icon: Icons.check_circle_outline_rounded,
            ),
            _vDivider(),
            _summaryTile(
              label: 'Pending',
              value: '${summary['pending']}',
              color: _kWarning,
              icon: Icons.hourglass_bottom_rounded,
            ),
            _vDivider(),
            _summaryTile(
              label: 'Failed',
              value: '${summary['failed']}',
              color: _kDanger,
              icon: Icons.cancel_outlined,
            ),
          ],
        ),
      ),
    );
  }

  Widget _vDivider() => Container(
    width: 1,
    height: 36,
    margin: const EdgeInsets.symmetric(horizontal: 12),
    color: _kCardBorder,
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
          Text(label, style: const TextStyle(color: _kTextSub, fontSize: 10)),
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
            '$count transaction${count == 1 ? '' : 's'}',
            style: const TextStyle(
              color: _kTextSub,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          Text(
            HistoryTimeFormatter.shortMonthYear(DateTime.now()),
            style: const TextStyle(color: _kTextSub, fontSize: 12),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────
  // TRANSACTIONS LIST
  // ─────────────────────────────────────────────────────────────────────

  Widget _buildList(List filtered) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final txn = filtered[index];
        return _txnCard(txn, index);
      },
    );
  }

  Widget _txnCard(dynamic txn, int index) {
    final statusText = (txn.statusText as String? ?? 'Unknown');
    final statusLower = statusText.toLowerCase();
    final Color statusColor;
    final Color statusBg;
    final IconData statusIcon;

    // ✅ Fix: Check for 'completed' instead of 'success'
    if (statusLower.contains('completed')) {
      statusColor = _kSuccess; // Green
      statusBg = _kSuccessDim;
      statusIcon = Icons.check_circle_rounded;
    } else if (statusLower.contains('pending')) {
      statusColor = _kWarning; // Orange/Yellow
      statusBg = _kWarningDim;
      statusIcon = Icons.hourglass_bottom_rounded;
    } else {
      statusColor = _kDanger; // Red - for failed
      statusBg = _kDangerDim;
      statusIcon = Icons.cancel_rounded;
    }

    final shortId = (txn.razorpayOrderId as String? ?? '').length > 14
        ? '${(txn.razorpayOrderId as String).substring(0, 14)}...'
        : (txn.razorpayOrderId as String? ?? '');

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        bondNavigator.newPage(
          context,
          page: TransactionDetailsScreen(transaction: txn),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: _kCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _kCardBorder),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            children: [
              // Left accent bar
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                child: Container(
                  width: 3,
                  decoration: BoxDecoration(
                    color: statusColor,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      bottomLeft: Radius.circular(16),
                    ),
                  ),
                ),
              ),

              Padding(
                padding: const EdgeInsets.fromLTRB(18, 14, 14, 14),
                child: Row(
                  children: [
                    // Avatar
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: statusColor.withOpacity(0.25),
                          width: 1.5,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(13),
                        child:
                            (txn.image != null &&
                                (txn.image as String).isNotEmpty)
                            ? Image.network(
                                txn.image as String,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) =>
                                    _defaultAvatar(statusColor),
                              )
                            : _defaultAvatar(statusColor),
                      ),
                    ),
                    const SizedBox(width: 14),

                    // Middle info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Text(
                                'ID: ',
                                style: TextStyle(
                                  color: _kTextSub,
                                  fontSize: 11,
                                ),
                              ),
                              Text(
                                shortId,
                                style: const TextStyle(
                                  color: _kText,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.2,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 5),
                          Row(
                            children: [
                              const Icon(
                                Icons.access_time_rounded,
                                color: _kTextSub,
                                size: 11,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                HistoryTimeFormatter.list(
                                  txn.createdAt as DateTime,
                                ),
                                style: const TextStyle(
                                  color: _kTextSub,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          // Status badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: statusBg,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: statusColor.withOpacity(0.3),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(statusIcon, color: statusColor, size: 10),
                                const SizedBox(width: 4),
                                Text(
                                  statusText,
                                  style: TextStyle(
                                    color: statusColor,
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

                    // Amount + arrow
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '₹${txn.totalAmount}',
                          style: const TextStyle(
                            color: _kText,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: _kCardBorder,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.arrow_forward_ios_rounded,
                            color: _kTextMid,
                            size: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _defaultAvatar(Color accentColor) {
    return Container(
      color: _kPurpleDim,
      child: Icon(Icons.receipt_outlined, color: accentColor, size: 22),
    );
  }
}
