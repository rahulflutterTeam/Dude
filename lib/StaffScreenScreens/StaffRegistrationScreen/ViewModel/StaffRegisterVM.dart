// lib/viewmodels/staff_view_model.dart

import 'dart:io';
import 'dart:developer';

import 'package:dude/DudeScreens/DeleteAccountScreeen/Model/DeleteModel.dart';
import 'package:dude/DudeScreens/HomeScreen/Model/StaffDataModel.dart';
import 'package:dude/DudeScreens/LoginScreens/AddProfile/Model/ProfileModel.dart';
import 'package:dude/DudeScreens/LoginScreens/InterestScreen/Model/InterestModel.dart';
import 'package:dude/StaffScreenScreens/ProfileVerficationScreen/Model/ProfileIdModel.dart';
import 'package:dude/StaffScreenScreens/RecentCallScreen/Model/recentCallModel.dart';
import 'package:dude/StaffScreenScreens/StaffDashBoardScreen/Model/CallGraphModel.dart';
import 'package:dude/StaffScreenScreens/StaffDashBoardScreen/Model/StaffSingleDataModel.dart';
import 'package:dude/StaffScreenScreens/StaffRegistrationScreen/Model/StaffRegisterModel.dart';
import 'package:dude/StaffScreenScreens/StaffRegistrationScreen/Model/StaffGiftModel.dart';
import 'package:dude/StaffScreenScreens/StaffRegistrationScreen/Repo/StaffRegisterRepo.dart';
import 'package:dude/StaffScreenScreens/WithdrawScreen/Model/FeeManagementModel.dart';
import 'package:dude/DudeScreens/HomeScreen/Socket.dart';
import 'package:flutter/material.dart';

class StaffViewModel extends ChangeNotifier {
  final StaffRepository _staffRepo;
  final SocketService _socketService = SocketService();

  // ─── Staff Gifts ─────────────────────────────────────────────────────────
  List<StaffGiftItem> _gifts = [];
  bool _isFetchingGifts = false;
  String? _giftsError;

  List<StaffGiftItem> get gifts => _gifts;
  bool get isFetchingGifts => _isFetchingGifts;
  String? get giftsError => _giftsError;

  StaffViewModel(this._staffRepo) {
    _setupSocketListeners();
  }

  // ─── Staff Fee Management ───────────────────────────────────────────────
  FeeManagementData? _feeManagement;
  bool _isLoadingFeeManagement = false;
  String? _feeManagementError;

  FeeManagementData? get feeManagement => _feeManagement;
  bool get isLoadingFeeManagement => _isLoadingFeeManagement;
  String? get feeManagementError => _feeManagementError;
  Map<String, FeeManagementItem> get feeConfig => _feeManagement?.config ?? {};
  FeeManagementItem? get staffWithdrawalFeeConfig =>
      _feeManagement?.staffWithdrawalFee;

  double feeValue(String key, {double fallback = 0}) {
    return _feeManagement?.valueForKey(key, fallback: fallback) ?? fallback;
  }

  double feeAmountFor(String key, double baseAmount, {double fallback = 0}) {
    return _feeManagement?.feeForKey(key, baseAmount, fallback: fallback) ??
        fallback;
  }

  double audioCallAmount({double fallback = 0}) {
    return feeValue(FeeManagementData.audioCallAmount, fallback: fallback);
  }

  double videoCallAmount({double fallback = 0}) {
    return feeValue(FeeManagementData.videoCallAmount, fallback: fallback);
  }

  double messageAmount({double fallback = 0}) {
    return feeValue(FeeManagementData.messageAmount, fallback: fallback);
  }

  double withdrawFee({double fallback = 0}) {
    return feeValue(FeeManagementData.withdrawFee, fallback: fallback);
  }

  double platformFee({double fallback = 0}) {
    return feeValue(FeeManagementData.platformFee, fallback: fallback);
  }

  double gst({double fallback = 0}) {
    return feeValue(FeeManagementData.gst, fallback: fallback);
  }

  double staffWithdrawalFeeFor(double amount) {
    if (amount <= 0) return 0;

    final fee = staffWithdrawalFeeConfig?.feeFor(amount) ?? 0;
    return fee < 0 ? 0 : fee;
  }

  double staffWithdrawalNetAmountFor(double amount) {
    final netAmount = amount - staffWithdrawalFeeFor(amount);
    return netAmount < 0 ? 0 : netAmount;
  }

