// lib/repositories/staff_repository.dart

import 'dart:io';

import 'package:dude/APIService/Remote/network/ApiEndPoints.dart';
import 'package:dude/APIService/Remote/network/NetworkApiService.dart';
import 'package:dude/DudeScreens/AuthService.dart';
import 'package:dude/DudeScreens/DeleteAccountScreeen/Model/DeleteModel.dart';
import 'package:dude/DudeScreens/HomeScreen/Model/StaffDataModel.dart';
import 'package:dude/DudeScreens/LoginScreens/AddProfile/Model/ProfileModel.dart';
import 'package:dude/DudeScreens/LoginScreens/InterestScreen/Model/InterestModel.dart';
import 'package:dude/StaffScreenScreens/ProfileVerficationScreen/Model/ProfileIdModel.dart';
import 'package:dude/StaffScreenScreens/RecentCallScreen/Model/recentCallModel.dart';
import 'package:dude/StaffScreenScreens/StaffDashBoardScreen/Model/CallGraphModel.dart';
import 'package:dude/StaffScreenScreens/StaffDashBoardScreen/Model/StaffSingleDataModel.dart';
import 'package:dude/StaffScreenScreens/StaffDashBoardScreen/Model/busycallStatus.dart';
import 'package:dude/StaffScreenScreens/StaffDashBoardScreen/Model/callStatusModel.dart';
import 'package:dude/StaffScreenScreens/StaffRegistrationScreen/Model/StaffRegisterModel.dart';
import 'package:dude/StaffScreenScreens/StaffRegistrationScreen/Model/StaffGiftModel.dart';
import 'package:dude/StaffScreenScreens/StaffRegistrationScreen/Model/callTypeModel.dart';
import 'package:dude/StaffScreenScreens/WithdrawScreen/Model/FeeManagementModel.dart';
import 'package:flutter/foundation.dart';

class StaffRepository {
  final NetworkApiService _apiService;

  StaffRepository(this._apiService);

  Future<StaffRegisterResponse> registerStaff({
    required String name,
    required String email,
    required String city,
    required String dob,
  }) async {
    try {
      final body = {"name": name, "email": email, "city": city, "dob": dob};

      final response = await _apiService.postResponseV3(
        ApiEndPoints().staffRegister, // → "/api/v1/auth/user/staffdata"
        body: body,
      );

      if (kDebugMode) {
        print("Staff Register Response: $response");
      }

      final staffResp = StaffRegisterResponse.fromJson(response);

      if (staffResp.isSuccess) {
        return staffResp;
      } else {
        throw Exception(staffResp.message);
      }
    } catch (e) {
      throw Exception("StaffRepository registerStaff error: $e");
    }
  }

  // Add this method to your StaffRepository class

