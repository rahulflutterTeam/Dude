// lib/models/staff_id_verify_response.dart

class StaffIdVerifyResponse {
  final bool status;
  final String message;
  final StaffProfile? data;

  StaffIdVerifyResponse({
    required this.status,
    required this.message,
    this.data,
  });

  factory StaffIdVerifyResponse.fromJson(Map<String, dynamic> json) {
    return StaffIdVerifyResponse(
      status: json['status'] == true,
      message: json['message']?.toString() ?? 'Verification failed',
      data: json['data'] != null ? StaffProfile.fromJson(json['data']) : null,
    );
  }

  bool get isSuccess => status && data != null;
}

class StaffProfile {
  final String id;
  final String email;
  final String phone;
  final String name;
  final String? otpExpiresAt;
  final String memberID;
  final String? otp;
  final String? gender;
  final String role;
  final int balance;
  final bool isLogin;
  final List<dynamic> areaOfInterest;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? idNumber; // ← new from response
  final String? idType; // ← new from response

  StaffProfile({
    required this.id,
    required this.email,
    required this.phone,
    required this.name,
    this.otpExpiresAt,
    required this.memberID,
    this.otp,
    this.gender,
    required this.role,
    required this.balance,
    required this.isLogin,
    required this.areaOfInterest,
    required this.createdAt,
    required this.updatedAt,
    this.idNumber,
    this.idType,
  });

  factory StaffProfile.fromJson(Map<String, dynamic> json) {
    return StaffProfile(
      id: json['_id'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      name: json['name'] ?? '',
      otpExpiresAt: json['otpExpiresAt']?.toString(),
      memberID: json['memberID'] ?? '',
      otp: json['otp']?.toString(),
      gender: json['gender']?.toString(),
      role: json['role'] ?? '',
      balance: json['balance'] ?? 0,
      isLogin: json['isLogin'] == true,
      areaOfInterest: json['areaOfInterest'] ?? [],
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updatedAt'] ?? '') ?? DateTime.now(),
      idNumber: json['IDnumber']?.toString(),
      idType: json['IDtype']?.toString(),
    );
  }
}