  double staffWithdrawalFeePercent() {
    final feeConfig = staffWithdrawalFeeConfig;
    if (feeConfig == null || !feeConfig.isPercent) return 0;

    return feeConfig.configuredValue;
  }

  String staffWithdrawalFeeLabel() {
    return staffWithdrawalFeeConfig?.displayValue ?? '0';
  }

  Future<void> fetchFeeManagement() async {
    _isLoadingFeeManagement = true;
    _feeManagementError = null;
    notifyListeners();

    try {
      final response = await _staffRepo.getStaffFeeManagement();
      _feeManagement = response.data;
    } catch (e) {
      _feeManagementError = e.toString();
    } finally {
      _isLoadingFeeManagement = false;
      notifyListeners();
    }
  }

  // ─── Staff List with Live Updates ─────────────────────────────────────────
  List<StaffDataProfile> _staffList = [];
  List<StaffDataProfile> _filteredStaffList = [];

  List<StaffDataProfile> get allStaffList => _staffList;
  List<StaffDataProfile> get staffList => _filteredStaffList;

  String _searchQuery = '';
  String get searchQuery => _searchQuery;

  bool _isFetchingStaff = false;
  String? _staffFetchError;

  bool get isFetchingStaff => _isFetchingStaff;
  String? get staffFetchError => _staffFetchError;

  // Track socket listeners to avoid duplicates
  bool _socketListenersSet = false;
  String? _currentStaffId;

  // ─── Online Status Tracking ──────────────────────────────────────────────
  Map<String, bool> onlineStatus = {};

  void clearStaffData() {
    _currentStaff = null;
    _singleStaffError = null;
    _isFetchingSingleStaff = false;
    _registerResponse = null;
    _errorMessage = null;
    _isRegistering = false;
    _callTypeUpdateError = null;
    _weeklyCallGraph = [];
    _weeklyGraphError = null;
    _totalMinutes = 0;
    _callStatsError = null;
    _gifts = [];
    _isFetchingGifts = false;
    _giftsError = null;
    _feeManagement = null;
    _isLoadingFeeManagement = false;
    _feeManagementError = null;
    notifyListeners();
  }

  void setUserOnline(String userId, bool isOnline) {
    onlineStatus[userId] = isOnline;
    notifyListeners();
  }

  bool isOnline(String userId) {
    return onlineStatus[userId] ?? false;
  }

  // ─── Socket Setup ────────────────────────────────────────────────────────
  void _setupSocketListeners() {
    if (_socketListenersSet) return;

    // debugPrint("🔌 [StaffVM] Setting up socket listeners");

    // Listen for staff list updates
    _socketService.listenStaffList((data) {
      // debugPrint("📡 [StaffVM] Received staff list update via socket");
      _processStaffListUpdate(data);
    });

    // Listen for status changes (including busy status)
    _socketService.listenStatusChanges((data) {
      // debugPrint("📡 [StaffVM] Received status change via socket");
      _processStatusUpdate(data);
    });

    _socketListenersSet = true;
  }

