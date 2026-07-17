import 'dart:io';
import 'package:dude/DudeScreens/LoginScreens/ViewModel/LoginVM.dart';
import 'package:dude/DudeScreens/LoginScreens/IdentityScreen/IdentityScreen.dart';
import 'package:dude/Dude_Utils/CustomSnackBar/StatusMessage.dart';
import 'package:dude/Reusable_Widgets/AppText_Theme/AppText_Theme.dart';
import 'package:dude/Reusable_Widgets/BondingNavigator.dart';
import 'package:dude/Dude_Utils/App_Theme/DudeTheme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:dude/Reusable_Widgets/Premium_UI/dude_logo.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

class AddProfile extends StatefulWidget {
  const AddProfile({super.key});

  @override
  State<AddProfile> createState() => _AddProfileState();
}

class _AddProfileState extends State<AddProfile> {
  final ImagePicker _picker = ImagePicker();

  @override
  Widget build(BuildContext context) {
    return Consumer<LoginViewModel>(
      builder: (context, vm, child) {
        return Scaffold(
          body: Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
                colors: [
                  DudeTheme.background,
                  DudeTheme.background,
                  DudeTheme.background,
                  DudeTheme.background,
                ],
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 10),
                    DudeLogo(height: 40),
                    const SizedBox(height: 40),

                    // Profile Photo
                    Center(
                      child: GestureDetector(
                        onTap: () async {
                          final XFile? image = await _picker.pickImage(
                            source: ImageSource.gallery,
                            imageQuality: 70,
                          );
                          if (image != null) {
                            vm.setProfileImage(File(image.path));
                          }
                        },
                        child: Container(
                          width: 220,
                          height: 220,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white24,
                              width: 1.2,
                            ),
                            color: DudeTheme.surfaceRaised,
                            image: vm.selectedProfileImage != null
                                ? DecorationImage(
                                    image: FileImage(vm.selectedProfileImage!),
                                    fit: BoxFit.cover,
                                  )
                                : null,
                          ),
                          child: vm.selectedProfileImage == null
                              ? Center(
                                  child: SvgPicture.asset(
                                    "assets/Images/image.svg",
                                  ),
                                )
                              : null,
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    Padding(
                      padding: const EdgeInsets.only(left: 12.0),
                      child: AppText(
                        "Add your best photo",
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),

                    const SizedBox(height: 12),

                    Padding(
                      padding: const EdgeInsets.only(left: 12.0),
                      child: AppText(
                        "Bonding is building real dating between real people. At least add one photo of yourself",
                        color: DudeTheme.textMuted,
                        fontSize: 16,
                        maxLines: 3,
                      ),
                    ),

                    // if (vm.uploadError != null) ...[
                    //   const SizedBox(height: 16),
                    //   Center(
                    //     child: Text(
                    //       vm.uploadError!,
                    //       style: const TextStyle(color: Colors.redAccent, fontSize: 14),
                    //       textAlign: TextAlign.center,
                    //     ),
                    //   ),
                    // ],
                    const Spacer(),

                    // Upload / Continue Button
                    GestureDetector(
                      onTap: vm.isUploading
                          ? null
                          : () async {
                              if (vm.selectedProfileImage == null) {
                                Utils.snackBarErrorMessage(
                                  "Please select a photo first",
                                );
                                return;
                              }

                              final success = await vm.uploadProfileImage();

                              if (success) {
                                bondNavigator.newPage(
                                  context,
                                  page: const IdentityScreen(),
                                );
                              } else {
                                Utils.snackBarErrorMessage(
                                  "Failed to upload photo",
                                );
                              }
                            },
                      child: Container(
                        height: 50,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          gradient: vm.isUploading
                              ? const LinearGradient(
                                  colors: [Colors.grey, Colors.blueGrey],
                                )
                              : const LinearGradient(
                                  colors: [
                                    DudeTheme.accent,
                                    DudeTheme.accent,
                                  ],
                                ),
                        ),
                        child: Center(
                          child: vm.isUploading
                              ? const SizedBox(
                                  height: 24,
                                  width: 24,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2.5,
                                  ),
                                )
                              : const Text(
                                  "Add Photo  →",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 14),

                    // Skip Button
                    GestureDetector(
                      onTap: () {
                        bondNavigator.newPage(
                          context,
                          page: const IdentityScreen(),
                        );
                      },
                      child: Container(
                        height: 52,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          gradient: const LinearGradient(
                            colors: [DudeTheme.surface, DudeTheme.surfaceRaised],
                          ),
                        ),
                        child: Center(
                          child: ShaderMask(
                            shaderCallback: (bounds) =>
                                const LinearGradient(
                                  colors: [
                                    DudeTheme.accent,
                                    DudeTheme.accent,
                                  ],
                                ).createShader(
                                  Rect.fromLTWH(
                                    0,
                                    0,
                                    bounds.width,
                                    bounds.height,
                                  ),
                                ),
                            child: AppText(
                              "Skip & Continue",
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
