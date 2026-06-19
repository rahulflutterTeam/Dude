// lib/models/staff_single_data_model.dart

// class StaffSingleDataResponse {
//   final bool status;
//   final String message;
//   final StaffSingleProfile? data;
//
//   StaffSingleDataResponse({
//     required this.status,
//     required this.message,
//     this.data,
//   });
//
//   factory StaffSingleDataResponse.fromJson(Map<String, dynamic> json) {
//     return StaffSingleDataResponse(
//       status: json['status'] == true,
//       message:
//       json['message']?.toString() ?? 'Failed to fetch staff details',
//       data: json['data'] != null
//           ? StaffSingleProfile.fromJson(json['data'])
//           : null,
//     );
//   }
// }

class StaffSingleProfile {
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
  final bool isRegister;
  final List<InterestItem> areaOfInterest;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? idNumber;
  final String? idType;
  final String? image;
  final String? formStatus;
  final double? totalEarnings;
  final double? pendingBalance;
  final double? coinAmount;
  final double? coin;
  final double? staffEarned;
  final String? isApproved;
  final String? callType; // ✅ NEW FIELD

  StaffSingleProfile({
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
    required this.isRegister,
    required this.areaOfInterest,
    required this.createdAt,
    required this.updatedAt,
    this.idNumber,
    this.idType,
    this.image,
    this.formStatus,
    this.totalEarnings,
    this.pendingBalance,
    this.coinAmount,
    this.coin,
    this.staffEarned,
    this.isApproved,
    this.callType, // ✅ NEW FIELD
  });

  factory StaffSingleProfile.fromJson(Map<String, dynamic> json) {
    return StaffSingleProfile(
      id: json['_id']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      otpExpiresAt: json['otpExpiresAt']?.toString(),
      memberID: json['memberID']?.toString() ?? '',
      otp: json['otp']?.toString(),
      gender: json['gender']?.toString(),
      role: json['role']?.toString() ?? 'Staff',
      balance: (json['balance'] as num?)?.toInt() ?? 0,
      isLogin: json['isLogin'] == true,
      isRegister: json['isRegister'] == true,
      areaOfInterest:
          (json['areaOfInterest'] as List<dynamic>?)
              ?.map((e) => InterestItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      createdAt:
          DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.now(),
      updatedAt:
          DateTime.tryParse(json['updatedAt']?.toString() ?? '') ??
          DateTime.now(),
      idNumber: json['IDnumber']?.toString(),
      idType: json['IDtype']?.toString(),
      image: json['image']?.toString(),
      formStatus: json['formStatus']?.toString(),
      totalEarnings: (json['totalEarnings'] as num?)?.toDouble() ?? 0.0,
      pendingBalance: (json['pendingBalance'] as num?)?.toDouble() ?? 0.0,
      coinAmount: (json['coinAmount'] as num?)?.toDouble() ?? 0.0,
      coin: (json['coin'] as num?)?.toDouble() ?? 0.0,
      staffEarned: (json['staffEarned'] as num?)?.toDouble() ?? 0.0,
      isApproved: json['isApproved']?.toString(),
      callType: json['callType']?.toString(), // ✅ NEW FIELD
    );
  }
}

class StaffSingleDataResponse {
  final bool status;
  final String message;
  final StaffSingleProfile? data;

  StaffSingleDataResponse({
    required this.status,
    required this.message,
    this.data,
  });

  factory StaffSingleDataResponse.fromJson(Map<String, dynamic> json) {
    return StaffSingleDataResponse(
      status: json['status'] == true,
      message: json['message']?.toString() ?? 'Failed to fetch staff details',
      data: json['data'] != null
          ? StaffSingleProfile.fromJson(json['data'])
          : null,
    );
  }
}

class InterestItem {
  final String title;

  InterestItem({required this.title});

  factory InterestItem.fromJson(Map<String, dynamic> json) {
    return InterestItem(title: json['title']?.toString() ?? '');
  }
}
