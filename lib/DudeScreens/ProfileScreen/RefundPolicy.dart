import 'package:dude/Reusable_Widgets/AppText_Theme/AppText_Theme.dart';
import 'package:dude/Reusable_Widgets/BondingNavigator.dart';
import 'package:dude/Dude_Utils/App_Theme/DudeTheme.dart';
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
                      "Refund Policy",
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
                        "REFUND POLICY",
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
                        "At Dude, we strive to provide a seamless user experience. This Refund Policy explains how refunds are handled for purchases made on the Platform.",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15.5,
                          height: 1.55,
                        ),
                      ),

                      const SizedBox(height: 28),
                      _buildHeading("1. VIRTUAL COINS"),
                      const Text(
                        "Coins purchased on Dude are virtual digital items and have no cash value.\n\n"
                        "Once Coins are successfully credited to your account, purchases are generally non-refundable.\n\n"
                        "Coins cannot be exchanged for cash, transferred to another user, or redeemed outside the Platform.",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15.5,
                          height: 1.55,
                        ),
                      ),

                      const SizedBox(height: 28),
                      _buildHeading("2. ELIGIBLE REFUND CASES"),
                      const Text(
                        "Refund requests may be considered in the following circumstances:\n"
                        "• Duplicate payment due to a technical error.\n"
                        "• Payment completed but Coins were not credited.\n"
                        "• Unauthorized transaction verified by Dude.\n"
                        "• Service interruption caused solely by a platform-side technical issue.",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15.5,
                          height: 1.55,
                        ),
                      ),

                      const SizedBox(height: 28),
                      _buildHeading("3. NON-REFUNDABLE CASES"),
                      const Text(
                        "Refunds will not be provided for:\n"
                        "• Used Coins.\n"
                        "• Completed audio calls, video calls, or premium services.\n"
                        "• User dissatisfaction with another user's behavior.\n"
                        "• Accidental purchases by the user.\n"
                        "• Temporary internet or device-related issues.\n"
                        "• Account suspension due to policy violations.",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15.5,
                          height: 1.55,
                        ),
                      ),

                      const SizedBox(height: 28),
                      _buildHeading("4. REFUND REQUEST PROCESS"),
                      const Text(
                        "To request a refund, contact:\n"
                        "Email: dudeofficial@gmail.com\n\n"
                        "Provide:\n"
                        "• Registered mobile number\n"
                        "• Transaction ID\n"
                        "• Payment screenshot (if available)\n"
                        "• Description of the issue",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15.5,
                          height: 1.55,
                        ),
                      ),

                      const SizedBox(height: 28),
                      _buildHeading("5. REFUND PROCESSING"),
                      const Text(
                        "Approved refunds may take 5–10 business days depending on the payment provider and banking institution.",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15.5,
                          height: 1.55,
                        ),
                      ),

                      const SizedBox(height: 28),
                      _buildHeading("6. POLICY CHANGES"),
                      const Text(
                        "Dude reserves the right to modify this Refund Policy at any time. Updated versions will be published on the Platform.",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15.5,
                          height: 1.55,
                        ),
                      ),

                      const SizedBox(height: 40),
                      _buildHeading("CONTACT US"),
                      const Text(
                        "DUDE TECH\n"
                        "Registered Office\n"
                        "Plot No. 1, Velan Nagar, Lakshmi Complex,\n"
                        "Sengunram Nagar, Madurai – 625004,\n"
                        "Tamil Nadu, India\n\n"
                        "Customer Support\n"
                        "📧 Email: dudeofficial@gmail.com\n\n"
                        "Grievance Officer\n"
                        "Name: Hari Haran\n"
                        "📧 Email: hariharanpandiyarajan8@gmail.com\n\n"
                        "Nodal Officer\n"
                        "Name: Vinith J\n"
                        "📧 Email: vinithrichardsjl@gmail.com\n\n"
                        "Business Hours\n"
                        "Monday – Saturday\n"
                        "10:00 AM – 6:00 PM (IST)\n\n"
                        "Response Time\n"
                        "General Support: Within 24–48 hours\n"
                        "Payment Issues: Within 3–5 business days\n"
                        "Grievance Complaints: Within 15 days as per applicable regulations",
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
