// lib/DudeScreens/HomeScreen/Model/StaffDataModel.dart

class StaffDetailsResponse {
  final bool status;
  final String message;
  final List<StaffDataProfile>? data;

  StaffDetailsResponse({
    required this.status,
    required this.message,
    this.data,
  });

  factory StaffDetailsResponse.fromJson(Map<String, dynamic> json) {
    return StaffDetailsResponse(
      status: json['status'] == true,
      message: json['message']?.toString() ?? 'Failed to fetch staff details',
      data: (json['data'] as List<dynamic>?)
          ?.map((e) => StaffDataProfile.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class StaffDataProfile {
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
  final List<InterestItem> areaOfInterest;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? idNumber;
  final String? idType;
  final String? image;
  final String? dob;
  final String? callType;
  final String? bio;
  final String? language;
  final String? city;

  /// Presence fields
  final bool isOnline;
  final bool isBusy;
  final DateTime? lastSeen;
  final String? socketId;

  StaffDataProfile({
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
    this.image,
    this.dob,
    required this.isOnline,
    required this.isBusy,
    this.lastSeen,
    this.socketId,
    this.callType,
    this.bio,
    this.language,
    this.city,
  });

  /// ─────────────────────────────────────────
  /// JSON Parsing
  /// ─────────────────────────────────────────

  factory StaffDataProfile.fromJson(Map<String, dynamic> json) {
    return StaffDataProfile(
      id: json['_id']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      otpExpiresAt: json['otpExpiresAt']?.toString(),
      memberID: json['memberID']?.toString() ?? '',
      otp: json['otp']?.toString(),
      gender: json['gender']?.toString(),
      role: json['role']?.toString() ?? 'User',
      balance: (json['balance'] as num?)?.toInt() ?? 0,
      isLogin: json['isLogin'] == true,
      language: json['Language']?.toString(),
      city: json['city']?.toString() ?? json['City']?.toString(),
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
      dob: json['dob']?.toString(),

      /// presence
      isOnline: json['isOnline'] == true,
      isBusy: json['isBusy'] == true,
      lastSeen: json['lastSeen'] != null
          ? DateTime.tryParse(json['lastSeen'].toString())
          : null,
      socketId: json['socketId']?.toString(),

      /// call type - ADD THIS LINE
      callType: json['callType']?.toString(),
      bio: json['bio']?.toString() ?? "Not here to waste time - impress me",
    );
  }

  /// ─────────────────────────────────────────
  /// copyWith
  /// ─────────────────────────────────────────

  StaffDataProfile copyWith({
    bool? isOnline,
    bool? isBusy,
    DateTime? lastSeen,
    String? socketId,
    String? callType,
    String? city,
  }) {
    return StaffDataProfile(
      id: id,
      email: email,
      phone: phone,
      name: name,
      otpExpiresAt: otpExpiresAt,
      memberID: memberID,
      otp: otp,
      gender: gender,
      role: role,
      balance: balance,
      isLogin: isLogin,
      areaOfInterest: areaOfInterest,
      createdAt: createdAt,
      updatedAt: updatedAt,
      idNumber: idNumber,
      idType: idType,
      image: image,
      dob: dob,
      isOnline: isOnline ?? this.isOnline,
      isBusy: isBusy ?? this.isBusy,
      lastSeen: lastSeen ?? this.lastSeen,
      socketId: socketId ?? this.socketId,
      callType: callType ?? this.callType,
      bio: bio,
      language: language,
      city: city ?? this.city,
    );
  }

  /// ─────────────────────────────────────────
  /// Age Calculator
  /// ─────────────────────────────────────────

  int? get age {
    if (dob == null || dob!.isEmpty) return null;

    try {
      final parts = dob!.split('/');
      if (parts.length != 3) return null;

      final day = int.tryParse(parts[0]);
      final month = int.tryParse(parts[1]);
      final year = int.tryParse(parts[2]);

      if (day == null || month == null || year == null) return null;

      final birthDate = DateTime(year, month, day);
      final now = DateTime.now();

      int age = now.year - birthDate.year;

      if (now.month < birthDate.month ||
          (now.month == birthDate.month && now.day < birthDate.day)) {
        age--;
      }

      return age >= 0 ? age : null;
    } catch (_) {
      return null;
    }
  }
}

class InterestItem {
  final String title;

  InterestItem({required this.title});

  factory InterestItem.fromJson(Map<String, dynamic> json) {
    return InterestItem(title: json['title']?.toString() ?? '');
  }
}
