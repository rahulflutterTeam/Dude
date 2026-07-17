import 'dart:io';
import 'package:dude/Dude_Utils/App_Theme/DudeTheme.dart';
import 'package:dude/Reusable_Widgets/Premium_UI/dude_logo.dart';
import 'package:dude/Reusable_Widgets/Premium_UI/premium_ambient_background.dart';
import 'package:dude/DudeScreens/LoginScreens/ViewModel/LoginVM.dart';
import 'package:dude/Dude_Utils/CustomSnackBar/StatusMessage.dart';
import 'package:dude/Reusable_Widgets/BondingNavigator.dart';
import 'package:dude/StaffScreenScreens/StaffRegistrationScreen/ViewModel/StaffRegisterVM.dart';
import 'package:dude/StaffScreenScreens/VerificationApprovedScreen/VerificationApprovedScreen.dart';
import 'package:dude/StaffScreenScreens/VerificationInprogressScreen/VerificationInprogressScreen.dart';
import 'package:dude/StaffScreenScreens/VerificationUnsuccessfulScreen/VerificationUnsuccessScreen.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

class LiveVerificationScreen extends StatefulWidget {
  const LiveVerificationScreen({super.key});

  @override
  State<LiveVerificationScreen> createState() => _LiveVerificationScreenState();
}

class _LiveVerificationScreenState extends State<LiveVerificationScreen> {
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();
  bool _isPickingImage = false;

  Future<bool> _requestCameraPermission() async {
    PermissionStatus cameraStatus = await Permission.camera.request();
    if (cameraStatus.isGranted) return true;
    if (cameraStatus.isPermanentlyDenied) await openAppSettings();
    Utils.snackBarErrorMessage("Camera permission required");
    return false;
  }

