// lib/models/area_of_interest_response.dart

class AreaOfInterestResponse {
  final bool status;
  final String message;
  final UserProfileWithInterests? data;

  AreaOfInterestResponse({
    required this.status,
    required this.message,
    this.data,
  });

  factory AreaOfInterestResponse.fromJson(Map<String, dynamic> json) {
    return AreaOfInterestResponse(
      status: json['status'] == true,
      message: json['message']?.toString() ?? 'Update failed',
      data: json['data'] != null
          ? UserProfileWithInterests.fromJson(json['data'])
          : null,
    );
  }

  bool get isSuccess => status && data != null;
}

class UserProfileWithInterests {
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
  final DateTime createdAt;
  final DateTime updatedAt;

  UserProfileWithInterests({
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
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserProfileWithInterests.fromJson(Map<String, dynamic> json) {
    return UserProfileWithInterests(
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
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updatedAt'] ?? '') ?? DateTime.now(),
    );
  }
}

class InterestItem {
  final String title;

  InterestItem({required this.title});

  factory InterestItem.fromJson(Map<String, dynamic> json) {
    return InterestItem(title: json['title']?.toString() ?? '');
  }

  Map<String, dynamic> toJson() => {'title': title};
}
