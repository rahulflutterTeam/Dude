import 'package:dude/Reusable_Widgets/AppText_Theme/AppText_Theme.dart';
import 'package:dude/Reusable_Widgets/BondingNavigator.dart';
import 'package:dude/Dude_Utils/App_Theme/DudeTheme.dart';
import 'package:flutter/material.dart';

class TermsAndConditionsScreen extends StatelessWidget {
  const TermsAndConditionsScreen({super.key});

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
                      "Terms & Conditions",
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
                        "DUDE TECH\nTERMS AND CONDITIONS",
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        "Effective Date: 10 May 2026",
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 20),

                      const Text(
                        "Welcome to Dude (\"Platform\"), operated by DUDE TECH (\"Dude\", \"Company\", \"we\", \"our\", or \"us\").\n\n"
                        "By accessing, downloading, registering, or using Dude, you agree to these Terms and Conditions, our Privacy Policy, Community Guidelines, and any additional policies communicated by us.\n\n"
                        "If you do not agree, please do not use the Platform.",
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
                        "• Exchange messages\n"
                        "• Purchase virtual coins\n"
                        "• Interact with hosts and creators\n\n"
                        "Dude acts solely as a technology intermediary and does not guarantee the behavior, actions, or intentions of any user.",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15.5,
                          height: 1.55,
                        ),
                      ),

                      const SizedBox(height: 28),
                      _buildHeading("2. ELIGIBILITY"),
                      const Text(
                        "You may use Dude only if:\n"
                        "• You are at least 18 years old.\n"
                        "• You have the legal capacity to enter into binding agreements.\n"
                        "• You comply with all applicable laws.\n\n"
                        "We may request age verification at any time.\n"
                        "Accounts found belonging to minors may be permanently suspended.",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15.5,
                          height: 1.55,
                        ),
                      ),

                      const SizedBox(height: 28),
                      _buildHeading("3. ACCOUNT REGISTRATION"),
                      const Text(
                        "To use Dude, you may be required to create an account.\n\n"
                        "You agree that:\n"
                        "• Information provided is accurate and complete.\n"
                        "• You will maintain only one personal account.\n"
                        "• You will not impersonate another person.\n"
                        "• You will keep your credentials secure.\n"
                        "• You are responsible for all activities conducted through your account.",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15.5,
                          height: 1.55,
                        ),
                      ),

                      const SizedBox(height: 28),
                      _buildHeading("4. USER RESPONSIBILITIES"),
                      const Text(
                        "You agree:\n"
                        "• Not to violate any law.\n"
                        "• Not to harass or threaten others.\n"
                        "• Not to upload illegal content.\n"
                        "• Not to engage in fraud.\n"
                        "• Not to use automated tools or bots.\n"
                        "• Not to interfere with platform operations.",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15.5,
                          height: 1.55,
                        ),
                      ),

                      const SizedBox(height: 28),
                      _buildHeading("5. AUDIO, VIDEO & CHAT SERVICES"),
                      const Text(
                        "Dude provides communication features including:\n"
                        "• Audio calls\n"
                        "• Video calls\n"
                        "• Messaging\n\n"
                        "Users are solely responsible for their conduct and communications.\n\n"
                        "Dude reserves the right to monitor, review, moderate, restrict, or remove content when necessary for safety, fraud prevention, legal compliance, or community protection.",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15.5,
                          height: 1.55,
                        ),
                      ),

                      const SizedBox(height: 28),
                      _buildHeading("6. VIRTUAL COINS"),
                      const Text(
                        "Dude may offer virtual coins for purchase.\n\n"
                        "Coins may be used for:\n"
                        "• Audio calls\n"
                        "• Video calls\n"
                        "• Creator interactions\n\n"
                        "Important:\n"
                        "• Coins are virtual items only.\n"
                        "• Coins are not redeemable for cash.\n"
                        "• Coins cannot be transferred.\n"
                        "• Coins have no monetary value outside the Platform.\n"
                        "• All purchases are final except where required by law.",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15.5,
                          height: 1.55,
                        ),
                      ),

                      const SizedBox(height: 28),
                      _buildHeading("7. PAYMENTS"),
                      const Text(
                        "Payments may be processed through:\n"
                        "• Cashfree\n"
                        "• Razorpay\n"
                        "• PayU\n"
                        "• Google Play Billing\n"
                        "• Authorized payment providers\n\n"
                        "Dude is not responsible for errors caused by payment service providers.",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15.5,
                          height: 1.55,
                        ),
                      ),

                      const SizedBox(height: 28),
                      _buildHeading("8. REFUND POLICY"),
                      const Text(
                        "Except where required by law:\n"
                        "• Coin purchases are non-refundable.\n"
                        "• Used services are non-refundable.\n\n"
                        "Refund requests may be reviewed on a case-by-case basis.",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15.5,
                          height: 1.55,
                        ),
                      ),

                      const SizedBox(height: 28),
                      _buildHeading("9. HOSTS & CREATORS"),
                      const Text(
                        "Hosts and creators participating in Dude:\n"
                        "• Operate independently.\n"
                        "• Are not employees of Dude.\n"
                        "• Must comply with Platform policies.\n\n"
                        "Dude may suspend, restrict, or remove hosts at its discretion.",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15.5,
                          height: 1.55,
                        ),
                      ),

                      const SizedBox(height: 28),
                      _buildHeading("10. CONTENT OWNERSHIP"),
                      const Text(
                        "Users retain ownership of content they upload.\n\n"
                        "By uploading content, you grant Dude a worldwide, non-exclusive license to host, store, display, moderate, and process content for Platform operations.",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15.5,
                          height: 1.55,
                        ),
                      ),

                      const SizedBox(height: 28),
                      _buildHeading("11. PROHIBITED ACTIVITIES"),
                      const Text(
                        "Users must not:\n"
                        "• Share pornography\n"
                        "• Share nudity\n"
                        "• Promote prostitution\n"
                        "• Engage in sexual exploitation\n"
                        "• Harass users\n"
                        "• Spread hate speech\n"
                        "• Commit fraud\n"
                        "• Promote gambling\n"
                        "• Share illegal content\n"
                        "• Impersonate others\n"
                        "• Share malware\n"
                        "• Circumvent security systems\n\n"
                        "Violations may result in permanent suspension.",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15.5,
                          height: 1.55,
                        ),
                      ),

                      const SizedBox(height: 28),
                      _buildHeading("12. ACCOUNT SUSPENSION & TERMINATION"),
                      const Text(
                        "Dude may suspend or terminate accounts for:\n"
                        "• Policy violations\n"
                        "• Fraudulent activity\n"
                        "• Security concerns\n"
                        "• Regulatory requirements\n"
                        "• Harmful behavior\n\n"
                        "No prior notice is required where immediate action is necessary.",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15.5,
                          height: 1.55,
                        ),
                      ),

                      const SizedBox(height: 28),
                      _buildHeading("13. DISCLAIMER"),
                      const Text(
                        "Dude is provided on an \"AS IS\" and \"AS AVAILABLE\" basis.\n\n"
                        "We do not guarantee:\n"
                        "• Uninterrupted service\n"
                        "• Error-free operation\n"
                        "• User compatibility\n"
                        "• Success of interactions",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15.5,
                          height: 1.55,
                        ),
                      ),

                      const SizedBox(height: 28),
                      _buildHeading("14. LIMITATION OF LIABILITY"),
                      const Text(
                        "To the maximum extent permitted by law:\n"
                        "DUDE TECH shall not be liable for:\n"
                        "• Indirect damages\n"
                        "• Consequential damages\n"
                        "• Lost profits\n"
                        "• Lost data\n"
                        "• Emotional distress\n\n"
                        "Maximum liability shall not exceed INR 1,000.",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15.5,
                          height: 1.55,
                        ),
                      ),

                      const SizedBox(height: 28),
                      _buildHeading("15. INDEMNIFICATION"),
                      const Text(
                        "You agree to indemnify and hold harmless Dude from claims arising from:\n"
                        "• Your actions\n"
                        "• Your content\n"
                        "• Your violations of these Terms\n"
                        "• Your violation of applicable laws",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15.5,
                          height: 1.55,
                        ),
                      ),

                      const SizedBox(height: 28),
                      _buildHeading("16. GOVERNING LAW"),
                      const Text(
                        "These Terms shall be governed by Indian law.\n"
                        "Courts located in Madurai, Tamil Nadu shall have exclusive jurisdiction.",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15.5,
                          height: 1.55,
                        ),
                      ),

                      const SizedBox(height: 28),
                      _buildHeading("17. CONTACT"),
                      const Text(
                        "DUDE TECH\n"
                        "Plot No. 1, Velan Nagar, Lakshmi Complex,\n"
                        "Sengunram Nagar, Madurai – 625004, Tamil Nadu, India\n\n"
                        "Support: dudeofficial@gmail.com\n"
                        "Grievance: hariharanpandiyarajan8@gmail.com\n"
                        "Nodal: vinithrichardsjl@gmail.com",
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
