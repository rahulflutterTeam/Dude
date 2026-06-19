import 'package:flutter/material.dart';
import 'package:dude/Reusable_Widgets/AppText_Theme/AppText_Theme.dart';
import 'package:dude/Reusable_Widgets/BondingNavigator.dart';

class DeleteReasonScreen extends StatefulWidget {
  const DeleteReasonScreen({super.key});

  @override
  State<DeleteReasonScreen> createState() => _DeleteReasonScreenState();
}

class _DeleteReasonScreenState extends State<DeleteReasonScreen> {
  String? selectedReason;

  final List<String> categories = [
    "Asked for money",
    "Not Interested",
    "Buddy not polite",
    "Abusive Language",
    "Unable to hear",
    "Other reason", // duplicate as per screenshot
  ];
  List<bool> selectedCategories = List.filled(6, false)
    ..[2] = true; // "stress" selected

  bool get canProceed => selectedReason != null;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF100a0a),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: GestureDetector(
          onTap: () => bondNavigator.backPage(context),
          child: Container(
            margin: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF35272d),
              borderRadius: BorderRadius.circular(40),
            ),
            child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
          ),
        ),
        title: const Text(
          "Delete Account",
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            const Text(
              "Please select at least one\nreason for deleting your\naccount",
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 40),

            Wrap(
              spacing: 6,
              runSpacing: 10,
              children: List.generate(categories.length, (index) {
                bool isSelected = selectedCategories[index];
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      selectedCategories[index] = !selectedCategories[index];
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      gradient: isSelected
                          ? const LinearGradient(
                              colors: [Color(0xFF8d51d2), Color(0xFFf8655f)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            )
                          : null,
                      color: isSelected
                          ? null
                          : const Color(0xFF35272d).withOpacity(0.6),
                      borderRadius: BorderRadius.circular(8),
                      border: !isSelected
                          ? Border.all(
                              color: Colors.white.withOpacity(0.1),
                              width: 1,
                            )
                          : null,
                    ),
                    child: Text(
                      categories[index],
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.grey[400],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                );
              }),
            ),

            const Spacer(),

            // Delete Account Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: GestureDetector(
                onTap: () {
                  showDeleteConfirmDialog(context);
                  // TODO: Proceed with deletion using selectedReason
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("Deleting account: $selectedReason"),
                    ),
                  );
                },
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    gradient: const LinearGradient(
                      colors: [Color(0xFF8d51d2), Color(0xFFf8655f)],
                    ),
                  ),
                  alignment: Alignment.center,
                  child: const Text(
                    "Delete account",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

Future<bool?> showDeleteConfirmDialog(BuildContext context) {
  return showDialog<bool>(
    context: context,
    barrierDismissible: true,
    barrierColor: Colors.black.withOpacity(0.8),
    builder: (_) => const DeleteConfirmDialog(),
  );
}

class DeleteConfirmDialog extends StatelessWidget {
  const DeleteConfirmDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
              colors: [
                Color(0xFF482135),

                // Deep purple-ish at top
                Color(0xFF140c0e), // Darker purple-black at bottom
              ],
            ),
            borderRadius: BorderRadius.circular(28),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Gradient Info Icon
              Container(
                width: 80,
                height: 80,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [Color(0xFF9D4EDD), Color(0xFFFF5A5F)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: const Center(
                  child: Text(
                    "i",
                    style: TextStyle(
                      color: Colors
                          .white, // Changed to white for better contrast on gradient
                      fontSize: 48,
                      fontWeight: FontWeight.w300,
                      height: 1,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Title
              AppText(
                "Are you sure want to delete\naccount ?",
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w600,
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 24),

              // Description
              AppText(
                "Information related to your account will be\nkept for 30 days\nand will be completely purged after no\nactivity for continuous 30 days.",
                textAlign: TextAlign.center,

                color: Colors.grey,
                fontSize: 16,
              ),

              const SizedBox(height: 40),

              // Buttons
              Row(
                children: [
                  // Cancel Button
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context, false),
                      child: Container(
                        height: 50,
                        decoration: BoxDecoration(
                          color: const Color(0xFF2A1F23),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: AppText(
                            "cancel",

                            color: Colors.white70,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 16),

                  // Confirm Button
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context, true),
                      child: Container(
                        height: 50,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          gradient: const LinearGradient(
                            colors: [Color(0xFF9D4EDD), Color(0xFFFF5A5F)],
                          ),
                        ),
                        child: Center(
                          child: AppText(
                            "confirm",

                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
