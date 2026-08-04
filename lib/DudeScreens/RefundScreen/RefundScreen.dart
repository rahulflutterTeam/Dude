import 'package:dude/Dude_Utils/App_Theme/DudeTheme.dart';
import 'package:dude/Reusable_Widgets/BondingNavigator.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class RefundsCancellationsScreen extends StatelessWidget {
  const RefundsCancellationsScreen({super.key});

  Future<void> _launchEmail() async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: 'dudeappofficial@gmail.com',
      queryParameters: {
        'subject': 'Billing Support Request',
        'body':
            'Dear Support Team,\n\nI would like to inquire about:\n\n\n\nBest regards,\n[Your Name]\n[Your Account Email]',
      },
    );

    try {
      if (await canLaunchUrl(emailUri)) {
        await launchUrl(emailUri);
      }
    } catch (e) {
      debugPrint('Error launching email: $e');
    }
  }

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
                      'Refunds & Cancellations',
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
                        title: 'Subscription Cancellation',
                        child: const Text(
                          'Users may cancel their subscription at any time through Google Play Store or Apple App Store settings.',
                          style: TextStyle(
                            color: DudeTheme.textPrimary,
                            fontSize: 14.5,
                            height: 1.55,
                          ),
                        ),
                      ),
                      _sectionCard(
                        title: 'Refund Policy',
                        child: Column(
                          children: [
                            _bullet(
                              'Subscription payments are generally non-refundable after successful activation.',
                            ),
                            const SizedBox(height: 10),
                            _bullet(
                              'Refund requests may be considered in exceptional cases such as duplicate transactions or technical issues.',
                            ),
                            const SizedBox(height: 10),
                            _bullet(
                              'Approved refunds may take 5–10 business days to process.',
                            ),
                          ],
                        ),
                      ),
                      _sectionCard(
                        title: 'Auto-Renewal',
                        child: const Text(
                          'Subscriptions may renew automatically unless canceled before the renewal date.',
                          style: TextStyle(
                            color: DudeTheme.textPrimary,
                            fontSize: 14.5,
                            height: 1.55,
                          ),
                        ),
                      ),
                      _sectionCard(
                        title: 'Contact for Billing Issues',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'For any billing-related questions or concerns, please contact our support team:',
                              style: TextStyle(
                                color: DudeTheme.textPrimary,
                                fontSize: 14.5,
                                height: 1.55,
                              ),
                            ),
                            const SizedBox(height: 14),
                            _contactCard(
                              icon: Icons.email_outlined,
                              title: 'Email Support',
                              detail: 'dudeappofficial@gmail.com',
                              onTap: _launchEmail,
                            ),
                          ],
                        ),
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
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: DudeTheme.border.withValues(alpha: 0.55)),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [DudeTheme.accentDim, DudeTheme.surface],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Refunds & Cancellations',
            style: TextStyle(
              color: DudeTheme.accentBright,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            height: 3,
            width: 48,
            decoration: BoxDecoration(
              gradient: DudeTheme.premiumAccentGradient,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Learn how cancellations, refunds, and billing support work on Dude.',
            style: TextStyle(
              color: DudeTheme.textMuted,
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionCard({required String title, required Widget child}) {
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
          Row(
            children: [
              Container(
                width: 4,
                height: 22,
                decoration: BoxDecoration(
                  gradient: DudeTheme.premiumAccentGradient,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: DudeTheme.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _bullet(String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 7),
          width: 6,
          height: 6,
          decoration: const BoxDecoration(
            color: DudeTheme.accent,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: DudeTheme.textPrimary,
              fontSize: 14.5,
              height: 1.55,
            ),
          ),
        ),
      ],
    );
  }

  Widget _contactCard({
    required IconData icon,
    required String title,
    required String detail,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: DudeTheme.surfaceRaised,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: DudeTheme.border.withValues(alpha: 0.55)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: DudeTheme.accentDim,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: DudeTheme.accent.withValues(alpha: 0.35),
                ),
              ),
              child: Icon(icon, color: DudeTheme.accent, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: DudeTheme.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    detail,
                    style: const TextStyle(
                      color: DudeTheme.accentBright,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              color: DudeTheme.accent,
              size: 14,
            ),
          ],
        ),
      ),
    );
  }
}
