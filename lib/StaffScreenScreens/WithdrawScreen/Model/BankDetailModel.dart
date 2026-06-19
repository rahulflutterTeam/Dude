// lib/models/bank_details_response.dart

import 'dart:math';

class BankDetailsResponse {
  final bool status;
  final String message;
  final List<BankDetailItem>? data;

  BankDetailsResponse({required this.status, required this.message, this.data});

  factory BankDetailsResponse.fromJson(Map<String, dynamic> json) {
    return BankDetailsResponse(
      status: json['status'] as bool? ?? false,
      message: json['message'] as String? ?? '',
      data: (json['data'] as List<dynamic>?)
          ?.map((e) => BankDetailItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class BankDetailItem {
  final String id;
  final String userId;
  final String? accountNumber;
  final String? ifsc;
  final String? bankHolderName;
  final String? bankName;
  final String? upi;
  final String createdAt;
  final String updatedAt;
  final int v;

  BankDetailItem({
    required this.id,
    required this.userId,
    this.accountNumber,
    this.ifsc,
    this.bankHolderName,
    this.bankName,
    this.upi,
    required this.createdAt,
    required this.updatedAt,
    required this.v,
  });

  factory BankDetailItem.fromJson(Map<String, dynamic> json) {
    return BankDetailItem(
      id: json['_id'] as String? ?? '',
      userId: json['userId'] as String? ?? '',
      accountNumber: json['accountNumber'] as String?,
      ifsc: json['IFSC'] as String?,
      bankHolderName: json['bankHolderName'] as String?,
      bankName: json['bankNamee'] as String?,
      upi: json['UPI'] as String?,
      createdAt: json['createdAt'] as String? ?? '',
      updatedAt: json['updatedAt'] as String? ?? '',
      v: json['__v'] as int? ?? 0,
    );
  }

  // Helper: Get masked display string
  String get displayText {
    if (upi != null && upi!.isNotEmpty) {
      return "UPI: ${upi!.substring(0, min(8, upi!.length))}...";
    } else if (accountNumber != null && accountNumber!.isNotEmpty) {
      final last4 = accountNumber!.substring(accountNumber!.length - 4);
      return "Bank: ****$last4";
    }
    return "No details saved";
  }

  bool get isUpi => upi != null && upi!.isNotEmpty;
}
