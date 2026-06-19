// lib/models/staff_weekly_call_graph_model.dart

class StaffWeeklyCallGraphResponse {
  final bool status;
  final String message;
  final List<WeeklyCallData>? data;

  StaffWeeklyCallGraphResponse({
    required this.status,
    required this.message,
    this.data,
  });

  factory StaffWeeklyCallGraphResponse.fromJson(Map<String, dynamic> json) {
    return StaffWeeklyCallGraphResponse(
      status: json['status'] as bool? ?? false,
      message: json['message'] as String? ?? '',
      data: (json['data'] as List<dynamic>?)
          ?.map((e) => WeeklyCallData.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class WeeklyCallData {
  final String day;
  final int calls;

  WeeklyCallData({required this.day, required this.calls});

  factory WeeklyCallData.fromJson(Map<String, dynamic> json) {
    return WeeklyCallData(
      day: json['day'] as String? ?? '',
      calls: json['calls'] as int? ?? 0,
    );
  }
}
