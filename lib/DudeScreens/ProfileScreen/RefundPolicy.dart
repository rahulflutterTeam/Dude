import 'package:dude/Dude_Utils/App_Theme/DudeTheme.dart';
import 'package:dude/Reusable_Widgets/BondingNavigator.dart';
import 'package:flutter/material.dart';

class RefundPolicyScreen extends StatelessWidget {
  const RefundPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DudeTheme.background,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: DudeTheme.backgroundGradient,
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => bondNavigator.backPage(context),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: DudeTheme.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: DudeTheme.border),
                        ),
                        child: const Icon(
                          Icons.arrow_back_ios_new,
                          color: DudeTheme.textPrimary,
                          size: 18,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Refund Policy',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: DudeTheme.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _heroCard(),
                      const SizedBox(height: 16),
                      _sectionCard(
                        title: '1. Virtual Coins',
                        body:
                            'Coins purchased on Dude are virtual digital items and have no cash value.\n\n'
                            'Once Coins are successfully credited to your account, purchases are generally non-refundable.\n\n'
                            'Coins cannot be exchanged for cash, transferred to another user, or redeemed outside the Platform.',
                      ),
                      _sectionCard(
                        title: '2. Eligible Refund Cases',
                        body:
                            'Refund requests may be considered in the following circumstances:\n'
                            '• Duplicate payment due to a technical error.\n'
                            '• Payment completed but Coins were not credited.\n'
                            '• Unauthorized transaction verified by Dude.\n'
                            '• Service interruption caused solely by a platform-side technical issue.',
                      ),
                      _sectionCard(
                        title: '3. Non-Refundable Cases',
                        body:
                            'Refunds will not be provided for:\n'
                            '• Used Coins.\n'
                            '• Completed audio calls, video calls, or premium services.\n'
                            '• User dissatisfaction with another user\'s behavior.\n'
                            '• Accidental purchases by the user.\n'
                            '• Temporary internet or device-related issues.\n'
                            '• Account suspension due to policy violations.',
                      ),
                      _sectionCard(
                        title: '4. Refund Request Process',
                        body:
                            'To request a refund, contact:\n'
                            'Email: dudeappofficial@gmail.com\n\n'
                            'Provide:\n'
                            '• Registered mobile number\n'
                            '• Transaction ID\n'
                            '• Payment screenshot (if available)\n'
                            '• Description of the issue',
                      ),
                      _sectionCard(
                        title: '5. Refund Processing',
                        body:
                            'Approved refunds may take 5–10 business days depending on the payment provider and banking institution.',
                      ),
                      _sectionCard(
                        title: '6. Policy Changes',
                        body:
                            'Dude reserves the right to modify this Refund Policy at any time. Updated versions will be published on the Platform.',
                      ),
                      _sectionCard(
                        title: 'Contact Us',
                        body:
                            'DUDE TECH\n'
                            'Registered Office\n'
                            'Plot No. 1, Velan Nagar, Lakshmi Complex,\n'
                            'Sengunram Nagar, Madurai – 625004,\n'
                            'Tamil Nadu, India\n\n'
                            'Customer Support\n'
                            'Email: dudeappofficial@gmail.com\n\n'
                            'Grievance Officer\n'
                            'Name: Hari Haran\n'
                            'Email: hariharanpandiyarajan8@gmail.com\n\n'
                            'Nodal Officer\n'
                            'Name: Vinith J\n'
                            'Email: vinithrichardsjl@gmail.com\n\n'
                            'Business Hours\n'
                            'Monday – Saturday\n'
                            '10:00 AM – 6:00 PM (IST)\n\n'
                            'Response Time\n'
                            'General Support: Within 24–48 hours\n'
                            'Payment Issues: Within 3–5 business days\n'
                            'Grievance Complaints: Within 15 days as per applicable regulations',
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _heroCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: DudeTheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: DudeTheme.border.withValues(alpha: 0.55)),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            DudeTheme.accentDim,
            DudeTheme.surface,
          ],
        ),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'REFUND POLICY',
            style: TextStyle(
              color: DudeTheme.accentBright,
              fontSize: 20,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.4,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Effective Date: 10 May 2026',
            style: TextStyle(
              color: DudeTheme.textSubtle,
              fontSize: 13,
            ),
          ),
          SizedBox(height: 12),
          Text(
            'At Dude, we strive to provide a seamless user experience. This Refund Policy explains how refunds are handled for purchases made on the Platform.',
            style: TextStyle(
              color: DudeTheme.textMuted,
              fontSize: 14.5,
              height: 1.55,
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionCard({required String title, required String body}) {
    return Container(
      width: double.infinity,
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
          Text(
            title,
            style: const TextStyle(
              color: DudeTheme.accent,
              fontSize: 15.5,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            body,
            style: const TextStyle(
              color: DudeTheme.textPrimary,
              fontSize: 14.5,
              height: 1.55,
            ),
          ),
        ],
      ),
    );
  }
}
