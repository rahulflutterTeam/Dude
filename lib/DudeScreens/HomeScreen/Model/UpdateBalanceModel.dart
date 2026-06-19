// 1. Keep AreaOfInterest as is
class AreaOfInterest {
  final String title;
  AreaOfInterest({required this.title});

  factory AreaOfInterest.fromJson(Map<String, dynamic> json) {
    return AreaOfInterest(title: json['title'] as String);
  }
}

// 2. Rename your current UpdateBalanceData → better name: UserData (or keep if you prefer)
class UserData {
  // ← was UpdateBalanceData
  final int totalCoinBalance;
  final String id;
  final String phone;
  final String? otpExpiresAt;
  final String memberID;
  final String? otp;
  final String gender;
  final String role;
  final bool isLogin;
  final bool isOAuth;
  final String ip;
  final int totalPurchaseAmount;
  final List<AreaOfInterest> areaOfInterest;
  final String createdAt;
  final String updatedAt;
  final int v;
  final String formStatus;
  final String image;
  final String DOB;
  final String bio;
  final String name;
  final String language;
  final int coinBalance;

  UserData({
    required this.totalCoinBalance,
    required this.id,
    required this.phone,
    this.otpExpiresAt,
    required this.memberID,
    this.otp,
    required this.gender,
    required this.role,
    required this.isLogin,
    required this.isOAuth,
    required this.ip,
    required this.totalPurchaseAmount,
    required this.areaOfInterest,
    required this.createdAt,
    required this.updatedAt,
    required this.v,
    required this.formStatus,
    required this.image,
    required this.DOB,
    required this.bio,
    required this.name,
    required this.language,
    required this.coinBalance,
  });

  factory UserData.fromJson(Map<String, dynamic> json) {
    return UserData(
      totalCoinBalance: (json['totalCoinBalance'] as num?)?.toInt() ?? 0,
      id: json['_id'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      otpExpiresAt: json['otpExpiresAt'] as String?,
      memberID: json['memberID'] as String? ?? '',
      otp: json['otp'] as String?,
      gender: json['gender'] as String? ?? '',
      role: json['role'] as String? ?? '',
      isLogin: json['isLogin'] as bool? ?? false,
      isOAuth: json['isOAuth'] as bool? ?? false,
      ip: json['ip'] as String? ?? '',
      totalPurchaseAmount: (json['totalPurchaseAmount'] as num?)?.toInt() ?? 0,
      areaOfInterest:
          (json['areaOfInterest'] as List<dynamic>?)
              ?.map((e) => AreaOfInterest.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      createdAt: json['createdAt'] as String? ?? '',
      updatedAt: json['updatedAt'] as String? ?? '',
      v: (json['__v'] as num?)?.toInt() ?? 0,
      formStatus: json['formStatus'] as String? ?? '',
      image: json['image'] as String? ?? '',
      DOB: json['DOB'] as String? ?? '',
      bio: json['bio'] as String? ?? '',
      name: json['name'] as String? ?? '',
      language: json['Language'] as String? ?? '',
      coinBalance: (json['coinBalance'] as num?)?.toInt() ?? 0,
    );
  }
}

// 3. New lightweight class for staff (only the fields you care about)
class StaffUpdateInfo {
  final String id;
  final int? staffEarned;
  final int? totalEarnings; // optional – from the full staff object

  StaffUpdateInfo({required this.id, this.staffEarned, this.totalEarnings});

  factory StaffUpdateInfo.fromJson(Map<String, dynamic> json) {
    return StaffUpdateInfo(
      id: json['_id'] as String? ?? json['staffId'] as String? ?? '',
      staffEarned: (json['staffEarned'] as num?)?.toInt(),
      totalEarnings: (json['totalEarnings'] as num?)?.toInt(),
    );
  }
}

// 4. Wrapper for data → contains user + staff
class BalanceUpdateData {
  final UserData user;
  final StaffUpdateInfo? staff;

  BalanceUpdateData({required this.user, this.staff});

  factory BalanceUpdateData.fromJson(Map<String, dynamic> json) {
    return BalanceUpdateData(
      user: UserData.fromJson(json['user'] as Map<String, dynamic>),
      staff: json['staff'] != null
          ? StaffUpdateInfo.fromJson(json['staff'] as Map<String, dynamic>)
          : null,
    );
  }
}

// 5. Final response class
class UpdateBalanceResponse {
  final bool status;
  final String message;
  final BalanceUpdateData? data;

  UpdateBalanceResponse({
    required this.status,
    required this.message,
    this.data,
  });

  factory UpdateBalanceResponse.fromJson(Map<String, dynamic> json) {
    return UpdateBalanceResponse(
      status: json['status'] as bool,
      message: json['message'] as String,
      data: json['data'] != null
          ? BalanceUpdateData.fromJson(json['data'] as Map<String, dynamic>)
          : null,
    );
  }
}
