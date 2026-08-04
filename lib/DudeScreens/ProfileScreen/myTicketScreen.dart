import 'package:dude/APIService/support_ticket_service.dart';
import 'package:dude/Dude_Utils/App_Theme/DudeTheme.dart';
import 'package:flutter/material.dart';

class MyTicketsScreen extends StatefulWidget {
  @override
  State<MyTicketsScreen> createState() => _MyTicketsScreenState();
}

class _MyTicketsScreenState extends State<MyTicketsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late SupportTicketService _service;
  List<dynamic> activeTickets = [];
  List<dynamic> resolvedTickets = [];
  bool loading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _service = SupportTicketService();
    fetchTickets();
  }

  Future<void> fetchTickets() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final active = await _service.getTickets(status: 'active');
      final resolved = await _service.getTickets(status: 'resolved');
      setState(() {
        activeTickets = active;
        resolvedTickets = resolved;
        loading = false;
      });
    } catch (e) {
      setState(() {
        error = e.toString();
        loading = false;
      });
    }
  }

  Widget buildTicketCard(Map ticket, {bool isActive = true}) {
    final statusColor = isActive ? DudeTheme.accent : DudeTheme.success;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: DudeTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: DudeTheme.border.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: statusColor.withValues(alpha: 0.45),
                  ),
                ),
                child: Text(
                  isActive ? 'Active' : 'Resolved',
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          '#${ticket['ticketId'] ?? ticket['_id'] ?? ''}',
                          style: const TextStyle(
                            color: DudeTheme.textPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          ticket['createdAt'] != null
                              ? _formatDate(ticket['createdAt'])
                              : '',
                          style: const TextStyle(color: DudeTheme.textSubtle),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      ticket['description'] ?? '',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        color: DudeTheme.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (!isActive &&
              (ticket['adminNote'] != null &&
                  (ticket['adminNote'] as String).trim().isNotEmpty))
            Padding(
              padding: const EdgeInsets.only(top: 12.0),
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: DudeTheme.accentDim,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: DudeTheme.accent.withValues(alpha: 0.25),
                  ),
                ),
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Reply from Support',
                      style: TextStyle(
                        color: DudeTheme.accentBright,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      ticket['adminNote'],
                      style: const TextStyle(
                        color: DudeTheme.textPrimary,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _formatDate(String dateStr) {
    try {
      final dt = DateTime.parse(dateStr);
      return "${dt.day.toString().padLeft(2, '0')} ${_monthName(dt.month)} ${dt.year}";
    } catch (_) {
      return dateStr;
    }
  }

  String _monthName(int month) {
    const months = [
      '',
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return months[month];
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DudeTheme.background,
      appBar: AppBar(
        leading: const BackButton(color: DudeTheme.textMid),
        title: const Text(
          'My Tickets',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: DudeTheme.textPrimary,
          ),
        ),
        backgroundColor: DudeTheme.background,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: DudeTheme.accent,
          unselectedLabelColor: DudeTheme.textSubtle,
          indicatorColor: DudeTheme.accent,
          indicatorWeight: 2.5,
          tabs: const [
            Tab(text: 'ACTIVE'),
            Tab(text: 'RESOLVED'),
          ],
        ),
      ),
      body: loading
          ? const Center(
              child: CircularProgressIndicator(
                color: DudeTheme.accent,
                strokeWidth: 2,
              ),
            )
          : error != null
          ? Center(
              child: Text(
                error!,
                style: const TextStyle(color: DudeTheme.danger),
              ),
            )
          : TabBarView(
              controller: _tabController,
              children: [
                activeTickets.isEmpty
                    ? const Center(
                        child: Text(
                          'No active tickets',
                          style: TextStyle(color: DudeTheme.textSubtle),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: activeTickets.length,
                        itemBuilder: (context, i) =>
                            buildTicketCard(activeTickets[i], isActive: true),
                      ),
                resolvedTickets.isEmpty
                    ? const Center(
                        child: Text(
                          'No resolved tickets',
                          style: TextStyle(color: DudeTheme.textSubtle),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: resolvedTickets.length,
                        itemBuilder: (context, i) => buildTicketCard(
                          resolvedTickets[i],
                          isActive: false,
                        ),
                      ),
              ],
            ),
    );
  }
}
