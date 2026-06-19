// lib/StaffScreenScreens/StaffDashBoardScreen/Model/CallTypeModel.dart

class CallTypeUpdateResponse {
  final bool status;
  final String message;
  final CallTypeData? data;

  CallTypeUpdateResponse({
    required this.status,
    required this.message,
    this.data,
  });

  factory CallTypeUpdateResponse.fromJson(Map<String, dynamic> json) {
    return CallTypeUpdateResponse(
      status: json['status'] ?? false,
      message: json['message'] ?? '',
      data: json['data'] != null ? CallTypeData.fromJson(json['data']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {'status': status, 'message': message, 'data': data?.toJson()};
  }
}

class CallTypeData {
  final String callType;
  final String updatedAt;

  CallTypeData({required this.callType, required this.updatedAt});

  factory CallTypeData.fromJson(Map<String, dynamic> json) {
    return CallTypeData(
      callType: json['callType'] ?? '',
      updatedAt: json['updatedAt'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {'callType': callType, 'updatedAt': updatedAt};
  }
}
