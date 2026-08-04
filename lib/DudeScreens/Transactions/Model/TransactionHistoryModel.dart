import 'dart:ui';

import 'package:dude/Dude_Utils/DateTimeFormatter/history_time_formatter.dart';
import 'package:flutter/material.dart';

class DepositHistoryResponse {
  final bool status;
  final String message;
  final List<DepositHistoryItem>? data;

  DepositHistoryResponse({
    required this.status,
    required this.message,
    this.data,
  });

  factory DepositHistoryResponse.fromJson(Map<String, dynamic> json) {
    final rawData = json['data'];
    final items = rawData is List
        ? rawData
        : rawData is Map && rawData['docs'] is List
        ? rawData['docs'] as List
        : rawData is Map && rawData['transactions'] is List
        ? rawData['transactions'] as List
        : const [];
    return DepositHistoryResponse(
      status: _boolValue(json['status']),
      message: json['message']?.toString() ?? 'No message',
      data: items
          .whereType<Map>()
          .map((e) => DepositHistoryItem.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
    );
  }
}

class DepositHistoryItem {
  final String id;
  final String userId;
  final String userName;
  final String userPhone;
  final String razorpayOrderId;
  final int totalAmount;
  final String currency;
  final String paymentStatus;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int v;
  final String? razorpayPaymentId;
  final String? razorpaySignature;

  // ─── Newly added field ──────────────────────────────────────────────────
  final String? image; // URL or path to image (nullable)

  DepositHistoryItem({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userPhone,
    required this.razorpayOrderId,
    required this.totalAmount,
    required this.currency,
    required this.paymentStatus,
    required this.createdAt,
    required this.updatedAt,
    required this.v,
    this.razorpayPaymentId,
    this.razorpaySignature,
    this.image, // ← added
  });

  factory DepositHistoryItem.fromJson(Map<String, dynamic> json) {
    return DepositHistoryItem(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      userId: json['userId']?.toString() ?? '',
      userName: json['userName']?.toString() ?? '',
      userPhone: json['userPhone']?.toString() ?? '',
      razorpayOrderId:
          json['orderId']?.toString() ??
          json['order_id']?.toString() ??
          json['razorpayOrderId']?.toString() ??
          json['cashfreeOrderId']?.toString() ??
          '',
      totalAmount: _intValue(
        json['totalAmount'] ?? json['amount'] ?? json['orderAmount'],
      ),
      currency: json['currency']?.toString() ?? 'INR',
      paymentStatus:
          json['paymentStatus']?.toString() ??
          json['status']?.toString() ??
          'pending',
      createdAt: HistoryTimeFormatter.parseLocal(json['createdAt']),
      updatedAt: HistoryTimeFormatter.parseLocal(json['updatedAt']),
      v: _intValue(json['__v']),
      razorpayPaymentId:
          json['razorpayPaymentId']?.toString() ??
          json['paymentId']?.toString() ??
          json['cfPaymentId']?.toString(),
      razorpaySignature: json['razorpaySignature']?.toString(),

      // Parse the new image field
      image: json['image']?.toString(),
    );
  }

  // Helper for UI (status text & color)
  String get statusText {
    switch (paymentStatus.toLowerCase()) {
      case 'paid':
        return 'Completed';
      case 'created':
        return 'Pending';
      case 'failed':
        return 'Failed';
      default:
        return paymentStatus;
    }
  }

  Color get statusColor {
    switch (paymentStatus.toLowerCase()) {
      case 'paid':
        return Colors.green;
      case 'created':
        return Colors.orange;
      case 'failed':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}

bool _boolValue(dynamic value) {
  if (value is bool) return value;
  final normalized = value?.toString().toLowerCase();
  return normalized == 'true' || normalized == '1' || normalized == 'success';
}

int _intValue(dynamic value) {
  if (value is num) return value.toInt();
  return num.tryParse(value?.toString() ?? '')?.toInt() ?? 0;
}
