import 'dart:io';
import 'dart:convert';
import 'package:dude/APIService/Remote/network/ApiEndPoints.dart';
import 'package:dude/DudeScreens/AuthService.dart';
import 'package:dude/DudeScreens/HomeScreen/ViewModel/UserVM.dart';
import 'package:dude/DudeScreens/HomeScreen/Model/UserDataModel.dart';
import 'package:dude/Dude_Utils/CustomSnackBar/StatusMessage.dart';
import 'package:dude/Reusable_Widgets/AppText_Theme/AppText_Theme.dart';
import 'package:dude/Reusable_Widgets/BondingNavigator.dart';
import 'package:dude/Dude_Utils/App_Theme/DudeTheme.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:mime/mime.dart';
import 'package:http_parser/http_parser.dart' as http_parser;

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen>
    with TickerProviderStateMixin {
  late TextEditingController _nameController;
  late TextEditingController _bioController;

  File? _selectedImage;
  String? _currentImageUrl;
  String? _selectedLanguage;

  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final List<String> languages = [
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

  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _bioController = TextEditingController();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero).animate(
          CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
        );

    _fadeController.forward();
    _slideController.forward();

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
    _fadeController.dispose();
    _slideController.dispose();
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
      var request = http.MultipartRequest('POST', uri);
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
              child: CircularProgressIndicator(color: DudeTheme.accent),
            ),
          );
        }

        return Scaffold(
          backgroundColor: DudeTheme.background,
          body: Stack(
            children: [
              // ── Ambient background glows ────────────────────────────────
              Positioned(
                top: -80,
                right: -60,
                child: Container(
                  width: 280,
                  height: 280,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        DudeTheme.accentSoft.withOpacity(0.35),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 100,
                left: -80,
                child: Container(
                  width: 240,
                  height: 240,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        DudeTheme.accent.withOpacity(0.12),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),

              // ── Main content ────────────────────────────────────────────
              FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: SafeArea(
                    child: Column(
                      children: [
                        _buildTopBar(),
                        Expanded(
                          child: SingleChildScrollView(
                            physics: const BouncingScrollPhysics(),
                            child: Column(
                              children: [
                                const SizedBox(height: 28),
                                _buildAvatarSection(user),
                                const SizedBox(height: 36),
                                _buildFieldsSection(user),
                                const SizedBox(height: 100),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          bottomNavigationBar: _buildBottomButton(userVM),
        );
      },
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => bondNavigator.backPage(context),
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.06),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white.withOpacity(0.1)),
              ),
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: Colors.white,
                size: 18,
              ),
            ),
          ),
          const Spacer(),
          Column(
            children: [
              const Text(
                "Edit Profile",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                ),
              ),
              Container(
                margin: const EdgeInsets.only(top: 3),
                height: 2,
                width: 28,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(2),
                  gradient: const LinearGradient(
                    colors: [DudeTheme.accent, DudeTheme.accent],
                  ),
                ),
              ),
            ],
          ),
          const Spacer(),
          const SizedBox(width: 42),
        ],
      ),
    );
  }

  Widget _buildAvatarSection(user) {
    return Column(
      children: [
        GestureDetector(
          onTap: _pickImage,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Outer glow ring
              Container(
                width: 124,
                height: 124,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const SweepGradient(
                    colors: [
                      DudeTheme.accent,
                      DudeTheme.accentSoft,
                      DudeTheme.accent,
                    ],
                  ),
                ),
              ),
              // Inner dark ring
              Container(
                width: 118,
                height: 118,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: DudeTheme.background,
                ),
              ),
              // Avatar image
              ClipOval(
                child: SizedBox(
                  width: 110,
                  height: 110,
                  child: _selectedImage != null
                      ? Image.file(_selectedImage!, fit: BoxFit.cover)
                      : (user.image != null && user.image!.isNotEmpty
                            ? Image.network(
                                user.image!,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Image.asset(
                                  "assets/Images/men.png",
                                  fit: BoxFit.cover,
                                ),
                              )
                            : Image.asset(
                                "assets/Images/men.png",
                                fit: BoxFit.cover,
                              )),
                ),
              ),
              // Camera badge
              Positioned(
                bottom: 4,
                right: 4,
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [DudeTheme.accent, DudeTheme.accent],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: DudeTheme.accent.withOpacity(0.5),
                        blurRadius: 8,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.camera_alt_rounded,
                    color: DudeTheme.textOnLightChip,
                    size: 16,
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
            "Change Photo",
            style: TextStyle(
              color: DudeTheme.accent,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFieldsSection(user) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          _buildCard(
            children: [
              _buildFieldLabel("Full Name", Icons.person_outline_rounded),
              const SizedBox(height: 10),
              _buildTextField(
                controller: _nameController,
                hint: "Enter your name",
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(
                    Icons.info_outline_rounded,
                    color: DudeTheme.textSubtle,
                    size: 13,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    "Can change username 2 more times  •  4–10 characters",
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.35),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 16),

          _buildCard(
            children: [
              _buildFieldLabel("Bio", Icons.edit_note_rounded),
              const SizedBox(height: 10),
              _buildTextField(
                controller: _bioController,
                hint: "Write something about yourself...",
                maxLines: 4,
                maxLength: 200,
              ),
            ],
          ),

          const SizedBox(height: 16),

          _buildCard(
            children: [
              _buildFieldLabel("Preferred Language", Icons.language_rounded),
              const SizedBox(height: 10),
              _buildDropdown(user),
            ],
          ),

          const SizedBox(height: 16),

          _buildCard(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.06),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.wc_rounded,
                          color: DudeTheme.accent,
                          size: 16,
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        "Gender",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withOpacity(0.1)),
                    ),
                    child: Text(
                      user.gender ?? "Not specified",
                      style: const TextStyle(
                        color: DudeTheme.textMid,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCard({required List<Widget> children}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _buildFieldLabel(String label, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.06),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: DudeTheme.accent, size: 16),
        ),
        const SizedBox(width: 10),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    int maxLines = 1,
    int? maxLength,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      maxLength: maxLength,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 15,
        fontWeight: FontWeight.w400,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          color: Colors.white.withOpacity(0.25),
          fontSize: 14,
        ),
        filled: true,
        fillColor: Colors.white.withOpacity(0.05),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: DudeTheme.accent, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        counterStyle: TextStyle(
          color: Colors.white.withOpacity(0.3),
          fontSize: 11,
        ),
      ),
    );
  }

  Widget _buildDropdown(user) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: DropdownButton<String>(
        value: _selectedLanguage ?? user.language ?? "English",
        isExpanded: true,
        underline: const SizedBox(),
        dropdownColor: DudeTheme.surface,
        icon: const Icon(
          Icons.keyboard_arrow_down_rounded,
          color: DudeTheme.accent,
        ),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 15,
          fontWeight: FontWeight.w400,
        ),
        items: languages.map((String lang) {
          return DropdownMenuItem<String>(value: lang, child: Text(lang));
        }).toList(),
        onChanged: (String? newValue) {
          setState(() => _selectedLanguage = newValue);
        },
      ),
    );
  }

  Widget _buildBottomButton(UserViewModel userVM) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
        child: GestureDetector(
          onTap: (userVM.isLoading || _isUpdating) ? null : _updateProfile,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: 56,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: (userVM.isLoading || _isUpdating)
                  ? LinearGradient(
                      colors: [
                        DudeTheme.accent.withOpacity(0.4),
                        DudeTheme.accent.withOpacity(0.4),
                      ],
                    )
                  : const LinearGradient(
                      colors: [
                        DudeTheme.accent,
                        DudeTheme.accent,
                        DudeTheme.accent,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
              boxShadow: (userVM.isLoading || _isUpdating)
                  ? []
                  : [
                      BoxShadow(
                        color: DudeTheme.accent.withOpacity(0.4),
                        blurRadius: 20,
                        offset: const Offset(0, 6),
                      ),
                    ],
            ),
            alignment: Alignment.center,
            child: _isUpdating || userVM.isLoading
                ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(
                      color: DudeTheme.textOnLightChip,
                      strokeWidth: 2.5,
                    ),
                  )
                : const Text(
                    "Save Changes",
                    style: TextStyle(
                      color: DudeTheme.textOnLightChip,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.6,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