  // ─── Process Staff List Update from Socket ──────────────────────────────
  void _processStaffListUpdate(dynamic data) {
    // debugPrint("🔄 [StaffVM] Processing staff list update");

    try {
      if (data == null) {
        debugPrint("⚠️ [StaffVM] Received null data");
        _staffFetchError = "Received null data from server";
        _isFetchingStaff = false;
        notifyListeners();
        return;
      }

      // Handle different data formats
      List<dynamic> staffDataList = [];

      if (data is List) {
        // Direct list
        staffDataList = data;
        debugPrint(
          "📊 [StaffVM] Received direct list with ${staffDataList.length} items",
        );
      } else if (data is Map<String, dynamic>) {
        // debugPrint("📊 [StaffVM] Received map with keys: ${data.keys}");

        // Check for the specific format from your server
        if (data.containsKey('status') &&
            data['status'] == true &&
            data.containsKey('data')) {
          if (data['data'] is List) {
            staffDataList = data['data'];
            // debugPrint(
            //   "📊 [StaffVM] Found data array in status response with ${staffDataList.length} items",
            // );
          }
        }
        // Check for common response formats
        else if (data.containsKey('data') && data['data'] is List) {
          staffDataList = data['data'];
          // debugPrint(
          //   "📊 [StaffVM] Found data array with ${staffDataList.length} items",
          // );
        } else if (data.containsKey('staff') && data['staff'] is List) {
          staffDataList = data['staff'];
          debugPrint(
            "📊 [StaffVM] Found staff array with ${staffDataList.length} items",
          );
        } else if (data.containsKey('users') && data['users'] is List) {
          staffDataList = data['users'];
          debugPrint(
            "📊 [StaffVM] Found users array with ${staffDataList.length} items",
          );
        } else if (data.containsKey('staffList') && data['staffList'] is List) {
          staffDataList = data['staffList'];
          debugPrint(
            "📊 [StaffVM] Found staffList array with ${staffDataList.length} items",
          );
        } else if (data.containsKey('result') && data['result'] is List) {
          staffDataList = data['result'];
          debugPrint(
            "📊 [StaffVM] Found result array with ${staffDataList.length} items",
          );
        } else if (data.containsKey('online_staff') &&
            data['online_staff'] is List) {
          staffDataList = data['online_staff'];
          debugPrint(
            "📊 [StaffVM] Found online_staff array with ${staffDataList.length} items",
          );
        } else {
          // Maybe the entire map is a staff object?
          if (data.containsKey('memberID') && data.containsKey('name')) {
            staffDataList = [data];
            debugPrint("📊 [StaffVM] Single staff object received");
          } else {
            debugPrint("⚠️ [StaffVM] Unknown data format: ${data.keys}");
            _staffFetchError = "Unknown data format from server";
            _isFetchingStaff = false;
            notifyListeners();
            return;
          }
        }
      } else {
        debugPrint("⚠️ [StaffVM] Unexpected data type: ${data.runtimeType}");
        _staffFetchError = "Unexpected data type: ${data.runtimeType}";
        _isFetchingStaff = false;
        notifyListeners();
        return;
      }

      if (staffDataList.isEmpty) {
        debugPrint("⚠️ [StaffVM] Empty staff list received");
        _staffList = [];
        _filteredStaffList = [];
        _staffFetchError = null;
        _isFetchingStaff = false;
        notifyListeners();
        return;
      }

      // Convert to StaffDataProfile objects
      final updatedStaffList = <StaffDataProfile>[];

      for (var item in staffDataList) {
        try {
          if (item is Map<String, dynamic>) {
            final staff = StaffDataProfile.fromJson(item);
            updatedStaffList.add(staff);
          } else {
            debugPrint("⚠️ [StaffVM] Item is not a Map: ${item.runtimeType}");
          }
        } catch (e, stackTrace) {
          debugPrint("❌ [StaffVM] Error parsing staff item: $e");
          debugPrint("❌ [StaffVM] Stack trace: $stackTrace");
        }
      }

      if (updatedStaffList.isNotEmpty) {
        // debugPrint(
        //   "✅ [StaffVM] Successfully parsed ${updatedStaffList.length} staff members",
        // );

        // Update the main staff list
        _staffList = updatedStaffList;

        // Update online status map
        for (var staff in _staffList) {
          onlineStatus[staff.memberID] = staff.isOnline;
        }

        // Sort the list
        _sortStaffList();

        _applyFilter();
        // Clear any error
        _staffFetchError = null;
        _isFetchingStaff = false;

        // Notify listeners
        notifyListeners();

        // debugPrint(
        //   "📢 [StaffVM] Notified listeners with ${_filteredStaffList.length} staff members",
        // );
      } else {
        debugPrint("⚠️ [StaffVM] No valid staff members parsed");
        _staffFetchError = "Failed to parse staff data";
        _isFetchingStaff = false;
        notifyListeners();
      }
    } catch (e, stackTrace) {
      debugPrint("❌ [StaffVM] Error processing staff list update: $e");
      debugPrint("❌ [StaffVM] Stack trace: $stackTrace");
      _staffFetchError = "Error processing staff data: ${e.toString()}";
      _isFetchingStaff = false;
      notifyListeners();
    }
  }

