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
  final String? staffImage;
  final String? userImage;
  final String? callSessionId;
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
    this.staffImage,
    this.userImage,
    this.callSessionId,
    required this.missedCall,
    required this.createdAt,
    required this.updatedAt,
    required this.v,
  });

  factory CallHistoryItem.fromJson(Map<String, dynamic> json) {
    return CallHistoryItem(
      id: _stringValue(json['_id'], fallback: ''),
      callDuration: _stringValue(json['callDuration'], fallback: '0'),
      callType: _stringValue(json['callType'], fallback: 'audio'),
      userPhone: _stringValue(json['userPhone'], fallback: ''),
      userName: _stringValue(json['userName'], fallback: 'Unknown'),
      userMemberID: _stringValue(json['userMemberID'], fallback: ''),
      userSpentAmount: _doubleValue(json['userSpentAmount']),
      userId: _stringValue(json['userId'], fallback: ''),
      staffEarned: _doubleValue(json['staffEarned']),
      staffId: _stringValue(json['staffId'], fallback: ''),
      staffEmail: _stringValue(json['staffEmail'], fallback: ''),
      staffPhone: _stringValue(json['staffPhone'], fallback: ''),
      staffName: _stringValue(json['staffName'], fallback: 'Unknown'),
      staffMemberID: _stringValue(json['staffMemberID'], fallback: ''),
      staffImage: json['staffImage']?.toString(),
      userImage: json['userImage']?.toString(),
      callSessionId: json['callSessionId']?.toString(),
      missedCall: _boolValue(json['missedCall']),
      createdAt: HistoryTimeFormatter.parseLocal(json['createdAt']),
      updatedAt: HistoryTimeFormatter.parseLocal(json['updatedAt']),
      v: json['__v'] is int ? json['__v'] as int : 0,
    );
  }

  /// Group key for collapsing leftover minute slices if the API returns them raw.
  String get groupKey {
    final session = (callSessionId ?? '').trim();
    if (session.isNotEmpty) {
      return session.split('#').first;
    }
    final rawId = id.trim();
    if (rawId.contains('#')) return rawId.split('#').first;
    // pe_... call ids without slice marker
    if (rawId.startsWith('pe_')) return rawId;
    return rawId.isNotEmpty ? rawId : '$userId|$staffId|${createdAt.millisecondsSinceEpoch}';
  }

  int get durationSeconds {
    if (missedCall || callDuration == '-1') return 0;
    return double.tryParse(callDuration)?.round() ?? 0;
  }

  CallHistoryItem mergeSlice(CallHistoryItem other) {
    final mergedMissed = missedCall || other.missedCall;
    final totalSecs = durationSeconds + other.durationSeconds;
    return CallHistoryItem(
      id: groupKey,
      callDuration: mergedMissed ? '-1' : totalSecs.toString(),
      callType: callType.isNotEmpty ? callType : other.callType,
      userPhone: userPhone.isNotEmpty ? userPhone : other.userPhone,
      userName: userName.isNotEmpty ? userName : other.userName,
      userMemberID: userMemberID.isNotEmpty ? userMemberID : other.userMemberID,
      userSpentAmount: userSpentAmount + other.userSpentAmount,
      userId: userId.isNotEmpty ? userId : other.userId,
      staffEarned: staffEarned + other.staffEarned,
      staffId: staffId.isNotEmpty ? staffId : other.staffId,
      staffEmail: staffEmail.isNotEmpty ? staffEmail : other.staffEmail,
      staffPhone: staffPhone.isNotEmpty ? staffPhone : other.staffPhone,
      staffName: staffName.isNotEmpty ? staffName : other.staffName,
      staffMemberID:
          staffMemberID.isNotEmpty ? staffMemberID : other.staffMemberID,
      staffImage: staffImage ?? other.staffImage,
      userImage: userImage ?? other.userImage,
      callSessionId: groupKey,
      missedCall: mergedMissed,
      createdAt: createdAt.isBefore(other.createdAt) ? createdAt : other.createdAt,
      updatedAt: updatedAt.isAfter(other.updatedAt) ? updatedAt : other.updatedAt,
      v: v,
    );
  }

  /// Collapse minute-billing slices into one row per logical call.
  static List<CallHistoryItem> coalesce(List<CallHistoryItem> items) {
    if (items.length <= 1) return items;
    final map = <String, CallHistoryItem>{};
    for (final item in items) {
      final key = item.groupKey;
      final existing = map[key];
      map[key] = existing == null ? item : existing.mergeSlice(item);
    }
    final list = map.values.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
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

  CallStatus get status {
    if (missedCall) return CallStatus.missed;
    if (callDuration == "-1") return CallStatus.missed;
    return CallStatus.completed;
  }
}

enum CallStatus { completed, missed, outgoing }

enum CallType { audio, video }
