// lib/repositories/wallet_repository.dart

import 'package:dude/APIService/Remote/network/ApiEndPoints.dart';
import 'package:dude/APIService/Remote/network/NetworkApiService.dart';
import 'package:dude/DudeScreens/Transactions/Model/TransactionHistoryModel.dart';
import 'package:dude/DudeScreens/WalletScreen/razorPayFlow/Model/PaymentModel.dart';
import 'package:dude/DudeScreens/WalletScreen/razorPayFlow/Model/amountAdminCoinModel.dart';
import 'package:dude/DudeScreens/WalletScreen/razorPayFlow/Model/confirmPaymentModel.dart';
import 'package:dude/DudeScreens/WalletScreen/razorPayFlow/Model/paymentGatewayKeyModel.dart';
import 'package:dude/StaffScreenScreens/WithdrawScreen/Model/AddBankDetailsModel.dart';
import 'package:dude/StaffScreenScreens/WithdrawScreen/Model/BankDetailModel.dart';
import 'package:dude/StaffScreenScreens/WithdrawScreen/Model/WithdrawHistoryModel.dart';
import 'package:dude/StaffScreenScreens/WithdrawScreen/Model/WithdrawRequestModel.dart';
import 'package:flutter/foundation.dart';

class WalletRepository {
  final NetworkApiService _apiService = NetworkApiService();

  WalletRepository();

  Future<PaymentGatewayKeyResponse> getPaymentGatewayKey() async {
    try {
      final response = await _apiService.getResponseV2(
        ApiEndPoints().getPaymentGatewayKey,
      );

      final resp = PaymentGatewayKeyResponse.fromJson(response);

      final gateway = resp.data;
      final provider = gateway?.provider.toLowerCase() ?? '';
      final hasRequiredKey = provider == 'razorpay'
          ? gateway!.keyId.isNotEmpty
          : provider.isNotEmpty;

      if (resp.status && gateway != null && hasRequiredKey) {
        return resp;
      } else {
        throw Exception(
          resp.message.isNotEmpty
              ? resp.message
              : "Payment gateway key not available",
        );
      }
    } catch (e) {
      debugPrint("WalletRepository getPaymentGatewayKey error: $e");
      throw Exception("Failed to fetch payment gateway key: $e");
    }
  }

  Future<PlaceOrderResponse> placeOrder({
    required int amountInPaise,
    required String currency,
    required int coin,
  }) async {
    try {
      final body = {
        "amount": amountInPaise,
        "currency": currency,
        "coin": coin,
      };
      final response = await _apiService.postResponseV3(
        ApiEndPoints().placeOrder,
        body: body,
      );

      final resp = PlaceOrderResponse.fromJson(response);

      if (resp.status) {
        return resp;
      } else {
        throw Exception(resp.message ?? "Failed to place order");
      }
    } catch (e) {
      debugPrint("WalletRepository placeOrder error: $e");
      throw Exception("Failed to place order: $e");
    }
  }

  Future<ConfirmPurchaseResponse> confirmPurchase({
    required String razorpayOrderId,
    required String razorpayPaymentId,
    required String razorpaySignature,
  }) async {
    try {
      final body = {
        "razorpay_order_id": razorpayOrderId,
        "razorpay_payment_id": razorpayPaymentId,
        "razorpay_signature": razorpaySignature,
      };
      final response = await _apiService.postResponseV3(
        ApiEndPoints().confirmPurchase, // ← your endpoint path
        body: body,
      );

      final resp = ConfirmPurchaseResponse.fromJson(response);

      if (resp.status) {
        return resp;
      } else {
        throw Exception(resp.message ?? "Payment confirmation failed");
      }
    } catch (e) {
      debugPrint("WalletRepository confirmPurchase error: $e");
      throw Exception("Failed to confirm purchase: $e");
    }
  }

  Future<ConfirmPurchaseResponse> confirmCashfreePurchase({
    required String orderId,
  }) async {
    try {
      final body = {"order_id": orderId};

      final response = await _apiService.postResponseV3(
        ApiEndPoints().confirmPurchase,
        body: body,
      );

      final resp = ConfirmPurchaseResponse.fromJson(response);

      if (resp.status) {
        return resp;
      } else {
        throw Exception(resp.message ?? "Payment confirmation failed");
      }
    } catch (e) {
      debugPrint("WalletRepository confirmCashfreePurchase error: $e");
      throw Exception("Failed to confirm Cashfree purchase: $e");
    }
  }