  void _processStatusUpdate(dynamic data) {
    // debugPrint("🔄 [StaffVM] Processing status update");

    try {
      if (data == null) return;

      String? staffId;
      bool? isOnline;
      bool? isBusy;
      String? status;
      Map<String, dynamic>? fullStaffData;

      // Extract staff ID and status from different formats
      if (data is Map<String, dynamic>) {
        // debugPrint("📊 [StaffVM] Status data keys: ${data.keys}");

        // Try different field names for staff ID
        staffId =
            data['memberID']?.toString() ??
            data['memberId']?.toString() ??
            data['userId']?.toString() ??
            data['user_id']?.toString() ??
            data['id']?.toString() ??
            data['staffId']?.toString() ??
            data['staff_id']?.toString();

        // Try different field names for online status
        if (data.containsKey('isOnline')) {
          isOnline = data['isOnline'] as bool?;
        } else if (data.containsKey('status')) {
          status = data['status'] as String?;
          isOnline =
              status?.toLowerCase() == 'online' ||
              status?.toLowerCase() == 'available' ||
              status?.toLowerCase() == 'active';
        } else if (data.containsKey('online')) {
          isOnline = data['online'] as bool?;
        } else if (data.containsKey('presence')) {
          final presence = data['presence'] as String?;
          isOnline = presence?.toLowerCase() == 'online';
        }

        // Check for busy status
        if (data.containsKey('isBusy')) {
          isBusy = data['isBusy'] as bool?;
        }

        // Check if this is a full staff data object
        if (data.containsKey('name') &&
            data.containsKey('memberID') &&
            data.containsKey('areaOfInterest')) {
          fullStaffData = data;
        }
      }

      if (staffId != null) {
        // Find the staff in the list
        final existingIndex = _staffList.indexWhere(
          (s) => s.memberID == staffId,
        );

        if (existingIndex != -1) {
          // ✅ FIX: DO NOT remove staff when offline
          // Just update their status
          // debugPrint(
          //   "🔄 Updating existing staff: $staffId, isOnline: $isOnline, isBusy: $isBusy",
          // );

          var updatedStaff = _staffList[existingIndex];

          if (isOnline != null) {
            updatedStaff = updatedStaff.copyWith(isOnline: isOnline);
          }

          if (isBusy != null) {
            updatedStaff = updatedStaff.copyWith(isBusy: isBusy);
          }

          _staffList[existingIndex] = updatedStaff;

          // Update online status map
          if (isOnline != null) {
            onlineStatus[staffId] = isOnline;
          }

          _sortStaffList();
          _applyFilter();
          notifyListeners();

          // debugPrint(
          //   "✅ Staff updated: ${updatedStaff.name} - Online: ${updatedStaff.isOnline}, Busy: ${updatedStaff.isBusy}",
          // );
        } else if (fullStaffData != null && isOnline == true) {
          // Only add new staff if they are online
          // debugPrint(
          //   "🆕 [StaffVM] New staff detected! Adding to list: $staffId",
          // );
          try {
            final newStaff = StaffDataProfile.fromJson(fullStaffData);
            _staffList.add(newStaff);
            onlineStatus[staffId] = newStaff.isOnline;

            _sortStaffList();
            _applyFilter();
            notifyListeners();

            // debugPrint("✅ [StaffVM] Added new staff: ${newStaff.name}");
          } catch (e) {
            // debugPrint("❌ [StaffVM] Error creating new staff from data: $e");
            _requestFullListRefresh();
          }
        } else {
          // debugPrint(
          //   "⚠️ [StaffVM] Staff $staffId not found - requesting refresh",
          // );
          _requestFullListRefresh();
        }
      } else {
        // debugPrint("⚠️ [StaffVM] Could not extract staff ID from data");
      }
    } catch (e, stackTrace) {
      // debugPrint("❌ [StaffVM] Error processing status update: $e");
      // debugPrint("❌ [StaffVM] Stack trace: $stackTrace");
    }
  }

  void _sortStaffList() {
    // Custom sorting logic
    _staffList.sort((a, b) {
      // First sort by online status (online first, then busy, then offline)
      if (a.isOnline && !b.isOnline) return -1;
      if (!a.isOnline && b.isOnline) return 1;

      // If both online, sort by busy status (available first, then busy)
      if (a.isOnline && b.isOnline) {
        if (!a.isBusy && b.isBusy) return -1;
        if (a.isBusy && !b.isBusy) return 1;
      }

      // Then sort by name alphabetically
      return a.name.compareTo(b.name);
    });
  }

  // ─── Request Full List Refresh ──────────────────────────────────────────
  void _requestFullListRefresh() {
    if (_socketService.isConnected) {
      // debugPrint("📤 [StaffVM] Requesting full staff list refresh via socket");
      _socketService.emit("get_all_staff", {
        "requestId": DateTime.now().millisecondsSinceEpoch.toString(),
        "timestamp": DateTime.now().toIso8601String(),
        "reason": "refresh_requested",
      });
    }
  }

