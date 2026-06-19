import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:dude/Dude_Utils/CustomSnackBar/StatusMessage.dart';
import 'package:http/http.dart' as http;
import 'package:dude/APIService/Remote/network/ApiEndPoints.dart';
import 'package:dude/DudeScreens/AuthService.dart';

/// Reusable review dialog. Call `await showStaffReviewDialog(context, staffId);`
Future<void> showStaffReviewDialog(BuildContext context, String staffId) async {
  int rating = 5;
  final TextEditingController _commentController = TextEditingController();

  // Primary app color requested by the user
  const Color primaryColor = Color(0xFFbcd71c);
  const Color dialogBg = Color(
    0xFF1c122d,
  ); // matches app dark dialog background
  const Color inputBg = Color(0xFF12151c);

  await showDialog(
    context: context,
    useRootNavigator: true,
    barrierDismissible: true,
    builder: (ctx) {
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            backgroundColor: dialogBg,
            title: const Text(
              'Rate your staff',
              style: TextStyle(color: Colors.white),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) {
                    return IconButton(
                      icon: Icon(
                        index < rating ? Icons.star : Icons.star_border,
                        color: index < rating ? primaryColor : Colors.grey,
                      ),
                      onPressed: () {
                        setState(() {
                          rating = index + 1;
                        });
                      },
                    );
                  }),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _commentController,
                  maxLines: 3,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Write a short comment (optional)',
                    hintStyle: TextStyle(color: Colors.white.withOpacity(0.6)),
                    filled: true,
                    fillColor: inputBg,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                  ),
                ),
              ],
            ),
            actionsPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 8,
            ),
            actions: [
              TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white70,
                  textStyle: const TextStyle(fontSize: 15),
                ),
                onPressed: () {
                  Navigator.of(ctx).pop();
                },
                child: const Text('Skip'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 10,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: () async {
                  final comment = _commentController.text.trim();

                  Navigator.of(ctx).pop();

                  // Submit review to real backend endpoint /auth/user/reportStaff
                  try {
                    final url = Uri.parse(
                      '${ApiEndPoints().baseUrl}auth/user/reportStaff',
                    );
                    final token = await AuthService.getToken();

                    if (token == null || token.isEmpty) {
                      Utils.snackBarErrorMessage(
                        'You must be logged in to submit a review.',
                      );
                      return;
                    }

                    final body = {
                      'staffId': staffId,
                      'rating': rating,
                      if (comment.isNotEmpty) 'comment': comment,
                    };

                    final response = await http.post(
                      url,
                      headers: {
                        'Content-Type': 'application/json',
                        'Authorization': 'Bearer $token',
                      },
                      body: jsonEncode(body),
                    );

                    if (response.statusCode == 200 ||
                        response.statusCode == 201) {
                      final json = jsonDecode(response.body);
                      print("json ${json}");
                      if (json['status'] == true) {
                        Utils.snackBar('Thanks for your feedback!');
                      } else {
                        Utils.snackBarErrorMessage(
                          json['message'] ?? 'Failed to submit review',
                        );
                      }
                    } else {
                      Utils.snackBarErrorMessage(
                        'Failed to submit review: ${response.statusCode}',
                      );
                    }
                  } catch (e) {
                    Utils.snackBarErrorMessage('Failed to submit review: $e');
                  }
                },
                child: const Text('Submit'),
              ),
            ],
          );
        },
      );
    },
  );
}