  Future<DepositHistoryResponse> getUserDepositHistory() async {
    try {
      final response = await _apiService.getResponseV2(
        ApiEndPoints().userDepositHistory, // ← your GET endpoint
      );

      final resp = DepositHistoryResponse.fromJson(response);

      if (resp.status) {
        return resp;
      } else {
        throw Exception(resp.message ?? "Failed to fetch deposit history");
      }
    } catch (e) {
      debugPrint("WalletRepository getUserDepositHistory error: $e");
      throw Exception("Failed to fetch deposit history: $e");
    }
  }

  Future<AddBankDetailsResponse> addBankDetails({
    required Map<String, dynamic> body,
  }) async {
    try {
      final response = await _apiService.postResponseV3(
        ApiEndPoints().addBankDetails, // "staff/addBankDetails"
        body: body,
      );

      final resp = AddBankDetailsResponse.fromJson(response);

      if (resp.status) {
        return resp;
      } else {
        throw Exception(resp.message ?? "Failed to add bank details");
      }
    } catch (e) {
      debugPrint("WalletRepository addBankDetails error: $e");
      throw Exception("Failed to add bank details: $e");
    }
  }

  Future<BankDetailsResponse> getAllBankDetails() async {
    try {
      final response = await _apiService.getResponseV2(
        ApiEndPoints().getAllBankDetails, // "staff/getAllBankDetails"
      );

      final resp = BankDetailsResponse.fromJson(response);

      if (resp.status) {
        return resp;
      } else {
        throw Exception(resp.message ?? "Failed to fetch bank details");
      }
    } catch (e) {
      debugPrint("WalletRepository getAllBankDetails error: $e");
      throw Exception("Failed to fetch bank details: $e");
    }
  }

  Future<void> deleteBankDetails({required String bankId}) async {
    try {
      final body = {"bankId": bankId};

      final response = await _apiService.postResponseV3(
        ApiEndPoints().deleteBankDetails, // "staff/deleteBankDetails"
        body: body,
      );

      if (response['status'] != true) {
        throw Exception(response['message'] ?? "Delete failed");
      }
    } catch (e) {
      debugPrint("WalletRepository deleteBankDetails error: $e");
      throw Exception("Failed to delete bank details: $e");
    }
  }

  Future<StaffWithdrawResponse> staffWithdraw({
    required String accountNumber,
    required String confirmAccountNumber,
    required String ifsc,
    required String bankHolderName,
    required String bankName,
    required String upi,
    required String confirmUpi,
    required num amount,
  }) async {
    try {
      final body = {
        "accountNumber": accountNumber,
        "confirmAccountNumber": confirmAccountNumber,
        "IFSC": ifsc,
        "bankHolderName": bankHolderName,
        "bankNamee": bankName,
        "UPI": upi,
        "confirmUPI": confirmUpi,
        "amount": amount,
      };

      final response = await _apiService.postResponseV3(
        ApiEndPoints().staffWithdraw,
        body: body,
      );

      final resp = StaffWithdrawResponse.fromJson(response);

      // Return response even if status is false
      return resp;
    } catch (e) {
      debugPrint("WalletRepository staffWithdraw error: $e");
      rethrow; // Let ViewModel handle network errors
    }
  }

  Future<StaffWithdrawHistoryResponse> getStaffWithdrawHistory() async {
    try {
      final response = await _apiService.getResponseV2(
        ApiEndPoints().staffWithdrawHistory, // "staff/staffWithdrawHistory"
      );

      final resp = StaffWithdrawHistoryResponse.fromJson(response);

      if (resp.status) {
        return resp;
      } else {
        throw Exception(resp.message ?? "Failed to fetch withdrawal history");
      }
    } catch (e) {
      debugPrint("WalletRepository getStaffWithdrawHistory error: $e");
      throw Exception("Failed to fetch withdrawal history: $e");
    }
  }

  Future<PaymentStructureResponse> getPaymentStructure() async {
    try {
      final response = await _apiService.getResponseV2(
        ApiEndPoints().getPaymentsStructure, // ← your actual endpoint
      );

      final resp = PaymentStructureResponse.fromJson(response);

      if (resp.status) {
        return resp;
      } else {
        throw Exception(resp.message ?? "Failed to fetch payment structure");
      }
    } catch (e) {
      debugPrint("WalletRepository getPaymentStructure error: $e");
      throw Exception("Failed to fetch payment structure: $e");
    }
  }
}
