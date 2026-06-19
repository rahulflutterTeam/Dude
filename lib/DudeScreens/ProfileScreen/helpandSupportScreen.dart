// help_and_support_screen.dart
import 'package:dude/APIService/support_ticket_service.dart';
import 'package:dude/DudeScreens/ProfileScreen/myTicketScreen.dart';
import 'package:dude/DudeScreens/ProfileScreen/submitTicketScreen.dart';
import 'package:flutter/material.dart';

class HelpAndSupportScreen extends StatefulWidget {
  @override
  State<HelpAndSupportScreen> createState() => _HelpAndSupportScreenState();
}

class _HelpAndSupportScreenState extends State<HelpAndSupportScreen> {
  final Color primary = const Color(0xFFcee640); // Updated app main color
  late SupportTicketService _service;
  Map<String, dynamic>? dashboard;
  bool loading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    // TODO: Replace with your actual baseUrl and token retrieval
    _service = SupportTicketService();
    fetchDashboard();
  }

  Future<void> fetchDashboard() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final data = await _service.getDashboard();
      setState(() {
        dashboard = data;
        loading = false;
      });
    } catch (e) {
      setState(() {
        error = e.toString();
        loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF080612),
      appBar: AppBar(
        leading: BackButton(color: Colors.white54),
        title: Text(
          'Help and Support',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF100E1E),
        elevation: 0,
      ),
      body: loading
          ? Center(child: CircularProgressIndicator())
          : error != null
          ? Center(child: Text(error!))
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Your tickets',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 8),
                  Card(
                    color: const Color(0xFF100E1E),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: ListTile(
                      title: Text(
                        'Raised Ticket',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      subtitle: Text(
                        '${dashboard?['activeTickets'] ?? 0} active ticket',
                        style: TextStyle(color: primary),
                      ),
                      leading: CircleAvatar(
                        backgroundColor: primary,
                        child: Icon(Icons.info, color: Colors.white),
                      ),
                      trailing: Icon(Icons.chevron_right, color: Colors.white),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => MyTicketsScreen()),
                        );
                      },
                    ),
                  ),
                  SizedBox(height: 24),
                  Text(
                    'Create a new ticket',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 8),
                  Card(
                    color: const Color(0xFF100E1E),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: ListTile(
                      title: Text(
                        'Raise new ticket',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      leading: CircleAvatar(
                        backgroundColor: primary,
                        child: Icon(Icons.info, color: Colors.white),
                      ),
                      trailing: Icon(Icons.chevron_right, color: Colors.white),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => SubmitTicketScreen(),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
