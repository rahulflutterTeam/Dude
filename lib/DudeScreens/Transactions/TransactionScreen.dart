import 'package:dude/Dude_Utils/DateTimeFormatter/history_time_formatter.dart';
import 'package:dude/DudeScreens/BottomNavBar/BottomNavBar.dart';
import 'package:dude/DudeScreens/Transactions/TransactionDetailScreen.dart';
import 'package:dude/DudeScreens/Transactions/ViewModel/TransactionHistoryVM.dart';
import 'package:dude/Reusable_Widgets/BondingNavigator.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:dude/Dude_Utils/App_Theme/DudeTheme.dart';
import 'package:dude/Reusable_Widgets/Premium_UI/premium_ambient_background.dart';
import 'package:dude/Reusable_Widgets/Premium_UI/premium_animations.dart';
import 'package:dude/Reusable_Widgets/Premium_UI/premium_glass_card.dart';
import 'package:dude/Reusable_Widgets/Premium_UI/premium_stagger.dart';
import 'package:provider/provider.dart';

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

  double _filteredTotal(List filtered) {
    var total = 0.0;
    for (final t in filtered) {
      total += (t.totalAmount as num? ?? 0).toDouble();
    }
    return total;
  }

  List<MapEntry<String, List>> _groupByDate(List filtered) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    final groups = <String, List>{};
    for (final txn in filtered) {
      final created = txn.createdAt as DateTime;
      final day = DateTime(created.year, created.month, created.day);
      String label;
      if (day == today) {
        label = 'Today';
      } else if (day == yesterday) {
        label = 'Yesterday';
      } else if (now.difference(day).inDays < 7) {
        label = 'This week';
      } else {
        label = HistoryTimeFormatter.shortMonthYear(created);
      }
      groups.putIfAbsent(label, () => []).add(txn);
    }
    return groups.entries.toList();
  }

  _TxnStatusStyle _statusStyle(String statusText) {
    final s = statusText.toLowerCase();
    if (s.contains('completed')) {
      return _TxnStatusStyle(
        color: DudeTheme.success,
        icon: Icons.check_circle_rounded,
        label: 'Success',
      );
    }
    if (s.contains('pending')) {
      return _TxnStatusStyle(
        color: DudeTheme.warning,
        icon: Icons.schedule_rounded,
        label: 'Pending',
      );
    }
    return _TxnStatusStyle(
      color: DudeTheme.danger,
      icon: Icons.cancel_rounded,
      label: 'Failed',
    );
  }

  // ─────────────────────────────────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Consumer<DepositHistoryViewModel>(
      builder: (context, vm, _) {
        final filtered = _applyFilters(vm.depositHistory);
        final totalSpent = _filteredTotal(filtered);
        final grouped = _groupByDate(filtered);

        return Scaffold(
          backgroundColor: DudeTheme.background,
          body: PremiumAmbientBackground(
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
                          Expanded(
                            child: filtered.isEmpty
                                ? Column(
                                    children: [
                                      PremiumStaggerItem(
                                        index: 0,
                                        child: _buildFilterSection(),
                                      ),
                                      Expanded(child: _buildEmpty()),
                                    ],
                                  )
                                : RefreshIndicator(
                                    onRefresh: vm.refresh,
                                    color: DudeTheme.accent,
                                    backgroundColor: DudeTheme.surface,
                                    child: CustomScrollView(
                                      physics:
                                          const AlwaysScrollableScrollPhysics(
                                        parent: BouncingScrollPhysics(),
                                      ),
                                      slivers: [
                                        SliverToBoxAdapter(
                                          child: PremiumStaggerItem(
                                            index: 0,
                                            child: _buildSpentHero(
                                              totalSpent,
                                              filtered.length,
                                            ),
                                          ),
                                        ),
                                        SliverToBoxAdapter(
                                          child: PremiumStaggerItem(
                                            index: 1,
                                            child: _buildFilterSection(),
                                          ),
                                        ),
                                        const SliverToBoxAdapter(
                                          child: SizedBox(height: 8),
                                        ),
                                        ..._buildGroupedSlivers(grouped),
                                        const SliverToBoxAdapter(
                                          child: SizedBox(height: 24),
                                        ),
                                      ],
                                    ),
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

  List<Widget> _buildGroupedSlivers(List<MapEntry<String, List>> grouped) {
    final slivers = <Widget>[];
    var stagger = 2;

    for (final group in grouped) {
      slivers.add(
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Text(
              group.key,
              style: const TextStyle(
                color: DudeTheme.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
      );

      final txns = group.value;
      for (var i = 0; i < txns.length; i++) {
        slivers.add(
          SliverToBoxAdapter(
            child: PremiumStaggerItem(
              index: stagger++,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                child: _txnCard(txns[i]),
              ),
            ),
          ),
        );
      }
    }

    return slivers;
  }

  // ─────────────────────────────────────────────────────────────────────
  // LOADER / ERROR / EMPTY
  // ─────────────────────────────────────────────────────────────────────

  Widget _buildLoader() => const Center(
    child: CircularProgressIndicator(color: DudeTheme.accent, strokeWidth: 2),
  );

  Widget _buildError(DepositHistoryViewModel vm) => Center(
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
          child: const Icon(Icons.wifi_off_rounded, color: DudeTheme.danger, size: 28),
        ),
        const SizedBox(height: 16),
        const Text(
          'Connection failed',
          style: TextStyle(
            color: DudeTheme.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          vm.errorMessage!,
          style: const TextStyle(color: DudeTheme.textSubtle, fontSize: 13),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        GestureDetector(
          onTap: vm.refresh,
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
          child: const Icon(
            Icons.receipt_long_rounded,
            color: DudeTheme.accent,
            size: 36,
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'No transactions found',
          style: TextStyle(
            color: DudeTheme.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Try adjusting your filters',
          style: TextStyle(color: DudeTheme.textSubtle, fontSize: 13),
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
            child: const Text(
              'Clear Filters',
              style: TextStyle(
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
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
      child: Row(
        children: [
          IconButton(
            onPressed: () {
              HapticFeedback.lightImpact();
              widget.backPage
                  ? bondNavigator.backPage(context)
                  : bondNavigator.newPageRemoveUntil(
                      context,
                      page: MainBottomBar(index: 0),
                    );
            },
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: DudeTheme.textPrimary,
              size: 18,
            ),
          ),
          const Expanded(
            child: Text(
              'Transactions',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: DudeTheme.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          IconButton(
            onPressed: () {
              HapticFeedback.lightImpact();
              setState(() {
                _searchVisible = !_searchVisible;
                if (!_searchVisible) {
                  _searchCtrl.clear();
                  _searchQuery = '';
                }
              });
            },
            icon: Icon(
              _searchVisible ? Icons.close_rounded : Icons.search_rounded,
              color: _searchVisible ? DudeTheme.accent : DudeTheme.textMid,
              size: 22,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpentHero(double total, int count) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
        decoration: BoxDecoration(
          gradient: DudeTheme.premiumAccentGradient,
          borderRadius: BorderRadius.circular(22),
          boxShadow: DudeTheme.accentGlowShadow(blur: 22, spread: -4),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _dateFilter.label,
                    style: TextStyle(
                      color: DudeTheme.textOnAccent.withValues(alpha: 0.85),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '₹${total.toStringAsFixed(total == total.roundToDouble() ? 0 : 2)}',
                    style: const TextStyle(
                      color: DudeTheme.textOnAccent,
                      fontSize: 34,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                      height: 1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$count payment${count == 1 ? '' : 's'}',
                    style: TextStyle(
                      color: DudeTheme.textOnAccent.withValues(alpha: 0.75),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.35),
                ),
              ),
              child: const Icon(
                Icons.receipt_long_rounded,
                color: DudeTheme.textOnAccent,
                size: 26,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterSection() {
    final hasActiveFilters =
        _dateFilter != _DateFilter.thisMonth ||
        _statusFilter != _StatusFilter.all;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Filter',
                style: TextStyle(
                  color: DudeTheme.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              if (hasActiveFilters)
                GestureDetector(
                  onTap: _resetFilters,
                  child: Text(
                    'Clear all',
                    style: TextStyle(
                      color: DudeTheme.accent,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 36,
            child: ListView(
              scrollDirection: Axis.horizontal,
              physics: PremiumAnimations.scrollPhysics,
              children: _StatusFilter.values.map((status) {
                final isSelected = _statusFilter == status;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _statusFilter = status);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        gradient: isSelected
                            ? DudeTheme.premiumAccentGradient
                            : null,
                        color: isSelected ? null : DudeTheme.surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected
                              ? Colors.transparent
                              : DudeTheme.border,
                        ),
                        boxShadow: isSelected
                            ? DudeTheme.accentGlowShadow(blur: 12, spread: -6)
                            : null,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        status == _StatusFilter.all ? 'All' : status.label,
                        style: TextStyle(
                          color: isSelected
                              ? DudeTheme.textOnAccent
                              : DudeTheme.textMid,
                          fontSize: 12,
                          fontWeight:
                              isSelected ? FontWeight.w700 : FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              _showDateFilterSheet();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: _dateFilter != _DateFilter.thisMonth
                    ? DudeTheme.accentDim
                    : DudeTheme.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: _dateFilter != _DateFilter.thisMonth
                      ? DudeTheme.accent.withValues(alpha: 0.45)
                      : DudeTheme.border,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.calendar_month_rounded,
                    size: 16,
                    color: _dateFilter != _DateFilter.thisMonth
                        ? DudeTheme.accent
                        : DudeTheme.textSubtle,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _dateFilter.label,
                    style: TextStyle(
                      color: _dateFilter != _DateFilter.thisMonth
                          ? DudeTheme.accent
                          : DudeTheme.textMid,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: 18,
                    color: _dateFilter != _DateFilter.thisMonth
                        ? DudeTheme.accent
                        : DudeTheme.textSubtle,
                  ),
                ],
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
            style: const TextStyle(color: DudeTheme.textPrimary, fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Search by Transaction ID...',
              hintStyle: const TextStyle(color: DudeTheme.textSubtle, fontSize: 13),
              prefixIcon: const Icon(
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
                      child: const Icon(
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
              style: const TextStyle(
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
  // TRANSACTION CARD
  // ─────────────────────────────────────────────────────────────────────

  Widget _txnCard(dynamic txn) {
    final statusText = (txn.statusText as String? ?? 'Unknown');
    final style = _statusStyle(statusText);
    final shortId = (txn.razorpayOrderId as String? ?? '').length > 12
        ? '${(txn.razorpayOrderId as String).substring(0, 12)}…'
        : (txn.razorpayOrderId as String? ?? '—');

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        bondNavigator.newPage(
          context,
          page: TransactionDetailsScreen(transaction: txn),
        );
      },
      child: PremiumGlassCard(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: style.color.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: style.color.withValues(alpha: 0.3)),
              ),
              child: Icon(style.icon, color: style.color, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        '₹${txn.totalAmount}',
                        style: const TextStyle(
                          color: DudeTheme.textPrimary,
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: style.color.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          style.label,
                          style: TextStyle(
                            color: style.color,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    shortId,
                    style: const TextStyle(
                      color: DudeTheme.textSubtle,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    HistoryTimeFormatter.list(txn.createdAt as DateTime),
                    style: TextStyle(
                      color: DudeTheme.textSubtle.withValues(alpha: 0.85),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: DudeTheme.textSubtle.withValues(alpha: 0.6),
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}

class _TxnStatusStyle {
  final Color color;
  final IconData icon;
  final String label;

  const _TxnStatusStyle({
    required this.color,
    required this.icon,
    required this.label,
  });
}
