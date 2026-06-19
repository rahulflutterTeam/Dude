import 'dart:convert';
import 'package:dude/DudeScreens/HomeScreen/Socket.dart';
import 'package:dude/DudeScreens/HomeScreen/callService.dart';
import 'package:flutter/foundation.dart';
import 'package:zego_uikit/zego_uikit.dart';

const String kCallBalanceTopUpCommand = 'pe_call_balance_topup';

class CallBalanceTopUpPayload {
  const CallBalanceTopUpPayload({
    required this.coinBalance,
    required this.maxSeconds,
    required this.pricePerMin,
    required this.elapsedSeconds,
    this.callId,
  });

  final int coinBalance;
  final int maxSeconds;
  final int pricePerMin;
  final int elapsedSeconds;
  final String? callId;

  Map<String, dynamic> toJson() => {
    'type': kCallBalanceTopUpCommand,
    'coin_balance': coinBalance,
    'max_seconds': maxSeconds,
    'price_per_min': pricePerMin,
    'elapsed_seconds': elapsedSeconds,
    if (callId != null && callId!.isNotEmpty) 'call_id': callId,
  };

  factory CallBalanceTopUpPayload.fromJson(Map<String, dynamic> json) {
    return CallBalanceTopUpPayload(
      coinBalance: _int(json['coin_balance'] ?? json['coinBalance']),
      maxSeconds: _int(json['max_seconds'] ?? json['maxSeconds']),
      pricePerMin: _int(json['price_per_min'] ?? json['pricePerMin']),
      elapsedSeconds: _int(json['elapsed_seconds'] ?? json['elapsedSeconds']),
      callId: json['call_id']?.toString() ?? json['callId']?.toString(),
    );
  }

  static int _int(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}

class CallBalanceSync {
  static Future<void> notifyStaffTopUp(CallService callService) async {
    if (!callService.isCallActive) return;

    final staffMemberId = callService.currentCallTargetID;
    final pricePerMin = callService.currentCallPricePerMin ?? 0;
    if (staffMemberId == null || staffMemberId.isEmpty || pricePerMin <= 0) {
      return;
    }

    final payload = CallBalanceTopUpPayload(
      coinBalance: callService.initialCoinBalance,
      maxSeconds: callService.maxCallSeconds,
      pricePerMin: pricePerMin,
      elapsedSeconds: callService.connectedElapsedSeconds,
      callId: callService.currentCallID,
    );

    final encoded = jsonEncode(payload.toJson());

    try {
      await ZegoUIKit().sendInRoomCommand(encoded, [staffMemberId]);
    } catch (e) {
      debugPrint('Failed to send in-call balance sync via Zego: $e');
    }

    SocketService().emit('call_balance_topup', {
      'staff_member_id': staffMemberId,
      'staff_id': callService.staffId,
      'call_id': callService.currentCallID,
      ...payload.toJson(),
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
  }

  static CallBalanceTopUpPayload? parseTopUpMessage(dynamic raw) {
    if (raw == null) return null;

    Map<String, dynamic>? map;
    if (raw is String) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is Map<String, dynamic>) {
          map = decoded;
        } else if (decoded is Map) {
          map = Map<String, dynamic>.from(decoded);
        }
      } catch (_) {
        return null;
      }
    } else if (raw is Map<String, dynamic>) {
      map = raw;
    } else if (raw is Map) {
      map = Map<String, dynamic>.from(raw);
    }

    if (map == null) return null;

    final type = map['type']?.toString();
    if (type != null && type != kCallBalanceTopUpCommand) return null;

    final payload = CallBalanceTopUpPayload.fromJson(map);
    if (payload.coinBalance <= 0 &&
        payload.maxSeconds <= 0 &&
        payload.pricePerMin <= 0) {
      return null;
    }
    return payload;
  }
}
