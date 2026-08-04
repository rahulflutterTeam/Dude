import 'dart:convert';
import 'dart:io';

import 'package:dude/APIService/Remote/network/ApiEndPoints.dart';
import 'package:dude/DudeScreens/AuthService.dart';
import 'package:dude/DudeScreens/HomeScreen/Model/UserDataModel.dart';
import 'package:dude/DudeScreens/HomeScreen/ViewModel/UserVM.dart';
import 'package:dude/Dude_Utils/App_Theme/DudeTheme.dart';
import 'package:dude/Dude_Utils/CustomSnackBar/StatusMessage.dart';
import 'package:dude/Reusable_Widgets/BondingNavigator.dart';
import 'package:dude/Reusable_Widgets/Premium_UI/premium_ambient_background.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart' as http_parser;
import 'package:image_picker/image_picker.dart';
import 'package:mime/mime.dart';
import 'package:provider/provider.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen>
    with SingleTickerProviderStateMixin {
  late TextEditingController _nameController;
  late TextEditingController _bioController;

  File? _selectedImage;
  String? _currentImageUrl;
  String? _selectedLanguage;
  bool _isUpdating = false;

  late final AnimationController _fadeCtrl;
  late final Animation<double> _fadeAnim;

  final List<String> languages = const [
    "English",
    "Hindi",
    "Tamil",
    "Telugu",
    "Kannada",
    "Malayalam",
    "Marathi",
    "Bengali",
    "Gujarati",
    "Punjabi",
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _bioController = TextEditingController();

    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _fadeCtrl.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userVM = context.read<UserViewModel>();
      userVM.fetchUserDetails();
      final user = userVM.currentUser;
      if (user != null) {
        _nameController.text = user.name ?? '';
        _bioController.text = user.bio ?? '';
        _currentImageUrl = user.image;
        _selectedLanguage = user.language ?? "English";
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    _fadeCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() => _selectedImage = File(pickedFile.path));
    }
  }

  Future<String?> _uploadImage(File imageFile) async {
    try {
      final token = await AuthService.getToken() ?? "";
      if (token.isEmpty) {
        Utils.snackBarErrorMessage("Authentication token not found");
        return null;
      }
      final uri = Uri.parse('${ApiEndPoints().baseUrl}auth/user/editProfile');
      final request = http.MultipartRequest('POST', uri);
      request.headers['Authorization'] = 'Bearer $token';
      final mimeType = lookupMimeType(imageFile.path) ?? 'image/jpeg';
      final extension = mimeType.split('/').last;
      request.files.add(
        await http.MultipartFile.fromPath(
          'image',
          imageFile.path,
          filename: 'profile.$extension',
          contentType: http_parser.MediaType('image', extension),
        ),
      );
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        if (json['status'] == true && json['data'] != null) {
          final newImageUrl = json['data']['image'] as String?;
          if (newImageUrl != null && newImageUrl.isNotEmpty) return newImageUrl;
        }
      }
      Utils.snackBarErrorMessage("Image upload failed: ${response.statusCode}");
      return null;
    } catch (e) {
      Utils.snackBarErrorMessage("Image upload error: $e");
      return null;
    }
  }

  Future<void> _updateProfile() async {
    final userVM = context.read<UserViewModel>();
    final user = userVM.currentUser;
    if (user == null) {
      Utils.snackBarErrorMessage("No user data found");
      return;
    }
    setState(() => _isUpdating = true);
    String? newImageUrl = _currentImageUrl;
    if (_selectedImage != null) {
      newImageUrl = await _uploadImage(_selectedImage!);
      if (newImageUrl == null) {
        setState(() => _isUpdating = false);
        return;
      }
    }
    final success = await userVM.updateUserProfile(
      name: _nameController.text.trim(),
      bio: _bioController.text.trim(),
      language: _selectedLanguage,
      image: newImageUrl,
    );
    setState(() => _isUpdating = false);
    if (success) {
      Utils.snackBar("Profile updated successfully");
      bondNavigator.backPage(context);
    } else {
      Utils.snackBarErrorMessage("Failed to update profile");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<UserViewModel>(
      builder: (context, userVM, child) {
        final user = userVM.currentUser;

        if (userVM.isLoading || user == null) {
          return const Scaffold(
            backgroundColor: DudeTheme.background,
            body: Center(
              child: CircularProgressIndicator(
                color: DudeTheme.accent,
                strokeWidth: 2,
              ),
            ),
          );
        }

        return Scaffold(
          backgroundColor: DudeTheme.background,
          body: PremiumAmbientBackground(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: SafeArea(
                child: Column(
                  children: [
                    _buildTopBar(),
                    Expanded(
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
                        child: Column(
                          children: [
                            _buildAvatarSection(user),
                            const SizedBox(height: 24),
                            _buildFieldsSection(user),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          bottomNavigationBar: _buildBottomButton(userVM),
        );
      },
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => bondNavigator.backPage(context),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: DudeTheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: DudeTheme.border),
              ),
              child: const Icon(
                Icons.arrow_back_ios_new,
                color: DudeTheme.textPrimary,
                size: 18,
              ),
            ),
          ),
          const Expanded(
            child: Text(
              'Edit Profile',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: DudeTheme.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 42),
        ],
      ),
    );
  }

  Widget _buildAvatarSection(UserProfile user) {
    return Column(
      children: [
        GestureDetector(
          onTap: _pickImage,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 118,
                height: 118,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: DudeTheme.premiumAccentGradient,
                  boxShadow: DudeTheme.accentGlowShadow(blur: 18, spread: -4),
                ),
              ),
              Container(
                width: 112,
                height: 112,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: DudeTheme.background,
                ),
              ),
              ClipOval(
                child: SizedBox(
                  width: 104,
                  height: 104,
                  child: _selectedImage != null
                      ? Image.file(_selectedImage!, fit: BoxFit.cover)
                      : (user.image != null && user.image!.isNotEmpty
                          ? Image.network(
                              user.image!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Image.asset(
                                'assets/Images/men.png',
                                fit: BoxFit.cover,
                              ),
                            )
                          : Image.asset(
                              'assets/Images/men.png',
                              fit: BoxFit.cover,
                            )),
                ),
              ),
              Positioned(
                bottom: 2,
                right: 2,
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: DudeTheme.premiumAccentGradient,
                    border: Border.all(color: DudeTheme.background, width: 2),
                  ),
                  child: const Icon(
                    Icons.camera_alt_rounded,
                    color: Colors.white,
                    size: 15,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: _pickImage,
          child: const Text(
            'Change Photo',
            style: TextStyle(
              color: DudeTheme.accentBright,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFieldsSection(UserProfile user) {
    return Column(
      children: [
        _card(
          children: [
            _fieldLabel('Full Name', Icons.person_outline_rounded),
            const SizedBox(height: 10),
            _textField(
              controller: _nameController,
              hint: 'Enter your name',
            ),
            const SizedBox(height: 8),
            const Row(
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  color: DudeTheme.textSubtle,
                  size: 13,
                ),
                SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Can change username 2 more times  •  4–10 characters',
                    style: TextStyle(
                      color: DudeTheme.textSubtle,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),
        _card(
          children: [
            _fieldLabel('Bio', Icons.edit_note_rounded),
            const SizedBox(height: 10),
            _textField(
              controller: _bioController,
              hint: 'Write something about yourself...',
              maxLines: 4,
              maxLength: 200,
            ),
          ],
        ),
        const SizedBox(height: 12),
        _card(
          children: [
            _fieldLabel('Preferred Language', Icons.language_rounded),
            const SizedBox(height: 10),
            _dropdown(user),
          ],
        ),
        const SizedBox(height: 12),
        _card(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _fieldLabel('Gender', Icons.wc_rounded),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: DudeTheme.accentDim,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: DudeTheme.accent.withValues(alpha: 0.35),
                    ),
                  ),
                  child: Text(
                    user.gender ?? 'Not specified',
                    style: const TextStyle(
                      color: DudeTheme.accentBright,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _card({required List<Widget> children}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: DudeTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: DudeTheme.border.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _fieldLabel(String label, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: DudeTheme.accentDim,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: DudeTheme.accent.withValues(alpha: 0.3),
            ),
          ),
          child: Icon(icon, color: DudeTheme.accent, size: 16),
        ),
        const SizedBox(width: 10),
        Text(
          label,
          style: const TextStyle(
            color: DudeTheme.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _textField({
    required TextEditingController controller,
    required String hint,
    int maxLines = 1,
    int? maxLength,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      maxLength: maxLength,
      cursorColor: DudeTheme.accent,
      style: const TextStyle(
        color: DudeTheme.textPrimary,
        fontSize: 15,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(
          color: DudeTheme.textSubtle,
          fontSize: 14,
        ),
        filled: true,
        fillColor: DudeTheme.surfaceRaised,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: DudeTheme.border.withValues(alpha: 0.6),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: DudeTheme.border.withValues(alpha: 0.6),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: DudeTheme.accent, width: 1.4),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        counterStyle: const TextStyle(
          color: DudeTheme.textSubtle,
          fontSize: 11,
        ),
      ),
    );
  }

  Widget _dropdown(UserProfile user) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
      decoration: BoxDecoration(
        color: DudeTheme.surfaceRaised,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: DudeTheme.border.withValues(alpha: 0.6)),
      ),
      child: DropdownButton<String>(
        value: _selectedLanguage ?? user.language ?? 'English',
        isExpanded: true,
        underline: const SizedBox(),
        dropdownColor: DudeTheme.surfaceRaised,
        icon: const Icon(
          Icons.keyboard_arrow_down_rounded,
          color: DudeTheme.accent,
        ),
        style: const TextStyle(
          color: DudeTheme.textPrimary,
          fontSize: 15,
        ),
        items: languages
            .map((lang) => DropdownMenuItem(value: lang, child: Text(lang)))
            .toList(),
        onChanged: (value) => setState(() => _selectedLanguage = value),
      ),
    );
  }

  Widget _buildBottomButton(UserViewModel userVM) {
    final busy = userVM.isLoading || _isUpdating;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: GestureDetector(
          onTap: busy ? null : _updateProfile,
          child: Container(
            height: 54,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              gradient: busy
                  ? null
                  : DudeTheme.premiumAccentGradient,
              color: busy ? DudeTheme.surfaceElevated : null,
              boxShadow: busy
                  ? null
                  : DudeTheme.accentGlowShadow(blur: 16, spread: -4),
            ),
            child: busy
                ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.5,
                    ),
                  )
                : const Text(
                    'Save Changes',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
