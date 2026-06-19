import 'package:flutter/material.dart';
import 'package:dude/Reusable_Widgets/BondingNavigator.dart';
import 'package:url_launcher/url_launcher.dart';

class RefundsCancellationsScreen extends StatelessWidget {
  const RefundsCancellationsScreen({super.key});

  Future<void> _launchEmail() async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: 'dudeofficial@gmail.com',
      queryParameters: {
        'subject': 'Billing Support Request',
        'body':
            'Dear Support Team,\n\nI would like to inquire about:\n\n\n\nBest regards,\n[Your Name]\n[Your Account Email]',
      },
    );

    try {
      if (await canLaunchUrl(emailUri)) {
        await launchUrl(emailUri);
      } else {
        throw 'Could not launch email client';
      }
    } catch (e) {
      print('Error launching email: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0E0A14),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF241b40),
              Color(0xFF12151c),
              Color(0xFF12151c),
              Color(0xFF12151c),
              Color(0xFF12151c),
              Color(0xFF12151c),
              Color(0xFF2b1e4e),
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Custom Back Button
                  GestureDetector(
                    onTap: () => bondNavigator.backPage(context),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2c1e4f),
                        borderRadius: BorderRadius.circular(40),
                      ),
                      child: const Padding(
                        padding: EdgeInsets.all(10.0),
                        child: Icon(
                          Icons.arrow_back,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ),
                  ),

                  // Main Title
                  const Text(
                    "Refunds & Cancellations",
                    style: TextStyle(
                      color: Color(0xFFbdd534),
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 12),

                  Container(
                    height: 2,
                    width: 60,
                    decoration: BoxDecoration(
                      color: const Color(0xFFbdd534),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Subscription Cancellation
                  _buildSubSectionHeader("Subscription Cancellation"),
                  const SizedBox(height: 12),
                  _buildDescriptionText(
                    "Users may cancel their subscription at any time through Google Play Store or Apple App Store settings.",
                  ),
                  const SizedBox(height: 28),

                  // Refund Policy
                  _buildSubSectionHeader("Refund Policy"),
                  const SizedBox(height: 16),
                  _buildBulletPointWithSubtext(
                    "Subscription payments are generally non-refundable after successful activation.",
                  ),
                  const SizedBox(height: 12),
                  _buildBulletPointWithSubtext(
                    "Refund requests may be considered in exceptional cases such as duplicate transactions or technical issues.",
                  ),
                  const SizedBox(height: 12),
                  _buildBulletPointWithSubtext(
                    "Approved refunds may take 5–10 business days to process.",
                  ),
                  const SizedBox(height: 28),

                  // Auto-Renewal
                  _buildSubSectionHeader("Auto-Renewal"),
                  const SizedBox(height: 12),
                  _buildDescriptionText(
                    "Subscriptions may renew automatically unless canceled before the renewal date.",
                  ),
                  const SizedBox(height: 28),

                  // Contact for Billing Issues
                  _buildSubSectionHeader("Contact for Billing Issues"),
                  const SizedBox(height: 12),
                  _buildDescriptionText(
                    "For any billing-related questions or concerns, please contact our support team:",
                  ),
                  const SizedBox(height: 16),

                  // Contact Cards
                  _buildContactCard(
                    icon: Icons.email_outlined,
                    title: "Email Support",
                    detail: "dudeofficial@gmail.com",
                    onTap: () async {
                      await _launchEmail();
                    },
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSubSectionHeader(String title) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 24,
          decoration: BoxDecoration(
            color: const Color(0xFFbdd534),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }

  Widget _buildDescriptionText(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 16),
      child: Text(
        text,
        style: const TextStyle(
          color: Color(0xFFC4C0D0),
          fontSize: 15,
          height: 1.6,
        ),
      ),
    );
  }

  Widget _buildBulletPointWithSubtext(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 6),
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: Color(0xFFbdd534),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Color(0xFFC4C0D0),
                fontSize: 15,
                height: 1.6,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactCard({
    required IconData icon,
    required String title,
    required String detail,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1c122d),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF2A1F38), width: 1),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF2c1e4f),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: const Color(0xFFbdd534), size: 24),
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
                  const SizedBox(height: 4),
                  Text(
                    detail,
                    style: const TextStyle(
                      color: Color(0xFFB0A8C0),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              color: Color(0xFFbdd534),
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}