  Future<CallTypeUpdateResponse> updateStaffCallType(String callType) async {
    try {
      final body = {
        "callType": callType, // "audio", "video", or "both"
      };

      if (kDebugMode) {
        print("📤 Updating staff call type - callType: $callType");
        print("📤 Request body: $body");
      }

      final response = await _apiService.postResponseV3(
        ApiEndPoints().staffUpdateCallType,
        body: body,
      );

      if (kDebugMode) {
        print("📥 Staff call type update response: $response");
      }

      final callTypeResponse = CallTypeUpdateResponse.fromJson(response);

      if (callTypeResponse.status) {
        return callTypeResponse;
      } else {
        throw Exception(
          callTypeResponse.message.isNotEmpty
              ? callTypeResponse.message
              : "Failed to update call type",
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print("❌ StaffRepository updateStaffCallType error: $e");
      }
      throw Exception("StaffRepository updateStaffCallType error: $e");
    }
  }

  // Add this method to StaffRepository class
  Future<StaffCallStatusResponse> updateStaffCallStatus({
    required String staffId,
    required bool isBusy,
  }) async {
    try {
      final request = StaffCallStatusRequest(staffId: staffId, isBusy: isBusy);

      if (kDebugMode) {
        print(
          "📤 Updating staff call status - staffId: $staffId, isBusy: $isBusy",
        );
        print("📤 Request body: ${request.toJson()}");
      }

      final response = await _apiService.postResponseV3(
        ApiEndPoints().staffCallStatusUpdate,
        body: request.toJson(),
      );

      if (kDebugMode) {
        print("📥 Staff call status update response: $response");
      }

      final statusResponse = StaffCallStatusResponse.fromJson(response);

      if (statusResponse.status) {
        return statusResponse;
      } else {
        throw Exception(
          statusResponse.message.isNotEmpty
              ? statusResponse.message
              : "Failed to update call status",
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print("❌ StaffRepository updateStaffCallStatus error: $e");
      }
      throw Exception("StaffRepository updateStaffCallStatus error: $e");
    }
  }

  Future<StaffRegisterResponse> registerStaffNew({
    required String phone,
  }) async {
    try {
      final body = {"phone": phone};

      final response = await _apiService.postResponseV2(
        ApiEndPoints().staffRegisterNew,
        body: body,
      );

      if (kDebugMode) {
        print("Staff Register Response: $response");
      }

      final staffResp = StaffRegisterResponse.fromJson(response);

      if (staffResp.isSuccess) {
        return staffResp;
      } else {
        throw Exception(staffResp.message);
      }
    } catch (e) {
      throw Exception("StaffRepository registerStaff error: $e");
    }
  }

  // lib/repositories/staff_repository.dart

  Future<StaffIdVerifyResponse> verifyStaffId({
    required String idType,
    required String idNumber,
  }) async {
    try {
      final body = {"IDtype": idType, "IDnumber": idNumber};

      final response = await _apiService.postResponseV3(
        ApiEndPoints().staffIdVerify, // → "/api/v1/auth/user/staffIdVerify"
        body: body,
      );

      if (kDebugMode) {
        print("Staff ID Verify Response: $response");
      }

      final verifyResp = StaffIdVerifyResponse.fromJson(response);

      if (verifyResp.isSuccess) {
        return verifyResp;
      } else {
        throw Exception(verifyResp.message);
      }
    } catch (e) {
      throw Exception("StaffRepository verifyStaffId error: $e");
    }
  }

  Future<UpdateProfileResponse> updateProfileImage(File imageFile) async {
    try {
      // Optional: get token
      final token = await AuthService.getToken();

      final response = await _apiService.uploadImageMultipart(
        endpoint: ApiEndPoints().updateStaffProfile,
        imageFile: imageFile,
        fieldName: 'image',
        token: token,
        // additionalFields: {'someKey': 'value'}, // if needed later
      );

      if (kDebugMode) {
        print("Update Profile Raw Response1: $response");
      }

      final updateResp = UpdateProfileResponse.fromJson(response);

      if (updateResp.isSuccess) {
        return updateResp;
      } else {
        throw Exception(updateResp.message);
      }
    } catch (e) {
      throw Exception("AuthRepository updateProfileImage error: $e");
    }
  }

  Future<AreaOfInterestResponse> updateStaffAreaOfInterest({
    required List<String> interests,
  }) async {
    try {
      final body = {
        "areaOfInterest": interests.map((title) => {"title": title}).toList(),
      };

      final response = await _apiService.postResponseV3(
        ApiEndPoints().updateStaffAreaOfInterest,
        body: body,
      );

      if (kDebugMode) {
        print("Update Area of Interest Response: $response");
      }

      final resp = AreaOfInterestResponse.fromJson(response);
      print("......$resp");

      if (resp.isSuccess) {
        return resp;
      } else {
        throw Exception(resp.message);
      }
    } catch (e) {
      throw Exception("AuthRepository updateAreaOfInterest error: $e");
    }
  }

  Future<StaffDetailsResponse> getStaffDetails() async {
    try {
      final response = await _apiService.getResponseV2(
        ApiEndPoints().getStaffDetails, // "/api/v1/auth/user/getstaffDetails"
        // If it requires auth token, add headers here
        // headers: {'Authorization': 'Bearer $token'},
      );

      print("Get Staff Details Raw Response: $response");

      final staffResp = StaffDetailsResponse.fromJson(response);

      if (staffResp.status) {
        return staffResp;
      } else {
        throw Exception(staffResp.message);
      }
    } catch (e) {
      throw Exception("StaffRepository getStaffDetails error: $e");
    }
  }

  // lib/repositories/staff_repository.dart  (or auth_repository.dart)

  Future<StaffSingleDataResponse> getStaffSingleData() async {
    try {
      final response = await _apiService.getResponseV2(
        ApiEndPoints()
            .getStaffSingleData, // "/api/v1/auth/user/getstaffSingleData"
        // Add auth header if required
        // headers: {'Authorization': 'Bearer ${await AuthService.getToken()}'},
      );

      print("Get Staff Single Data Raw Response: $response");

      final staffResp = StaffSingleDataResponse.fromJson(response);

      if (staffResp.status && staffResp.data != null) {
        return staffResp;
      } else {
        throw Exception(staffResp.message);
      }
    } catch (e) {
      throw Exception("StaffRepository getStaffSingleData error: $e");
    }
  }

  Future<CallHistoryResponse> getStaffCallHistory() async {
    try {
      final response = await _apiService.getResponseV2(
        ApiEndPoints().staffCallHistory, // ← your GET endpoint
      );

      if (kDebugMode) {
        print("Staff Call History Response: $response");
      }

      final resp = CallHistoryResponse.fromJson(response);

      if (resp.status) {
        return resp;
      } else {
        throw Exception(resp.message ?? "Failed to fetch call history");
      }
    } catch (e) {
      throw Exception("CallRepository getStaffCallHistory error: $e");
    }
  }

  Future<StaffCallStatsResponse> getStaffCallStats() async {
    try {
      final response = await _apiService.getResponseV2(
        ApiEndPoints().staffCallStats, // "staff/getStaffCallStats"
      );

      if (kDebugMode) {
        print("Staff Call Stats Response: $response");
      }

      final resp = StaffCallStatsResponse.fromJson(response);

      if (resp.status) {
        return resp;
      } else {
        throw Exception(resp.message ?? "Failed to fetch call stats");
      }
    } catch (e) {
      debugPrint("StaffRepository getStaffCallStats error: $e");
      throw Exception("Failed to fetch call stats: $e");
    }
  }

  Future<StaffWeeklyCallGraphResponse> getWeeklyCallGraph() async {
    try {
      final response = await _apiService.getResponseV2(
        ApiEndPoints().staffWeeklyCallGraph, // "staff/getWeeklyCallGraph"
      );

      if (kDebugMode) {
        print("Weekly Call Graph Response: $response");
      }

      final resp = StaffWeeklyCallGraphResponse.fromJson(response);

      if (resp.status) {
        return resp;
      } else {
        throw Exception(resp.message ?? "Failed to fetch weekly call graph");
      }
    } catch (e) {
      debugPrint("Repository getWeeklyCallGraph error: $e");
      throw Exception("Failed to fetch weekly call graph: $e");
    }
  }

  Future<DeleteAccountResponse> deleteStaffAccount() async {
    try {
      final response = await _apiService.getResponseV2(
        ApiEndPoints()
            .staffDeleteAccount, // ← must return "auth/staff/deleteAccount"
      );

      if (kDebugMode) {
        print("Staff Delete Account Response: $response");
      }

      final deleteResp = DeleteAccountResponse.fromJson(response);

      if (deleteResp.status) {
        return deleteResp;
      } else {
        throw Exception(
          deleteResp.message.isNotEmpty
              ? deleteResp.message
              : "Failed to delete account",
        );
      }
    } catch (e) {
      throw Exception("StaffRepository deleteStaffAccount error: $e");
    }
  }

  Future<StaffGiftsResponse> getStaffGifts() async {
    try {
      final response = await _apiService.getResponseV2(
        ApiEndPoints().getStaffGifts,
      );

      if (kDebugMode) {
        print("Staff Gifts API Response: $response");
      }

      return StaffGiftsResponse.fromJson(response);
    } catch (e) {
      if (kDebugMode) {
        print("❌ StaffRepository getStaffGifts error: $e");
      }
      throw Exception("StaffRepository getStaffGifts error: $e");
    }
  }

  Future<FeeManagementResponse> getStaffFeeManagement() async {
    try {
      final response = await _apiService.getResponseV2(
        ApiEndPoints().staffFeeManagement,
      );

      if (kDebugMode) {
        print("Staff Fee Management API Response: $response");
      }

      final resp = FeeManagementResponse.fromJson(response);

      if (resp.status) {
        return resp;
      } else {
        throw Exception(
          resp.message.isNotEmpty
              ? resp.message
              : "Failed to fetch staff fee management",
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print("❌ StaffRepository getStaffFeeManagement error: $e");
      }
      throw Exception("StaffRepository getStaffFeeManagement error: $e");
    }
  }

  Future<List<Map<String, dynamic>>> getOnlineUsers() async {
    try {
      final response = await _apiService.getResponseV2(
        ApiEndPoints().staffOnlineUsers,
      );

      if (kDebugMode) {
        print("Staff Online Users Response: $response");
      }

      if (response['status'] != true) {
        throw Exception(
          response['message']?.toString() ?? 'Failed to fetch online users',
        );
      }

      final data = response['data'];
      if (data is! List) return [];
      return data
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
    } catch (e) {
      throw Exception("StaffRepository getOnlineUsers error: $e");
    }
  }

  Future<Map<String, dynamic>> waveUser({required String userMemberID}) async {
    try {
      final response = await _apiService.postResponseV3(
        ApiEndPoints().staffWaveUser,
        body: {'userMemberID': userMemberID},
      );

      if (kDebugMode) {
        print("Staff Wave User Response: $response");
      }

      if (response is Map && response['status'] == true) {
        return Map<String, dynamic>.from(response);
      }

      throw Exception(
        (response is Map ? response['message']?.toString() : null) ??
            'Failed to send wave',
      );
    } catch (e) {
      throw Exception("StaffRepository waveUser error: $e");
    }
  }
}
