// lib/viewmodels/login_viewmodel.dart
import 'dart:io';

import 'package:dude/DudeScreens/AuthService.dart';
import 'package:dude/DudeScreens/LoginScreens/AddProfile/Model/ProfileModel.dart';
import 'package:dude/DudeScreens/LoginScreens/IdentityScreen/Model/IdentifyModel.dart';
import 'package:dude/DudeScreens/LoginScreens/InterestLanguage/Model/LanguageModel.dart';
import 'package:dude/DudeScreens/LoginScreens/InterestScreen/Model/InterestModel.dart';
import 'package:dude/DudeScreens/LoginScreens/Model/LoginModel.dart';
import 'package:dude/DudeScreens/LoginScreens/Model/VerifyOtpModel.dart';
import 'package:dude/DudeScreens/LoginScreens/Repository/LoginRepo.dart';
import 'package:dude/Dude_Utils/CustomSnackBar/StatusMessage.dart';
import 'package:flutter/material.dart';

class LoginViewModel extends ChangeNotifier {
  final AuthRepository _authRepo;

  LoginViewModel(this._authRepo);

  bool _isLoading = false;
  String? _errorMessage;
  SignupResponse? _signupResponse;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  SignupResponse? get signupResponse => _signupResponse;
  String? get autoOtp => _signupResponse?.otp?.toString(); // 👈 ADD

  String? _autoOtp;
  String? get autoOtp1 => _autoOtp;
  // ─── New fields for verify OTP ─────────────────────────────────
  VerifyOtpResponse? _verifyResponse;
  bool _isVerifying = false;
  String? _verifyError;

  // Getters

  bool get isVerifying => _isVerifying;

  String? get verifyError => _verifyError;
  VerifyOtpResponse? get verifyResponse => _verifyResponse;

