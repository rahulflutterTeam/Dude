// lib/models/update_profile_response.dart
class UpdateProfileResponse {
  final bool status;
  final String message;
  final UserProfileData? data;

  UpdateProfileResponse({
    required this.status,
    required this.message,
    this.data,
  });

  factory UpdateProfileResponse.fromJson(Map<String, dynamic> json) {
    return UpdateProfileResponse(
      status: json['status'] == true,
      message: json['message']?.toString() ?? 'Update failed',
      data: json['data'] != null
          ? UserProfileData.fromJson(json['data'])
          : null,
    );
  }

  bool get isSuccess => status && data != null;
}

class UserProfileData {
  final String id;
  final String phone;
  final bool isVerified;
  final String memberID;
  final String role;
  final String affiliateStatus;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? imageUrl; // profile picture URL after upload

  UserProfileData({
    required this.id,
    required this.phone,
    required this.isVerified,
    required this.memberID,
    required this.role,
    required this.affiliateStatus,
    required this.createdAt,
    required this.updatedAt,
    this.imageUrl,
  });

  factory UserProfileData.fromJson(Map<String, dynamic> json) {
    return UserProfileData(
      id: json['_id']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      isVerified: json['isVerified'] == true,
      memberID: json['memberID']?.toString() ?? '',
      role: json['role']?.toString() ?? '',
      affiliateStatus: json['affiliateStatus']?.toString() ?? '',
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updatedAt'] ?? '') ?? DateTime.now(),
      imageUrl: json['image']?.toString(),
    );
  }
}
