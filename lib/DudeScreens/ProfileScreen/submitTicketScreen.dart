// submit_ticket_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dude/APIService/support_ticket_service.dart';
import 'package:dude/Dude_Utils/CustomSnackBar/StatusMessage.dart';
import 'ProfileScreen.dart';

class SubmitTicketScreen extends StatefulWidget {
  @override
  State<SubmitTicketScreen> createState() => _SubmitTicketScreenState();
}

class _SubmitTicketScreenState extends State<SubmitTicketScreen> {
  final Color primary = const Color(0xFF4FB9D1); // App main color
  final TextEditingController _descController = TextEditingController();
  List<File> _images = [];
  bool loading = false;
  String? error;
  String? success;
  late SupportTicketService _service = SupportTicketService();

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
      final result = await _service.createTicket(
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
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF080612),
      appBar: AppBar(
        leading: BackButton(color: Colors.white54),
        title: Text(
          'Submit Ticket',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF100E1E),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            if (error != null) ...[
              Text(error!, style: TextStyle(color: Colors.red)),
              SizedBox(height: 8),
            ],
            if (success != null) ...[
              Text(success!, style: TextStyle(color: Colors.green)),
              SizedBox(height: 8),
            ],
            Card(
              color: const Color(0xFF100E1E),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Describe your issue',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.white,
                          ),
                        ),
                        Spacer(),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: primary.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'Required',
                            style: TextStyle(
                              color: primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Please provide detailed information (minimum 15 characters)',
                      style: TextStyle(color: Colors.grey),
                    ),
                    SizedBox(height: 8),
                    TextField(
                      controller: _descController,
                      maxLines: 5,
                      maxLength: 250,
                      style: TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Describe your issue...',
                        hintStyle: TextStyle(color: Colors.white54),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        counterText: '250',
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 16),
            Card(
              color: const Color(0xFF100E1E),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Attach Images',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.white,
                          ),
                        ),
                        Spacer(),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.blue[100],
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'Optional',
                            style: TextStyle(
                              color: Colors.blue,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Add up to 3 images to help us understand better',
                      style: TextStyle(color: Colors.grey),
                    ),
                    SizedBox(height: 8),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1E1A30),
                        foregroundColor: Colors.white,
                        side: BorderSide(color: Colors.grey[700]!),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                        minimumSize: Size(double.infinity, 48),
                      ),
                      icon: Icon(Icons.attach_file),
                      label: Text('ATTACH IMAGES'),
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
                                    Image.file(
                                      img,
                                      width: 80,
                                      height: 80,
                                      fit: BoxFit.cover,
                                    ),
                                    GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          _images.remove(img);
                                        });
                                      },
                                      child: CircleAvatar(
                                        radius: 12,
                                        backgroundColor: Colors.red,
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
            ),
            SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFcee640),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: loading
                    ? CircularProgressIndicator(color: Colors.white)
                    : Text(
                        'Submit Ticket',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: Colors.black,
                        ),
                      ),
                onPressed: loading ? null : _submitTicket,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
