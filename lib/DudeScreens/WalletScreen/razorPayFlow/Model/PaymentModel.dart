class PlaceOrderResponse {
  final bool status;
  final String message;
  final PlaceOrderData? data;
  final GatewayOrderData? gatewayOrder;

  PlaceOrderResponse({
    required this.status,
    required this.message,
    this.data,
    this.gatewayOrder,
  });

  factory PlaceOrderResponse.fromJson(Map<String, dynamic> json) {
    final dataJson = json['data'] is Map<String, dynamic>
        ? json['data'] as Map<String, dynamic>
        : null;
    final gatewayOrderJson = json['gatewayOrder'] is Map<String, dynamic>
        ? json['gatewayOrder'] as Map<String, dynamic>
        : dataJson?['gatewayOrder'] is Map<String, dynamic>
        ? dataJson!['gatewayOrder'] as Map<String, dynamic>
        : null;

    return PlaceOrderResponse(
      status: json['status'] as bool? ?? false,
      message: json['message'] as String? ?? '',
      data: dataJson != null ? PlaceOrderData.fromJson(dataJson) : null,
      gatewayOrder: gatewayOrderJson != null
          ? GatewayOrderData.fromJson(gatewayOrderJson)
          : null,
    );
  }
}

class GatewayOrderData {
  final String provider;
  final String orderId;
  final String paymentSessionId;
  final String cfOrderId;

  const GatewayOrderData({
    required this.provider,
    required this.orderId,
    required this.paymentSessionId,
    required this.cfOrderId,
  });

  factory GatewayOrderData.fromJson(Map<String, dynamic> json) {
    return GatewayOrderData(
      provider: json['provider']?.toString() ?? '',
      orderId:
          json['orderId']?.toString() ?? json['order_id']?.toString() ?? '',
      paymentSessionId:
          json['paymentSessionId']?.toString() ??
          json['payment_session_id']?.toString() ??
          '',
      cfOrderId:
          json['cfOrderId']?.toString() ??
          json['cf_order_id']?.toString() ??
          '',
    );
  }
}

class PlaceOrderData {
  final String userId;
  final String userName;
  final String userPhone;
  final String razorpayOrderId;
  final int totalAmount;
  final String currency;
  final String paymentStatus;
  final String id;
  final String createdAt;
  final String updatedAt;
  final int v;
  final GatewayOrderData? gatewayOrder;
  final String paymentProvider;
  final String cashfreeOrderId;
  final String cashfreePaymentSessionId;

  PlaceOrderData({
    required this.userId,
    required this.userName,
    required this.userPhone,
    required this.razorpayOrderId,
    required this.totalAmount,
    required this.currency,
    required this.paymentStatus,
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    required this.v,
    this.gatewayOrder,
    required this.paymentProvider,
    required this.cashfreeOrderId,
    required this.cashfreePaymentSessionId,
  });

  factory PlaceOrderData.fromJson(Map<String, dynamic> json) {
    return PlaceOrderData(
      userId: json['userId'] as String? ?? '',
      userName: json['userName'] as String? ?? '',
      userPhone: json['userPhone'] as String? ?? '',
      razorpayOrderId: json['razorpayOrderId'] as String? ?? '',
      totalAmount: json['totalAmount'] as int? ?? 0,
      currency: json['currency'] as String? ?? 'INR',
      paymentStatus: json['paymentStatus'] as String? ?? 'created',
      id: json['_id'] as String? ?? '',
      createdAt: json['createdAt'] as String? ?? '',
      updatedAt: json['updatedAt'] as String? ?? '',
      v: json['__v'] as int? ?? 0,
      gatewayOrder: json['gatewayOrder'] is Map<String, dynamic>
          ? GatewayOrderData.fromJson(
              json['gatewayOrder'] as Map<String, dynamic>,
            )
          : null,
      paymentProvider: json['paymentProvider']?.toString() ?? '',
      cashfreeOrderId: json['cashfreeOrderId']?.toString() ?? '',
      cashfreePaymentSessionId:
          json['cashfreePaymentSessionId']?.toString() ?? '',
    );
  }
}
