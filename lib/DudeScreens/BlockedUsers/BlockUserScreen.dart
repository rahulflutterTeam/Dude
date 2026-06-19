import 'package:dude/Reusable_Widgets/AppText_Theme/AppText_Theme.dart';
import 'package:dude/Reusable_Widgets/BondingNavigator.dart';
import 'package:flutter/material.dart';

class BlockedUsersScreen extends StatefulWidget {
  const BlockedUsersScreen({super.key});

  @override
  State<BlockedUsersScreen> createState() => _BlockedUsersScreenState();
}

class _BlockedUsersScreenState extends State<BlockedUsersScreen> {
  // Sample blocked users data
  final List<Map<String, dynamic>> blockedUsers = List.generate(
    5,
    (index) => {
      'name': 'Pooja_25',
      'blockedDate': '21/07/2025',
      'image': 'assets/Images/pooja.png', // Replace with actual image path
    },
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        color: const Color(0xFF100a0a),
        child: SafeArea(
          child: Column(
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
                      "Blocked users",
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Blocked Users List
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  itemCount: blockedUsers.length,
                  itemBuilder: (context, index) {
                    final user = blockedUsers[index];

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 30.0),
                      child: Row(
                        children: [
                          // Profile Picture
                          CircleAvatar(
                            radius: 28,
                            backgroundImage: AssetImage(user['image']),
                          ),
                          const SizedBox(width: 16),

                          // User Info
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                AppText(
                                  user['name'],

                                  color: Colors.white,
                                  fontSize: 17,
                                  fontWeight: FontWeight.w600,
                                ),
                                const SizedBox(height: 4),
                                AppText(
                                  "Blocked: ${user['blockedDate']}",

                                  color: Color(0XFFc7c7cc),
                                  fontSize: 15,
                                ),
                              ],
                            ),
                          ),

                          // Unblock Button
                          GestureDetector(
                            onTap: () {
                              // Handle unblock action
                              setState(() {});
                              // You can also show a confirmation dialog
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF29090f),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: AppText(
                                "Unblock",

                                color: Color(0xFFf4063a),
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),

              // Empty state (optional - show when no blocked users)
              // if (blockedUsers.isEmpty)
              //   const Center(
              //     child: Text(
              //       "No blocked users",
              //       style: TextStyle(color: Colors.grey, fontSize: 16),
              //     ),
              //   ),
            ],
          ),
        ),
      ),
    );
  }
}
