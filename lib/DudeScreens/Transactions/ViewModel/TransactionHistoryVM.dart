// lib/viewmodels/deposit_history_view_model.dart

import 'package:dude/DudeScreens/Transactions/Model/TransactionHistoryModel.dart';
import 'package:dude/DudeScreens/WalletScreen/razorPayFlow/Repository/PaymentRepo.dart';
import 'package:dude/Dude_Utils/CustomSnackBar/StatusMessage.dart';
import 'package:flutter/material.dart';

class DepositHistoryViewModel extends ChangeNotifier {
  final WalletRepository _walletRepo;

  List<DepositHistoryItem> _depositHistory = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<DepositHistoryItem> get depositHistory => _depositHistory;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  DepositHistoryViewModel(this._walletRepo);

  Future<void> fetchDepositHistory() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _walletRepo.getUserDepositHistory();
      _depositHistory = response.data ?? [];
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint("Deposit history error: $e");
      Utils.snackBarErrorMessage("Failed to load deposit history");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Optional: Refresh
  Future<void> refresh() => fetchDepositHistory();
}
