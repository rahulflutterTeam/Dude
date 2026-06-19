// lib/models/language_update_response.dart

class LanguageUpdateResponse {
  final bool status;
  final String message;
  final UserProfileWithLanguage? data;

  LanguageUpdateResponse({
    required this.status,
    required this.message,
    this.data,
  });

  factory LanguageUpdateResponse.fromJson(Map<String, dynamic> json) {
    return LanguageUpdateResponse(
      status: json['status'] == true,
      message: json['message']?.toString() ?? 'Update failed',
      data: json['data'] != null
          ? UserProfileWithLanguage.fromJson(json['data'])
          : null,
    );
  }

  bool get isSuccess => status && data != null;
}

class UserProfileWithLanguage {
  final String id;
  final String phone;
  final bool isVerified;
  final String memberID;
  final String? name;
  final String? gender;
  final String? dob;
  final String? bio;
  final String? image;
  final List<InterestItem>? areaOfInterest;
  final String? language; // ← new field
  final DateTime createdAt;
  final DateTime updatedAt;

  UserProfileWithLanguage({
    required this.id,
    required this.phone,
    required this.isVerified,
    required this.memberID,
    this.name,
    this.gender,
    this.dob,
    this.bio,
    this.image,
    this.areaOfInterest,
    this.language,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserProfileWithLanguage.fromJson(Map<String, dynamic> json) {
    return UserProfileWithLanguage(
      id: json['_id']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      isVerified: json['isVerified'] == true,
      memberID: json['memberID']?.toString() ?? '',
      name: json['name']?.toString(),
      gender: json['gender']?.toString(),
      dob: json['DOB']?.toString(),
      bio: json['bio']?.toString(),
      image: json['image']?.toString(),
      areaOfInterest: (json['areaOfInterest'] as List<dynamic>?)
          ?.map((e) => InterestItem.fromJson(e))
          .toList(),
      language: json['Language']?.toString(),
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updatedAt'] ?? '') ?? DateTime.now(),
    );
  }
}

// Reuse or keep InterestItem from previous file if you want
class InterestItem {
  final String title;
  InterestItem({required this.title});
  factory InterestItem.fromJson(Map<String, dynamic> json) =>
      InterestItem(title: json['title'] ?? '');
}
