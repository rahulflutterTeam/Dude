// lib/models/add_bank_details_response.dart

class AddBankDetailsResponse {
  final bool status;
  final String message;
  final AddBankDetailsData? data;

  AddBankDetailsResponse({
    required this.status,
    required this.message,
    this.data,
  });

  factory AddBankDetailsResponse.fromJson(Map<String, dynamic> json) {
    return AddBankDetailsResponse(
      status: json['status'] as bool? ?? false,
      message: json['message'] as String? ?? '',
      data: json['data'] != null
          ? AddBankDetailsData.fromJson(json['data'])
          : null,
    );
  }
}

class AddBankDetailsData {
  final String userId;
  final String? accountNumber;
  final String? ifsc;
  final String? bankHolderName;
  final String? bankName;
  final String? upi;
  final String id;
  final String createdAt;
  final String updatedAt;
  final int v;

  AddBankDetailsData({
    required this.userId,
    this.accountNumber,
    this.ifsc,
    this.bankHolderName,
    this.bankName,
    this.upi,
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    required this.v,
  });

  factory AddBankDetailsData.fromJson(Map<String, dynamic> json) {
    return AddBankDetailsData(
      userId: json['userId'] as String? ?? '',
      accountNumber: json['accountNumber'] as String?,
      ifsc: json['IFSC'] as String?,
      bankHolderName: json['bankHolderName'] as String?,
      bankName: json['bankNamee'] as String?,
      upi: json['UPI'] as String?,
      id: json['_id'] as String? ?? '',
      createdAt: json['createdAt'] as String? ?? '',
      updatedAt: json['updatedAt'] as String? ?? '',
      v: json['__v'] as int? ?? 0,
    );
  }
}
