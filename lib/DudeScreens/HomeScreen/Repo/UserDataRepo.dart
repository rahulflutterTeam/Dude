// lib/repositories/user_repository.dart

import 'package:dude/APIService/Remote/network/ApiEndPoints.dart';
import 'package:dude/APIService/Remote/network/NetworkApiService.dart';
import 'package:dude/DudeScreens/DeleteAccountScreeen/Model/DeleteModel.dart';
import 'package:dude/DudeScreens/HomeScreen/Model/UpdateBalanceModel.dart';
import 'package:dude/DudeScreens/HomeScreen/Model/UserDataModel.dart';
import 'package:dude/DudeScreens/WalletScreen/AdModel/Model.dart';
import 'package:flutter/foundation.dart';

class UserRepository {
  final NetworkApiService _apiService;

  UserRepository(this._apiService);

  // Add this method to your existing UserRepository class

  // lib/repositories/user_repository.dart

  Future<AdBannerModel> getAdBanner() async {
    try {
      final response = await _apiService.getResponseV2(
        ApiEndPoints().getAdBanner,
      );

      if (kDebugMode) {
        print("Get Ad Banner Response: $response");
      }

      final bannerResp = AdBannerModel.fromJson(response);

      if (bannerResp.status && bannerResp.data != null) {
        return bannerResp;
      } else {
        throw Exception(
          bannerResp.message.isNotEmpty
              ? bannerResp.message
              : "Failed to fetch ad banner",
        );
      }
    } catch (e) {
      throw Exception("UserRepository getAdBanner error: $e");
    }
  }

  Future<UserDetailsResponse> getUserDetails() async {
    try {
      final response = await _apiService.getResponseV2(
        ApiEndPoints().getUserDetails,
      );

      if (kDebugMode) {
        print("Get User Details Response: $response");
      }

      final userResp = UserDetailsResponse.fromJson(response);

      if (userResp.status && userResp.data != null) {
        return userResp;
      } else {
        throw Exception(
          userResp.message.isNotEmpty
              ? userResp.message
              : "Failed to fetch user details",
        );
      }
    } catch (e) {
      throw Exception("UserRepository getUserDetails error: $e");
    }
  }

  Future<UserDetailsResponse> getUserCallHistory() async {
    try {
      final response = await _apiService.getResponseV2(
        ApiEndPoints().userCallHistory,
      );

      if (kDebugMode) {
        print("Get User Details Response: $response");
      }

      final userResp = UserDetailsResponse.fromJson(response);

      if (userResp.status && userResp.data != null) {
        return userResp;
      } else {
        throw Exception(
          userResp.message.isNotEmpty
              ? userResp.message
              : "Failed to fetch user details",
        );
      }
    } catch (e) {
      throw Exception("UserRepository getUserDetails error: $e");
    }
  }

  Future<bool> updateIsFirstLogin() async {
    try {
      final response = await _apiService.getResponseV2(
        ApiEndPoints().updateIsFirstLogin,
      );

      if (kDebugMode) {
        print("Update Is First Login Response: $response");
      }

      if (response is Map<String, dynamic>) {
        final status = response['status'];
        if (status == true) {
          return true;
        }
        throw Exception(response['message']?.toString() ?? "Failed to update");
      }

      throw Exception("Unexpected response format");
    } catch (e) {
      throw Exception("UserRepository updateIsFirstLogin error: $e");
    }
  }

  Future<UpdateBalanceResponse> updateCoinBalance({
    required int newCoinBalance,
    required String staffId,
    required dynamic staffAmount,
    required String callDuration,
    required String callType,
    String? callID,
  }) async {
    try {
      final body = {
        "coinBalance": newCoinBalance,
        "staffId": staffId,
        "staffEarned": staffAmount,
        "callDuration": callDuration,
        "callType": callType,
        if (callID != null && callID.isNotEmpty) "callID": callID,
      };
      print("body :: $body");

      final response = await _apiService.postResponseV3(
        ApiEndPoints().userBalanceUpdate, // ← your endpoint path
        body: body,
      );

      if (kDebugMode) {
        print("Update Coin Balance Response: $response");
      }

      final resp = UpdateBalanceResponse.fromJson(response);

      if (resp.status) {
        return resp;
      } else {
        throw Exception(resp.message);
      }
    } catch (e) {
      throw Exception("UserRepository updateCoinBalance error: $e");
    }
  }

  Future<DeleteAccountResponse> deleteAccount() async {
    try {
      final response = await _apiService.getResponseV2(
        ApiEndPoints().deleteAccount, // e.g. "auth/user/deleteAccount"
      );

      if (kDebugMode) {
        print("Delete Account Response: $response");
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
      throw Exception("UserRepository deleteAccount error: $e");
    }
  }

  // You can add more user-related methods later, e.g.
  // Future updateProfile(...)
  // Future getWalletBalance(...)
}
