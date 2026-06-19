// lib/DudeScreens/HomeScreen/ViewModel/UserVM.dart

import 'dart:async';
import 'dart:convert';

import 'package:dude/APIService/Remote/network/ApiEndPoints.dart';
import 'package:dude/DudeScreens/AuthService.dart';
import 'package:dude/DudeScreens/DeleteAccountScreeen/Model/DeleteModel.dart';
import 'package:dude/DudeScreens/HomeScreen/Model/UserDataModel.dart';
import 'package:dude/DudeScreens/HomeScreen/Repo/UserDataRepo.dart';
import 'package:dude/Dude_Utils/CustomSnackBar/StatusMessage.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class UserViewModel extends ChangeNotifier {
  static const String _pendingBalanceUpdatesKey = 'pending_balance_updates';

  final UserRepository _userRepo;
  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;

  UserViewModel(this._userRepo) {
    _connectivitySub = _connectivity.onConnectivityChanged.listen((results) {
      final isOnline = results.any(
        (result) =>
            result == ConnectivityResult.mobile ||
            result == ConnectivityResult.wifi ||
            result == ConnectivityResult.ethernet,
      );

      if (isOnline) {
        retryPendingBalanceUpdates();
      }
    });
  }

  @override
  void dispose() {
    _connectivitySub?.cancel();
    super.dispose();
  }

  // ─── State ──────────────────────────────────────────────────────────────
  UserProfile? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;
  bool _isRetryingPendingBalanceUpdates = false;

  UserProfile? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // ─── Fetch user details ─────────────────────────────────────────────────

  Future<void> fetchUserDetails() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _userRepo.getUserDetails();
      _currentUser = response.data;

      await retryPendingBalanceUpdates();
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      debugPrint("User fetch error: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ─── Update coin balance (API + local) ──────────────────────────────────
  Future<bool> updateUserCoinBalance(
    int newBalance,
    String staffId,
    dynamic staffAmount,
    String callDuration,
    String callType, [
    String? callID,
  ]) async {
    try {
      _isLoading = true;
      notifyListeners();

      final response = await _userRepo.updateCoinBalance(
        newCoinBalance: newBalance,
        staffId: staffId,
        staffAmount: staffAmount,
        callDuration: callDuration,
        callType: callType,
        callID: callID,
      );

      print("status");
      print("data");

      if (response.status && response.data != null) {
        notifyListeners();
        // Utils.snackBar("Balance updated successfully");
        return true;
      } else {
        print("Error: ${response.message}");
        Utils.snackBarErrorMessage(response.message);
        return false;
      }
    } catch (e) {
      print("Failed to update balance: $e");
      if (_shouldQueueBalanceRetry(e)) {
        await _queuePendingBalanceUpdate(
          staffId: staffId,
          staffAmount: staffAmount,
          callDuration: callDuration,
          callType: callType,
          callID: callID,
        );
        debugPrint("📌 Queued balance update for retry when internet returns");
      } else {
        Utils.snackBarErrorMessage("Failed to update balance: $e");
      }
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void updateLocalCoinBalance(int newBalance) {
    if (_currentUser != null) {
      _currentUser = _currentUser!.copyWith(coinBalance: newBalance);
      notifyListeners();
    }
  }

  Future<void> retryPendingBalanceUpdates() async {
    if (_isRetryingPendingBalanceUpdates) return;
    if (_currentUser == null) return;

    final prefs = await SharedPreferences.getInstance();
    final pendingJson = prefs.getString(_pendingBalanceUpdatesKey);
    if (pendingJson == null || pendingJson.isEmpty) return;

    final pending = _decodePendingBalanceUpdates(pendingJson);
    if (pending.isEmpty) {
      await prefs.remove(_pendingBalanceUpdatesKey);
      return;
    }

    _isRetryingPendingBalanceUpdates = true;
    final remaining = <Map<String, dynamic>>[];
    var runningBalance = _currentUser?.coinBalance ?? 0;
    var currentIndex = 0;

    try {
      for (; currentIndex < pending.length; currentIndex++) {
        final item = pending[currentIndex];
        final staffId = item['staffId']?.toString() ?? '';
        final callDuration = item['callDuration']?.toString() ?? '0';
        final callType = item['callType']?.toString() ?? 'audio';
        final callID = item['callID']?.toString();
        final staffAmount =
            int.tryParse(item['staffAmount']?.toString() ?? '') ?? 0;

        if (staffId.isEmpty || staffAmount <= 0) continue;

        final nextBalance = runningBalance - staffAmount;
        final response = await _userRepo.updateCoinBalance(
          newCoinBalance: nextBalance < 0 ? 0 : nextBalance,
          staffId: staffId,
          staffAmount: staffAmount,
          callDuration: callDuration,
          callType: callType,
          callID: callID,
        );

        if (response.status) {
          runningBalance = nextBalance < 0 ? 0 : nextBalance;
        } else {
          remaining.add(item);
        }
      }

      await _savePendingBalanceUpdates(prefs, remaining);
      if (remaining.length != pending.length) {
        updateLocalCoinBalance(runningBalance);
      }
    } catch (e) {
      debugPrint("Pending balance retry stopped: $e");
      remaining.addAll(pending.skip(currentIndex));
      await _savePendingBalanceUpdates(prefs, remaining);
    } finally {
      _isRetryingPendingBalanceUpdates = false;
    }
  }

  bool _shouldQueueBalanceRetry(Object error) {
    final message = error.toString().toLowerCase();
    return message.contains('socketexception') ||
        message.contains('clientexception') ||
        message.contains('connection') ||
        message.contains('network') ||
        message.contains('timeout') ||
        message.contains('failed host lookup') ||
        message.contains('no address associated with hostname') ||
        message.contains('offline');
  }

  Future<void> _queuePendingBalanceUpdate({
    required String staffId,
    required dynamic staffAmount,
    required String callDuration,
    required String callType,
    String? callID,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final pending = _decodePendingBalanceUpdates(
      prefs.getString(_pendingBalanceUpdatesKey),
    );

    pending.add({
      'staffId': staffId,
      'staffAmount': staffAmount.toString(),
      'callDuration': callDuration,
      'callType': callType,
      if (callID != null && callID.isNotEmpty) 'callID': callID,
      'queuedAt': DateTime.now().toIso8601String(),
    });

    await _savePendingBalanceUpdates(prefs, pending);
  }

  List<Map<String, dynamic>> _decodePendingBalanceUpdates(String? source) {
    if (source == null || source.isEmpty) return [];

    try {
      final decoded = jsonDecode(source);
      if (decoded is! List) return [];
      return decoded
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> _savePendingBalanceUpdates(
    SharedPreferences prefs,
    List<Map<String, dynamic>> pending,
  ) async {
    if (pending.isEmpty) {
      await prefs.remove(_pendingBalanceUpdatesKey);
      return;
    }

    await prefs.setString(_pendingBalanceUpdatesKey, jsonEncode(pending));
  }

  Future<bool> updateIsFirstLogin() async {
    try {
      _isLoading = true;
      notifyListeners();

      final success = await _userRepo.updateIsFirstLogin();
      if (success && _currentUser != null) {
        _currentUser = _currentUser!.copyWith(isFirstLogin: 1);
        notifyListeners();
      }
      return success;
    } catch (e) {
      debugPrint("Update first login error: $e");
      Utils.snackBarErrorMessage("Failed to update first login");
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Optional: Clear user data (e.g. on logout)
  void clearUser() {
    _currentUser = null;
    _errorMessage = null;
    notifyListeners();
  }

  // Optional: Refresh
  Future<void> refreshUser() => fetchUserDetails();

  Future<bool> updateUserProfile({
    String? name,
    String? bio,
    String? language,
    String? image,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();

      final body = {
        if (name != null && name.isNotEmpty) "name": name,
        if (bio != null && bio.isNotEmpty) "bio": bio,
        if (language != null && language.isNotEmpty) "language": language,
        if (image != null && image.isNotEmpty) "image": image,
      };

      if (body.isEmpty) {
        return false; // Nothing to update
      }

      final response = await http.post(
        Uri.parse('${ApiEndPoints().baseUrl}auth/user/editProfile'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${await AuthService.getToken()}',
        },
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        if (json['status'] == true && json['data'] != null) {
          _currentUser = UserProfile.fromJson(json['data']);
          notifyListeners();
          return true;
        }
      }

      throw Exception("Update failed: ${response.body}");
    } catch (e) {
      debugPrint("Update profile error: $e");
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<DeleteAccountResponse?> deleteUserAccount() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _userRepo.deleteAccount();
      _isLoading = false;
      notifyListeners();
      return response;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString().replaceFirst("Exception: ", "");
      notifyListeners();
      return null;
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
