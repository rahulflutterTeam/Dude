import 'package:dude/DudeScreens/LoginScreens/LoginScreen.dart';
import 'package:dude/Reusable_Widgets/BondingNavigator.dart';
import 'package:dude/StaffScreenScreens/StaffRegistrationScreen/staffregisterNew.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class AccountSelectScreen extends StatefulWidget {
  const AccountSelectScreen({super.key});

  @override
  State<AccountSelectScreen> createState() => _AccountSelectScreenState();
}

class _AccountSelectScreenState extends State<AccountSelectScreen> {
  int selectedAccount = 0; // 1 = Male (Him), 2 = Female (Her)

  void _openDiscoverPeopleFlow() {
    setState(() => selectedAccount = 1);
    bondNavigator.newPage(context, page: const LoginScreen());
  }

  void _openBeActiveFlow() {
    setState(() => selectedAccount = 2);
    _showBeActiveRoleDialog();
  }

  Future<void> _showBeActiveRoleDialog() async {
    await showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.68),
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24),
          child: Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: const Color(0xFF1C1426),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: const Color(0xFFdcee72).withValues(alpha: 0.28),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.35),
                  blurRadius: 28,
                  offset: const Offset(0, 18),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Align(
                  alignment: Alignment.centerRight,
                  child: IconButton(
                    tooltip: "Close",
                    visualDensity: VisualDensity.compact,
                    onPressed: () => Navigator.of(dialogContext).pop(),
                    icon: const Icon(
                      Icons.close_rounded,
                      color: Colors.white70,
                    ),
                  ),
                ),
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF2A1F38),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFdcee72).withValues(alpha: 0.25),
                        blurRadius: 22,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.account_circle_rounded,
                    color: Color(0xFFdcee72),
                    size: 40,
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  "Continue As",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Choose the account type you want to open.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.68),
                    fontSize: 14,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 22),
                _buildRoleOption(
                  icon: Icons.person_search_rounded,
                  title: "User",
                  subtitle: "Discover people and start connecting",
                  onTap: () {
                    Navigator.of(dialogContext).pop();
                    bondNavigator.newPage(context, page: const LoginScreen());
                  },
                ),
                const SizedBox(height: 12),
                _buildRoleOption(
                  icon: Icons.verified_user_rounded,
                  title: "Host",
                  subtitle: "Register as Host and be active",
                  onTap: () {
                    Navigator.of(dialogContext).pop();
                    bondNavigator.newPage(
                      context,
                      page: const StaffRegisterNew(),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildRoleOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Ink(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: const Color(0xFF2A1F38),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  color: Color(0xFFdcee72),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: Colors.black, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.62),
                        fontSize: 12.5,
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                color: Colors.white54,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF1F0B2E),
              Color(0xFF1A0A2A),
              Color(0xFF12071F),
              Color(0xFF0F061A),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 30),

              // Logo
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: SvgPicture.asset("assets/Images/dude.svg", height: 54),
                ),
              ),

              const SizedBox(height: 40),

              Text(
                "Select Your Gender",
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.65),
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 40),

              // Male Card (Him)
              _buildAvatarCard(
                imagePath: "assets/Images/men.png",
                label: "Male",
                isSelected: selectedAccount == 1,
                onTap: _openDiscoverPeopleFlow,
                glowColor: const Color(0xFFdcee72),
              ),

              const SizedBox(height: 40),

              // OR Divider
              Row(
                children: [
                  Expanded(
                    child: Divider(
                      color: Colors.white.withValues(alpha: 0.2),
                      thickness: 1,
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      "OR",
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Divider(
                      color: Colors.white.withValues(alpha: 0.2),
                      thickness: 1,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 40),

              // Female Card (Her)
              _buildAvatarCard(
                imagePath: "assets/Images/women.png",
                label: "Female",
                isSelected: selectedAccount == 2,
                onTap: _openBeActiveFlow,
                glowColor: const Color(0xFFdcee72),
              ),

              const Spacer(),
              //
              // // Continue Button
              // Padding(
              //   padding: const EdgeInsets.symmetric(
              //     horizontal: 24,
              //     vertical: 40,
              //   ),
              //   child: GestureDetector(
              //     onTap: selectedAccount == 0
              //         ? null
              //         : () {
              //             if (selectedAccount == 1) {
              //               bondNavigator.newPage(
              //                 context,
              //                 page: const LoginScreen(),
              //               );
              //             } else if (selectedAccount == 2) {
              //               _showBeActiveRoleDialog();
              //             }
              //           },
              //     child: AnimatedContainer(
              //       duration: const Duration(milliseconds: 300),
              //       height: 58,
              //       width: double.infinity,
              //       decoration: BoxDecoration(
              //         borderRadius: BorderRadius.circular(16),
              //         gradient: selectedAccount == 0
              //             ? const LinearGradient(
              //                 colors: [Color(0xFF444444), Color(0xFF666666)],
              //               )
              //             : const LinearGradient(
              //                 colors: [Color(0xFFaecc01), Color(0xFFaecc01)],
              //               ),
              //         boxShadow: selectedAccount != 0
              //             ? [
              //                 BoxShadow(
              //                   color: const Color(
              //                     0xFFaecc01,
              //                   ).withValues(alpha: 0.5),
              //                   blurRadius: 20,
              //                   offset: const Offset(0, 8),
              //                 ),
              //               ]
              //             : [],
              //       ),
              //       alignment: Alignment.center,
              //       child: Text(
              //         "Continue →",
              //         style: TextStyle(
              //           color: selectedAccount == 0
              //               ? Colors.black54
              //               : Colors.black,
              //           fontSize: 18,
              //           fontWeight: FontWeight.w700,
              //         ),
              //       ),
              //     ),
              //   ),
              // ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatarCard({
    required String imagePath,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    required Color glowColor,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        width: 200,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xFF1C1426),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? glowColor : Colors.white54,
            width: isSelected ? 3 : 0.5,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: glowColor.withValues(alpha: 0.45),
                    blurRadius: 30,
                    spreadRadius: 4,
                  ),
                ]
              : [],
        ),
        child: Column(
          children: [
            // Avatar with Glow
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: glowColor.withValues(alpha: 0.6),
                          blurRadius: 25,
                        ),
                      ]
                    : [],
              ),
              child: ClipOval(
                child: Image.asset(
                  imagePath,
                  height: 80,
                  width: 80,
                  fit: BoxFit.cover,
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Label Button
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
              decoration: BoxDecoration(
                color: isSelected ? glowColor : const Color(0xFF2A1F38),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.black : Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
