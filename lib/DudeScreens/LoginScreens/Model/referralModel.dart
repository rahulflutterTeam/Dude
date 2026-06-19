// lib/StaffScreenScreens/ReferEarnScreen/Model/ReferralDashboardModel.dart

class ReferralDashboardResponse {
  final bool status;
  final String message;
  final ReferralData data;

  ReferralDashboardResponse({
    required this.status,
    required this.message,
    required this.data,
  });

  factory ReferralDashboardResponse.fromJson(Map<String, dynamic> json) {
    return ReferralDashboardResponse(
      status: json['status'] ?? false,
      message: json['message'] ?? '',
      data: ReferralData.fromJson(json['data'] ?? {}),
    );
  }
}

class ReferralData {
  final int myInvites;
  final int perInvite;
  final int totalCoinsEarned;
  final String inviteCode;
  final String shareLink;

  ReferralData({
    required this.myInvites,
    required this.perInvite,
    required this.totalCoinsEarned,
    required this.inviteCode,
    required this.shareLink,
  });

  factory ReferralData.fromJson(Map<String, dynamic> json) {
    return ReferralData(
      myInvites: json['myInvites'] ?? 0,
      perInvite: json['perInvite'] ?? 0,
      totalCoinsEarned: json['totalCoinsEarned'] ?? 0,
      inviteCode: json['inviteCode'] ?? '',
      shareLink: json['shareLink'] ?? '',
    );
  }
}
