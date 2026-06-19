// lib/StaffScreenScreens/ReferEarnScreen/ViewModel/ReferralVM.dart

import 'package:dude/DudeScreens/LoginScreens/Model/referralModel.dart';
import 'package:dude/DudeScreens/LoginScreens/Repository/LoginRepo.dart';
import 'package:flutter/material.dart';
import 'package:dude/APIService/Remote/network/NetworkApiService.dart';

class ReferralViewModel extends ChangeNotifier {
  final AuthRepository _authRepo;

  ReferralViewModel(this._authRepo);

  bool _isLoading = false;
  String? _errorMessage;
  ReferralDashboardResponse? _dashboardData;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  ReferralDashboardResponse? get dashboardData => _dashboardData;

  Future<bool> fetchReferralDashboard() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _dashboardData = await _authRepo.getReferralDashboard();
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
