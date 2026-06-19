import 'package:intl/intl.dart';
import 'package:dude/Dude_Utils/DateTimeFormatter/history_time_formatter.dart';
import 'package:dude/Reusable_Widgets/BondingNavigator.dart';
import 'package:dude/StaffScreenScreens/RecentCallScreen/Model/recentCallModel.dart';
import 'package:dude/StaffScreenScreens/StaffBottomNavBar/StaffBottomNavBar.dart';
import 'package:dude/StaffScreenScreens/StaffRegistrationScreen/ViewModel/StaffRegisterVM.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class RecentCallsPage extends StatefulWidget {
  final bool backPage;
  const RecentCallsPage({super.key, required this.backPage});

  @override
  State<RecentCallsPage> createState() => _RecentCallsPageState();
}

class _RecentCallsPageState extends State<RecentCallsPage> {
  String selectedFilter = "all calls";
  bool isSearchVisible = true;

  DateTime? selectedDay;
  DateTime? selectedMonth;
  DateTime? fromDate;
  DateTime? toDate;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<StaffViewModel>().fetchCallHistory();
    });
  }

  List<CallHistoryItem> get filteredCalls {
    final vm = context.watch<StaffViewModel>();
    var calls = vm.callHistory;

    // Filter by type
    switch (selectedFilter) {
      case "video calls":
        calls = calls
            .where((c) => c.callType.toLowerCase() == "video")
            .toList();
        break;
      case "audio calls":
        calls = calls
            .where((c) => c.callType.toLowerCase() == "audio")
            .toList();
        break;
    }

    // Filter by specific day
    if (selectedDay != null) {
      calls = calls.where((c) {
        return c.createdAt.year == selectedDay!.year &&
            c.createdAt.month == selectedDay!.month &&
            c.createdAt.day == selectedDay!.day;
      }).toList();
    }

    // Filter by specific month
    if (selectedMonth != null) {
      calls = calls.where((c) {
        return c.createdAt.year == selectedMonth!.year &&
            c.createdAt.month == selectedMonth!.month;
      }).toList();
    }

    // Filter by date range (From - To)
    if (fromDate != null) {
      final start = DateTime(
        fromDate!.year,
        fromDate!.month,
        fromDate!.day,
        0,
        0,
        0,
      );
      calls = calls.where((c) {
        return c.createdAt.isAfter(start) ||
            c.createdAt.isAtSameMomentAs(start);
      }).toList();
    }
    if (toDate != null) {
      final end = DateTime(
        toDate!.year,
        toDate!.month,
        toDate!.day,
        23,
        59,
        59,
      );
      calls = calls.where((c) {
        return c.createdAt.isBefore(end) || c.createdAt.isAtSameMomentAs(end);
      }).toList();
    }

    return calls;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<StaffViewModel>(
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
              child: vm.isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    )
                  : vm.errorMessage != null
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            vm.errorMessage!,
                            style: const TextStyle(color: Colors.redAccent),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: vm.refresh,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFB86AF6),
                            ),
                            child: const Text("Retry"),
                          ),
                        ],
                      ),
                    )
                  : Column(
                      children: [
                        _topBar(context),
                        const SizedBox(height: 8),
                        _buildDatePickerSection(),
                        const SizedBox(height: 12),
                        _buildStatsSummary(),
                        const SizedBox(height: 12),
                        _filterChips(),
                        const SizedBox(height: 8),
                        Expanded(child: _callList(vm)),
                      ],
                    ),
            ),
          ),
        );
      },
    );
  }

  Widget _topBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          widget.backPage
              ? GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF2A1F38),
                      borderRadius: BorderRadius.circular(40),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Icon(
                        Icons.arrow_back,
                        color: Colors.white,
                        size: 26,
                      ),
                    ),
                  ),
                )
              : GestureDetector(
                  onTap: () => bondNavigator.newPageRemoveUntil(
                    context,
                    page: const StaffBottomBar(index: 0),
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF2A1F38),
                      borderRadius: BorderRadius.circular(40),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Icon(
                        Icons.arrow_back,
                        color: Colors.white,
                        size: 26,
                      ),
                    ),
                  ),
                ),
          const SizedBox(width: 16),
          const Text(
            "Recent Calls",
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: () => setState(() => isSearchVisible = !isSearchVisible),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF2A1F38),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white12),
              ),
              child: Icon(
                isSearchVisible ? Icons.search : Icons.close,
                color: Colors.white,
                size: 26,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterChips() {
    final filters = ["all calls", "video calls", "audio calls"];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: filters.map((filter) {
          final isSelected = selectedFilter == filter;
          return GestureDetector(
            onTap: () => setState(() => selectedFilter = filter),
            child: Container(
              margin: const EdgeInsets.only(right: 10),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                gradient: isSelected
                    ? const LinearGradient(
                        colors: [Color(0xFFbcd71c), Color(0xFFbcd71c)],
                      )
                    : const LinearGradient(
                        colors: [Color(0xFF2A1F38), Color(0xFF1C1426)],
                      ),
                border: isSelected
                    ? null
                    : Border.all(color: const Color(0xFF3A2A4A), width: 1),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: const Color(0xFFB86AF6).withOpacity(0.4),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : null,
              ),
              child: Text(
                filter.toUpperCase(),
                style: TextStyle(
                  color: isSelected ? Colors.black : const Color(0xFFB0A8C0),
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  static String formatCallDurationCompact(String durationInSeconds) {
    if (durationInSeconds == "-1") return "Missed";

    try {
      int totalSeconds = double.parse(durationInSeconds).round();
      if (totalSeconds < 60) return '${totalSeconds}s';

      int minutes = totalSeconds ~/ 60;
      int seconds = totalSeconds % 60;

      return seconds > 0 ? '${minutes}m ${seconds}s' : '${minutes}m';
    } catch (e) {
      return durationInSeconds;
    }
  }

  static double _earnedAmountForCall(CallHistoryItem call) {
    if (call.status == CallStatus.missed) return 0;

    final seconds = double.tryParse(call.callDuration) ?? 0;
    final ratePerMinute = call.callType.toLowerCase() == "video" ? 12.0 : 3.0;
    return (seconds / 60) * ratePerMinute;
  }

  static String _formatEarnedAmount(double amount) {
    return "₹${amount.toStringAsFixed(2)}";
  }

  Widget _callList(StaffViewModel vm) {
    if (vm.callHistory.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animated gradient circle with icon
            Center(
              child: Icon(
                Icons.call_end_rounded,
                size: 60,
                color: Colors.grey.shade800,
              ),
            ),

            const SizedBox(height: 22),

            // Premium title text
            const Text(
              "No Call History Yet",
              style: TextStyle(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),

            const SizedBox(height: 12),

            // Subtle description
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                "Your call history will appear here.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 15,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      );
    }
    if (filteredCalls.isEmpty) {
      return Center(
        child: Text(
          "No ${selectedFilter} yet",
          style: const TextStyle(color: Colors.white70, fontSize: 18),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: filteredCalls.length,
      itemBuilder: (context, index) {
        final call = filteredCalls[index];
        final isMissed = call.status == CallStatus.missed;
        final isVideo = call.callType.toLowerCase() == "video";
        final earnedAmount = _earnedAmountForCall(call);

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF2A1F38), Color(0xFF1C1426)],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF3A2A4A)),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundImage: AssetImage("assets/Images/men.png"),
                backgroundColor: const Color(0xFF3A2A4A),
              ),
              const SizedBox(width: 14),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      call.userName,
                      style: TextStyle(
                        color: isMissed ? Colors.redAccent : Colors.white,
                        fontSize: 16.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(
                          isMissed ? Icons.call_received : Icons.call_made,
                          color: isMissed
                              ? Colors.redAccent
                              : Colors.greenAccent,
                          size: 17,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            HistoryTimeFormatter.list(call.createdAt),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xFFB0A8C0),
                              fontSize: 13.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isVideo ? Icons.videocam_rounded : Icons.call_rounded,
                    color: isVideo
                        ? const Color(0xFFB86AF6)
                        : const Color(0xFF7BFF9E),
                    size: 26,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    formatCallDurationCompact(call.callDuration),
                    style: TextStyle(
                      color: isMissed ? Colors.redAccent : Colors.white70,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isMissed
                        ? "₹0.00"
                        : "Earn ${_formatEarnedAmount(earnedAmount)}",
                    style: TextStyle(
                      color: isMissed
                          ? Colors.redAccent
                          : const Color(0xFFBCD71C),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  // ─── CUSTOM DATE AND STATS PICKERS ──────────────────────────────────────────
  Future<void> _selectDay(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDay ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      builder: (context, child) => _datePickerTheme(child),
    );
    if (picked != null) {
      setState(() {
        selectedDay = picked;
        selectedMonth = null;
        fromDate = null;
        toDate = null;
      });
    }
  }

  Future<void> _selectMonth(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedMonth ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      initialDatePickerMode: DatePickerMode.year,
      builder: (context, child) => _datePickerTheme(child),
    );
    if (picked != null) {
      setState(() {
        selectedMonth = DateTime(picked.year, picked.month, 1);
        selectedDay = null;
        fromDate = null;
        toDate = null;
      });
    }
  }

  Future<void> _selectFromDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: fromDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: toDate ?? DateTime.now().add(const Duration(days: 1)),
      builder: (context, child) => _datePickerTheme(child),
    );
    if (picked != null) {
      setState(() {
        fromDate = picked;
        selectedDay = null;
        selectedMonth = null;
      });
    }
  }

  Future<void> _selectToDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: toDate ?? DateTime.now(),
      firstDate: fromDate ?? DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      builder: (context, child) => _datePickerTheme(child),
    );
    if (picked != null) {
      setState(() {
        toDate = picked;
        selectedDay = null;
        selectedMonth = null;
      });
    }
  }

  void _clearFilters() {
    setState(() {
      selectedDay = null;
      selectedMonth = null;
      fromDate = null;
      toDate = null;
    });
  }

  Widget _datePickerTheme(Widget? child) {
    return Theme(
      data: Theme.of(context).copyWith(
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFbcd71c),
          onPrimary: Colors.black,
          surface: Color(0xFF2A1F38),
          onSurface: Colors.white,
        ),
        dialogBackgroundColor: const Color(0xFF1C1426),
      ),
      child: child!,
    );
  }

  Widget _buildDatePickerSection() {
    final hasActiveFilter =
        selectedDay != null ||
        selectedMonth != null ||
        fromDate != null ||
        toDate != null;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: _buildPickerItem(
                  label: 'Day',
                  value: selectedDay != null
                      ? DateFormat('dd-MM-yyyy').format(selectedDay!)
                      : 'dd-mm-yyyy',
                  onTap: () => _selectDay(context),
                  isActive: selectedDay != null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildPickerItem(
                  label: 'Month',
                  value: selectedMonth != null
                      ? DateFormat('MMMM, yyyy').format(selectedMonth!)
                      : '--------, ----',
                  onTap: () => _selectMonth(context),
                  isActive: selectedMonth != null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildPickerItem(
                  label: 'From Date',
                  value: fromDate != null
                      ? DateFormat('dd-MM-yyyy').format(fromDate!)
                      : 'dd-mm-yyyy',
                  onTap: () => _selectFromDate(context),
                  isActive: fromDate != null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildPickerItem(
                  label: 'To Date',
                  value: toDate != null
                      ? DateFormat('dd-MM-yyyy').format(toDate!)
                      : 'dd-mm-yyyy',
                  onTap: () => _selectToDate(context),
                  isActive: toDate != null,
                ),
              ),
            ],
          ),
          if (hasActiveFilter) ...[
            const SizedBox(height: 12),
            GestureDetector(
              onTap: _clearFilters,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 10),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: const Color(0xFFEF4444).withOpacity(0.3),
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.clear_rounded,
                      color: Color(0xFFEF4444),
                      size: 16,
                    ),
                    SizedBox(width: 6),
                    Text(
                      'Reset Filters',
                      style: TextStyle(
                        color: Color(0xFFEF4444),
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPickerItem({
    required String label,
    required String value,
    required VoidCallback onTap,
    bool isActive = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFFB0A8C0),
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF100E1E),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isActive
                    ? const Color(0xFFbcd71c)
                    : const Color(0xFF2A1F38),
                width: 1.5,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    value,
                    style: TextStyle(
                      color: isActive ? Colors.white : const Color(0xFF6B6585),
                      fontSize: 13,
                      fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(
                  Icons.calendar_today_rounded,
                  color: isActive
                      ? const Color(0xFFbcd71c)
                      : const Color(0xFF6B6585),
                  size: 15,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatsSummary() {
    final calls = filteredCalls;
    int totalConnected = 0;
    int totalMissed = 0;
    int videoCount = 0;
    int audioCount = 0;
    int totalSeconds = 0;
    double totalEarned = 0.0;

    for (var call in calls) {
      if (call.status == CallStatus.missed) {
        totalMissed++;
      } else {
        totalConnected++;
        final duration = double.tryParse(call.callDuration) ?? 0.0;
        totalSeconds += duration.round();
        if (call.callType.toLowerCase() == "video") {
          videoCount++;
        } else {
          audioCount++;
        }
        totalEarned += _earnedAmountForCall(call);
      }
    }

    final durationText = formatCallDurationCompact(totalSeconds.toString());

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1C1426),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF3A2A4A)),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'STATS SUMMARY',
                  style: TextStyle(
                    color: Color(0xFFbcd71c),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                  ),
                ),
                Text(
                  'Connected: $totalConnected | Missed: $totalMissed',
                  style: const TextStyle(
                    color: Color(0xFFB0A8C0),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _statsCol(
                  label: 'TOTAL CALLS',
                  value: '${calls.length}',
                  icon: Icons.phone_callback_rounded,
                  color: Colors.white,
                ),
                _statsCol(
                  label: 'AUDIO / VIDEO',
                  value: '$audioCount / $videoCount',
                  icon: Icons.call_merge_rounded,
                  color: const Color(0xFFB86AF6),
                ),
                _statsCol(
                  label: 'TOTAL DURATION',
                  value: durationText == "Missed" ? "0s" : durationText,
                  icon: Icons.access_time_rounded,
                  color: const Color(0xFF7BFF9E),
                ),
                _statsCol(
                  label: 'EARNINGS',
                  value: '₹${totalEarned.toStringAsFixed(2)}',
                  icon: Icons.monetization_on_outlined,
                  color: const Color(0xFFbcd71c),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _statsCol({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: color.withOpacity(0.8), size: 18),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF6B6585),
              fontSize: 9,
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
