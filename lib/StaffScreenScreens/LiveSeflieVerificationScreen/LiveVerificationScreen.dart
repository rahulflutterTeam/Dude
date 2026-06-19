import 'dart:io';

import 'package:dude/DudeScreens/LoginScreens/ViewModel/LoginVM.dart';
import 'package:dude/Dude_Utils/CustomSnackBar/StatusMessage.dart';
import 'package:dude/Reusable_Widgets/AppText_Theme/AppText_Theme.dart';
import 'package:dude/Reusable_Widgets/BondingNavigator.dart';
import 'package:dude/StaffScreenScreens/StaffRegistrationScreen/ViewModel/StaffRegisterVM.dart';
import 'package:dude/StaffScreenScreens/VerificationApprovedScreen/VerificationApprovedScreen.dart';
import 'package:dude/StaffScreenScreens/VerificationInprogressScreen/VerificationInprogressScreen.dart';
import 'package:dude/StaffScreenScreens/VerificationUnsuccessfulScreen/VerificationUnsuccessScreen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
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
          body: Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF241b40), // top
                  Color(0xFF1C1426),
                  Color(0xFF12151c),
                  Color(0xFF12151c),
                  Color(0xFF12151c),
                  Color(0xFF2b1e4e),
                ],
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    const SizedBox(height: 12),
                    SvgPicture.asset("assets/Images/dude.svg", height: 54),

                    const SizedBox(height: 40),

                    const Text(
                      "Profile Verification",
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),

                    const SizedBox(height: 8),

                    const Text(
                      "Complete verification to activate your account.",
                      style: TextStyle(
                        color: Color(0xFFB0A8C0),
                        fontSize: 15.5,
                        height: 1.4,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const Spacer(),

                    // Large Purple Camera Circle
                    Center(
                      child: GestureDetector(
                        onTap: vm.isUploading ? null : _takeSelfie,
                        child: Container(
                          width: 260,
                          height: 260,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color(0xFF9F6BFF),
                              width: 4,
                            ),
                            color: const Color(0xFF1A0F2B),
                            image: _selectedImage != null
                                ? DecorationImage(
                                    image: FileImage(_selectedImage!),
                                    fit: BoxFit.cover,
                                  )
                                : null,
                          ),
                          child: _selectedImage == null
                              ? const Center(
                                  child: Icon(
                                    Icons.camera_alt_rounded,
                                    size: 90,
                                    color: Color(0xFF9F6BFF),
                                  ),
                                )
                              : null,
                        ),
                      ),
                    ),

                    const SizedBox(height: 40),

                    // Two Option Buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildOptionButton(
                          icon: Icons.camera_alt,
                          label: "Take Selfie",
                          onTap: vm.isUploading ? null : _takeSelfie,
                        ),
                        const SizedBox(width: 50),
                        _buildOptionButton(
                          icon: Icons.photo_library_rounded,
                          label: "From Gallery",
                          onTap: vm.isUploading ? null : _pickFromGallery,
                        ),
                      ],
                    ),

                    const Spacer(),

                    // Instruction Text
                    Text(
                      "Upload a clear live selfie or photo to confirm your identity.",
                      style: TextStyle(
                        color: Color(0xFFB0A8C0),
                        fontSize: 15,
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          ),

          // Bottom Button
          bottomNavigationBar: Container(
            color: Color(0xFF2b1e4e),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: GestureDetector(
                  onTap: (vm.isUploading || _selectedImage == null)
                      ? null
                      : () async {
                          final success = await vm.uploadSelfie(
                            _selectedImage!,
                          );
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
                            Utils.snackBarErrorMessage(
                              "Failed to upload photo",
                            );
                          }
                        },
                  child: Container(
                    height: 58,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: (vm.isUploading || _selectedImage == null)
                          ? LinearGradient(
                              colors: [
                                Color(0xFFaecc01).withOpacity(0.4),
                                Color(0xFFaecc01).withOpacity(0.4),
                              ],
                            )
                          : const LinearGradient(
                              colors: [Color(0xFFaecc01), Color(0xFFaecc01)],
                            ),
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
                                  ? "Select Image First"
                                  : "Upload & Verify",
                              style: TextStyle(
                                color: _selectedImage == null
                                    ? Colors.white
                                    : Colors.black,
                                fontSize: 17,
                                fontWeight: FontWeight.w600,
                              ),
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
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF2A1F38),
              border: Border.all(color: const Color(0xFF9F6BFF), width: 1.5),
            ),
            child: Icon(icon, color: const Color(0xFF9F6BFF), size: 28),
          ),
          const SizedBox(height: 10),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFFB0A8C0),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