  // ─── Refresh Staff List via Socket (Manual) ─────────────────────────────
  void refreshStaffListViaSocket() {
    _isFetchingStaff = true;
    notifyListeners();

    if (_socketService.isConnected) {
      // debugPrint("📤 [StaffVM] Manually requesting staff list via socket");
      _socketService.requestStaffList();

      // Set a timeout to stop showing loading if no response
      Future.delayed(const Duration(seconds: 5), () {
        if (_isFetchingStaff) {
          _isFetchingStaff = false;
          _staffFetchError = "Request timed out. Please try again.";
          notifyListeners();
        }
      });
    } else {
      // debugPrint("⚠️ [StaffVM] Socket not connected, cannot refresh");
      _isFetchingStaff = false;
      _staffFetchError = "Socket not connected. Please check your connection.";
      notifyListeners();

      // Try to reconnect
      if (_currentStaffId != null) {
        _socketService.connectStaff(_currentStaffId!);
      }
    }
  }

  // ─── Update Staff Presence (called from outside) ──────────────────────
  void updateStaffPresence(dynamic data) {
    _processStatusUpdate(data);
  }

  // ─── Search Functionality ────────────────────────────────────────────────
  void updateSearchQuery(String query) {
    _searchQuery = query.trim().toLowerCase();
    _applyFilter();
    notifyListeners();
  }

  void _applyFilter() {
    if (_searchQuery.isEmpty) {
      _filteredStaffList = List.from(_staffList);
    } else {
      _filteredStaffList = _staffList.where((staff) {
        final nameMatch = staff.name.toLowerCase().contains(_searchQuery);
        final ageMatch = (staff.age?.toString() ?? '').contains(_searchQuery);
        final languageMatch = (staff.language ?? '')
            .trim()
            .toLowerCase()
            .contains(_searchQuery);
        final cityMatch = (staff.city ?? '').trim().toLowerCase().contains(
          _searchQuery,
        );
        final interestMatch = staff.areaOfInterest.any(
          (interest) => interest.title.toLowerCase().contains(_searchQuery),
        );
        return nameMatch ||
            ageMatch ||
            languageMatch ||
            cityMatch ||
            interestMatch;
      }).toList();
    }

    // debugPrint(
    //   "🔍 [StaffVM] Search filter applied: ${_filteredStaffList.length} results from ${_staffList.length} total",
    // );
  }

  // ─── Staff Registration ──────────────────────────────────────────────────
  bool _isRegistering = false;
  String? _errorMessage;
  StaffRegisterResponse? _registerResponse;

  bool get isRegistering => _isRegistering;
  String? get errorMessage => _errorMessage;
  StaffRegisterResponse? get registerResponse => _registerResponse;

  Future<bool> registerStaff({
    required String name,
    required String email,
    required String city,
    required String dob,
  }) async {
    _isRegistering = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _registerResponse = await _staffRepo.registerStaff(
        name: name,
        email: email,
        city: city,
        dob: dob,
      );

      _isRegistering = false;
      notifyListeners();
      return _registerResponse!.isSuccess;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      _isRegistering = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> registerStaffNew({required String phone}) async {
    _isRegistering = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _registerResponse = await _staffRepo.registerStaffNew(phone: phone);

      _isRegistering = false;
      notifyListeners();
      return _registerResponse!.isSuccess;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      _isRegistering = false;
      notifyListeners();
      return false;
    }
  }

  void clearErrors() {
    _errorMessage = null;
    notifyListeners();
  }

  // ─── Staff ID Verification ───────────────────────────────────────────────
  bool _isVerifyingId = false;
  String? _idVerifyError;
  StaffIdVerifyResponse? _idVerifyResponse;

  bool get isVerifyingId => _isVerifyingId;
  String? get idVerifyError => _idVerifyError;
  StaffIdVerifyResponse? get idVerifyResponse => _idVerifyResponse;

  Future<bool> verifyStaffId({
    required String idType,
    required String idNumber,
  }) async {
    _isVerifyingId = true;
    _idVerifyError = null;
    notifyListeners();

    try {
      _idVerifyResponse = await _staffRepo.verifyStaffId(
        idType: idType,
        idNumber: idNumber,
      );

      _isVerifyingId = false;
      notifyListeners();
      return _idVerifyResponse!.isSuccess;
    } catch (e) {
      _idVerifyError = e.toString().replaceFirst('Exception: ', '');
      _isVerifyingId = false;
      notifyListeners();
      return false;
    }
  }