  Future<bool> sendOtp(String phone, String referralCode) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _signupResponse = await _authRepo.sendOtp(phone, referralCode);
      _autoOtp = _signupResponse?.otp?.toString(); // ⭐ ADD

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst("Exception: ", "");
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> verifyOtp(String phone, String otp) async {
    _isVerifying = true;
    _verifyError = null;
    notifyListeners();

    try {
      _verifyResponse = await _authRepo.verifyOtp(phone: phone, otp: otp);
      _isVerifying = false;

      if (_verifyResponse != null && _verifyResponse!.isSuccess) {
        // Save token + optional data
        await AuthService.saveLoginData(
          token: _verifyResponse!.token!,
          userId: _verifyResponse!.user?.id,
          phone: phone,
        );
      }

      notifyListeners();

      return true;
    } catch (e) {
      _verifyError = e.toString().replaceFirst('Exception: ', '');
      _isVerifying = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> staffVerifyOtp(String phone, String otp) async {
    _isVerifying = true;
    _verifyError = null;
    notifyListeners();

    try {
      _verifyResponse = await _authRepo.StaffVerifyOtp(phone: phone, otp: otp);
      _isVerifying = false;

      if (_verifyResponse != null && _verifyResponse!.isSuccess) {
        // Save token + optional data
        await AuthService.saveLoginData(
          token: _verifyResponse!.token!,
          userId: _verifyResponse!.user?.id,
          phone: phone,
        );
      }

      notifyListeners();

      return true;
    } catch (e) {
      _verifyError = e.toString().replaceFirst('Exception: ', '');
      _isVerifying = false;
      notifyListeners();
      return false;
    }
  }

  void clearErrors() {
    _errorMessage = null;
    _verifyError = null;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    _verifyError = null;
    notifyListeners();
  }
  // lib/DudeScreens/LoginScreens/ViewModel/LoginVM.dart

  // Add these fields
  File? _selectedProfileImage;
  bool _isUploading = false;
  String? _uploadError;
  UpdateProfileResponse? _updateResponse;

  File? get selectedProfileImage => _selectedProfileImage;
  bool get isUploading => _isUploading;
  String? get uploadError => _uploadError;
  UpdateProfileResponse? get updateResponse => _updateResponse;

  // Method to set image from UI
  void setProfileImage(File? image) {
    _selectedProfileImage = image;
    _uploadError = null;
    notifyListeners();
  }

  // Upload method
  Future<bool> uploadProfileImage() async {
    if (_selectedProfileImage == null) {
      _uploadError = "No image selected";
      notifyListeners();
      return false;
    }

    _isUploading = true;
    _uploadError = null;
    notifyListeners();

    try {
      _updateResponse = await _authRepo.updateProfileImage(
        _selectedProfileImage!,
      );
      _isUploading = false;

      if (_updateResponse!.isSuccess &&
          _updateResponse!.data?.imageUrl != null) {
        // Optional: save updated user data / image url locally
        notifyListeners();
        return true;
      } else {
        _uploadError = _updateResponse!.message;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _uploadError = e.toString().replaceAll('Exception: ', '');
      _isUploading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> uploadSelfie(File selfieFile) async {
    _isUploading = true;
    _uploadError = null;
    notifyListeners();

    try {
      // Your real API call (example using your repo)
      final response = await _authRepo.uploadStaffSelfie(
        selfieFile,
      ); // ← adjust method name

      _isUploading = false;
      print("response.status::::${response.status}");

      // Just check status — that's enough
      if (response.status == true) {
        print("response.status::::${response.status}");
        // Optional: show success message
        Utils.snackBar("Selfie uploaded successfully!");
        return true;
      } else {
        _uploadError = response.message ?? "Upload failed";
        return false;
      }
    } catch (e) {
      _uploadError = e.toString().replaceFirst('Exception: ', '');
      _isUploading = false;
      notifyListeners();
      return false;
    }
  } // lib/DudeScreens/LoginScreens/ViewModel/LoginVM.dart

  // Add these new fields
  bool _isUpdatingBio = false;
  String? _bioError;
  BioProfileResponse? _bioResponse;

  bool get isUpdatingBio => _isUpdatingBio;
  String? get bioError => _bioError;
  BioProfileResponse? get bioResponse => _bioResponse;

  // New method
  Future<bool> updateBioData({
    required String name,
    required String gender,
    required String dob,
    required String bio,
  }) async {
    _isUpdatingBio = true;
    _bioError = null;
    notifyListeners();

    try {
      _bioResponse = await _authRepo.updateBioData(
        name: name,
        gender: gender,
        dob: dob,
        bio: bio,
      );

      _isUpdatingBio = false;
      notifyListeners();

      return _bioResponse!.isSuccess;
    } catch (e) {
      _bioError = e.toString().replaceFirst('Exception: ', '');
      _isUpdatingBio = false;
      notifyListeners();
      return false;
    }
  }

  void clearBioErrors() {
    _bioError = null;
    notifyListeners();
  }

  // lib/DudeScreens/LoginScreens/ViewModel/LoginVM.dart

  // Add these fields
  bool _isUpdatingInterests = false;
  String? _interestError;
  AreaOfInterestResponse? _interestResponse;

  bool get isUpdatingInterests => _isUpdatingInterests;
  String? get interestError => _interestError;
  AreaOfInterestResponse? get interestResponse => _interestResponse;

  // Method
  Future<bool> updateAreaOfInterest(List<String> selectedTitles) async {
    if (selectedTitles.length < 3) {
      _interestError = "Please select at least 3 interests";
      notifyListeners();
      return false;
    }

    _isUpdatingInterests = true;
    _interestError = null;
    notifyListeners();

    try {
      _interestResponse = await _authRepo.updateAreaOfInterest(
        interests: selectedTitles,
      );

      _isUpdatingInterests = false;
      notifyListeners();
      return _interestResponse!.isSuccess;
    } catch (e) {
      _interestError = e.toString().replaceFirst('Exception: ', '');
      _isUpdatingInterests = false;
      notifyListeners();
      return false;
    }
  }

  // lib/DudeScreens/LoginScreens/ViewModel/LoginVM.dart

  // Add these fields
  bool _isUpdatingLanguage = false;
  String? _languageError;
  LanguageUpdateResponse? _languageResponse;

  bool get isUpdatingLanguage => _isUpdatingLanguage;
  String? get languageError => _languageError;
  LanguageUpdateResponse? get languageResponse => _languageResponse;

  // Method to update language
  Future<bool> updateUserLanguage(String selectedLanguage) async {
    if (selectedLanguage.isEmpty) {
      _languageError = "Please select a language";
      notifyListeners();
      return false;
    }

    _isUpdatingLanguage = true;
    _languageError = null;
    notifyListeners();

    try {
      _languageResponse = await _authRepo.updateUserLanguage(
        language: selectedLanguage,
      );

      _isUpdatingLanguage = false;
      notifyListeners();
      return _languageResponse!.isSuccess;
    } catch (e) {
      _languageError = e.toString().replaceFirst('Exception: ', '');
      _isUpdatingLanguage = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> staffUpdateUserLanguage(String selectedLanguage) async {
    if (selectedLanguage.isEmpty) {
      _languageError = "Please select a language";
      notifyListeners();
      return false;
    }

    _isUpdatingLanguage = true;
    _languageError = null;
    notifyListeners();

    try {
      _languageResponse = await _authRepo.updateStaffLanguage(
        language: selectedLanguage,
      );

      _isUpdatingLanguage = false;
      notifyListeners();
      return _languageResponse!.isSuccess;
    } catch (e) {
      _languageError = e.toString().replaceFirst('Exception: ', '');
      _isUpdatingLanguage = false;
      notifyListeners();
      return false;
    }
  }
}