  Future<void> _takeSelfie() async {
    if (_isPickingImage) return;
    if (!await _requestCameraPermission()) return;

    setState(() => _isPickingImage = true);
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.front,
        imageQuality: 80,
      );
      if (photo != null && mounted) {
        setState(() => _selectedImage = File(photo.path));
      }
    } catch (e) {
      Utils.snackBarErrorMessage("Failed to open camera");
    } finally {
      if (mounted) setState(() => _isPickingImage = false);
    }
  }

  Future<void> _pickFromGallery() async {
    if (_isPickingImage) return;
    setState(() => _isPickingImage = true);
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );
      if (photo != null && mounted) {
        setState(() => _selectedImage = File(photo.path));
      }
    } catch (e) {
      Utils.snackBarErrorMessage("Failed to pick image");
    } finally {
      if (mounted) setState(() => _isPickingImage = false);
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<StaffViewModel>().fetchStaffSingleData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<LoginViewModel, StaffViewModel>(
      builder: (context, vm, staffVM, child) {
        final staff = staffVM.currentStaff;
        final isApproved = staff?.isApproved?.toString() ?? '0';

        return Scaffold(
          backgroundColor: DudeTheme.background,
          body: PremiumAmbientBackground(
            child: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Center(child: DudeLogo(height: 54)),
                    const SizedBox(height: 28),
                    _stepLabel(),
                    const SizedBox(height: 14),
                    const Text(
                      "Add a clear selfie",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        height: 1.15,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.7,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      "This helps Dude match you with your ID and protects the community from fake profiles.",
                      style: TextStyle(
                        color: DudeTheme.textSubtle,
                        fontSize: 15,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 26),
                    GestureDetector(
                      onTap: vm.isUploading ? null : _takeSelfie,
                      child: Container(
                        height: 270,
                        width: double.infinity,
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          gradient: DudeTheme.premiumAccentGradient,
                          borderRadius: BorderRadius.circular(28),
                          boxShadow: _selectedImage == null
                              ? DudeTheme.accentGlowShadow(blur: 26)
                              : DudeTheme.softShadow,
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(26),
                          child: _selectedImage != null
                              ? Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    Image.file(
                                      _selectedImage!,
                                      fit: BoxFit.cover,
                                    ),
                                    Positioned(
                                      right: 12,
                                      top: 12,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 7,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.black.withValues(
                                            alpha: 0.7,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                        ),
                                        child: const Row(
                                          children: [
                                            Icon(
                                              Icons.check_circle_rounded,
                                              size: 16,
                                              color: DudeTheme.accentBright,
                                            ),
                                            SizedBox(width: 5),
                                            Text(
                                              "Ready",
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 12,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                )
                              : Container(
                                  color: DudeTheme.surface,
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Container(
                                        width: 84,
                                        height: 84,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: DudeTheme.accentDim,
                                          border: Border.all(
                                            color: DudeTheme.accent.withValues(
                                              alpha: 0.45,
                                            ),
                                          ),
                                        ),
                                        child: const Icon(
                                          Icons.camera_alt_rounded,
                                          size: 38,
                                          color: DudeTheme.accentBright,
                                        ),
                                      ),
                                      const SizedBox(height: 18),
                                      const Text(
                                        "Tap to take a selfie",
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 17,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      const Text(
                                        "Face forward in good lighting",
                                        style: TextStyle(
                                          color: DudeTheme.textSubtle,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Expanded(
                          child: _buildOptionButton(
                            icon: Icons.camera_alt_rounded,
                            label: "Take selfie",
                            onTap: vm.isUploading ? null : _takeSelfie,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildOptionButton(
                            icon: Icons.photo_library_outlined,
                            label: "Choose photo",
                            onTap: vm.isUploading ? null : _pickFromGallery,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 22),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: DudeTheme.accentDim.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.verified_user_outlined,
                            color: DudeTheme.accentBright,
                            size: 20,
                          ),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              "Use a recent, unfiltered photo with only your face visible.",
                              style: TextStyle(
                                color: DudeTheme.textMuted,
                                fontSize: 13,
                                height: 1.45,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          bottomNavigationBar: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: GestureDetector(
                onTap: (vm.isUploading || _selectedImage == null)
                    ? null
                    : () async {
                        final success = await vm.uploadSelfie(_selectedImage!);
                        if (!context.mounted) return;
                        if (success) {
                          final nextScreen = isApproved == "1"
                              ? const ApprovedScreen()
                              : isApproved == "2"
                              ? const VerificationUnsuccessScreen()
                              : const VerificationInprogressScreen();

                          bondNavigator.newPageRemoveUntil(
                            context,
                            page: nextScreen,
                          );
                        } else {
                          Utils.snackBarErrorMessage("Failed to upload photo");
                        }
                      },
                child: Container(
                  height: 58,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: (vm.isUploading || _selectedImage == null)
                        ? const LinearGradient(
                            colors: [Color(0xFF452331), Color(0xFF301923)],
                          )
                        : DudeTheme.premiumAccentGradient,
                  ),
                  child: Center(
                    child: vm.isUploading
                        ? const SizedBox(
                            height: 28,
                            width: 28,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 3,
                            ),
                          )
                        : Text(
                            _selectedImage == null
                                ? "Add a photo to continue"
                                : "Submit for verification  →",
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildOptionButton({
    required IconData icon,
    required String label,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 54,
        decoration: BoxDecoration(
          color: DudeTheme.surfaceRaised,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: DudeTheme.borderSubtle),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: DudeTheme.accentBright, size: 21),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _stepLabel() => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
    decoration: BoxDecoration(
      color: DudeTheme.accentDim,
      borderRadius: BorderRadius.circular(30),
      border: Border.all(color: DudeTheme.accent.withValues(alpha: 0.35)),
    ),
    child: const Text(
      "STEP 2 OF 2  •  SELFIE CHECK",
      style: TextStyle(
        color: DudeTheme.accentBright,
        fontSize: 11,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.7,
      ),
    ),
  );
}
