import 'package:dude/APIService/support_ticket_service.dart';
import 'package:dude/DudeScreens/ProfileScreen/myTicketScreen.dart';
import 'package:dude/DudeScreens/ProfileScreen/submitTicketScreen.dart';
import 'package:dude/Dude_Utils/App_Theme/DudeTheme.dart';
import 'package:flutter/material.dart';

class HelpAndSupportScreen extends StatefulWidget {
  @override
  State<HelpAndSupportScreen> createState() => _HelpAndSupportScreenState();
}

class _HelpAndSupportScreenState extends State<HelpAndSupportScreen> {
  late SupportTicketService _service;
  Map<String, dynamic>? dashboard;
  bool loading = true;
  String? error;

  @override
  void initState() {
    super.initState();
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
      backgroundColor: DudeTheme.background,
      appBar: AppBar(
        leading: const BackButton(color: DudeTheme.textMid),
        title: const Text(
          'Help and Support',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: DudeTheme.textPrimary,
          ),
        ),
        backgroundColor: DudeTheme.background,
        elevation: 0,
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
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Your tickets',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                      color: DudeTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _SupportTile(
                    title: 'Raised Ticket',
                    subtitle:
                        '${dashboard?['activeTickets'] ?? 0} active ticket',
                    icon: Icons.confirmation_number_outlined,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => MyTicketsScreen()),
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Create a new ticket',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                      color: DudeTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _SupportTile(
                    title: 'Raise new ticket',
                    subtitle: 'Describe your issue and attach screenshots',
                    icon: Icons.add_circle_outline_rounded,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => SubmitTicketScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
    );
  }
}

class _SupportTile extends StatelessWidget {
  const _SupportTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: DudeTheme.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: DudeTheme.border.withValues(alpha: 0.5)),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 6,
            ),
            title: Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: DudeTheme.textPrimary,
              ),
            ),
            subtitle: Text(
              subtitle,
              style: const TextStyle(color: DudeTheme.accent),
            ),
            leading: CircleAvatar(
              backgroundColor: DudeTheme.accentDim,
              child: Icon(icon, color: DudeTheme.accent),
            ),
            trailing: const Icon(
              Icons.chevron_right_rounded,
              color: DudeTheme.textMid,
            ),
          ),
        ),
      ),
    );
  }
}
