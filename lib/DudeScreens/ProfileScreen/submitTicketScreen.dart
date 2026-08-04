import 'dart:io';

import 'package:dude/APIService/support_ticket_service.dart';
import 'package:dude/DudeScreens/ProfileScreen/ProfileScreen.dart';
import 'package:dude/Dude_Utils/App_Theme/DudeTheme.dart';
import 'package:dude/Dude_Utils/CustomSnackBar/StatusMessage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class SubmitTicketScreen extends StatefulWidget {
  @override
  State<SubmitTicketScreen> createState() => _SubmitTicketScreenState();
}

class _SubmitTicketScreenState extends State<SubmitTicketScreen> {
  final TextEditingController _descController = TextEditingController();
  List<File> _images = [];
  bool loading = false;
  String? error;
  String? success;
  late final SupportTicketService _service = SupportTicketService();

  Future<void> _pickImages() async {
    final picker = ImagePicker();
    final picked = await picker.pickMultiImage(imageQuality: 80);
    setState(() {
      _images = picked.take(3).map((x) => File(x.path)).toList();
    });
  }

  Future<void> _submitTicket() async {
    setState(() {
      loading = true;
      error = null;
      success = null;
    });
    try {
      final desc = _descController.text.trim();
      if (desc.length < 15 || desc.length > 250) {
        setState(() {
          error = 'Description must be 15-250 characters.';
          loading = false;
        });
        return;
      }
      await _service.createTicket(
        description: desc,
        images: _images,
      );
      setState(() {
        success = 'Ticket submitted successfully!';
        loading = false;
        _descController.clear();
        _images.clear();
      });
      Utils.snackBar('Ticket submitted successfully!');
      Future.delayed(const Duration(milliseconds: 800), () {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => ProfileScreen(backPage: false)),
          (route) => false,
        );
      });
    } catch (e) {
      setState(() {
        error = e.toString();
        loading = false;
      });
    }
  }

  @override
  void dispose() {
    _descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DudeTheme.background,
      appBar: AppBar(
        leading: const BackButton(color: DudeTheme.textMid),
        title: const Text(
          'Submit Ticket',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: DudeTheme.textPrimary,
          ),
        ),
        backgroundColor: DudeTheme.background,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (error != null) ...[
              Text(error!, style: const TextStyle(color: DudeTheme.danger)),
              const SizedBox(height: 8),
            ],
            if (success != null) ...[
              Text(success!, style: const TextStyle(color: DudeTheme.success)),
              const SizedBox(height: 8),
            ],
            _TicketCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text(
                        'Describe your issue',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          color: DudeTheme.textPrimary,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: DudeTheme.accentDim,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: DudeTheme.accent.withValues(alpha: 0.35),
                          ),
                        ),
                        child: const Text(
                          'Required',
                          style: TextStyle(
                            color: DudeTheme.accent,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Please provide detailed information (minimum 15 characters)',
                    style: TextStyle(color: DudeTheme.textSubtle),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _descController,
                    maxLines: 5,
                    maxLength: 250,
                    style: const TextStyle(color: DudeTheme.textPrimary),
                    cursorColor: DudeTheme.accent,
                    decoration: InputDecoration(
                      hintText: 'Describe your issue...',
                      hintStyle: const TextStyle(color: DudeTheme.textSubtle),
                      filled: true,
                      fillColor: DudeTheme.surfaceRaised,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: DudeTheme.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: DudeTheme.border.withValues(alpha: 0.6),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: DudeTheme.accent,
                          width: 1.4,
                        ),
                      ),
                      counterStyle: const TextStyle(
                        color: DudeTheme.textSubtle,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _TicketCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text(
                        'Attach Images',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          color: DudeTheme.textPrimary,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: DudeTheme.surfaceElevated,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: DudeTheme.borderSubtle),
                        ),
                        child: const Text(
                          'Optional',
                          style: TextStyle(
                            color: DudeTheme.textMid,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Add up to 3 images to help us understand better',
                    style: TextStyle(color: DudeTheme.textSubtle),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: DudeTheme.surfaceRaised,
                      foregroundColor: DudeTheme.textPrimary,
                      side: BorderSide(
                        color: DudeTheme.border.withValues(alpha: 0.7),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                      minimumSize: const Size(double.infinity, 48),
                    ),
                    icon: const Icon(
                      Icons.attach_file_rounded,
                      color: DudeTheme.accent,
                    ),
                    label: const Text('ATTACH IMAGES'),
                    onPressed: loading ? null : _pickImages,
                  ),
                  if (_images.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Wrap(
                        spacing: 8,
                        children: _images
                            .map(
                              (img) => Stack(
                                alignment: Alignment.topRight,
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: Image.file(
                                      img,
                                      width: 80,
                                      height: 80,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _images.remove(img);
                                      });
                                    },
                                    child: const CircleAvatar(
                                      radius: 12,
                                      backgroundColor: DudeTheme.danger,
                                      child: Icon(
                                        Icons.close,
                                        size: 16,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            )
                            .toList(),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: loading ? null : DudeTheme.premiumAccentGradient,
                  color: loading ? DudeTheme.surfaceElevated : null,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: loading ? null : _submitTicket,
                  child: loading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Submit Ticket',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                            color: DudeTheme.textOnAccent,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TicketCard extends StatelessWidget {
  const _TicketCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: DudeTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: DudeTheme.border.withValues(alpha: 0.5)),
      ),
      child: child,
    );
  }
}
