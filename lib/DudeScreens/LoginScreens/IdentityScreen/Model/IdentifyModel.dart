// lib/models/bio_profile_response.dart  (or update_profile_bio_response.dart)

class BioProfileResponse {
  final bool status;
  final String message;
  final UserBioData? data;

  BioProfileResponse({required this.status, required this.message, this.data});

  factory BioProfileResponse.fromJson(Map<String, dynamic> json) {
    return BioProfileResponse(
      status: json['status'] == true,
      message: json['message']?.toString() ?? 'Update failed',
      data: json['data'] != null ? UserBioData.fromJson(json['data']) : null,
    );
  }

  bool get isSuccess => status && data != null;
}

class UserBioData {
  final String id;
  final String phone;
  final bool isVerified;
  final String memberID;
  final String? name;
  final String? gender;
  final String? dob; // stored as string from your backend
  final String? bio;
  final String? image;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserBioData({
    required this.id,
    required this.phone,
    required this.isVerified,
    required this.memberID,
    this.name,
    this.gender,
    this.dob,
    this.bio,
    this.image,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserBioData.fromJson(Map<String, dynamic> json) {
    return UserBioData(
      id: json['_id']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      isVerified: json['isVerified'] == true,
      memberID: json['memberID']?.toString() ?? '',
      name: json['name']?.toString(),
      gender: json['gender']?.toString(),
      dob: json['DOB']?.toString(),
      bio: json['bio']?.toString(),
      image: json['image']?.toString(),
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updatedAt'] ?? '') ?? DateTime.now(),
    );
  }
}
