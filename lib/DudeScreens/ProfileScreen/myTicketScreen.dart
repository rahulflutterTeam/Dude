// my_tickets_screen.dart
import 'package:flutter/material.dart';
import 'package:dude/APIService/support_ticket_service.dart';

class MyTicketsScreen extends StatefulWidget {
  @override
  State<MyTicketsScreen> createState() => _MyTicketsScreenState();
}

class _MyTicketsScreenState extends State<MyTicketsScreen>
    with SingleTickerProviderStateMixin {
  final Color primary = const Color(0xFFcee640); // Updated app main color
  final Color cardBg = const Color(0xFF100E1E);
  final Color bg = const Color(0xFF080612);
  final Color resolvedGreen = Color(0xFF3DC16B);
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
    return Card(
      color: cardBg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: isActive ? primary : resolvedGreen,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        isActive ? 'Active' : 'Resolved',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            '#${ticket['ticketId'] ?? ticket['_id'] ?? ''}',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Spacer(),
                          Text(
                            ticket['createdAt'] != null
                                ? _formatDate(ticket['createdAt'])
                                : '',
                            style: TextStyle(color: Colors.white70),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Text(
                        ticket['description'] ?? '',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: Colors.white,
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
                    color: Colors.white.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Reply from Support',
                        style: TextStyle(
                          color: Color(0xFF3B7BCE),
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      SizedBox(height: 6),
                      Text(
                        ticket['adminNote'],
                        style: TextStyle(color: Colors.white, fontSize: 15),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
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
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        leading: BackButton(color: Colors.white54),
        title: Text(
          'My Tickets',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: cardBg,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: primary,
          unselectedLabelColor: Colors.white54,
          indicatorColor: primary,
          tabs: [
            Tab(text: 'ACTIVE'),
            Tab(text: 'RESOLVED'),
          ],
        ),
      ),
      body: loading
          ? Center(child: CircularProgressIndicator())
          : error != null
          ? Center(child: Text(error!))
          : TabBarView(
              controller: _tabController,
              children: [
                // Active Tickets
                activeTickets.isEmpty
                    ? Center(child: Text('No active tickets'))
                    : ListView.builder(
                        padding: EdgeInsets.all(16),
                        itemCount: activeTickets.length,
                        itemBuilder: (context, i) =>
                            buildTicketCard(activeTickets[i], isActive: true),
                      ),
                // Resolved Tickets
                resolvedTickets.isEmpty
                    ? Center(child: Text('No resolved tickets'))
                    : ListView.builder(
                        padding: EdgeInsets.all(16),
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
