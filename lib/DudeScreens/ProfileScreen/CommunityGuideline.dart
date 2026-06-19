import 'package:dude/Reusable_Widgets/AppText_Theme/AppText_Theme.dart';
import 'package:dude/Reusable_Widgets/BondingNavigator.dart';
import 'package:flutter/material.dart';

class CommunityGuidelinesScreen extends StatelessWidget {
  const CommunityGuidelinesScreen({super.key});

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
              Color(0xFF2b1e4e),
            ],
          ),
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
                          color: const Color(0xFF2c1e4f),
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
                      "Community Guidelines",
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
                        "DUDE PRIVATE LIMITED\nCOMMUNITY GUIDELINES",
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
                        "Dude is built to create safe, respectful, and meaningful social interactions.\n\n"
                        "All users must follow these Community Guidelines.",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15.5,
                          height: 1.55,
                        ),
                      ),

                      const SizedBox(height: 28),
                      _buildHeading("1. AGE REQUIREMENT"),
                      const Text(
                        "You must be 18 years or older.\n"
                        "We do not permit minors on Dude.\n"
                        "Accounts identified as underage will be permanently removed.",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15.5,
                          height: 1.55,
                        ),
                      ),

                      const SizedBox(height: 28),
                      _buildHeading("2. RESPECTFUL BEHAVIOR"),
                      const Text(
                        "Users must:\n"
                        "✅ Be respectful\n"
                        "✅ Communicate politely\n"
                        "✅ Respect personal boundaries\n"
                        "✅ Treat others fairly",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15.5,
                          height: 1.55,
                        ),
                      ),

                      const SizedBox(height: 28),
                      _buildHeading("3. NUDITY & SEXUAL CONTENT"),
                      const Text(
                        "Strictly prohibited:\n"
                        "❌ Nudity\n"
                        "❌ Pornographic content\n"
                        "❌ Explicit sexual activity\n"
                        "❌ Sexual live streaming\n"
                        "❌ Sexual solicitation\n"
                        "❌ Escort services\n"
                        "❌ Prostitution-related content\n"
                        "❌ Sexually explicit profile photos",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15.5,
                          height: 1.55,
                        ),
                      ),

                      const SizedBox(height: 28),
                      _buildHeading("4. HARASSMENT & ABUSE"),
                      const Text(
                        "Not allowed:\n"
                        "❌ Bullying\n"
                        "❌ Threats\n"
                        "❌ Stalking\n"
                        "❌ Blackmail\n"
                        "❌ Intimidation\n"
                        "❌ Repeated unwanted contact\n"
                        "❌ Verbal abuse",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15.5,
                          height: 1.55,
                        ),
                      ),

                      const SizedBox(height: 28),
                      _buildHeading("5. CHILD SAFETY"),
                      const Text(
                        "Zero tolerance policy.\n\n"
                        "Prohibited:\n"
                        "❌ Child sexual abuse material\n"
                        "❌ Child exploitation\n"
                        "❌ Grooming\n"
                        "❌ Sexualization of minors\n\n"
                        "Violations may be reported to law enforcement authorities.",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15.5,
                          height: 1.55,
                        ),
                      ),

                      const SizedBox(height: 28),
                      _buildHeading("6. HATE SPEECH"),
                      const Text(
                        "Prohibited:\n"
                        "❌ Racism\n"
                        "❌ Religious hatred\n"
                        "❌ Caste discrimination\n"
                        "❌ Gender discrimination\n"
                        "❌ Disability-based abuse\n"
                        "❌ Nationality-based attacks",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15.5,
                          height: 1.55,
                        ),
                      ),

                      const SizedBox(height: 28),
                      _buildHeading("7. SCAMS & FRAUD"),
                      const Text(
                        "Users may not:\n"
                        "❌ Request money\n"
                        "❌ Seek loans\n"
                        "❌ Offer investment schemes\n"
                        "❌ Run crypto scams\n"
                        "❌ Promote Ponzi schemes\n"
                        "❌ Share payment credentials\n"
                        "❌ Request OTPs",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15.5,
                          height: 1.55,
                        ),
                      ),

                      const SizedBox(height: 28),
                      _buildHeading("8. IMPERSONATION"),
                      const Text(
                        "Prohibited:\n"
                        "❌ Fake profiles\n"
                        "❌ Identity theft\n"
                        "❌ Catfishing\n"
                        "❌ Deepfake impersonation\n\n"
                        "Users must accurately represent themselves.",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15.5,
                          height: 1.55,
                        ),
                      ),

                      const SizedBox(height: 28),
                      _buildHeading("9. VIOLENCE & DANGEROUS CONTENT"),
                      const Text(
                        "Not allowed:\n"
                        "❌ Threats of violence\n"
                        "❌ Terrorist content\n"
                        "❌ Criminal activities\n"
                        "❌ Weapons promotion\n"
                        "❌ Human trafficking\n"
                        "❌ Violent imagery",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15.5,
                          height: 1.55,
                        ),
                      ),

                      const SizedBox(height: 28),
                      _buildHeading("10. ILLEGAL ACTIVITIES"),
                      const Text(
                        "Strictly prohibited:\n"
                        "❌ Drugs\n"
                        "❌ Money laundering\n"
                        "❌ Illegal betting\n"
                        "❌ Gambling\n"
                        "❌ Counterfeit goods\n"
                        "❌ Illegal financial activities",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15.5,
                          height: 1.55,
                        ),
                      ),

                      const SizedBox(height: 28),
                      _buildHeading("11. PRIVACY VIOLATIONS"),
                      const Text(
                        "Do not share:\n"
                        "❌ Phone numbers\n"
                        "❌ Addresses\n"
                        "❌ Aadhaar information\n"
                        "❌ Bank details\n"
                        "❌ Personal documents\n"
                        "❌ Private photos without consent",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15.5,
                          height: 1.55,
                        ),
                      ),

                      const SizedBox(height: 28),
                      _buildHeading("12. PLATFORM MANIPULATION"),
                      const Text(
                        "Users may not:\n"
                        "❌ Use bots\n"
                        "❌ Create multiple fake accounts\n"
                        "❌ Manipulate engagement\n"
                        "❌ Abuse referral systems\n"
                        "❌ Exploit platform vulnerabilities",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15.5,
                          height: 1.55,
                        ),
                      ),

                      const SizedBox(height: 28),
                      _buildHeading("13. HOST RULES"),
                      const Text(
                        "Hosts must not:\n"
                        "❌ Share personal contact details\n"
                        "❌ Accept direct payments\n"
                        "❌ Solicit money outside Dude\n"
                        "❌ Redirect users to external platforms\n"
                        "❌ Engage in explicit sexual activity\n"
                        "❌ Mislead users regarding services",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15.5,
                          height: 1.55,
                        ),
                      ),

                      const SizedBox(height: 28),
                      _buildHeading("14. REPORTING"),
                      const Text(
                        "Users may report violations through:\n"
                        "• In-App Reporting\n"
                        "• dudeofficial@gmail.com",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15.5,
                          height: 1.55,
                        ),
                      ),

                      const SizedBox(height: 28),
                      _buildHeading("15. ENFORCEMENT"),
                      const Text(
                        "Dude may:\n"
                        "• Remove content\n"
                        "• Restrict features\n"
                        "• Suspend accounts\n"
                        "• Permanently ban users\n"
                        "• Report illegal activity to authorities\n\n"
                        "without prior notice when necessary.",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15.5,
                          height: 1.55,
                        ),
                      ),

                      const SizedBox(height: 40),
                      Center(
                        child: Text(
                          "DUDE TECH\n"
                          "Plot No. 1, Velan Nagar, Lakshmi Complex,\n"
                          "Sengunram Nagar, Madurai – 625004,\n"
                          "Tamil Nadu, India.\n\n"
                          "Email: dudeofficial@gmail.com",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                            height: 1.5,
                          ),
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
          color: Color(0xFFd2ea46),
          fontSize: 17.5,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
