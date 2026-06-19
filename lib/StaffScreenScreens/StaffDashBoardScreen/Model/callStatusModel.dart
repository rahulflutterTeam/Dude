// lib/models/staff_call_stats_model.dart

class StaffCallStatsResponse {
  final bool status;
  final String message;
  final StaffCallStatsData? data;

  StaffCallStatsResponse({
    required this.status,
    required this.message,
    this.data,
  });

  factory StaffCallStatsResponse.fromJson(Map<String, dynamic> json) {
    return StaffCallStatsResponse(
      status: json['status'] as bool? ?? false,
      message: json['message'] as String? ?? '',
      data: json['data'] != null
          ? StaffCallStatsData.fromJson(json['data'])
          : null,
    );
  }
}

class StaffCallStatsData {
  final int callsToday;
  final int totalMinutes;

  StaffCallStatsData({required this.callsToday, required this.totalMinutes});

  factory StaffCallStatsData.fromJson(Map<String, dynamic> json) {
    return StaffCallStatsData(
      callsToday: json['callsToday'] as int? ?? 0,
      totalMinutes: json['totalMinutes'] as int? ?? 0,
    );
  }
}
