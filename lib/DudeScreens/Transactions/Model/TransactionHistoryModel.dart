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
    return DepositHistoryResponse(
      status: json['status'] as bool? ?? false,
      message: json['message'] as String? ?? 'No message',
      data: (json['data'] as List<dynamic>?)
          ?.map((e) => DepositHistoryItem.fromJson(e as Map<String, dynamic>))
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
      id: json['_id'] as String? ?? '',
      userId: json['userId'] as String? ?? '',
      userName: json['userName'] as String? ?? '',
      userPhone: json['userPhone'] as String? ?? '',
      razorpayOrderId: json['razorpayOrderId'] as String? ?? '',
      totalAmount: json['totalAmount'] as int? ?? 0,
      currency: json['currency'] as String? ?? 'INR',
      paymentStatus: json['paymentStatus'] as String? ?? 'pending',
      createdAt: HistoryTimeFormatter.parseLocal(json['createdAt']),
      updatedAt: HistoryTimeFormatter.parseLocal(json['updatedAt']),
      v: json['__v'] as int? ?? 0,
      razorpayPaymentId: json['razorpayPaymentId'] as String?,
      razorpaySignature: json['razorpaySignature'] as String?,

      // Parse the new image field
      image: json['image'] as String?,
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
