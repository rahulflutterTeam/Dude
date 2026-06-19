// lib/StaffScreenScreens/StaffDashBoardScreen/Model/StaffCallStatusModel.dart

class StaffCallStatusRequest {
  final String staffId;
  final bool isBusy;

  StaffCallStatusRequest({required this.staffId, required this.isBusy});

  Map<String, dynamic> toJson() {
    return {'staffId': staffId, 'isBusy': isBusy};
  }
}

class StaffCallStatusResponse {
  final bool status;
  final String message;

  StaffCallStatusResponse({required this.status, required this.message});

  factory StaffCallStatusResponse.fromJson(Map<String, dynamic> json) {
    return StaffCallStatusResponse(
      status: json['status'] == true,
      message: json['message']?.toString() ?? '',
    );
  }
}
