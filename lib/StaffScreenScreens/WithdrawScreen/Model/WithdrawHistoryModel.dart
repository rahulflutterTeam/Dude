// lib/models/staff_withdraw_history_response.dart

import 'package:dude/Dude_Utils/DateTimeFormatter/history_time_formatter.dart';
import 'package:flutter/material.dart';

class StaffWithdrawHistoryResponse {
  final bool status;
  final String message;
  final List<StaffWithdrawHistoryItem>? data;

  StaffWithdrawHistoryResponse({
    required this.status,
    required this.message,
    this.data,
  });

  factory StaffWithdrawHistoryResponse.fromJson(Map<String, dynamic> json) {
    return StaffWithdrawHistoryResponse(
      status: json['status'] as bool? ?? false,
      message: json['message'] as String? ?? '',
      data: (json['data'] as List<dynamic>?)
          ?.map(
            (e) => StaffWithdrawHistoryItem.fromJson(e as Map<String, dynamic>),
          )
          .toList(),
    );
  }
}

class StaffWithdrawHistoryItem {
  final String id;
  final String userId;
  final String accountNumber;
  final String confirmAccountNumber;
  final String ifsc;
  final String bankHolderName;
  final String bankNamee;
  final String? upi;
  final String? confirmUpi;
  final String email;
  final String phone;
  final String image;
  final String name;
  final String otpExpiresAt;
  final String memberID;
  final double amount;
  final double requestedAmount;
  final double withdrawFeeAmount;
  final double withdrawFeePercent;
  final double netAmount;
  final int status;
  final int statusCode;
  final String statusLabel;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int v;

  StaffWithdrawHistoryItem({
    required this.id,
    required this.userId,
    required this.accountNumber,
    required this.confirmAccountNumber,
    required this.ifsc,
    required this.bankHolderName,
    required this.bankNamee,
    this.upi,
    this.confirmUpi,
    required this.email,
    required this.phone,
    required this.image,
    required this.name,
    required this.otpExpiresAt,
    required this.memberID,
    required this.amount,
    required this.requestedAmount,
    required this.withdrawFeeAmount,
    required this.withdrawFeePercent,
    required this.netAmount,
    required this.status,
    required this.statusCode,
    required this.statusLabel,
    required this.createdAt,
    required this.updatedAt,
    required this.v,
  });

  factory StaffWithdrawHistoryItem.fromJson(Map<String, dynamic> json) {
    final withdrawalFeeUnit =
        json['withdrawalFeeUnit']?.toString().toLowerCase() ?? '';
    final withdrawalFeeValue = _toDouble(json['withdrawalFeeValue']);
    final parsedFeePercent = _toDouble(
      json['withdrawFeePercent'] ??
          json['withdrawalFeePercent'] ??
          json['feePercent'] ??
          json['feePercentage'],
    );
    final parsedFeeAmount = _toDouble(
      json['withdrawFeeAmount'] ??
          json['withdrawalFee'] ??
          json['feeAmount'] ??
          json['deductedFee'],
    );
    final resolvedFeeAmount =
        parsedFeeAmount > 0 || !_isAmountUnit(withdrawalFeeUnit)
        ? parsedFeeAmount
        : withdrawalFeeValue;
    final resolvedFeePercent = parsedFeePercent > 0
        ? parsedFeePercent
        : _isPercentUnit(withdrawalFeeUnit)
        ? withdrawalFeeValue
        : 0.0;

    return StaffWithdrawHistoryItem(
      id: json['_id'] as String? ?? '',
      userId: json['userId'] as String? ?? '',
      accountNumber: json['accountNumber'] as String? ?? '',
      confirmAccountNumber: json['confirmAccountNumber'] as String? ?? '',
      ifsc: json['IFSC'] as String? ?? '',
      bankHolderName: json['bankHolderName'] as String? ?? '',
      bankNamee: json['bankNamee'] as String? ?? '',
      upi: json['UPI'] as String?,
      confirmUpi: json['confirmUPI'] as String?,
      email: json['email'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      image: json['image'] as String? ?? '',
      name: json['name'] as String? ?? '',
      otpExpiresAt: json['otpExpiresAt'] as String? ?? '',
      memberID: json['memberID'] as String? ?? '',
      amount: _toDouble(json['amount']),
      requestedAmount: _toDouble(
        json['requestedAmount'] ??
            json['grossAmount'] ??
            json['originalAmount'],
      ),
      withdrawFeeAmount: resolvedFeeAmount,
      withdrawFeePercent: resolvedFeePercent,
      netAmount: _toDouble(json['netAmount'] ?? json['finalAmount']),
      status: int.tryParse(json['status']?.toString() ?? '0') ?? 0,
      createdAt: HistoryTimeFormatter.parseLocal(json['createdAt']),
      updatedAt: HistoryTimeFormatter.parseLocal(json['updatedAt']),
      v: json['__v'] as int? ?? 0,
      statusCode: int.tryParse(json['statusCode']?.toString() ?? '0') ?? 0,
      statusLabel: json['statusLabel'] as String? ?? 'Pending',
    );
  }

  static bool _isPercentUnit(String unit) =>
      unit == 'percent' || unit == 'percentage' || unit == '%';

  static bool _isAmountUnit(String unit) =>
      unit == 'amount' || unit == 'fixed' || unit == 'flat';

  double get displayRequestedAmount =>
      requestedAmount > 0 ? requestedAmount : amount + withdrawFeeAmount;

  double get displayNetAmount => netAmount > 0 ? netAmount : amount;

  bool get hasFeeBreakdown =>
      withdrawFeeAmount > 0 || withdrawFeePercent > 0 || requestedAmount > 0;

  String get amountText => _formatMoney(amount);
  String get requestedAmountText => _formatMoney(displayRequestedAmount);
  String get feeAmountText => _formatMoney(withdrawFeeAmount);
  String get netAmountText => _formatMoney(displayNetAmount);

  String get feeLabel {
    if (withdrawFeePercent <= 0) return 'Fee deduction';
    return 'Fee deduction (${_formatMoney(withdrawFeePercent)}%)';
  }

  static double _toDouble(dynamic value) {
    if (value is int) return value.toDouble();
    if (value is double) return value;
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  static String _formatMoney(double value) {
    if (value == value.roundToDouble()) {
      return value.toStringAsFixed(0);
    }

    return value.toStringAsFixed(2);
  }

  // Helper for UI
  Color get statusColor {
    switch (statusCode) {
      case 0:
        return Colors.orange;
      case 1:
        return Colors.green;
      case 2:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String get statusText => statusLabel.toUpperCase();
}