  // ─── Profile Image Upload ────────────────────────────────────────────────
  File? _selectedProfileImage;
  bool _isUploading = false;
  String? _uploadError;
  UpdateProfileResponse? _updateResponse;

  File? get selectedProfileImage => _selectedProfileImage;
  bool get isUploading => _isUploading;
  String? get uploadError => _uploadError;
  UpdateProfileResponse? get updateResponse => _updateResponse;

  void setProfileImage(File? image) {
    _selectedProfileImage = image;
    _uploadError = null;
    notifyListeners();
  }

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
      _updateResponse = await _staffRepo.updateProfileImage(
        _selectedProfileImage!,
      );
      _isUploading = false;

      if (_updateResponse!.isSuccess &&
          _updateResponse!.data?.imageUrl != null) {
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

  // ─── Update Staff Interests ──────────────────────────────────────────────
  bool _isUpdatingInterests = false;
  String? _interestError;
  AreaOfInterestResponse? _interestResponse;

  bool get isUpdatingInterests => _isUpdatingInterests;
  String? get interestError => _interestError;
  AreaOfInterestResponse? get interestResponse => _interestResponse;

  Future<bool> updateStaffAreaOfInterest(List<String> selectedTitles) async {
    if (selectedTitles.length < 3) {
      _interestError = "Please select at least 3 interests";
      notifyListeners();
      return false;
    }

    _isUpdatingInterests = true;
    _interestError = null;
    notifyListeners();

    try {
      _interestResponse = await _staffRepo.updateStaffAreaOfInterest(
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

  // ─── Single Staff Profile ────────────────────────────────────────────────
  StaffSingleProfile? _currentStaff;
  StaffDataProfile? _currentStaff1;
  bool _isFetchingSingleStaff = false;
  String? _singleStaffError;

  StaffSingleProfile? get currentStaff => _currentStaff;
  bool get isFetchingSingleStaff => _isFetchingSingleStaff;
  String? get singleStaffError => _singleStaffError;

  Future<void> fetchStaffSingleData() async {
    _isFetchingSingleStaff = true;
    _singleStaffError = null;
    notifyListeners();

    try {
      final response = await _staffRepo.getStaffSingleData();
      _currentStaff = response.data;
      if (_currentStaff != null) {
        _currentStaffId = _currentStaff!.memberID;
        await fetchFeeManagement();
      }
      _isFetchingSingleStaff = false;
      notifyListeners();
    } catch (e) {
      _singleStaffError = e.toString().replaceFirst('Exception: ', '');
      _isFetchingSingleStaff = false;
      notifyListeners();
    }
  }

  // ─── Call History ────────────────────────────────────────────────────────
  List<CallHistoryItem> _callHistory = [];
  bool _isLoading = false;

  List<CallHistoryItem> get callHistory => _callHistory;
  bool get isLoading => _isLoading;

  Future<void> fetchCallHistory() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _staffRepo.getStaffCallHistory();
      _callHistory = response.data ?? [];
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint("Call history error: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refresh() => fetchCallHistory();

  // ─── Call Stats ──────────────────────────────────────────────────────────
  int _callsToday = 0;
  int _totalMinutes = 0;
  bool _isFetchingCallStats = false;
  String? _callStatsError;

  int get callsToday => _callsToday;
  int get totalMinutes => _totalMinutes;
  bool get isFetchingCallStats => _isFetchingCallStats;
  String? get callStatsError => _callStatsError;

  Future<void> fetchStaffCallStats() async {
    _isFetchingCallStats = true;
    _callStatsError = null;
    notifyListeners();

    try {
      final response = await _staffRepo.getStaffCallStats();
      if (response.status && response.data != null) {
        _callsToday = response.data!.callsToday;
        _totalMinutes = response.data!.totalMinutes;
      }
    } catch (e) {
      _callStatsError = e.toString();
    } finally {
      _isFetchingCallStats = false;
      notifyListeners();
    }
  }

  // ─── Weekly Call Graph ───────────────────────────────────────────────────
  List<WeeklyCallData> _weeklyCallGraph = [];
  bool _isFetchingWeeklyGraph = false;
  String? _weeklyGraphError;

  List<WeeklyCallData> get weeklyCallGraph => _weeklyCallGraph;
  bool get isFetchingWeeklyGraph => _isFetchingWeeklyGraph;
  String? get weeklyGraphError => _weeklyGraphError;

  Future<void> fetchWeeklyCallGraph() async {
    _isFetchingWeeklyGraph = true;
    _weeklyGraphError = null;
    notifyListeners();

    try {
      final response = await _staffRepo.getWeeklyCallGraph();
      if (response.status && response.data != null) {
        _weeklyCallGraph = response.data!;
      }
    } catch (e) {
      _weeklyGraphError = e.toString();
    } finally {
      _isFetchingWeeklyGraph = false;
      notifyListeners();
    }
  }

  // ─── Get Staff ID by Member ID ───────────────────────────────────────────
  String? getStaffIdByMemberId(String memberId) {
    // If you have _currentStaff and it's the logged-in staff
    if (_currentStaff != null && _currentStaff!.memberID == memberId) {
      return _currentStaff!.id;
    }

    // If you have staffList (all staff)
    try {
      final staff = _staffList.firstWhere((s) => s.memberID == memberId);
      return staff.id.isNotEmpty ? staff.id : null;
    } catch (e) {
      return null;
    }
  }

  // ─── Delete Staff Account ────────────────────────────────────────────────
  Future<DeleteAccountResponse?> deleteStaffAccount() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _staffRepo.deleteStaffAccount();
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

  // ─── Clear Error ─────────────────────────────────────────────────────────
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // ─── Clean up listeners ──────────────────────────────────────────────────
  void disposeListeners() {
    // debugPrint("🧹 [StaffVM] Cleaning up socket listeners");
    _socketListenersSet = false;
  }

  Future<void> fetchStaffDetails() async {
    _isFetchingStaff = true;
    _staffFetchError = null;
    notifyListeners();

    try {
      // debugPrint("🌐 [StaffVM] Fetching staff details via API");
      final response = await _staffRepo.getStaffDetails();

      if (response.status == true) {
        _staffList = response.data ?? [];

        // Update online status map
        for (var staff in _staffList) {
          onlineStatus[staff.memberID] = staff.isOnline;
        }

        // Sort the list
        _sortStaffList();

        // debugPrint(
        //   "✅ [StaffVM] API: Fetched ${_staffList.length} staff members",
        // );

        // Reset filtered list with the fresh data
        _filteredStaffList = List.from(_staffList);

        // Re-apply current search
        _applyFilter();

        // Setup socket listeners if not already set
        _setupSocketListeners();

        // Request fresh staff list via socket after API fetch
        Future.delayed(const Duration(seconds: 1), () {
          if (_socketService.isConnected) {
            // debugPrint(
            //   "📤 [StaffVM] Requesting staff list via socket after API fetch",
            // );
            _socketService.requestStaffList();
          }
        });

        _staffFetchError = null;
      } else {
        // debugPrint(
        //   "❌ [StaffVM] API: Failed to fetch staff - ${response.message}",
        // );
        _staffList = [];
        _filteredStaffList = [];
        _staffFetchError = response.message ?? 'Failed to load staff list';
      }
    } catch (e, stackTrace) {
      // debugPrint('❌ [StaffVM] fetchStaffDetails error: $e');
      // debugPrint('Stack trace: $stackTrace');

      _staffList = [];
      _filteredStaffList = [];

      _staffFetchError = e
          .toString()
          .replaceAll('Exception: ', '')
          .replaceAll('Exception:', '')
          .trim();

      if (_staffFetchError!.isEmpty) {
        _staffFetchError = 'Failed to load staff. Please try again.';
      }
    } finally {
      _isFetchingStaff = false;
      notifyListeners();
    }
  }

  // ─── Staff Call Status Update ─────────────────────────────────────────
  bool _isUpdatingCallStatus = false;
  String? _callStatusError;

  bool get isUpdatingCallStatus => _isUpdatingCallStatus;
  String? get callStatusError => _callStatusError;

  Future<bool> updateStaffCallStatus({
    required String staffId,
    required bool isBusy,
  }) async {
    _isUpdatingCallStatus = true;
    _callStatusError = null;
    notifyListeners();

    try {
      // debugPrint(
      //   "🔄 [StaffVM] Updating call status via API - staffId: $staffId, isBusy: $isBusy",
      // );

      final response = await _staffRepo.updateStaffCallStatus(
        staffId: staffId,
        isBusy: isBusy,
      );

      if (response.status) {
        debugPrint(
          "✅ [StaffVM] Call status updated successfully: ${response.message}",
        );

        // Update local data if this is the current staff
        if (_currentStaff1 != null && _currentStaff1!.id == staffId) {
          _currentStaff1 = _currentStaff1!.copyWith(isBusy: isBusy);
        }

        // Also update in staff list if present
        final staffIndex = _staffList.indexWhere((s) => s.id == staffId);
        if (staffIndex != -1) {
          _staffList[staffIndex] = _staffList[staffIndex].copyWith(
            isBusy: isBusy,
          );
          _applyFilter();
        }

        _isUpdatingCallStatus = false;
        notifyListeners();
        return true;
      } else {
        _callStatusError = response.message;
        _isUpdatingCallStatus = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      debugPrint("❌ [StaffVM] Error updating call status: $e");
      _callStatusError = e.toString().replaceFirst('Exception: ', '');
      _isUpdatingCallStatus = false;
      notifyListeners();
      return false;
    }
  }

  // Convenience method to set current staff as busy
  Future<bool> setCurrentStaffBusy(bool isBusy) async {
    if (_currentStaff == null) {
      debugPrint("⚠️ [StaffVM] Cannot update status - current staff is null");
      return false;
    }

    return updateStaffCallStatus(staffId: _currentStaff!.id, isBusy: isBusy);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ─── STAFF CALL TYPE UPDATE ─────────────────────────────────────────────
  // ═══════════════════════════════════════════════════════════════════════════

  bool _isUpdatingCallType = false;
  String? _callTypeUpdateError;
  String? _currentCallType;

  bool get isUpdatingCallType => _isUpdatingCallType;
  String? get callTypeUpdateError => _callTypeUpdateError;
  String? get currentCallType => _currentCallType;

  /// Updates the staff's call type preference
  /// [callType] should be one of: "audio", "video", or "both"
  Future<bool> updateStaffCallType(String callType) async {
    _isUpdatingCallType = true;
    _callTypeUpdateError = null;
    notifyListeners();

    try {
      debugPrint(
        "📞 [StaffVM] Updating call type via API - callType: $callType",
      );

      final response = await _staffRepo.updateStaffCallType(callType);

      if (response.status) {
        debugPrint(
          "✅ [StaffVM] Call type updated successfully: ${response.message}",
        );

        // Update local state
        _currentCallType = callType;

        // Also update in current staff if available
        if (_currentStaff != null) {
          // If your StaffSingleProfile model has a callType field, update it here
          // _currentStaff = _currentStaff!.copyWith(callType: callType);
        }

        _isUpdatingCallType = false;
        notifyListeners();
        return true;
      } else {
        _callTypeUpdateError = response.message;
        _isUpdatingCallType = false;
        notifyListeners();
        debugPrint(
          "❌ [StaffVM] Failed to update call type: ${response.message}",
        );
        return false;
      }
    } catch (e) {
      debugPrint("❌ [StaffVM] Error updating call type: $e");
      _callTypeUpdateError = e.toString().replaceFirst('Exception: ', '');
      _isUpdatingCallType = false;
      notifyListeners();
      return false;
    }
  }

  /// Convenience method to update call type with enum
  Future<bool> updateStaffCallTypeWithEnum(String callTypeValue) async {
    // Validate call type
    final validTypes = ["audio", "video", "both"];
    if (!validTypes.contains(callTypeValue.toLowerCase())) {
      _callTypeUpdateError =
          "Invalid call type. Must be 'audio', 'video', or 'both'";
      notifyListeners();
      return false;
    }

    return updateStaffCallType(callTypeValue.toLowerCase());
  }

  // ─── Fetch Staff Gifts ───────────────────────────────────────────────────
  Future<void> fetchStaffGifts() async {
    _isFetchingGifts = true;
    _giftsError = null;
    notifyListeners();

    try {
      final response = await _staffRepo.getStaffGifts();
      if (response.status) {
        _gifts = response.data;
        _giftsError = null;
      } else {
        _giftsError = response.message;
      }
    } catch (e) {
      _giftsError = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _isFetchingGifts = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    disposeListeners();
    super.dispose();
  }
}
