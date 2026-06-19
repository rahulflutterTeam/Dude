class ConfirmPurchaseResponse {
  final bool status;
  final String message;
  final ConfirmPurchaseData? data;

  ConfirmPurchaseResponse({
    required this.status,
    required this.message,
    this.data,
  });

  factory ConfirmPurchaseResponse.fromJson(Map<String, dynamic> json) {
    final dataJson = json['data'];
    return ConfirmPurchaseResponse(
      status: json['status'] as bool? ?? false,
      message: json['message'] as String? ?? '',
      data: dataJson is Map<String, dynamic>
          ? ConfirmPurchaseData.fromJson(dataJson)
          : null,
    );
  }
}

class ConfirmPurchaseData {
  final String userId;
  final String orderId;
  final String paymentId;
  final String signature;
  final int creditedCoins;
  final int newCoinBalance;
  final String status;
  final String id;
  final String createdAt;
  final String updatedAt;
  final int v;

  ConfirmPurchaseData({
    required this.userId,
    required this.orderId,
    required this.paymentId,
    required this.signature,
    required this.creditedCoins,
    required this.newCoinBalance,
    required this.status,
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    required this.v,
  });

  factory ConfirmPurchaseData.fromJson(Map<String, dynamic> json) {
    final userJson = json['user'] is Map<String, dynamic>
        ? json['user'] as Map<String, dynamic>
        : null;

    return ConfirmPurchaseData(
      userId: json['userId'] as String? ?? '',
      orderId:
          json['orderId'] as String? ??
          json['order_id'] as String? ??
          json['razorpayOrderId'] as String? ??
          '',
      paymentId:
          json['paymentId'] as String? ??
          json['razorpayPaymentId'] as String? ??
          json['cashfreePaymentId'] as String? ??
          '',
      signature: json['signature'] as String? ?? '',
      creditedCoins: _firstInt([
        json['creditedCoins'],
        json['creditedCoin'],
        json['coinsCredited'],
        json['coin'],
      ]),
      newCoinBalance: _firstInt([
        json['newCoinBalance'],
        json['coinBalance'],
        json['updatedCoinBalance'],
        json['userCoinBalance'],
        json['currentCoinBalance'],
        userJson?['coinBalance'],
      ]),
      status: json['status']?.toString() ?? 'pending',
      id: json['_id'] as String? ?? '',
      createdAt: json['createdAt'] as String? ?? '',
      updatedAt: json['updatedAt'] as String? ?? '',
      v: _toInt(json['__v']),
    );
  }

  static int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static int _firstInt(List<dynamic> values) {
    for (final value in values) {
      final parsed = _toInt(value);
      if (parsed > 0) return parsed;
    }
    return 0;
  }
}
