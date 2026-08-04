import 'dart:convert';

import 'package:dude/APIService/Remote/network/ApiEndPoints.dart';
import 'package:dude/DudeScreens/AuthService.dart';
import 'package:dude/DudeScreens/HomeScreen/Model/StaffDataModel.dart';
import 'package:dude/Dude_Utils/App_Theme/DudeTheme.dart';
import 'package:dude/Dude_Utils/CustomSnackBar/StatusMessage.dart';
import 'package:dude/StaffScreenScreens/StaffRegistrationScreen/ViewModel/StaffRegisterVM.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

/// Post-call feedback prompt.
Future<void> showStaffReviewDialog(BuildContext context, String staffId) async {
  final staff = _findStaff(context, staffId);
  final otherController = TextEditingController();
  var rating = 4;
  var isSubmitting = false;
  final selectedTags = <String>{};
  const tags = ['Good Person', 'Supportive', 'Clear voice', 'Friendly', 'Other'];

  await showDialog<void>(
    context: context,
    useRootNavigator: true,
    barrierDismissible: true,
    barrierColor: Colors.black.withValues(alpha: 0.82),
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (context, setState) {
          return Dialog(
            insetPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 28,
            ),
            backgroundColor: Colors.transparent,
            child: Container(
              width: double.infinity,
              constraints: const BoxConstraints(maxWidth: 430),
              padding: const EdgeInsets.fromLTRB(22, 24, 22, 20),
              decoration: BoxDecoration(
                gradient: DudeTheme.dialogGradient,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: DudeTheme.accent.withValues(alpha: 0.34),
                ),
                boxShadow: [
                  ...DudeTheme.softShadow,
                  ...DudeTheme.accentGlowShadow(blur: 34, spread: -12),
                ],
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Call Feedback',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: DudeTheme.textPrimary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(height: 22),
                    _StaffAvatar(staff: staff),
                    const SizedBox(height: 18),
                    Text(
                      _staffName(staff),
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: DudeTheme.textPrimary,
                        fontWeight: FontWeight.w800,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 28),
                    Text(
                      'Tell us about your call',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: DudeTheme.textMuted,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (index) {
                        final active = index < rating;
                        return IconButton(
                          visualDensity: VisualDensity.compact,
                          iconSize: 38,
                          color: active
                              ? DudeTheme.accent
                              : DudeTheme.textSubtle.withValues(alpha: 0.45),
                          icon: Icon(
                            active
                                ? Icons.star_rounded
                                : Icons.star_outline_rounded,
                          ),
                          onPressed: isSubmitting
                              ? null
                              : () => setState(() => rating = index + 1),
                        );
                      }),
                    ),
                    const SizedBox(height: 14),
                    if (selectedTags.contains('Other'))
                      _OtherFeedbackField(
                        controller: otherController,
                        enabled: !isSubmitting,
                        onCancel: () => setState(() {
                          selectedTags.remove('Other');
                          otherController.clear();
                        }),
                      )
                    else
                      Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 9,
                        runSpacing: 10,
                        children: tags.map((tag) {
                          final selected = selectedTags.contains(tag);
                          return ChoiceChip(
                            selected: selected,
                            showCheckmark: false,
                            label: Text(tag),
                            onSelected: isSubmitting
                                ? null
                                : (_) => setState(() {
                                    if (tag == 'Other') {
                                      selectedTags.add(tag);
                                    } else if (selected) {
                                      selectedTags.remove(tag);
                                    } else {
                                      selectedTags.add(tag);
                                    }
                                  }),
                            selectedColor:
                                DudeTheme.accent.withValues(alpha: 0.22),
                            backgroundColor: DudeTheme.surfaceRaised,
                            side: BorderSide(
                              color: selected
                                  ? DudeTheme.accent
                                  : DudeTheme.border.withValues(alpha: 0.7),
                            ),
                            labelStyle: TextStyle(
                              color: selected
                                  ? DudeTheme.accentBright
                                  : DudeTheme.textMuted,
                              fontWeight: FontWeight.w700,
                            ),
                          );
                        }).toList(),
                      ),
                    const SizedBox(height: 28),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: isSubmitting
                            ? null
                            : () async {
                                setState(() => isSubmitting = true);
                                final success = await _submitFeedback(
                                  staffId: staffId,
                                  rating: rating,
                                  tags: selectedTags,
                                  otherFeedback: otherController.text.trim(),
                                );
                                if (!dialogContext.mounted) return;
                                Navigator.of(dialogContext).pop();
                                if (success) {
                                  Utils.snackBar('Thanks for your feedback!');
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: DudeTheme.accent,
                          foregroundColor: DudeTheme.textOnAccent,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: isSubmitting
                            ? const SizedBox.square(
                                dimension: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                'Submit Feedback',
                                style: TextStyle(fontWeight: FontWeight.w800),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    },
  );
  otherController.dispose();
}

String _staffName(StaffDataProfile? staff) {
  final name = staff?.name.trim() ?? '';
  return name.isEmpty ? 'your staff' : name;
}

StaffDataProfile? _findStaff(BuildContext context, String staffId) {
  try {
    for (final item in context.read<StaffViewModel>().allStaffList) {
      if (item.id == staffId || item.memberID == staffId) return item;
    }
  } catch (_) {
    // A missing provider should not prevent the post-call prompt.
  }
  return null;
}

Future<bool> _submitFeedback({
  required String staffId,
  required int rating,
  required Set<String> tags,
  required String otherFeedback,
}) async {
  try {
    final token = await AuthService.getToken();
    if (token == null || token.isEmpty) {
      Utils.snackBarErrorMessage('You must be logged in.');
      return false;
    }

    final response = await http.post(
      Uri.parse('${ApiEndPoints().baseUrl}auth/user/reportStaff'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
},
      body: jsonEncode({
        'staffId': staffId,
        'rating': rating,
        if (tags.isNotEmpty || otherFeedback.isNotEmpty)
          'comment': [
            ...tags.where((tag) => tag != 'Other'),
            if (otherFeedback.isNotEmpty) otherFeedback,
          ].join(', '),
      }),
    );

    final payload = response.body.isNotEmpty
        ? jsonDecode(response.body) as Map<String, dynamic>
        : <String, dynamic>{};
    if ((response.statusCode == 200 || response.statusCode == 201) &&
        payload['status'] == true) {
      return true;
    }
    Utils.snackBarErrorMessage(
      payload['message']?.toString() ?? 'Failed to submit feedback',
    );
  } catch (e) {
    Utils.snackBarErrorMessage('Failed to submit feedback: $e');
  }
  return false;
}

class _OtherFeedbackField extends StatelessWidget {
  const _OtherFeedbackField({
    required this.controller,
    required this.enabled,
    required this.onCancel,
  });

  final TextEditingController controller;
  final bool enabled;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 150,
      padding: const EdgeInsets.fromLTRB(16, 8, 10, 10),
      decoration: BoxDecoration(
        color: DudeTheme.surfaceRaised,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: DudeTheme.accent.withValues(alpha: 0.5)),
      ),
      child: Stack(
        children: [
          TextField(
            controller: controller,
            enabled: enabled,
            maxLines: 5,
            style: const TextStyle(color: DudeTheme.textPrimary),
            decoration: const InputDecoration(
              hintText: 'Please tell us what happened...',
              hintStyle: TextStyle(color: DudeTheme.textSubtle),
              filled: false,
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              contentPadding: EdgeInsets.zero,
            ),
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: TextButton.icon(
              onPressed: enabled ? onCancel : null,
              icon: const Icon(Icons.close_rounded, size: 18),
              label: const Text('Cancel'),
              style: TextButton.styleFrom(
                foregroundColor: DudeTheme.accent,
                backgroundColor: DudeTheme.surfaceElevated,
                shape: const StadiumBorder(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StaffAvatar extends StatelessWidget {
  const _StaffAvatar({required this.staff});

  final StaffDataProfile? staff;

  @override
  Widget build(BuildContext context) {
    final imageUrl = staff?.image?.trim() ?? '';
    return Container(
      width: 132,
      height: 132,
      padding: const EdgeInsets.all(3),
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: DudeTheme.premiumAccentGradient,
      ),
      child: ClipOval(
        child: imageUrl.isNotEmpty
            ? Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _fallback(),
              )
            : _fallback(),
      ),
    );
  }

  Widget _fallback() => Container(
    color: DudeTheme.surfaceRaised,
    alignment: Alignment.center,
    child: const Icon(
      Icons.person_rounded,
      size: 62,
      color: DudeTheme.textSubtle,
    ),
  );
}
