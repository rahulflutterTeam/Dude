import 'package:dude/Reusable_Widgets/AppText_Theme/AppText_Theme.dart';
import 'package:dude/Reusable_Widgets/BondingNavigator.dart';
import 'package:dude/Dude_Utils/App_Theme/DudeTheme.dart';
import 'package:flutter/material.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

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
              // Top Bar
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => bondNavigator.backPage(context),
                      child: Container(
                        decoration: BoxDecoration(
                          color: DudeTheme.surfaceRaised,
                          borderRadius: BorderRadius.circular(40),
                        ),
                        child: const Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Icon(Icons.arrow_back, color: Colors.white),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    AppText(
                      "Privacy Policy",
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ],
                ),
              ),

              // Full Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 10),
                      AppText(
                        "DUDE TECH\nPRIVACY POLICY",
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        "Effective Date: 10 May 2026\nLast Updated: 04 June 2026",
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 20),

                      const Text(
                        "Welcome to Dude (\"Platform\"), operated by DUDE TECH (\"Dude\", \"Company\", \"we\", \"our\", or \"us\").\n\n"
                        "This Privacy Policy explains how we collect, use, store, process, and disclose your information when you use Dude, including our mobile applications, websites, audio calls, video calls, chat services, coin purchases, creator/host programs, and related services.\n\n"
                        "By using Dude, you agree to the practices described in this Privacy Policy.",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15.5,
                          height: 1.55,
                        ),
                      ),

                      const SizedBox(height: 28),
                      _buildHeading("1. ABOUT DUDE"),
                      const Text(
                        "Dude is a social discovery platform that enables users to:\n"
                        "• Discover and connect with other users\n"
                        "• Participate in audio calls\n"
                        "• Participate in video calls\n"
                        "• Send and receive messages\n"
                        "• Purchase virtual coins\n"
                        "• Access premium features\n"
                        "• Interact with verified hosts/creators\n\n"
                        "Dude acts as a technology intermediary facilitating interactions between users and hosts.",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15.5,
                          height: 1.55,
                        ),
                      ),

                      const SizedBox(height: 28),
                      _buildHeading("2. INFORMATION WE COLLECT"),
                      const Text(
                        "A. Account Information\n"
                        "When you register, we may collect:\n"
                        "• Username\n"
                        "• Mobile Number\n"
                        "• Email Address\n"
                        "• Gender\n"
                        "• Date of Birth\n"
                        "• Profile Picture\n"
                        "• Language Preference\n"
                        "• Country and State\n\n"
                        "B. Profile Information\n"
                        "You may voluntarily provide:\n"
                        "• Biography\n"
                        "• Interests\n"
                        "• Preferences\n"
                        "• Photos\n"
                        "• Social Discovery Information\n\n"
                        "C. Audio & Video Call Information\n"
                        "To provide audio and video services, we may collect:\n"
                        "• Call duration\n"
                        "• Call timestamps\n"
                        "• Call participants\n"
                        "• Connection quality information\n"
                        "• Call activity logs\n"
                        "• Call moderation data\n\n"
                        "Where legally permitted and necessary for safety, fraud prevention, platform moderation, or legal compliance, Dude may review, analyze, or retain limited call-related information.\n\n"
                        "D. Chat Information\n"
                        "When using messaging features, we may collect:\n"
                        "• Messages sent and received\n"
                        "• Chat timestamps\n"
                        "• User reports related to chats\n\n"
                        "E. Device Information\n"
                        "We may collect:\n"
                        "• App Version\n"
                        "This information is used to maintain compatibility with our services, diagnose technical issues, and improve application performance and user experience.\n\n"
                        "F. Location Information\n"
                        "With your permission, we may collect:\n"
                        "• Country\n"
                        "• State\n"
                        "• City\n"
                        "Location information may be used to improve matching, safety, and content personalization.\n\n"
                        "G. Payment Information\n"
                        "When purchasing coins or premium features, we may collect:\n"
                        "• Transaction ID\n"
                        "• Payment Status\n"
                        "• Payment Amount\n"
                        "• Purchase History\n"
                        "• Refund Information\n"
                        "Payment card details are processed directly by our payment providers and are not stored by Dude.\n\n"
                        "H. Host / Creator Information\n"
                        "For hosts and creators, we may collect:\n"
                        "• Name\n"
                        "• PAN Details\n"
                        "• Aadhaar Details\n"
                        "• Bank Account Information\n"
                        "• UPI Information\n"
                        "• KYC Documents\n"
                        "• Earnings Information\n"
                        "This information is collected solely for verification, compliance, taxation, and payout processing.\n\n"
                        "I. Analytics Information\n"
                        "We may collect:\n"
                        "• Session duration\n"
                        "• User activity\n"
                        "• Feature usage\n"
                        "• Crash reports\n"
                        "• Performance metrics",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15.5,
                          height: 1.55,
                        ),
                      ),

                      const SizedBox(height: 28),
                      _buildHeading("3. HOW WE USE INFORMATION"),
                      const Text(
                        "We use information to:\n"
                        "• Create and manage accounts\n"
                        "• Verify user identity\n"
                        "• Enable audio and video calls\n"
                        "• Enable chat functionality\n"
                        "• Process coin purchases\n"
                        "• Process creator payouts\n"
                        "• Detect fraud and abuse\n"
                        "• Improve platform performance\n"
                        "• Personalize user experience\n"
                        "• Comply with legal obligations\n"
                        "• Resolve disputes and complaints\n"
                        "• Protect users and the platform",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15.5,
                          height: 1.55,
                        ),
                      ),

                      const SizedBox(height: 28),
                      _buildHeading("4. CONTENT MODERATION"),
                      const Text(
                        "To maintain platform safety, Dude may use:\n"
                        "• Automated moderation systems\n"
                        "• Human review processes\n"
                        "• User reporting mechanisms\n\n"
                        "Content, chats, audio, video, profiles, and interactions may be reviewed when necessary to investigate violations of our policies.",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15.5,
                          height: 1.55,
                        ),
                      ),

                      const SizedBox(height: 28),
                      _buildHeading("5. INFORMATION SHARING"),
                      const Text(
                        "We do not sell personal information.\n\n"
                        "We may share information with:\n"
                        "• Service Providers (Cloud hosting, Analytics, Communication, Customer support)\n"
                        "• Payment Providers (Cashfree, Razorpay, PayU, Banking partners)\n"
                        "• Legal Authorities (When required by law, court orders, or government requests)\n\n"
                        "Business Transfers: If Dude undergoes merger, acquisition, restructuring, or sale.",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15.5,
                          height: 1.55,
                        ),
                      ),

                      const SizedBox(height: 28),
                      _buildHeading("6. DATA RETENTION"),
                      const Text(
                        "We retain information for as long as necessary to:\n"
                        "• Provide services\n"
                        "• Maintain security\n"
                        "• Resolve disputes\n"
                        "• Prevent fraud\n"
                        "• Comply with legal obligations\n\n"
                        "Certain records may be retained after account deletion where required by law.",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15.5,
                          height: 1.55,
                        ),
                      ),

                      const SizedBox(height: 28),
                      _buildHeading("7. ACCOUNT DELETION"),
                      const Text(
                        "Users may request account deletion by contacting:\n"
                        "dudeappofficial@gmail.com\n\n"
                        "Upon deletion:\n"
                        "• Public profile information will be removed.\n"
                        "• Access to the account will be disabled.\n"
                        "• Certain records may be retained for legal and compliance purposes.",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15.5,
                          height: 1.55,
                        ),
                      ),

                      const SizedBox(height: 28),
                      _buildHeading("8. USER RIGHTS"),
                      const Text(
                        "Subject to applicable laws, users may:\n"
                        "• Access personal information\n"
                        "• Correct inaccurate information\n"
                        "• Request deletion\n"
                        "• Withdraw consent\n"
                        "• Object to certain processing activities\n\n"
                        "Requests may be submitted to:\n"
                        "dudeappofficial@gmail.com",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15.5,
                          height: 1.55,
                        ),
                      ),

                      const SizedBox(height: 28),
                      _buildHeading("9. SECURITY"),
                      const Text(
                        "We use reasonable technical, organizational, and administrative safeguards to protect information against unauthorized access, loss, misuse, alteration, or disclosure.\n\n"
                        "However, no method of transmission or storage is completely secure.",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15.5,
                          height: 1.55,
                        ),
                      ),

                      const SizedBox(height: 28),
                      _buildHeading("10. CHILDREN'S PRIVACY"),
                      const Text(
                        "Dude is strictly intended for users aged 18 years and above.\n\n"
                        "We do not knowingly collect information from individuals under 18 years of age.\n"
                        "Accounts identified as belonging to minors may be permanently removed.",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15.5,
                          height: 1.55,
                        ),
                      ),

                      const SizedBox(height: 28),
                      _buildHeading("11. INTERNATIONAL DATA PROCESSING"),
                      const Text(
                        "Your information may be processed using servers and service providers located within or outside India, subject to applicable data protection laws.",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15.5,
                          height: 1.55,
                        ),
                      ),

                      const SizedBox(height: 28),
                      _buildHeading("12. COOKIES & TRACKING TECHNOLOGIES"),
                      const Text(
                        "We may use:\n"
                        "• Cookies\n"
                        "• SDKs\n"
                        "• Analytics Tools\n"
                        "• Device Identifiers\n\n"
                        "to improve services, security, and performance.",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15.5,
                          height: 1.55,
                        ),
                      ),

                      const SizedBox(height: 28),
                      _buildHeading("13. CHANGES TO THIS POLICY"),
                      const Text(
                        "We may update this Privacy Policy from time to time.\n\n"
                        "Material changes may be communicated through:\n"
                        "• App notifications\n"
                        "• Email\n"
                        "• SMS\n\n"
                        "Continued use of Dude after updates constitutes acceptance of the revised Privacy Policy.",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15.5,
                          height: 1.55,
                        ),
                      ),

                      const SizedBox(height: 28),
                      _buildHeading("14. GRIEVANCE REDRESSAL"),
                      const Text(
                        "For privacy concerns, complaints, or requests:\n\n"
                        "Support\n"
                        "Email: dudeappofficial@gmail.com\n\n"
                        "Grievance Officer\n"
                        "Name: Hari Haran\n"
                        "Email: hariharanpandiyarajan8@gmail.com\n\n"
                        "Nodal Officer\n"
                        "Name: Vinith J\n"
                        "Email: vinithrichardsjl@gmail.com\n\n"
                        "Registered Office\n"
                        "DUDE TECH\n"
                        "Plot No. 1, Velan Nagar, Lakshmi Complex,\n"
                        "Sengunram Nagar, Madurai – 625004,\n"
                        "Tamil Nadu, India",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15.5,
                          height: 1.55,
                        ),
                      ),

                      const SizedBox(height: 50),
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

  Widget _buildHeading(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        text,
        style: const TextStyle(
          color: DudeTheme.accent,
          fontSize: 17.5,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
