import 'package:dude/Dude_Utils/DateTimeFormatter/history_time_formatter.dart';

class CallHistoryResponse {
  final bool status;
  final String message;
  final List<CallHistoryItem>? data;

  CallHistoryResponse({required this.status, required this.message, this.data});

  factory CallHistoryResponse.fromJson(Map<String, dynamic> json) {
    return CallHistoryResponse(
      status: json['status'] as bool? ?? false,
      message: json['message'] as String? ?? '',
      data: (json['data'] as List<dynamic>?)
          ?.map((e) => CallHistoryItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class CallHistoryItem {
  final String id;
  final String callDuration; // can be "-1" for missed/failed
  final String callType; // "audio" or "video"
  final String userPhone;
  final String userName;
  final String userMemberID;
  final double userSpentAmount;
  final String userId;
  final double staffEarned;
  final String staffId;
  final String staffEmail;
  final String staffPhone;
  final String staffName;
  final String staffMemberID;
  final String? staffImage; // ← NEW FIELD (nullable URL string)
  final bool missedCall;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int v;

  CallHistoryItem({
    required this.id,
    required this.callDuration,
    required this.callType,
    required this.userPhone,
    required this.userName,
    required this.userMemberID,
    required this.userSpentAmount,
    required this.userId,
    required this.staffEarned,
    required this.staffId,
    required this.staffEmail,
    required this.staffPhone,
    required this.staffName,
    required this.staffMemberID,
    this.staffImage, // ← added here (nullable)
    required this.missedCall,
    required this.createdAt,
    required this.updatedAt,
    required this.v,
  });

  factory CallHistoryItem.fromJson(Map<String, dynamic> json) {
    return CallHistoryItem(
      id: json['_id'] as String? ?? '',
      callDuration: _stringValue(json['callDuration'], fallback: '0'),
      callType: json['callType'] as String? ?? 'audio',
      userPhone: json['userPhone'] as String? ?? '',
      userName: json['userName'] as String? ?? 'Unknown',
      userMemberID: json['userMemberID'] as String? ?? '',
      userSpentAmount: _doubleValue(json['userSpentAmount']),
      userId: json['userId'] as String? ?? '',
      staffEarned: _doubleValue(json['staffEarned']),
      staffId: json['staffId'] as String? ?? '',
      staffEmail: json['staffEmail'] as String? ?? '',
      staffPhone: json['staffPhone'] as String? ?? '',
      staffName: json['staffName'] as String? ?? 'Unknown',
      staffMemberID: json['staffMemberID'] as String? ?? '',
      staffImage: json['staffImage'] as String?, // ← added parsing
      missedCall: _boolValue(json['missedCall']),
      createdAt: HistoryTimeFormatter.parseLocal(json['createdAt']),
      updatedAt: HistoryTimeFormatter.parseLocal(json['updatedAt']),
      v: json['__v'] as int? ?? 0,
    );
  }

  static String _stringValue(dynamic value, {required String fallback}) {
    if (value == null) return fallback;
    return value.toString();
  }

  static double _doubleValue(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0;
    return 0;
  }

  static bool _boolValue(dynamic value) {
    if (value is bool) return value;
    return value?.toString().toLowerCase().trim() == 'true';
  }

  // Helper to determine status (for UI)
  CallStatus get status {
    if (missedCall) return CallStatus.missed;
    if (callDuration == "-1") return CallStatus.missed;
    return CallStatus.completed; // or outgoing/incoming based on logic
  }
}

// Reuse your existing enum or define here
enum CallStatus { completed, missed, outgoing }

enum CallType { audio, video }
