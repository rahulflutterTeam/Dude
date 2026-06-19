// lib/models/staff_withdraw_response.dart

class StaffWithdrawResponse {
  final bool status;
  final String message;
  final StaffWithdrawData? data;

  StaffWithdrawResponse({
    required this.status,
    required this.message,
    this.data,
  });

  factory StaffWithdrawResponse.fromJson(Map<String, dynamic> json) {
    return StaffWithdrawResponse(
      status: json['status'] as bool? ?? false,
      message: json['message'] as String? ?? '',
      data: json['data'] != null
          ? StaffWithdrawData.fromJson(json['data'])
          : null,
    );
  }
}

class StaffWithdrawData {
  final String accountNumber;
  final String confirmAccountNumber;
  final String ifsc;
  final String bankHolderName;
  final String bankNamee;
  final String upi;
  final String confirmUpi;
  final String email;
  final String phone;
  final String image;
  final String name;
  final String otpExpiresAt;
  final String memberID;
  final int amount;
  final String status;
  final String id;
  final String createdAt;
  final String updatedAt;
  final int v;

  StaffWithdrawData({
    required this.accountNumber,
    required this.confirmAccountNumber,
    required this.ifsc,
    required this.bankHolderName,
    required this.bankNamee,
    required this.upi,
    required this.confirmUpi,
    required this.email,
    required this.phone,
    required this.image,
    required this.name,
    required this.otpExpiresAt,
    required this.memberID,
    required this.amount,
    required this.status,
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    required this.v,
  });

  factory StaffWithdrawData.fromJson(Map<String, dynamic> json) {
    return StaffWithdrawData(
      accountNumber: json['accountNumber'] as String? ?? '',
      confirmAccountNumber: json['confirmAccountNumber'] as String? ?? '',
      ifsc: json['IFSC'] as String? ?? '',
      bankHolderName: json['bankHolderName'] as String? ?? '',
      bankNamee: json['bankNamee'] as String? ?? '',
      upi: json['UPI'] as String? ?? '',
      confirmUpi: json['confirmUPI'] as String? ?? '',
      email: json['email'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      image: json['image'] as String? ?? '',
      name: json['name'] as String? ?? '',
      otpExpiresAt: json['otpExpiresAt'] as String? ?? '',
      memberID: json['memberID'] as String? ?? '',
      amount: json['amount'] as int? ?? 0,
      status: json['status'] as String? ?? 'PENDING',
      id: json['_id'] as String? ?? '',
      createdAt: json['createdAt'] as String? ?? '',
      updatedAt: json['updatedAt'] as String? ?? '',
      v: json['__v'] as int? ?? 0,
    );
  }
}
