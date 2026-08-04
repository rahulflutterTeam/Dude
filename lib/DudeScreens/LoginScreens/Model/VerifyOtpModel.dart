// lib/models/verify_otp_response.dart
class VerifyOtpResponse {
  final bool status;
  final String? token;
  final String message;
  final UserData? user;
  final bool newUser;

  VerifyOtpResponse({
    required this.status,
    this.token,
    required this.message,
    this.user,
    required this.newUser,
  });

  factory VerifyOtpResponse.fromJson(Map<String, dynamic> json) {
    return VerifyOtpResponse(
      status: json['status'] == true,
      token: json['token']?.toString(),
      message: json['message']?.toString() ?? 'Verification failed',
      user: json['user'] != null ? UserData.fromJson(json['user']) : null,
      newUser: _parseBool(json['newUser']),
    );
  }

  static bool _parseBool(dynamic value) {
    if (value is bool) return value;
    return value?.toString().toLowerCase() == 'true' ||
        value?.toString() == '1';
  }

  bool get isSuccess => status && token != null && token!.isNotEmpty;
}

class UserData {
  final String id;
  final String phone;
  final bool isVerified;
  final String memberID;
  final String role;
  final String affiliateStatus;
  final String appName;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Add other fields if you need them later

  UserData({
    required this.id,
    required this.phone,
    required this.isVerified,
    required this.memberID,
    required this.role,
    required this.affiliateStatus,
    required this.appName,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserData.fromJson(Map<String, dynamic> json) {
    return UserData(
      id: json['_id']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      isVerified: json['isVerified'] == true,
      memberID: json['memberID']?.toString() ?? '',
      role: json['role']?.toString() ?? '',
      affiliateStatus: json['affiliateStatus']?.toString() ?? '',
      appName: json['appName']?.toString() ?? '0',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : DateTime.now(),
    );
  }
}
