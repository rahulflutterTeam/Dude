import 'package:dude/Reusable_Widgets/AppText_Theme/AppText_Theme.dart';
import 'package:dude/Reusable_Widgets/BondingNavigator.dart';
import 'package:flutter/material.dart';

class ReportDetailsScreen extends StatelessWidget {
  const ReportDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [
              Color(0xFF140810),
              Color(0xFF3A152A),
              Color(0xFF140810),
              Color(0xFF140810),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Bar
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        bondNavigator.backPage(context);
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF35272d),
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
                      "report details",
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              // User Info Row
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  children: [
                    // Profile Picture
                    const CircleAvatar(
                      radius: 28,
                      backgroundImage: AssetImage(
                        "assets/Images/men.png",
                      ), // Replace with actual image
                    ),
                    const SizedBox(width: 16),
                    // Username
                    const Text(
                      "unus_007",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    // Report Date
                    Text(
                      "21 December 2025",
                      style: TextStyle(color: Colors.grey[400], fontSize: 14),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              // Report Title
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: AppText(
                  "report",
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),

              const SizedBox(height: 16),

              // Report Description (long text)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: AppText(
                  "sfcsfafsafscsfsaffsdfscdfacddaDAcdadaDAmdakdma\nDKAMDAKldmakODMDOIMDOIJAKDMAoipdkmaFdIO\nAmdpoa,DMApod,aDPOa,clpoaKSDPodsk",

                  color: Colors.white,
                  fontSize: 15,

                  // Line spacing
                ),
              ),

              const SizedBox(height: 10),

              // Report Time
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(
                  "7:30am",
                  style: TextStyle(color: Colors.grey[500], fontSize: 14),
                ),
              ),

              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}
